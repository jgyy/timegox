"""Net-Mender Ah Shui (Part XII): a fisherwoman of Landfall who mends nets and tells stories about the holes, a shuttle of twine in her hand and a blue head-cloth.
Run: blender --background --python art/characters/ah_shui.py  ->  assets/characters/ah_shui.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ah_shui.glb", {
    "fem": True, "age": 0.35, "eye_size": 1.15, "jaw": 0.92, "build": 0.98,
    "props": [("shuttle", {"col": "c8a060"})], "pose": "hold_l", "robe_len": "short",
    "robe": "4a7a8a", "trim": "f0e8d0", "inner": "f6f2e8", "sash": "c8803a", "hair": "1a1416", "hair_style": "braid", "eyes": "2a2018", "pants": "3a4a5a", "ribbon": "3a6a9a"
})
