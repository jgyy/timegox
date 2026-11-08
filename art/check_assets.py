"""Validate every exported asset in assets/ without Blender: a small GLB reader checks what the game
relies on, so a broken build fails in the art job instead of in a playthrough.

    python art/check_assets.py            # after python art/build_all.py

Checks
------
* every script in art/<group>/ has its .glb, and every .glb has a script (no hand-made files);
* the file is a valid glTF 2.0 binary with a JSON and a BIN chunk;
* materials are only the game's three slots: toon, plain, glow;
* meshes carry vertex colours (COLOR_0, the surface class lives in alpha) and the tint UV (TEXCOORD_0);
* triangle budgets: characters 5k-50k, monsters 3k-90k, props under 5k (they are instanced) except one-off set pieces;
* characters have a skin with the bones the game drives (hips, chest, head, eyes, mouth, hands,
  fingers, thumbs, sleeve pockets, feet, toes, the hair and cape chains) and all eleven clips
  (idle, walk, run, sit, talk, bow, attack, cast, hurt, victory, die);
* monsters have a skin and at least the five clips the game plays: idle and walk (loops), attack,
  hurt and die.

Exits non-zero and lists every problem if anything fails.
"""
import json
import os
import struct
import sys

ART = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(ART)
GROUPS = ("characters", "monsters", "props")
BUDGET = {"characters": (5000, 50000), "monsters": (3000, 90000), "props": (200, 5000)}
# one-off set pieces shown once (ending screen), not scattered across maps
SET_PIECES = {"props/magpiebridge": (2000, 24000)}
PERSON_BONES = ("hips", "chest", "neck", "head", "eyes", "mouth", "hand.L", "hand.R", "fingers.L", "fingers.R",
                "thumb.L", "thumb.R", "sleeve.L", "sleeve.R", "foot.L", "foot.R", "toe.L", "toe.R", "hair_tail2", "cape3")
PERSON_CLIPS = ("idle", "walk", "run", "sit", "talk", "bow", "attack", "cast", "hurt", "victory", "die")
MONSTER_CLIPS = ("idle", "walk", "attack", "hurt", "die")
MATERIALS = {"toon", "plain", "glow"}


def read_glb(path):
    """Return the glTF JSON of a .glb file (raises ValueError on a malformed file)."""
    with open(path, "rb") as f:
        data = f.read()
    if len(data) < 20:
        raise ValueError("file too short")
    magic, version, length = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67:
        raise ValueError("not a glTF binary")
    if version != 2:
        raise ValueError("glTF version %d, expected 2" % version)
    if length != len(data):
        raise ValueError("length header %d does not match file size %d" % (length, len(data)))
    off = 12
    js = None
    has_bin = False
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(chunk.decode("utf-8"))
        elif ctype == 0x004E4942:
            has_bin = True
        off += 8 + clen
    if js is None or not has_bin:
        raise ValueError("missing JSON or BIN chunk")
    return js


def triangles(js):
    tris = 0
    for mesh in js.get("meshes", []):
        for prim in mesh.get("primitives", []):
            if prim.get("mode", 4) != 4:
                continue
            if "indices" in prim:
                tris += js["accessors"][prim["indices"]]["count"] // 3
            else:
                tris += js["accessors"][prim["attributes"]["POSITION"]]["count"] // 3
    return tris


def check_asset(group, name, path):
    problems = []
    try:
        js = read_glb(path)
    except (ValueError, OSError, json.JSONDecodeError) as e:
        return ["%s/%s: unreadable (%s)" % (group, name, e)]
    tag = "%s/%s" % (group, name)
    mats = {m.get("name", "") for m in js.get("materials", [])}
    stray = {m for m in mats if not any(m.startswith(k) for k in MATERIALS)}
    if stray:
        problems.append("%s: unexpected materials %s" % (tag, sorted(stray)))
    for mesh in js.get("meshes", []):
        for prim in mesh.get("primitives", []):
            attrs = prim.get("attributes", {})
            if "COLOR_0" not in attrs:
                problems.append("%s: a mesh has no vertex colours" % tag)
            if "TEXCOORD_0" not in attrs:
                problems.append("%s: a mesh has no tint UV" % tag)
    lo, hi = SET_PIECES.get(tag, BUDGET[group])
    tris = triangles(js)
    if not lo <= tris <= hi:
        problems.append("%s: %d triangles, budget %d-%d" % (tag, tris, lo, hi))
    if group == "props":
        return problems
    skins = js.get("skins", [])
    if not skins:
        problems.append("%s: no skin (rig)" % tag)
        return problems
    names = {js["nodes"][j].get("name", "") for j in skins[0]["joints"]}
    clips = {a.get("name", "") for a in js.get("animations", [])}
    if group == "characters":
        missing = [b for b in PERSON_BONES if b not in names]
        if missing:
            problems.append("%s: rig lacks bones %s" % (tag, missing))
        need = PERSON_CLIPS
    else:
        need = MONSTER_CLIPS
    miss_clips = [c for c in need if c not in clips]
    if miss_clips:
        problems.append("%s: missing clips %s" % (tag, miss_clips))
    return problems


def main():
    problems = []
    counts = {}
    for group in GROUPS:
        scripts = {f[:-3] for f in os.listdir(os.path.join(ART, group)) if f.endswith(".py")}
        folder = os.path.join(ROOT, "assets", group)
        glbs = {f[:-4] for f in os.listdir(folder) if f.endswith(".glb")} if os.path.isdir(folder) else set()
        for name in sorted(scripts - glbs):
            problems.append("%s/%s: script has no exported .glb (run art/build_all.py)" % (group, name))
        for name in sorted(glbs - scripts):
            problems.append("%s/%s: .glb has no script in art/%s (all art must be generated)" % (group, name, group))
        for name in sorted(scripts & glbs):
            problems += check_asset(group, name, os.path.join(folder, name + ".glb"))
        counts[group] = len(scripts & glbs)
    print("[check_assets] %s" % ", ".join("%d %s" % (n, g) for g, n in counts.items()))
    if problems:
        for p in problems:
            print("[check_assets] FAIL " + p)
        sys.exit(1)
    print("[check_assets] all assets pass")


if __name__ == "__main__":
    main()
