"""Carp: the golden koi of the Hanging Falls and the river carp of the Nine Bends (Part VI).  A koi
swimming through the air, after the fish (FishBase's Cyprinus carpio; the koi breeders' anatomy):

* a fusiform body, deepest a third of the way back, its back gently arched before the dorsal fin,
  laterally compressed and tapering to a narrow tail stalk; a blunt, rounded, scaleless head with
  the edge of the gill cover behind it;
* a small mouth at the front of the snout with fleshy lips (on the jaw bone, so it gapes) and two
  short pairs of barbels, the upper on the lip and the longer at its corners (a carp's, not a
  catfish's whiskers);
* large cycloid scales in neat offset rows that follow the body, each with a darker free edge, so
  the flank reads as a net of overlapping scales; a lateral line of pored scales down each side;
* one long, low dorsal fin, tallest at its front ray, running down the back; a forked tail with
  rounded lobes; rounded paddle pectorals low behind the gill cover; pelvic and anal fins - every fin
  a soft membrane with its rays drawn in, a little longer and more flowing than a pond koi's;
* a koi's markings: white patches (they keep their colour) over the colour the game gives it, a
  pale belly and a darker back.

The body is a loft (not clay) so the scales are painted in the body's own coordinates, and it uses
the smooth surface class: the shader's "scale" class draws a grid of its own, which is what made the
old carp a chequerboard.  The body is a five-bone chain so it swims with a travelling wave.
Clips: idle (swimming in place), walk (swimming forward), attack (a lunge and a gape), hurt, die
(rolls belly-up and sinks to the ground) and cast (arches like a carp leaping the Dragon Gate).
Run: blender --background --python art/monsters/carp.py  ->  assets/monsters/carp.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import anatomy as A  # noqa: E402
from creature import add, chain_weights, zero_pose  # noqa: E402
from sculpt import catmull, fbm3, loft, smooth, strand  # noqa: E402
from kit import CLOTH, CRYSTAL, MAT_GLOW, MAT_PLAIN, SKIN, THIN, V, Builder, Rig, env, euler_g, lin  # noqa: E402
from mathutils import Quaternion  # noqa: E402
from creature import euler_yxz  # noqa: E402

kit.reset()
creature.realtime()
Y = 1.05
Z0, Z1 = 0.95, -1.0          # snout tip, end of the tail stalk
r = Rig("rig")
r.bone("root", (0, 0, 0), (0, 0.3, 0))
zs = [0.75, 0.38, 0.0, -0.38, -0.72, -1.02]
for i in range(5):
    r.bone("body%d" % i, (0, Y, zs[i]), (0, Y, zs[i + 1]), "root" if i == 0 else "body%d" % (i - 1))
r.bone("tailfin", (0, Y, zs[5]), (0, Y, zs[5] - 0.4), "body4")
r.bone("jaw", (0, Y - 0.035, 0.84), (0, Y - 0.05, 0.98), "body0")
for s, sd in ((1, "L"), (-1, "R")):
    r.bone("pec." + sd, (0.15 * s, Y - 0.12, 0.42), (0.36 * s, Y - 0.3, 0.2), "body0")
    r.bone("pelv." + sd, (0.1 * s, Y - 0.2, -0.12), (0.26 * s, Y - 0.38, -0.32), "body2")
b = Builder("carp")


def body_bone(z):
    f = 0.0
    for i in range(5):
        if zs[i + 1] <= z <= zs[i]:
            f = i + (zs[i] - z) / (zs[i] - zs[i + 1])
            break
    if z > zs[0]:
        f = 0.0
    if z < zs[5]:
        f = 4.99
    return chain_weights("body", f, 5)


# ---------------------------------------------------------------- the body: a loft in body coordinates
# (s from the snout 0 to the tail stalk 1; a the angle round the body from the top of the back)
H_PTS = [(0.0, 0.0), (0.02, 0.085), (0.06, 0.145), (0.12, 0.195), (0.2, 0.235), (0.3, 0.258), (0.4, 0.26), (0.5, 0.245),
         (0.62, 0.2), (0.74, 0.145), (0.85, 0.1), (0.93, 0.078), (1.0, 0.07)]


def interp(pts, s):
    for i in range(len(pts) - 1):
        a, b2 = pts[i], pts[i + 1]
        if s <= b2[0]:
            t = (s - a[0]) / (b2[0] - a[0])
            t = t * t * (3 - 2 * t)
            return a[1] + (b2[1] - a[1]) * t
    return pts[-1][1]


def half_h(s):
    return interp(H_PTS, s)


def half_w(s):
    # a blunt round head, a compressed body, a narrow stalk
    return half_h(s) * (0.82 - 0.2 * smooth(0.12, 0.35, s) - 0.1 * smooth(0.7, 1.0, s))


def centre_y(s):
    return Y + 0.025 * math.sin(math.pi * min(1.0, s * 1.2)) - 0.01


def zof(s):
    return Z0 + (Z1 - Z0) * s


OPER = 0.215     # where the gill cover ends


def section_pt(s, a):
    h, w = half_h(s), half_w(s)
    ca, sa = math.cos(a), math.sin(a)
    # a ridged back (narrower at the top), a full round belly
    x = w * sa * (1.0 - 0.18 * max(0.0, ca) ** 3)
    y = h * ca * (1.04 if ca > 0 else 0.96)
    # the gill cover stands a little proud of the body just in front of its edge
    so = OPER + 0.03 * ca
    k = 1.0 + 0.025 * smooth(so - 0.05, so - 0.005, s) * (1.0 - smooth(so - 0.005, so + 0.004, s))
    return V(x * k, centre_y(s) + y * k, zof(s))


NR, NA = 190, 104
SS = [0.004 + 0.996 * (j / (NR - 1)) ** 1.08 for j in range(NR)]
rings = [[section_pt(s, 2 * math.pi * i / NA) for i in range(NA)] for s in SS]

# scales: offset rows of round scales whose free (rear) edges show; the anterior scale lies on top
N_ALONG, N_ROUND, S_SC = 24, 22, 0.25


def scale_edge(s, a):
    """0 inside a scale .. 1 on the dark free edge of the scale that lies on top here."""
    if s < S_SC:
        return 0.0, 0.0
    u = (s - S_SC) / (1.0 - S_SC) * N_ALONG
    v = (a / (2 * math.pi)) * N_ROUND
    best = None
    for k in (-1, 0, 1):
        cu = math.floor(u) + k
        off = 0.5 * (cu % 2)
        for m in (-1, 0, 1):
            cv = math.floor(v - off) + m + off
            d = math.hypot((u - cu) * 1.0, (v - cv) * 1.05)
            if d < 0.74 and (best is None or cu < best[0]):
                best = (cu, d)
    if best is None:
        return 1.0, 1.0
    d = best[1]
    return smooth(0.5, 0.72, d), d / 0.74


def koi_white(s, a):
    """White koi patches (they keep their colour): a blaze on the head, two saddles on the back,
    the belly."""
    ca = math.cos(a)
    side = abs(math.sin(a))
    n = 0.12 * (fbm3((s * 9.0, ca * 3.0, side * 3.0), 2, 21) - 0.5)
    blaze = smooth(0.06, 0.0, abs(s - 0.06) - 0.04) * smooth(0.55, 0.85, ca)
    sad1 = smooth(0.1, 0.0, math.hypot((s - 0.33) * 1.6, (ca - 0.85) * 0.35) - 0.07 + n)
    sad2 = smooth(0.08, 0.0, math.hypot((s - 0.66) * 1.4, (ca - 0.6) * 0.3) - 0.07 + n)
    belly = smooth(-0.25, -0.5, ca + n)
    return max(blaze, sad1, sad2, belly)


def body_sa(p):
    """Body coordinates (s, a) of a point on the loft."""
    s = max(0.0, min(1.0, (p.z - Z0) / (Z1 - Z0)))
    h, w = max(1e-4, half_h(s)), max(1e-4, half_w(s))
    a = math.atan2(p.x / w, (p.y - centre_y(s)) / h)
    return s, (a if a >= 0 else a + 2 * math.pi)


def white_k(s, a):
    return smooth(0.35, 0.65, koi_white(s, a))


def body_col(p, j, i):
    s = SS[j]
    a = 2 * math.pi * i / NA
    ca = math.cos(a)
    v = 0.94 - 0.12 * smooth(0.3, 0.95, ca)            # a darker back
    edge, rad = scale_edge(s, a)
    if s >= S_SC:
        v *= 1.0 - 0.13 * edge - 0.05 * (1.0 - rad)     # each scale shaded from its base, its free edge rimmed dark
    # the gill cover's edge, and the lateral line
    so = OPER + 0.03 * ca
    v *= 1.0 - 0.18 * smooth(0.01, 0.0, abs(s - so)) * smooth(0.95, 0.6, abs(ca))
    ll = smooth(0.06, 0.0, abs(ca - 0.1 - 0.05 * math.sin(s * 3.0))) * smooth(S_SC, S_SC + 0.05, s) * (1.0 - edge)
    v *= 1.0 - 0.18 * ll * (0.5 + 0.5 * math.cos(((s - S_SC) / (1.0 - S_SC) * N_ALONG) * 2 * math.pi))
    # the white patches keep a faint trace of the scales
    wk = white_k(*body_sa(p))
    vw = 0.98 * (1.0 - 0.05 * edge)
    v = v * (1.0 - wk) + vw * wk
    return (v, v, v)


def body_tint(p):
    return 1.0 - white_k(*body_sa(p))


b.cur_pal = 0.0
loft(b, rings, (0.9, 0.9, 0.9), cls=CLOTH, col_fn=body_col, bone_fn=lambda p: body_bone(p.z), tint_fn=body_tint, cap0=True, cap1=True, cap_push=0.5)


def on_body(s, a, lift=0.0):
    """A point on the body surface (and its outward normal-ish direction)."""
    p = section_pt(s, a)
    c = V(0, centre_y(s), zof(s))
    n = (p - c).normalized()
    return p + n * lift, n


# ---------------------------------------------------------------- the face
b.cur_pal = 0.0
for s_ in (1, -1):
    # the eye: high on the side of the head, a gold ring round a dark pupil, slightly domed
    ep, en = on_body(0.085, 1.05 if s_ > 0 else 2 * math.pi - 1.05, 0.0)
    ef = (en * 0.85 + V(0, 0, 0.35)).normalized()
    A.animal_eye(b, ep + en * 0.004, ef, 0.034, "e8b040", "body0", pupil="round", almond=0.98, side=s_, lid="2a1a12", lid_w=0.07, glow=False, accent=False)
    # nostrils before the eye
    npnt, nn = on_body(0.035, 0.75 if s_ > 0 else 2 * math.pi - 0.75, 0.0)
    b.ellipsoid(npnt, (0.012, 0.009, 0.01), "2a1418", cls=SKIN, bone="body0", seg=8, rings=5, mat=MAT_PLAIN)
# the mouth: fleshy lips round a small dark gape at the front of the snout, on the jaw
mc = V(0, Y - 0.045, Z0 - 0.012)
lips = []
for k in range(25):
    t = 2 * math.pi * k / 24
    lips.append(mc + V(math.cos(t) * 0.042, math.sin(t) * 0.026, -0.01 * (1.0 + math.sin(t)) * 0.5))
b.tube(lips, [0.012] * 25, "f2c8b0", cls=SKIN, bone="jaw", seg=8, cap0=False, cap1=False, tint=0.35)
b.ellipsoid(mc + V(0, 0, 0.002), (0.042, 0.026, 0.012), "2a0e12", cls=SKIN, bone="jaw", seg=12, rings=6, mat=MAT_PLAIN)
# two short pairs of barbels: on the upper lip, and longer at the corners of the mouth
for s_ in (1, -1):
    r0 = mc + V(0.035 * s_, 0.02, -0.012)
    strand(b, [r0, r0 + V(0.03 * s_, -0.03, 0.01), r0 + V(0.05 * s_, -0.065, 0.0)], 0.009, 0.004, "f0c4a8", cls=SKIN, bone="jaw", seg=6, per=3, tint=0.35)
    r1 = mc + V(0.052 * s_, -0.012, -0.03)
    strand(b, [r1, r1 + V(0.04 * s_, -0.04, -0.01), r1 + V(0.07 * s_, -0.09, -0.04), r1 + V(0.08 * s_, -0.13, -0.08)], 0.011, 0.004, "f0c4a8",
           cls=SKIN, bone="jaw", seg=6, per=3, tint=0.35)


# ---------------------------------------------------------------- the fins
def fin(rays, bones, n_rows=9, col=0.96, edge=1.0, ray_dark=0.84, tint_root=1.0, tint_edge=0.35, wave=0.0, wave_n=None):
    """A soft fin: `rays` are polylines from the root to the free edge (catmull-smoothed and
    resampled to n_rows points), joined by a double-sided membrane.  The membrane pales towards its
    edge (its tint falls, so the authored white shows through: a translucent rim) and every ray is a
    darker line along it.  `bones(p, t)` weights each point."""
    nr = n_rows
    res = []
    for ry in rays:
        cp = catmull(ry, 4)
        acc = [0.0]
        for k in range(len(cp) - 1):
            acc.append(acc[-1] + (cp[k + 1] - cp[k]).length)
        out = []
        for j in range(nr):
            sl = acc[-1] * j / (nr - 1)
            for k in range(len(cp) - 1):
                if sl <= acc[k + 1] or k == len(cp) - 2:
                    u = min(1.0, (sl - acc[k]) / max(1e-6, acc[k + 1] - acc[k]))
                    out.append(cp[k].lerp(cp[k + 1], u))
                    break
        res.append(out)
    nc = len(res)
    # insert a membrane column between every two rays so the rays read as lines
    cols_pts = []
    is_ray = []
    for c in range(nc):
        cols_pts.append(res[c])
        is_ray.append(True)
        if c < nc - 1:
            cols_pts.append([res[c][j].lerp(res[c + 1][j], 0.5) + (wave_n * (wave * math.sin(c * 2.1 + j * 0.9) * j / (nr - 1)) if wave_n is not None else V(0, 0, 0)) for j in range(nr)])
            is_ray.append(False)
    ncol = len(cols_pts)
    verts, cols, tints, bws = [], [], [], []
    for j in range(nr):
        t = j / (nr - 1)
        for c in range(ncol):
            p = cols_pts[c][j]
            verts.append(p)
            g = col + (edge - col) * smooth(0.5, 1.0, t)
            if is_ray[c]:
                g *= ray_dark + (1.0 - ray_dark) * smooth(0.8, 1.0, t)
            cols.append((g, g, g))
            tints.append(tint_root + (tint_edge - tint_root) * smooth(0.35, 1.0, t))
            bws.append(bones(p, t))
    faces = []
    for j in range(nr - 1):
        for c in range(ncol - 1):
            a0 = j * ncol + c
            faces.append((a0, a0 + 1, a0 + ncol + 1, a0 + ncol))
    # double-sided: offset front and back along the face normals
    import mathutils
    nrm = []
    for j in range(nr):
        for c in range(ncol):
            pa = cols_pts[min(ncol - 1, c + 1)][j] - cols_pts[max(0, c - 1)][j]
            pb = cols_pts[c][min(nr - 1, j + 1)] - cols_pts[c][max(0, j - 1)]
            nn = pa.cross(pb)
            nrm.append(nn.normalized() if nn.length > 1e-9 else mathutils.Vector((1, 0, 0)))
    th = 0.004
    front = [verts[k] + nrm[k] * th for k in range(len(verts))]
    back = [verts[k] - nrm[k] * th for k in range(len(verts))]
    cl = [lin(c_, CLOTH + THIN) for c_ in cols]
    b.add(front, faces, (0.9, 0.9, 0.9), CLOTH, None, 0.0, 0, True, cols=cl, tints=tints, bones=bws, closed=False)
    clb = [(c_[0] * 0.8, c_[1] * 0.8, c_[2] * 0.8, c_[3]) for c_ in cl]
    b.add(back, [tuple(reversed(f)) for f in faces], (0.9, 0.9, 0.9), CLOTH, None, 0.0, 0, True, cols=clb, tints=tints, bones=bws, closed=False)


b.cur_pal = 0.5   # the fins take the secondary colour
# the dorsal fin: one long low fin down the back, tallest at its front ray
rays = []
N_D = 17
for k in range(N_D):
    u = k / (N_D - 1)
    s = 0.36 + 0.43 * u
    root, _ = on_body(s, 0.0, -0.01)
    hgt = 0.27 * (1.0 - 0.72 * u ** 0.8) * (1.0 - 0.2 * smooth(0.0, 0.08, 0.08 - u)) + 0.02
    lean = V(0, 1.0, -0.62 - 0.4 * u).normalized()
    tip = root + lean * hgt
    rays.append([root, root.lerp(tip, 0.5) + V(0, 0, -0.012 * k ** 0.5), tip])
fin(rays, lambda p, t: body_bone(p.z), n_rows=8, wave=0.012, wave_n=V(1, 0, 0))
# the anal fin, small, under the tail stalk
rays = []
for k in range(7):
    u = k / 6
    s = 0.77 + 0.1 * u
    root, _ = on_body(s, math.pi, -0.01)
    hgt = 0.13 * (1.0 - 0.6 * u) + 0.02
    tip = root + V(0, -1.0, -0.8).normalized() * hgt
    rays.append([root, tip])
fin(rays, lambda p, t: body_bone(p.z), n_rows=6)
# the tail: forked, the lobes long and rounded, rays fanning from the stalk
rays = []
N_T = 21
end = V(0, centre_y(1.0), Z1 + 0.02)
for k in range(N_T):
    u = k / (N_T - 1) * 2.0 - 1.0          # -1 lower lobe .. 1 upper lobe
    ang = u * 0.95
    L = 0.3 + 0.36 * abs(u) ** 1.4 - 0.05 * smooth(0.85, 1.0, abs(u))
    d = V(0, math.sin(ang), -math.cos(ang))
    root = end + V(0, u * 0.055, 0.03)
    tip = root + d * L
    mid = root.lerp(tip, 0.5) + V(0, 0.02 * u, 0)
    rays.append([root, mid, tip])


def tail_w(p, t):
    k = smooth(0.0, 0.35, t)
    return {"body4": 1.0 - k, "tailfin": k} if k < 0.999 else {"tailfin": 1.0}


fin(rays, tail_w, n_rows=10, wave=0.02, wave_n=V(1, 0, 0))
# pectoral fins: rounded paddles low behind the gill cover; pelvic fins on the belly
for s_, sd in ((1, "L"), (-1, "R")):
    rays = []
    base_s = 0.25
    for k in range(11):
        u = k / 10
        root, nb = on_body(base_s + 0.025 * u, (2.05 + 0.25 * u) if s_ > 0 else 2 * math.pi - (2.05 + 0.25 * u), -0.004)
        d = V(0.55 * s_, -0.55 - 0.2 * u, -0.5 - 0.5 * u).normalized()
        L = 0.3 * (0.55 + 0.45 * math.sin(math.pi * min(1.0, 0.25 + u * 0.8)))
        rays.append([root, root + d * (L * 0.5) + V(0.02 * s_, 0, 0), root + d * L])
    fin(rays, lambda p, t, sd=sd: {"body0": 1.0 - smooth(0.0, 0.3, t), "pec." + sd: smooth(0.0, 0.3, t)} if t < 0.3 else {"pec." + sd: 1.0}, n_rows=8)
    rays = []
    for k in range(9):
        u = k / 8
        root, nb = on_body(0.5 + 0.03 * u, (2.75 + 0.1 * u) if s_ > 0 else 2 * math.pi - (2.75 + 0.1 * u), -0.006)
        d = V(0.4 * s_, -0.7, -0.6 - 0.4 * u).normalized()
        L = 0.22 * (0.6 + 0.4 * math.sin(math.pi * min(1.0, 0.2 + u * 0.85)))
        rays.append([root, root + d * L])
    fin(rays, lambda p, t, sd=sd: {"body2": 1.0 - smooth(0.0, 0.3, t), "pelv." + sd: smooth(0.0, 0.3, t)} if t < 0.3 else {"pelv." + sd: 1.0}, n_rows=6)
b.cur_pal = 0.0

# a few pearl bubbles rising from the mouth
for k, (dx, dy, rr) in enumerate(((0.01, 0.07, 0.018), (-0.015, 0.16, 0.013), (0.02, 0.26, 0.01))):
    b.ball(mc + V(dx, dy, 0.03 + 0.015 * k), rr, "f0f8ff", cls=CRYSTAL, bone="jaw", seg=8, rings=5, mat=MAT_GLOW)


T_IDLE = 2.4


def swim(p, t, speed, amp, hover=0.05, fin=1.3, pelv=1.1, bob=0.5, fin_amp=1.0):
    """Travelling wave down the body.  Loops pass fin/pelv/bob ratios that give whole cycles."""
    for i in range(5):
        p["body%d" % i] = ((0, math.sin(t * speed - i * 0.9) * amp * (0.4 + i * 0.25), 0), (0, 0, 0))
    p["tailfin"] = ((0, math.sin(t * speed - 5 * 0.9) * amp * 1.8, 0), (0, 0, 0))
    p["root"] = ((math.sin(t * speed * bob) * 0.04, 0, 0), (0, math.sin(t * speed * bob) * hover, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["pec." + sd] = ((math.sin(t * speed * fin) * 0.3 * fin_amp, 0, math.sin(t * speed * fin + 0.5) * 0.25 * s * fin_amp), (0, 0, 0))
        p["pelv." + sd] = ((math.sin(t * speed * pelv + 1.0) * 0.2 * fin_amp, 0, 0), (0, 0, 0))


def idle(t):
    p = zero_pose(r)
    swim(p, t, 2 * math.pi / T_IDLE * 2, 0.12, fin=1.5, pelv=1.0, bob=0.5)
    p["jaw"] = ((0.08 + 0.1 * max(0.0, math.sin(t * 2 * math.pi / T_IDLE * 3)), 0, 0), (0, 0, 0))
    return p


def attack(t):
    k = t / 0.55
    e = env(k)
    lunge = math.sin(min(1.0, k * 1.5) * math.pi)
    p = zero_pose(r)
    # the thrash builds and settles with the strike instead of snapping back to the idle swim
    swim(p, t, 16.0, 0.08 + 0.14 * e)
    p["root"] = ((0.15 * lunge, 0, 0), (0, 0.1 * lunge, 0.6 * lunge))
    p["jaw"] = ((0.6 * lunge, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = zero_pose(r)
    swim(p, t, 20.0, 0.25 * e)
    p["root"] = ((-0.3 * e, 0, 0.4 * e), (0, 0, -0.15 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = zero_pose(r)
    # leap: arch the body like a carp climbing the dragon gate
    for i in range(5):
        p["body%d" % i] = ((-0.12 * e, 0, 0), (0, 0, 0))
    p["tailfin"] = ((-0.3 * e, 0, 0), (0, 0, 0))
    # (about its own middle, not about the ground under it)
    R = euler_g((-0.35 * e, 0, 0))
    c0 = V(0, Y, 0)
    p["root"] = (euler_yxz(R), tuple(c0 - R @ c0 + V(0, 0.55 * e, 0)))
    return p


T_WALK = 1.2


def walk(t):
    """Swims through the air: a stronger travelling wave and beating pectoral fins."""
    p = zero_pose(r)
    swim(p, t, 2 * math.pi / T_WALK, 0.18, hover=0.04, fin=2.0, pelv=1.0, bob=1.0)
    add(p, "root", (0.06, 0, 0))
    return p


REST = 0.2


def die(t):
    """Thrashes, rolls onto its side and sinks to the ground, where it lies still, fins folded.
    (It rolls about its own spine, not about the ground under it, so it ends lying on the ground
    rather than sunk into it.)"""
    k = min(1.0, t / 1.2)
    f = smooth(0.15, 0.8, k) ** 1.3
    roll = smooth(0.1, 0.6, k)
    p = zero_pose(r)
    swim(p, t, 20.0 * (1.0 - f) + 0.5, 0.25 * (1.0 - f), hover=0.05 * (1.0 - f), fin_amp=1.0 - f)
    R = euler_g((0.0, 0.0, 1.5 * roll))
    c0 = V(0, Y, 0)
    B = V(0, Y + (REST - Y) * f, 0)
    p["root"] = (euler_yxz(R), tuple(B - R @ c0))
    for i in range(5):
        add(p, "body%d" % i, (0.0, -0.035 * f, 0.0))
    # the paired fins fold back flat along the flanks
    for sd, s in (("L", 1), ("R", -1)):
        for nm, tgt in (("pec." + sd, V(0.12 * s, -0.12, -1.0)), ("pelv." + sd, V(0.08 * s, -0.1, -1.0))):
            h, tl, _ = r.bones[nm]
            M = (tl - h).normalized().rotation_difference(tgt.normalized()).to_matrix()
            q = M.to_quaternion()
            p[nm] = (euler_yxz(Quaternion().slerp(q, f).to_matrix()), (0, 0, 0))
    return p


print("[art] carp: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/carp.glb", {"idle": (T_IDLE, idle), "walk": (T_WALK, walk), "attack": (0.55, attack), "hurt": (0.55, hurt), "die": (1.2, die), "cast": (0.6, cast)}, samples=16, dist=0.3, strength=0.45)
