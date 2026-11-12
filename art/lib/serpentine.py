"""Long scaled bodies for the monster scripts: the loong (art/monsters/dragon.py) and the great snakes
(art/monsters/serpent.py).

* ``scaled_body``: a skin lofted along an anatomy.Spline with a cross-section flattened under the
  belly, its scales *sculpted* rather than painted: rows of shingles staggered by half a scale, each
  rising from under the one in front of it to a free rear edge that steps down onto the next (fish
  and snake scales overlap tailwards), and across the belly a run of broad transverse plates (a
  snake's ventral scutes, a dragon's "belly of a clam").  The mesh is laid out so that every scale
  falls on whole rows and columns of vertices (four rings a scale, four columns a scale), so the
  steps resolve as clean bands of cel shading and dark rear edges instead of aliasing into a
  chequerboard; the paint only darkens each scale's rear edge and the seams between the plates.
* ``flame``: a flat, wavy, tapering blade through control points - a lock of a loong's mane, an
  elbow flame, a beard, a tail fin's ray.
* ``fin``: a flat, swept dorsal fin with a curved trailing edge.

Bodies are greyscale with tint weight 1 (the game recolours them); `back`, `flank` and `belly`
set the countershading.  Everything is in Godot space, like the rest of the kit.
"""

import math

from kit import V, mix, rgb
from sculpt import TAU, catmull, loft, section, smooth

PLAIN = 0.1     # a plain toon surface (outlined, no shader pattern: see arthropod.CHITIN)


def grey(v):
    return (v, v, v)


def scaled_body(b, sp, rad, bones, scale_len=0.075, cols=10, per=4, belly=58.0, height=0.07, plate_h=0.045, flat=0.18, ridge=0.0,
                back=0.66, flank=0.8, under=0.95, edge=0.22, u0=0.0, u1=1.0, cap0=False, cap1=True, col_fn=None, cls=PLAIN, tint=1.0,
                profile=None, reverse=False):
    """Loft a scaled skin along spline `sp` from u0 to u1: `rad(u)` its radius, `bones(u)` its bone
    weights.  Scales are `scale_len` long with `cols` round the body, `per` vertices a side; the
    belly plates fill `belly` degrees either side of straight down.  `height` and `plate_h` are the
    steps of a scale and a plate (a share of the radius), `flat` flattens the underside, `ridge`
    raises a keel along the spine.  Values: `back` along the spine, `flank` on the sides, `under`
    on the plates, rear edges darkened by `edge`.  `col_fn(u, a, f, g, kind, v)` may repaint a
    vertex (a = angle from the back, f along its scale 0..1, g across it -0.5..0.5) and
    `profile(u, a)` scale its radius.  The spline should run from the head to the tail (scales
    overlap tailwards); `reverse` if it runs from the tail to the head.  Returns the verts."""
    L = sp.L * (u1 - u0)
    n_along = max(4, int(round(L / scale_len)))
    n_rings = n_along * per
    n_round = cols * per
    bel = math.radians(belly)
    rings = []
    meta = []
    ring_bones = []
    for j in range(n_rings + 1):
        u = u0 + (u1 - u0) * j / n_rings
        p, t, up, side = sp.at(u)
        R = rad(u)
        s_idx = j / per                        # position in scales along the body
        row = int(math.floor(s_idx + 1e-6))
        f = s_idx - row
        if reverse:
            f = (1.0 - f) % 1.0
        ring_meta = []

        def prof(a, R=R, f=f, row=row, u=u, ring_meta=ring_meta):
            # a = 0 on the back, pi under the belly
            aa = math.atan2(math.sin(a), math.cos(a))
            from_down = math.pi - abs(aa)
            k = 1.0
            if flat > 0.0:
                k *= 1.0 - flat * max(0.0, -math.cos(aa)) ** 3
            if ridge > 0.0:
                k *= 1.0 + ridge * max(0.0, math.cos(aa)) ** 12
            if profile is not None:
                k *= profile(u, aa)
            if from_down < bel:
                kind = "plate"
                g = 0.0
                k *= 1.0 + plate_h * (f ** 0.7)
            else:
                kind = "scale"
                c = aa / TAU * cols + 0.5 * (row % 2)
                g = (c - math.floor(c)) - 0.5
                k *= 1.0 + height * (f ** 0.8) * (1.0 - 1.4 * g * g)
            ring_meta.append((u, aa, f, g, kind))
            return R * k

        ring = section(p, t, prof, n_round, up=up)
        rings.append(ring)
        meta.append(ring_meta)
        ring_bones.append(bones(u))

    def colf(pos, j, i):
        u, a, f, g, kind = meta[j][i]
        cy = math.cos(a)
        if kind == "plate":
            v = under * (1.0 - 0.28 * smooth(0.72, 0.98, f))
        else:
            v = flank + (back - flank) * smooth(0.0, 0.9, cy)
            v *= 1.0 - edge * smooth(0.68, 0.95, f) - 0.5 * edge * smooth(0.36, 0.5, abs(g))
            # the scales nearest the belly plates are paler, so the countershading runs into them
            v = v + (under - v) * 0.35 * smooth(-0.2, -0.55, cy)
        if col_fn is not None:
            v = col_fn(u, a, f, g, kind, v)
        return grey(max(0.0, min(1.0, v)))

    return loft(b, rings, grey(flank), cls=cls, bones=ring_bones, col_fn=colf, tint=tint, cap0=cap0, cap1=cap1, cap_push=0.5)


def flame(b, pts, width, nrm, col, col_tip=None, bone=None, thick=0.28, per=3, n=6, tint=1.0, cls=0.2, mat=0, widest=0.3, bones=None):
    """A flat, tapering blade through control points `pts` (a wavy lock of mane, a flame, a fin
    ray), widest at `widest` of its length and pointed at the tip, its flat side facing `nrm`."""
    cp = catmull([V(p) for p in pts], per)
    m = len(cp)
    nv = V(nrm)
    rings = []
    rcols = []
    rbones = []
    c0 = rgb(col) if not isinstance(col, (int, float)) else grey(col)
    c1 = (rgb(col_tip) if not isinstance(col_tip, (int, float)) else grey(col_tip)) if col_tip is not None else c0
    for j, c in enumerate(cp):
        t = j / (m - 1)
        tan = (cp[min(m - 1, j + 1)] - cp[max(0, j - 1)]).normalized()
        w = width * (0.45 + 0.55 * math.sin(math.pi * min(1.0, t / (2.0 * widest))) if t < widest else math.cos(0.5 * math.pi * (t - widest) / (1.0 - widest)) ** 0.9)
        w = max(0.0008, w)
        up = nv - tan * nv.dot(tan)
        if up.length < 1e-5:
            up = tan.orthogonal()
        rings.append(section(c, tan, lambda a, w=w: 1.0 / math.sqrt((math.cos(a) / max(0.0006, w * thick)) ** 2 + (math.sin(a) / w) ** 2), n, up=up))
        rcols.append(mix(c0, c1, t ** 1.2))
        if bones is not None:
            rbones.append(bones[min(len(bones) - 1, int(t * (len(bones) - 1) + 0.5))])
    return loft(b, rings, c0, cls=cls, cols=rcols, bone=bone if bones is None else None, bones=rbones if bones is not None else None, tint=tint, mat=mat,
                cap0=True, cap1=True, cap_push=0.25)


def fin(b, root, d, nrm, height, bone, col=0.8, col_tip=0.95, sweep=0.7, width=0.5, tint=1.0, cls=PLAIN, n=6, curl=0.25):
    """A flat dorsal fin standing on `root`: a blade rising along `nrm` and swept back along `d` (the
    way the body runs tailwards) to a point that curls back like a tongue of flame, its flat side
    facing sideways, `width` x its height across at the root."""
    root, d, nv = V(root), V(d).normalized(), V(nrm)
    nv = (nv - d * nv.dot(d)).normalized()
    side = d.cross(nv).normalized()
    pts = [root - nv * (height * 0.12), root + nv * (height * 0.55) + d * (height * sweep * 0.25),
           root + nv * height + d * (height * sweep * 0.75), root + nv * (height * (1.0 - curl * 0.3)) + d * (height * (sweep + curl))]
    return flame(b, pts, height * width * 0.5, side, col, col_tip, bone=bone, thick=0.18, n=n, tint=tint, cls=cls, widest=0.15)
