"""Jiangshi, the hopping corpse of the Yellow Springs (Part VI): a stiff Qing-dynasty official in a
long robe and a fringed hat, grey-green skin, a yellow paper talisman on its forehead, arms held
straight out.  It does not walk: every clip hops.  Cloth is tinted per enemy.
Run: blender --background --python art/monsters/jiangshi.py  ->  assets/monsters/jiangshi.glb"""
import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402
from kit import env  # noqa: E402


def stiff(p, hop):
    """Arms locked straight out in front, legs together, the whole body bobbing with the hop."""
    for sd, s in (("L", 1), ("R", -1)):
        p["upper_arm." + sd] = ((-1.45, 0, -0.08 * s), (0, 0, 0))
        p["forearm." + sd] = ((-0.05, 0, 0), (0, 0, 0))
        p["hand." + sd] = ((0.25, 0, 0), (0, 0, 0))
        p["thigh." + sd] = ((-0.12 * hop, 0, 0), (0, 0, 0))
        p["shin." + sd] = ((0.25 * hop, 0, 0), (0, 0, 0))
        p["foot." + sd] = ((-0.2 * hop, 0, 0), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, 0.16 * hop, 0))
    p["head"] = ((0.08, 0, 0), (0, 0, 0))
    p["eyes"] = ((0, 0, 0), (0, 0, 0), (1, 0.55, 1))
    p["robe_f"] = ((-0.1 * hop, 0, 0), (0, 0, 0))
    p["robe_b"] = ((0.25 * hop, 0, 0), (0, 0, 0))
    return p


def idle(t):
    ph = (t / 1.2) % 1.0
    hop = max(0.0, math.sin(ph * math.pi * 2)) ** 0.8
    return stiff(person.clip_idle(0.0), hop)


def attack(t):
    k = t / 0.6
    e = env(k)
    p = stiff(person.clip_idle(0.0), math.sin(min(1.0, k * 1.4) * math.pi))
    p["root"] = ((0, 0, 0), (0, 0, 0.5 * e))
    for sd in ("L", "R"):
        p["upper_arm." + sd] = ((-1.45 + 0.5 * math.sin(k * math.pi * 3) * e, 0, 0), (0, 0, 0))
    return p


def hurt(t):
    e = env(t / 0.55)
    p = stiff(person.clip_idle(0.0), 0.0)
    p["chest"] = ((-0.3 * e, 0, 0.05 * e), (0, 0, 0))
    p["head"] = ((-0.35 * e, 0.15 * e, 0), (0, 0, 0))
    p["hips"] = ((0, 0, 0), (0, 0, -0.1 * e))
    return p


def cast(t):
    e = env(t / 0.6)
    p = stiff(person.clip_idle(0.0), e)
    p["root"] = ((0, e * math.pi * 2 * min(1.0, t / 0.6), 0), (0, 0, 0))
    return p


kit.reset()
person.export_person("monsters/jiangshi.glb", {
    "robe": "b8b8b8", "trim": "e8e8e8", "inner": "8a8a8a", "sash": "5a5a5a", "pants": "4a4a4a", "boots": "1a1a1a",
    "sleeve": "a8a8a8", "hair": "101014", "hair_style": "bun", "eyes": "e8f0e0", "skin": "b8c8b0", "hat": "qing",
    "talisman": True, "tint_cloth": True, "embroidery": "d0b050", "folds": 12, "collar2": "6a2a2a",
}, clips={"idle": (1.2, idle), "walk": (1.2, idle), "attack": (0.6, attack), "hurt": (0.55, hurt), "cast": (0.6, cast), "victory": (1.2, idle)})
