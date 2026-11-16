"""Put a tape round the body under the clothes (art/lib/body.py), and round a reference figure.

    python art/measure_body.py                 # the man and the woman of body.py, slice by slice
    python art/measure_body.py --ref DIR       # ... beside a reference figure of each sex

The reference is the CC0 base mesh of MakeHuman (``base.obj``) with its young man and young woman
(``asian-male-young.target``, ``asian-female-young.target``, from the project's ``data/3dobjs`` and
``data/targets/macrodetails``): fetch the three files into DIR yourself.  **They are measured, never
committed**: all art in this repository is generated from its own scripts (CLAUDE.md), and a reference
is something to hold a tape against.  The reference is laid over the game's rig joint for joint (its
ankle, knee, hip and shoulder joints brought to the rig's heights, everything between stretched
evenly, widths and depths scaled with the trunk), so that a slice at 0.88 m is the seat of both.

For each height the table gives the width and depth of the trunk, its girth as a tape would take it
(the convex hull), and how far the midline lies behind the fullest point in front (``cleftF``: the
sternum between the pectorals or the breasts) and behind (``cleftB``: the furrow of the spine, the
cleft between the cheeks); then the girth of one leg.  The Broken Mirror release was sculpted to this
table: see the README.
"""
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "lib"))
RIG = {"ank": 0.1, "knee": 0.5, "hip": 0.92, "sho": 1.405}
TORSO = [1.44, 1.36, 1.32, 1.30, 1.28, 1.26, 1.22, 1.18, 1.14, 1.10, 1.06, 1.02, 0.98, 0.94, 0.90, 0.88, 0.86, 0.84]
LEG = [0.80, 0.74, 0.66, 0.58, 0.50, 0.46, 0.40, 0.34, 0.26, 0.18]


def section(v, tris, y, xlo=-9.0, xhi=9.0):
    """The outline of the mesh where the plane at height y cuts it: segments [(x, z), (x, z)]."""
    a = v[tris]
    d = a[:, :, 1] - y
    s = np.sign(d)
    out = []
    for t, dd in zip(a[(s.min(axis=1) < 0) & (s.max(axis=1) >= 0)], d[(s.min(axis=1) < 0) & (s.max(axis=1) >= 0)]):
        p = []
        for i, j in ((0, 1), (1, 2), (2, 0)):
            if (dd[i] < 0) != (dd[j] < 0):
                k = dd[i] / (dd[i] - dd[j])
                q = t[i] + (t[j] - t[i]) * k
                p.append((q[0], q[2]))
        if len(p) == 2 and xlo <= (p[0][0] + p[1][0]) / 2 <= xhi:
            out.append(p)
    return np.array(out).reshape(-1, 2)


def girth(P):
    """The length of a tape drawn tight round the points (the perimeter of their convex hull)."""
    P = sorted(set(map(tuple, np.round(P, 5))))
    if len(P) < 3:
        return 0.0

    def cr(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, up = [], []
    for p in P:
        while len(lo) >= 2 and cr(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    for p in reversed(P):
        while len(up) >= 2 and cr(up[-2], up[-1], p) <= 0:
            up.pop()
        up.append(p)
    H = lo[:-1] + up[:-1]
    return float(sum(np.hypot(H[i][0] - H[i - 1][0], H[i][1] - H[i - 1][1]) for i in range(len(H))))


def measure(v, tris, arm_x=9.0):
    rows = {}
    for y in TORSO:
        lim = arm_x if not callable(arm_x) else arm_x(y)
        P = section(v, tris, y, -lim, lim)
        if len(P) == 0:
            continue
        mid = P[np.abs(P[:, 0]) < 0.006]
        zf, zb = P[:, 1].max(), P[:, 1].min()
        rows[y] = dict(width=P[:, 0].max() - P[:, 0].min(), depth=zf - zb, girth=girth(P),
                       cleftF=zf - mid[:, 1].max() if len(mid) else float("nan"), cleftB=mid[:, 1].min() - zb if len(mid) else float("nan"))
    legs = {}
    for y in LEG:
        P = section(v, tris, y, 0.0, 9.0)
        if len(P):
            legs[y] = girth(P)
    return rows, legs


def largest(v, tris):
    """The triangles of the biggest connected piece (the trunk and legs: the arms are clays of their own)."""
    par = list(range(len(v)))

    def find(a):
        while par[a] != a:
            par[a] = par[par[a]]
            a = par[a]
        return a
    for t in tris:
        a = find(t[0])
        par[find(t[1])] = a
        par[find(t[2])] = a
    roots = np.array([find(i) for i in range(len(v))])
    r, n = np.unique(roots[tris[:, 0]], return_counts=True)
    return tris[roots[tris[:, 0]] == r[n.argmax()]]


def ours(opts):
    import kit
    import body
    kit.reset()
    b = kit.Builder("bare")
    body.build(b, opts)
    ob = b.to_object("bare")
    me = ob.data
    me.calc_loop_triangles()
    v = np.array([(p.co.x, p.co.z, -p.co.y) for p in me.vertices])
    tris = np.array([tuple(t.vertices) for t in me.loop_triangles])
    return v, largest(v, tris)


def reference(refdir, target):
    vs, groups, g = [], {}, None
    for ln in open(os.path.join(refdir, "base.obj")):
        if ln.startswith("v "):
            vs.append([float(t) for t in ln.split()[1:4]])
        elif ln.startswith("g "):
            g = ln.split()[1]
        elif ln.startswith("f "):
            groups.setdefault(g, []).append([int(t.split("/")[0]) - 1 for t in ln.split()[1:]])
    v = np.array(vs)
    for ln in open(os.path.join(refdir, target)):
        if ln.strip() and not ln.startswith("#"):
            t = ln.split()
            v[int(t[0])] += [float(t[1]), float(t[2]), float(t[3])]

    def joint(name):
        return v[sorted({i for f in groups[name] for i in f})].mean(axis=0)[1]
    ids = sorted({i for f in groups["body"] for i in f})
    floor = v[ids][:, 1].min()
    ys = [floor, joint("joint-l-ankle"), joint("joint-l-knee"), joint("joint-l-upper-leg"), joint("joint-l-shoulder")]
    yt = [0.0, RIG["ank"], RIG["knee"], RIG["hip"], RIG["sho"]]
    k = RIG["sho"] / (ys[-1] - floor)
    out = v.copy()
    out[:, 1] = np.where(v[:, 1] > ys[-1], yt[-1] + (v[:, 1] - ys[-1]) * k, np.interp(v[:, 1], ys, yt))
    out[:, 0] *= k
    out[:, 2] *= k
    tris = np.array([[f[0], f[i], f[i + 1]] for f in groups["body"] for i in range(1, len(f) - 1)])
    return out, tris


def main():
    refdir = sys.argv[sys.argv.index("--ref") + 1] if "--ref" in sys.argv else ""
    for name, opts, target in (("man", {}, "asian-male-young.target"), ("woman", {"fem": True}, "asian-female-young.target")):
        rows, legs = measure(*ours(opts))
        ref = None
        if refdir:
            # (the reference stands with its arms out: the trunk is what lies inside the armpits)
            ref = measure(*reference(refdir, target), arm_x=lambda y: 0.2 if y < 1.36 else 0.26)
        print("==== the %s (metres; ours%s)" % (name, " | the reference" if ref else ""))
        print("  height  width  depth  girth cleftF cleftB")
        for y in TORSO:
            if y not in rows:
                continue
            r = rows[y]
            ln = "  %.2f    %.3f  %.3f  %.3f  %.3f  %.3f" % (y, r["width"], r["depth"], r["girth"], r["cleftF"], r["cleftB"])
            if ref and y in ref[0]:
                q = ref[0][y]
                ln += "  |  %.3f  %.3f  %.3f  %.3f  %.3f" % (q["width"], q["depth"], q["girth"], q["cleftF"], q["cleftB"])
            print(ln)
        print("  one leg, girth")
        for y in LEG:
            if y in legs:
                print("  %.2f    %.3f%s" % (y, legs[y], ("  |  %.3f" % ref[1][y]) if ref and y in ref[1] else ""))


if __name__ == "__main__":
    main()
