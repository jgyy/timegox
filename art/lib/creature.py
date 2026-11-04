"""Helpers shared by the monster scripts in ``art/monsters``.

Monster meshes are authored mostly in greys with tint weight 1, so the game can recolour one mesh
for every enemy of that shape (``Assets.monster(shape, colour)``).  Eyes, teeth, claws and glowing
parts keep their own colours (tint 0).
"""

import math

from kit import (CRYSTAL, MAT_GLOW, MAT_PLAIN, SKIN, STONE, Rig, V, auto_weights, env)


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
        b.eye(V(c) + V(spread * s, 0, 0), r, iris, side=s, bone=bone, slit=slit, glow=glow, rot_y=rot_y, h=h, mat=MAT_PLAIN)


def fangs(b, pts, length, bone, col="f6f0e0", down=True):
    for p in pts:
        b.cone(V(p) + V(0, -length * 0.5 if down else length * 0.5, 0), length * 0.28, length, col, cls=STONE, bone=bone, seg=6, rot=(math.pi if down else 0.0, 0, 0))


def claws(b, base, fwd, bone, n=3, spread=0.04, length=0.06, col="ece6d6"):
    base = V(base)
    for k in range(n):
        x = (k - (n - 1) / 2) * spread
        b.cone(base + V(x, 0, 0), length * 0.25, length, col, cls=STONE, bone=bone, seg=5, rot=(math.pi / 2 if fwd else 0.0, 0, 0))


def glow_ball(b, c, r, col, bone):
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
    """Join chains of skin nodes into one graph.  Each chain is (nodes, attach_index or None);
    a chain's first node is linked to node `attach_index` of the graph built so far."""
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


def zero_pose(rig):
    return {nm: ((0, 0, 0), (0, 0, 0)) for nm in rig.bones}


def tail_wave(p, n, t, speed, amp, curl=0.0, axis=1, prefix="tail"):
    for i in range(n):
        a = math.sin(t * speed - i * 0.7) * amp * (1 + i * 0.25)
        rot = [curl * (i + 1) * 0.3, 0.0, 0.0]
        rot[axis] += a
        p["%s%d" % (prefix, i)] = (tuple(rot), (0, 0, 0))


def weights_for(rig, names=None, sharp=4.0, k=2):
    return auto_weights(rig, names, sharp, k)


__all__ = ["shade_fn", "eyes", "fangs", "claws", "glow_ball", "quad_rig", "leg_nodes", "skin_graph", "zero_pose", "tail_wave", "weights_for", "env", "SKIN"]


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
    """Blend weights for a point at fractional segment position f along bones prefix0..prefix{n-1}."""
    i = int(math.floor(f))
    t = f - i
    a = min(n - 1, max(0, i))
    b2 = min(n - 1, a + 1)
    if t < 0.5 or a == b2:
        w = {"%s%d" % (prefix, a): 1.0}
        if a > 0 and t < 0.3:
            w = {"%s%d" % (prefix, a - 1): 0.3 - t, "%s%d" % (prefix, a): 0.7 + t}
        return w
    return {"%s%d" % (prefix, a): 1.0 - (t - 0.5), "%s%d" % (prefix, b2): t - 0.5}
