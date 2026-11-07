"""Magpie (new in Part VIII): the magpies of the bridge over the River of Heaven - the Lost Bridge
Magpies, the Storm-Crowned Magpie and Que Lao's scattered flock.  The bird anatomy of
art/lib/bird.py in the magpie's plumage: black head, back and wings that take the enemy's colour,
a white belly and white wing patches that keep theirs, a long graduated tail of stiff feathers
with a blue-green sheen, and no crest.
Run: blender --background --python art/monsters/magpie.py  ->  assets/monsters/magpie.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import bird  # noqa: E402

kit.reset()
b, r, clips = bird.build("magpie", "magpie")
print("[art] magpie: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/magpie.glb", clips, samples=12, dist=0.25, strength=0.4)
