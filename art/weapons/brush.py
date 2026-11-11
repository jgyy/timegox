"""One of the Eight Arms (art/lib/arms.py): the brush, built standing on its grip.
Run: blender --background --python art/weapons/brush.py  ->  assets/weapons/brush.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import arms  # noqa: E402

arms.export("brush")
