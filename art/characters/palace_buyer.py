"""The Buyer in Yellow (Part XXVII): the palace commissioner of Bai Juyi's poem, who rides up to an old man's cart of a
thousand jin of charcoal with a paper in his hand, says it is by order, turns the ox north, and ties half a bolt of red
gauze to its horn for the price; a sleek, smooth-faced man of forty in a robe of imperial yellow with a white under-robe,
a black gauze cap, soft boots, a scroll of requisition in his hand.
Run: blender --background --python art/characters/palace_buyer.py  ->  assets/characters/palace_buyer.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/palace_buyer.glb", {"fem": False, "age": 0.42, "build": 1.0, "waist": 1.15, "jaw": 0.92, "brow": 0.85, "cheek": 1.15, "smile": True, "skin": "e8ccb0",
    "robe": "d8b030", "trim": "8a2a2a", "inner": "f4f0e8", "sash": "8a2a2a", "pants": "e8e4dc", "boots": "1a1a1e",
    "hair": "141216", "hair_style": "bun", "eyes": "2a2222",
    "props": ["scroll"], "pose": "hold_l"})
