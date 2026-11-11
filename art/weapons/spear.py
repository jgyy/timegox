"""One of the Eight Arms (art/lib/arms.py): the spear, built standing on its grip.
Run: blender --background --python art/weapons/spear.py  ->  assets/weapons/spear.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import arms  # noqa: E402

arms.export("spear")
