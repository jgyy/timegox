"""Pack an exported .glb smaller without changing what the game sees (no Blender needed: numpy only).

``kit.export`` runs this on every file it writes, and ``python art/pack_all.py`` runs it over everything in
``assets/`` (it is idempotent: packing a packed file changes nothing).

What the Blender exporter writes is generous: every vertex weight, normal and tint UV as 32-bit
floats, three animation channels for every bone of every clip (translation, rotation and scale, most
of them two keys that say "stay where the rig rests"), a time track of its own for every channel and
a JSON entry for each of those.  A character with sixty clips is two thirds bookkeeping.  Packing

* drops the animation channels of a clip in which the bone never leaves its rest pose (Godot's
  importer makes no track of those, so the game's clips are the same, track for track);
* stores bone rotations as normalised 16-bit quaternions (half the size, 1/32767 precision);
* shares one time track between every channel that has the same keys, and any other accessor whose
  bytes are identical;
* stores skin weights as normalised bytes (four weights that still sum to exactly one) and the tint
  UV as normalised 16-bit, both plain glTF 2.0 (normals stay floats: quantised normals need
  ``KHR_mesh_quantization``, which Godot's importer refuses);
* writes one buffer view per kind of data instead of one per accessor, and compact JSON.

Positions, normals, vertex colours (the surface class lives in their alpha), indices, joints and the rig are
left exactly as exported.
"""
import json
import os
import struct
import sys

import numpy as np

CT = {5120: "i1", 5121: "u1", 5122: "<i2", 5123: "<u2", 5125: "<u4", 5126: "<f4"}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
REST = {"translation": (0.0, 0.0, 0.0), "rotation": (0.0, 0.0, 0.0, 1.0), "scale": (1.0, 1.0, 1.0)}
# how far a channel may stray from the rest pose and still count as resting
EPS = {"translation": 1e-6, "rotation": 1e-6, "scale": 1e-6}
ARRAY_BUFFER = 34962
ELEMENT_ARRAY_BUFFER = 34963


def read(path):
    with open(path, "rb") as f:
        data = f.read()
    magic, version, length = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67 or version != 2:
        raise ValueError("%s is not a glTF 2.0 binary" % path)
    off = 12
    js = None
    blob = b""
    while off < length:
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(chunk.decode("utf-8"))
        elif ctype == 0x004E4942:
            blob = chunk
        off += 8 + clen
    return js, blob


def write(path, js, blob):
    text = json.dumps(js, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    text += b" " * (-len(text) % 4)
    blob = bytes(blob) + b"\0" * (-len(blob) % 4)
    total = 12 + 8 + len(text) + 8 + len(blob)
    with open(path, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(text), 0x4E4F534A))
        f.write(text)
        f.write(struct.pack("<II", len(blob), 0x004E4942))
        f.write(blob)


def fetch(js, blob, index):
    """The values of accessor `index` as an (n, components) array of its own type."""
    a = js["accessors"][index]
    if "sparse" in a or "bufferView" not in a:
        raise ValueError("sparse accessors are not written by the kit")
    v = js["bufferViews"][a["bufferView"]]
    n = NC[a["type"]]
    dt = np.dtype(CT[a["componentType"]])
    start = v.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = v.get("byteStride", 0)
    if stride and stride != dt.itemsize * n:
        rows = np.frombuffer(blob, np.uint8, stride * (a["count"] - 1) + dt.itemsize * n, start)
        idx = np.arange(a["count"])[:, None] * stride + np.arange(dt.itemsize * n)[None, :]
        return np.frombuffer(rows[idx].tobytes(), dt).reshape(-1, n)
    return np.frombuffer(blob, dt, a["count"] * n, start).reshape(-1, n)


def as_float(arr, a):
    """Accessor values as floats (normalised integers are scaled back)."""
    if a["componentType"] == 5126 or not a.get("normalized"):
        return arr.astype(np.float64)
    top = {5120: 127.0, 5121: 255.0, 5122: 32767.0, 5123: 65535.0}[a["componentType"]]
    return np.maximum(arr.astype(np.float64) / top, -1.0)


def weights_u8(w):
    """Four float weights -> four bytes that sum to exactly 255 (largest remainder)."""
    w = np.clip(w.astype(np.float64), 0.0, None)
    s = w.sum(1, keepdims=True)
    s[s == 0.0] = 1.0
    x = w / s * 255.0
    q = np.floor(x)
    left = (255 - q.sum(1)).astype(np.int64)
    order = np.argsort(-(x - q), axis=1, kind="stable")
    rank = np.empty_like(order)
    np.put_along_axis(rank, order, np.arange(w.shape[1])[None, :].repeat(len(w), 0), 1)
    q += rank < left[:, None]
    # a vertex with no weights at all stays empty
    q[w.sum(1) == 0.0] = 0
    return q.astype(np.uint8)


class Out:
    """The new buffer: one view per kind of data, identical accessors stored once."""

    def __init__(self):
        self.views = {}   # key -> [bytearray, view dict]
        self.order = []
        self.accessors = []
        self.seen = {}

    def add(self, arr, type_, ctype, kind, normalized=False, minmax=False, target=None, pad4=False):
        arr = np.ascontiguousarray(arr.astype(CT[ctype]))
        raw = arr.tobytes()
        rows = len(arr)
        width = arr.dtype.itemsize * NC[type_]
        stride = width
        if pad4 and width % 4:
            stride = width + (-width % 4)
            padded = np.zeros((rows, stride), np.uint8)
            padded[:, :width] = np.frombuffer(raw, np.uint8).reshape(rows, width)
            raw = padded.tobytes()
        key = (kind, stride if target == ARRAY_BUFFER else 0)
        sig = (key, type_, ctype, normalized, rows, raw)
        if sig in self.seen:
            return self.seen[sig]
        if key not in self.views:
            view = {"buffer": 0}
            if target:
                view["target"] = target
            if target == ARRAY_BUFFER:
                view["byteStride"] = stride
            self.views[key] = [bytearray(), view]
            self.order.append(key)
        data = self.views[key][0]
        data.extend(b"\0" * (-len(data) % max(4, arr.dtype.itemsize)))
        acc = {"bufferView": self.order.index(key), "componentType": ctype, "count": rows, "type": type_}
        if len(data):
            acc["byteOffset"] = len(data)
        if normalized:
            acc["normalized"] = True
        if minmax and rows:
            cast = float if ctype == 5126 else int
            acc["min"] = [cast(x) for x in arr.min(0)]
            acc["max"] = [cast(x) for x in arr.max(0)]
        data.extend(raw)
        self.accessors.append(acc)
        self.seen[sig] = len(self.accessors) - 1
        return self.seen[sig]

    def finish(self):
        blob = bytearray()
        views = []
        for key in self.order:
            data, view = self.views[key]
            blob.extend(b"\0" * (-len(blob) % 4))
            view["byteOffset"] = len(blob)
            view["byteLength"] = len(data)
            blob.extend(data)
            views.append(view)
        return views, blob


def rests(js, node, path):
    return np.array(js["nodes"][node].get(path, REST[path]), np.float64)


def at_rest(values, rest, path):
    if path == "rotation":
        # q and -q are the same turn
        d = np.minimum(np.abs(values - rest).max(), np.abs(values + rest).max())
    else:
        d = np.abs(values - rest).max()
    return d <= EPS[path]


def pack(glb, quiet=True):
    """Rewrite `glb` packed.  Returns (bytes before, bytes after)."""
    before = os.path.getsize(glb)
    js, blob = read(glb)
    old = js.get("accessors", [])
    out = Out()

    # ---- meshes
    for mesh in js.get("meshes", []):
        for prim in mesh["primitives"]:
            if prim.get("targets"):
                raise ValueError("morph targets are not written by the kit")
            attrs = prim["attributes"]
            for name in list(attrs):
                a = old[attrs[name]]
                arr = fetch(js, blob, attrs[name])
                if name == "POSITION":
                    attrs[name] = out.add(arr, a["type"], 5126, "vertex", minmax=True, target=ARRAY_BUFFER)
                elif name.startswith("TEXCOORD_"):
                    f = as_float(arr, a)
                    if a["componentType"] != 5126:
                        attrs[name] = out.add(arr, a["type"], a["componentType"], "vertex", normalized=a.get("normalized", False), target=ARRAY_BUFFER)
                    elif f.size and f.min() >= 0.0 and f.max() <= 1.0:
                        attrs[name] = out.add(np.round(f * 65535.0), "VEC2", 5123, "vertex", normalized=True, target=ARRAY_BUFFER)
                    else:
                        attrs[name] = out.add(arr, a["type"], a["componentType"], "vertex", normalized=a.get("normalized", False), target=ARRAY_BUFFER)
                elif name.startswith("WEIGHTS_") and a["componentType"] == 5121:
                    attrs[name] = out.add(arr, "VEC4", 5121, "vertex", normalized=True, target=ARRAY_BUFFER)
                elif name.startswith("WEIGHTS_"):
                    attrs[name] = out.add(weights_u8(as_float(arr, a)), "VEC4", 5121, "vertex", normalized=True, target=ARRAY_BUFFER)
                else:
                    # colours (the surface class is in alpha), joints: as exported
                    attrs[name] = out.add(arr, a["type"], a["componentType"], "vertex", normalized=a.get("normalized", False), target=ARRAY_BUFFER,
                        pad4=True)
            if "indices" in prim:
                a = old[prim["indices"]]
                arr = fetch(js, blob, prim["indices"])
                ctype = 5123 if int(arr.max(initial=0)) < 65535 else 5125
                prim["indices"] = out.add(arr, "SCALAR", ctype, "index", target=ELEMENT_ARRAY_BUFFER)

    # ---- skins
    for skin in js.get("skins", []):
        if "inverseBindMatrices" in skin:
            skin["inverseBindMatrices"] = out.add(fetch(js, blob, skin["inverseBindMatrices"]), "MAT4", 5126, "skin")

    # ---- animations
    anims = js.get("animations", [])
    cache = {}
    for anim in anims:
        channels = []
        samplers = []
        made = {}
        for ch in anim["channels"]:
            node, prop = ch["target"].get("node"), ch["target"]["path"]
            s = anim["samplers"][ch["sampler"]]
            spline = s.get("interpolation") == "CUBICSPLINE"
            if prop in REST and node is not None and not spline:
                if s["output"] not in cache:
                    cache[s["output"]] = as_float(fetch(js, blob, s["output"]), old[s["output"]])
                if at_rest(cache[s["output"]], rests(js, node, prop), prop):
                    # the bone never leaves its rest pose in this clip: the importer makes no track of it
                    continue
            if ch["sampler"] not in made:
                t = fetch(js, blob, s["input"])
                ia = out.add(t, "SCALAR", 5126, "anim", minmax=True)
                oa_old = old[s["output"]]
                vals = fetch(js, blob, s["output"])
                if prop == "rotation" and not spline and oa_old["componentType"] == 5126:
                    f = as_float(vals, oa_old)
                    ln = np.linalg.norm(f, axis=1, keepdims=True)
                    ln[ln == 0.0] = 1.0
                    oa = out.add(np.round(f / ln * 32767.0), "VEC4", 5122, "anim", normalized=True)
                else:
                    oa = out.add(vals, oa_old["type"], oa_old["componentType"], "anim", normalized=oa_old.get("normalized", False))
                ns = {"input": ia, "output": oa}
                if s.get("interpolation", "LINEAR") != "LINEAR":
                    ns["interpolation"] = s["interpolation"]
                made[ch["sampler"]] = len(samplers)
                samplers.append(ns)
            channels.append({"sampler": made[ch["sampler"]], "target": ch["target"]})
        anim["channels"] = channels
        anim["samplers"] = samplers

    views, data = out.finish()
    js["accessors"] = out.accessors
    js["bufferViews"] = views
    js["buffers"] = [{"byteLength": len(data) + (-len(data) % 4)}]
    write(glb, js, data)
    after = os.path.getsize(glb)
    if not quiet:
        print("[pack] %s %d -> %d bytes (%.0f%%)" % (glb, before, after, 100.0 * after / max(1, before)))
    return before, after


def pack_all(root):
    total = [0, 0]
    n = 0
    for folder, _dirs, files in sorted(os.walk(root)):
        for name in sorted(files):
            if name.endswith(".glb"):
                b, a = pack(os.path.join(folder, name))
                total[0] += b
                total[1] += a
                n += 1
    print("[pack] %d files: %.1f MB -> %.1f MB" % (n, total[0] / 1048576.0, total[1] / 1048576.0))
    return total


if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    targets = sys.argv[1:] or [os.path.join(here, "..", "..", "assets")]
    for t in targets:
        if os.path.isdir(t):
            pack_all(t)
        else:
            pack(t, quiet=False)
