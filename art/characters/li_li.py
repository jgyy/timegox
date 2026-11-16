"""Li Li, Judge of Jin (Part XXX): the chief judge of Duke Wen who heard a case wrongly, had a man put to death for it,
bound himself and asked for the sentence; who, told that the fault was his clerk's, said that he had not shared his rank
or his salary with his clerks and would not share this, and fell on his sword. A spare, straight-backed man in a
judge's black robe with a dark red border, a black cap, a trimmed grey beard, and his own wrists tied with a cord.
Run: blender --background --python art/characters/li_li.py  ->  assets/characters/li_li.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/li_li.glb", {"fem": False, "age": 0.65, "build": 0.94, "jaw": 1.0, "brow": 1.25, "stern": True, "smile": False, "skin": "cca884",
    "robe": "1e1c22", "trim": "7a1e1e", "inner": "e4dcd0", "sash": "7a1e1e", "pants": "18161a", "boots": "141214",
    "hair": "8a8a8e", "hair_style": "topknot", "eyes": "2a2018", "beard": True, "beard_len": 0.25, "beard_col": "8a8a8e"})
