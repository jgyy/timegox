"""Rigs, kinematics and animation clips shared by the monster scripts in ``art/monsters``.

Monster meshes are authored mostly in greys with tint weight 1, so the game can recolour one mesh
for every enemy of that shape (``Assets.monster(shape, colour)``).  Eyes, teeth, claws and glowing
parts keep their own colours (tint 0).

Every monster exports the same five clips the game plays - ``idle`` (loop), ``walk`` (loop, in
place: the game moves the model), ``attack`` (0.55 s), ``hurt`` (0.55 s) and ``die`` (about 1.2 s,
ending still on the ground) - plus whatever extra clips it already had (cast, fly, swim).

Kinematics
----------
Clips are baked from Python functions of time returning ``{bone: (rot, loc[, scale])}`` with
Godot Euler rotations in the parent's frame (see ``kit.bake_action``).  ``Poser`` evaluates the
same poses forward, so a clip can ask where a hip or a shoulder *is* in a given frame and solve
the leg below it with inverse kinematics (``leg_ik`` for the sagittal limbs of mammals and birds,
``limb_ik`` for any two-bone limb in its own plane, splayed insect legs included).  Feet are
planted where they touch the ground and roll heel-to-toe, instead of swinging stiffly from the
hip.

Gaits (after animation references for four-legged walks: a lateral-sequence walk sets the feet
down hind-left, fore-left, hind-right, fore-right a quarter cycle apart; hips and chest rise and
fall like two bouncing balls out of phase; the head nods with the forefeet; the tail is the end of
the spine and follows through with a lag instead of whipping; every cycle is symmetric and its last
frame equals its first):

* ``QuadMotion`` - idle, walk, attack, hurt and die for any four-legged rig built by ``quad_rig2``.
* ``Gait`` - the per-leg stance/swing timing used by the quadruped and by many-legged walkers.
"""

import math

from mathutils import Matrix

from kit import CRYSTAL, MAT_GLOW, MAT_PLAIN, STONE, Rig, V, auto_weights, euler_g

TAU = 2.0 * math.pi


def smooth(a, b, x):
    if a == b:
        return 0.0 if x < a else 1.0
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3.0 - 2.0 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def bump(x, c, w):
    """0..1..0 cosine window of half-width w around c."""
    d = abs(x - c) / w
    return 0.5 + 0.5 * math.cos(math.pi * d) if d < 1.0 else 0.0


def wrap(a):
    while a > math.pi:
        a -= TAU
    while a < -math.pi:
        a += TAU
    return a


def euler_yxz(R):
    """Godot Euler angles (order YXZ) of a 3x3 rotation in Godot space (inverse of kit.euler_g)."""
    m12 = max(-1.0, min(1.0, R[1][2]))
    x = math.asin(-m12)
    if abs(m12) < 0.9999:
        y = math.atan2(R[0][2], R[2][2])
        z = math.atan2(R[1][0], R[1][1])
    else:
        y = math.atan2(-R[2][0], R[0][0])
        z = 0.0
    return (x, y, z)


# ---------------------------------------------------------------- pose dictionaries
def zero_pose(rig):
    return {nm: ((0, 0, 0), (0, 0, 0)) for nm in rig.bones}


def add(p, nm, rot=(0.0, 0.0, 0.0), loc=(0.0, 0.0, 0.0), scl=None):
    """Add a rotation / offset to bone nm in pose p (missing bones are ignored)."""
    if nm is None or nm not in p:
        return
    old = p[nm]
    r = (old[0][0] + rot[0], old[0][1] + rot[1], old[0][2] + rot[2])
    o = (old[1][0] + loc[0], old[1][1] + loc[1], old[1][2] + loc[2])
    if scl is not None:
        p[nm] = (r, o, tuple(scl))
    elif len(old) > 2:
        p[nm] = (r, o, old[2])
    else:
        p[nm] = (r, o)


def mix_pose(a, b, k):
    """Blend two poses (Euler components linearly - fine for the moderate angles used here)."""
    out = {}
    for nm in a:
        ra, la = a[nm][0], a[nm][1]
        rb, lb = b.get(nm, a[nm])[0], b.get(nm, a[nm])[1]
        sa = a[nm][2] if len(a[nm]) > 2 else (1.0, 1.0, 1.0)
        sb = b[nm][2] if (nm in b and len(b[nm]) > 2) else (1.0, 1.0, 1.0)
        r = tuple(ra[i] + (rb[i] - ra[i]) * k for i in range(3))
        lo = tuple(la[i] + (lb[i] - la[i]) * k for i in range(3))
        s = tuple(sa[i] + (sb[i] - sa[i]) * k for i in range(3))
        out[nm] = (r, lo, s) if any(abs(x - 1.0) > 1e-6 for x in s) else (r, lo)
    return out


# ---------------------------------------------------------------- forward kinematics
class Poser:
    """Forward kinematics of a kit.Rig for a pose dict.  ``fk(pose)`` returns, per bone, the 4x4
    transform (Godot space) taking a rest-pose point attached to that bone to its posed position,
    using exactly the conventions of ``kit.bake_action``."""

    def __init__(self, rig):
        self.rig = rig
        self.names = list(rig.bones)

    def fk(self, pose):
        D = {}
        for nm in self.names:
            h, t, par = self.rig.bones[nm]
            val = pose.get(nm)
            if val is None:
                L = Matrix.Identity(4)
            else:
                rot, loc = val[0], val[1]
                L = Matrix.Translation(h + V(loc)) @ euler_g(rot).to_4x4() @ Matrix.Translation(-h)
            D[nm] = D[par] @ L if par is not None else L
        return D


def _ang(u, v):
    return math.atan2(v, u)


def leg_ik(rig, D, chain, parent, ball, meta=0.0, toe=0.0):
    """Sagittal inverse kinematics for a limb chain [upper, lower, meta(, toe)] hanging from
    `parent`: put the far end of `meta` (the ball of the foot, the knuckles, the fetlock) at the
    world point `ball`, the metapodial pitched by `meta` and the toes by `toe` (radians about X
    relative to their rest direction in world space; positive swings a bone's far end backwards /
    downwards).  The bend keeps its rest direction (stifle forward, hock back, elbow back).  Returns
    {bone: (rot, loc)} X rotations to merge into the pose."""
    up, lo, mt = chain[0], chain[1], chain[2]
    tb = chain[3] if len(chain) > 3 else None
    H0 = rig.bones[up][0]
    K0 = rig.bones[lo][0]
    A0 = rig.bones[mt][0]
    P0 = rig.bones[mt][1]
    Dp = D[parent] if parent is not None else Matrix.Identity(4)
    Rp = Dp.to_3x3().normalized()
    Rpi = Rp.transposed()
    bl = Dp.inverted() @ V(ball)
    m0 = P0 - A0
    mW = Matrix.Rotation(meta, 3, "X") @ m0
    mL = Rpi @ mW
    lm = math.hypot(m0.z, m0.y)
    lm2 = math.hypot(mL.z, mL.y) or 1.0
    mz, my = mL.z / lm2 * lm, mL.y / lm2 * lm
    az, ay = bl.z - mz, bl.y - my
    hz, hy = H0.z, H0.y
    L1 = math.hypot(K0.z - H0.z, K0.y - H0.y)
    L2 = math.hypot(A0.z - K0.z, A0.y - K0.y)
    dz, dy = az - hz, ay - hy
    d = math.hypot(dz, dy)
    dmin = abs(L1 - L2) + 1e-4
    dmax = (L1 + L2) * 0.9995
    if d < 1e-6:
        dz, dy, d = 0.0, -1.0, 1.0
    dc = min(dmax, max(dmin, d))
    ca = (L1 * L1 + dc * dc - L2 * L2) / (2.0 * L1 * dc)
    a = math.acos(max(-1.0, min(1.0, ca)))
    base = _ang(dz, dy)
    az2, ay2 = hz + dz / d * dc, hy + dy / d * dc
    rest_cross = (K0.z - H0.z) * (A0.y - K0.y) - (K0.y - H0.y) * (A0.z - K0.z)
    best = None
    for sgn in (1.0, -1.0):
        kz = hz + L1 * math.cos(base + sgn * a)
        ky = hy + L1 * math.sin(base + sgn * a)
        cr = (kz - hz) * (ay2 - ky) - (ky - hy) * (az2 - kz)
        if best is None or (cr * rest_cross > 0 and not (best[2] * rest_cross > 0)):
            best = (kz, ky, cr)
    kz, ky, _ = best
    du = -wrap(_ang(kz - hz, ky - hy) - _ang(K0.z - H0.z, K0.y - H0.y))
    dl = -wrap(_ang(az2 - kz, ay2 - ky) - _ang(A0.z - K0.z, A0.y - K0.y))
    dm = -wrap(_ang(mz, my) - _ang(m0.z, m0.y))
    out = {up: ((du, 0.0, 0.0), (0, 0, 0)), lo: ((dl - du, 0.0, 0.0), (0, 0, 0)), mt: ((dm - dl, 0.0, 0.0), (0, 0, 0))}
    if tb is not None:
        t0 = rig.bones[tb][1] - rig.bones[tb][0]
        tL = Rpi @ (Matrix.Rotation(toe, 3, "X") @ t0)
        dt = -wrap(_ang(tL.z, tL.y) - _ang(t0.z, t0.y))
        out[tb] = ((dt - dm, 0.0, 0.0), (0, 0, 0))
    return out


def knee_ik(rig, D, up, lo, parent, target):
    """Sagittal two-bone IK for upright legs (bipeds, hoppers): X rotations of `up` and `lo`
    that put the far end of `lo` at the world point `target`, the knee keeping its rest side.
    Lateral offsets stay as rigged, so a nearly straight leg never yaws out of its plane."""
    H0 = rig.bones[up][0]
    K0 = rig.bones[lo][0]
    F0 = rig.bones[lo][1]
    Dp = D[parent] if parent is not None else Matrix.Identity(4)
    tl = Dp.inverted() @ V(target)
    hz, hy = H0.z, H0.y
    L1 = math.hypot(K0.z - hz, K0.y - hy)
    L2 = math.hypot(F0.z - K0.z, F0.y - K0.y)
    dz, dy = tl.z - hz, tl.y - hy
    d = math.hypot(dz, dy)
    if d < 1e-6:
        dz, dy, d = 0.0, -1.0, 1.0
    dc = min((L1 + L2) * 0.9995, max(abs(L1 - L2) + 1e-4, d))
    ca = (L1 * L1 + dc * dc - L2 * L2) / (2.0 * L1 * dc)
    a = math.acos(max(-1.0, min(1.0, ca)))
    base = _ang(dz, dy)
    fz, fy = hz + dz / d * dc, hy + dy / d * dc
    rest_cross = (K0.z - hz) * (F0.y - K0.y) - (K0.y - hy) * (F0.z - K0.z)
    best = None
    for sgn in (1.0, -1.0):
        kz = hz + L1 * math.cos(base + sgn * a)
        ky = hy + L1 * math.sin(base + sgn * a)
        cr = (kz - hz) * (fy - ky) - (ky - hy) * (fz - kz)
        if best is None or (cr * rest_cross > 0 and not (best[2] * rest_cross > 0)):
            best = (kz, ky, cr)
    kz, ky, _ = best
    du = -wrap(_ang(kz - hz, ky - hy) - _ang(K0.z - hz, K0.y - hy))
    dl = -wrap(_ang(fz - kz, fy - ky) - _ang(F0.z - K0.z, F0.y - K0.y))
    return {up: ((du, 0.0, 0.0), (0, 0, 0)), lo: ((dl - du, 0.0, 0.0), (0, 0, 0))}


def limb_ik(rig, D, a, b, parent, target, swing_axis=(0.0, 1.0, 0.0), swing=True):
    """Two-bone IK in the limb's own rest plane (splayed insect and spider legs, arms): bone `a`
    swings about `swing_axis` through its head to face the target, then the two bones fold in
    their plane to reach it.  Returns {bone: (rot, loc)}."""
    H0 = rig.bones[a][0]
    K0 = rig.bones[b][0]
    F0 = rig.bones[b][1]
    Dp = D[parent] if parent is not None else Matrix.Identity(4)
    T = Dp.inverted() @ V(target)
    ax = V(swing_axis).normalized()
    R_sw = Matrix.Identity(3)
    if swing:
        # yaw about the swing axis so the limb plane contains the target
        def flat(v):
            return v - ax * v.dot(ax)
        f0 = flat(F0 - H0)
        ft = flat(T - H0)
        if f0.length > 1e-6 and ft.length > 1e-6:
            ang = math.atan2(f0.cross(ft).dot(ax), f0.dot(ft))
            R_sw = Matrix.Rotation(ang, 3, ax)
    # work in the swung rest plane
    K1 = H0 + R_sw @ (K0 - H0)
    F1 = H0 + R_sw @ (F0 - H0)
    n = (K1 - H0).cross(F1 - K1)
    if n.length < 1e-8:
        n = R_sw @ V(1, 0, 0)
    n.normalize()
    L1 = (K0 - H0).length
    L2 = (F0 - K0).length
    dv = T - H0
    dv = dv - n * dv.dot(n)
    d = dv.length
    dc = min((L1 + L2) * 0.999, max(abs(L1 - L2) + 1e-4, d))
    if d < 1e-6:
        dv = F1 - H0
        d = dv.length
    dirv = dv / d
    ca = (L1 * L1 + dc * dc - L2 * L2) / (2.0 * L1 * dc)
    ang_a = math.acos(max(-1.0, min(1.0, ca)))
    # the knee lies on the same side of the hip-foot line as in the rest pose
    side = n.cross(dirv).normalized()
    rest_side = (K1 - H0) - dirv * (K1 - H0).dot(dirv)
    if rest_side.dot(side) < 0:
        side = -side
    K = H0 + dirv * (math.cos(ang_a) * L1) + side * (math.sin(ang_a) * L1)
    F = H0 + dirv * dc
    q1 = (K1 - H0).normalized().rotation_difference((K - H0).normalized())
    R1 = q1.to_matrix() @ R_sw
    # second bone, relative to the first
    k_dir_after = R1 @ (F0 - K0).normalized()
    q2 = k_dir_after.rotation_difference((F - K).normalized())
    R2_world = q2.to_matrix() @ R1
    R2_local = R1.transposed() @ R2_world
    return {a: (euler_yxz(R1), (0, 0, 0)), b: (euler_yxz(R2_local), (0, 0, 0))}


# ---------------------------------------------------------------- gait timing
class Gait:
    """Stance/swing timing for one foot.  `td` is the phase (0..1 of the cycle) at which the foot
    touches down, `duty` the share of the cycle it spends on the ground."""

    def __init__(self, td, duty):
        self.td = td
        self.duty = duty

    def at(self, ph):
        u = (ph - self.td) % 1.0
        if u < self.duty:
            return True, u / self.duty
        return False, (u - self.duty) / (1.0 - self.duty)


def foot_path(stance, s, stride, lift, reach=0.0):
    """Offset (dz, dy) of a foot from its rest point: on the ground it slides back from +stride/2
    to -stride/2 (the body moves over it); in the air it arcs forward, highest early in the swing."""
    if stance:
        return stride * (0.5 - s), 0.0
    e = s * s * (3.0 - 2.0 * s)
    z = stride * (-0.5 + e) + reach * math.sin(math.pi * s)
    y = lift * math.sin(math.pi * min(1.0, s / 0.92))
    return z, y


# ---------------------------------------------------------------- the four-legged rig
class LegSpec:
    def __init__(self, chain, parent, front, side, td):
        self.chain = chain
        self.parent = parent
        self.front = front
        self.side = side
        self.td = td


class QuadSkel:
    """Joint positions of a four-legged animal (Godot space, facing +Z, left legs at +X).  Build
    one with ``quad_skel`` and adjust any point before calling ``quad_rig2``."""

    def __init__(self):
        self.pts = {}

    def __getitem__(self, k):
        return self.pts[k]

    def __setitem__(self, k, v):
        self.pts[k] = V(v)


def quad_skel(H=0.8, hip_z=-0.42, sh_z=0.42, hip_w=0.13, sh_w=0.12, foot="digit", neck=None, head=None, tail=None,
              withers=0.06, croup=0.0, tail_n=6):
    """Joint layout from the height of the back H.  Front leg: scapula top over the withers, the
    shoulder joint in front of it, the elbow behind at the bottom of the chest, the wrist low and
    the paw on the ground; hind leg: hip joint under the croup, stifle forward, hock back and high,
    long metatarsus to the paw.  `foot`: "digit" (paws), "hoof", "plant" (flat feet)."""
    s = QuadSkel()
    s.H = H
    s.foot = foot
    s["back_h"] = (0, H + croup, hip_z)
    s["back_f"] = (0, H + withers, sh_z)
    s["body"] = (0, H, (hip_z + sh_z) * 0.5)
    s["loin"] = (0, H + croup * 0.5, hip_z + (sh_z - hip_z) * 0.22)
    s["pelvis"] = (0, H - 0.06 * H + croup, hip_z + 0.04 * H)
    s["chest"] = (0, H + withers * 0.5, (hip_z + sh_z) * 0.5 + (sh_z - hip_z) * 0.15)
    for sd, sg in (("L", 1), ("R", -1)):
        hx = hip_w * sg
        fx = sh_w * sg
        if foot == "hoof":
            s["sc." + sd] = (fx * 0.8, H + withers - 0.04 * H, sh_z - 0.1 * H)
            s["sh." + sd] = (fx, 0.66 * H, sh_z + 0.06 * H)
            s["el." + sd] = (fx, 0.5 * H, sh_z - 0.06 * H)
            s["wr." + sd] = (fx, 0.24 * H, sh_z - 0.02 * H)
            s["fb." + sd] = (fx, 0.1 * H, sh_z + 0.0 * H)
            s["ft." + sd] = (fx, 0.0, sh_z + 0.05 * H)
            s["hip." + sd] = (hx, 0.86 * H + croup, hip_z)
            s["kn." + sd] = (hx, 0.58 * H, hip_z + 0.12 * H)
            s["hk." + sd] = (hx, 0.3 * H, hip_z - 0.12 * H)
            s["hb." + sd] = (hx, 0.1 * H, hip_z - 0.07 * H)
            s["ht." + sd] = (hx, 0.0, hip_z - 0.03 * H)
        elif foot == "plant":
            s["sc." + sd] = (fx * 0.8, H + withers - 0.04 * H, sh_z - 0.08 * H)
            s["sh." + sd] = (fx, 0.72 * H, sh_z + 0.03 * H)
            s["el." + sd] = (fx, 0.42 * H, sh_z - 0.05 * H)
            s["wr." + sd] = (fx, 0.1 * H, sh_z + 0.01 * H)
            s["fb." + sd] = (fx, 0.02 * H, sh_z + 0.1 * H)
            s["ft." + sd] = (fx, 0.0, sh_z + 0.17 * H)
            s["hip." + sd] = (hx, 0.84 * H + croup, hip_z)
            s["kn." + sd] = (hx, 0.48 * H, hip_z + 0.1 * H)
            s["hk." + sd] = (hx, 0.1 * H, hip_z - 0.02 * H)
            s["hb." + sd] = (hx, 0.02 * H, hip_z + 0.12 * H)
            s["ht." + sd] = (hx, 0.0, hip_z + 0.2 * H)
        else:
            s["sc." + sd] = (fx * 0.8, H + withers - 0.03 * H, sh_z - 0.1 * H)
            s["sh." + sd] = (fx, 0.64 * H, sh_z + 0.04 * H)
            s["el." + sd] = (fx, 0.44 * H, sh_z - 0.07 * H)
            s["wr." + sd] = (fx, 0.14 * H, sh_z - 0.02 * H)
            s["fb." + sd] = (fx, 0.035 * H, sh_z + 0.03 * H)
            s["ft." + sd] = (fx, 0.02 * H, sh_z + 0.1 * H)
            s["hip." + sd] = (hx, 0.8 * H + croup, hip_z)
            s["kn." + sd] = (hx, 0.52 * H, hip_z + 0.13 * H)
            s["hk." + sd] = (hx, 0.25 * H, hip_z - 0.12 * H)
            s["hb." + sd] = (hx, 0.035 * H, hip_z - 0.05 * H)
            s["ht." + sd] = (hx, 0.02 * H, hip_z + 0.03 * H)
    nb = V(0, H + withers + 0.02 * H, sh_z + 0.08 * H)
    s["neck0"] = nb
    s["neck1"] = neck[0] if neck else nb + V(0, 0.18 * H, 0.16 * H)
    s["head"] = neck[1] if neck else s["neck1"] + V(0, 0.08 * H, 0.14 * H)
    s["snout"] = head if head else s["head"] + V(0, -0.06 * H, 0.32 * H)
    if tail is None:
        tb = V(0, H + croup - 0.02 * H, hip_z - 0.1 * H)
        tail = [tb + V(0, -0.12 * H * k * k * 0.25, -0.2 * H * k) for k in range(tail_n + 1)]
    s.tail = [V(p) for p in tail]
    return s


def quad_rig2(s, ears=None, extra=None, jaw=True, toes=True):
    """The four-legged rig on a QuadSkel:

        root - body - loin - pelvis - tail0..tailN, h_up/h_lo/h_meta/h_toe.L/R
                    \\- chest - neck0 - neck1 - head - jaw, ear.L/R
                             \\- shoulder.L/R - f_up/f_lo/f_meta/f_toe.L/R

    Returns (rig, legs) where legs are LegSpecs for the lateral-sequence walk."""
    r = Rig("rig")
    r.bone("root", (0, 0, 0), (0, 0.3, 0))
    r.bone("body", s["body"], s["body"] + V(0, 0, 0.1), "root")
    r.bone("loin", s["body"], s["loin"], "body")
    r.bone("pelvis", s["loin"], s["pelvis"] + V(0, 0, -0.15 * s.H), "loin")
    r.bone("chest", s["body"], s["chest"] + V(0, 0, 0.2 * s.H), "body")
    r.bone("neck0", s["neck0"], s["neck1"], "chest")
    r.bone("neck1", s["neck1"], s["head"], "neck0")
    r.bone("head", s["head"], s["snout"], "neck1")
    if jaw:
        hv = (s["snout"] - s["head"])
        r.bone("jaw", s["head"] + hv * 0.18 + V(0, -0.1 * s.H, 0), s["snout"] + V(0, -0.1 * s.H, 0), "head")
    if ears:
        for sd, (a, b2) in zip(("L", "R"), ears):
            r.bone("ear." + sd, a, b2, "head")
    prev = "pelvis"
    for i in range(len(s.tail) - 1):
        r.bone("tail%d" % i, s.tail[i], s.tail[i + 1], prev)
        prev = "tail%d" % i
    legs = []
    for sd, sg in (("L", 1), ("R", -1)):
        r.bone("shoulder." + sd, s["sc." + sd], s["sh." + sd], "chest")
        r.bone("f_up." + sd, s["sh." + sd], s["el." + sd], "shoulder." + sd)
        r.bone("f_lo." + sd, s["el." + sd], s["wr." + sd], "f_up." + sd)
        r.bone("f_meta." + sd, s["wr." + sd], s["fb." + sd], "f_lo." + sd)
        ch = ["f_up." + sd, "f_lo." + sd, "f_meta." + sd]
        if toes:
            r.bone("f_toe." + sd, s["fb." + sd], s["ft." + sd], "f_meta." + sd)
            ch.append("f_toe." + sd)
        legs.append(LegSpec(ch, "shoulder." + sd, True, sg, 0.25 if sg > 0 else 0.75))
        r.bone("h_up." + sd, s["hip." + sd], s["kn." + sd], "pelvis")
        r.bone("h_lo." + sd, s["kn." + sd], s["hk." + sd], "h_up." + sd)
        r.bone("h_meta." + sd, s["hk." + sd], s["hb." + sd], "h_lo." + sd)
        ch = ["h_up." + sd, "h_lo." + sd, "h_meta." + sd]
        if toes:
            r.bone("h_toe." + sd, s["hb." + sd], s["ht." + sd], "h_meta." + sd)
            ch.append("h_toe." + sd)
        legs.append(LegSpec(ch, "pelvis", False, sg, 0.0 if sg > 0 else 0.5))
    if extra:
        for e in extra:
            r.bone(*e)
    return r, legs


def tail_names(rig, prefix="tail"):
    out = []
    i = 0
    while "%s%d" % (prefix, i) in rig.bones:
        out.append("%s%d" % (prefix, i))
        i += 1
    return out


# ---------------------------------------------------------------- four-legged motion
class QuadMotion:
    """Idle, walk, attack, hurt and die for a quad_rig2 rig.  `style` tunes the character:

    T_walk, stride, lift, duty      walk timing and footfall (stride in metres)
    bob, roll, yaw, pitch            hip/chest motion amplitudes (m, rad)
    head_nod, head_low, neck_up      head carriage
    tail_amp, tail_lift, tail_lag    tail carriage and follow-through
    crouch                           how low the body is carried while walking (m)
    pounce                           attack style: "pounce" (forepaws), "bite", "ram", "rear"
    pant                             jaw opening in the idle
    """

    def __init__(self, rig, legs, **style):
        self.rig = rig
        self.legs = legs
        self.poser = Poser(rig)
        self.st = dict(T_walk=1.2, stride=0.36, lift=0.07, duty=0.62, bob=0.012, roll=0.03, yaw=0.05, pitch=0.025,
                       head_nod=0.05, head_low=0.0, neck_up=0.0, tail_amp=0.12, tail_lift=0.0, tail_lag=0.7, tail_droop=0.0,
                       crouch=0.0, pounce="pounce", pant=0.0, T_idle=4.0, ear_flick=0.35, front_flex=1.3, hind_flex=0.55,
                       reach=0.03, side_fall=1, rest_h=None, gallop=False, lunge=0.4, die_T=1.2)
        self.st.update(style)
        self.tail = tail_names(rig)
        self.H = rig.bones["body"][0].y
        self.ears = [e for e in ("ear.L", "ear.R") if e in rig.bones]

    def zero(self):
        return zero_pose(self.rig)

    # ---- feet
    def plant(self, p, offsets=None, metas=None, toes=None, carried=None):
        """Solve every leg with IK: each foot at its rest point plus offsets[i] = (dz, dy) in world
        space (root motion included).  carried[i] = (w, (dx, dy, dz)) blends a foot by w towards
        its rest point carried along with the leg's parent plus that offset in the parent's rest
        frame, for feet lifted with the body (rearing, raking)."""
        D = self.poser.fk(p)
        for i, leg in enumerate(self.legs):
            mt = leg.chain[2]
            rest_ball = V(self.rig.bones[mt][1])
            ball = rest_ball
            if offsets is not None:
                dz, dy = offsets[i][0], offsets[i][1]
                dx = offsets[i][2] if len(offsets[i]) > 2 else 0.0
                ball = ball + V(dx, dy, dz)
            if carried is not None and carried[i] is not None and carried[i][0] > 0.0:
                w, off = carried[i]
                ball = ball.lerp(D[leg.parent] @ (rest_ball + V(off)), w)
            res = leg_ik(self.rig, D, leg.chain, leg.parent, ball, metas[i] if metas else 0.0, toes[i] if toes else 0.0)
            for nm, val in res.items():
                p[nm] = val
        return p

    # ---- body helpers
    def _spine(self, p, hips_y, chest_y, roll_h, roll_f, yaw_h, yaw_f, sway=0.0, pitch_extra=0.0):
        H = self.H
        length = (self.rig.bones["chest"][1] - self.rig.bones["loin"][1]).length or 1.0
        pitch = -math.atan2(chest_y - hips_y, length) + pitch_extra
        add(p, "body", (pitch, (yaw_f + yaw_h) * 0.25, 0.0), (sway, (hips_y + chest_y) * 0.5, 0.0))
        add(p, "loin", (0.0, (yaw_h - yaw_f) * 0.3, 0.0))
        add(p, "pelvis", (0.0, yaw_h * 0.5, roll_h))
        add(p, "chest", (0.0, (yaw_f - yaw_h) * 0.3, roll_f))
        return pitch

    def _tail(self, p, ph, amp, lift=0.0, lag=None, vamp=0.0, droop=0.0, w2=1.0):
        lag = self.st["tail_lag"] if lag is None else lag
        n = len(self.tail)
        for i, nm in enumerate(self.tail):
            k = (i + 1) / n
            yaw = amp * (0.35 + 0.9 * k) * math.sin(TAU * ph - i * lag)
            pit = lift * (1.0 - k * 0.6) - droop * k + vamp * math.sin(TAU * ph * w2 - i * lag)
            add(p, nm, (pit, yaw, 0.0))

    def _ears(self, p, t, T, amp=None):
        amp = self.st["ear_flick"] if amp is None else amp
        if not self.ears:
            return
        # a quick flick of one ear, later the other, inside every idle loop
        for k, (nm, at) in enumerate(zip(self.ears, (0.31, 0.72))):
            u = (t / T - at) % 1.0
            f = math.sin(math.pi * min(1.0, u / 0.06)) if u < 0.06 else 0.0
            add(p, nm, (-0.3 * f * amp, 0.0, (amp if k == 0 else -amp) * f))

    # ---- clips
    def idle(self, t):
        st = self.st
        T = st["T_idle"]
        ph = t / T
        p = self.zero()
        br = math.sin(TAU * ph * 3)          # three slow breaths per loop
        shift = math.sin(TAU * ph)           # weight shifts from side to side
        look = math.sin(TAU * ph + 0.6)
        self._spine(p, 0.004 * br * self.H - st["crouch"] * 0.3, 0.008 * br * self.H - st["crouch"] * 0.3, 0.012 * shift, -0.01 * shift, 0.0, 0.0, 0.012 * shift * self.H)
        add(p, "chest", (0.012 * br, 0.0, 0.0))
        # the eyes lead, the head turns first and the neck follows a beat later
        add(p, "neck0", (-st["neck_up"] + 0.02 * math.sin(TAU * ph * 2), 0.12 * math.sin(TAU * ph - 0.5), 0.0))
        add(p, "neck1", (0.0, 0.1 * math.sin(TAU * ph - 0.3), 0.0))
        add(p, "head", (st["head_low"] * 0.3 + 0.03 * math.sin(TAU * ph * 2 + 1.0), 0.16 * look, 0.05 * look))
        add(p, "jaw", (0.03 + st["pant"] * (0.5 + 0.5 * math.sin(TAU * ph * 6)), 0.0, 0.0))
        self._tail(p, ph * 2, st["tail_amp"] * 0.7, st["tail_lift"], droop=st["tail_droop"])
        self._ears(p, t, T)
        return self.plant(p)

    def walk(self, t):
        st = self.st
        T = st["T_walk"]
        ph = (t / T) % 1.0
        p = self.zero()
        duty = st["duty"]
        # two bouncing balls: the hips are highest at hind mid-stance, the chest a quarter later
        hb = st["bob"] * math.cos(TAU * 2 * (ph - duty * 0.5)) - st["crouch"]
        cb = st["bob"] * math.cos(TAU * 2 * (ph - 0.25 - duty * 0.5)) - st["crouch"]
        # the hip of the swinging hind leg drops and swings forward; the shoulders do the same
        roll_h = -st["roll"] * math.cos(TAU * (ph - (duty + 1.0) * 0.5))
        roll_f = -st["roll"] * 0.7 * math.cos(TAU * (ph - 0.25 - (duty + 1.0) * 0.5))
        yaw_h = st["yaw"] * math.sin(TAU * (ph - (duty + 1.0) * 0.5))
        yaw_f = -st["yaw"] * math.sin(TAU * (ph - 0.25 - (duty + 1.0) * 0.5))
        sway = 0.01 * self.H * math.sin(TAU * (ph - 0.1))
        pitch = self._spine(p, hb, cb, roll_h, roll_f, yaw_h, yaw_f, sway)
        # the head stays level against the body's pitch and nods as each forefoot lands
        nod = st["head_nod"] * math.cos(TAU * 2 * (ph - 0.25 - 0.05))
        add(p, "neck0", (-pitch * 0.6 - st["neck_up"] + st["head_low"], -yaw_f * 0.6, 0.0))
        add(p, "neck1", (nod * 0.4, -yaw_f * 0.3, 0.0))
        add(p, "head", (nod * 0.6 - st["head_low"] * 0.4, -yaw_f * 0.3, -roll_f * 0.5))
        add(p, "jaw", (0.04 + st["pant"] * (0.5 + 0.5 * math.sin(TAU * ph * 2)), 0.0, 0.0))
        for k, sd in enumerate(("shoulder.L", "shoulder.R")):
            leg = self.legs[0] if k == 0 else self.legs[2]
            on, s = Gait(leg.td, duty).at(ph)
            # the shoulder blade swings with its leg and rides up as the leg takes weight
            sw = -0.12 * math.cos(math.pi * s) if on else 0.12 * math.cos(math.pi * s)
            add(p, sd, (sw, 0.0, 0.0))
        self._tail(p, ph, st["tail_amp"], st["tail_lift"], droop=st["tail_droop"], vamp=0.04, w2=2.0)
        ear_b = 0.08 * math.sin(TAU * 2 * (ph - 0.3))
        for e in self.ears:
            add(p, e, (ear_b, 0.0, 0.0))
        offs, metas, toes = [], [], []
        for leg in self.legs:
            on, s = Gait(leg.td, duty).at(ph)
            dz, dy = foot_path(on, s, st["stride"], st["lift"] * (1.0 if leg.front else 0.85), st["reach"])
            offs.append((dz, dy))
            if on:
                heel = smooth(0.6, 1.0, s)
                m = (lerp(-0.12, 0.2, s) + 0.75 * heel) if leg.front else (lerp(-0.15, 0.15, s) + 0.6 * heel)
                tt = 0.0
            else:
                # the foot folds up as it leaves the ground and unfolds smoothly before it lands,
                # starting and ending where the stance leaves off and picks up
                flex = st["front_flex"] if leg.front else st["hind_flex"]
                fold = smooth(0.0, 0.4, s) * (1.0 - smooth(0.55, 0.92, s))
                m = flex * fold + lerp(0.95 if leg.front else 0.75, -0.12 if leg.front else -0.15, smooth(0.0, 0.35, s))
                tt = 0.7 * math.sin(math.pi * s)
            metas.append(m)
            toes.append(tt)
        return self.plant(p, offs, metas, toes)

    def attack(self, t, T=0.55):
        """Anticipation (crouch and draw back), strike, follow-through and recovery.  Styles:
        "pounce" (rear the forequarters and rake with both forepaws, then bite), "bite" (lunge
        with the head low, forefeet planted), "ram" (head down, a short charge), "rear" (stand on
        the hind legs and stamp down with the forefeet)."""
        st = self.st
        k = t / T
        H = self.H
        p = self.zero()
        ant = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.42, k))
        hit = smooth(0.28, 0.42, k) * (1.0 - smooth(0.62, 1.0, k))
        snap = bump(k, 0.45, 0.12)
        lunge = st["lunge"] * H
        style = st["pounce"]
        rz = -0.08 * H * ant + lunge * hit
        add(p, "root", (0.0, 0.0, 0.0), (0.0, -0.06 * H * ant, rz))
        # rearing: the forequarters lift through the anticipation and come down with the strike
        if style == "rear":
            lifted = smooth(0.0, 0.32, k) * (1.0 - smooth(0.4, 0.56, k))
            lowered = lifted
        else:
            lifted = smooth(0.06, 0.38, k) * (1.0 - smooth(0.5, 0.68, k))
            lowered = smooth(0.06, 0.38, k) * (1.0 - smooth(0.44, 0.62, k))
        rake = smooth(0.32, 0.5, k)
        land = smooth(0.4, 0.62, k) * (1.0 - smooth(0.7, 1.0, k))
        if style in ("rear", "pounce"):
            rise = (0.4 if style == "rear" else 0.22) * H * lowered
            self._spine(p, -0.08 * H * ant, -0.1 * H * ant + rise, 0.0, 0.0, 0.0, 0.0, 0.0)
        elif style == "ram":
            self._spine(p, -0.05 * H * ant, -0.12 * H * ant - 0.05 * H * hit, 0.0, 0.0, 0.0, 0.0, 0.0)
        else:
            self._spine(p, -0.06 * H * ant, -0.1 * H * ant - 0.04 * H * hit, 0.0, 0.0, 0.0, 0.0, 0.0)
        if style == "ram":
            add(p, "neck0", (0.3 * ant + 0.35 * hit, 0.0, 0.0))
            add(p, "head", (0.2 * ant + 0.45 * hit - 0.3 * snap, 0.0, 0.0))
        elif style == "bite":
            add(p, "neck0", (0.3 * ant - 0.15 * hit, 0.0, 0.0))
            add(p, "neck1", (-0.25 * hit, 0.0, 0.0))
            add(p, "head", (0.25 * ant + 0.3 * hit - 0.25 * snap, 0.0, 0.0))
        else:
            add(p, "neck0", (0.25 * ant - 0.1 * lifted + 0.3 * snap, 0.0, 0.0))
            add(p, "head", (0.15 * ant + 0.25 * lifted - 0.2 * snap, 0.0, 0.0))
        jaw_open = smooth(0.22, 0.4, k) * (1.0 - smooth(0.46, 0.6, k)) + 0.3 * smooth(0.6, 0.7, k) * (1.0 - smooth(0.75, 0.9, k))
        add(p, "jaw", (0.04 + (0.95 if style != "ram" else 0.3) * jaw_open, 0.0, 0.0))
        for e in self.ears:
            add(p, e, (0.6 * (ant + hit), 0.0, 0.0))
        self._tail(p, k * 2.0, st["tail_amp"] * 1.6, st["tail_lift"] + 0.35 * ant, droop=st["tail_droop"])
        offs, metas, toes, carried = [], [], [], []
        for leg in self.legs:
            if leg.front and style in ("pounce", "rear"):
                # the forelegs ride up with the forequarters: a rearing hoofed beast tucks them under
                # its chest and stamps down; a cat reaches forward and rakes down, claws out
                if style == "rear":
                    carried.append((lifted, (0.0, 0.26 * H * lifted, 0.08 * H * lifted)))
                    metas.append(1.0 * lifted)
                    toes.append(0.3 * lifted)
                else:
                    carried.append((lifted, (-0.02 * H * leg.side * lifted, (0.26 - 0.12 * rake) * H * lifted, (0.06 + 0.26 * rake) * H * lifted)))
                    metas.append((-0.2 - 0.5 * rake) * lifted)
                    toes.append(-0.6 * lifted)
                offs.append((rz * 0.85 + (0.14 * H * land if style == "pounce" else 0.0), 0.0))
                continue
            carried.append(None)
            if leg.front:
                offs.append((rz * 0.85, 0.0))
                metas.append(0.15 * hit)
                toes.append(0.0)
            else:
                offs.append((rz * 0.7, 0.0))
                metas.append(0.35 * hit + 0.15 * ant)
                toes.append(0.0)
        return self.plant(p, offs, metas, toes, carried)

    def hurt(self, t, T=0.55):
        st = self.st
        k = t / T
        e = math.sin(math.pi * min(1.0, k * 1.15)) if k < 0.87 else 0.0
        snap = bump(k, 0.18, 0.18)
        H = self.H
        p = self.zero()
        add(p, "root", (0.0, 0.0, 0.0), (0.02 * H * e, -0.04 * H * e, -0.12 * H * e))
        self._spine(p, -0.03 * H * e, 0.02 * H * e, 0.06 * e, -0.1 * e, 0.0, 0.12 * e, 0.0)
        add(p, "neck0", (-0.3 * e, 0.25 * e, 0.0))
        add(p, "neck1", (-0.1 * snap, 0.15 * e, 0.0))
        add(p, "head", (-0.15 * e, 0.2 * e, 0.15 * snap))
        add(p, "jaw", (0.35 * e, 0.0, 0.0))
        for i, e2 in enumerate(self.ears):
            add(p, e2, (0.7 * e, 0.0, (0.3 if i == 0 else -0.3) * e))
        self._tail(p, k, st["tail_amp"] * 0.5, st["tail_lift"], droop=st["tail_droop"] + 0.35 * e)
        offs = [(-0.12 * H * e, 0.0) for _ in self.legs]
        return self.plant(p, offs)

    def die(self, t):
        """Stagger, buckle, topple onto one side and lie still (non-looping)."""
        st = self.st
        T = st["die_T"]
        k = min(1.0, t / T)
        H = self.H
        sd = st["side_fall"]
        buckle = smooth(0.0, 0.35, k)
        fall = smooth(0.25, 0.72, k)
        settle = bump(k, 0.78, 0.07) * 0.5
        w = st["rest_h"] if st["rest_h"] is not None else 0.22 * H
        a = (1.45 * fall - 0.04 * settle) * sd
        p = self.zero()
        # roll about the line of the far feet on the ground, then rest on the flank
        q = -w * sd
        ca, sa = math.cos(a), math.sin(a)
        drop = (H * 0.25) * buckle * (1.0 - fall)
        add(p, "root", (0.0, 0.0, a), (q - ca * q, -sa * q - drop - 0.06 * H * fall, -0.05 * H * buckle))
        add(p, "body", (0.1 * buckle - 0.08 * fall, 0.0, 0.0))
        add(p, "chest", (0.08 * buckle, 0.0, 0.0))
        add(p, "loin", (-0.05 * fall, -0.1 * fall * sd, 0.0))
        # the neck sags and the head comes to rest on the ground
        add(p, "neck0", (0.45 * buckle - 0.2 * fall, -0.35 * fall * sd, 0.0))
        add(p, "neck1", (0.15 * buckle, -0.3 * fall * sd, 0.0))
        add(p, "head", (0.2 * buckle, -0.15 * fall * sd, -0.1 * fall * sd))
        add(p, "jaw", (0.25 * fall, 0.0, 0.0))
        for i, e in enumerate(self.ears):
            add(p, e, (0.6 * fall, 0.0, (0.2 if i == 0 else -0.2) * fall))
        n = len(self.tail)
        for i, nm in enumerate(self.tail):
            add(p, nm, (-0.12 * buckle, (-0.18 - 0.05 * i) * fall * sd / max(1, n) * 6, 0.0))
        # the legs buckle, then hang limp
        for leg in self.legs:
            up, lo, mt = leg.chain[0], leg.chain[1], leg.chain[2]
            if leg.front:
                add(p, up, (-0.35 * buckle + 0.15 * fall, 0.0, 0.1 * leg.side * fall))
                add(p, lo, (0.6 * buckle - 0.2 * fall, 0.0, 0.0))
                add(p, mt, (0.5 * buckle + 0.2 * fall, 0.0, 0.0))
            else:
                add(p, up, (0.45 * buckle - 0.1 * fall, 0.0, 0.08 * leg.side * fall))
                add(p, lo, (-0.5 * buckle + 0.15 * fall, 0.0, 0.0))
                add(p, mt, (0.35 * buckle, 0.0, 0.0))
            if len(leg.chain) > 3:
                add(p, leg.chain[3], (0.5 * fall, 0.0, 0.0))
        return p

    def clips(self, extra=None, T_walk=None):
        T_idle = self.st["T_idle"]
        Tw = T_walk or self.st["T_walk"]
        out = {"idle": (T_idle, self.idle), "walk": (Tw, self.walk), "attack": (0.55, self.attack), "hurt": (0.55, self.hurt),
               "die": (self.st["die_T"], self.die)}
        if extra:
            out.update(extra)
        return out


# ---------------------------------------------------------------- generic death and helpers
def fall_root(p, t, T, height, side=1, rest=0.12, axis="z", start=0.2, end=0.7):
    """Topple a body standing `height` tall onto its side about a ground pivot `rest` from its
    centre line; returns the 0..1 fall amount."""
    k = min(1.0, t / T)
    f = smooth(start, end, k)
    a = 1.5 * f * side
    q = -rest * side
    if axis == "z":
        add(p, "root", (0.0, 0.0, a), (q - math.cos(a) * q, -math.sin(a) * q, 0.0))
    else:
        add(p, "root", (a, 0.0, 0.0), (0.0, -math.sin(a) * q, q - math.cos(a) * q))
    return f


def sink(t, T, start=0.3, end=0.9):
    return smooth(start, end, min(1.0, t / T))


# ---------------------------------------------------------------- legacy helpers (still used by some scripts)
def shade_fn(spine_y, back=0.62, side=0.85, belly=1.18, stripes=0.0, stripe_axis=2):
    """Grey shading for a tinted body: darker back, lighter belly, optional stripes along z."""

    def fn(p):
        dy = p.y - spine_y(p)
        k = 0.5 + 0.5 * math.tanh(dy * 7.0)
        v = belly + (back - belly) * k
        v = v * 0.7 + side * 0.3
        if stripes > 0.0:
            s = math.sin(p[stripe_axis] * stripes)
            v *= 1.0 - 0.18 * max(0.0, s) * k
        return (v, v, v)

    return fn


def eyes(b, c, spread, r, iris="ffd040", bone="head", slit=True, glow=True, rot_y=0.5, h=1.0):
    for s in (1, -1):
        b.eye(V(c) + V(spread * s, 0, 0), r, iris, side=s, bone=bone, slit=slit, glow=glow, rot_y=rot_y, h=h, mat=MAT_PLAIN, accent=True)


def fangs(b, pts, length, bone, col="f6f0e0", down=True):
    for p in pts:
        b.cone(V(p) + V(0, -length * 0.5 if down else length * 0.5, 0), length * 0.28, length, col, cls=STONE, bone=bone, seg=6, rot=(math.pi if down else 0.0, 0, 0))


def claws(b, base, fwd, bone, n=3, spread=0.04, length=0.06, col="ece6d6"):
    base = V(base)
    for k in range(n):
        x = (k - (n - 1) / 2) * spread
        b.cone(base + V(x, 0, 0), length * 0.25, length, col, cls=STONE, bone=bone, seg=5, rot=(math.pi / 2 if fwd else 0.0, 0, 0))


def glow_ball(b, c, r, col, bone, accent=False):
    """A glowing ball; with `accent` it burns in the enemy's accent colour (ghost-fire, sparks)."""
    if accent:
        old = b.cur_pal
        b.cur_pal = 1.0
        b.ball(c, r, "f0f0f0", cls=CRYSTAL, bone=bone, seg=12, rings=8, mat=MAT_GLOW, tint=1.0)
        b.cur_pal = old
        return
    b.ball(c, r, col, cls=CRYSTAL, bone=bone, seg=12, rings=8, mat=MAT_GLOW)


def quad_rig(body_y, front_z, hind_z, hip_w, neck, head, tail_pts, leg_len=None, extra=None):
    """Quadruped rig: root, pelvis, chest, neck, head, jaw, tail chain and three-bone legs."""
    r = Rig("rig")
    r.bone("root", (0, 0, 0), (0, 0.3, 0))
    r.bone("pelvis", (0, body_y, hind_z), (0, body_y + 0.02, (hind_z + front_z) * 0.5), "root")
    r.bone("chest", (0, body_y + 0.02, (hind_z + front_z) * 0.5), (0, body_y + 0.08, front_z), "pelvis")
    r.bone("neck", (0, body_y + 0.08, front_z), neck, "chest")
    r.bone("head", neck, head, "neck")
    hv = V(head) - V(neck)
    r.bone("jaw", V(neck) + hv * 0.35 + V(0, -0.08, 0), V(head) + V(0, -0.1, 0), "head")
    prev = "pelvis"
    for i in range(len(tail_pts) - 1):
        nm = "tail%d" % i
        r.bone(nm, tail_pts[i], tail_pts[i + 1], prev)
        prev = nm
    for fz, nm, par in ((front_z, "f", "chest"), (hind_z, "h", "pelvis")):
        for s, sd in ((1, "L"), (-1, "R")):
            top = V(hip_w * s, body_y - 0.05, fz)
            kz = 0.04 if nm == "f" else 0.1
            knee = V(hip_w * s * 1.05, body_y * 0.52, fz + kz)
            ank = V(hip_w * s * 1.05, body_y * 0.12, fz - (0.0 if nm == "f" else 0.12))
            paw = V(hip_w * s * 1.05, 0.03, fz + 0.1 - (0.0 if nm == "f" else 0.08))
            r.bone("%s_up.%s" % (nm, sd), top, knee, par)
            r.bone("%s_lo.%s" % (nm, sd), knee, ank, "%s_up.%s" % (nm, sd))
            r.bone("%s_paw.%s" % (nm, sd), ank, paw, "%s_lo.%s" % (nm, sd))
    if extra:
        for e in extra:
            r.bone(*e)
    return r


def leg_nodes(r, nm, sd, radii):
    """Skin-modifier nodes for one leg of a quad_rig (top, knee, ankle, paw)."""
    up = r.bones["%s_up.%s" % (nm, sd)]
    lo = r.bones["%s_lo.%s" % (nm, sd)]
    pw = r.bones["%s_paw.%s" % (nm, sd)]
    return [(up[0], radii[0]), (up[1], radii[1]), (lo[1], radii[2]), (pw[1], radii[3])]


def skin_graph(chains):
    nodes = []
    edges = []
    for chain, attach in chains:
        base = len(nodes)
        nodes.extend(chain)
        for i in range(len(chain) - 1):
            edges.append((base + i, base + i + 1))
        if attach is not None:
            edges.append((attach, base))
    return nodes, edges


def tail_wave(p, n, t, speed, amp, curl=0.0, axis=1, prefix="tail"):
    for i in range(n):
        a = math.sin(t * speed - i * 0.7) * amp * (1 + i * 0.25)
        rot = [curl * (i + 1) * 0.3, 0.0, 0.0]
        rot[axis] += a
        p["%s%d" % (prefix, i)] = (tuple(rot), (0, 0, 0))


def weights_for(rig, names=None, sharp=4.0, k=2):
    return auto_weights(rig, names, sharp, k)


def catmull(pts, per=4):
    """Smoothly resample a polyline (Catmull-Rom); returns (points, segment index of each)."""
    pts = [V(p) for p in pts]
    out = []
    idx = []
    n = len(pts)
    for i in range(n - 1):
        p0 = pts[max(0, i - 1)]
        p1 = pts[i]
        p2 = pts[i + 1]
        p3 = pts[min(n - 1, i + 2)]
        for k in range(per):
            t = k / per
            t2 = t * t
            t3 = t2 * t
            out.append(0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
            idx.append(i + t)
    out.append(pts[-1])
    idx.append(n - 1)
    return out, idx


def chain_weights(prefix, f, n):
    """Blend weights for a point at fractional segment position f along bones prefix0..prefix{n-1}:
    a smooth linear blend between neighbouring bones around every joint."""
    f = max(0.0, min(n - 1e-6, f))
    i = int(math.floor(f))
    t = f - i
    a = min(n - 1, i)
    if t < 0.25 and a > 0:
        k = 0.5 + 2.0 * t      # 0.5 at the joint -> 1.0 a quarter in
        return {"%s%d" % (prefix, a - 1): 1.0 - k, "%s%d" % (prefix, a): k}
    if t > 0.75 and a < n - 1:
        k = 0.5 + 2.0 * (1.0 - t)
        return {"%s%d" % (prefix, a): k, "%s%d" % (prefix, a + 1): 1.0 - k}
    return {"%s%d" % (prefix, a): 1.0}


def chain_rig(r, prefix, pts, parent):
    """Add a bone chain prefix0..prefixN-1 through `pts` under `parent`; returns the bone names."""
    names = []
    prev = parent
    for i in range(len(pts) - 1):
        nm = "%s%d" % (prefix, i)
        r.bone(nm, pts[i], pts[i + 1], prev)
        names.append(nm)
        prev = nm
    return names


def leg_chain(r, nm, root, knee, foot, parent):
    """Two-bone insect/crustacean leg: nm_a (root->knee) and nm_b (knee->foot)."""
    r.bone(nm + "_a", root, knee, parent)
    r.bone(nm + "_b", knee, foot, nm + "_a")
    return [nm + "_a", nm + "_b"]


def wave_chain(p, names, t, speed, amp, axis=1, lag=0.7, grow=0.2, base=(0.0, 0.0, 0.0)):
    """Travelling wave down a bone chain (swimming, slithering, tentacles, tails)."""
    for i, nm in enumerate(names):
        rot = list(base)
        rot[axis] += math.sin(t * speed - i * lag) * amp * (1 + i * grow)
        p[nm] = (tuple(rot), (0, 0, 0))


def scuttle(p, legs, t, speed, amp_up, amp_swing):
    """Alternating tripod gait for many-legged walkers: legs = [(name_a, name_b, phase), ...]."""
    for a, b, ph in legs:
        s = math.sin(t * speed + ph)
        p[a] = ((-max(0.0, s) * amp_up, s * amp_swing, 0), (0, 0, 0))
        p[b] = ((max(0.0, s) * amp_up * 0.8, 0, 0), (0, 0, 0))


def bob(p, t, speed, amp, bone="root"):
    p[bone] = ((0, 0, 0), (0, math.sin(t * speed) * amp, 0))


# ---------------------------------------------------------------- humanoid deaths (person.py rigs)
def person_die(base=None, T=1.2, side=0.25):
    """A death clip for the character rig of art/lib/person.py (root, hips, spine, chest, neck,
    head, arms, legs, robe panels, cape): the knees buckle, the body topples backwards about the
    heels and lands on its back, arms flung out, the head rolling to one side; it ends lying still.
    `base` is an optional pose function to start from (the character's idle at t=0)."""

    def clip(t):
        k = min(1.0, t / T)
        buckle = smooth(0.0, 0.32, k)
        fall = smooth(0.22, 0.72, k)
        settle = bump(k, 0.78, 0.08)
        p = base(0.0) if base is not None else {}
        p = {nm: tuple(v) for nm, v in p.items()}

        def put(nm, rot=(0.0, 0.0, 0.0), loc=(0.0, 0.0, 0.0), scl=None):
            old = p.get(nm, ((0, 0, 0), (0, 0, 0)))
            r2 = (old[0][0] + rot[0], old[0][1] + rot[1], old[0][2] + rot[2])
            l2 = (old[1][0] + loc[0], old[1][1] + loc[1], old[1][2] + loc[2])
            p[nm] = (r2, l2) + ((scl,) if scl else tuple(old[2:]))

        a = -1.5 * fall + 0.04 * settle
        q = V(0.0, 0.0, -0.13)
        R = euler_g((a, side * fall, 0.0))
        off = q - R @ q
        put("root", (a, side * fall, 0.0), (off.x, off.y - 0.28 * buckle * (1.0 - fall), off.z))
        put("hips", (0.25 * buckle * (1.0 - fall), 0.0, 0.0))
        put("spine", (0.18 * buckle - 0.1 * fall, 0.0, 0.05 * fall))
        put("chest", (0.12 * buckle - 0.15 * fall, 0.0, 0.0))
        put("neck", (0.2 * buckle - 0.25 * fall, 0.0, 0.0))
        put("head", (0.15 * buckle - 0.2 * fall, 0.55 * fall, 0.2 * fall))
        for sd, s in (("L", 1), ("R", -1)):
            put("thigh." + sd, (-0.9 * buckle * (1.0 - 0.6 * fall), 0.0, 0.08 * s * fall))
            put("shin." + sd, (1.5 * buckle * (1.0 - 0.6 * fall), 0.0, 0.0))
            put("foot." + sd, (0.3 * fall, 0.0, 0.0))
            put("upper_arm." + sd, (-0.4 * buckle + 0.2 * fall, 0.0, -s * (0.2 * buckle + 0.95 * fall)))
            put("forearm." + sd, (-0.4 * buckle + 0.2 * fall, 0.0, 0.0))
        put("cape", (-0.6 * fall, 0.0, 0.0))
        put("robe_f", (-0.3 * fall, 0.0, 0.0))
        put("robe_b", (0.4 * fall, 0.0, 0.0))
        put("eyes", (0.0, 0.0, 0.0), (0.0, 0.0, 0.0), (1.0, 1.0 - 0.9 * fall, 1.0))
        return p

    return clip


def realtime():
    """Export clips in real time.  ``kit.bake_action`` samples poses every 1/30 s but keys them on
    Blender frames, and Blender's factory scene runs at 24 frames per second, so every exported
    clip came out a quarter too long (a 0.55 s attack lasted 0.71 s).  Monster scripts call this
    right after ``kit.reset()`` so their clips last exactly as long as they were authored."""
    import os

    import bpy
    import kit
    bpy.context.scene.render.fps = kit.FPS
    bpy.context.scene.render.fps_base = 1.0
    if getattr(kit.export, "slides_to_zero", False):
        return

    # the clips are keyed from frame 1: slide them to start at 0 so a loop's last frame meets its
    # first instead of holding it for an extra frame (this process only; kit itself is unchanged)
    def export(path, objs, animations=True):
        for o in bpy.context.scene.objects:
            o.select_set(False)
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        kw = dict(filepath=path, export_format="GLB", use_selection=True, export_yup=True, export_apply=False, export_texcoords=True,
                  export_normals=True, export_vertex_color="ACTIVE", export_materials="EXPORT", export_skins=True, export_animations=animations)
        if animations:
            kw["export_animation_mode"] = "ACTIONS"
            kw["export_anim_slide_to_zero"] = True
        bpy.ops.export_scene.gltf(**kw)
        print("[art] wrote", os.path.relpath(path, kit.ROOT))

    export.slides_to_zero = True
    kit.export = export


# ---------------------------------------------------------------- many-legged walkers
class Walker:
    """Feet for insects, spiders, crabs and other many-legged walkers: each leg is a two-bone
    chain (a, b) hanging from `parent`; ``step`` plants or swings every foot with ``limb_ik`` so
    the feet stay on the ground in stance and arc forward in swing.  `phases` are touchdown
    phases (the alternating tripod: 0 and 0.5).  ``sagittal=True`` is for upright legs (bipeds):
    they bend only fore and aft with ``knee_ik`` instead of yawing to face the foot."""

    def __init__(self, rig, legs, phases, duty=0.55, sagittal=False):
        self.rig = rig
        self.legs = legs
        self.phases = phases
        self.duty = duty
        self.sagittal = sagittal
        self.poser = Poser(rig)

    def step(self, p, ph=None, stride=0.0, lift=0.0, offsets=None, parent=None, lift_all=0.0):
        D = self.poser.fk(p)
        for i, (a, b2) in enumerate(self.legs):
            par = parent or self.rig.bones[a][2]
            foot = V(self.rig.bones[b2][1])
            if ph is not None:
                on, s = Gait(self.phases[i], self.duty).at(ph)
                dz, dy = foot_path(on, s, stride, lift)
                foot = foot + V(0.0, dy, dz)
            if offsets is not None:
                foot = foot + V(offsets[i])
            foot = foot + V(0.0, lift_all, 0.0)
            if self.sagittal:
                res = knee_ik(self.rig, D, a, b2, par, foot)
            else:
                res = limb_ik(self.rig, D, a, b2, par, foot)
            for nm, val in res.items():
                p[nm] = val
        return p


def flip_die(p, t, T, height, side=1, curl_legs=None, rest=0.08):
    """Insects and crabs die on their backs: a stagger, a roll right over, the legs curling up.
    `height` is the body's resting height, `rest` its half thickness."""
    k = min(1.0, t / T)
    roll = smooth(0.2, 0.7, k)
    hop = math.sin(math.pi * smooth(0.15, 0.6, k)) * 0.15
    a = math.pi * roll * side
    # roll about the body's centre, which settles from its standing height to resting on its back
    yc = height + (rest - height) * smooth(0.25, 0.8, k) + hop
    add(p, "root", (0.0, 0.0, a), (height * math.sin(a), yc - height * math.cos(a), 0.0))
    if curl_legs:
        c = smooth(0.4, 0.86, k)
        for nm, amt in curl_legs:
            rot = p[nm][0]
            p[nm] = ((rot[0] * (1.0 - c) + amt[0] * c, rot[1] * (1.0 - c) + amt[1] * c, rot[2] * (1.0 - c) + amt[2] * c), p[nm][1])
    return roll


def drop_die(p, t, T, drop, bone="root", tilt=(0.0, 0.0, 0.0), squash=None):
    """Floaters (jellies, wisps, rays, ghosts) sink to the ground: the root drops `drop` metres with
    a little bounce and tilts, optionally squashing flat."""
    k = min(1.0, t / T)
    f = smooth(0.1, 0.75, k) ** 1.4
    bounce = 0.06 * math.sin(math.pi * smooth(0.72, 0.92, k)) * drop
    add(p, bone, (tilt[0] * f, tilt[1] * f, tilt[2] * f), (0.0, -drop * f + bounce, 0.0))
    if squash is not None:
        sx, sy, sz = squash
        old = p[bone]
        p[bone] = (old[0], old[1], (1.0 + (sx - 1.0) * f, 1.0 + (sy - 1.0) * f, 1.0 + (sz - 1.0) * f))
    return f
