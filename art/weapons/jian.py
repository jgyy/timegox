"""One of the Eight Arms (art/lib/arms.py): the jian, built standing on its grip.
Run: blender --background --python art/weapons/jian.py  ->  assets/weapons/jian.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import arms  # noqa: E402

arms.export("jian")
