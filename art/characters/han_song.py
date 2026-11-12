"""Han Song, Patriarch of the Cold Pine Sect (Part XXV): "only when the year turns cold do we see that the pine and the cypress are the last
to wither"; a master who has outlasted every rival and every pupil he ever thought worthy, and holds that whatever grows within a hundred li of his mountain
grows by his leave: a tall, spare old man in pine-green with silver trims, white hair and a long white beard, a sword at his side.
Run: blender --background --python art/characters/han_song.py  ->  assets/characters/han_song.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/han_song.glb", {"fem": False, "age": 0.9, "build": 0.95, "jaw": 1.0, "brow": 1.2, "stern": True, "smile": False, "skin": "d8c4a8", "scale": 1.12,
    "robe": "2e6250", "trim": "c8ccd4", "inner": "e8ece8", "sash": "c8ccd4", "pants": "1c2e28", "boots": "14201c", "hair": "eceae6", "hair_style": "topknot", "eyes": "3a4a44",
    "beard": True, "beard_len": 0.6, "beard_col": "f0eeea", "cape": "1e4438", "sleeve_w": 1.2, "brocade": "cloud", "brocade_col": "3a6a58",
    "sword": True, "blade": "e0e8f0", "hilt": "c8ccd4"})
