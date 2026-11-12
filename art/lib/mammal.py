"""Helpers shared by the furred beasts (art/lib/canine.py, feline.py and the ape, mammoth, qilin and
jade rabbit scripts): grooming of sculpted fur that keeps the silhouette tidy, frames along chains,
and the parts of a face that read at a distance.

Stylised fur (after the usual advice for game creatures: silhouette first, then value, colour
last): a coat is a few big, smooth forms; it breaks into locks only where it leaves the outline -
the ruff, the cheeks, the elbows, the brush of a tail - and those locks are broad, soft and all
groomed one way.  No noise sprinkled over the whole skin: at the distance a battle is seen from it
only makes the shape look crumpled.

Everything is in Godot space (+X the animal's left, +Y up, +Z forward), like the rest of the kit.
"""
import math

from kit import V
from sculpt import smooth


class ChainFrame:
    """Frames along a polyline (a tail, a neck): ``at(t)`` for the chain parameter t = 0 .. n-1
    returns (centre, tangent, side, up), the up vector kept as close to world up as it can be."""

    def __init__(self, pts, up=(0.0, 1.0, 0.0)):
        self.pts = [V(p) for p in pts]
        self.up0 = V(up)

    def at(self, t):
        n = len(self.pts)
        t = max(0.0, min(n - 1.0, t))
        i = min(n - 2, int(t))
        u = t - i
        c = self.pts[i].lerp(self.pts[i + 1], u)
        a = self.pts[max(0, i - 1)]
        b = self.pts[min(n - 1, i + 2)]
        d0 = (self.pts[i + 1] - a).normalized()
        d1 = (b - self.pts[i]).normalized()
        d = d0.lerp(d1, u).normalized()
        side = d.cross(self.up0)
        if side.length < 1e-4:
            side = d.cross(V(0, 0, 1))
        side.normalize()
        up = side.cross(d).normalized()
        return c, d, side, up

    def angle(self, p, t):
        """Angle of point p round the chain at t: 0 on top, +pi/2 on the side."""
        c, d, side, up = self.at(t)
        q = p - c
        q = q - d * q.dot(d)
        return math.atan2(q.dot(side), q.dot(up))


def brush(frame, n_locks=7, amp=0.012, twist=0.6, t_end=None, tip=0.75, phase=0.0):
    """A displacement for a clay chain built on `frame` (a tail): soft locks running along it -
    rounded ridges that twist a little - so the outline of the brush breaks into a few clumps of
    fur instead of a sausage, strongest in the middle, fading at the root and gathering to a point
    at the tip."""
    def post(p, info):
        t = info.t
        te = t_end if t_end is not None else len(frame.pts) - 1.0
        k = t / max(1e-6, te)
        a = frame.angle(p, t)
        ridge = 0.5 + 0.5 * math.cos(n_locks * a + twist * t * 2.0 + phase)
        ridge = ridge ** 2
        env = smooth(0.0, 0.25, k) * (1.0 - 0.6 * smooth(tip, 1.0, k))
        return info.n * (amp * env * (ridge - 0.35))
    return post


def scallops(down=V(0.0, -0.45, -1.0), freq=14.0, amp=0.02, rows_jitter=0.35, share=None):
    """Shingled clumps of a ruff or a mane: rows of rounded scallops, each lying over the next in
    the direction `down` (back and down along the neck), so the edge reads as fur locks but the
    surface stays calm.  `share` (a tag) limits it to where that tag dominates."""
    dn = V(down).normalized()

    def post(p, info):
        w = 1.0
        if share is not None:
            w = smooth(0.3, 0.7, info.share(share))
            if w <= 0.0:
                return None
        nn = info.n
        a = math.atan2(nn.x, nn.y)
        u = p.dot(dn) * freq + rows_jitter * math.sin(a * 5.0)
        f = u - math.floor(u)
        # a rounded lock: rises quickly, rounds over, drops at its tip
        prof = math.sin(math.pi * min(1.0, f * 1.15)) ** 0.7 * smooth(0.0, 0.25, f)
        return nn * (amp * w * prof)
    return post


def combine(*posts):
    """Run several displacement functions and add their offsets."""
    def post(p, info):
        out = None
        for f in posts:
            if f is None:
                continue
            o = f(p, info)
            if o is not None:
                out = o if out is None else out + o
        return out
    return post


def flame(b, base, up, size, bone, bend=0.0, side=None, core="ffffff", seg=10):
    """A tongue of spirit fire (fox-fire, a qilin's flames): a teardrop swelling from `base` and
    licking up along `up` to a point, bent a little sideways, with a paler core inside it.  The
    outer flame burns in the palette's accent colour (glow material, tinted); the core keeps its
    own colour."""
    from kit import CRYSTAL, MAT_GLOW
    up = V(up).normalized()
    if side is None:
        side = up.cross(V(0, 0, 1))
        if side.length < 1e-3:
            side = V(1, 0, 0)
    side = V(side).normalized()
    pts = [base - up * size * 0.12, base + up * size * 0.2, base + up * size * 0.5 + side * size * 0.12 * bend,
           base + up * size * 0.78 - side * size * 0.06 * bend, base + up * size * 1.0 + side * size * 0.1 * bend]
    radii = [size * 0.08, size * 0.3, size * 0.26, size * 0.14, size * 0.01]
    old = b.cur_pal
    b.cur_pal = 1.0
    b.tube(pts, radii, "f0f0f0", cls=CRYSTAL, bone=bone, seg=seg, mat=MAT_GLOW, tint=1.0)
    b.cur_pal = old
    inner = [base + up * size * 0.05, base + up * size * 0.22, base + up * size * 0.45 + side * size * 0.06 * bend, base + up * size * 0.62]
    b.tube(inner, [size * 0.06, size * 0.15, size * 0.1, size * 0.01], core, cls=CRYSTAL, bone=bone, seg=8, mat=MAT_GLOW, tint=0.0)


def lip_line(hit, hf, K, zs, x_out=0.2, y_top=-0.01, y_bot=-0.09, step=0.0015):
    """Where the built upper muzzle ends, seen from the side: for every station z (head-local, in
    units of K) the lowest height y_b at which a ray cast from the side still meets the head, and
    the half-width x_b there.  A lower jaw fitted to these closes the mouth flush, however the
    clay polygoniser rounded the thin lip forms.  Returns [(z, y_b, x_b)]."""
    Mt = hf.M.transposed()
    out = []
    for z in zs:
        last = None
        y = y_top
        while y > y_bot:
            o = hf.at(x_out * K, y * K, z * K)
            h = hit(o, -hf.r, x_out * K * 1.5)
            if h is not None:
                q = Mt @ (h[0] - hf.c) / K
                if q.x > 0.0:
                    last = (z, y, q.x)
            elif last is not None:
                break
            y -= step
        if last is not None:
            out.append(last)
    return out


def cat_nose(b, c, fwd, w, h, col, bone, up=(0.0, 1.0, 0.0), depth=0.14, nostril="1a0c0a"):
    """A big cat's nose leather: a broad, flat inverted triangle with a groove down the middle and
    comma nostrils at its lower corners - flatter than anatomy.nose_pad's, so it reads as leather
    on the end of the bridge rather than a ball."""
    from anatomy import euler_of, frame_m
    from kit import MAT_PLAIN, SKIN, lighten
    from mathutils import Matrix
    from sculpt import morph_sphere
    M = frame_m(fwd, up)

    def shape(dd):
        x, y, z = dd.x, dd.y, dd.z
        px = x * w * 0.5 * (1.0 - 0.62 * smooth(0.3, -1.0, y))
        py = y * h * 0.5
        pz = z * w * depth
        if z > 0:
            pz -= 0.04 * w * math.exp(-(x * 7.0) ** 2) * smooth(0.3, -0.8, y)
        return M @ V(px, py, pz)

    morph_sphere(b, V(c), shape, lambda p, dd: mix_c(col, lighten(col, 0.22), smooth(0.2, 0.9, dd.y)), cls=SKIN, bone=bone, seg=14, rings=10)
    for s in (1, -1):
        q = V(c) + M @ V(s * w * 0.24, -h * 0.18, w * depth * 0.7)
        b.ellipsoid(q, (w * 0.09, h * 0.14, w * 0.04), nostril, cls=SKIN, bone=bone, rot=euler_of(M @ Matrix.Rotation(0.6 * s, 3, "Z")), seg=8, rings=5, mat=MAT_PLAIN)


def mix_c(a, b2, t):
    from kit import mix
    return mix(a, b2, t)


def human_head(b, c, fwd, k, bone, up=(0.0, 1.0, 0.0), skin=(0.86, 0.68, 0.54), hair="1c1416", res=0.006, beard=0.0, band="c83a2a",
               knot=(0.0, 1.0), brow_tilt=0.35, name="face", jaw_bone=None, gold="e0b040", crown=False, eye_col="3a2416"):
    """A stern human head sculpted in clay (a guardian's face, after the warriors of the
    terracotta army): a round cranium, a heavy brow, cheekbones, a straight nose with flared
    wings, full lips over a strong chin, ears; the hair drawn up from a clean hairline into a
    topknot tied with a band (`knot`: its offset to the side and up, in head units); thick
    brows angled down to the nose; eyes under their lids; a drooping moustache and, with `beard`
    (a length), a beard.  `k` scales a head about 0.25 m tall; it faces `fwd`.  The skin and
    hair keep their own colours (tint 0)."""
    from anatomy import frame_m, lock
    from clay import Clay
    from kit import HAIR, MAT_PLAIN, METAL, SKIN, darken, mix, rgb
    M = frame_m(fwd, up)
    f = M @ V(0, 0, 1)
    u = M @ V(0, 1, 0)
    rr = M @ V(1, 0, 0)
    c = V(c)

    def at(x, y, z):
        return c + M @ V(x * k, y * k, z * k)

    bw = bone if isinstance(bone, dict) else {bone: 1.0}
    cl = Clay(res, name)
    E = cl.ellipsoid
    E(at(0, 0.028, -0.012), (0.074 * k, 0.084 * k, 0.084 * k), rot=M, bones=bw, tag="skull")
    E(at(0, -0.03, 0.028), (0.06 * k, 0.066 * k, 0.06 * k), rot=M, bones=bw, tag="face")
    E(at(0, -0.072, 0.044), (0.044 * k, 0.03 * k, 0.04 * k), rot=M, bones=bw, tag="face")
    for s in (1, -1):
        E(at(0.043 * s, -0.004, 0.054), (0.026 * k, 0.02 * k, 0.024 * k), rot=M, bones=bw, tag="face")
        E(at(0.074 * s, -0.01, -0.004), (0.011 * k, 0.026 * k, 0.017 * k), rot=M, bones=bw, tag="ear")
        E(at(0.026 * s, 0.008, 0.079), (0.017 * k, 0.011 * k, 0.012 * k), rot=M, bones=bw, tag="face", neg=True)
        E(at(0.012 * s, -0.029, 0.087), (0.0095 * k, 0.008 * k, 0.009 * k), rot=M, bones=bw, tag="face")
    E(at(0, 0.03, 0.071), (0.058 * k, 0.016 * k, 0.022 * k), rot=M, bones=bw, tag="face")
    E(at(0, 0.0, 0.088), (0.011 * k, 0.03 * k, 0.014 * k), rot=M, bones=bw, tag="face")
    E(at(0, -0.026, 0.095), (0.015 * k, 0.012 * k, 0.014 * k), rot=M, bones=bw, tag="face")
    E(at(0, -0.049, 0.083), (0.024 * k, 0.0085 * k, 0.012 * k), rot=M, bones=bw, tag="lip")
    E(at(0, -0.061, 0.079), (0.02 * k, 0.0085 * k, 0.011 * k), rot=M, bones=bw, tag="lip")
    E(at(0, -0.087, 0.068), (0.023 * k, 0.017 * k, 0.017 * k), rot=M, bones=bw, tag="face")
    Mt = M.transposed()
    skin_d = darken(skin, 0.3)
    lipc = mix(skin, (0.62, 0.26, 0.24), 0.55)

    def col(p, info):
        q = Mt @ (p - c) / k
        if info.tag == "lip" or info.share("lip") > 0.45:
            return lipc
        # a little shadow under the brow and down the sides of the nose, warmth on the cheeks
        v = skin
        v = mix(v, skin_d, 0.35 * smooth(0.02, -0.06, q.z))
        v = mix(v, mix(skin, (0.85, 0.45, 0.4), 0.3), 0.6 * smooth(0.03, 0.015, math.hypot(abs(q.x) - 0.042, q.y + 0.02)))
        return v

    cl.build(b, col, cls=SKIN, tint_fn=lambda p, info: 0.0)
    # the hair: a cap over the crown and the back of the head from a clean hairline, drawn up
    # into a topknot tied with a band and pinned
    hc = Clay(res, name + "_hair")
    hc.ellipsoid(at(0, 0.04, -0.022), (0.079 * k, 0.078 * k, 0.083 * k), rot=M, bones=bw, tag="hair")
    hc.ellipsoid(at(0, 0.0, -0.05), (0.07 * k, 0.07 * k, 0.05 * k), rot=M, bones=bw, tag="hair")
    hc.ellipsoid(at(0, 0.048, 0.045), (0.062 * k, 0.042 * k, 0.03 * k), rot=M, bones=bw, tag="hair", neg=True)
    kx, ky = knot
    kc = at(0.03 * kx, 0.105 + 0.02 * ky, -0.03)
    hc.ball(kc, 0.034 * k, bones=bw, tag="hair")
    hc.build(b, lambda p, info: rgb(hair), cls=HAIR, tint_fn=lambda p, info: 0.0)
    b.tube([kc - u * 0.03 * k, kc - u * 0.012 * k], [0.03 * k, 0.03 * k], band, cls=SKIN, bone=bone if isinstance(bone, str) else max(bw, key=bw.get), seg=12)
    bname = bone if isinstance(bone, str) else max(bw, key=bw.get)
    b.tube([kc - rr * 0.06 * k + f * 0.01 * k, kc + rr * 0.06 * k + f * 0.01 * k], [0.004 * k, 0.004 * k], gold, cls=METAL, bone=bname, seg=6)
    if crown:
        # a gilded circlet over the brow
        ring = [at(math.sin(a) * 0.081, 0.056 + 0.01 * math.cos(a), math.cos(a) * 0.083 - 0.012) for a in [i / 16 * 2 * math.pi for i in range(17)]]
        b.tube(ring, [0.008 * k] * 17, gold, cls=METAL, bone=bname, seg=6, cap0=False, cap1=False)
        b.ball(at(0, 0.064, 0.072), 0.013 * k, "e04030", cls=SKIN, bone=bname, seg=10, rings=6)
    # brows, eyes, moustache, beard
    for s in (1, -1):
        b0 = at(0.008 * s, 0.03 - 0.008 * brow_tilt, 0.089)
        b1 = at(0.03 * s, 0.035, 0.088)
        b2 = at(0.05 * s, 0.035 + 0.006 * brow_tilt, 0.072)
        b.tube([b0, b1, b2], [0.008 * k, 0.0095 * k, 0.004 * k], hair, cls=HAIR, bone=bname, seg=6, mat=MAT_PLAIN)
        human_eye(b, at(0.026 * s, 0.009, 0.077), f + rr * (0.1 * s), 0.0125 * k, bname, up=u, iris=eye_col, side=s, open_=0.5, tilt=-0.1)
        m0 = at(0.006 * s, -0.04, 0.094)
        b.tube([m0, at(0.02 * s, -0.043, 0.092), at(0.032 * s, -0.055, 0.082), at(0.036 * s, -0.075, 0.072)], [0.0035 * k, 0.005 * k, 0.0035 * k, 0.001 * k],
               hair, cls=HAIR, bone=bname, seg=6, mat=MAT_PLAIN)
    if beard > 0.0:
        jb = jaw_bone or bname
        lock(b, at(0, -0.088, 0.07), -u * 0.9 + f * 0.15, f, beard * k, 0.035 * k, hair, darken(hair, 0.2), bone=jb, lift=0.1, rise=0.05, thick=0.5,
             tint=0.0, cls=HAIR)
        for s in (1, -1):
            lock(b, at(0.03 * s, -0.08, 0.055), (-u * 0.9 + f * 0.1 + rr * 0.15 * s).normalized(), f + rr * 0.5 * s, beard * 0.75 * k, 0.025 * k, hair,
                 darken(hair, 0.2), bone=jb, lift=0.1, rise=0.05, thick=0.5, tint=0.0, cls=HAIR)
    return at


def human_eye(b, c, fwd, r, bone, up=(0.0, 1.0, 0.0), iris="2a1a10", side=1, lid="140c0a", open_=0.55, tilt=0.0):
    """A human eye that reads at a distance: a white almond set in the socket, a large dark iris
    with a catchlight, a heavy upper lid line and a thin lower one."""
    from anatomy import euler_of, frame_m
    from kit import CRYSTAL, MAT_GLOW, MAT_PLAIN, SKIN
    from mathutils import Matrix
    M = frame_m(fwd, up) @ Matrix.Rotation(tilt * side, 3, "Z")
    rot = euler_of(M)
    c = V(c)
    b.ellipsoid(c, (r, r * open_, r * 0.5), "efe8dc", cls=SKIN, bone=bone, rot=rot, seg=14, rings=8, mat=MAT_PLAIN)
    ir = r * 0.52
    b.ellipsoid(c + M @ V(0, -r * 0.04, r * 0.36), (ir, min(ir, r * open_ * 0.95), r * 0.18), iris, cls=CRYSTAL, bone=bone, rot=rot, seg=12, rings=6, mat=MAT_PLAIN)
    b.ellipsoid(c + M @ V(-r * 0.16 * side, r * 0.14, r * 0.5), (r * 0.12, r * 0.1, r * 0.05), "ffffff", cls=CRYSTAL, bone=bone, rot=rot, seg=6, rings=4, mat=MAT_GLOW)
    top = [c + M @ V(math.cos(a) * r * 1.08, math.sin(a) * r * open_ * 1.1, r * 0.3) for a in [math.pi * i / 10 for i in range(11)]]
    b.tube(top, [r * 0.07] + [r * 0.17] * 9 + [r * 0.07], lid, cls=SKIN, bone=bone, seg=5, mat=MAT_PLAIN)
    bot = [c + M @ V(math.cos(a) * r * 1.0, -math.sin(a) * r * open_ * 1.0, r * 0.3) for a in [math.pi * (0.15 + 0.7 * i / 6) for i in range(7)]]
    b.tube(bot, [r * 0.05] * 7, lid, cls=SKIN, bone=bone, seg=4, mat=MAT_PLAIN)


def mask_face(b, c, fwd, k, bone, col="d8a840", line="2a1a10", up=(0.0, 1.0, 0.0), cls=None, tint=0.0, seg=22, rings=16, brow_tilt=0.4):
    """A small face like a gilded mask (after the gold-faced bronze heads of Sanxingdui): a
    squarish face with a straight brow ridge, great almond eyes slanting up at the corners, a
    long straight nose, a wide closed mouth, a firm chin and tab ears, with the eyes, brows and
    the line of the mouth inlaid dark so it reads from afar.  About 0.25 m tall at k = 1."""
    from anatomy import frame_m
    from kit import MAT_PLAIN, METAL, darken, lighten, mix
    from mathutils import Matrix
    from sculpt import blob3, morph_sphere
    cls = METAL if cls is None else cls
    M = frame_m(fwd, up)
    c = V(c)

    def at(x, y, z):
        return c + M @ V(x * k, y * k, z * k)

    def shape(d):
        p = V(d.x * 0.07, d.y * 0.09, d.z * 0.055)
        # a flat back, a square jaw
        if p.z < 0.0:
            p.z *= 0.3
        p.x *= 1.0 - 0.18 * smooth(-0.3, -1.0, d.y)
        q = p
        off = 0.0
        off += 0.012 * blob3(q, (0, 0.03, 0.05), (0.058, 0.01, 0.02))           # brow ridge
        off += 0.022 * blob3(q, (0, -0.005, 0.056), (0.011, 0.03, 0.02))        # nose
        off += 0.01 * blob3(q, (0, -0.03, 0.056), (0.018, 0.008, 0.015))        # nose wings
        off += 0.006 * blob3(q, (0, -0.05, 0.052), (0.03, 0.007, 0.012))        # lips
        off += 0.006 * blob3(q, (0, -0.078, 0.045), (0.024, 0.012, 0.012))      # chin
        for s in (1, -1):
            off -= 0.01 * blob3(q, (0.028 * s, 0.012, 0.052), (0.018, 0.009, 0.012))   # eyes
            off += 0.006 * blob3(q, (0.044 * s, -0.012, 0.042), (0.018, 0.014, 0.014))  # cheekbones
        return M @ ((p + p.normalized() * off) * k)

    def colf(p, d):
        return mix(darken(col, 0.3), lighten(col, 0.18), smooth(-0.5, 0.8, d.z))

    morph_sphere(b, c, shape, colf, cls=cls, bone=bone, seg=seg, rings=rings, tint_fn=lambda p, d: tint)
    for s in (1, -1):
        # tab ears
        b.ellipsoid(at(0.068 * s, 0.0, 0.0), (0.012 * k, 0.03 * k, 0.02 * k), col, cls=cls, bone=bone, rot=_rot(M), seg=8, rings=6, tint=tint)
        # great almond eyes slanting up at the outer corners
        Me = M @ Matrix.Rotation(0.28 * s, 3, "Z")
        b.ellipsoid(at(0.028 * s, 0.012, 0.056), (0.017 * k, 0.0062 * k, 0.004 * k), line, cls=METAL, bone=bone, rot=_rot(Me), seg=10, rings=5, mat=MAT_PLAIN)
        # straight brows rising to the temples
        b.tube([at(0.008 * s, 0.03 - 0.006 * brow_tilt, 0.064), at(0.03 * s, 0.035, 0.062), at(0.054 * s, 0.042 + 0.006 * brow_tilt, 0.048)],
               [0.0045 * k, 0.005 * k, 0.003 * k], line, cls=METAL, bone=bone, seg=5, mat=MAT_PLAIN)
    # the line of the closed mouth
    b.tube([at(-0.028, -0.054, 0.05), at(-0.012, -0.049, 0.06), at(0.012, -0.049, 0.06), at(0.028, -0.054, 0.05)],
           [0.0015 * k, 0.003 * k, 0.003 * k, 0.0015 * k], line, cls=METAL, bone=bone, seg=5, mat=MAT_PLAIN)
    return at


def _rot(M):
    from anatomy import euler_of
    return euler_of(M)
