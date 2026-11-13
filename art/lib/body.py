"""The body under the clothes: a person sculpted from the skeleton out, in their underclothes.

Until this release a character *was* their clothes: the robe was the torso, the trousers were the
legs, and under them there was nothing.  This module sculpts the body itself, over the same rig as
everybody else (person.make_rig: the joints do not move, so every clip, mount, seat and weapon
still fits), and dresses it in what was worn under hanfu: the drawers anybody worked in (*kun*,
the "calf-nose" breeches of the Han: Sima Xiangru washed cups in a pair in his wife's wine shop)
and, for a woman, the *moxiong*, the band of cloth wrapped round the chest under the robe since the
Song.  Each character's export carries it as a second body, "bare", shown in place of the clothes
whenever the game undresses somebody (the hot springs, the wardrobe's underclothes, a gallery of
the cast); see person.build and scripts/models.gd ``undress``.

The sculpt follows the anatomy references in the README (Paul Richer's *Artistic Anatomy*, Loomis'
*Figure Drawing for All It's Worth*, the Proko proportion lessons, Anatomy for Sculptors, and the
ANSUR II and NASA anthropometric tables for the girth of a limb):

* proportions in heads, read off the rig: the nipples a head below the chin, the navel a head
  below that, the crotch half way up the figure, the knee joint at a quarter; a man's shoulders
  two heads across at the deltoids, a woman's about a head and three quarters with her hips as
  wide; the ribcage an egg tipped back, the pelvis a bowl tipped forward, the two joined by the
  soft cylinder of the waist (the obliques over the hip bones in front, the erectors behind);
* the masses that carry the light, sculpted in clay (art/lib/clay.py) so they melt into one skin:
  pectorals that slope up into the armpit, deltoids capping the shoulders, the trapezius from the
  neck to the tips of the shoulders, the shoulder blades and the V of the latissimus on the back,
  the rectus column over the belly, the gluteus maximus and the medius above it; thighs carried by
  the quadriceps (the vastus medialis a teardrop above the inside of the knee), the hamstrings and
  adductors, the kneecap, the two heads of the calf (the inner lower than the outer), the ankle
  bones and a foot with a heel, an arch and five toes; the girth of every limb from the tables
  (a thigh about 55 cm round at the top, a calf 37, an upper arm 30, a forearm 27, a wrist 17);
* and where two masses meet, a line: the furrow down the sternum and the belly, under the pecs,
  between the deltoid and the chest, between the quadriceps and the hamstrings, round the kneecap.
  A painter shades it in; here the clay itself says where its masses meet (``Info.tags``), and the
  meeting is darkened a little, more on a man, hardly at all on a woman, never on a child;
* a woman's figure from the same bones: narrower ribs and shoulders, a waist at its narrowest a
  hand above the navel, a wider and deeper pelvis, fuller hips, seat and upper thighs, smaller
  joints, a bust under the band; less muscle drawn and more of the soft layer over it;
* build (o["build"]), age (o["age"]: the muscle softens, the belly comes forward) and the child's
  frame (a scaled rig: a round belly, slim limbs, no muscle drawn);
* the arms are clays of their own (an arm hangs against the lats, and one skin would weld it to
  the ribs): the deltoid belongs to the torso and the arm starts inside it.

The hands and the head are the character's own (face.py, garment.hand) and are kept when they are
undressed; the neck is the body's own, running on unbroken from the shoulders into the head.
Everything is in Godot space for a person facing +Z, +X the person's left."""

import math

from clay import Clay
from kit import CLOTH, SKIN, V, darken, lighten, mix, rgb
from sculpt import fbm3, smooth

# the joints of the person rig (person.make_rig, garment.SHO ...)
SHO = V(0.166, 1.405, -0.006)
ELB = V(0.208, 1.148, -0.022)
WRI = V(0.232, 0.9, 0.02)
HIP = V(0.1, 0.92, 0.0)
KNEE = V(0.105, 0.5, 0.02)
ANK = V(0.105, 0.1, -0.01)

HEMP = "cdbf9f"       # undyed ramie and hemp: what anybody's underclothes were made of
HEMP_EDGE = "a8977a"
SKIN_DEFAULT = "f5d6c2"

# masses whose meeting is drawn as a line (body.py docstring); the rest are the soft fill between them
MASSES = ("pec", "delt", "trap", "abs", "obl", "lat", "glute", "medius", "quad", "ham", "add", "vmed", "patella", "calf", "bicep", "tricep",
          "flexor", "scap", "bust", "clav")


class Figure:
    """The proportions of one body from a person's options."""

    def __init__(self, o):
        self.fem = bool(o.get("fem", False))
        self.child = o.get("scale", 1.0) < 0.85
        self.age = float(o.get("age", 0.0))
        b = float(o.get("build", 1.0))
        self.build = b
        elder = smooth(0.45, 0.95, self.age)
        self.elder = elder
        # how much muscle is drawn (a man's, a woman's), and the soft layer over it
        mus = (0.45 if self.fem else 1.0) * (0.75 + 0.6 * (b - 0.95)) * (1.0 - 0.55 * elder)
        self.mus = 0.0 if self.child else max(0.15, min(1.4, mus))
        self.fat = (1.0 if self.fem else 0.35) + 0.3 * elder + max(0.0, b - 1.1) * 0.8
        # the frame: shoulders, ribs and pelvis
        self.w = (0.9 if self.fem else 1.0) * (0.9 + 0.1 * b) * (0.92 if self.child else 1.0)
        self.pel = (1.07 if self.fem else 1.0) * (0.96 + 0.04 * b) * (0.95 if self.child else 1.0)
        self.limb = (0.88 if self.fem else 1.0) * (0.86 + 0.14 * b) * (0.86 if self.child else 1.0)
        self.belly = (0.6 * elder + max(0.0, b - 1.05) * 2.4 + (0.6 if self.child else 0.0))
        self.bust = 0.0 if (self.child or not self.fem) else float(o.get("bust", 1.0 - 0.3 * elder))
        self.skin = rgb(o.get("skin", SKIN_DEFAULT))


def _torso_bones(p, t=0.0):
    """hips below the waist, spine through it, chest above the ribs' lower edge, the neck at the top."""
    y = p.y
    if y < 0.98:
        return {"hips": 1.0}
    if y < 1.08:
        k = smooth(0.98, 1.08, y)
        return {"hips": 1.0 - k, "spine": k}
    if y < 1.2:
        return {"spine": 1.0}
    if y < 1.3:
        k = smooth(1.2, 1.3, y)
        return {"spine": 1.0 - k, "chest": k}
    if y < 1.46:
        return {"chest": 1.0}
    if y < 1.52:
        k = smooth(1.46, 1.52, y)
        return {"chest": 1.0 - k, "neck": k}
    if y < 1.57:
        return {"neck": 1.0}
    k = smooth(1.57, 1.63, y)
    return {"neck": 1.0 - k, "head": k}


def _thigh_bones(sd):
    th, sh = "thigh." + sd, "shin." + sd

    def fn(p, t=0.0):
        y = p.y
        if y > 0.9:
            k = smooth(0.9, 0.98, y)
            return {th: 1.0 - 0.6 * k, "hips": 0.6 * k}
        if y > 0.56:
            return {th: 1.0}
        k = smooth(0.56, 0.44, y)
        return {th: 1.0 - k, sh: k}
    return fn


def _arm_bones(sd):
    ua, fa, hd = "upper_arm." + sd, "forearm." + sd, "hand." + sd

    def fn(p, t=0.0):
        y = p.y
        if y > 1.36:
            k = smooth(1.36, 1.44, y)
            return {ua: 1.0 - 0.45 * k, "chest": 0.45 * k}
        if y > 1.2:
            return {ua: 1.0}
        if y > 1.1:
            k = smooth(1.2, 1.1, y)
            return {ua: 1.0 - k, fa: k}
        if y > 0.93:
            return {fa: 1.0}
        k = smooth(0.93, 0.89, y)
        return {fa: 1.0 - k, hd: k}
    return fn


def _foot_bones(sd):
    sh, ft, tb = "shin." + sd, "foot." + sd, "toe." + sd

    def fn(p, t=0.0):
        if p.y > 0.12:
            return {sh: 1.0}
        if p.z > 0.115:
            k = smooth(0.115, 0.14, p.z)
            return {ft: 1.0 - k, tb: k}
        k = smooth(0.12, 0.07, p.y)
        return {sh: 1.0 - k, ft: k}
    return fn


# ---------------------------------------------------------------- the sculpt
def _torso(c, F):
    """Pelvis, waist, ribcage, chest, back, shoulders and the neck (one clay)."""
    w, pel, mus, fat = F.w, F.pel, F.mus, F.fat
    fem = F.fem
    tb = _torso_bones
    # ---- the pelvis: a bowl tipped forward, the hips over the joints, the seat behind
    c.ellipsoid(V(0, 0.95, -0.004), (0.122 * pel, 0.1, 0.098 * (1.0 + 0.06 * fat)), bones=tb, tag="pelvis")
    c.ellipsoid(V(0, 0.98, 0.03 + 0.014 * F.belly), (0.1 * pel, 0.075, 0.066 + 0.016 * F.belly), bones=tb, tag="pelvis")
    # (the crotch, where the drawers are gathered between the legs)
    c.ellipsoid(V(0, 0.86, 0.004), (0.06, 0.05, 0.07), bones=tb, tag="pelvis")
    for s, sd in ((1, "L"), (-1, "R")):
        # gluteus medius and the hip bone under the waist's side
        c.ellipsoid(V(0.108 * pel * s, 0.95, -0.016), (0.046 * pel, 0.075, 0.066), rot=(0, 0, -0.2 * s), bones=tb, tag="medius." + sd)
        # gluteus maximus: a woman's fuller, rounder and a little higher
        gr = ((0.082, 0.098, 0.08) if fem else (0.074, 0.094, 0.074))
        gr = (gr[0], gr[1] * (1.0 - 0.06 * F.elder), gr[2] * (1.0 - 0.12 * F.elder))
        c.ellipsoid(V(0.066 * pel * s, 0.876 + (0.01 if fem else 0.0), -0.066 - (0.008 if fem else 0.0)), (gr[0] * pel, gr[1], gr[2] * (0.95 + 0.1 * fat)),
                    rot=(0.25, 0, 0.12 * s), bones={"hips": 0.65, "thigh." + sd: 0.35}, tag="glute." + sd)
        if fem:
            # the soft layer over the outer hip and the top of the thigh
            c.ellipsoid(V(0.13 * pel * s, 0.885, -0.006), (0.05, 0.08, 0.066), bones={"hips": 0.5, "thigh." + sd: 0.5}, tag="medius." + sd)
    # ---- the waist: the obliques over the hip bones, the belly in front, the erectors behind
    # (an elder's waist has thickened; a heavy man's belly comes forward and out)
    waist_w = (0.11 if fem else 0.118) * w * (1.0 + 0.2 * F.belly + 0.12 * F.elder)
    c.ellipsoid(V(0, 1.095, 0.004 + 0.016 * F.belly), (waist_w, 0.118, 0.082 + 0.018 * F.belly + 0.006 * fat), bones=tb, tag="waist")
    if F.belly > 0.15 and not F.child:
        # a paunch: a heavy man's or an old one's belly carried in front, over the drawers' band
        bb = F.belly - 0.15
        c.ellipsoid(V(0, 1.05, 0.05 + 0.045 * bb), (0.1 * (1.0 + 0.3 * bb), 0.1 + 0.02 * bb, 0.055 + 0.055 * bb), bones=tb, tag="waist")
    for s, sd in ((1, "L"), (-1, "R")):
        c.ellipsoid(V(0.096 * w * s, 1.025, 0.0), (0.036 * (0.9 + 0.2 * fat), 0.06, 0.062), rot=(0, 0, 0.15 * s), bones=tb, tag="obl." + sd)
        c.ellipsoid(V(0.036 * s, 1.1, -0.082), (0.032, 0.13, 0.034), bones=tb, tag="waist")
        if not F.child:
            # the rectus abdominis: a long column either side of the midline
            c.ellipsoid(V(0.034 * s, 1.135, 0.072 + 0.014 * F.belly), (0.032, 0.11, 0.022 + 0.012 * mus), bones=tb, tag="abs." + sd)
    # ---- the ribcage: an egg tipped back, widest a little below the armpits
    c.ellipsoid(V(0, 1.285, -0.008), (0.136 * w, 0.165, 0.104), rot=(-0.06, 0, 0), bones=tb, tag="ribs")
    c.ellipsoid(V(0, 1.21, 0.004), (0.116 * w, 0.08, 0.09), bones=tb, tag="ribs")
    # the back: the upper back, the shoulder blades, the V of the lats
    c.ellipsoid(V(0, 1.36, -0.07), (0.122 * w, 0.09, 0.054), bones=tb, tag="back")
    for s, sd in ((1, "L"), (-1, "R")):
        c.ellipsoid(V(0.088 * w * s, 1.34, -0.092), (0.06 * w, 0.072, 0.026), rot=(0, 0, 0.22 * s), bones=tb, tag="scap." + sd)
        lat = 0.65 + 0.5 * mus
        c.ellipsoid(V(0.112 * w * s, 1.25, -0.044), (0.036 * lat, 0.11, 0.056), rot=(0, 0, -0.3 * s), bones=tb, tag="lat." + sd)
    # ---- the chest: pectorals sloping up into the armpit; a woman's bust under the band
    for s, sd in ((1, "L"), (-1, "R")):
        pk = 0.7 + 0.45 * mus
        c.ellipsoid(V(0.074 * w * s, 1.318, 0.07), (0.08 * w, 0.062, 0.038 * pk), rot=(0.08, 0, -0.28 * s), bones=tb, tag="pec." + sd)
        if F.bust > 0.0:
            bk = 0.8 + 0.25 * F.bust
            c.ellipsoid(V(0.08 * w * s, 1.268 - 0.025 * F.elder, 0.088), (0.062 * bk, 0.06 * bk, 0.056 * bk), rot=(0.2, 0, -0.18 * s), bones=tb, tag="bust." + sd)
            c.ellipsoid(V(0.071 * w * s, 1.305, 0.08), (0.06 * bk, 0.052, 0.042 * bk), rot=(0.1, 0, -0.2 * s), bones=tb, tag="bust." + sd)
    c.ellipsoid(V(0, 1.39, 0.048), (0.072 * w, 0.056, 0.036), bones=tb, tag="ribs")
    # ---- shoulders: the trapezius from the neck to the tips of the shoulders, the clavicles, the deltoids
    for s, sd in ((1, "L"), (-1, "R")):
        tr = 0.034 + 0.014 * mus
        c.capsule(V(0.014 * s, 1.53, -0.03), V(0.152 * w * s, 1.448, -0.02), tr, bones=tb, tag="trap")
        c.capsule(V(0.03 * s, 1.452, 0.05), V(0.15 * w * s, 1.456, 0.012), 0.009, bones=tb, tag="clav." + sd)
        # (the hollow under the outer end of the collarbone, filled so it shades as a dip and not a hole)
        c.ellipsoid(V(0.13 * w * s, 1.4, 0.046), (0.038, 0.04, 0.028), bones=tb, tag="ribs")
        dk = (0.82 + 0.3 * mus) * (0.82 if fem else 1.0)
        side = "upper_arm." + sd
        # the deltoid caps the joint and runs down the arm to its insertion a third of the way to the elbow
        # (a woman's shoulders are narrower on the same bones: a slighter deltoid, nearer the joint)
        c.ellipsoid(V((SHO.x + (0.014 if fem else 0.024)) * s, 1.385, -0.004), (0.052 * dk, 0.076, 0.06 * dk), rot=(0, 0, 0.16 * s), bones={side: 0.6, "chest": 0.4}, tag="delt." + sd)
        c.ellipsoid(V((SHO.x + 0.01) * s, 1.392, 0.038), (0.038 * dk, 0.06, 0.034 * dk), rot=(0.2, 0, 0.12 * s), bones={side: 0.5, "chest": 0.5}, tag="delt." + sd)
    c.ellipsoid(V(0, 1.43, -0.052), (0.094 * w, 0.06, 0.044), bones=tb, tag="trap")
    # ---- the neck, running on into the head (as thick as face.neck's, which the clothes wear)
    nk = 0.84 if fem else 1.0
    c.chain([V(0, 1.42, -0.012), V(0, 1.5, -0.004), V(0, 1.57, -0.006), V(0, 1.63, -0.012)],
            [0.064 * nk, 0.056 * nk, 0.052 * nk, 0.048 * nk], bones=tb, tag="neck", t0=0.0, t1=1.0)
    if not fem:
        for s in (1, -1):
            # the sternocleidomastoids, from behind the ears to the top of the sternum
            c.capsule(V(0.042 * s, 1.575, -0.02), V(0.012 * s, 1.462, 0.044), 0.012 + 0.004 * mus, bones=tb, tag="neck")
        c.ellipsoid(V(0, 1.545, 0.046), (0.011, 0.014, 0.01), bones=tb, tag="neck")


def _legs(c, F):
    """Thighs, knees, calves, ankles and feet, melting into the pelvis at the top."""
    L = F.limb
    fem = F.fem
    m = F.mus
    for s, sd in ((1, "L"), (-1, "R")):
        hip = V(HIP.x * s, HIP.y, HIP.z)
        kn = V(KNEE.x * s, KNEE.y, KNEE.z)
        an = V(ANK.x * s, ANK.y, ANK.z)
        tb = _thigh_bones(sd)
        # the thigh tapers from the hip to the knee; a woman's fuller at the top
        top = (0.09 if fem else 0.083) * L
        c.chain([hip + V(0.0, 0.0, -0.004), hip.lerp(kn, 0.35), hip.lerp(kn, 0.72), kn + V(0, 0.03, 0)],
                [top, (0.08 if fem else 0.078) * L, 0.064 * L, 0.052 * L], bones=tb, tag="thigh." + sd, t0=0.0, t1=1.0)
        # quadriceps: vastus lateralis outside, rectus femoris down the front, vastus medialis a teardrop
        # above the inside of the knee; the adductors fill the inside top, the hamstrings the back
        qk = 0.85 + 0.3 * m
        c.ellipsoid(hip.lerp(kn, 0.48) + V(0.028 * s, 0.0, 0.008), (0.042 * L, 0.16, 0.05 * L * qk), rot=(0, 0, 0.04 * s), bones=tb, tag="quad." + sd)
        c.ellipsoid(hip.lerp(kn, 0.42) + V(0.0, 0.0, 0.04), (0.042 * L, 0.15, 0.032 * qk), bones=tb, tag="quad." + sd)
        c.ellipsoid(hip.lerp(kn, 0.8) + V(-0.026 * s, 0.0, 0.02), (0.035 * L * qk, 0.058, 0.036 * L), bones=tb, tag="vmed." + sd)
        c.ellipsoid(hip.lerp(kn, 0.25) + V(-0.038 * s, -0.01, -0.004), (0.046 * L, 0.11, 0.056 * L), bones=tb, tag="add." + sd)
        c.ellipsoid(hip.lerp(kn, 0.5) + V(0.004 * s, 0.0, -0.038), (0.05 * L, 0.16, 0.042 * L), bones=tb, tag="ham." + sd)
        # the knee: the kneecap and the bony sides
        def sb(p, t=0.0, sd=sd):
            k = smooth(0.46, 0.54, p.y)
            return {"shin." + sd: 1.0 - k, "thigh." + sd: k}
        c.ellipsoid(kn + V(0.0, 0.014, 0.046), (0.026, 0.03, 0.018), bones=sb, tag="patella." + sd)
        c.ball(kn + V(0.0, 0.0, 0.004), 0.054 * L, bones=sb, tag="knee." + sd)
        # the shin and the calf: two heads of the gastrocnemius, the inner lower and fuller
        fb = _foot_bones(sd)
        c.chain([kn + V(0, -0.01, 0), kn.lerp(an, 0.3), kn.lerp(an, 0.65), an + V(0, 0.02, 0)],
                [0.05 * L, 0.05 * L, 0.038 * L, 0.031 * L], bones=lambda p, t, sd=sd: {"shin." + sd: 1.0}, tag="shin." + sd, t0=0.0, t1=1.0)
        cm = 0.85 + 0.3 * m
        c.ellipsoid(kn.lerp(an, 0.26) + V(0.016 * s, 0.0, -0.024), (0.032 * L * cm, 0.088, 0.032 * L * cm), rot=(-0.1, 0, 0), bones={"shin." + sd: 1.0}, tag="calf." + sd)
        c.ellipsoid(kn.lerp(an, 0.31) + V(-0.018 * s, 0.0, -0.022), (0.034 * L * cm, 0.092, 0.034 * L * cm), rot=(-0.1, 0, 0), bones={"shin." + sd: 1.0}, tag="calf." + sd)
        # the ankle bones: the inner higher, the outer lower and further back
        c.ball(an + V(-0.026 * s, 0.012, 0.0), 0.015, bones=fb, tag="ankle." + sd)
        c.ball(an + V(0.028 * s, 0.0, -0.008), 0.015, bones=fb, tag="ankle." + sd)
        # the foot: heel, arch, the ball of the foot and five toes
        fk = (0.9 if fem else 1.0) * (0.85 if F.child else 1.0)
        x = ANK.x * s
        c.ellipsoid(V(x, 0.045, -0.036), (0.032 * fk, 0.037, 0.038 * fk), bones=fb, tag="foot." + sd)
        c.ellipsoid(V(x + 0.004 * s, 0.05, 0.04), (0.038 * fk, 0.031, 0.072 * fk), rot=(-0.12, 0, 0), bones=fb, tag="foot." + sd)
        c.ellipsoid(V(x + 0.006 * s, 0.026, 0.11 * fk), (0.044 * fk, 0.023, 0.037 * fk), bones=fb, tag="foot." + sd)
        for k in range(5):
            # big toe on the inside (towards the midline), the little toe outside and shortest
            u = k / 4.0
            tx = x - 0.028 * s * fk + u * 0.06 * s * fk
            ln = (0.046 - 0.016 * u) * fk
            z0 = (0.134 - 0.022 * u * u) * fk
            r = (0.0125 - 0.0035 * u) * fk if k else 0.0148 * fk
            c.capsule(V(tx, 0.022, z0), V(tx + 0.002 * s * u, 0.016, z0 + ln * 0.62), r, bones={"toe." + sd: 1.0}, tag="toes." + sd)


def _arm(c, F, s, sd):
    """One arm, its own clay: from inside the deltoid to the wrist, where the hand is the character's own."""
    L = F.limb
    m = F.mus
    ab = _arm_bones(sd)
    sh = V(SHO.x * s, SHO.y, SHO.z)
    el = V(ELB.x * s, ELB.y, ELB.z)
    wr = V(WRI.x * s, WRI.y, WRI.z)
    c.chain([sh + V(0.01 * s, 0.0, 0.0), sh.lerp(el, 0.5), el], [0.046 * L, 0.042 * L, 0.037 * L], bones=ab, tag="arm", t0=0.0, t1=1.0)
    # biceps in front, the long and lateral heads of the triceps behind (the arm hangs palm in)
    c.ellipsoid(sh.lerp(el, 0.52) + V(0.0, 0.0, 0.02), (0.032 * L, 0.082, 0.028 * L * (0.8 + 0.35 * m)), bones=ab, tag="bicep")
    c.ellipsoid(sh.lerp(el, 0.42) + V(0.004 * s, 0.0, -0.024), (0.033 * L, 0.092, 0.029 * L * (0.85 + 0.25 * m)), bones=ab, tag="tricep")
    # the elbow, and the forearm: full below the elbow (the flexors and the brachioradialis on the
    # thumb's side), narrowing to a flat wrist
    c.ball(el + V(0.0, 0.004, -0.008), 0.035 * L, bones=ab, tag="arm")
    c.chain([el + V(0, -0.01, 0), el.lerp(wr, 0.3), el.lerp(wr, 0.7), wr + V(0.0, 0.012, 0.0)],
            [0.04 * L, 0.039 * L, 0.03 * L, 0.025 * L], bones=ab, tag="forearm", t0=0.0, t1=1.0)
    c.ellipsoid(el.lerp(wr, 0.24) + V(-0.004 * s, 0.0, 0.018), (0.033 * L, 0.074, 0.03 * L * (0.85 + 0.25 * m)), rot=(0.1, 0, 0), bones=ab, tag="flexor")
    c.ellipsoid(el.lerp(wr, 0.66) + V(0.0, 0.0, 0.002), (0.021 * L, 0.06, 0.028 * L), bones=ab, tag="forearm")


# ---------------------------------------------------------------- the underclothes
def _waist(p):
    # the band rides on the hip bones, a little lower in front than behind
    return 1.005 + 0.012 * smooth(-0.02, -0.09, p.z) - 0.008 * smooth(0.02, 0.09, p.z)


def _drawers_cover(p, info, F):
    """Is point p of the clay inside the drawers?  The waist band sits on the hip bones, a little
    lower in front; the legs end half way down the thigh (a woman's a little higher)."""
    if p.y > _waist(p):
        return False
    tag = info.tag.split(".")[0]
    if tag in ("thigh", "quad", "ham", "add", "vmed", "glute", "medius", "pelvis", "waist", "obl", "abs", "lat"):
        return p.y > _hem(p, F)
    return False


def _hem(p, F):
    # (the hem rises a little on the outside of the leg, as a short pair of drawers is cut)
    return (0.69 if F.fem else 0.655) + 0.025 * smooth(0.08, 0.17, abs(p.x))


def _band_cover(p, info, F):
    """The moxiong: a band of cloth wrapped round the chest from under the arms to below the bust."""
    if not F.fem or F.child:
        return False
    if info.tag.split(".")[0] not in ("bust", "pec", "ribs", "back", "lat", "scap", "abs", "waist", "obl"):
        return False
    lo = 1.19 + 0.02 * smooth(0.0, -0.08, p.z)
    hi = 1.378 - 0.028 * smooth(0.05, -0.08, p.z)
    return lo < p.y < hi


def _seam(info):
    """How much point `info` lies on a line where two masses of the body meet (0 .. 1)."""
    top = sorted(info.tags.items(), key=lambda kv: -kv[1])
    if len(top) < 2:
        return 0.0
    (t1, a), (t2, b2) = top[0], top[1]
    m1, m2 = t1.split(".")[0] in MASSES, t2.split(".")[0] in MASSES
    if not (m1 or m2):
        return 0.0
    if t1.split(".")[0] == t2.split(".")[0] and t1 == t2:
        return 0.0
    k = smooth(0.72, 1.0, b2 / max(a, 1e-6))
    return k * (1.0 if (m1 and m2) else 0.45)


def build(b, o, cloth=HEMP):
    """Sculpt the bare body of person options `o` in its underclothes into Builder b.  Returns the
    figure (for the parts the caller adds after)."""
    F = Figure(o)
    sk = F.skin
    cl = rgb(o.get("underclothes", cloth))
    edge = rgb(HEMP_EDGE)
    res = 0.0115 if not F.child else 0.0095
    body = Clay(res, "body_bare")
    _torso(body, F)
    _legs(body, F)
    line = mix(sk, "a86a58", 0.5)
    line_k = 0.0 if F.child else (0.1 + 0.16 * min(1.0, F.mus)) * (0.5 if F.fem else 1.0)

    def cover(p, info):
        return _drawers_cover(p, info, F) or _band_cover(p, info, F)

    def col(p, info):
        if cover(p, info):
            # hemp: a faint weave, a rolled hem a shade darker
            g = fbm3((p.x * 40.0, p.y * 40.0, p.z * 40.0), 2, 11)
            c = mix(cl, darken(cl, 0.12), 0.35 * g)
            if _drawers_cover(p, info, F) and (p.y < _hem(p, F) + 0.016 or p.y > _waist(p) - 0.024):
                # (the rolled hem, and the band at the waist the drawstring runs through)
                c = mix(c, edge, 0.75)
            return c
        c = sk
        # skin: a warmer flush at the knees, a line where the masses meet
        c = mix(c, mix(sk, "d8907c", 0.4), 0.25 * smooth(0.06, 0.0, abs(p.y - KNEE.y)) * smooth(0.0, 0.05, p.z))
        if line_k > 0.0:
            c = mix(c, line, line_k * _seam(info))
        if not F.fem and info.tag.startswith("pec"):
            # a man's nipples, small and a shade darker, a head below the chin
            for s2 in (1, -1):
                d = (p - V(0.094 * s2 * F.w, 1.286, 0.1)).length
                c = mix(c, mix(sk, "a8665a", 0.45), smooth(0.011, 0.006, d))
        return c

    def post(p, info):
        if not cover(p, info):
            return None
        n = info.n
        # cloth stands off the skin, and creases where it is gathered
        fold = 0.004 + 0.003 * fbm3((p.x * 18.0, p.y * 9.0, p.z * 18.0), 2, 21)
        if _drawers_cover(p, info, F):
            # (fuller over the seat and the crotch, where the drawers hang loose; the band stands out)
            fold += 0.006 * smooth(0.02, 0.12, p.y - _hem(p, F)) * smooth(0.95, 0.85, p.y)
            fold += 0.0025 * smooth(_waist(p) - 0.026, _waist(p) - 0.02, p.y)
        return n * fold

    out = body.build(b, col, cls=SKIN, post=post)
    # the cloth's surface class, so it shades as cloth and the hero's dye never reaches it (assets.gd)
    front = V(0.0, 0.0, -1.0)
    back = V(0.0, 0.0, 1.0)
    for v, info in out:
        p = V(v.co.x, v.co.z, -v.co.y)
        if cover(p, info):
            c = v[b.cl]
            v[b.cl] = (c[0], c[1], c[2], CLOTH)
        # (where the knots go: the front of the band below the navel, the middle of the back of the chest band)
        if abs(p.x - 0.014) < 0.012 and abs(p.y - 0.99) < 0.01 and p.z > front.z:
            front = p
        if abs(p.x) < 0.012 and abs(p.y - 1.29) < 0.012 and p.z < back.z:
            back = p
    for s, sd in ((1, "L"), (-1, "R")):
        arm = Clay(res, "arm_bare_" + sd)
        _arm(arm, F, s, sd)

        def acol(p, info):
            c = mix(F.skin, mix(F.skin, "d8907c", 0.35), 0.3 * smooth(0.03, 0.0, abs(p.y - ELB.y)))
            return mix(c, line, line_k * _seam(info)) if line_k > 0.0 else c
        arm.build(b, acol, cls=SKIN)
    _ties(b, o, F, cl, edge, front, back)
    return F


def _ties(b, o, F, cl, edge, front, back):
    """The drawstring at the waist, tied in front, and for a woman the band's knot behind."""
    knot = front + V(0.0, 0.0, 0.004)
    b.ellipsoid(knot, (0.011, 0.008, 0.006), edge, cls=CLOTH, bone="hips", seg=8, rings=5)
    for s in (1, -1):
        b.tube([knot, knot + V(0.01 * s, -0.035, 0.006), knot + V(0.006 * s, -0.07, 0.008)], [0.0032, 0.0028, 0.0022], edge, cls=CLOTH, bone="hips", seg=5)
    if F.fem and not F.child and back.z < 0.0:
        k2 = back + V(0.0, 0.0, -0.005)
        b.ellipsoid(k2, (0.016, 0.011, 0.008), edge, cls=CLOTH, bone="chest", seg=8, rings=5)
        for s in (1, -1):
            b.tube([k2, k2 + V(0.018 * s, -0.04, -0.01), k2 + V(0.02 * s, -0.085, -0.012)], [0.006, 0.005, 0.003], cl, cls=CLOTH, bone="chest", seg=5)
