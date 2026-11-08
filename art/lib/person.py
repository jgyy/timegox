"""Articulated xianxia cultivator built with the kit: rig, sculpted head (face.py), hair (hair.py),
layered hanfu (garment.py), weapons and twenty-one baked animation clips (eleven for the world and
battle, ten cutscene gestures).  The character scripts in
``art/characters`` only pick colours and options.

Rig (Godot space, the model faces +Z, +X is the character's left):

    root - hips - spine - chest - neck - head - (eyes, mouth, hair_tail - hair_tail2)
                              \\- upper_arm.L/R - forearm.L/R - (hand.L/R - fingers, thumb), sleeve.L/R
                              \\- cape - cape2 - cape3
         hips - thigh.L/R - shin.L/R - foot.L/R - toe.L/R
         hips - robe_f, robe_b, robe_l, robe_r   (skirt panels that swing with the legs)

Clips: idle (4 s loop), walk (2.2 s loop, four steps), run (1.12 s loop, the qinggong dash the
hero uses on the road), sit (4 s loop, lotus meditation), talk (3 s loop, gestures and speech),
bow (1.6 s, the cupped-fist salute), attack, cast, hurt (0.55 s), victory (1.2 s) and die (1.4 s,
held at the end).  ``Assets.animate`` in ``scripts/assets.gd`` plays them.

Options (all optional): robe, trim, inner, sash, pants, boots, sleeve, metal, skin, hair,
hair_style (topknot, long, bun, wild, bald), eyes, fem, age, build, jaw, cheek, brow, chin, lip,
lash, glow_eyes, slit_eyes, stern, smile, beard, beard_col, beard_len, cape, ribbon, crown, armor,
sword, blade, hilt, scabbard, staff, staff_gem, halberd, hat (straw, scholar, hood, fur, qing),
hat_col, talisman, horns, horn_col, beast_head (ox, horse), head_col, muzzle_col, embroidery,
jade, pin, collar2, folds, flare, sleeve_w, ahoge, hair_len, tint_cloth, head_scale, scale,
claws, claw_col, claw_len, fangs, tail, beads, badge, bracers, props (accessory.py names), pose
(hold_l, hold_both, flute, hold_r) and extra (a callable adding custom geometry).  Race features
(wings, crest, ears, tails, scales, whiskers and horns "antler") are built by art/lib/race.py.
"""

import math

import accessory as acc
import face as facelib
import garment as G
import hair as hairlib
import race
from kit import CLOTH, HAIR, METAL, SKIN, STONE, Builder, Rig, V, darken, env, finish_rigged, harmonise, lighten, mix, rgb
from kit import hsv as kit_hsv
from kit import to_hsv as kit_to_hsv
from sculpt import blob3, clamp, fbm3, morph_sphere, smooth, strand

SKIN_COL = "f5d6c2"
HIP_Y = G.HIP_Y
SHO, ELB, WRI, KNEE, ANK = G.SHO, G.ELB, G.WRI, G.KNEE, G.ANK
EYE_Y = facelib.HC.y + facelib.EYE_Y


def make_rig():
    """The skeleton (see the module docstring).  Beyond the core chain it carries the bones a game
    rig adds for secondary motion and expression (references: mocaponline skeleton hierarchy
    guide, gamedev.net "Demystifying character rigging"): a pocket bone per hanfu sleeve, finger and
    thumb bones per hand, toe bones for the roll of the foot, a mouth bone for speech, a two-bone
    hair tail and a three-bone cape."""
    r = Rig("rig")
    r.bone("root", (0, 0, 0), (0, 0.25, 0))
    r.bone("hips", (0, HIP_Y, 0), (0, 1.05, 0), "root")
    r.bone("spine", (0, 1.05, 0), (0, 1.28, 0), "hips")
    r.bone("chest", (0, 1.28, 0), (0, 1.47, 0), "spine")
    r.bone("neck", (0, 1.47, 0.0), (0, 1.56, 0.01), "chest")
    r.bone("head", (0, 1.56, 0.01), (0, 1.88, 0.0), "neck")
    r.bone("eyes", (0, EYE_Y, 0.08), (0, EYE_Y + 0.05, 0.08), "head")
    mouth_y = facelib.HC.y + facelib.MOUTH_Y
    r.bone("mouth", (0, mouth_y + 0.001, 0.09), (0, mouth_y + 0.03, 0.09), "head")
    r.bone("hair_tail", (0, 1.78, -0.1), (0, 1.4, -0.18), "head")
    r.bone("hair_tail2", (0, 1.4, -0.18), (0, 1.05, -0.2), "hair_tail")
    for s, sd in ((1, "L"), (-1, "R")):
        sh = V(SHO.x * s, SHO.y, SHO.z)
        el = V(ELB.x * s, ELB.y, ELB.z)
        wr = V(WRI.x * s, WRI.y, WRI.z)
        r.bone("upper_arm." + sd, sh, el, "chest")
        r.bone("forearm." + sd, el, wr, "upper_arm." + sd)
        r.bone("sleeve." + sd, el.lerp(wr, 0.35) + V(0, 0, -0.04), wr + V(0, -0.12, -0.1), "forearm." + sd)
        r.bone("hand." + sd, wr, wr + V(0.01 * s, -0.1, 0.01), "forearm." + sd)
        kn = wr + V(0.003 * s, -0.087, 0.008)
        r.bone("fingers." + sd, kn, kn + V(0.0, -0.07, 0.0), "hand." + sd)
        tb = wr + V(-0.002 * s, -0.025, 0.024)
        r.bone("thumb." + sd, tb, tb + V(-0.012 * s, -0.05, 0.02), "hand." + sd)
        kn2 = V(KNEE.x * s, KNEE.y, KNEE.z)
        an = V(ANK.x * s, ANK.y, ANK.z)
        r.bone("thigh." + sd, V(0.1 * s, HIP_Y, 0), kn2, "hips")
        r.bone("shin." + sd, kn2, an, "thigh." + sd)
        r.bone("foot." + sd, an, V(ANK.x * s, 0.03, 0.12), "shin." + sd)
        r.bone("toe." + sd, V(ANK.x * s, 0.03, 0.12), V(ANK.x * s, 0.03, 0.2), "foot." + sd)
    r.bone("robe_f", (0, 0.98, 0.13), (0, 0.3, 0.2), "hips")
    r.bone("robe_b", (0, 0.98, -0.13), (0, 0.3, -0.22), "hips")
    r.bone("robe_l", (0.17, 0.98, 0), (0.27, 0.3, 0), "hips")
    r.bone("robe_r", (-0.17, 0.98, 0), (-0.27, 0.3, 0), "hips")
    r.bone("cape", (0, 1.45, -0.14), (0, 1.1, -0.22), "chest")
    r.bone("cape2", (0, 1.1, -0.22), (0, 0.75, -0.3), "cape")
    r.bone("cape3", (0, 0.75, -0.3), (0, 0.42, -0.36), "cape2")
    return r


def build(o):
    rig = make_rig()
    b = Builder("body")
    o = harmonise(o)
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
    # costumes painted at full saturation read as neon under the cel shading: calm them a little
    robe, sleeve_col, sash_col = soften(robe), soften(sleeve_col), soften(sash_col, 0.42, 0.88)
    # palette slots (used when the cloth is tinted, i.e. recolourable enemies): trousers, sash and
    # cape in the secondary colour, the collar and trims in the accent, the robe in the primary
    # ---------------- lower body, robe, sash
    b.cur_pal = 0.5
    G.legs(b, o, pants, boots, trim)
    b.cur_pal = 0.0
    robe_start = len(b.bm.verts)
    G.body(b, o, tor, robe, trim, inner, gold)
    b.cur_pal = 1.0
    lapel_end = G.collar(b, o, tor, robe, trim, inner, gold)
    b.cur_pal = 0.0
    G.skirt(b, o, tor, robe, trim, inner, gold, lapel_end)
    if o.get("brocade"):
        # woven motifs over the robe: "cloud", "waves" (along the hem), "cranes" or "plum"
        b.bm.verts.ensure_lookup_table()
        robe_verts = [b.bm.verts[i] for i in range(robe_start, len(b.bm.verts))]
        motif = o["brocade"]
        bcol = o.get("brocade_col", lighten(robe, 0.35))
        G.brocade(b, robe_verts, motif, bcol, base_y=0.17, strength=0.65,
                  where=(lambda p: p.y < 0.75) if motif == "waves" else None)
    b.cur_pal = 0.5
    G.sash(b, o, tor, sash_col, gold)
    b.cur_pal = 0.0

    # ---------------- arms
    for s in (1, -1):
        G.sleeve(b, o, s, sleeve_col, trim, inner, gold)
        G.hand(b, o, s, skin)

    # ---------------- neck and head
    f = s = None
    if o.get("beast_head") is not None:
        b.tube([V(0, 1.46, 0.0), V(0, 1.6, 0.01)], [0.06, 0.055], o.get("head_col", "6a4a3a"), cls=CLOTH, bones=[{"neck": 0.6, "chest": 0.4}, {"neck": 0.5, "head": 0.5}], seg=14)
        beast_head(b, o)
        top = facelib.HC.y + 0.16
    else:
        f = facelib.Face(o)
        facelib.neck(b, f, o, [{"chest": 0.6, "neck": 0.4}, "neck", {"neck": 0.5, "head": 0.5}, "head"])
        if race.hides_ears(o):
            race.head(b, o, "head", "eyes")
        else:
            facelib.head(b, o, "head", "eyes")
        s = hairlib.build(b, f, o.get("hair_style", "topknot"), hair_col, o)
        top = hairlib.top_y(s)
        if o.get("beard", False):
            facelib.beard(b, f, o)
        if o.get("marks"):
            G.scars(b, f, facelib.HC, o["marks"])
    if o.get("crown", False):
        G.crown(b, o, top)
    if o.get("hat"):
        G.hat(b, o, o["hat"], top)
    if o.get("talisman", False):
        G.talisman(b, facelib.HC)
    if o.get("horns") == "antler":
        race.antlers(b, o, top)
    elif o.get("horns", False):
        hcol = o.get("horn_col", "2a1a20")
        for side in (1, -1):
            pts = [V(0.06 * side, top - 0.04, 0.03), V(0.11 * side, top + 0.04, -0.0), V(0.16 * side, top + 0.12, -0.07), V(0.15 * side, top + 0.2, -0.16)]
            strand(b, pts, 0.032, 0.004, hcol, col_tip=lighten(hcol, 0.25), cls=STONE, bone="head", seg=10, per=4)
            for k in range(3):
                q = V(0.06 * side, top - 0.04, 0.03).lerp(pts[2], 0.2 + k * 0.2)
                b.tube([q + V(0, 0.004, 0), q - V(0, 0.004, 0)], [0.031 - k * 0.006] * 2, darken(hcol, 0.3), cls=STONE, bone="head", seg=10, cap0=False, cap1=False)
    # wings, crest, fox or fin ears, fox tails, scales, whiskers (art/lib/race.py)
    if race.wanted(o):
        race.build(b, o, f, s)

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
        b.cur_pal = 0.5
        G.cape(b, o, soften(o["cape"]))
        b.cur_pal = 0.0
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
    # a slightly larger head than life (about 6.6 heads tall) reads better at game distance, the
    # usual stylised proportion (references: anime proportion guides; Genshin model evolution)
    hk = o.get("head_scale", 1.0 if o.get("beast_head") is not None else 1.08)
    if hk != 1.0:
        pivot = V(0, 1.58, 0.0)
        b.scale_where(lambda w: w.get("head", 0.0) + w.get("eyes", 0.0) + w.get("mouth", 0.0) + w.get("hair_tail", 0.0) >= 0.5, pivot, hk)
        for nm in ("eyes", "mouth", "hair_tail"):
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


def soften(c, s_knee=0.36, v_max=0.84):
    """Ease a very saturated or very bright cloth colour back: plant dyes, not paint."""
    h, sat, v = kit_to_hsv(c)
    if sat > s_knee:
        sat = s_knee + (sat - s_knee) * 0.55
    return kit_hsv(h, sat, min(v, v_max)) if sat > 0.08 else rgb(c)


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
# Clips follow the usual key poses and principles (references: Richard Williams' contact method,
# Animation Mentor walk and idle tutorials, UW CSE 459 walk cycle notes, AnimSchool "Breathing life
# into idle animations"): a walk is built from contact, down, passing and up poses with the arms
# counter-swinging a few frames behind the legs (drag); idles breathe, shift the weight from leg to
# leg and let the eyes and head lead; actions have anticipation, a fast strike, follow-through and
# recovery; cloth, sleeves and hair overlap a beat behind the body.
#
# Sign conventions (Godot Euler angles in the parent's frame): for a bone hanging down, x < 0
# swings it forward (thigh, upper arm), x > 0 back; the shin's x > 0 bends the knee, the forearm's
# x < 0 bends the elbow; foot x < 0 lifts the toes; spine/chest/head x > 0 lean or nod forward;
# y turns towards the character's left; for the left arm z > 0 lifts it away from the body.


def _blink(t, at):
    for a in at:
        if a <= t < a + 0.13:
            k = (t - a) / 0.13
            return 0.1 + 0.9 * abs(1.0 - 2.0 * k)
    return 1.0


def _set(p, nm, x=0.0, y=0.0, z=0.0, loc=(0.0, 0.0, 0.0), scl=None):
    p[nm] = ((x, y, z), loc) if scl is None else ((x, y, z), loc, scl)


def _add(p, nm, x=0.0, y=0.0, z=0.0):
    val = p.get(nm, ((0, 0, 0), (0, 0, 0)))
    rot, loc = val[0], val[1]
    p[nm] = ((rot[0] + x, rot[1] + y, rot[2] + z), loc) + tuple(val[2:])


def _hands(p, curl_l=0.35, curl_r=0.35, thumb=0.15):
    """Finger curl (0 open hand .. 1.2 fist) for both hands."""
    _set(p, "fingers.L", 0.0, 0.0, -curl_l)
    _set(p, "fingers.R", 0.0, 0.0, curl_r)
    _set(p, "thumb.L", -thumb * 0.5, 0.0, -thumb)
    _set(p, "thumb.R", -thumb * 0.5, 0.0, thumb)


def _secondary(p, t, walking, sit, legs_x, lag, sleeve=(0.0, 0.0)):
    """Robe panels, cape, sleeves and hair follow the legs and the stride, a beat behind."""
    fwd = max(-legs_x[0], -legs_x[1]) if not sit else 1.2
    back = max(legs_x[0], legs_x[1])
    p["robe_f"] = ((-max(0.0, fwd) * 0.8 - (0.12 if walking else 0.0), 0, 0), (0, 0, 0))
    p["robe_b"] = ((max(0.0, back) * 0.6 + (0.28 if walking else 0.03), 0, 0), (0, 0, 0))
    p["robe_l"] = ((-abs(legs_x[0]) * 0.35 - (0.6 if sit else 0.0), 0, -0.05 if not sit else -0.5), (0, 0, 0))
    p["robe_r"] = ((-abs(legs_x[1]) * 0.35 - (0.6 if sit else 0.0), 0, 0.05 if not sit else 0.5), (0, 0, 0))
    calm = 0.025 * math.sin(t * 2 * math.pi / 4)
    p["cape"] = (((0.3 + 0.1 * lag if walking else 0.02 + calm), 0.03 * lag, 0), (0, 0, 0))
    p["cape2"] = (((0.14 * abs(lag) + 0.04 if walking else 0.02 * math.sin(t * 2 * math.pi / 2)), 0, 0.04 * lag), (0, 0, 0))
    p["cape3"] = (((0.12 * abs(lag) + 0.03 if walking else 0.015 * math.sin(t * 2 * math.pi / 2 + 1.0)), 0, 0.05 * lag), (0, 0, 0))
    p["hair_tail"] = ((0.12 + (0.3 if walking else 0.05) * abs(lag), 0, lag * (0.22 if walking else 0.06)), (0, 0, 0))
    p["hair_tail2"] = ((0.06 + (0.16 if walking else 0.03) * abs(lag), 0, lag * (0.16 if walking else 0.05)), (0, 0, 0))
    p["sleeve.L"] = ((sleeve[0], 0, 0), (0, 0, 0))
    p["sleeve.R"] = ((sleeve[1], 0, 0), (0, 0, 0))


IDLE_T = 4.0


def clip_idle(t):
    """Standing at ease: weight resting on one leg (contrapposto) and slowly shifting to the other,
    breathing in the chest, relaxed arms and hands, the head looking about and blinking."""
    w = 2 * math.pi / IDLE_T
    br = math.sin(t * w * 2)
    shift = math.sin(t * w)               # weight from leg to leg over the loop
    turn = math.sin(t * w + 0.4)
    p = {}
    p["root"] = ((0, 0, 0), (0.012 * shift, 0, 0))
    p["hips"] = ((0.02, 0.05 * turn, -0.04 * shift), (0, br * 0.005 - 0.007 * abs(shift), 0))
    p["spine"] = ((br * 0.014, -0.025 * turn, 0.024 * shift), (0, 0, 0))
    p["chest"] = ((-br * 0.022, -0.02 * turn, 0.018 * shift), (0, 0.003 * br, 0))
    p["neck"] = ((0.035, 0, 0), (0, 0, 0))
    # the eyes lead and the head follows: a slow look to one side and back
    p["head"] = ((-0.02 + 0.03 * math.sin(t * w * 2 + 1.0), 0.17 * math.sin(t * w + 0.6), -0.035 * shift), (0, 0, 0))
    p["upper_arm.L"] = ((0.03 + br * 0.025, 0, 0.035 - br * 0.012), (0, 0, 0))
    p["upper_arm.R"] = ((0.03 - br * 0.025, 0, -0.035 + br * 0.012), (0, 0, 0))
    p["forearm.L"] = ((-0.2 - 0.03 * br, 0.12, 0), (0, 0, 0))
    p["forearm.R"] = ((-0.24 + 0.03 * br, -0.12, 0), (0, 0, 0))
    p["hand.L"] = ((0.05, 0.2, 0), (0, 0, 0))
    p["hand.R"] = ((0.05, -0.2, 0), (0, 0, 0))
    _hands(p, 0.38 + 0.04 * br, 0.4 - 0.04 * br)
    # the leg carrying less weight bends a little at the knee; feet stay flat on the ground
    for sd, k in (("L", max(0.0, -shift)), ("R", max(0.0, shift))):
        th = -0.05 * k
        sh = 0.03 + 0.11 * k
        p["thigh." + sd] = ((th, 0, 0.035 * shift), (0, 0, 0))
        p["shin." + sd] = ((sh, 0, 0), (0, 0, 0))
        p["foot." + sd] = ((-(th + sh) * 0.9, 0, -0.03 * shift), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (1.3, 3.4)), 1))
    _secondary(p, t, False, False, (0.0, 0.0), math.sin(t * w * 2), (0.05 * br, -0.05 * br))
    return p


WALK_T = 2.2           # two full cycles (four steps) of 0.55 s: an unhurried walk
WALK_CYCLE = 1.1


def clip_walk(t):
    """Contact, down, passing and up: heel strike with the toes lifted, the knee taking the weight,
    the hips at their lowest just after contact and highest as the free leg passes, toe-off with
    the toes bending; hips turn towards the forward leg and drop on the free side while the
    shoulders counter-rotate; the arms swing against the legs, a few frames late, and the
    sleeves, robe and hair follow later still."""
    ph = t * 2 * math.pi / WALK_CYCLE
    s = math.sin(ph)
    c = math.cos(ph)
    p = {}
    legs = []
    for sd, phase in (("L", ph), ("R", ph + math.pi)):
        sl = math.sin(phase)
        cl = math.cos(phase)
        th = -0.5 * sl + 0.04                      # sl > 0: this leg forward
        swing = max(0.0, cl)                         # moving forward through the air
        absorb = math.exp(-((phase % (2 * math.pi)) - (math.pi * 0.5 + 0.35)) ** 2 / 0.08)
        sh = 0.07 + 0.95 * swing ** 1.4 + 0.16 * absorb
        heel = 0.24 * max(0.0, sl) ** 2 * (1.0 - swing * 0.5)
        push = max(0.0, -sl) * max(0.0, cl) * 1.6
        ft = -heel + 0.34 * push - (th + sh) * 0.15
        p["thigh." + sd] = ((th, 0, 0.02 if sd == "L" else -0.02), (0, 0, 0))
        p["shin." + sd] = ((sh, 0, 0), (0, 0, 0))
        p["foot." + sd] = ((ft, 0, 0), (0, 0, 0))
        p["toe." + sd] = ((-0.55 * push, 0, 0), (0, 0, 0))
        legs.append(th)
    bob = math.cos(2 * (ph - 0.3))                   # +1 passing/up, -1 down
    p["root"] = ((0, 0, 0), (0, 0, 0))
    p["hips"] = ((0.05, -0.12 * s, -0.04 * c), (0, 0.022 * bob - 0.012, 0))
    p["spine"] = ((0.035, 0.05 * s, 0.02 * c), (0, 0, 0))
    p["chest"] = ((0.02 - 0.012 * bob, 0.13 * s, 0.01 * c), (0, 0, 0))
    p["neck"] = ((0.02, 0.0, 0), (0, 0, 0))
    p["head"] = ((-0.05 + 0.015 * bob, -0.06 * s, -0.012 * c), (0, 0, 0))
    # arms against the legs, with drag
    sd_ = math.sin(ph - 0.3)
    p["upper_arm.L"] = ((0.36 * sd_ + 0.04, 0, 0.06), (0, 0, 0))
    p["upper_arm.R"] = ((-0.36 * sd_ + 0.04, 0, -0.06), (0, 0, 0))
    p["forearm.L"] = ((-0.28 - 0.32 * max(0.0, -sd_), 0.1, 0), (0, 0, 0))
    p["forearm.R"] = ((-0.28 - 0.32 * max(0.0, sd_), -0.1, 0), (0, 0, 0))
    p["hand.L"] = ((0.08 + 0.1 * math.sin(ph - 0.9), 0.15, 0), (0, 0, 0))
    p["hand.R"] = ((0.08 - 0.1 * math.sin(ph - 0.9), -0.15, 0), (0, 0, 0))
    _hands(p, 0.42, 0.42)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (0.9,)), 1))
    lag = math.sin(ph - 0.8)
    sw = math.sin(ph - 1.2)
    _secondary(p, t, True, False, legs, lag, (0.12 + 0.22 * sw, 0.12 - 0.22 * sw))
    return p


RUN_T = 1.12            # two cycles of 0.56 s: the light-body run of a cultivator


def clip_run(t):
    """A qinggong dash: the body leans into the run, long strides with a flight phase between the
    steps, the heel folding up behind on the recovery, arms pumping with bent elbows against the
    legs, and the cape, sleeves, robe and hair streaming back."""
    ph = t * 2 * math.pi / (RUN_T / 2)
    s = math.sin(ph)
    c = math.cos(ph)
    p = {}
    legs = []
    for sd, phase in (("L", ph), ("R", ph + math.pi)):
        sl = math.sin(phase)
        cl = math.cos(phase)
        th = -0.82 * sl - 0.22
        fold = max(0.0, math.cos(phase + 0.35)) ** 1.2
        sh = 0.22 + 1.45 * fold
        ft = 0.42 * max(0.0, -sl) - 0.22 * max(0.0, sl) * (1.0 - fold)
        p["thigh." + sd] = ((th, 0, 0.03 if sd == "L" else -0.03), (0, 0, 0))
        p["shin." + sd] = ((sh, 0, 0), (0, 0, 0))
        p["foot." + sd] = ((ft, 0, 0), (0, 0, 0))
        p["toe." + sd] = ((-0.4 * max(0.0, -sl) * max(0.0, cl), 0, 0), (0, 0, 0))
        legs.append(th)
    up = abs(s) ** 1.5                                # flight between the steps, low at mid-stance
    p["root"] = ((0, 0, 0), (0, 0, 0))
    p["hips"] = ((0.22, -0.15 * s, -0.03 * c), (0, -0.05 + 0.065 * up, 0.03))
    p["spine"] = ((0.08, 0.08 * s, 0.0), (0, 0, 0))
    p["chest"] = ((0.06 - 0.03 * up, 0.24 * s, 0.0), (0, 0, 0))
    p["neck"] = ((-0.06, -0.08 * s, 0), (0, 0, 0))
    p["head"] = ((-0.16 + 0.03 * up, -0.08 * s, 0), (0, 0, 0))
    sd_ = math.sin(ph - 0.25)
    p["upper_arm.L"] = ((0.72 * sd_ + 0.1, 0, 0.1), (0, 0, 0))
    p["upper_arm.R"] = ((-0.72 * sd_ + 0.1, 0, -0.1), (0, 0, 0))
    p["forearm.L"] = ((-1.25 - 0.3 * max(0.0, -sd_), 0.25, 0), (0, 0, 0))
    p["forearm.R"] = ((-1.25 - 0.3 * max(0.0, sd_), -0.25, 0), (0, 0, 0))
    p["hand.L"] = ((0.15, 0.2, 0), (0, 0, 0))
    p["hand.R"] = ((0.15, -0.2, 0), (0, 0, 0))
    _hands(p, 0.95, 0.95, 0.4)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1, 1))
    lag = math.sin(ph - 0.9)
    # everything loose streams back in the wind of the run
    p["robe_f"] = ((-0.38 - 0.22 * max(0.0, -min(legs)), 0, 0), (0, 0, 0))
    p["robe_b"] = ((0.55 + 0.1 * abs(lag), 0, 0), (0, 0, 0))
    p["robe_l"] = ((-abs(legs[0]) * 0.4 + 0.2, 0, -0.08), (0, 0, 0))
    p["robe_r"] = ((-abs(legs[1]) * 0.4 + 0.2, 0, 0.08), (0, 0, 0))
    p["cape"] = ((1.05 + 0.12 * math.sin(2 * ph - 0.8), 0.04 * lag, 0), (0, 0, 0))
    p["cape2"] = ((0.32 + 0.15 * math.sin(2 * ph - 1.6), 0, 0.06 * lag), (0, 0, 0))
    p["cape3"] = ((0.2 + 0.12 * math.sin(2 * ph - 2.4), 0, 0.08 * lag), (0, 0, 0))
    p["hair_tail"] = ((0.75 + 0.1 * math.sin(2 * ph - 0.8), 0, 0.1 * lag), (0, 0, 0))
    p["hair_tail2"] = ((0.35 + 0.14 * math.sin(2 * ph - 1.7), 0, 0.12 * lag), (0, 0, 0))
    p["sleeve.L"] = ((0.75 + 0.25 * math.sin(ph - 1.3), 0, 0), (0, 0, 0))
    p["sleeve.R"] = ((0.75 - 0.25 * math.sin(ph - 1.3), 0, 0), (0, 0, 0))
    return p


SIT_T = 4.0


def clip_sit(t):
    """Lotus meditation: crossed legs, hands resting in the lap in a mudra, slow deep breaths, eyes
    closed, the sleeves pooling on the knees."""
    w = 2 * math.pi / SIT_T
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
    _hands(p, 0.25, 0.25, 0.35)
    p["hips"] = ((0, 0, 0), (0, br * 0.006, 0))
    p["spine"] = ((-0.03, 0, 0), (0, 0, 0))
    p["chest"] = ((-br * 0.025, 0, 0), (0, br * 0.004, 0))
    p["head"] = ((0.14 + br * 0.02, 0, 0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.12, 1))
    _secondary(p, t, False, True, (-1.45, -1.45), br, (-0.5, -0.5))
    return p


TALK_T = 3.0


def clip_talk(t):
    """Talking: the weight on one leg, the right hand opening and turning with the phrases, the head
    nodding on the stresses and the mouth opening and closing on the syllables."""
    w = 2 * math.pi / TALK_T
    p = clip_idle(t * IDLE_T / TALK_T)
    gest = 0.5 + 0.5 * math.sin(t * w * 2 - 0.5)
    _add(p, "upper_arm.R", -0.32 - 0.22 * gest, 0.0, 0.12)
    p["forearm.R"] = ((-1.0 - 0.35 * gest, -0.25 + 0.3 * math.sin(t * w * 2), 0), (0, 0, 0))
    p["hand.R"] = ((-0.15 * gest, 0.35 * math.sin(t * w * 2 + 1.0), 0.15), (0, 0, 0))
    p["fingers.R"] = ((0, 0, 0.12 + 0.25 * (1.0 - gest)), (0, 0, 0))
    _add(p, "upper_arm.L", -0.06, 0.0, 0.0)
    _add(p, "head", 0.035 * math.sin(t * w * 4), 0.06 * math.sin(t * w), 0.0)
    _add(p, "chest", 0.0, -0.05 * gest, 0.0)
    syl = max(0.0, math.sin(t * w * 10.0)) * (0.55 + 0.45 * math.sin(t * w * 2.0))
    pause = smooth(0.0, 0.15, (t % TALK_T) / TALK_T) * (1.0 - smooth(0.82, 0.95, (t % TALK_T) / TALK_T))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 2.6 * syl * pause, 1))
    _add(p, "sleeve.R", 0.25 * gest, 0.0, 0.0)
    return p


BOW_T = 1.6


def clip_bow(t):
    """The cultivator's salute (baoquan li): the right fist pressed into the left palm before the
    chest, a bow from the hips, held, then back up."""
    k = t / BOW_T
    raise_ = smooth(0.0, 0.25, k) * (1.0 - smooth(0.82, 1.0, k))
    bow = smooth(0.22, 0.45, k) * (1.0 - smooth(0.62, 0.88, k))
    p = clip_idle(0.0)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.62 * raise_, 0.15 * s * raise_, -0.42 * s * raise_), (0, 0, 0))
        p["forearm." + sd] = ((-1.55 * raise_ - 0.2, -0.35 * s * raise_, 0), (0, 0, 0))
        p["hand." + sd] = ((0.2 * raise_, 0.0, 0.25 * s * raise_), (0, 0, 0))
    _hands(p, 0.05 + 0.3 * (1 - raise_), 0.4 + 0.8 * raise_)
    p["hips"] = ((0.12 * bow, 0, 0), (0, -0.01 * bow, -0.02 * bow))
    p["spine"] = ((0.16 * bow, 0, 0), (0, 0, 0))
    p["chest"] = ((0.14 * bow, 0, 0), (0, 0, 0))
    p["head"] = ((0.16 * bow, 0, 0), (0, 0, 0))
    p["sleeve.L"] = ((0.3 * raise_, 0, 0), (0, 0, 0))
    p["sleeve.R"] = ((0.3 * raise_, 0, 0), (0, 0, 0))
    return p


ACT_T = 0.55


def _base_for_act():
    return clip_idle(0.0)


def clip_attack(t):
    """Anticipation: the weight goes back and the sword is drawn up behind the head; the strike: a
    step in on the left foot with a fast diagonal cut and a twist of the hips; follow-through with
    the blade past the body; recovery."""
    k = t / ACT_T
    e = env(k)
    wind = smooth(0.0, 0.28, k) * (1.0 - smooth(0.28, 0.42, k))
    cut = smooth(0.3, 0.58, k)
    rec = smooth(0.7, 1.0, k)
    step = smooth(0.25, 0.45, k) * (1.0 - rec)
    p = _base_for_act()
    arm_x = -2.5 * wind + (-2.5 + 3.2 * cut) * (1 - wind) * (1 - rec) * smooth(0.22, 0.3, k)
    p["upper_arm.R"] = ((arm_x, 0, -(0.5 - 0.95 * cut) * (1 - rec)), (0, 0, 0))
    p["forearm.R"] = ((-0.95 * wind - 0.2 * cut * (1 - rec), 0, 0), (0, 0, 0))
    p["hand.R"] = ((0.35 * cut * (1 - rec), 0, 0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.55 * e, 0, 0.6 * e), (0, 0, 0))
    p["forearm.L"] = ((-0.7 * e, 0, 0), (0, 0, 0))
    _hands(p, 0.1 + 0.2 * (1 - e), 1.15)
    turn = (0.5 * wind - 0.65 * cut) * (1 - rec)
    p["hips"] = ((0.12 * e, turn * 0.5, 0), (0, -0.04 * step, 0.12 * step - 0.04 * wind))
    p["spine"] = ((0.06 * e - 0.05 * wind, turn * 0.3, 0), (0, 0, 0))
    p["chest"] = ((0.14 * e - 0.08 * wind, turn * 0.5, 0), (0, 0, 0))
    p["head"] = ((0.05 * e, -turn * 0.45, 0), (0, 0, 0))
    p["thigh.L"] = ((-0.65 * step, 0, 0.05), (0, 0, 0))
    p["shin.L"] = ((0.55 * step, 0, 0), (0, 0, 0))
    p["foot.L"] = ((0.1 * step, 0, 0), (0, 0, 0))
    p["thigh.R"] = ((0.42 * step, 0, -0.05), (0, 0, 0))
    p["shin.R"] = ((0.3 * step, 0, 0), (0, 0, 0))
    p["foot.R"] = ((0.35 * step, 0, 0), (0, 0, 0))
    p["toe.R"] = ((-0.4 * step, 0, 0), (0, 0, 0))
    # the sleeve pocket falls back towards the ground while the arm is up, instead of pointing at the sky
    up = smooth(-0.6, -2.2, arm_x)
    _secondary(p, t, False, False, (-0.65 * step, 0.42 * step), e, (0.3 * e, 0.5 * cut * (1 - rec) + 1.25 * up))
    return p


def clip_cast(t):
    """A hand seal: the right hand comes up before the face with two fingers raised (the sword
    finger), the left hand flat beneath it, then both thrust forward as the qi leaves them; the
    sleeves, cape and hair lift on the surge."""
    k = t / ACT_T
    e = env(k)
    seal = smooth(0.0, 0.35, k) * (1.0 - smooth(0.5, 0.75, k))
    thrust = smooth(0.4, 0.62, k) * (1.0 - smooth(0.8, 1.0, k))
    p = _base_for_act()
    p["upper_arm.R"] = ((-0.75 * seal - 1.45 * thrust, 0.2 * seal, -(0.35 * seal + 0.2 * thrust)), (0, 0, 0))
    p["forearm.R"] = ((-1.75 * seal - 0.25 * thrust, -0.4 * seal, 0), (0, 0, 0))
    p["hand.R"] = ((-0.4 * thrust, 0, 0.2 * seal), (0, 0, 0))
    p["upper_arm.L"] = ((-0.55 * seal - 1.35 * thrust, -0.1 * seal, 0.35 * seal + 0.25 * thrust), (0, 0, 0))
    p["forearm.L"] = ((-1.3 * seal - 0.35 * thrust, 0.3 * seal, 0), (0, 0, 0))
    p["hand.L"] = ((-0.3 * thrust, 0, -0.2 * seal), (0, 0, 0))
    _hands(p, 0.05, 0.35 + 0.4 * seal, 0.5 * seal)
    p["head"] = ((-0.08 * seal - 0.18 * thrust, 0, 0), (0, 0, 0))
    p["chest"] = ((-0.08 * e, 0, 0), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, 0.04 * e, 0.03 * thrust))
    p["cape"] = ((0.45 * e, 0, 0), (0, 0, 0))
    p["cape2"] = ((0.25 * e, 0, 0), (0, 0, 0))
    p["cape3"] = ((0.2 * e, 0, 0), (0, 0, 0))
    p["hair_tail"] = ((0.4 * e, 0, 0), (0, 0, 0))
    p["hair_tail2"] = ((0.25 * e, 0, 0), (0, 0, 0))
    p["robe_b"] = ((0.22 * e, 0, 0), (0, 0, 0))
    p["sleeve.L"] = ((0.55 * thrust + 0.2 * seal, 0, 0), (0, 0, 0))
    p["sleeve.R"] = ((0.55 * thrust + 0.2 * seal, 0, 0), (0, 0, 0))
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
        p["upper_arm." + sd] = ((0.45 * e, 0, 0.25 * s * e), (0, 0, 0))
        p["forearm." + sd] = ((-0.5 * e, 0, 0), (0, 0, 0))
    _hands(p, 0.05, 0.9)
    p["hips"] = ((-0.05 * e, 0, 0), (0, -0.02 * e, -0.09 * e))
    p["thigh.R"] = ((0.3 * e, 0, 0), (0, 0, 0))
    p["shin.R"] = ((0.3 * e, 0, 0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.85 * e, 1))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 2.0 * snap, 1))
    _secondary(p, t, False, False, (0.0, 0.3 * e), -e, (-0.4 * snap, -0.4 * snap))
    return p


def clip_victory(t):
    """The sword swept up to the sky, the free hand on the hip, chest out, a settling bounce."""
    k = min(1.0, t / 0.35)
    e = math.sin(k * math.pi / 2)
    settle = 0.04 * math.sin(clamp((t - 0.35) / 0.6) * math.pi) if t > 0.35 else 0.0
    p = _base_for_act()
    p["upper_arm.R"] = ((-2.8 * e, 0, -0.18), (0, 0, 0))
    p["forearm.R"] = ((-0.2, 0, 0), (0, 0, 0))
    p["hand.R"] = ((-0.2 * e, 0, 0), (0, 0, 0))
    p["upper_arm.L"] = ((0.12, 0, 0.45 * e), (0, 0, 0))
    p["forearm.L"] = ((-1.3 * e, 0.4 * e, 0), (0, 0, 0))
    _hands(p, 0.7, 1.15)
    p["head"] = ((-0.16 * e, 0, 0), (0, 0, 0))
    p["chest"] = ((-0.08 * e - settle, 0, 0), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, settle * 0.3, 0))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 1.2 * e, 1))
    p["sleeve.R"] = ((1.2 * e, 0, 0), (0, 0, 0))
    p["sleeve.L"] = ((0.2 * e, 0, 0), (0, 0, 0))
    return p


DIE_T = 1.4


def clip_die(t):
    """Collapse: a stagger back, the knees buckle, the body folds and falls onto its side, and lies
    still (the clip holds its last frame)."""
    k = t / DIE_T
    stag = math.sin(math.pi * clamp(k / 0.3)) if k < 0.3 else 0.0
    buckle = smooth(0.12, 0.5, k)
    fall = smooth(0.32, 0.86, k)
    land = smooth(0.8, 1.0, k)
    p = _base_for_act()
    p["root"] = ((0, 0, 1.42 * fall), (0, 0.11 * fall, -0.06 * stag))
    p["hips"] = ((0.35 * buckle - 0.15 * stag, 0, 0), (0, -0.22 * buckle * (1 - fall), 0))
    p["spine"] = ((0.18 * buckle - 0.1 * stag, 0, 0.1 * fall), (0, 0, 0))
    p["chest"] = ((0.15 * buckle - 0.15 * stag, 0.1 * fall, 0), (0, 0, 0))
    p["head"] = ((0.25 * buckle - 0.2 * stag, 0.3 * fall, 0.25 * land), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["thigh." + sd] = ((-0.75 * buckle, 0, 0.1 * s * buckle), (0, 0, 0))
        p["shin." + sd] = ((1.3 * buckle, 0, 0), (0, 0, 0))
        p["foot." + sd] = ((0.4 * buckle, 0, 0), (0, 0, 0))
        p["upper_arm." + sd] = ((0.4 * stag - 0.5 * fall, 0, (0.35 * stag + 0.6 * fall) * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.3 - 0.4 * fall, 0, 0), (0, 0, 0))
    _hands(p, 0.5, 0.5)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.9 * fall, 1))
    _secondary(p, t, False, False, (-0.75 * buckle, -0.75 * buckle), -stag, (0.3 * fall, 0.3 * fall))
    return p


# ---------------------------------------------------------------- cutscene gestures
# Played once, on top of a conversation, when a line of dialogue calls for them (Data.emote_for in
# the game picks them from the line, or a line names one).  Each starts and ends in the idle pose so
# it blends in and out of the talk loop; `_hold` is an in-hold-out envelope.


def _hold(k, a, b, c, d):
    return smooth(a, b, k) * (1.0 - smooth(c, d, k))


def _arm_in(p, sd, e, lift=0.0, bend=0.0):
    """An arm brought in before the body on the salute's arm template (the bow brings both fists
    together before the chest with it): `lift` raises the elbow higher (towards the face), `bend`
    folds the forearm further; `e` blends it in from the idle pose."""
    s = 1 if sd == "L" else -1
    p["upper_arm." + sd] = (((-0.62 - lift) * e, 0.15 * s * e, -0.42 * s * e), (0, 0, 0))
    p["forearm." + sd] = (((-1.55 - bend) * e - 0.2 * (1 - e), -0.35 * s * e, 0), (0, 0, 0))
    p["hand." + sd] = ((0.2 * e, 0.0, 0.25 * s * e), (0, 0, 0))


NOD_T = 1.0


def clip_nod(t):
    """Agreement: two small nods of the head, the chest dipping with the first, the eyes closing a
    moment on the second."""
    k = t / NOD_T
    p = clip_idle(0.0)
    n = math.sin(k * math.pi * 4.0) * _hold(k, 0.0, 0.12, 0.8, 1.0)
    _add(p, "head", 0.22 * max(0.0, n), 0.0, 0.0)
    _add(p, "neck", 0.08 * max(0.0, n), 0.0, 0.0)
    _add(p, "chest", 0.05 * _hold(k, 0.0, 0.2, 0.4, 0.6), 0.0, 0.0)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.8 * _hold(k, 0.45, 0.55, 0.62, 0.72), 1))
    return p


SHAKE_T = 1.2


def clip_shake(t):
    """Refusal: the head turns side to side three times, the right hand comes up and waves low,
    palm out, the weight settling back."""
    k = t / SHAKE_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.15, 0.75, 1.0)
    _add(p, "head", 0.04 * e, 0.32 * math.sin(k * math.pi * 6.0) * e, 0.0)
    _arm_in(p, "R", e, -0.1, -0.3)
    p["hand.R"] = ((-0.3 * e, 0.45 * math.sin(k * math.pi * 6.0) * e, -0.1 * e), (0, 0, 0))
    _hands(p, 0.38, 0.4 - 0.35 * e)
    _add(p, "chest", -0.05 * e, 0.0, 0.0)
    _add(p, "sleeve.R", 0.25 * e, 0.0, 0.0)
    return p


POINT_T = 1.4


def clip_point(t):
    """Showing the way: the right arm swings up and out to point into the distance with the index
    finger, the head and shoulders turning to follow it, held, then lowered."""
    k = t / POINT_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.25, 0.72, 1.0)
    p["upper_arm.R"] = ((-1.35 * e, 0.0, -0.75 * e), (0, 0, 0))
    p["forearm.R"] = ((-0.15 * e - 0.2 * (1 - e), 0.9 * e, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.15 * e, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.38, 0.38 - 0.3 * e, 0.15)
    _add(p, "chest", 0.0, -0.28 * e, 0.0)
    _add(p, "head", -0.06 * e, -0.3 * e, 0.0)
    _add(p, "hips", 0.0, -0.08 * e, 0.0)
    _add(p, "sleeve.R", 1.0 * e, 0.0, 0.0)
    return p


WAVE_T = 1.6


def clip_wave(t):
    """A greeting: the right hand raised beside the head and waved from the wrist and forearm, a
    smile, the other hand at ease."""
    k = t / WAVE_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.18, 0.78, 1.0)
    w = math.sin(k * math.pi * 7.0) * e
    p["upper_arm.R"] = ((-1.9 * e, 0.0, -0.55 * e), (0, 0, 0))
    p["forearm.R"] = ((-0.6 * e, 0.35 * w, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.0, 0.0, 0.35 * w), (0, 0, 0))
    _hands(p, 0.38, 0.38 - 0.3 * e)
    _add(p, "head", -0.05 * e, 0.0, 0.08 * e)
    _add(p, "chest", -0.04 * e, 0.06 * e, 0.0)
    _add(p, "sleeve.R", 1.4 * e, 0.0, 0.0)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.8 * e, 1))
    return p


LAUGH_T = 1.6


def clip_laugh(t):
    """Laughter: the head thrown back, the shoulders and chest shaking in quick pulses, one hand on
    the belly, the mouth open, and a lean forward at the end as it subsides."""
    k = t / LAUGH_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.15, 0.7, 1.0)
    pulse = abs(math.sin(k * math.pi * 10.0)) * e
    _add(p, "head", -0.22 * e + 0.05 * pulse, 0.0, 0.05 * math.sin(k * math.pi * 3.0) * e)
    _add(p, "chest", -0.1 * e + 0.06 * pulse, 0.0, 0.0)
    _add(p, "spine", 0.03 * pulse, 0.0, 0.0)
    _arm_in(p, "L", e, -0.45, 0.1)
    _add(p, "upper_arm.R", 0.0, 0.0, -0.2 * pulse)
    _add(p, "hips", 0.0, 0.0, 0.0)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 2.2 * e * (0.5 + 0.5 * pulse), 1))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.6 * e, 1))
    return p


GRIEVE_T = 2.4


def clip_grieve(t):
    """Grief: the head drops, both hands come up to cover the face, the shoulders hunch and shake
    with sobs, and slowly the hands come down again."""
    k = t / GRIEVE_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.2, 0.78, 1.0)
    sob = math.sin(k * math.pi * 9.0) * e
    for sd in ("L", "R"):
        _arm_in(p, sd, e, 0.3, 0.35)
        _add(p, "sleeve." + sd, 0.5 * e, 0.0, 0.0)
    _hands(p, 0.38 - 0.3 * e, 0.38 - 0.3 * e)
    _add(p, "head", 0.42 * e + 0.03 * sob, 0.0, 0.0)
    _add(p, "neck", 0.15 * e, 0.0, 0.0)
    _add(p, "chest", 0.16 * e + 0.03 * sob, 0.0, 0.0)
    _add(p, "spine", 0.06 * e, 0.0, 0.0)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.9 * e, 1))
    return p


THINK_T = 2.0


def clip_think(t):
    """Thought: the right hand comes to the chin, the left arm folds across under its elbow, the head
    tilts and the eyes look up and aside, the weight shifts; then a small nod as the thought lands."""
    k = t / THINK_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.2, 0.8, 1.0)
    _arm_in(p, "R", e, 0.15, 0.55)
    _arm_in(p, "L", e, -0.5, 0.0)
    _hands(p, 0.38 + 0.4 * e, 0.38 + 0.5 * e)
    land = _hold(k, 0.66, 0.72, 0.76, 0.84)
    _add(p, "head", -0.1 * e + 0.15 * land, 0.18 * e, 0.14 * e)
    _add(p, "hips", 0.0, 0.05 * e, -0.04 * e)
    _add(p, "sleeve.R", 0.3 * e, 0.0, 0.0)
    return p


KNEEL_T = 2.4


def clip_kneel(t):
    """Kneeling: a step back onto the right knee, the left foot planted before it, the head and back
    bowed and the fist pressed to the palm, held, and up again."""
    k = t / KNEEL_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.3, 0.72, 1.0)
    bow = _hold(k, 0.25, 0.4, 0.6, 0.75)
    p["hips"] = ((0.1 * e + 0.1 * bow, 0.0, 0.0), (0.0, -0.42 * e, -0.06 * e))
    p["thigh.L"] = ((-1.45 * e, 0.0, 0.08 * e), (0, 0, 0))
    p["shin.L"] = ((1.5 * e, 0.0, 0.0), (0, 0, 0))
    p["foot.L"] = ((-0.05 * e, 0.0, 0.0), (0, 0, 0))
    p["thigh.R"] = ((0.05 * e, 0.0, -0.06 * e), (0, 0, 0))
    p["shin.R"] = ((1.55 * e, 0.0, 0.0), (0, 0, 0))
    p["foot.R"] = ((0.6 * e, 0.0, 0.0), (0, 0, 0))
    p["toe.R"] = ((-0.9 * e, 0.0, 0.0), (0, 0, 0))
    _add(p, "spine", 0.1 * bow, 0.0, 0.0)
    _add(p, "chest", 0.12 * bow, 0.0, 0.0)
    _add(p, "head", 0.25 * bow, 0.0, 0.0)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.62 * bow, 0.15 * s * bow, -0.42 * s * bow), (0, 0, 0))
        p["forearm." + sd] = ((-1.55 * bow - 0.2, -0.35 * s * bow, 0), (0, 0, 0))
    _hands(p, 0.05 + 0.3 * (1 - bow), 0.4 + 0.8 * bow)
    _secondary(p, t, False, False, (-1.45 * e, 0.05 * e), 0.0, (0.3 * bow, 0.3 * bow))
    return p


OFFER_T = 1.6


def clip_offer(t):
    """Giving: both hands extended forward, palms up, as if offering something with both hands (the
    courteous way), a small bow over them, held, and drawn back."""
    k = t / OFFER_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.25, 0.75, 1.0)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.95 * e, 0.0, -0.18 * s * e), (0, 0, 0))
        p["forearm." + sd] = ((-0.55 * e, 0.9 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((-0.1 * e, 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.6 * e, 0.0, 0.0)
    _hands(p, 0.38 - 0.25 * e, 0.38 - 0.25 * e)
    _add(p, "chest", 0.14 * e, 0.0, 0.0)
    _add(p, "head", 0.12 * e, 0.0, 0.0)
    return p


SHOCK_T = 1.0


def clip_shock(t):
    """Surprise: a start backwards, both hands flung up before the chest, the eyes and mouth wide,
    then settling."""
    k = t / SHOCK_T
    p = clip_idle(0.0)
    snap = _hold(k, 0.0, 0.1, 0.45, 1.0)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.6 * snap, 0.0, 0.3 * s * snap), (0, 0, 0))
        p["forearm." + sd] = ((-1.3 * snap, 0.0, 0.0), (0, 0, 0))
        p["hand." + sd] = ((-0.4 * snap, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.38 - 0.35 * snap, 0.38 - 0.35 * snap, 0.3)
    _add(p, "chest", -0.16 * snap, 0.0, 0.0)
    _add(p, "head", -0.14 * snap, 0.0, 0.0)
    p["hips"] = ((-0.04 * snap, 0.0, 0.0), (0.0, 0.02 * snap, 0.08 * snap))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.25 * snap, 1))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 1.6 * snap, 1))
    return p


## the gestures a conversation can call for (Data.EMOTES in the game lists the same names)
GESTURES = ("nod", "shake", "point", "wave", "laugh", "grieve", "think", "kneel", "offer", "shock")

CLIPS = {
    "idle": (IDLE_T, clip_idle),
    "walk": (WALK_T, clip_walk),
    "run": (RUN_T, clip_run),
    "sit": (SIT_T, clip_sit),
    "talk": (TALK_T, clip_talk),
    "bow": (BOW_T, clip_bow),
    "attack": (ACT_T, clip_attack),
    "cast": (ACT_T, clip_cast),
    "hurt": (ACT_T, clip_hurt),
    "victory": (1.2, clip_victory),
    "die": (DIE_T, clip_die),
    # cutscene gestures (Part XII)
    "nod": (NOD_T, clip_nod),
    "shake": (SHAKE_T, clip_shake),
    "point": (POINT_T, clip_point),
    "wave": (WAVE_T, clip_wave),
    "laugh": (LAUGH_T, clip_laugh),
    "grieve": (GRIEVE_T, clip_grieve),
    "think": (THINK_T, clip_think),
    "kneel": (KNEEL_T, clip_kneel),
    "offer": (OFFER_T, clip_offer),
    "shock": (SHOCK_T, clip_shock),
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
    # a scholar's courtesy: hands joined and hidden inside the sleeves before the chest
    "sleeves": {"upper_arm.L": (-0.5, 0.0, -0.3), "forearm.L": (-1.2, 0.0, 0.0), "upper_arm.R": (-0.5, 0.0, 0.3), "forearm.R": (-1.2, 0.0, 0.0)},
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
        clips = {nm: (secs, _with_pose(fn, pose) if nm in ("idle", "walk", "sit", "talk") else fn) for nm, (secs, fn) in clips.items()}
    print("[art] %s: %d triangles" % (rel, b.tri_count()))
    # robes are not coats: person-shaped monsters keep their dominant/secondary/accent cut
    return finish_rigged(b, rig, rel, clips, coat=False, samples=16, dist=0.22, strength=0.5, floor_y=0.0, floor_k=0.2)

