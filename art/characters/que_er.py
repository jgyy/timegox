"""Little Que'er of Featherfall (Part XI): a Yumin child whose wings have only just grown their
flight feathers, who is not yet allowed to jump from the high branches, and does.  Little
sparrow-brown wings streaked with umber and buff, a tuft of a crest, and a short robe of buff and
russet.
Run: blender --background --python art/characters/que_er.py  ->  assets/characters/que_er.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/que_er.glb", {
    # a child (like little_dou and child_hua): small, with a big head and big eyes
    "age": 0.0, "build": 0.8, "eye_size": 1.45, "scale": 0.7, "head_scale": 1.2, "jaw": 0.85,
    # race (art/lib/race.py): a sparrow's little wings and a tuft of a crest
    "wings": "8a6440", "wing_tip": "d8c098", "wing_bar": "4a3220", "wing_span": 0.76,
    "crest": "6a4a2c", "crest_tip": "b89068", "crest_len": 0.12, "crest_n": 3, "crest_up": 0.75,
    "robe_len": "short",
    "robe": "d8a868", "trim": "fff2dc", "inner": "fff8ee", "sash": "a83a3a", "pants": "8a4a2a",
    "hair": "3a2818", "hair_style": "short", "eyes": "5a3a1a",
})
