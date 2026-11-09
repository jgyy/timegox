"""The Echo of Founder Qing Lian (Part XV, the Lotus release): who wove Yue Ling out of the Lotus Seal's
pond three hundred years ago, sitting by her own barrow in white and pale jade with a weaver's shuttle.
Run: blender --background --python art/characters/qing_lian_echo.py  ->  assets/characters/qing_lian_echo.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/qing_lian_echo.glb", {
    # face and build (see art/lib/face.py, garment.py): a woman past her middle years, upright and calm
    "fem": True, "age": 0.35, "eye_size": 1.18, "hair_len": 0.66, "smile": True,
    # plum-blossom brocade over a white robe (garment.MOTIFS), the sect's jade at her sash
    "brocade": "plum", "brocade_col": "f0b0c8",
    # the shuttle she wove with, held before her (art/lib/accessory.py, person.POSES)
    "props": ["shuttle"], "pose": "hold_l",
    "robe": "f4f2f6",
    "trim": "8ad8b8",
    "inner": "ffffff",
    "hair": "d8d4dc",
    "hair_style": "bun",
    "eyes": "5aa88a",
    "sash": "e890b0",
    "jade": "8af0c8", "pin": "f0b0c8",
    "glow_eyes": True,
})
