"""The Guest Who Said So (Part XXIX): the guest of the parable in the Book of Han who told his host to bend the chimney and
move the firewood away from the stove, was thanked for nothing, and was not asked to the feast after the fire; a thin old
man in a plain grey-brown travelling robe with a patched hem, a wispy white beard and a scholar's small cap, who looks at a
chimney the way a physician looks at a cough.
Run: blender --background --python art/characters/the_guest.py  ->  assets/characters/the_guest.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/the_guest.glb", {"fem": False, "age": 0.9, "build": 0.88, "jaw": 0.9, "brow": 1.1, "smile": False, "skin": "d0b090",
    "robe": "7a7262", "trim": "4a4438", "inner": "e4dcc8", "sash": "4a4438", "pants": "5a5448", "boots": "2a2620",
    "hair": "e8e4dc", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.45, "beard_col": "e8e4dc"})
