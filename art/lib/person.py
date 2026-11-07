"""Articulated xianxia cultivator built with the kit: rig, sculpted head (face.py), hair (hair.py),
layered hanfu (garment.py), weapons and seven baked animation clips.  The character scripts in
``art/characters`` only pick colours and options.

Rig (Godot space, the model faces +Z, +X is the character's left):

    root - hips - spine - chest - neck - head - (eyes, hair_tail)
                              \\- upper_arm.L/R - forearm.L/R - hand.L/R
                              \\- cape - cape2
         hips - thigh.L/R - shin.L/R - foot.L/R
         hips - robe_f, robe_b, robe_l, robe_r   (skirt panels that swing with the legs)

Clips: idle (4 s loop), walk (2.1 s loop, three strides), sit (4 s loop, lotus meditation),
attack, cast, hurt (0.55 s) and victory (1.2 s).  The clip names and lengths match
``Models.anim_person`` in ``scripts/models.gd`` so procedural and Blender characters move alike.

Options (all optional): robe, trim, inner, sash, pants, boots, sleeve, metal, skin, hair,
hair_style (topknot, long, bun, wild, bald), eyes, fem, age, build, jaw, cheek, brow, chin, lip,
lash, glow_eyes, slit_eyes, stern, smile, beard, beard_col, beard_len, cape, ribbon, crown, armor,
sword, blade, hilt, scabbard, staff, staff_gem, halberd, hat (straw, scholar, hood, fur, qing),
hat_col, talisman, horns, horn_col, beast_head (ox, horse), head_col, muzzle_col, embroidery,
jade, pin, collar2, folds, flare, sleeve_w, ahoge, hair_len, tint_cloth, head_scale, scale,
claws, claw_col, claw_len, fangs, tail, beads, badge, bracers, props (accessory.py names), pose
(hold_l, hold_both, flute, hold_r) and extra (a callable adding custom geometry).
"""

import math

import accessory as acc
import face as facelib
import garment as G
import hair as hairlib
from kit import CLOTH, HAIR, METAL, SKIN, STONE, Builder, Rig, V, darken, env, finish_rigged, lighten, mix, rgb
from sculpt import blob3, clamp, fbm3, morph_sphere, smooth, strand

SKIN_COL = "f5d6c2"
HIP_Y = G.HIP_Y
SHO, ELB, WRI, KNEE, ANK = G.SHO, G.ELB, G.WRI, G.KNEE, G.ANK
EYE_Y = facelib.HC.y + facelib.EYE_Y


def make_rig():
    r = Rig("rig")
    r.bone("root", (0, 0, 0), (0, 0.25, 0))
    r.bone("hips", (0, HIP_Y, 0), (0, 1.05, 0), "root")
    r.bone("spine", (0, 1.05, 0), (0, 1.28, 0), "hips")
    r.bone("chest", (0, 1.28, 0), (0, 1.47, 0), "spine")
    r.bone("neck", (0, 1.47, 0.0), (0, 1.56, 0.01), "chest")
    r.bone("head", (0, 1.56, 0.01), (0, 1.88, 0.0), "neck")
    r.bone("eyes", (0, EYE_Y, 0.08), (0, EYE_Y + 0.05, 0.08), "head")
    r.bone("hair_tail", (0, 1.78, -0.1), (0, 1.4, -0.18), "head")
    for s, sd in ((1, "L"), (-1, "R")):
        sh = V(SHO.x * s, SHO.y, SHO.z)
        el = V(ELB.x * s, ELB.y, ELB.z)
        wr = V(WRI.x * s, WRI.y, WRI.z)
        r.bone("upper_arm." + sd, sh, el, "chest")
        r.bone("forearm." + sd, el, wr, "upper_arm." + sd)
        r.bone("hand." + sd, wr, wr + V(0.01 * s, -0.1, 0.01), "forearm." + sd)
        kn = V(KNEE.x * s, KNEE.y, KNEE.z)
        an = V(ANK.x * s, ANK.y, ANK.z)
        r.bone("thigh." + sd, V(0.1 * s, HIP_Y, 0), kn, "hips")
        r.bone("shin." + sd, kn, an, "thigh." + sd)
        r.bone("foot." + sd, an, V(ANK.x * s, 0.03, 0.15), "shin." + sd)
    r.bone("robe_f", (0, 0.98, 0.13), (0, 0.3, 0.2), "hips")
    r.bone("robe_b", (0, 0.98, -0.13), (0, 0.3, -0.22), "hips")
    r.bone("robe_l", (0.17, 0.98, 0), (0.27, 0.3, 0), "hips")
    r.bone("robe_r", (-0.17, 0.98, 0), (-0.27, 0.3, 0), "hips")
    r.bone("cape", (0, 1.45, -0.14), (0, 1.0, -0.24), "chest")
    r.bone("cape2", (0, 1.0, -0.24), (0, 0.45, -0.34), "cape")
    return r


def build(o):
    rig = make_rig()
    b = Builder("body")
    robe = rgb(o.get("robe", "3a8ae8"))
    trim = rgb(o.get("trim", lighten(robe, 0.5)))
    inner = rgb(o.get("inner", "f4f0e8"))
    hair_col = rgb(o.get("hair", "1a1a2a"))
    sash_col = rgb(o.get("sash", darken(robe, 0.55)))
    boots = rgb(o.get("boots", "2a2430"))
    pants = rgb(o.get("pants", darken(robe, 0.6)))
    metal = rgb(o.get("metal", "b8bcc8"))
    skin = rgb(o.get("skin", SKIN_COL))
    gold = rgb(o.get("embroidery", "f0c860"))
    sleeve_col = rgb(o.get("sleeve", robe))
    o = dict(o)
    o.setdefault("skin", skin)
    if o.get("pose") in ("hold_l", "hold_both", "flute"):
        # a raised forearm turns a wide hanfu sleeve's mouth to the viewer: hold things in
        # narrower sleeves
        o.setdefault("sleeve_w", 0.78)
    if "fem" not in o:
        # long hair and no beard reads as a woman unless the script says otherwise
        o["fem"] = o.get("hair_style") == "long" and not o.get("beard", False) and not o.get("stern", False)

    tor = G.Torso(o)
    # ---------------- lower body, robe, sash
    G.legs(b, o, pants, boots, trim)
    G.body(b, o, tor, robe, trim, inner, gold)
    lapel_end = G.collar(b, o, tor, robe, trim, inner, gold)
    G.skirt(b, o, tor, robe, trim, inner, gold, lapel_end)
    G.sash(b, o, tor, sash_col, gold)

    # ---------------- arms
    for s in (1, -1):
        G.sleeve(b, o, s, sleeve_col, trim, inner, gold)
        G.hand(b, o, s, skin)

    # ---------------- neck and head
    if o.get("beast_head") is not None:
        b.tube([V(0, 1.46, 0.0), V(0, 1.6, 0.01)], [0.06, 0.055], o.get("head_col", "6a4a3a"), cls=CLOTH, bones=[{"neck": 0.6, "chest": 0.4}, {"neck": 0.5, "head": 0.5}], seg=14)
        beast_head(b, o)
        top = facelib.HC.y + 0.16
    else:
        f = facelib.Face(o)
        facelib.neck(b, f, o, [{"chest": 0.6, "neck": 0.4}, "neck", {"neck": 0.5, "head": 0.5}, "head"])
        facelib.head(b, o, "head", "eyes")
        s = hairlib.build(b, f, o.get("hair_style", "topknot"), hair_col, o)
        top = hairlib.top_y(s)
        if o.get("beard", False):
            facelib.beard(b, f, o)
    if o.get("crown", False):
        G.crown(b, o, top)
    if o.get("hat"):
        G.hat(b, o, o["hat"], top)
    if o.get("talisman", False):
        G.talisman(b, facelib.HC)
    if o.get("horns", False):
        hcol = o.get("horn_col", "2a1a20")
        for side in (1, -1):
            pts = [V(0.06 * side, top - 0.04, 0.03), V(0.11 * side, top + 0.04, -0.0), V(0.16 * side, top + 0.12, -0.07), V(0.15 * side, top + 0.2, -0.16)]
            strand(b, pts, 0.032, 0.004, hcol, col_tip=lighten(hcol, 0.25), cls=STONE, bone="head", seg=10, per=4)
            for k in range(3):
                q = V(0.06 * side, top - 0.04, 0.03).lerp(pts[2], 0.2 + k * 0.2)
                b.tube([q + V(0, 0.004, 0), q - V(0, 0.004, 0)], [0.031 - k * 0.006] * 2, darken(hcol, 0.3), cls=STONE, bone="head", seg=10, cap0=False, cap1=False)

    # ---------------- ribbons in the hair
    if o.get("ribbon") is not None:
        rc = rgb(o["ribbon"])
        for s2 in (1, -1):
            knot = V(0.055 * s2, top - 0.05, -0.1)
            b.ellipsoid(knot, (0.02, 0.016, 0.012), rc, cls=CLOTH, bone="head", seg=10, rings=6)
            for k in range(2):
                loop = [knot, knot + V(0.04 * s2, 0.03 - 0.05 * k, -0.01), knot + V(0.05 * s2, 0.0 - 0.03 * k, -0.02), knot]
                b.tube(loop, [(0.014, 0.004)] * 4, rc, cls=CLOTH, bone="head", seg=6, up=(0, 0, 1))
            pts = [knot, knot + V(0.03 * s2, -0.12, -0.06), knot + V(0.05 * s2, -0.28, -0.1), knot + V(0.06 * s2, -0.42, -0.1)]
            bones = [{"head": 1.0}, {"head": 0.5, "hair_tail": 0.5}, {"hair_tail": 1.0}, {"hair_tail": 1.0}]
            b.ribbon(pts, [0.02, 0.022, 0.018, 0.006], (1, 0, 0), rc, bones=bones, col_end=lighten(rc, 0.3))

    # ---------------- cape, armour, weapons
    if o.get("cape") is not None:
        G.cape(b, o, rgb(o["cape"]))
    if o.get("armor", False):
        G.armour(b, o, tor, metal)
    hand_r = WRI * V(-1, 1, 1) + V(-0.004, -0.075, 0.02)
    if o.get("sword", False):
        G.sword(b, "hand.R", hand_r, rgb(o.get("blade", "dce8ff")), rgb(o.get("hilt", "3a3048")))
        G.scabbard(b, rgb(o.get("scabbard", "2a2a40")))
    if o.get("staff", False):
        G.staff(b, hand_r + V(0.004, 0.0, 0.0), rgb(o.get("staff_gem", "8af0ff")))
    if o.get("halberd", False):
        G.halberd(b, hand_r)

    # ornaments and monstrous extras
    if o.get("beads"):
        G.court_beads(b, tor, *([o["beads"]] if isinstance(o["beads"], str) else []))
    if o.get("badge"):
        G.rank_badge(b, tor, *([o["badge"]] if isinstance(o["badge"], str) else []))
    for s2 in (1, -1):
        if o.get("claws"):
            G.claw_nails(b, s2, o.get("claw_col", "1a1418"), o.get("claw_len", 0.05))
        if o.get("bracers"):
            G.bracers(b, s2, rgb(o["bracers"]))
    if o.get("tail"):
        G.demon_tail(b, rgb(o["tail"]), o.get("tail_tip", "ff4020"))
    if o.get("fangs") and o.get("beast_head") is None:
        for s2 in (1, -1):
            tip = facelib.HC + V(0.012 * s2, facelib.MOUTH_Y - 0.004, facelib.RZF * 0.86)
            b.cone(tip, 0.0035, 0.012, "f8f4e8", cls=STONE, bone="head", seg=5, rot=(math.pi, 0, 0))
    # signature props (art/lib/accessory.py): names, or (name, {kwargs}) pairs
    for pr in o.get("props", []):
        name, kw = (pr, {}) if isinstance(pr, str) else pr
        if name == "star_crown":
            kw = dict(kw, top=top)
        getattr(acc, name)(b, **kw)
    if o.get("extra") is not None:
        o["extra"](b, rig, o, tor)
    if o.get("tint_cloth", False):
        # a recolourable enemy: every cloth surface takes the colour the game asks for
        for v in b.bm.verts:
            if v[b.cl][3] > 0.94:
                v[b.tl] = 1.0
    hk = o.get("head_scale", 1.0)
    if hk != 1.0:
        pivot = V(0, 1.58, 0.0)
        b.scale_where(lambda w: w.get("head", 0.0) + w.get("eyes", 0.0) + w.get("hair_tail", 0.0) >= 0.5, pivot, hk)
        for nm in ("eyes", "hair_tail"):
            h0, t0, par = rig.bones[nm]
            rig.bones[nm] = (pivot + (V(h0) - pivot) * hk, pivot + (V(t0) - pivot) * hk, par)
        h0, t0, par = rig.bones["head"]
        rig.bones["head"] = (h0, pivot + (V(t0) - pivot) * hk, par)
    sc = o.get("scale", 1.0)
    if sc != 1.0:
        for v in b.bm.verts:
            v.co *= sc
        for nm in list(rig.bones):
            h, t, p = rig.bones[nm]
            rig.bones[nm] = (h * sc, t * sc, p)
    return b, rig


# ---------------------------------------------------------------- animal heads
def beast_head(b, o):
    """Animal heads for the runners of the underworld: 'ox' (Ox-Head) and 'horse' (Horse-Face),
    sculpted like the human heads: one surface for skull, brow, cheeks and muzzle."""
    kind = o["beast_head"]
    hc = rgb(o.get("head_col", "6a4a3a"))
    muz = rgb(o.get("muzzle_col", lighten(hc, 0.25)))
    eye = o.get("eyes", "ff4020")
    C = facelib.HC + V(0, 0.02, 0.0)
    if kind == "ox":
        def shape(d):
            p = V(d.x * 0.16, d.y * 0.15, d.z * 0.15)
            front = smooth(0.0, 0.9, d.z)
            low = smooth(-0.1, -0.9, d.y)
            # broad muzzle pushed forward and down
            p.z += 0.12 * front * smooth(0.6, -0.6, d.y)
            p.y -= 0.05 * front * low
            p.x *= 1.0 - 0.18 * front * low
            # heavy brow and poll
            q = p.copy()
            off = 0.02 * blob3(q, (0, 0.07, 0.1), (0.12, 0.03, 0.05)) + 0.015 * blob3(q, (0, 0.12, -0.02), (0.1, 0.04, 0.06))
            for s in (1, -1):
                off -= 0.012 * blob3(q, (0.07 * s, 0.03, 0.14), (0.03, 0.025, 0.03))
            return p + p.normalized() * off

        def col(p, d):
            c = mix(hc, muz, smooth(0.12, 0.24, p.z))
            c = mix(c, darken(hc, 0.3), smooth(0.4, 1.0, -d.y) * 0.4)
            return mix(c, lighten(c, 0.12), fbm3((p.x * 30, p.y * 30, p.z * 30), 2, 4) - 0.5)

        morph_sphere(b, C, shape, col, cls=CLOTH, bone="head", seg=32, rings=24)
        nose_c = C + V(0, -0.06, 0.27)
        b.ellipsoid(nose_c, (0.09, 0.055, 0.03), darken(muz, 0.15), cls=SKIN, bone="head", seg=16, rings=8)
        for s in (1, -1):
            b.ellipsoid(nose_c + V(0.04 * s, -0.004, 0.022), (0.016, 0.012, 0.008), "1a1010", cls=SKIN, bone="head", seg=10, rings=5)
            horn = [C + V(0.12 * s, 0.1, 0.0), C + V(0.24 * s, 0.13, -0.01), C + V(0.33 * s, 0.2, 0.04), C + V(0.35 * s, 0.31, 0.11), C + V(0.32 * s, 0.38, 0.15)]
            strand(b, horn, 0.045, 0.004, "8a7a60", col_tip="f8f0e0", cls=STONE, bone="head", seg=12, per=4, power=1.2)
            for k in range(4):
                q = horn[0].lerp(horn[1], 0.3 + k * 0.2)
                b.tube([q + V(0.004 * s, 0, 0), q - V(0.004 * s, 0, 0)], [0.044 - k * 0.003] * 2, "6a5a44", cls=STONE, bone="head", seg=12, cap0=False, cap1=False)
            ear = [C + V(0.14 * s, 0.04, -0.02), C + V(0.22 * s, 0.03, -0.03), C + V(0.27 * s, 0.0, -0.02)]
            b.tube(ear, [(0.03, 0.012), (0.04, 0.012), (0.01, 0.006)], hc, cls=CLOTH, bone="head", seg=8, up=(0, 0, 1))
            b.eye(C + V(0.085 * s, 0.035, 0.14), 0.026, eye, side=s, bone="eyes", rot_y=0.45, h=0.85, glow=True)
            b.tube([C + V(0.04 * s, 0.07, 0.165), C + V(0.1 * s, 0.075, 0.15), C + V(0.13 * s, 0.06, 0.12)], [0.012, 0.014, 0.006], darken(hc, 0.4), cls=HAIR, bone="head", seg=6)
        ring = [nose_c + V(math.sin(2 * math.pi * i / 16) * 0.04, -0.035 + math.cos(2 * math.pi * i / 16) * 0.035, 0.035) for i in range(17)]
        b.tube(ring, [0.0075] * 17, "e8c050", cls=METAL, bone="head", seg=8, cap0=False, cap1=False)
        # tuft between the horns
        for k in range(7):
            a = (k / 6 - 0.5) * 1.6
            root = C + V(math.sin(a) * 0.06, 0.14, 0.04 + math.cos(a) * 0.02)
            strand(b, [root, root + V(math.sin(a) * 0.02, 0.04, 0.03), root + V(math.sin(a) * 0.03, 0.01, 0.07)], 0.014, 0.002, darken(hc, 0.35), cls=HAIR, bone="head", seg=5, per=3)
    else:
        def shape(d):
            p = V(d.x * 0.11, d.y * 0.14, d.z * 0.14)
            front = smooth(-0.1, 0.95, d.z)
            # long face reaching forward and down to the muzzle
            p.z += 0.26 * front ** 1.4 * smooth(0.7, -0.3, d.y)
            p.y -= 0.16 * front ** 1.6 * smooth(0.5, -0.5, d.y)
            p.x *= 1.0 - 0.3 * front ** 2 * smooth(0.3, -0.6, d.y)
            q = p.copy()
            off = 0.0
            for s in (1, -1):
                off += 0.018 * blob3(q, (0.08 * s, -0.04, 0.05), (0.03, 0.05, 0.05))   # cheek
                off += 0.012 * blob3(q, (0.04 * s, -0.17, 0.33), (0.03, 0.03, 0.03))   # nostrils
            return p + p.normalized() * off

        def col(p, d):
            c = mix(hc, muz, smooth(0.25, 0.36, p.z))
            c = mix(c, lighten(hc, 0.5), blob3(p, (0, 0.02, 0.2), (0.025, 0.14, 0.12)) * 0.8)  # blaze
            return mix(c, darken(hc, 0.3), smooth(0.4, 1.0, -d.y) * 0.3)

        morph_sphere(b, C, shape, col, cls=CLOTH, bone="head", seg=32, rings=24)
        for s in (1, -1):
            b.ellipsoid(C + V(0.035 * s, -0.17, 0.4), (0.012, 0.02, 0.01), "1a1010", cls=SKIN, bone="head", seg=8, rings=5, rot=(0, 0.4 * s, 0))
            ear = [C + V(0.06 * s, 0.12, -0.03), C + V(0.075 * s, 0.2, -0.04), C + V(0.07 * s, 0.26, -0.05)]
            b.tube(ear, [(0.028, 0.012), (0.024, 0.01), (0.002, 0.002)], hc, cls=CLOTH, bone="head", seg=8, up=(0, 0, 1))
            b.eye(C + V(0.095 * s, 0.03, 0.06), 0.028, eye, side=s, bone="eyes", rot_y=1.0, h=0.95, glow=True)
        mane = rgb(o.get("hair", "1a1010"))
        for i in range(16):
            y = 0.17 - i * 0.03
            z = -0.04 - i * 0.012
            root = C + V(0, y, z)
            strand(b, [root, root + V(0.0, 0.03, -0.05), root + V((i % 2 - 0.5) * 0.04, -0.03, -0.14)], 0.02, 0.002, mane if i % 2 else darken(mane, 0.3), col_tip=lighten(mane, 0.2), cls=HAIR, bone="head" if i < 9 else "neck", seg=6, per=3)


# ---------------------------------------------------------------- animation
def _blink(t, at):
    for a in at:
        if a <= t < a + 0.13:
            k = (t - a) / 0.13
            return 0.1 + 0.9 * abs(1.0 - 2.0 * k)
    return 1.0


def _secondary(p, t, walking, sit, legs_x, lag):
    """Robe panels, cape and hair follow the legs and the stride, a beat behind."""
    fwd = max(-legs_x[0], -legs_x[1]) if not sit else 1.2
    back = max(legs_x[0], legs_x[1])
    p["robe_f"] = ((-max(0.0, fwd) * 0.8 - (0.12 if walking else 0.0), 0, 0), (0, 0, 0))
    p["robe_b"] = ((max(0.0, back) * 0.6 + (0.28 if walking else 0.03), 0, 0), (0, 0, 0))
    p["robe_l"] = ((-abs(legs_x[0]) * 0.35 - (0.6 if sit else 0.0), 0, -0.05 if not sit else -0.5), (0, 0, 0))
    p["robe_r"] = ((-abs(legs_x[1]) * 0.35 - (0.6 if sit else 0.0), 0, 0.05 if not sit else 0.5), (0, 0, 0))
    p["cape"] = ((0.1 + (0.42 + 0.12 * lag if walking else 0.04 * math.sin(t * 2 * math.pi / 4)), 0.03 * lag, 0), (0, 0, 0))
    p["cape2"] = ((0.08 + (0.22 * abs(lag) if walking else 0.03 * math.sin(t * 2 * math.pi / 2)), 0, 0.04 * lag), (0, 0, 0))
    p["hair_tail"] = ((0.12 + (0.3 if walking else 0.05) * abs(lag), 0, lag * (0.22 if walking else 0.06)), (0, 0, 0))


def clip_idle(t):
    """Standing at ease: weight resting on one leg (contrapposto) and slowly shifting, breathing in
    the chest, relaxed arms, the head looking about."""
    w = 2 * math.pi / 4.0
    br = math.sin(t * w * 2)
    shift = math.sin(t * w)               # weight shift from leg to leg over the loop
    p = {}
    p["root"] = ((0, 0, 0), (0.012 * shift, 0, 0))
    p["hips"] = ((0.02, math.sin(t * w) * 0.05, -0.035 * shift), (0, br * 0.006 - 0.006 * abs(shift), 0))
    p["spine"] = ((br * 0.012, -0.02 * shift, 0.02 * shift), (0, 0, 0))
    p["chest"] = ((-br * 0.018, -0.02 * shift, 0.018 * shift), (0, 0, 0))
    p["neck"] = ((0.03, 0, 0), (0, 0, 0))
    p["head"] = ((math.sin(t * w) * 0.04 - 0.02, math.sin(t * w + 0.6) * 0.18, -0.03 * shift + math.sin(t * w * 2) * 0.02), (0, 0, 0))
    p["upper_arm.L"] = ((0.03 + math.sin(t * w * 2) * 0.035, 0, -0.07 - br * 0.02), (0, 0, 0))
    p["upper_arm.R"] = ((0.03 - math.sin(t * w * 2) * 0.035, 0, 0.07 + br * 0.02), (0, 0, 0))
    p["forearm.L"] = ((-0.22, 0.1, 0), (0, 0, 0))
    p["forearm.R"] = ((-0.26, -0.1, 0), (0, 0, 0))
    p["hand.L"] = ((0.06, 0.15, 0), (0, 0, 0))
    p["hand.R"] = ((0.06, -0.15, 0), (0, 0, 0))
    # the leg carrying less weight bends a little at the knee
    p["thigh.L"] = ((-0.04 * max(0.0, -shift), 0, 0.03 * shift), (0, 0, 0))
    p["thigh.R"] = ((-0.04 * max(0.0, shift), 0, 0.03 * shift), (0, 0, 0))
    p["shin.L"] = ((0.03 + 0.09 * max(0.0, -shift), 0, 0), (0, 0, 0))
    p["shin.R"] = ((0.03 + 0.09 * max(0.0, shift), 0, 0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (1.3, 3.4)), 1))
    _secondary(p, t, False, False, (0.0, 0.0), math.sin(t * w * 2))
    return p


WALK_T = 2.1


def clip_walk(t):
    """Three strides: heel strike and toe-off, a double bob of the hips per stride, hips and
    shoulders counter-rotating, arms swinging against the legs, a slight forward lean."""
    ph = t * 2 * math.pi * 3 / WALK_T
    sw = math.sin(ph)
    cw = math.cos(ph)
    p = {}
    legs = (sw * 0.55, -sw * 0.55)
    p["thigh.L"] = ((legs[0] - 0.05, 0, 0.02), (0, 0, 0))
    p["thigh.R"] = ((legs[1] - 0.05, 0, -0.02), (0, 0, 0))
    # the knee bends most as the leg swings through (after toe-off)
    p["shin.L"] = ((0.12 + max(0.0, -cw) * 0.95 + 0.1 * max(0.0, sw), 0, 0), (0, 0, 0))
    p["shin.R"] = ((0.12 + max(0.0, cw) * 0.95 + 0.1 * max(0.0, -sw), 0, 0), (0, 0, 0))
    # heel strike (toe up) when the leg is forward, toe-off (heel up) when it trails
    p["foot.L"] = ((-0.28 * max(0.0, -sw) + 0.3 * max(0.0, sw) * max(0.0, -cw), 0, 0), (0, 0, 0))
    p["foot.R"] = ((-0.28 * max(0.0, sw) + 0.3 * max(0.0, -sw) * max(0.0, cw), 0, 0), (0, 0, 0))
    p["upper_arm.L"] = ((sw * 0.42 + 0.05, 0, -0.1), (0, 0, 0))
    p["upper_arm.R"] = ((-sw * 0.36 + 0.05, 0, 0.1), (0, 0, 0))
    p["forearm.L"] = ((-0.3 - max(0.0, -sw) * 0.35, 0.1, 0), (0, 0, 0))
    p["forearm.R"] = ((-0.3 - max(0.0, sw) * 0.35, -0.1, 0), (0, 0, 0))
    p["hand.L"] = ((0.1, 0.15, 0), (0, 0, 0))
    p["hand.R"] = ((0.1, -0.15, 0), (0, 0, 0))
    bob = abs(math.sin(ph))
    p["hips"] = ((0.06, sw * 0.13, -0.04 * cw), (0, 0.035 * bob - 0.012, 0))
    p["spine"] = ((0.03, -sw * 0.06, 0.02 * cw), (0, 0, 0))
    p["chest"] = ((0.02 - 0.015 * bob, -sw * 0.1, 0), (0, 0, 0))
    p["neck"] = ((0.0, sw * 0.04, 0), (0, 0, 0))
    p["head"] = ((-0.06 + 0.02 * bob, sw * 0.05, 0.015 * cw), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (0.9,)), 1))
    lag = math.sin(ph - 0.8)
    _secondary(p, t, True, False, legs, lag)
    return p


def clip_sit(t):
    """Lotus meditation: crossed legs, hands resting in the lap, slow deep breaths, eyes closed."""
    w = 2 * math.pi / 4.0
    br = math.sin(t * w)
    p = {}
    for i, sd in enumerate(("L", "R")):
        s = 1 if sd == "L" else -1
        p["thigh." + sd] = ((-1.45, 0, 0.55 * s), (0, 0, 0))
        p["shin." + sd] = ((2.5, 0, 0), (0, 0, 0))
        p["foot." + sd] = ((0.3, 0, 0), (0, 0, 0))
        p["upper_arm." + sd] = ((-0.5 - br * 0.02, 0, 0.25 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.95, 0, -0.35 * s), (0, 0, 0))
        p["hand." + sd] = ((0.25, 0, 0.2 * s), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, br * 0.006, 0))
    p["spine"] = ((-0.03, 0, 0), (0, 0, 0))
    p["chest"] = ((-br * 0.025, 0, 0), (0, br * 0.004, 0))
    p["head"] = ((0.14 + br * 0.02, 0, 0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.12, 1))
    _secondary(p, t, False, True, (-1.45, -1.45), br)
    return p


ACT_T = 0.55


def _base_for_act():
    return clip_idle(0.0)


def clip_attack(t):
    """Wind-up with the sword behind the head, step in on the left foot, a fast diagonal cut,
    follow-through and recovery."""
    k = t / ACT_T
    e = env(k)
    wind = smooth(0.0, 0.3, k) * (1.0 - smooth(0.3, 0.45, k))
    cut = smooth(0.3, 0.62, k)
    rec = smooth(0.7, 1.0, k)
    p = _base_for_act()
    p["upper_arm.R"] = ((-2.4 * wind + (-2.4 + 3.1 * cut) * (1 - wind) * (1 - rec) * smooth(0.25, 0.32, k), 0, -(0.45 - 0.9 * cut) * (1 - rec)), (0, 0, 0))
    p["forearm.R"] = ((-0.9 * wind - 0.15 * cut * (1 - rec), 0, 0), (0, 0, 0))
    p["hand.R"] = ((0.3 * cut * (1 - rec), 0, 0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.5 * e, 0, -0.55 * e), (0, 0, 0))
    p["forearm.L"] = ((-0.6 * e, 0, 0), (0, 0, 0))
    turn = (0.45 * wind - 0.6 * cut) * (1 - rec)
    p["hips"] = ((0.1 * e, turn * 0.5, 0), (0, -0.03 * e, 0.09 * e))
    p["spine"] = ((0.06 * e, turn * 0.3, 0), (0, 0, 0))
    p["chest"] = ((0.12 * e, turn * 0.5, 0), (0, 0, 0))
    p["head"] = ((0.05 * e, -turn * 0.4, 0), (0, 0, 0))
    p["thigh.L"] = ((-0.6 * e, 0, 0.05), (0, 0, 0))
    p["shin.L"] = ((0.5 * e, 0, 0), (0, 0, 0))
    p["thigh.R"] = ((0.4 * e, 0, -0.05), (0, 0, 0))
    p["shin.R"] = ((0.25 * e, 0, 0), (0, 0, 0))
    p["foot.R"] = ((0.3 * e, 0, 0), (0, 0, 0))
    _secondary(p, t, False, False, (-0.6 * e, 0.4 * e), e)
    return p


def clip_cast(t):
    """Both hands raised forward forming a seal, sleeves and cape lifting with the qi."""
    e = env(t / ACT_T)
    p = _base_for_act()
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-1.45 * e, 0.2 * s * e, -(0.12 + 0.45 * e) * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.7 * e, -0.3 * s * e, 0), (0, 0, 0))
        p["hand." + sd] = ((-0.5 * e, 0, 0.2 * s * e), (0, 0, 0))
    p["head"] = ((-0.22 * e, 0, 0), (0, 0, 0))
    p["chest"] = ((-0.12 * e, 0, 0), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, 0.04 * e, 0))
    p["cape"] = ((0.45 * e, 0, 0), (0, 0, 0))
    p["cape2"] = ((0.25 * e, 0, 0), (0, 0, 0))
    p["hair_tail"] = ((0.4 * e, 0, 0), (0, 0, 0))
    p["robe_b"] = ((0.2 * e, 0, 0), (0, 0, 0))
    return p


def clip_hurt(t):
    """Recoil: thrown back at the chest, head snapping, arms flung, a step back, eyes screwed."""
    k = t / ACT_T
    e = env(k)
    snap = math.sin(math.pi * clamp(k * 1.6)) if k < 0.62 else 0.0
    p = _base_for_act()
    p["chest"] = ((-0.35 * e, 0, 0.06 * e), (0, 0, 0))
    p["spine"] = ((-0.12 * e, 0, 0), (0, 0, 0))
    p["neck"] = ((-0.1 * snap, 0, 0), (0, 0, 0))
    p["head"] = ((-0.28 * e, 0.2 * e, 0.05 * snap), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((0.45 * e, 0, -0.25 * s * e), (0, 0, 0))
        p["forearm." + sd] = ((-0.5 * e, 0, 0), (0, 0, 0))
    p["hips"] = ((-0.05 * e, 0, 0), (0, -0.02 * e, -0.09 * e))
    p["thigh.R"] = ((0.3 * e, 0, 0), (0, 0, 0))
    p["shin.R"] = ((0.3 * e, 0, 0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.85 * e, 1))
    _secondary(p, t, False, False, (0.0, 0.3 * e), -e)
    return p


def clip_victory(t):
    """Sword raised to the sky, the free hand on the hip, chest out, a settling bounce."""
    k = min(1.0, t / 0.35)
    e = math.sin(k * math.pi / 2)
    settle = 0.04 * math.sin(clamp((t - 0.35) / 0.6) * math.pi) if t > 0.35 else 0.0
    p = _base_for_act()
    p["upper_arm.R"] = ((-2.8 * e, 0, -0.18), (0, 0, 0))
    p["forearm.R"] = ((-0.2, 0, 0), (0, 0, 0))
    p["hand.R"] = ((-0.2 * e, 0, 0), (0, 0, 0))
    p["upper_arm.L"] = ((0.12, 0, -0.45 * e), (0, 0, 0))
    p["forearm.L"] = ((-1.3 * e, 0.4 * e, 0), (0, 0, 0))
    p["head"] = ((-0.16 * e, 0, 0), (0, 0, 0))
    p["chest"] = ((-0.08 * e - settle, 0, 0), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, settle * 0.3, 0))
    return p


CLIPS = {
    "idle": (4.0, clip_idle),
    "walk": (WALK_T, clip_walk),
    "sit": (4.0, clip_sit),
    "attack": (ACT_T, clip_attack),
    "cast": (ACT_T, clip_cast),
    "hurt": (ACT_T, clip_hurt),
    "victory": (1.2, clip_victory),
}


def _with_posture(fn, age):
    """Elders stand with a slight stoop: the spine and neck bend forward a little in every clip."""
    k = smooth(0.5, 1.0, age)

    def clip(t):
        p = fn(t)
        for nm, amt in (("spine", 0.08), ("chest", 0.1), ("neck", 0.12), ("head", -0.1)):
            rot, loc = p.get(nm, ((0, 0, 0), (0, 0, 0)))[:2]
            rest = p.get(nm, ((0, 0, 0), (0, 0, 0)))[2:]
            p[nm] = ((rot[0] + amt * k, rot[1], rot[2]), loc) + tuple(rest)
        return p

    return clip


# holding poses, added on top of every clip so a prop stays in hand (see accessory.py)
POSES = {
    # left forearm raised in front of the body: a lantern, a basket, a ledger, a pearl
    "hold_l": {"upper_arm.L": (-0.35, 0.0, -0.2), "forearm.L": (-1.2, 0.0, 0.0), "hand.L": (0.25, 0.0, 0.0)},
    # both hands together in front of the chest: a bowl, a teapot
    "hold_both": {"upper_arm.L": (-0.45, 0.0, -0.32), "forearm.L": (-1.25, 0.0, 0.0), "upper_arm.R": (-0.45, 0.0, 0.32), "forearm.R": (-1.25, 0.0, 0.0)},
    # a flute at the lips
    "flute": {"upper_arm.L": (-0.75, 0.0, -0.45), "forearm.L": (-1.9, 0.0, 0.0), "upper_arm.R": (-0.6, 0.0, 0.05), "forearm.R": (-1.75, 0.0, 0.0), "head": (0.06, 0.0, -0.1)},
    # something tall held upright in the right hand (an oar, a rod over the shoulder)
    "hold_r": {"upper_arm.R": (-0.2, 0.0, 0.0), "forearm.R": (-0.55, 0.0, 0.0)},
}


def _with_pose(fn, pose):
    def clip(t):
        p = fn(t)
        for nm, (x, y, z) in pose.items():
            val = p.get(nm, ((0, 0, 0), (0, 0, 0)))
            rot, loc = val[0], val[1]
            p[nm] = ((rot[0] + x, rot[1] + y, rot[2] + z), loc) + tuple(val[2:])
        return p

    return clip


def export_person(rel, opts, clips=None):
    b, rig = build(opts)
    clips = clips or CLIPS
    if opts.get("age", 0.0) > 0.5:
        clips = {nm: (secs, _with_posture(fn, opts["age"])) for nm, (secs, fn) in clips.items()}
    if opts.get("pose") in POSES:
        pose = POSES[opts["pose"]]
        # actions free the arms: the pose holds in idle, walk and sit
        clips = {nm: (secs, _with_pose(fn, pose) if nm in ("idle", "walk", "sit") else fn) for nm, (secs, fn) in clips.items()}
    print("[art] %s: %d triangles" % (rel, b.tri_count()))
    return finish_rigged(b, rig, rel, clips, samples=16, dist=0.22, strength=0.5, floor_y=0.0, floor_k=0.2)

