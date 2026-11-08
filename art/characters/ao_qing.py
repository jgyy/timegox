"""Cloud-Scribe Ao Qing of the Rain Ministry (Part XI): a young dragon-kin who writes out the rain
orders in a hand so fine that the clouds can read it.  Small pale antlers, pale jade scales on
her cheekbones and the backs of her hands, slit jade eyes, robes of white jade trimmed in green,
and her brush.
Run: blender --background --python art/characters/ao_qing.py  ->  assets/characters/ao_qing.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import person  # noqa: E402

kit.reset()
person.export_person("characters/ao_qing.glb", {
    # face and build (see art/lib/face.py, garment.py)
    "fem": True, "eye_size": 1.34, "jaw": 0.85, "lip": "d8848a", "hair_len": 0.66, "slit_eyes": True, "build": 0.94,
    # race (art/lib/race.py): small antlers and pale scales
    "horns": "antler", "horn_col": "e6eee0", "antler_size": 0.72, "scales": "86c6ae",
    # signature props (art/lib/accessory.py)
    "props": [("brush", {"col": "2a3a34"})],
    # a white-jade robe: keep the greens chosen here
    "monotone": True,
    "robe": "e4efe8", "trim": "76b69e", "inner": "ffffff", "sash": "5a9a84", "pants": "a6c6ba", "boots": "46665c",
    "collar2": "a6d6c2", "hair": "1e2c2c", "hair_style": "long", "eyes": "48b090", "pin": "9ad8c0", "embroidery": "8ac8b0",
})
