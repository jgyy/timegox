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
# how much lower the head sits on a shorter neck (see build): the chin about a third of a head above
# the collar, not half of one
NECK_DROP = 0.028


def make_rig(o=None):
    """The skeleton (see the module docstring).  Beyond the core chain it carries the bones a game
    rig adds for secondary motion and expression (references: mocaponline skeleton hierarchy
    guide, gamedev.net "Demystifying character rigging"): a pocket bone per hanfu sleeve, finger and
    thumb bones per hand, toe bones for the roll of the foot, a mouth bone for speech, a two-bone
    hair tail and a three-bone cape; and for a swordsman a sword bone in the right hand, so a clip
    that needs both hands free (the interactions) can put the blade away."""
    r = Rig("rig")
    r.bone("root", (0, 0, 0), (0, 0.25, 0))
    r.bone("hips", (0, HIP_Y, 0), (0, 1.05, 0), "root")
    r.bone("spine", (0, 1.05, 0), (0, 1.28, 0), "hips")
    r.bone("chest", (0, 1.28, 0), (0, 1.47, 0), "spine")
    r.bone("neck", (0, 1.47, 0.0), (0, 1.56, 0.01), "chest")
    r.bone("head", (0, 1.56, 0.01), (0, 1.88, 0.0), "neck")
    ey = facelib.HC.y + facelib.eye_y_of(o)
    # the bones of expression (face.py: brows, corners of the mouth, lids and jaw), posed at runtime
    facelib.expression_bones(r, o)
    r.bone("eyes", (0, ey, 0.08), (0, ey + 0.05, 0.08), "lids")
    mouth_y = facelib.HC.y + facelib.MOUTH_Y
    r.bone("mouth", (0, mouth_y + 0.001, 0.09), (0, mouth_y + 0.03, 0.09), "jaw")
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
    if o is not None and o.get("sword", False):
        grip = WRI * V(-1, 1, 1) + V(-0.004, -0.075, 0.02)
        r.bone("sword", grip, grip + V(0, -0.06, 0.05), "hand.R")
    return r


def build(o):
    rig = make_rig(o)
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
    # (the hero's blade is one of the Eight Arms, hung on the sword bone by the game: "arms")
    if o.get("sword", False) and not o.get("arms", False):
        G.sword(b, "sword", hand_r, rgb(o.get("blade", "dce8ff")), rgb(o.get("hilt", "3a3048")))
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
    # (the Spring Thunder release: a woman's head a little bigger again, about 6.5 heads tall like the
    # gacha games' adult women, a man's about 7)
    hk = o.get("head_scale", 1.0 if o.get("beast_head") is not None else (1.13 if o.get("fem") else 1.08))
    if hk != 1.0:
        pivot = V(0, 1.58, 0.0)
        b.scale_where(lambda w: sum(w.get(nm, 0.0) for nm in ("head", "eyes", "mouth", "hair_tail") + facelib.FACE_BONES) >= 0.5, pivot, hk)
        for nm in ("eyes", "mouth", "hair_tail") + facelib.FACE_BONES:
            h0, t0, par = rig.bones[nm]
            rig.bones[nm] = (pivot + (V(h0) - pivot) * hk, pivot + (V(t0) - pivot) * hk, par)
        h0, t0, par = rig.bones["head"]
        rig.bones["head"] = (h0, pivot + (V(t0) - pivot) * hk, par)
    # a shorter neck (the Spring Thunder release): the head, and everything that hangs from it, sits
    # NECK_DROP lower on a neck bone that much shorter.  The bigger anime head had left a long column
    # of neck between the chin and the collar; the modelling guides shorten the neck itself and bring
    # the head down to it rather than scale the head
    drop = o.get("neck_drop", NECK_DROP if o.get("beast_head") is None else 0.0)
    if drop != 0.0:
        heads = ("head", "eyes", "mouth", "hair_tail", "hair_tail2") + facelib.FACE_BONES
        b.shift_where(lambda w: min(1.0, sum(w.get(nm, 0.0) for nm in heads)), V(0, -drop, 0))
        for nm in heads:
            h0, t0, par = rig.bones[nm]
            rig.bones[nm] = (V(h0) + V(0, -drop, 0), V(t0) + V(0, -drop, 0), par)
        h0, t0, par = rig.bones["neck"]
        rig.bones["neck"] = (h0, V(t0) + V(0, -drop, 0), par)
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
GESTURES = ("nod", "shake", "point", "wave", "laugh", "grieve", "think", "kneel", "offer", "shock",
            # the Hollow Hills release (Part XX)
            "shrug", "cheer", "beckon", "refuse", "shiver")

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


# ---------------------------------------------------------------- interactions
# What Lin Feng and Yue Ling do with the things of the world (scripts/props.gd in the game): sit on
# a bench, drink from a well, strike a bell, read, play the qin, fish, pray, gather herbs, warm their
# hands, stir a cauldron, work an anvil, sweep, weave, lift the training stones, toss a coin, lay a
# hand on a stone, doze.  Loops hold a pose and breathe; one-shots start and end in the idle pose.
# Clips that sit or crouch lower the hips themselves: the game stands the model where the feet go.

def _stow(p):
    """Hands busy: a swordsman's blade is put away (its bone shrinks to nothing; the empty scabbard
    stays on the hip) for as long as the interaction lasts."""
    p["sword"] = ((0, 0, 0), (0, 0, 0), (0.001, 0.001, 0.001))
    return p


def _seated(p, t, w, drop=0.44, spread=0.1):
    """Sitting on a seat at knee height: the hips `drop` lower and a little back, thighs level,
    shins hanging and feet flat, the back upright and breathing.  Returns the breath."""
    br = math.sin(t * w * 2)
    p["root"] = ((0, 0, 0), (0, 0, 0))
    p["hips"] = ((0.0, 0.0, 0.0), (0.0, -drop + br * 0.004, -0.08))
    for sd, s in (("L", 1), ("R", -1)):
        p["thigh." + sd] = ((-1.5, 0.0, spread * s), (0, 0, 0))
        p["shin." + sd] = ((1.45, 0.0, 0.0), (0, 0, 0))
        p["foot." + sd] = ((0.05, 0.0, -0.04 * s), (0, 0, 0))
    p["spine"] = ((-0.03 + br * 0.01, 0.0, 0.0), (0, 0, 0))
    p["chest"] = ((-br * 0.02, 0.0, 0.0), (0, 0.003 * br, 0))
    p["neck"] = ((0.03, 0.0, 0.0), (0, 0, 0))
    return br


def _cross_legged(p, t, w, drop=0.8):
    """Sitting cross-legged on the ground or a cushion (the meditation legs, with the hips lowered
    onto the seat).  Returns the breath."""
    br = math.sin(t * w * 2)
    p["root"] = ((0, 0, 0), (0, 0, 0))
    p["hips"] = ((0.0, 0.0, 0.0), (0.0, -drop + br * 0.004, 0.0))
    for sd, s in (("L", 1), ("R", -1)):
        p["thigh." + sd] = ((-1.45, 0, 0.55 * s), (0, 0, 0))
        p["shin." + sd] = ((2.5, 0, 0), (0, 0, 0))
        p["foot." + sd] = ((0.3, 0, 0), (0, 0, 0))
    p["spine"] = ((-0.02 + br * 0.01, 0.0, 0.0), (0, 0, 0))
    p["chest"] = ((-br * 0.02, 0.0, 0.0), (0, 0.003 * br, 0))
    return br


def _crouch(p, e, knee_r=True):
    """Down on one knee (the right, or the left): blended in by `e`."""
    a, b = ("R", "L") if knee_r else ("L", "R")
    p["hips"] = ((0.12 * e, 0.0, 0.0), (0.0, -0.42 * e, -0.06 * e))
    p["thigh." + b] = ((-1.45 * e, 0.0, 0.08 * e * (1 if b == "L" else -1)), (0, 0, 0))
    p["shin." + b] = ((1.5 * e, 0.0, 0.0), (0, 0, 0))
    p["foot." + b] = ((-0.05 * e, 0.0, 0.0), (0, 0, 0))
    p["thigh." + a] = ((0.05 * e, 0.0, -0.06 * e * (1 if a == "L" else -1)), (0, 0, 0))
    p["shin." + a] = ((1.55 * e, 0.0, 0.0), (0, 0, 0))
    p["foot." + a] = ((0.6 * e, 0.0, 0.0), (0, 0, 0))
    p["toe." + a] = ((-0.9 * e, 0.0, 0.0), (0, 0, 0))


SITB_T = 4.0


def clip_sit_bench(t):
    """Sitting on a bench, a stool or a swing: thighs level, shins hanging, the hands resting on the
    knees, slow breaths and a look about."""
    w = 2 * math.pi / SITB_T
    p = clip_idle(0.0)
    br = _seated(p, t, w)
    look = math.sin(t * w + 0.6)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.42 - br * 0.01, 0.0, 0.12 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.7, 0.25 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.3, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.35, 0.35)
    p["head"] = ((0.02 + 0.03 * math.sin(t * w * 2 + 1.0), 0.25 * look, 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (1.1, 3.0)), 1))
    _secondary(p, t, False, False, (-1.5, -1.5), br, (0.4, 0.4))
    return p


DOZE_T = 4.0


def clip_doze(t):
    """Nodding off sitting on the edge of a bed: the hands in the lap, the head sinking slowly to
    the chest and jerking up again, the eyes shut, deep slow breaths."""
    w = 2 * math.pi / DOZE_T
    p = clip_idle(0.0)
    br = _seated(p, t, w * 0.5, drop=0.36)
    k = (t % DOZE_T) / DOZE_T
    sink = smooth(0.0, 0.8, k) * (1.0 - smooth(0.86, 0.92, k))
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.3, 0.1 * s, 0.05 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.95, 0.5 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.1, 0.0, 0.25 * s), (0, 0, 0))
    _hands(p, 0.5, 0.5)
    _add(p, "spine", 0.08 + 0.05 * sink)
    _add(p, "chest", 0.06 + 0.06 * sink)
    p["head"] = ((0.15 + 0.4 * sink, 0.0, 0.12 * sink), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.08 + 0.5 * smooth(0.86, 0.9, k) * (1.0 - smooth(0.92, 1.0, k)), 1))
    _secondary(p, t, False, False, (-1.5, -1.5), br, (0.4, 0.4))
    return p


DRINK_T = 2.4


def clip_drink(t):
    """Drinking: the right hand brings the dipper (or the cup) up to the lips, the left hand steadying
    it beneath, the head tips back for the sip, the eyes close, and the hands come down again."""
    k = t / DRINK_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.25, 0.78, 1.0)
    sip = _hold(k, 0.3, 0.42, 0.62, 0.74)
    p["upper_arm.R"] = ((-0.7 * e, 0.0, -0.3 * e), (0, 0, 0))
    p["forearm.R"] = ((-2.05 * e - 0.24 * (1 - e), 0.35 * e, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.25 * e - 0.45 * sip, 0.0, 0.1 * e), (0, 0, 0))
    p["upper_arm.L"] = ((-0.5 * e, 0.0, 0.3 * e), (0, 0, 0))
    p["forearm.L"] = ((-1.75 * e - 0.2 * (1 - e), -0.45 * e, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.2 * e, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.38 + 0.1 * e, 0.38 + 0.45 * e)
    _add(p, "head", -0.28 * sip, 0.0, 0.0)
    _add(p, "chest", -0.06 * sip, 0.0, 0.0)
    _add(p, "sleeve.R", 0.9 * e, 0.0, 0.0)
    _add(p, "sleeve.L", 0.5 * e, 0.0, 0.0)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.85 * sip, 1))
    return p


STRIKE_T = 1.8


def clip_strike(t):
    """Striking a temple bell (or a drum): both hands take the hanging beam, draw it back with the
    weight on the back foot, swing it forward into the bell with a step and a turn of the hips, and
    let it swing back."""
    k = t / STRIKE_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.15, 0.85, 1.0)
    wind = smooth(0.12, 0.42, k) * (1.0 - smooth(0.45, 0.55, k))
    hit = smooth(0.45, 0.56, k) * (1.0 - smooth(0.72, 0.95, k))
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-1.25 * e + 0.55 * wind - 0.3 * hit, 0.0, -0.12 * s * e), (0, 0, 0))
        p["forearm." + sd] = ((-0.55 * e - 0.45 * wind, 0.15 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.1 * e, 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.8 * e, 0.0, 0.0)
    _hands(p, 0.38 + 0.75 * e, 0.38 + 0.75 * e)
    p["hips"] = ((0.06 * e, 0.0, 0.0), (0.0, -0.04 * wind - 0.02 * hit, -0.1 * wind + 0.1 * hit))
    _add(p, "spine", -0.12 * wind + 0.12 * hit)
    _add(p, "chest", -0.1 * wind + 0.16 * hit)
    _add(p, "head", 0.05 * wind - 0.08 * hit)
    p["thigh.L"] = ((-0.5 * hit + 0.1 * wind, 0.0, 0.04), (0, 0, 0))
    p["shin.L"] = ((0.4 * hit + 0.15 * wind, 0.0, 0.0), (0, 0, 0))
    p["thigh.R"] = ((0.3 * hit + 0.25 * wind, 0.0, -0.04), (0, 0, 0))
    p["shin.R"] = ((0.25 * hit + 0.35 * wind, 0.0, 0.0), (0, 0, 0))
    p["foot.R"] = ((0.3 * hit, 0.0, 0.0), (0, 0, 0))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.8 * hit, 1))
    return p


READ_T = 3.6


def clip_read(t):
    """Reading: both hands hold a scroll (a book, a notice) open before the chest, the head bowed
    over it and the eyes running along the lines, a nod at the end of a passage."""
    w = 2 * math.pi / READ_T
    p = clip_idle(t * IDLE_T / READ_T)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.5, 0.0, 0.22 * s), (0, 0, 0))
        p["forearm." + sd] = ((-1.45, -0.3 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((-0.35, 0.0, 0.35 * s), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.6, 0.0, 0.0)
    _hands(p, 0.55, 0.55, 0.3)
    scan = math.sin(t * w * 3.0)
    p["neck"] = ((0.12, 0, 0), (0, 0, 0))
    p["head"] = ((0.3 + 0.04 * max(0.0, math.sin(t * w)), 0.1 * scan, 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.75 * _blink(t, (2.2,)), 1))
    return p


QIN_T = 2.4


def clip_play_qin(t):
    """Playing the qin: sitting cross-legged behind the low table, the hands over the strings, the
    right plucking, the left pressing and sliding along them, the head inclined, listening."""
    w = 2 * math.pi / QIN_T
    p = clip_idle(0.0)
    br = _cross_legged(p, t, w)
    pluck = math.sin(t * w * 4.0)
    slide = math.sin(t * w + 0.8)
    p["upper_arm.R"] = ((-0.75 + 0.05 * pluck, 0.0, -0.18), (0, 0, 0))
    p["forearm.R"] = ((-0.75 - 0.1 * pluck, 0.4, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.35 + 0.15 * pluck, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.7, 0.0, 0.28 + 0.12 * slide), (0, 0, 0))
    p["forearm.L"] = ((-0.8, -0.4, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.3, 0.0, -0.1 * slide), (0, 0, 0))
    _hands(p, 0.3, 0.25 + 0.25 * max(0.0, pluck), 0.2)
    _add(p, "spine", 0.06)
    _add(p, "chest", 0.08)
    p["head"] = ((0.2, 0.06 * slide, -0.1), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.6 * _blink(t, (1.6,)), 1))
    _secondary(p, t, False, True, (-1.45, -1.45), br, (0.5, 0.5))
    return p


MEDITATE_T = 4.0


def clip_meditate(t):
    """Meditation on a cushion: cross-legged with the hips down on the seat, the hands resting in the
    lap in a mudra, the eyes closed, long slow breaths rising through the chest."""
    w = 2 * math.pi / MEDITATE_T
    p = clip_idle(0.0)
    br = _cross_legged(p, t, w * 0.5)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.42 - br * 0.02, 0.0, 0.22 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.95, -0.35 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.25, 0.0, 0.2 * s), (0, 0, 0))
    _hands(p, 0.25, 0.25, 0.35)
    p["head"] = ((0.14 + br * 0.02, 0.0, 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.12, 1))
    _secondary(p, t, False, True, (-1.45, -1.45), br, (0.5, 0.5))
    return p


FISH_T = 3.2


def clip_fish(t):
    """Fishing: standing on the bank with the rod held out over the water in both hands, the tip
    bobbing as the line drifts, and now and then a little flick to lift it."""
    w = 2 * math.pi / FISH_T
    k = (t % FISH_T) / FISH_T
    p = clip_idle(t * IDLE_T / FISH_T)
    bob = 0.03 * math.sin(t * w * 3.0)
    flick = _hold(k, 0.7, 0.76, 0.8, 0.9)
    p["upper_arm.R"] = ((-0.55 + bob - 0.25 * flick, 0.0, -0.12), (0, 0, 0))
    p["forearm.R"] = ((-1.05 - 0.2 * flick, 0.35, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.2 - 0.3 * flick, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-1.0 + bob - 0.15 * flick, 0.0, 0.12), (0, 0, 0))
    p["forearm.L"] = ((-0.45, -0.3, 0.0), (0, 0, 0))
    p["hand.L"] = ((-0.1, 0.0, 0.0), (0, 0, 0))
    _hands(p, 1.0, 1.0)
    _add(p, "sleeve.R", 0.6, 0.0, 0.0)
    _add(p, "sleeve.L", 0.9, 0.0, 0.0)
    _add(p, "head", 0.18, 0.0, 0.0)
    return p


PRAY_T = 3.0


def clip_pray(t):
    """Prayer: the palms pressed together before the chest, the head bowed over them, the eyes shut,
    breathing slowly; a deeper bow once in a while."""
    w = 2 * math.pi / PRAY_T
    k = (t % (PRAY_T * 2.0)) / (PRAY_T * 2.0)
    p = clip_idle(0.0)
    br = math.sin(t * w)
    bow = _hold(k, 0.55, 0.68, 0.78, 0.92)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.32 - 0.02 * br, 0.12 * s, -0.36 * s), (0, 0, 0))
        p["forearm." + sd] = ((-1.62, -0.6 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((-0.35, 0.0, 0.45 * s), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.6, 0.0, 0.0)
    _hands(p, 0.05, 0.05, 0.05)
    _add(p, "chest", 0.05 + 0.25 * bow + 0.01 * br, 0.0, 0.0)
    _add(p, "spine", 0.1 * bow, 0.0, 0.0)
    p["head"] = ((0.3 + 0.15 * bow, 0.0, 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.06, 1))
    return p


GATHER_T = 2.6


def clip_gather(t):
    """Gathering: down on one knee, the right hand reaches to the ground and picks, then up again,
    looking at what it found in the palm."""
    k = t / GATHER_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.25, 0.62, 0.8)
    reach = _hold(k, 0.2, 0.32, 0.42, 0.55)
    look = _hold(k, 0.55, 0.68, 0.88, 1.0)
    _crouch(p, e)
    p["upper_arm.R"] = ((-0.75 * reach - 0.9 * look, 0.0, -0.15 * reach), (0, 0, 0))
    p["forearm.R"] = ((-0.25 * reach - 1.3 * look - 0.2 * (1 - reach - look), 0.6 * look, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.3 * reach - 0.3 * look, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.3 * e, 0.0, 0.15 * e), (0, 0, 0))
    p["forearm.L"] = ((-0.9 * e - 0.2, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.38, 0.2 + 0.8 * smooth(0.36, 0.44, k) - 0.5 * look)
    _add(p, "spine", 0.25 * reach)
    _add(p, "chest", 0.25 * reach)
    _add(p, "head", 0.3 * reach + 0.35 * look, 0.0, 0.0)
    _add(p, "sleeve.R", 0.4 * look, 0.0, 0.0)
    return p


WARM_T = 2.4


def clip_warm(t):
    """Warming the hands at a fire: leaning in a little with both hands held out to it, palms to the
    heat, rubbing them together now and then."""
    w = 2 * math.pi / WARM_T
    k = (t % WARM_T) / WARM_T
    p = clip_idle(t * IDLE_T / WARM_T)
    rub = _hold(k, 0.55, 0.62, 0.85, 0.95)
    wob = math.sin(t * w * 6.0) * rub
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.85 + 0.1 * rub, 0.0, (0.1 - 0.12 * rub) * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.35 - 0.5 * rub, 0.5 * s * (1 - rub) + 0.1 * wob * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.6 * (1 - rub), 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.7, 0.0, 0.0)
    _hands(p, 0.15, 0.15)
    _add(p, "spine", 0.08)
    _add(p, "chest", 0.08)
    _add(p, "head", 0.05)
    p["hips"] = ((0.04, 0.0, 0.0), (0.0, -0.04, -0.03))
    for sd in ("L", "R"):
        _add(p, "thigh." + sd, -0.08)
        _add(p, "shin." + sd, 0.16)
        _add(p, "foot." + sd, -0.08)
    return p


STIR_T = 2.0


def clip_stir(t):
    """Stirring a cauldron (or a pot on the stove): both hands on the long ladle, going round in slow
    circles, the shoulders and the chest turning with them."""
    w = 2 * math.pi / STIR_T
    c = math.cos(t * w)
    s1 = math.sin(t * w)
    p = clip_idle(t * IDLE_T / STIR_T)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.75 + 0.18 * s1, 0.0, (0.05 + 0.12 * c * s) * s), (0, 0, 0))
        p["forearm." + sd] = ((-1.0 - 0.15 * s1, 0.3 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.2, 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.6, 0.0, 0.0)
    _hands(p, 0.9, 0.9)
    _add(p, "chest", 0.1, 0.12 * c, 0.0)
    _add(p, "spine", 0.06, 0.06 * c, 0.0)
    _add(p, "head", 0.22, -0.05 * c, 0.0)
    return p


HAMMER_T = 1.2


def clip_hammer(t):
    """Working at the anvil: the left hand holds the tongs on the iron, the right lifts the hammer
    high behind the head and brings it down on the blow, and lifts again."""
    k = (t % HAMMER_T) / HAMMER_T
    p = clip_idle(0.0)
    up = smooth(0.05, 0.5, k) * (1.0 - smooth(0.62, 0.72, k))
    blow = smooth(0.62, 0.72, k) * (1.0 - smooth(0.8, 1.0, k))
    p["upper_arm.R"] = ((-0.7 - 1.9 * up + 0.2 * blow, 0.0, -0.3 - 0.1 * up), (0, 0, 0))
    p["forearm.R"] = ((-0.6 - 1.2 * up, 0.2, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.3 - 0.5 * up + 0.4 * blow, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.75, 0.0, 0.15), (0, 0, 0))
    p["forearm.L"] = ((-0.55, -0.3, 0.0), (0, 0, 0))
    _hands(p, 1.0, 1.1)
    p["hips"] = ((0.08, 0.0, 0.0), (0.0, -0.06 - 0.02 * blow, 0.0))
    _add(p, "spine", 0.08 - 0.06 * up + 0.08 * blow)
    _add(p, "chest", 0.1 - 0.08 * up + 0.1 * blow)
    _add(p, "head", 0.25)
    _add(p, "sleeve.R", 0.5 + 0.8 * up, 0.0, 0.0)
    for sd in ("L", "R"):
        _add(p, "thigh." + sd, -0.15)
        _add(p, "shin." + sd, 0.3)
        _add(p, "foot." + sd, -0.15)
    return p


SWEEP_T = 1.8


def clip_sweep(t):
    """Sweeping (what Lin Feng did for three years on the sect's steps): the broom held low, the left
    hand high on the handle and the right low, swept from side to side with a turn of the body."""
    w = 2 * math.pi / SWEEP_T
    sw = math.sin(t * w)
    p = clip_idle(t * IDLE_T / SWEEP_T)
    p["upper_arm.L"] = ((-0.65 + 0.05 * sw, 0.0, 0.05 + 0.15 * sw), (0, 0, 0))
    p["forearm.L"] = ((-1.15, -0.3, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.1, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.R"] = ((-0.35 + 0.05 * sw, 0.0, -0.25 + 0.2 * sw), (0, 0, 0))
    p["forearm.R"] = ((-0.35, 0.3, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.2, 0.0, 0.0), (0, 0, 0))
    _hands(p, 1.0, 1.0)
    p["hips"] = ((0.06, 0.12 * sw, 0.0), (0.0, -0.04, 0.0))
    _add(p, "spine", 0.12, 0.12 * sw, 0.0)
    _add(p, "chest", 0.12, 0.18 * sw, 0.0)
    _add(p, "head", 0.3, -0.12 * sw, 0.0)
    for sd in ("L", "R"):
        _add(p, "thigh." + sd, -0.12)
        _add(p, "shin." + sd, 0.24)
        _add(p, "foot." + sd, -0.12)
    return p


WEAVE_T = 1.4


def clip_weave(t):
    """Weaving: seated at the loom, the hands pass the shuttle through the shed one way and the
    other, then pull the beater in with both hands, and the treadles change."""
    w = 2 * math.pi / WEAVE_T
    k = (t % WEAVE_T) / WEAVE_T
    p = clip_idle(0.0)
    br = _seated(p, t, w * 0.25)
    shuttle = math.sin(t * w)
    beat = _hold(k, 0.42, 0.5, 0.58, 0.7)
    p["upper_arm.L"] = ((-0.95 + 0.25 * beat, 0.0, 0.18 + 0.15 * max(0.0, shuttle)), (0, 0, 0))
    p["forearm.L"] = ((-0.75 - 0.3 * beat, -0.3, 0.0), (0, 0, 0))
    p["upper_arm.R"] = ((-0.95 + 0.25 * beat, 0.0, -0.18 - 0.15 * max(0.0, -shuttle)), (0, 0, 0))
    p["forearm.R"] = ((-0.75 - 0.3 * beat, 0.3, 0.0), (0, 0, 0))
    _hands(p, 0.7, 0.7)
    _add(p, "chest", 0.06 + 0.06 * beat, 0.08 * shuttle, 0.0)
    _add(p, "head", 0.15, 0.1 * shuttle, 0.0)
    _add(p, "thigh.L", -0.08 * max(0.0, shuttle))
    _add(p, "thigh.R", -0.08 * max(0.0, -shuttle))
    _secondary(p, t, False, False, (-1.5, -1.5), br, (0.6, 0.6))
    return p


LIFT_T = 2.8


def clip_lift(t):
    """Lifting a training stone: squat, both hands on the stone's grip, drive up through the legs and
    press it overhead, hold it there a breath, and set it down again."""
    k = t / LIFT_T
    p = clip_idle(0.0)
    squat = _hold(k, 0.0, 0.18, 0.3, 0.45) + _hold(k, 0.78, 0.9, 1.0, 1.01)
    press = _hold(k, 0.38, 0.55, 0.72, 0.86)
    held = smooth(0.12, 0.2, k) * (1.0 - smooth(0.92, 1.0, k))
    p["hips"] = ((0.3 * squat, 0.0, 0.0), (0.0, -0.38 * squat, -0.12 * squat))
    for sd, s in (("L", 1), ("R", -1)):
        p["thigh." + sd] = ((-1.25 * squat, 0.0, 0.14 * s), (0, 0, 0))
        p["shin." + sd] = ((1.5 * squat, 0.0, 0.0), (0, 0, 0))
        p["foot." + sd] = ((-0.25 * squat, 0.0, 0.0), (0, 0, 0))
        arm = -0.55 * squat * (1 - press) - 2.85 * press
        p["upper_arm." + sd] = ((arm, 0.0, (0.12 + 0.18 * press) * s * held), (0, 0, 0))
        p["forearm." + sd] = ((-0.15 * held - 0.3 * press, 0.2 * s * press, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.2 * held, 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.3 + 1.2 * press, 0.0, 0.0)
    _hands(p, 0.38 + 0.7 * held, 0.38 + 0.7 * held)
    _add(p, "spine", 0.3 * squat - 0.05 * press)
    _add(p, "chest", 0.15 * squat - 0.08 * press)
    _add(p, "head", -0.1 * squat - 0.15 * press)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.6 * press, 1))
    return p


TOSS_T = 1.4


def clip_toss(t):
    """Tossing a coin into a well (or crumbs to the fish): the right hand swings back and lobs it
    forward and up, the fingers opening at the top, and the eyes follow it down."""
    k = t / TOSS_T
    p = clip_idle(0.0)
    back = _hold(k, 0.05, 0.25, 0.3, 0.38)
    lob = _hold(k, 0.3, 0.45, 0.6, 0.85)
    p["upper_arm.R"] = ((0.45 * back - 1.25 * lob, 0.0, -0.1), (0, 0, 0))
    p["forearm.R"] = ((-0.4 * back - 0.25 * lob - 0.24, 0.3 * lob, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.3 * back - 0.35 * lob, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.38, 0.38 + 0.5 * back * (1 - lob) - 0.3 * lob)
    _add(p, "chest", 0.05 * back - 0.05 * lob, 0.1 * back - 0.08 * lob, 0.0)
    _add(p, "head", -0.12 * lob + 0.2 * smooth(0.6, 0.85, k) * (1 - smooth(0.9, 1.0, k)), 0.0, 0.0)
    _add(p, "sleeve.R", 0.8 * lob, 0.0, 0.0)
    return p


TOUCH_T = 2.2


def clip_touch(t):
    """Laying a hand on something (a stele, a great tree, a stone lion's head, a nest): the right hand
    reaches out and rests flat on it, the eyes close a moment, and the hand comes back."""
    k = t / TOUCH_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.28, 0.72, 1.0)
    rest = _hold(k, 0.3, 0.38, 0.62, 0.7)
    p["upper_arm.R"] = ((-1.25 * e, 0.0, -0.08 * e), (0, 0, 0))
    p["forearm.R"] = ((-0.25 * e - 0.24 * (1 - e), 0.25 * e, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.7 * e, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.38, 0.38 - 0.33 * e, 0.05)
    _add(p, "chest", 0.06 * e, 0.0, 0.0)
    _add(p, "head", 0.1 * e + 0.08 * rest, 0.0, 0.0)
    _add(p, "sleeve.R", 1.0 * e, 0.0, 0.0)
    _add(p, "hips", 0.0, 0.0, 0.0)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.9 * rest, 1))
    return p


# ---------------------------------------------------------------- things done together (Part XV)
# The Lotus release: more things to do in the world (scripts/props.gd) and the things Lin Feng and
# Yue Ling do side by side (scripts/bonds.gd): a flute played to his qin, a sleeve dance, a kite, the
# stars from the grass, a sky lantern let go and a river lantern pushed out, a poem written, a bow
# drawn at the butts, a soak in a hot spring, the millstone pushed round, a watchtower climbed and the
# land looked over from the top, a clap for the other's turn, and a sword form on an open-air stage.

FLUTE_T = 2.4


def clip_play_flute(t):
    """Playing the bamboo flute (dizi): held level out to the right at the lips, both hands along it,
    the fingers lifting and falling over the holes, the body swaying with the tune, eyes half shut."""
    w = 2 * math.pi / FLUTE_T
    p = clip_idle(t * IDLE_T / FLUTE_T)
    sway = math.sin(t * w)
    trill = math.sin(t * w * 4.0)
    p["upper_arm.L"] = ((-0.72 + 0.02 * sway, 0.0, -0.42), (0, 0, 0))
    p["forearm.L"] = ((-2.1, 0.12, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.1, 0.2, 0.0), (0, 0, 0))
    p["upper_arm.R"] = ((-0.57 + 0.02 * sway, 0.0, 0.02), (0, 0, 0))
    p["forearm.R"] = ((-1.98, -0.12, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.1, -0.2, 0.0), (0, 0, 0))
    _hands(p, 0.3 + 0.2 * max(0.0, trill), 0.3 + 0.2 * max(0.0, -trill), 0.25)
    _add(p, "sleeve.L", 0.7, 0.0, 0.0)
    _add(p, "sleeve.R", 0.7, 0.0, 0.0)
    p["hips"] = ((0.02, 0.06 * sway, -0.03 * sway), (0.0, -0.005, 0.0))
    _add(p, "spine", 0.0, 0.05 * sway, 0.03 * sway)
    p["head"] = ((0.06, -0.12, -0.12 + 0.04 * sway), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.45 * _blink(t, (1.4,)), 1))
    return p


DANCE_T = 4.0


def clip_dance(t):
    """A sleeve dance: stepping on the spot in a slow figure, the body turning half one way and back,
    the arms sweeping up and round in long arcs so the sleeves fly out, the head following the
    leading hand."""
    w = 2 * math.pi / DANCE_T
    ph = t * w
    a = math.sin(ph)
    b = math.cos(ph)
    st = math.sin(ph * 2.0)
    p = clip_idle(0.0)
    p["root"] = ((0, 0.55 * a, 0), (0, 0, 0))
    p["hips"] = ((0.03, 0.2 * a, 0.05 * st), (0.0, -0.04 - 0.03 * abs(st), 0.0))
    p["spine"] = ((-0.04, 0.15 * a, -0.06 * b), (0, 0, 0))
    p["chest"] = ((-0.06, 0.12 * a, -0.05 * b), (0, 0, 0))
    for sd, s, ph2 in (("L", 1, 0.0), ("R", -1, math.pi)):
        sweep = math.sin(ph + ph2)
        hi = max(0.0, sweep)
        p["upper_arm." + sd] = ((-0.6 - 1.7 * hi, 0.0, (0.55 + 0.5 * math.cos(ph + ph2)) * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.35 - 0.45 * (1.0 - hi), 0.3 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.35 - 0.6 * hi, 0.25 * s * sweep, 0.0), (0, 0, 0))
        p["sleeve." + sd] = ((0.6 + 0.9 * abs(math.cos(ph + ph2)), 0, 0.3 * s * sweep), (0, 0, 0))
    _hands(p, 0.1, 0.1, 0.1)
    for sd, ph3 in (("L", 0.0), ("R", math.pi)):
        k = max(0.0, math.sin(ph * 2.0 + ph3))
        p["thigh." + sd] = ((-0.4 * k, 0.0, 0.06 * (1 if sd == "L" else -1)), (0, 0, 0))
        p["shin." + sd] = ((0.7 * k + 0.05, 0.0, 0.0), (0, 0, 0))
        p["foot." + sd] = ((-0.2 * k, 0.0, 0.0), (0, 0, 0))
        p["toe." + sd] = ((0.3 * k, 0.0, 0.0), (0, 0, 0))
    p["head"] = ((-0.08, 0.35 * a, 0.08 * b), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.7 * _blink(t, (1.0, 3.1)), 1))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.15, 1))
    flow = math.sin(ph * 2.0 - 0.8)
    p["robe_f"] = ((-0.2 - 0.15 * abs(st), 0, 0), (0, 0, 0))
    p["robe_b"] = ((0.2 + 0.15 * abs(st), 0, 0), (0, 0, 0))
    p["robe_l"] = ((-0.1, 0, -0.25 - 0.15 * flow), (0, 0, 0))
    p["robe_r"] = ((-0.1, 0, 0.25 + 0.15 * flow), (0, 0, 0))
    p["hair_tail"] = ((0.25, 0, -0.35 * a), (0, 0, 0))
    p["hair_tail2"] = ((0.15, 0, -0.3 * math.sin(ph - 0.7)), (0, 0, 0))
    p["cape"] = ((0.15, 0.1 * a, 0), (0, 0, 0))
    p["cape2"] = ((0.08, 0, -0.1 * a), (0, 0, 0))
    p["cape3"] = ((0.06, 0, -0.12 * math.sin(ph - 0.6)), (0, 0, 0))
    return p


KITE_T = 3.0


def clip_kite(t):
    """Flying a kite: standing with the head tipped back to watch it, the right hand holding the reel
    before the chest and the left hand up on the string, tugging it in short pulls when it dips."""
    w = 2 * math.pi / KITE_T
    k = (t % KITE_T) / KITE_T
    p = clip_idle(t * IDLE_T / KITE_T)
    tug = _hold(k, 0.55, 0.62, 0.68, 0.8)
    drift = math.sin(t * w)
    p["upper_arm.R"] = ((-0.75 - 0.1 * tug, 0.0, -0.15), (0, 0, 0))
    p["forearm.R"] = ((-1.2 + 0.2 * tug, 0.35, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.15, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-2.1 + 0.4 * tug + 0.05 * drift, 0.0, 0.25), (0, 0, 0))
    p["forearm.L"] = ((-0.4 - 0.3 * tug, -0.2, 0.0), (0, 0, 0))
    p["hand.L"] = ((-0.2, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.9, 1.0)
    _add(p, "sleeve.L", 1.1, 0.0, 0.0)
    _add(p, "sleeve.R", 0.5, 0.0, 0.0)
    _add(p, "chest", -0.12 - 0.04 * tug, 0.0, 0.0)
    p["neck"] = ((-0.12, 0.0, 0.0), (0, 0, 0))
    p["head"] = ((-0.45 + 0.05 * drift, 0.12 * drift, 0.0), (0, 0, 0))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.1, 1))
    p["hips"] = ((0.0, 0.0, 0.0), (0.0, -0.01, -0.03 * tug))
    _add(p, "thigh.R", 0.15 * tug)
    _add(p, "shin.R", 0.1 * tug)
    return p


STAR_T = 4.0


def clip_stargaze(t):
    """Watching the stars from the grass: sitting on the ground with the legs out in front, leaning
    back on both hands, the head tipped back to the sky; now and then the right hand comes up to
    point out a star, and goes back."""
    w = 2 * math.pi / STAR_T
    k = (t % (STAR_T * 2.0)) / (STAR_T * 2.0)
    p = clip_idle(0.0)
    br = math.sin(t * w * 0.5)
    point = _hold(k, 0.5, 0.58, 0.72, 0.8)
    p["root"] = ((0, 0, 0), (0, 0, 0))
    p["hips"] = ((-0.25, 0.0, 0.0), (0.0, -0.8 + br * 0.004, -0.12))
    for sd, s in (("L", 1), ("R", -1)):
        p["thigh." + sd] = ((-1.3, 0.0, 0.12 * s), (0, 0, 0))
        p["shin." + sd] = ((0.35 if sd == "L" else 0.9, 0.0, 0.0), (0, 0, 0))
        p["foot." + sd] = ((0.25, 0.0, 0.0), (0, 0, 0))
    p["spine"] = ((-0.12 + br * 0.01, 0.0, 0.0), (0, 0, 0))
    p["chest"] = ((-0.08 - br * 0.02, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((0.75, 0.0, 0.3), (0, 0, 0))
    p["forearm.L"] = ((-0.15, 0.0, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.8, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.R"] = ((0.75 * (1.0 - point) - 2.4 * point, 0.0, -0.3 * (1.0 - point) - 0.1 * point), (0, 0, 0))
    p["forearm.R"] = ((-0.15 - 0.1 * point, 0.0, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.8 * (1.0 - point), 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.2, 0.2 + 0.6 * point)
    p["neck"] = ((-0.2, 0.0, 0.0), (0, 0, 0))
    p["head"] = ((-0.42, 0.15 * math.sin(t * w * 0.5 + 1.0), 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (2.1, 5.9)), 1))
    _secondary(p, t, False, True, (-1.3, -1.3), br, (0.3, 0.3 + 0.8 * point))
    return p


RELEASE_T = 3.2


def clip_release(t):
    """Letting a sky lantern go: both hands hold it before the chest while the warm air fills it,
    lift it slowly overhead, open and let it rise, the head tipping back to watch it go."""
    k = t / RELEASE_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.12, 0.88, 1.0)
    up = smooth(0.22, 0.58, k)
    let = smooth(0.58, 0.66, k)
    watch = _hold(k, 0.5, 0.62, 0.85, 0.98)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = (((-0.55 * (1.0 - up) - 2.55 * up) * e, 0.0, (0.3 * (1.0 - up) + 0.18 * up + 0.2 * let) * s * e), (0, 0, 0))
        p["forearm." + sd] = (((-1.3 * (1.0 - up) - 0.3 * up) * e - 0.22 * (1 - e), -0.3 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.15 * e - 0.3 * let * e, 0.0, 0.3 * s * e * (1.0 - let)), (0, 0, 0))
        _add(p, "sleeve." + sd, (0.5 + 1.0 * up) * e, 0.0, 0.0)
    _hands(p, 0.38 - 0.3 * e * (1.0 - let), 0.38 - 0.3 * e * (1.0 - let), 0.1)
    _add(p, "chest", -0.1 * up * e, 0.0, 0.0)
    p["neck"] = ((-0.15 * watch, 0.0, 0.0), (0, 0, 0))
    _add(p, "head", -0.25 * up * e - 0.25 * watch, 0.0, 0.0)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.25 * watch, 1))
    return p


FLOAT_T = 3.0


def clip_float_lantern(t):
    """Setting a lantern on the water: down on one knee at the bank, both hands lower the little lotus
    lantern to the water and push it gently out, then a moment watching it drift, and up again."""
    k = t / FLOAT_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.25, 0.75, 1.0)
    push = _hold(k, 0.32, 0.46, 0.52, 0.64)
    _crouch(p, e)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-(0.75 + 0.45 * push) * e, 0.0, 0.18 * s * e), (0, 0, 0))
        p["forearm." + sd] = ((-(0.75 - 0.45 * push) * e - 0.22 * (1 - e), -0.25 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.25 * e, 0.0, 0.2 * s * e), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.4 * e, 0.0, 0.0)
    _hands(p, 0.38 - 0.25 * e, 0.38 - 0.25 * e, 0.1)
    _add(p, "spine", 0.3 * e + 0.1 * push)
    _add(p, "chest", 0.2 * e)
    _add(p, "head", 0.3 * e, 0.0, 0.0)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.3 * e, 1))
    return p


WRITE_T = 2.4


def clip_write(t):
    """Writing with a brush at a table: standing bent a little over the paper, the left hand holding
    the right sleeve back out of the ink, the right hand moving the brush in strokes, lifting between
    characters; the head follows the brush."""
    w = 2 * math.pi / WRITE_T
    k = (t % WRITE_T) / WRITE_T
    p = clip_idle(t * IDLE_T / WRITE_T)
    stroke = math.sin(t * w * 2.0)
    lift = _hold(k, 0.42, 0.5, 0.56, 0.64)
    p["upper_arm.R"] = ((-0.85 + 0.06 * stroke + 0.12 * lift, 0.0, -0.15 + 0.08 * math.cos(t * w * 2.0)), (0, 0, 0))
    p["forearm.R"] = ((-0.9 - 0.08 * stroke - 0.15 * lift, 0.4, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.35 + 0.15 * stroke, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.55, 0.0, -0.35), (0, 0, 0))
    p["forearm.L"] = ((-1.45, -0.2, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.1, 0.0, 0.2), (0, 0, 0))
    _hands(p, 0.8, 0.85, 0.3)
    _add(p, "sleeve.R", 0.6, 0.0, 0.0)
    _add(p, "sleeve.L", 0.5, 0.0, 0.0)
    _add(p, "spine", 0.18)
    _add(p, "chest", 0.14)
    p["head"] = ((0.38, 0.06 * stroke, 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.7 * _blink(t, (1.9,)), 1))
    p["hips"] = ((0.06, 0.0, 0.0), (0.0, -0.02, -0.04))
    return p


ARCHERY_T = 2.6


def clip_archery(t):
    """Drawing a bow at the butts: the bow comes up in the left hand at arm's length, the right hand
    draws the string back to the cheek, a held breath, the loose (the right hand flies back open),
    and the bow comes down."""
    k = t / ARCHERY_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.15, 0.85, 1.0)
    draw = smooth(0.18, 0.45, k) * (1.0 - smooth(0.62, 0.66, k))
    loose = _hold(k, 0.62, 0.66, 0.74, 0.85)
    p["upper_arm.L"] = ((-1.5 * e, 0.0, -0.12 * e), (0, 0, 0))
    p["forearm.L"] = ((-0.05 * e - 0.2 * (1 - e), 0.0, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.0, 1.2 * e, 0.0), (0, 0, 0))
    p["upper_arm.R"] = ((-1.45 * e + 0.15 * draw, 0.0, 0.2 * e * (1.0 - draw) - 0.55 * draw - 0.25 * loose), (0, 0, 0))
    p["forearm.R"] = ((-0.4 * e - 1.8 * draw - 0.5 * loose - 0.24 * (1 - e), 0.0, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.2 * draw, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.38 + 0.7 * e, 0.38 + 0.4 * draw - 0.35 * loose)
    _add(p, "sleeve.L", 1.0 * e, 0.0, 0.0)
    _add(p, "sleeve.R", 0.6 * e, 0.0, 0.0)
    _add(p, "chest", -0.06 * draw, -0.18 * e, 0.0)
    _add(p, "spine", 0.0, -0.1 * e, 0.0)
    _add(p, "head", 0.05 * e, 0.22 * e, 0.0)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.35 * draw, 1))
    p["thigh.L"] = ((-0.08 * e, 0.0, 0.16 * e), (0, 0, 0))
    p["thigh.R"] = ((0.05 * e, 0.0, -0.16 * e), (0, 0, 0))
    return p


SOAK_T = 4.0


def clip_soak(t):
    """Soaking in a hot spring: sitting on the ledge under the water with the legs out, the arms laid
    along the rim of stones to either side, the head back and the eyes shut, slow deep breaths."""
    w = 2 * math.pi / SOAK_T
    p = clip_idle(0.0)
    br = _seated(p, t, w * 0.5, drop=0.6)
    for sd, s in (("L", 1), ("R", -1)):
        p["thigh." + sd] = ((-1.35, 0.0, 0.16 * s), (0, 0, 0))
        p["shin." + sd] = ((0.7, 0.0, 0.0), (0, 0, 0))
        p["upper_arm." + sd] = ((0.25, 0.0, (1.15 + 0.02 * br) * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.35, 0.3 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.1, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.2, 0.2)
    p["spine"] = ((-0.2 + br * 0.01, 0.0, 0.0), (0, 0, 0))
    p["chest"] = ((-0.08 - br * 0.025, 0.0, 0.0), (0, 0.004 * br, 0))
    p["head"] = ((-0.32, 0.06 * math.sin(t * w * 0.5), 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.08, 1))
    _secondary(p, t, False, True, (-1.35, -1.35), br, (0.2, 0.2))
    return p


PUSH_T = WALK_T


def clip_push(t):
    """Pushing the millstone round: leaning into the bar with both hands on it at chest height,
    walking steadily on a circle (the game moves him round), the head down with the effort."""
    p = clip_walk(t)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-1.2, 0.0, 0.12 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.65, 0.2 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.45, 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.7, 0.0, 0.0)
    _hands(p, 1.0, 1.0)
    _add(p, "hips", 0.14, 0.0, 0.0)
    _add(p, "spine", 0.22, 0.0, 0.0)
    _add(p, "chest", 0.12, 0.0, 0.0)
    _add(p, "head", -0.25, 0.0, 0.0)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.2, 1))
    return p


CLIMB_T = 1.2


def clip_climb(t):
    """Climbing a ladder: hand over hand and foot over foot, each hand reaching up for the next rung
    as the opposite foot steps up, the body close in to the ladder."""
    w = 2 * math.pi / CLIMB_T
    a = math.sin(t * w)
    p = clip_idle(0.0)
    for sd, s, sg in (("L", 1, 1.0), ("R", -1, -1.0)):
        r = max(0.0, a * sg)
        p["upper_arm." + sd] = ((-2.3 - 0.45 * r, 0.0, 0.18 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.75 + 0.45 * r, 0.0, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.2, 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 1.2, 0.0, 0.0)
        lift = max(0.0, -a * sg)
        p["thigh." + sd] = ((-0.35 - 0.85 * lift, 0.0, 0.08 * s), (0, 0, 0))
        p["shin." + sd] = ((0.45 + 1.0 * lift, 0.0, 0.0), (0, 0, 0))
        p["foot." + sd] = ((-0.1 - 0.15 * lift, 0.0, 0.0), (0, 0, 0))
    _hands(p, 1.0, 1.0)
    p["hips"] = ((0.18, 0.06 * a, 0.0), (0.0, -0.06, -0.08))
    _add(p, "spine", 0.08, 0.0, 0.0)
    p["head"] = ((-0.2, 0.0, 0.0), (0, 0, 0))
    return p


GAZE_T = 4.0


def clip_gaze(t):
    """Looking out from a height: standing with the weight on one leg, the right hand shading the eyes,
    the head turning slowly from one side of the land to the other, the left hand on the hip."""
    w = 2 * math.pi / GAZE_T
    p = clip_idle(t)
    look = math.sin(t * w * 0.5)
    p["upper_arm.R"] = ((-1.65, 0.0, 0.42), (0, 0, 0))
    p["forearm.R"] = ((-1.55, -0.3, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.4, 0.0, -0.45), (0, 0, 0))
    p["upper_arm.L"] = ((0.1, 0.0, 0.55), (0, 0, 0))
    p["forearm.L"] = ((-1.2, 0.5, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.6, 0.4, 0.0), (0, 0, 0))
    _hands(p, 0.6, 0.15)
    _add(p, "sleeve.R", 1.2, 0.0, 0.0)
    _add(p, "chest", -0.04, 0.12 * look, 0.0)
    p["head"] = ((-0.04, 0.45 * look, 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.6 * _blink(t, (1.7, 3.5)), 1))
    return p


CLAP_T = 1.6


def clip_clap(t):
    """Clapping for the other's turn: the hands come together before the chest three times, quick,
    with a little bounce on the toes and a wide smile."""
    k = t / CLAP_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.15, 0.82, 1.0)
    cl = max(0.0, math.sin(k * math.pi * 6.0)) * smooth(0.1, 0.2, k) * (1.0 - smooth(0.72, 0.8, k))
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.65 * e, 0.0, (0.15 - 0.32 * cl) * s * e - 0.05 * s * (1 - e)), (0, 0, 0))
        p["forearm." + sd] = ((-1.4 * e - 0.22 * (1 - e), -0.45 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((-0.2 * e, 0.0, 0.45 * s * e), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.6 * e, 0.0, 0.0)
    _hands(p, 0.05, 0.05, 0.05)
    bounce = abs(math.sin(k * math.pi * 3.0)) * e
    p["hips"] = ((0.0, 0.0, 0.0), (0.0, 0.015 * bounce, 0.0))
    _add(p, "head", -0.06 * e, 0.0, 0.05 * math.sin(k * math.pi * 3.0) * e)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.6 * e, 1))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.5 * e, 1))
    return p


SWORD_T = 3.2


def clip_sword_dance(t):
    """A sword form on the stage (the sword stays in the hand): a rising cut with the weight on the back
    leg, a turn with the blade sweeping round at shoulder height, a low sweep dropping into a bow
    stance, a thrust from it, and back to the opening guard: one figure, round and round."""
    k = (t % SWORD_T) / SWORD_T
    p = clip_idle(0.0)
    rise = _hold(k, 0.0, 0.18, 0.25, 0.35)
    turn = _hold(k, 0.25, 0.42, 0.45, 0.55)
    low = _hold(k, 0.5, 0.62, 0.66, 0.75)
    thrust = _hold(k, 0.68, 0.78, 0.84, 0.98)
    p["root"] = ((0, 1.2 * turn - 0.3 * low, 0), (0, 0, 0))
    p["hips"] = ((0.05 + 0.2 * low, 0.3 * turn, 0.0), (0.0, -0.05 - 0.28 * low - 0.1 * thrust, 0.12 * thrust - 0.04 * rise))
    p["upper_arm.R"] = ((-0.5 - 2.3 * rise - 1.3 * turn - 0.6 * low - 1.35 * thrust, 0.0, -0.25 + 0.2 * rise - 0.9 * turn + 0.4 * low), (0, 0, 0))
    p["forearm.R"] = ((-0.45 - 0.3 * rise + 0.25 * turn + 0.2 * thrust, 0.0, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.2 * rise - 0.3 * low, 0.0, 0.0), (0, 0, 0))
    # the sword-seal hand balances the blade
    p["upper_arm.L"] = ((-0.6 - 0.9 * turn + 0.6 * thrust, 0.0, 0.6 + 0.5 * low + 0.4 * thrust), (0, 0, 0))
    p["forearm.L"] = ((-1.2 + 0.6 * turn + 0.5 * thrust, -0.3, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.3, 0.2, 0.0), (0, 0, 0))
    _hands(p, 0.2, 1.15, 0.3)
    p["spine"] = ((0.05 + 0.15 * low + 0.08 * thrust, -0.15 * turn, 0.0), (0, 0, 0))
    p["chest"] = ((0.05 - 0.06 * rise, -0.2 * turn + 0.1 * thrust, 0.0), (0, 0, 0))
    p["head"] = ((-0.05 * rise + 0.1 * low, 0.25 * turn - 0.1 * thrust, 0.0), (0, 0, 0))
    p["thigh.L"] = ((-0.9 * low - 0.6 * thrust + 0.1 * rise, 0.0, 0.12), (0, 0, 0))
    p["shin.L"] = ((1.0 * low + 0.5 * thrust + 0.2 * rise, 0.0, 0.0), (0, 0, 0))
    p["foot.L"] = ((-0.1 * low, 0.0, 0.0), (0, 0, 0))
    p["thigh.R"] = ((0.35 * low + 0.45 * thrust - 0.25 * rise, 0.0, -0.12), (0, 0, 0))
    p["shin.R"] = ((0.35 * low + 0.25 * thrust + 0.45 * rise, 0.0, 0.0), (0, 0, 0))
    p["foot.R"] = ((0.3 * thrust, 0.0, 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.9, 1))
    _secondary(p, t, True, False, (-0.9 * low - 0.6 * thrust, 0.35 * low + 0.45 * thrust), math.sin(k * 2 * math.pi), (0.4 + 0.6 * turn, 0.8 * rise + 0.6 * turn))
    return p


# ---------------------------------------------------------------- the Living Land release: work
# What the people of the towns do all day (scripts/folk.gd in the game, which plays these on every
# townsperson as well as on the party): hoe a field, chop firewood, carry a shoulder pole, beat a gong
# or a pot (the noise that drives Nian off at the New Year), call out their wares or the watch, and eat.

HOE_T = 1.7


def clip_hoe(t):
    """Hoeing a field: both hands on the long handle, the right back by the hip and the left forward,
    the blade swung up over the right shoulder and brought down into the soil in front, drawn back
    towards the feet with a bend of the back, and lifted again; the left foot forward."""
    k = (t % HOE_T) / HOE_T
    p = clip_idle(0.0)
    up = smooth(0.0, 0.42, k) * (1.0 - smooth(0.5, 0.62, k))
    down = smooth(0.5, 0.62, k) * (1.0 - smooth(0.86, 1.0, k))
    pull = smooth(0.64, 0.84, k) * (1.0 - smooth(0.88, 1.0, k))
    p["upper_arm.R"] = ((-0.45 - 1.65 * up + 0.25 * down, 0.0, -0.3 + 0.12 * up), (0, 0, 0))
    p["forearm.R"] = ((-0.95 - 0.85 * up + 0.35 * pull, 0.3, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.25 - 0.35 * up, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.75 - 1.45 * up + 0.2 * down, 0.0, -0.18), (0, 0, 0))
    p["forearm.L"] = ((-0.55 - 0.55 * up + 0.3 * pull, -0.3, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.15, 0.0, 0.0), (0, 0, 0))
    _hands(p, 1.1, 1.1)
    p["hips"] = ((0.1 + 0.12 * down, 0.0, 0.0), (0.0, -0.06 - 0.04 * down, -0.02 * down))
    _add(p, "spine", 0.1 - 0.12 * up + 0.22 * down + 0.08 * pull)
    _add(p, "chest", 0.06 - 0.12 * up + 0.16 * down)
    _add(p, "head", 0.22 + 0.1 * down)
    _add(p, "sleeve.R", 0.5 + 0.6 * up)
    _add(p, "sleeve.L", 0.4 + 0.5 * up)
    _add(p, "thigh.L", -0.25)
    _add(p, "shin.L", 0.3)
    _add(p, "foot.L", -0.05)
    _add(p, "thigh.R", 0.12)
    _add(p, "shin.R", 0.25)
    _add(p, "foot.R", -0.35)
    return p


CHOP_T = 1.5


def clip_chop(t):
    """Chopping firewood: both hands together at the end of the axe handle, raised straight up over
    the head, brought down onto the log on the block with a bend of the knees and the back, a beat,
    and up again."""
    k = (t % CHOP_T) / CHOP_T
    p = clip_idle(0.0)
    up = smooth(0.05, 0.5, k) * (1.0 - smooth(0.58, 0.66, k))
    blow = smooth(0.58, 0.66, k) * (1.0 - smooth(0.84, 1.0, k))
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.85 - 2.0 * up + 0.3 * blow, 0.0, -0.22 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.45 - 0.55 * up, -0.35 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.2 - 0.3 * up + 0.3 * blow, 0.0, 0.3 * s), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.4 + 0.7 * up)
    _hands(p, 1.1, 1.1)
    p["hips"] = ((0.06 + 0.12 * blow, 0.0, 0.0), (0.0, -0.05 - 0.07 * blow, 0.0))
    _add(p, "spine", 0.04 - 0.12 * up + 0.26 * blow)
    _add(p, "chest", -0.1 * up + 0.16 * blow)
    _add(p, "head", 0.12 + 0.18 * blow - 0.12 * up)
    for sd in ("L", "R"):
        _add(p, "thigh." + sd, -0.14 - 0.12 * blow)
        _add(p, "shin." + sd, 0.26 + 0.24 * blow)
        _add(p, "foot." + sd, -0.12 - 0.12 * blow)
    return p


CARRY_T = WALK_T


def clip_carry(t):
    """Walking under a shoulder pole (a porter's load, two buckets of water, baskets of greens): the
    right hand steadies the pole on the right shoulder, the left arm swings, the head tips away
    from the pole and the body leans a little into the load."""
    p = clip_walk(t)
    p["upper_arm.R"] = ((-0.35, 0.0, -0.95), (0, 0, 0))
    p["forearm.R"] = ((-1.95, -0.25, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.3, 0.0, 0.25), (0, 0, 0))
    _hands(p, 0.42, 1.0)
    _add(p, "chest", 0.05, 0.0, 0.05)
    _add(p, "spine", 0.04, 0.0, 0.0)
    _add(p, "head", 0.0, 0.0, 0.08)
    _add(p, "sleeve.R", 0.6)
    return p


BANG_T = 1.0


def clip_bang(t):
    """Beating a gong or a pot (the noise that drives Nian off at the New Year, the watchman's gong):
    the left hand holds it up before the chest, the right beats it with a stick twice a beat, with a
    little bounce and a shout."""
    k = (t % BANG_T) / BANG_T
    p = clip_idle(t * IDLE_T / BANG_T * 0.25)
    lift = abs(math.sin(k * math.pi * 2.0))
    p["upper_arm.L"] = ((-0.95, 0.0, -0.12), (0, 0, 0))
    p["forearm.L"] = ((-1.1, -0.5, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.1, 0.0, 0.6), (0, 0, 0))
    p["upper_arm.R"] = ((-0.6 - 0.5 * lift, 0.0, -0.05), (0, 0, 0))
    p["forearm.R"] = ((-1.2 - 0.6 * lift, 0.4, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.3 - 0.5 * lift, 0.0, 0.0), (0, 0, 0))
    _hands(p, 1.0, 1.1)
    p["hips"] = ((0.0, 0.0, 0.0), (0.0, 0.012 * (1.0 - lift), 0.0))
    _add(p, "head", -0.1, 0.0, 0.0)
    _add(p, "sleeve.L", 0.5)
    _add(p, "sleeve.R", 0.5 + 0.3 * lift)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.8 * lift, 1))
    return p


CALL_T = 2.4


def clip_call(t):
    """Calling out (a hawker's wares, the watchman's hour, a name across the street): the right hand
    cupped at the mouth, the chest lifting and the head tipping back for the shout, and down."""
    k = t / CALL_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.2, 0.8, 1.0)
    shout = _hold(k, 0.25, 0.35, 0.65, 0.75)
    p["upper_arm.R"] = ((-0.7 * e, 0.0, -0.45 * e - 0.035 * (1 - e)), (0, 0, 0))
    p["forearm.R"] = ((-2.1 * e - 0.24 * (1 - e), 0.4 * e, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.2 * e, 0.0, 0.5 * e), (0, 0, 0))
    _hands(p, 0.4, 0.3 + 0.4 * e)
    _add(p, "chest", -0.08 * shout)
    _add(p, "head", -0.22 * shout, 0.0, 0.0)
    _add(p, "sleeve.R", 0.8 * e)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 1.0 * shout, 1))
    return p


EAT_T = 2.0


def clip_eat(t):
    """Eating at a table: seated, the left hand holds the bowl up near the chin, the right brings the
    chopsticks to the mouth and back down to the bowl, a chew, and again."""
    w = 2 * math.pi / EAT_T
    k = (t % EAT_T) / EAT_T
    p = clip_idle(0.0)
    br = _seated(p, t, w * 0.25)
    bite = _hold(k, 0.1, 0.35, 0.5, 0.75)
    p["upper_arm.L"] = ((-0.55, 0.0, -0.28), (0, 0, 0))
    p["forearm.L"] = ((-1.6, -0.45, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.2, 0.0, 0.3), (0, 0, 0))
    p["upper_arm.R"] = ((-0.5 - 0.25 * bite, 0.0, 0.25), (0, 0, 0))
    p["forearm.R"] = ((-1.5 - 0.6 * bite, 0.4, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.1 - 0.2 * bite, 0.0, 0.1), (0, 0, 0))
    _hands(p, 0.8, 0.9)
    _add(p, "head", 0.12 - 0.06 * bite)
    _add(p, "sleeve.L", 0.5)
    _add(p, "sleeve.R", 0.5 + 0.3 * bite)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.4 * math.sin(k * math.pi * 6.0) ** 2 * (1.0 - bite), 1))
    _secondary(p, t, False, False, (-1.5, -1.5), br, (0.4, 0.4))
    return p


# ---------------------------------------------------------------- the Hollow Hills release (Part XX)
# What is done under the ground and in the bigger houses: swinging a pick at an ore vein, digging,
# washing in an underground stream, tracing an old painting on the rock, opening a chest, combing at a
# mirror, pounding in a mortar, turning a spinning wheel, working an abacus, stretching at a window,
# knocking on a wall and listening, pouring from a jar, peering into a crack, hanging something up,
# rocking a cradle, carving, panning gravel, sidling through a squeeze and going bent under a low roof.

MINE_T = 1.6


def clip_mine(t):
    """Swinging a pick at a rock face: both hands on the haft, drawn back over the right shoulder with
    a turn of the hips, swung round and into the rock in front at chest height, a jolt, and back."""
    k = (t % MINE_T) / MINE_T
    p = clip_idle(0.0)
    back = smooth(0.0, 0.42, k) * (1.0 - smooth(0.5, 0.6, k))
    blow = smooth(0.5, 0.6, k) * (1.0 - smooth(0.82, 1.0, k))
    jolt = _hold(k, 0.58, 0.62, 0.66, 0.74)
    p["upper_arm.R"] = ((-0.9 - 1.3 * back - 0.25 * blow, 0.0, -0.35 - 0.3 * back + 0.35 * blow), (0, 0, 0))
    p["forearm.R"] = ((-0.9 - 0.9 * back + 0.5 * blow, 0.25, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.2 - 0.4 * back + 0.3 * blow, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-1.0 - 0.9 * back - 0.3 * blow, 0.0, -0.45 - 0.35 * back + 0.2 * blow), (0, 0, 0))
    p["forearm.L"] = ((-0.7 - 0.8 * back + 0.4 * blow, -0.3, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.15, 0.0, 0.0), (0, 0, 0))
    _hands(p, 1.1, 1.1)
    p["hips"] = ((0.08 + 0.08 * blow, -0.35 * back + 0.2 * blow, 0.0), (0.0, -0.07 - 0.03 * blow + 0.012 * jolt, 0.0))
    _add(p, "spine", 0.06 + 0.14 * blow - 0.06 * back, -0.2 * back + 0.12 * blow)
    _add(p, "chest", 0.04 + 0.1 * blow - 0.08 * back, -0.22 * back + 0.14 * blow)
    _add(p, "head", 0.1 + 0.08 * blow, 0.3 * back - 0.1 * blow, 0.03 * jolt)
    _add(p, "sleeve.R", 0.5 + 0.6 * back)
    _add(p, "sleeve.L", 0.5 + 0.4 * back)
    _add(p, "thigh.L", -0.3)
    _add(p, "shin.L", 0.36)
    _add(p, "foot.L", -0.06)
    _add(p, "thigh.R", 0.14)
    _add(p, "shin.R", 0.2)
    _add(p, "foot.R", -0.3)
    return p


DIG_T = 2.2


def clip_dig(t):
    """Digging: the spade driven down in front with both hands and the weight of the right foot,
    levered back with a bend of the knees, and the load swung up and away to the left."""
    k = (t % DIG_T) / DIG_T
    p = clip_idle(0.0)
    drive = _hold(k, 0.0, 0.2, 0.3, 0.42)
    lever = _hold(k, 0.3, 0.44, 0.5, 0.62)
    throw = _hold(k, 0.52, 0.68, 0.78, 0.96)
    p["upper_arm.R"] = ((-0.55 - 0.35 * drive - 0.3 * lever - 0.85 * throw, 0.0, -0.2 + 0.5 * throw), (0, 0, 0))
    p["forearm.R"] = ((-0.75 + 0.3 * drive - 0.5 * lever - 0.4 * throw, 0.3, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.2, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.7 - 0.25 * drive - 0.15 * lever - 0.9 * throw, 0.0, -0.15 + 0.55 * throw), (0, 0, 0))
    p["forearm.L"] = ((-0.35 + 0.15 * drive - 0.6 * lever - 0.3 * throw, -0.3, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.1, 0.0, 0.0), (0, 0, 0))
    _hands(p, 1.1, 1.1)
    p["hips"] = ((0.14 + 0.16 * drive + 0.05 * lever - 0.08 * throw, 0.35 * throw, 0.0), (0.0, -0.06 - 0.1 * lever - 0.04 * drive, 0.0))
    _add(p, "spine", 0.14 + 0.2 * drive - 0.1 * throw, 0.2 * throw)
    _add(p, "chest", 0.1 + 0.14 * drive - 0.1 * throw, 0.25 * throw)
    _add(p, "head", 0.25 + 0.1 * drive - 0.25 * throw, 0.3 * throw)
    _add(p, "sleeve.R", 0.5 + 0.5 * throw)
    _add(p, "sleeve.L", 0.4 + 0.5 * throw)
    _add(p, "thigh.R", -0.5 * drive - 0.2 - 0.25 * lever)
    _add(p, "shin.R", 0.75 * drive + 0.3 + 0.45 * lever)
    _add(p, "foot.R", -0.2 * drive - 0.1 - 0.2 * lever)
    _add(p, "thigh.L", 0.1 - 0.3 * lever)
    _add(p, "shin.L", 0.12 + 0.5 * lever)
    _add(p, "foot.L", -0.2 - 0.2 * lever)
    return p


WASH_T = 3.2


def clip_wash(t):
    """Washing at running water: down on one knee, both hands cupped into the stream, brought up to
    the face twice, the head shaken once, and up."""
    k = t / WASH_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.18, 0.84, 1.0)
    dip = _hold(k, 0.14, 0.24, 0.3, 0.38) + _hold(k, 0.46, 0.54, 0.58, 0.66)
    face = _hold(k, 0.3, 0.4, 0.44, 0.52) + _hold(k, 0.6, 0.7, 0.76, 0.86)
    _crouch(p, e)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.75 * dip - 0.95 * face - 0.2 * e, 0.0, -0.3 * s * (dip + face)), (0, 0, 0))
        p["forearm." + sd] = ((-0.35 * dip - 1.95 * face - 0.2, -0.3 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.3 * dip - 0.2 * face, 0.0, 0.3 * s * e), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.7 * face)
    _hands(p, 0.25, 0.25, 0.05)
    _add(p, "spine", 0.3 * dip + 0.08 * face)
    _add(p, "chest", 0.28 * dip + 0.06 * face)
    shake = math.sin(k * math.pi * 36.0) * _hold(k, 0.78, 0.8, 0.86, 0.9)
    _add(p, "head", 0.35 * dip + 0.3 * face, 0.22 * shake, 0.0)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.9 * min(1.0, face), 1))
    return p


TRACE_T = 4.0


def clip_trace(t):
    """Following an old painting on a rock wall with the fingertips: the left hand holds the light up
    and to the side, the right moves along the lines in slow arcs at the height of the eyes, the head
    following the hand."""
    w = 2 * math.pi / TRACE_T
    p = clip_idle(t)
    a = math.sin(t * w)
    c = math.cos(t * w * 2)
    p["upper_arm.R"] = ((-1.45 + 0.22 * c, 0.0, 0.1 + 0.3 * a), (0, 0, 0))
    p["forearm.R"] = ((-0.55 - 0.18 * c, 0.0, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.35, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-1.2, 0.0, 0.55), (0, 0, 0))
    p["forearm.L"] = ((-1.1, -0.3, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.2, 0.0, 0.0), (0, 0, 0))
    _hands(p, 1.0, 0.1, 0.3)
    _add(p, "sleeve.R", 1.0)
    _add(p, "sleeve.L", 0.9)
    _add(p, "chest", -0.03, 0.08 * a)
    p["head"] = ((-0.14 + 0.08 * c, -0.2 * a, 0.0), (0, 0, 0))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.3 * max(0.0, c), 1))
    return p


CHEST_T = 3.0


def clip_open_chest(t):
    """Opening a chest: down on one knee before it, both hands under the lid and up with it, a look
    inside, the right hand going in and coming out with something, and the lid let down."""
    k = t / CHEST_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.16, 0.86, 1.0)
    lid = _hold(k, 0.16, 0.34, 0.74, 0.88)
    take = _hold(k, 0.42, 0.52, 0.58, 0.7)
    _crouch(p, e)
    p["upper_arm.L"] = ((-0.7 * e - 0.75 * lid, 0.0, -0.1 * e), (0, 0, 0))
    p["forearm.L"] = ((-0.7 * e - 0.4 * lid - 0.2, -0.3 * e, 0.0), (0, 0, 0))
    p["hand.L"] = ((-0.5 * lid, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.R"] = ((-0.7 * e - 0.75 * lid * (1 - take) - 0.2 * take, 0.0, 0.1 * e), (0, 0, 0))
    p["forearm.R"] = ((-0.7 * e - 0.4 * lid * (1 - take) + 0.3 * take - 0.2, 0.3 * e, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.5 * lid * (1 - take) + 0.4 * take, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.6, 0.5 + 0.6 * smooth(0.5, 0.56, k), 0.2)
    _add(p, "spine", 0.12 * e + 0.2 * take)
    _add(p, "chest", 0.1 * e + 0.15 * take)
    _add(p, "head", 0.28 * e + 0.12 * take - 0.2 * _hold(k, 0.66, 0.74, 0.8, 0.88))
    _add(p, "sleeve.L", 0.5 * lid)
    _add(p, "sleeve.R", 0.5 * lid)
    return p


COMB_T = 3.0


def clip_comb(t):
    """At a mirror: leaning a little towards it with the head tipped, the right hand drawing a comb
    down through the hair by the temple three times, the left holding the hair out of the way."""
    k = (t % COMB_T) / COMB_T
    p = clip_idle(t)
    st = (k * 3.0) % 1.0
    down = smooth(0.1, 0.8, st)
    p["upper_arm.R"] = ((-1.5 + 0.5 * down, 0.0, -0.75), (0, 0, 0))
    p["forearm.R"] = ((-2.0 + 0.35 * down, 0.5, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.1, 0.0, 0.4), (0, 0, 0))
    p["upper_arm.L"] = ((-0.9, 0.0, 0.5), (0, 0, 0))
    p["forearm.L"] = ((-2.0, -0.5, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.0, 0.0, -0.4), (0, 0, 0))
    _hands(p, 0.7, 1.0)
    _add(p, "sleeve.R", 1.1)
    _add(p, "sleeve.L", 0.9)
    _add(p, "spine", 0.06)
    p["head"] = ((0.06, 0.12, 0.16 - 0.04 * down), (0, 0, 0))
    return p


POUND_T = 1.0


def clip_pound(t):
    """Pounding in a mortar: both hands round the long pestle before the chest, lifted to the chin and
    driven down, with a dip of the knees on the stroke."""
    k = (t % POUND_T) / POUND_T
    p = clip_idle(0.0)
    up = smooth(0.0, 0.5, k) * (1.0 - smooth(0.56, 0.68, k))
    hit = _hold(k, 0.6, 0.68, 0.74, 0.96)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.6 - 0.55 * up + 0.1 * hit, 0.0, -0.3 * s), (0, 0, 0))
        p["forearm." + sd] = ((-1.1 - 0.75 * up + 0.3 * hit, -0.4 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.1 + 0.2 * hit, 0.0, 0.35 * s), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.5 + 0.4 * up)
        _add(p, "thigh." + sd, -0.1 - 0.1 * hit)
        _add(p, "shin." + sd, 0.2 + 0.2 * hit)
        _add(p, "foot." + sd, -0.1 - 0.1 * hit)
    _hands(p, 1.1, 1.1)
    p["hips"] = ((0.08 + 0.05 * hit, 0.0, 0.0), (0.0, -0.04 - 0.05 * hit, 0.0))
    _add(p, "spine", 0.08 + 0.08 * hit - 0.04 * up)
    _add(p, "head", 0.24)
    return p


SPIN_T = 1.6


def clip_spin(t):
    """At the spinning wheel, seated: the right hand goes round with the wheel's crank, the left draws
    the thread out and back at arm's length, the eyes on the thread."""
    w = 2 * math.pi / SPIN_T
    p = clip_idle(0.0)
    _seated(p, t, w / 2, drop=0.46)
    a = t * w
    p["upper_arm.R"] = ((-0.75 + 0.22 * math.sin(a), 0.0, -0.35), (0, 0, 0))
    p["forearm.R"] = ((-0.9 + 0.3 * math.cos(a), 0.2, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.15 * math.sin(a), 0.0, 0.0), (0, 0, 0))
    draw = 0.5 + 0.5 * math.sin(a * 0.5)
    p["upper_arm.L"] = ((-0.6 - 0.5 * draw, 0.0, 0.25 + 0.55 * draw), (0, 0, 0))
    p["forearm.L"] = ((-1.2 + 0.7 * draw, -0.3, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.1, 0.0, -0.2), (0, 0, 0))
    _hands(p, 0.9, 0.9, 0.5)
    _add(p, "sleeve.R", 0.5)
    _add(p, "sleeve.L", 0.5 + 0.4 * draw)
    _add(p, "chest", 0.04, 0.1 * draw)
    p["head"] = ((0.14, 0.3 * draw, 0.0), (0, 0, 0))
    return p


COUNT_T = 2.4


def clip_count(t):
    """Working an abacus on a counter: bent a little over it, the left hand steadying the frame, the
    right flicking beads along a rod, moving to the next rod and flicking again; a nod at the sum."""
    k = (t % COUNT_T) / COUNT_T
    p = clip_idle(0.0)
    flick = math.sin(k * math.pi * 16.0)
    along = math.sin(k * math.pi * 2.0)
    p["upper_arm.R"] = ((-0.7, 0.0, 0.05 + 0.2 * along), (0, 0, 0))
    p["forearm.R"] = ((-0.95 + 0.05 * flick, 0.25, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.25 + 0.14 * flick, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.6, 0.0, -0.2), (0, 0, 0))
    p["forearm.L"] = ((-0.9, -0.3, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.3, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.25, 0.3 + 0.3 * max(0.0, flick), 0.2)
    p["hips"] = ((0.1, 0.0, 0.0), (0.0, -0.02, 0.0))
    _add(p, "spine", 0.1)
    _add(p, "chest", 0.08)
    _add(p, "sleeve.R", 0.5)
    _add(p, "sleeve.L", 0.5)
    p["head"] = ((0.3 + 0.1 * _hold(k, 0.86, 0.9, 0.94, 1.0), 0.12 * along, 0.0), (0, 0, 0))
    return p


STRETCH_T = 3.2


def clip_stretch(t):
    """Stretching: the fingers laced and pushed up over the head, up onto the toes, the back arched
    and the mouth wide in a yawn, then the arms let fall and the shoulders rolled."""
    k = t / STRETCH_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.3, 0.62, 0.82)
    roll = _hold(k, 0.78, 0.86, 0.9, 1.0)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-2.75 * e + 0.2 * roll, 0.0, 0.2 * s * e - 0.035 * s * (1 - e)), (0, 0, 0))
        p["forearm." + sd] = ((-0.35 * e - 0.22 * (1 - e), -0.3 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((-0.6 * e, 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 1.3 * e)
        _add(p, "foot." + sd, 0.35 * e)
        _add(p, "toe." + sd, -0.4 * e)
    _hands(p, 0.1 + 0.3 * (1 - e), 0.1 + 0.3 * (1 - e))
    p["hips"] = ((-0.03 * e, 0.0, 0.0), (0.0, 0.04 * e, 0.0))
    _add(p, "spine", -0.1 * e)
    _add(p, "chest", -0.14 * e + 0.05 * roll)
    _add(p, "head", -0.25 * e)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 1.6 * _hold(k, 0.2, 0.34, 0.5, 0.64), 1))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.9 * _hold(k, 0.22, 0.34, 0.54, 0.66), 1))
    return p


KNOCK_T = 2.8


def clip_knock(t):
    """Knocking and listening: three raps of the right knuckles on what stands in front, then the head
    turned and the ear laid close to it, quite still, and away."""
    k = t / KNOCK_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.12, 0.4, 0.5)
    rap = max(0.0, math.sin(k * math.pi * 16.0)) * _hold(k, 0.1, 0.14, 0.38, 0.42)
    ear = _hold(k, 0.44, 0.58, 0.86, 1.0)
    p["upper_arm.R"] = ((-1.15 * e - 0.4 * ear, 0.0, 0.1 * e), (0, 0, 0))
    p["forearm.R"] = ((-1.0 * e + 0.3 * rap - 0.9 * ear - 0.22 * (1 - e - ear), 0.0, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.2 * e - 0.3 * rap, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.9 * ear, 0.0, -0.2 * ear + 0.035), (0, 0, 0))
    p["forearm.L"] = ((-1.0 * ear - 0.2, 0.12, 0.0), (0, 0, 0))
    p["hand.L"] = ((-0.5 * ear, 0.2, 0.0), (0, 0, 0))
    _hands(p, 0.38 - 0.3 * ear, 0.4 + 0.7 * e)
    _add(p, "spine", 0.1 * ear)
    _add(p, "chest", 0.08 * ear, -0.3 * ear)
    _add(p, "head", 0.0, -0.75 * ear, 0.2 * ear)
    _add(p, "sleeve.R", 0.8 * e)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.5 * ear, 1))
    return p


POUR_T = 3.0


def clip_pour(t):
    """Pouring from a jar: taken up in both hands from before the knees, tipped slowly out in front
    at the height of the waist, righted, and set down."""
    k = t / POUR_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.2, 0.8, 1.0)
    tip = _hold(k, 0.26, 0.42, 0.62, 0.76)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.7 * e - 0.25 * tip * (1 if sd == "R" else 0.3), 0.0, -0.22 * s * e - 0.035 * s * (1 - e)), (0, 0, 0))
        p["forearm." + sd] = ((-0.95 * e - 0.22 * (1 - e) - 0.2 * tip * (1 if sd == "R" else -0.6), -0.3 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.1 * e, 0.0, (0.3 + 0.7 * tip) * e if sd == "R" else -0.3 * e - 0.3 * tip), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.5 * e)
    _hands(p, 0.7, 0.7, 0.3)
    dip = _hold(k, 0.0, 0.1, 0.14, 0.24) + _hold(k, 0.78, 0.88, 0.9, 1.0)
    p["hips"] = ((0.25 * dip, 0.0, 0.0), (0.0, -0.1 * dip, 0.0))
    _add(p, "spine", 0.2 * dip + 0.05 * tip)
    _add(p, "head", 0.22 * e + 0.1 * dip, 0.0, 0.06 * tip)
    return p


PEER_T = 3.2


def clip_peer(t):
    """Peering into a crack, a tube or a dark place: bent forward from the hips, the hands cupped
    either side of the eyes, the head turning a little as it looks; then straightening, blinking."""
    k = t / PEER_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.2, 0.78, 0.94)
    look = math.sin(k * math.pi * 4.0) * e
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-1.0 * e, 0.0, 0.5 * s * e - 0.035 * s * (1 - e)), (0, 0, 0))
        p["forearm." + sd] = ((-2.15 * e - 0.22 * (1 - e), -0.3 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.0, 0.0, -0.3 * s * e), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.9 * e)
        _add(p, "thigh." + sd, -0.2 * e)
        _add(p, "shin." + sd, 0.28 * e)
        _add(p, "foot." + sd, -0.08 * e)
    _hands(p, 0.6, 0.6, 0.2)
    p["hips"] = ((0.3 * e, 0.0, 0.0), (0.0, -0.05 * e, -0.05 * e))
    _add(p, "spine", 0.16 * e)
    _add(p, "chest", 0.1 * e)
    _add(p, "head", -0.3 * e, 0.12 * look, 0.0)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (2.7, 2.95)) * (1.0 - 0.3 * e), 1))
    return p


HANG_T = 3.0


def clip_hang(t):
    """Hanging something up: taken in both hands, lifted high in front, up on the toes to hook it over,
    the hands let go one after the other, a step back in the heels and a look up at it."""
    k = t / HANG_T
    p = clip_idle(0.0)
    up = _hold(k, 0.08, 0.36, 0.56, 0.74)
    lookup = _hold(k, 0.3, 0.4, 0.86, 1.0)
    for sd, s, late in (("L", 1, 0.0), ("R", -1, 0.06)):
        u = _hold(k, 0.08, 0.36, 0.56 + late, 0.74 + late)
        p["upper_arm." + sd] = ((-2.45 * u, 0.0, 0.1 * s * u - 0.035 * s * (1 - u)), (0, 0, 0))
        p["forearm." + sd] = ((-0.45 * u - 0.22 * (1 - u), -0.2 * s * u, 0.0), (0, 0, 0))
        p["hand." + sd] = ((-0.3 * u, 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 1.3 * u)
        _add(p, "foot." + sd, 0.4 * _hold(k, 0.3, 0.4, 0.5, 0.6))
        _add(p, "toe." + sd, -0.45 * _hold(k, 0.3, 0.4, 0.5, 0.6))
    _hands(p, 0.7 - 0.4 * smooth(0.56, 0.64, k), 0.7 - 0.4 * smooth(0.62, 0.7, k))
    p["hips"] = ((0.0, 0.0, 0.0), (0.0, 0.035 * _hold(k, 0.3, 0.4, 0.5, 0.6), 0.0))
    _add(p, "chest", -0.08 * up)
    _add(p, "head", -0.32 * lookup)
    return p


ROCK_T = 2.4


def clip_rock(t):
    """Rocking a cradle: bent over it with the left hand on the knee, the right on the rail pushing it
    away and letting it come back, the head on one side, humming."""
    w = 2 * math.pi / ROCK_T
    p = clip_idle(0.0)
    a = math.sin(t * w)
    p["hips"] = ((0.3, 0.0, 0.0), (0.0, -0.1, -0.04))
    for sd in ("L", "R"):
        _add(p, "thigh." + sd, -0.42)
        _add(p, "shin." + sd, 0.5)
        _add(p, "foot." + sd, -0.1)
    p["upper_arm.R"] = ((-0.75 - 0.14 * a, 0.0, -0.1), (0, 0, 0))
    p["forearm.R"] = ((-0.5 + 0.2 * a, 0.2, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.35, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.L"] = ((-0.3, 0.0, -0.1), (0, 0, 0))
    p["forearm.L"] = ((-0.6, -0.4, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.5, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.5, 0.7)
    _add(p, "spine", 0.14 + 0.02 * a)
    _add(p, "chest", 0.1)
    p["head"] = ((0.2, 0.0, 0.16 + 0.05 * a), (0, 0, 0))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.25 * (0.5 + 0.5 * math.sin(t * w * 2)), 1))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.55, 1))
    return p


CARVE_T = 1.8


def clip_carve(t):
    """Carving: the work held in the left hand before the chest, the right pushing a small blade along
    it in short strokes away from the body; the work turned, blown on, and the strokes go on."""
    k = (t % CARVE_T) / CARVE_T
    p = clip_idle(0.0)
    st = max(0.0, math.sin(k * math.pi * 8.0)) * (1.0 - smooth(0.7, 0.76, k))
    blow = _hold(k, 0.74, 0.82, 0.9, 1.0)
    p["upper_arm.L"] = ((-0.55 - 0.2 * blow, 0.0, -0.3), (0, 0, 0))
    p["forearm.L"] = ((-1.5 - 0.35 * blow, -0.35, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.1, 0.5 * blow, -0.3), (0, 0, 0))
    p["upper_arm.R"] = ((-0.5 - 0.1 * st, 0.0, 0.32), (0, 0, 0))
    p["forearm.R"] = ((-1.5 + 0.22 * st, 0.35, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.1 + 0.15 * st, 0.0, 0.3), (0, 0, 0))
    _hands(p, 0.8, 1.0, 0.4)
    _add(p, "sleeve.L", 0.6)
    _add(p, "sleeve.R", 0.6)
    _add(p, "chest", 0.05)
    p["head"] = ((0.34 - 0.12 * blow, -0.08, 0.0), (0, 0, 0))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1.0 - 0.3 * blow, 1.0 + 0.5 * blow, 1))
    return p


PAN_T = 2.4


def clip_pan(t):
    """Panning gravel at the water's edge: squatting on both heels with a shallow pan held out over
    the stream in both hands, swirled round and round and tipped, the eyes down for a glint."""
    w = 2 * math.pi / PAN_T
    p = clip_idle(0.0)
    a = t * w * 2
    p["hips"] = ((0.3, 0.0, 0.0), (0.0, -0.5, -0.1))
    for sd, s in (("L", 1), ("R", -1)):
        p["thigh." + sd] = ((-1.75, 0.0, 0.3 * s), (0, 0, 0))
        p["shin." + sd] = ((2.25, 0.0, 0.0), (0, 0, 0))
        p["foot." + sd] = ((-0.75, 0.0, 0.0), (0, 0, 0))
        p["upper_arm." + sd] = ((-0.95 + 0.07 * math.sin(a + s), 0.0, -0.22 * s + 0.07 * math.cos(a)), (0, 0, 0))
        p["forearm." + sd] = ((-0.55 + 0.07 * math.cos(a + s), -0.3 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.2, 0.0, 0.3 * s + 0.12 * math.sin(a)), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.5)
    _hands(p, 0.8, 0.8, 0.3)
    _add(p, "spine", 0.12)
    _add(p, "chest", 0.1, 0.0, 0.03 * math.sin(a))
    p["head"] = ((0.36, 0.05 * math.sin(a * 0.5), 0.0), (0, 0, 0))
    return p


SQUEEZE_T = 1.6


def clip_squeeze(t):
    """Sidling through a squeeze in the rock: the body turned side on with the back and the palms flat
    to the wall, the breath held, the leading foot feeling out and the other drawn up to it."""
    w = 2 * math.pi / SQUEEZE_T
    p = clip_idle(0.0)
    a = math.sin(t * w)
    step = max(0.0, a)
    draw = max(0.0, -a)
    p["root"] = ((0, 1.35, 0), (0, 0, 0))
    p["hips"] = ((0.0, 0.0, 0.0), (0.0, -0.04 - 0.02 * abs(a), 0.0))
    p["thigh.L"] = ((0.0, 0.0, 0.3 * step), (0, 0, 0))
    p["shin.L"] = ((0.12 * step, 0.0, 0.0), (0, 0, 0))
    p["foot.L"] = ((-0.05, 0.0, -0.3 * step), (0, 0, 0))
    p["thigh.R"] = ((0.0, 0.0, 0.22 * step - 0.05 * draw), (0, 0, 0))
    p["shin.R"] = ((0.3 * draw, 0.0, 0.0), (0, 0, 0))
    p["foot.R"] = ((-0.2 * draw, 0.0, 0.0), (0, 0, 0))
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((0.12, 0.0, 0.5 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.12, 0.6 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((-0.2, 0.0, 0.0), (0, 0, 0))
    _hands(p, 0.05, 0.05, 0.05)
    _add(p, "chest", -0.05)
    p["head"] = ((-0.03, -1.0, 0.0), (0, 0, 0))
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (0.8, 0.8, 1))
    return p


DUCK_T = 1.3


def clip_duck(t):
    """Going bent under a low roof: knees deep, the back and the head down and forward, one hand up
    before the brow to find the rock first, short quick steps."""
    w = 2 * math.pi / (DUCK_T / 2)
    p = clip_idle(0.0)
    a = math.sin(t * w)
    p["hips"] = ((0.45, 0.06 * a, 0.0), (0.0, -0.24 + 0.012 * abs(a), 0.0))
    for sd, sg in (("L", 1.0), ("R", -1.0)):
        sw = a * sg
        p["thigh." + sd] = ((-0.95 - 0.38 * sw, 0.0, 0.0), (0, 0, 0))
        p["shin." + sd] = ((1.15 + 0.3 * max(0.0, sw), 0.0, 0.0), (0, 0, 0))
        p["foot." + sd] = ((-0.6 + 0.1 * sw, 0.0, 0.0), (0, 0, 0))
    p["upper_arm.R"] = ((-1.5, 0.0, 0.25), (0, 0, 0))
    p["forearm.R"] = ((-1.5, -0.2, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.5, 0.0, -0.3), (0, 0, 0))
    p["upper_arm.L"] = ((-0.2 + 0.2 * a, 0.0, 0.12), (0, 0, 0))
    p["forearm.L"] = ((-0.7, 0.12, 0.0), (0, 0, 0))
    _hands(p, 0.4, 0.15)
    _add(p, "spine", 0.2)
    _add(p, "chest", 0.16)
    p["head"] = ((-0.42, 0.0, 0.0), (0, 0, 0))
    _secondary(p, t, True, False, (0.3 * a, -0.3 * a), a, (0.3, 1.0))
    return p


# ---- gestures everybody has, for the conversations of Part XX (Data.EMOTES in the game)
SHRUG_T = 1.4


def clip_shrug(t):
    """A shrug: both shoulders up, the palms turned out at the hips, the head on one side, and down."""
    k = t / SHRUG_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.25, 0.6, 1.0)
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.12 * e, 0.0, 0.3 * s * e + 0.035 * s * (1 - e) * (1 if sd == "L" else 1)), (0.0, 0.022 * e, 0.0))
        p["forearm." + sd] = ((-0.75 * e - 0.22 * (1 - e), 0.9 * s * e + 0.12 * s * (1 - e), 0.0), (0, 0, 0))
        p["hand." + sd] = ((-0.35 * e, 0.2 * s, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.4 * e)
    _hands(p, 0.38 - 0.3 * e, 0.4 - 0.3 * e, 0.1)
    _add(p, "chest", -0.03 * e)
    _add(p, "head", 0.0, 0.0, 0.14 * e)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.12 * e, 1))
    return p


CHEER_T = 1.6


def clip_cheer(t):
    """A cheer: both fists thrown up over the head twice with a spring off the toes, the mouth wide."""
    k = t / CHEER_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.16, 0.74, 1.0)
    pump = abs(math.sin(k * math.pi * 2.0)) * e
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-1.5 * e - 1.0 * pump, 0.0, 0.3 * s * e - 0.035 * s * (1 - e)), (0, 0, 0))
        p["forearm." + sd] = ((-1.3 * e + 0.9 * pump - 0.22 * (1 - e), 0.0, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.0, 0.0, 0.0), (0, 0, 0))
        _add(p, "sleeve." + sd, 1.2 * e)
        _add(p, "foot." + sd, 0.3 * pump)
        _add(p, "toe." + sd, -0.3 * pump)
    _hands(p, 0.38 + 0.7 * e, 0.4 + 0.7 * e)
    p["hips"] = ((0.0, 0.0, 0.0), (0.0, 0.04 * pump, 0.0))
    _add(p, "chest", -0.08 * pump)
    _add(p, "head", -0.12 * e)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 + 0.9 * e, 1))
    return p


BECKON_T = 1.6


def clip_beckon(t):
    """Come here: the right arm out in front with the palm down, the fingers and the hand scooping
    towards the body twice (the way it is done in the east), a small nod with it."""
    k = t / BECKON_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.2, 0.78, 1.0)
    sc = max(0.0, math.sin(k * math.pi * 5.0 - 0.6)) * e
    p["upper_arm.R"] = ((-1.05 * e, 0.0, -0.12 * e - 0.035 * (1 - e)), (0, 0, 0))
    p["forearm.R"] = ((-0.5 * e - 0.25 * sc - 0.24 * (1 - e), -0.12, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.75 * sc + 0.1 * e, -0.2 * (1 - e), 0.0), (0, 0, 0))
    _hands(p, 0.38, 0.1 + 0.9 * sc, 0.2)
    _add(p, "sleeve.R", 0.8 * e)
    _add(p, "head", 0.08 * sc, 0.0, 0.0)
    _add(p, "chest", 0.0, 0.06 * e)
    return p


REFUSE_T = 1.6


def clip_refuse(t):
    """No, and no further: the right hand up before the chest with the palm out, the head turned away
    from it and the weight going back onto the heels."""
    k = t / REFUSE_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.2, 0.72, 1.0)
    p["upper_arm.R"] = ((-0.95 * e, 0.0, 0.1 * e - 0.035 * (1 - e)), (0, 0, 0))
    p["forearm.R"] = ((-1.25 * e - 0.24 * (1 - e), 0.0, 0.0), (0, 0, 0))
    p["hand.R"] = ((-0.85 * e, -0.2 * (1 - e), 0.0), (0, 0, 0))
    _hands(p, 0.38, 0.4 - 0.36 * e, 0.1)
    _add(p, "sleeve.R", 0.9 * e)
    p["hips"] = ((-0.04 * e, 0.0, 0.0), (0.0, 0.0, -0.025 * e))
    _add(p, "chest", -0.05 * e, 0.14 * e)
    _add(p, "head", 0.05 * e, 0.42 * e, 0.0)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1.0 - 0.45 * e, 1))
    return p


SHIVER_T = 1.8


def clip_shiver(t):
    """Cold, or afraid of the dark: the arms hugged across the chest, the shoulders up round the ears
    and the whole body shaking, the knees a little bent."""
    k = t / SHIVER_T
    p = clip_idle(0.0)
    e = _hold(k, 0.0, 0.2, 0.8, 1.0)
    sh = math.sin(k * math.pi * 30.0) * e
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.55 * e, 0.15 * s * e, -0.5 * s * e + 0.035 * s * (1 - e)), (0.0, 0.016 * e, 0.0))
        p["forearm." + sd] = ((-1.85 * e - 0.22 * (1 - e), -0.4 * s * e, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.2 * e, 0.0, 0.3 * s * e), (0, 0, 0))
        _add(p, "sleeve." + sd, 0.5 * e)
        _add(p, "thigh." + sd, -0.14 * e)
        _add(p, "shin." + sd, 0.26 * e)
        _add(p, "foot." + sd, -0.12 * e)
    _hands(p, 0.8, 0.8)
    p["hips"] = ((0.05 * e, 0.012 * sh, 0.0), (0.004 * sh, -0.03 * e, 0.0))
    _add(p, "spine", 0.08 * e, 0.015 * sh)
    _add(p, "chest", 0.08 * e, -0.015 * sh)
    _add(p, "head", 0.14 * e, 0.03 * sh, 0.0)
    p["mouth"] = ((0, 0, 0), (0, 0, 0), (0.85, 1.0 - 0.2 * e, 1))
    return p


# the five gestures of the Hollow Hills release belong to everybody
CLIPS.update({
    "shrug": (SHRUG_T, lambda t: _stow(clip_shrug(t))),
    "cheer": (CHEER_T, lambda t: _stow(clip_cheer(t))),
    "beckon": (BECKON_T, lambda t: _stow(clip_beckon(t))),
    "refuse": (REFUSE_T, lambda t: _stow(clip_refuse(t))),
    "shiver": (SHIVER_T, lambda t: _stow(clip_shiver(t))),
})


def _stowing(fn):
    return lambda t: _stow(fn(t))


## what the hero and his companion do with the world's things, on top of the twenty-one clips
INTERACT = {
    "sit_bench": (SITB_T, clip_sit_bench),
    "doze": (DOZE_T, clip_doze),
    "drink": (DRINK_T, clip_drink),
    "strike": (STRIKE_T, clip_strike),
    "read": (READ_T, clip_read),
    "play_qin": (QIN_T, clip_play_qin),
    "meditate": (MEDITATE_T, clip_meditate),
    "fish": (FISH_T, clip_fish),
    "pray": (PRAY_T, clip_pray),
    "gather": (GATHER_T, clip_gather),
    "warm": (WARM_T, clip_warm),
    "stir": (STIR_T, clip_stir),
    "hammer": (HAMMER_T, clip_hammer),
    "sweep": (SWEEP_T, clip_sweep),
    "weave": (WEAVE_T, clip_weave),
    "lift": (LIFT_T, clip_lift),
    "toss": (TOSS_T, clip_toss),
    "touch": (TOUCH_T, clip_touch),
    # the Lotus release (Part XV): more things to do, and things done side by side
    "play_flute": (FLUTE_T, clip_play_flute),
    "dance": (DANCE_T, clip_dance),
    "kite": (KITE_T, clip_kite),
    "stargaze": (STAR_T, clip_stargaze),
    "release": (RELEASE_T, clip_release),
    "float_lantern": (FLOAT_T, clip_float_lantern),
    "write": (WRITE_T, clip_write),
    "archery": (ARCHERY_T, clip_archery),
    "soak": (SOAK_T, clip_soak),
    "push": (PUSH_T, clip_push),
    "climb": (CLIMB_T, clip_climb),
    "gaze": (GAZE_T, clip_gaze),
    "clap": (CLAP_T, clip_clap),
    # the Living Land release: the work of the towns (scripts/folk.gd plays these on everybody)
    "hoe": (HOE_T, clip_hoe),
    "chop": (CHOP_T, clip_chop),
    "carry": (CARRY_T, clip_carry),
    "bang": (BANG_T, clip_bang),
    "call": (CALL_T, clip_call),
    "eat": (EAT_T, clip_eat),
    # the Hollow Hills release (Part XX): what is done under the ground and in the bigger houses
    "mine": (MINE_T, clip_mine),
    "dig": (DIG_T, clip_dig),
    "wash": (WASH_T, clip_wash),
    "trace": (TRACE_T, clip_trace),
    "open_chest": (CHEST_T, clip_open_chest),
    "comb": (COMB_T, clip_comb),
    "pound": (POUND_T, clip_pound),
    "spin": (SPIN_T, clip_spin),
    "count": (COUNT_T, clip_count),
    "stretch": (STRETCH_T, clip_stretch),
    "knock": (KNOCK_T, clip_knock),
    "pour": (POUR_T, clip_pour),
    "peer": (PEER_T, clip_peer),
    "hang": (HANG_T, clip_hang),
    "rock": (ROCK_T, clip_rock),
    "carve": (CARVE_T, clip_carve),
    "pan": (PAN_T, clip_pan),
    "squeeze": (SQUEEZE_T, clip_squeeze),
    "duck": (DUCK_T, clip_duck),
}
INTERACT = {nm: (secs, _stowing(fn)) for nm, (secs, fn) in INTERACT.items()}
# the sword form on the stage is the one thing done with the blade out
INTERACT["sword_dance"] = (SWORD_T, clip_sword_dance)


# ---------------------------------------------------------------- riding (mounts and vehicles)
# The party rides (scripts/fashion.gd RIDES): astride a horse, a qilin or a tiger ("ride" on the move,
# "ride_idle" standing still), or standing on a flying sword, a cloud or a sky-barque ("ride_stand").
# The hips stay at their standing height (HIP_Y): the game stands the model so they meet the saddle,
# or its feet on the deck.  Hands are busy with the reins (or a sword-seal), so the blade is put away.

RIDE_T = 0.62          # one bounding stride of the horse's gallop (art/mounts/horse.py)
RIDE_IDLE_T = 4.0
RIDE_STAND_T = 3.0


def _astride(p, bob=0.0, lean=0.1):
    """Sitting astride a saddle: thighs forward and wide round the barrel, knees bent, heels down in
    the stirrups, the back upright with a little forward lean."""
    p["root"] = ((0, 0, 0), (0, 0, 0))
    p["hips"] = ((0.05, 0.0, 0.0), (0.0, -0.04 + bob, -0.04))
    for sd, s in (("L", 1), ("R", -1)):
        p["thigh." + sd] = ((-1.1, 0.0, 0.5 * s), (0, 0, 0))
        p["shin." + sd] = ((1.25, 0.0, -0.12 * s), (0, 0, 0))
        p["foot." + sd] = ((-0.2, 0.0, 0.0), (0, 0, 0))
        p["toe." + sd] = ((0.1, 0.0, 0.0), (0, 0, 0))
    p["spine"] = ((lean, 0.0, 0.0), (0, 0, 0))
    p["chest"] = ((0.05, 0.0, 0.0), (0, 0, 0))
    p["neck"] = ((-0.04, 0.0, 0.0), (0, 0, 0))


def _reins(p, k=1.0, br=0.0):
    """Both hands forward over the pommel, holding the reins."""
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-0.55 * k - br * 0.01, 0.0, -0.08 * s), (0, 0, 0))
        p["forearm." + sd] = ((-1.0 * k, 0.28 * s, 0.0), (0, 0, 0))
        p["hand." + sd] = ((0.2, 0.15 * s, 0.0), (0, 0, 0))
    _hands(p, 0.95, 0.95, 0.35)


def clip_ride(t):
    """Riding at the gallop: the rider sits deep and moves with the horse, one bob a stride, leaning
    into the run with the reins in both hands; the cape, sleeves and hair stream back."""
    ph = t * 2 * math.pi / RIDE_T
    s = math.sin(ph)
    p = {}
    _astride(p, 0.028 * s, 0.16 + 0.03 * math.sin(ph - 0.6))
    _reins(p, 1.0)
    _add(p, "forearm.L", -0.12 * s, 0.0, 0.0)
    _add(p, "forearm.R", -0.12 * s, 0.0, 0.0)
    p["head"] = ((-0.12 - 0.04 * s, 0.0, 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 1, 1))
    lag = math.sin(ph - 0.9)
    p["robe_f"] = ((-1.0, 0, 0), (0, 0, 0))
    p["robe_b"] = ((0.7 + 0.12 * abs(lag), 0, 0), (0, 0, 0))
    p["robe_l"] = ((-0.7, 0, -0.55), (0, 0, 0))
    p["robe_r"] = ((-0.7, 0, 0.55), (0, 0, 0))
    p["cape"] = ((1.0 + 0.12 * math.sin(2 * ph - 0.8), 0.04 * lag, 0), (0, 0, 0))
    p["cape2"] = ((0.3 + 0.14 * math.sin(2 * ph - 1.6), 0, 0.06 * lag), (0, 0, 0))
    p["cape3"] = ((0.2 + 0.12 * math.sin(2 * ph - 2.4), 0, 0.08 * lag), (0, 0, 0))
    p["hair_tail"] = ((0.7 + 0.1 * math.sin(2 * ph - 0.8), 0, 0.1 * lag), (0, 0, 0))
    p["hair_tail2"] = ((0.35 + 0.12 * math.sin(2 * ph - 1.7), 0, 0.12 * lag), (0, 0, 0))
    p["sleeve.L"] = ((0.8 + 0.2 * math.sin(ph - 1.3), 0, 0), (0, 0, 0))
    p["sleeve.R"] = ((0.8 - 0.2 * math.sin(ph - 1.3), 0, 0), (0, 0, 0))
    return _stow(p)


def clip_ride_idle(t):
    """Sitting a standing horse: upright and easy, the reins low in the hands, breathing, the head
    turning to look about."""
    w = 2 * math.pi / RIDE_IDLE_T
    br = math.sin(t * w * 2)
    look = math.sin(t * w + 0.6)
    p = {}
    _astride(p, br * 0.004, 0.03)
    _reins(p, 0.8, br)
    p["chest"] = ((-br * 0.02, 0.0, 0.0), (0, 0.003 * br, 0))
    p["head"] = ((0.02 + 0.03 * math.sin(t * w * 2 + 1.0), 0.28 * look, 0.0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (1.2, 3.1)), 1))
    _secondary(p, t, False, True, (-1.1, -1.1), br, (0.35, 0.35))
    return _stow(p)


def clip_ride_stand(t):
    """Standing on a flying sword or a cloud: feet set one before the other along the blade, knees
    soft, the left hand raised in a sword-seal before the chest and the right held back for balance;
    a slow sway against the wind, and everything loose streaming back."""
    w = 2 * math.pi / RIDE_STAND_T
    sw = math.sin(t * w)
    br = math.sin(t * w * 2)
    p = {}
    p["root"] = ((0, 0, 0), (0, 0, 0))
    p["hips"] = ((0.06, 0.12 + 0.03 * sw, 0.02 * sw), (0.0, -0.08 + 0.01 * br, 0.0))
    p["thigh.L"] = ((-0.38, 0.0, 0.08), (0, 0, 0))
    p["shin.L"] = ((0.42, 0.0, 0.0), (0, 0, 0))
    p["foot.L"] = ((-0.04, 0.0, 0.0), (0, 0, 0))
    p["thigh.R"] = ((0.3, 0.0, -0.1), (0, 0, 0))
    p["shin.R"] = ((0.38, 0.0, 0.0), (0, 0, 0))
    p["foot.R"] = ((-0.62, 0.0, 0.0), (0, 0, 0))
    p["toe.R"] = ((0.45, 0.0, 0.0), (0, 0, 0))
    p["spine"] = ((0.1, -0.1 - 0.03 * sw, 0.0), (0, 0, 0))
    p["chest"] = ((0.04 - br * 0.015, -0.06, 0.0), (0, 0, 0))
    p["neck"] = ((-0.04, 0.08, 0.0), (0, 0, 0))
    p["head"] = ((-0.1, 0.12 + 0.04 * sw, 0.0), (0, 0, 0))
    # the sword-seal: index and middle fingers raised before the chest
    p["upper_arm.L"] = ((-0.75, 0.0, -0.32), (0, 0, 0))
    p["forearm.L"] = ((-1.55, 0.35, 0.0), (0, 0, 0))
    p["hand.L"] = ((0.0, 0.3, 0.2), (0, 0, 0))
    p["upper_arm.R"] = ((0.35 + 0.05 * sw, 0.0, -0.45), (0, 0, 0))
    p["forearm.R"] = ((-0.35, -0.2, 0.0), (0, 0, 0))
    p["hand.R"] = ((0.1, -0.2, 0.0), (0, 0, 0))
    _hands(p, 0.2, 0.6, 0.3)
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, _blink(t, (0.9, 2.4)), 1))
    flap = math.sin(t * w * 4)
    p["robe_f"] = ((-0.25 + 0.06 * flap, 0, 0), (0, 0, 0))
    p["robe_b"] = ((0.75 + 0.1 * flap, 0, 0), (0, 0, 0))
    p["robe_l"] = ((0.25 + 0.05 * flap, 0, -0.12), (0, 0, 0))
    p["robe_r"] = ((0.25 - 0.05 * flap, 0, 0.12), (0, 0, 0))
    p["cape"] = ((1.1 + 0.1 * flap, 0.05 * sw, 0), (0, 0, 0))
    p["cape2"] = ((0.35 + 0.12 * math.sin(t * w * 4 - 0.8), 0, 0.06 * sw), (0, 0, 0))
    p["cape3"] = ((0.22 + 0.12 * math.sin(t * w * 4 - 1.6), 0, 0.08 * sw), (0, 0, 0))
    p["hair_tail"] = ((0.8 + 0.08 * flap, 0, 0.1 * sw), (0, 0, 0))
    p["hair_tail2"] = ((0.4 + 0.1 * math.sin(t * w * 4 - 1.0), 0, 0.1 * sw), (0, 0, 0))
    p["sleeve.L"] = ((0.6 + 0.15 * flap, 0, 0), (0, 0, 0))
    p["sleeve.R"] = ((0.9 + 0.15 * flap, 0, 0), (0, 0, 0))
    return _stow(p)


# ---------------------------------------------------------------- the Eight Arms (the Hundred Arms release)
# The hero carries one of eight weapons (art/lib/arms.py, scripts/arms.gd), hung on the sword bone, and
# each is used in its own way: a clip for its plain blow ("arm_<id>") and one for the technique of its
# Dao ("art_<id>").  They are written as a few held poses with the time each is reached; `_keyed`
# eases from one to the next, lets cloth and hair lag behind, and turns the whole figure where a form
# spins.  A pose names bones -> (x, y, z) Godot Euler angles as everywhere here, plus "loc" (the hips'
# offset), "hands" (the curl of the left and right fingers) and "spin" (turns of the whole body).
def _keyed(keys, secs):
    keys = [(0.0, {})] + list(keys) + [(1.0, {})]

    def clip(t):
        k = clamp(t / secs)
        i = 0
        while i < len(keys) - 2 and k >= keys[i + 1][0]:
            i += 1
        k0, a = keys[i]
        k1, c = keys[i + 1]
        u = smooth(0.0, 1.0, (k - k0) / max(1e-6, k1 - k0))
        # a blow lands fast and settles slowly
        u = u * u * (3.0 - 2.0 * u) if c.get("fast") else u
        p = _base_for_act()
        e = env(k)
        names = set(a) | set(c)
        for nm in names:
            if nm in ("fast",):
                continue
            va = a.get(nm, None)
            vc = c.get(nm, None)
            if nm == "hands":
                va = va or (0.35, 1.1)
                vc = vc or (0.35, 1.1)
                _hands(p, va[0] + (vc[0] - va[0]) * u, va[1] + (vc[1] - va[1]) * u)
                continue
            if nm == "spin":
                va = va or 0.0
                vc = vc if vc is not None else va
                p["root"] = ((0, 2.0 * math.pi * (va + (vc - va) * u), 0), (0, 0, 0))
                continue
            if nm == "loc":
                va = va or (0.0, 0.0, 0.0)
                vc = vc or (0.0, 0.0, 0.0)
                rot = p.get("hips", ((0, 0, 0), (0, 0, 0)))[0]
                p["hips"] = (rot, tuple(va[j] + (vc[j] - va[j]) * u for j in range(3)))
                continue
            va = va or (0.0, 0.0, 0.0)
            vc = vc or (0.0, 0.0, 0.0)
            rot = tuple(va[j] + (vc[j] - va[j]) * u for j in range(3))
            loc = p.get(nm, ((0, 0, 0), (0, 0, 0)))[1] if nm == "hips" else (0, 0, 0)
            p[nm] = (rot, loc)
        if "hands" not in names:
            _hands(p, 0.35, 1.1)
        lx = p.get("thigh.L", ((0, 0, 0),))[0][0]
        rx = p.get("thigh.R", ((0, 0, 0),))[0][0]
        ax = p.get("upper_arm.R", ((0, 0, 0),))[0][0]
        al = p.get("upper_arm.L", ((0, 0, 0),))[0][0]
        root = p.get("root")
        _secondary(p, t, False, False, (lx, rx), e, (0.25 * e + 1.2 * smooth(-0.6, -2.2, al), 0.25 * e + 1.2 * smooth(-0.6, -2.2, ax)))
        if root is not None:
            p["root"] = root
            # cloth and hair stream out behind a turn
            sp = math.sin(math.pi * clamp((k - k0) / max(1e-6, k1 - k0))) if (a.get("spin", 0.0) != c.get("spin", a.get("spin", 0.0))) else 0.0
            for nm, amt in (("cape", 0.5), ("cape2", 0.3), ("hair_tail", 0.5), ("hair_tail2", 0.3), ("robe_b", 0.35)):
                rot, loc = p[nm][0], p[nm][1]
                p[nm] = ((rot[0] + amt * sp, rot[1], rot[2] + 0.3 * amt * sp), loc)
        return p

    return clip


ARM_T = 0.7
ART_T = 1.3

# the lunge most blows end in: the left foot forward and bent, the right leg long behind
_LUNGE = {"thigh.L": (-0.95, 0, 0.05), "shin.L": (0.95, 0, 0), "thigh.R": (0.5, 0, -0.05), "shin.R": (0.2, 0, 0), "foot.R": (0.35, 0, 0), "toe.R": (-0.4, 0, 0)}
_SET = {"thigh.L": (-0.35, 0, 0.1), "shin.L": (0.5, 0, 0), "thigh.R": (-0.2, 0, -0.1), "shin.R": (0.5, 0, 0)}

# the sabre: both hands take it up behind the head, and the whole weight comes down with it
_SABRE_W = dict(_SET, **{"upper_arm.R": (-2.7, 0, -0.3), "forearm.R": (-0.9, 0, 0), "upper_arm.L": (-2.45, 0, 0.45), "forearm.L": (-1.1, 0, 0), "chest": (-0.22, 0.35, 0),
                         "hips": (-0.05, 0.3, 0), "loc": (0, -0.05, -0.06), "head": (0.12, -0.3, 0), "hands": (1.0, 1.15)})
_SABRE_H = dict(_LUNGE, **{"upper_arm.R": (-0.8, 0, 0.3), "forearm.R": (-0.15, 0, 0), "hand.R": (0.55, 0, 0), "upper_arm.L": (-0.85, 0, -0.3), "forearm.L": (-0.55, 0, 0),
                           "chest": (0.42, -0.4, 0), "spine": (0.15, -0.2, 0), "hips": (0.15, -0.35, 0), "loc": (0, -0.14, 0.2), "head": (-0.2, 0.3, 0), "hands": (1.0, 1.15), "fast": True})
# the spear: drawn back to the hip in both hands, then the whole body goes out along it
_SPEAR_W = dict(_SET, **{"hips": (0, 0.75, 0), "loc": (0, -0.08, -0.06), "chest": (0.05, 0.35, 0), "head": (0, -0.9, 0), "upper_arm.R": (0.55, 0, -0.35), "forearm.R": (-1.5, 0, 0),
                         "hand.R": (0.38, 0, 0), "upper_arm.L": (-1.05, -0.5, 0.1), "forearm.L": (-0.5, 0, 0), "hands": (0.9, 1.15)})
_SPEAR_H = dict(_LUNGE, **{"hips": (0.1, -0.25, 0), "loc": (0, -0.15, 0.3), "chest": (0.25, -0.3, 0), "head": (-0.1, 0.4, 0), "upper_arm.R": (-1.4, 0, 0.1), "forearm.R": (-0.05, 0, 0),
                           "hand.R": (0.2, 0, 0), "upper_arm.L": (-1.2, 0, -0.25), "forearm.L": (-0.45, 0, 0), "hands": (0.9, 1.15), "fast": True})
# the staff: level, in both hands, swept from one side of the body right round to the other
_STAFF_W = dict(_SET, **{"hips": (0, 0.9, 0), "loc": (0, -0.06, 0), "chest": (0, 0.5, 0), "head": (0, -1.1, 0), "upper_arm.R": (-0.9, 0, -1.1), "forearm.R": (-0.7, 0, 0),
                         "upper_arm.L": (-1.2, 0, -0.6), "forearm.L": (-1.2, 0, 0), "hands": (1.0, 1.15)})
_STAFF_H = {"hips": (0, -0.8, 0), "loc": (0, -0.1, 0.1), "chest": (0.1, -0.6, 0), "head": (0, 1.0, 0), "upper_arm.R": (-1.2, 0, 0.7), "forearm.R": (-0.3, 0, 0), "hand.R": (0.15, 0, 0),
            "upper_arm.L": (-0.9, 0, 0.5), "forearm.L": (-1.0, 0, 0), "thigh.L": (-0.5, 0, 0.1), "shin.L": (0.6, 0, 0), "thigh.R": (0.3, 0, -0.1), "shin.R": (0.3, 0, 0), "hands": (1.0, 1.15), "fast": True}
# the fan: closed across the body, then flicked open at arm's length, the other hand behind the back
_FAN_BACK = {"upper_arm.L": (0.5, 0, 0.3), "forearm.L": (-1.25, 0, 0)}
_FAN_W = dict(_FAN_BACK, **{"upper_arm.R": (-0.9, 0, 0.9), "forearm.R": (-1.6, 0, 0), "hand.R": (0, 0, 0.5), "chest": (0, 0.5, 0), "hips": (0, 0.3, 0), "loc": (0, 0.03, 0),
                            "head": (0, -0.4, 0.1), "foot.L": (0.25, 0, 0), "foot.R": (0.25, 0, 0)})
_FAN_H = dict(_FAN_BACK, **{"upper_arm.R": (-1.3, 0, -0.9), "forearm.R": (-0.15, 0, 0), "hand.R": (0.3, 0, -0.4), "chest": (0, -0.5, 0.05), "hips": (0, -0.3, 0), "loc": (0, 0, 0.1),
                            "head": (0, 0.3, -0.1), "thigh.L": (-0.4, 0, 0), "shin.L": (0.3, 0, 0), "fast": True})
# the bow: side on, the bow arm out along the line of the shot, the string hand drawn to the ear, loosed
_BOW_UP = {"hips": (0, 0.8, 0), "chest": (0, 0.4, 0), "head": (0, -1.1, 0), "upper_arm.R": (0, 0, -1.5), "hand.R": (0, 0, 0), "upper_arm.L": (-0.2, 0, -1.35), "forearm.L": (-0.3, 0, 0),
           "thigh.L": (0, 0, 0.2), "thigh.R": (0, 0, -0.2), "hands": (0.9, 1.15)}
_BOW_DRAW = dict(_BOW_UP, **{"chest": (-0.08, 0.5, 0), "upper_arm.L": (-0.15, 0, -1.2), "forearm.L": (-2.2, 0, 0), "hands": (1.1, 1.15)})
_BOW_LOOSE = dict(_BOW_UP, **{"chest": (-0.05, 0.55, 0), "upper_arm.L": (0, 0, 0.75), "forearm.L": (-0.9, 0, 0), "hands": (0.05, 1.15), "fast": True})
# the chain whip: whirled once overhead, and thrown out to its full length
_WHIP_W = {"upper_arm.R": (-2.8, 0, -0.6), "forearm.R": (-1.2, 0, 0), "hand.R": (-0.5, 0, 0), "chest": (-0.15, 0.4, 0), "hips": (0, 0.3, 0), "upper_arm.L": (-0.6, 0, 0.7),
           "forearm.L": (-0.5, 0, 0), "head": (0.05, -0.3, 0)}
_WHIP_H = {"upper_arm.R": (-1.2, 0, 0.3), "forearm.R": (-0.1, 0, 0), "hand.R": (0.38, 0, 0), "chest": (0.3, -0.45, 0), "hips": (0.05, -0.3, 0), "loc": (0, -0.05, 0.15),
           "upper_arm.L": (0.4, 0, 0.5), "forearm.L": (-0.4, 0, 0), "thigh.L": (-0.6, 0, 0), "shin.L": (0.6, 0, 0), "thigh.R": (0.35, 0, 0), "head": (-0.1, 0.3, 0), "fast": True}
# the judge's brush: written with, not struck with: a dot, a lift and a second dot, the off hand at the back
_BRUSH_BACK = {"upper_arm.L": (0.45, 0, 0.25), "forearm.L": (-1.3, 0, 0)}
_BRUSH_UP = dict(_BRUSH_BACK, **{"upper_arm.R": (-1.2, 0, -0.4), "forearm.R": (-1.3, 0, 0), "hand.R": (0.15, 0, 0), "chest": (0, 0.2, 0)})
_BRUSH_DOT = dict(_BRUSH_BACK, **{"upper_arm.R": (-1.5, 0, 0.1), "forearm.R": (-0.1, 0, 0), "hand.R": (0.23, 0, 0), "loc": (0, -0.04, 0.12), "thigh.L": (-0.5, 0, 0), "shin.L": (0.5, 0, 0),
                                  "chest": (0.1, -0.2, 0), "fast": True})
_BRUSH_DOT2 = dict(_BRUSH_DOT, **{"upper_arm.R": (-1.2, 0, 0.45), "forearm.R": (-0.2, 0, 0), "hand.R": (0.38, 0, 0), "chest": (0.2, -0.35, 0)})


def _but(pose, **kw):
    return dict(pose, **kw)


ARMS = {
    "arm_sabre": (ARM_T, _keyed([(0.32, _SABRE_W), (0.5, _SABRE_H), (0.72, _SABRE_H)], ARM_T)),
    "arm_spear": (ARM_T, _keyed([(0.32, _SPEAR_W), (0.48, _SPEAR_H), (0.7, _SPEAR_H)], ARM_T)),
    "arm_staff": (ARM_T, _keyed([(0.3, _STAFF_W), (0.52, _STAFF_H), (0.72, _STAFF_H)], ARM_T)),
    "arm_fan": (ARM_T, _keyed([(0.3, _FAN_W), (0.46, _FAN_H), (0.72, _FAN_H)], ARM_T)),
    "arm_bow": (ARM_T + 0.2, _keyed([(0.2, _BOW_UP), (0.55, _BOW_DRAW), (0.63, _BOW_LOOSE), (0.82, _BOW_LOOSE)], ARM_T + 0.2)),
    "arm_whip": (ARM_T, _keyed([(0.36, _WHIP_W), (0.54, _WHIP_H), (0.74, _WHIP_H)], ARM_T)),
    "arm_brush": (ARM_T + 0.1, _keyed([(0.2, _BRUSH_UP), (0.34, _BRUSH_DOT), (0.5, _BRUSH_UP), (0.64, _BRUSH_DOT2), (0.8, _BRUSH_DOT2)], ARM_T + 0.1)),
    # ---- the technique of each weapon's Dao
    # One Line: the jian drawn back along the forearm, and then nothing is out of line from heel to point
    "art_jian": (ART_T, _keyed([
        (0.28, dict(_SET, **{"hips": (0, 0.6, 0), "loc": (0, -0.12, -0.1), "chest": (0, 0.3, 0), "head": (0, -0.8, 0), "upper_arm.R": (0.4, 0, -0.3), "forearm.R": (-1.6, 0, 0),
                             "hand.R": (0.18, 0, 0), "upper_arm.L": (-1.3, 0, -0.2), "forearm.L": (-0.2, 0, 0), "hands": (0.1, 1.15)})),
        (0.5, dict(_LUNGE, **{"hips": (0.2, -0.3, 0), "loc": (0, 0.08, 0.5), "chest": (0.3, -0.3, 0), "head": (-0.3, 0.4, 0), "upper_arm.R": (-1.5, 0, 0.05), "forearm.R": (0, 0, 0),
                              "hand.R": (0.2, 0, 0), "upper_arm.L": (0.9, 0, 0.3), "forearm.L": (-0.1, 0, 0), "hands": (0.1, 1.15), "fast": True})),
        (0.78, dict(_LUNGE, **{"hips": (0.2, -0.3, 0), "loc": (0, -0.14, 0.42), "chest": (0.3, -0.3, 0), "head": (-0.3, 0.4, 0), "upper_arm.R": (-1.5, 0, 0.05), "hand.R": (0.2, 0, 0),
                               "upper_arm.L": (0.9, 0, 0.3), "hands": (0.1, 1.15)}))], ART_T)),
    # The Tiger Comes Down the Mountain: one whole turn to gather the weight, and the chop
    "art_sabre": (ART_T, _keyed([(0.18, _but(_SABRE_W, spin=0.0)), (0.52, _but(_SABRE_W, spin=1.0, loc=(0, 0.16, 0.1))), (0.66, _but(_SABRE_H, spin=1.0)), (0.84, _but(_SABRE_H, spin=1.0))], ART_T)),
    # The Dragon Leaves the Sea: down on one knee with the point trailing, and up through the guard
    "art_spear": (ART_T, _keyed([
        (0.3, _but(_SPEAR_W, loc=(0, -0.42, -0.1), **{"thigh.L": (-1.3, 0, 0.1), "shin.L": (1.5, 0, 0), "thigh.R": (-0.2, 0, -0.1), "shin.R": (1.6, 0, 0)})),
        (0.5, _but(_SPEAR_H, loc=(0, 0.22, 0.35), **{"upper_arm.R": (-2.1, 0, 0.1), "upper_arm.L": (-1.8, 0, -0.25), "chest": (-0.1, -0.3, 0), "head": (-0.45, 0.4, 0)})),
        (0.76, _but(_SPEAR_H, **{"upper_arm.R": (-1.75, 0, 0.1), "upper_arm.L": (-1.5, 0, -0.25)}))], ART_T)),
    # Sweeping the Thousand: the staff held level and the sweeper turning under it, twice
    "art_staff": (ART_T, _keyed([(0.14, _but(_STAFF_W, spin=0.0)), (0.72, _but(_STAFF_H, spin=2.0, fast=False)), (0.86, _but(_STAFF_H, spin=2.0, loc=(0, -0.2, 0.15)))], ART_T)),
    # The Wind Unfolds: a turn on the toes with the fan out, and the flick that sends the wind off it
    "art_fan": (ART_T, _keyed([(0.16, _but(_FAN_W, spin=0.0)), (0.56, _but(_FAN_H, spin=1.0, loc=(0, 0.06, 0.0), fast=False)),
                               (0.68, _but(_FAN_W, spin=1.0)), (0.8, _but(_FAN_H, spin=1.0)), (0.9, _but(_FAN_H, spin=1.0))], ART_T)),
    # The Shot Not Shot: kneeling, a long draw held until the breath is out, and the string let go
    "art_bow": (ART_T, _keyed([
        (0.2, _but(_BOW_UP, loc=(0, -0.4, 0), **{"thigh.L": (-1.4, 0, 0.2), "shin.L": (1.5, 0, 0), "thigh.R": (0.1, 0, -0.2), "shin.R": (1.5, 0, 0)})),
        (0.42, _but(_BOW_DRAW, loc=(0, -0.4, 0), **{"thigh.L": (-1.4, 0, 0.2), "shin.L": (1.5, 0, 0), "thigh.R": (0.1, 0, -0.2), "shin.R": (1.5, 0, 0)})),
        (0.7, _but(_BOW_DRAW, loc=(0, -0.4, 0), **{"chest": (-0.12, 0.55, 0), "thigh.L": (-1.4, 0, 0.2), "shin.L": (1.5, 0, 0), "thigh.R": (0.1, 0, -0.2), "shin.R": (1.5, 0, 0)})),
        (0.76, _but(_BOW_LOOSE, loc=(0, -0.4, 0), **{"thigh.L": (-1.4, 0, 0.2), "shin.L": (1.5, 0, 0), "thigh.R": (0.1, 0, -0.2), "shin.R": (1.5, 0, 0)})),
        (0.9, _but(_BOW_LOOSE, loc=(0, -0.4, 0), **{"thigh.L": (-1.4, 0, 0.2), "shin.L": (1.5, 0, 0), "thigh.R": (0.1, 0, -0.2), "shin.R": (1.5, 0, 0)}))], ART_T)),
    # Nine Bends: the chain whirled round a turning body, and let out at the last
    "art_whip": (ART_T, _keyed([(0.16, _but(_WHIP_W, spin=0.0)), (0.6, _but(_WHIP_W, spin=1.0, hips=(0, -0.3, 0), chest=(-0.15, -0.4, 0))), (0.72, _but(_WHIP_H, spin=1.0)), (0.88, _but(_WHIP_H, spin=1.0))], ART_T)),
    # One Stroke: the character for "one", written in the air from left to right at full arm, and its dot
    "art_brush": (ART_T, _keyed([
        (0.2, dict(_BRUSH_BACK, **{"upper_arm.R": (-1.75, 0, 0.75), "forearm.R": (-0.5, 0, 0), "hand.R": (0.15, 0, 0), "chest": (-0.1, 0.45, 0), "head": (-0.15, -0.3, 0), "loc": (0, 0.03, 0)})),
        (0.5, dict(_BRUSH_BACK, **{"upper_arm.R": (-1.55, 0, -1.0), "forearm.R": (-0.1, 0, 0), "hand.R": (0.15, 0, 0), "chest": (0.05, -0.5, 0), "head": (0, 0.35, 0), "loc": (0, -0.05, 0.08),
                                   "thigh.L": (-0.3, 0, 0.15), "thigh.R": (0, 0, -0.2)})),
        (0.62, _BRUSH_UP), (0.72, _BRUSH_DOT), (0.88, _BRUSH_DOT)], ART_T)),
}


RIDE = {
    "ride": (RIDE_T, clip_ride),
    "ride_idle": (RIDE_IDLE_T, clip_ride_idle),
    "ride_stand": (RIDE_STAND_T, clip_ride_stand),
}
PARTY_CLIPS = dict(CLIPS, **INTERACT, **RIDE)
# (only the hero bears arms: Yue Ling keeps to her needle)
HERO_CLIPS = dict(PARTY_CLIPS, **ARMS)


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

