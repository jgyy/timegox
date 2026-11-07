"""Phoenix / great bird (Ash Phoenix, Thunder Roc, Garden Crane, Jade Emperor of Ruin ...).
A hovering bird with a teardrop body under a coat of contour feathers, two-bone wings fanned with
primaries, secondaries and two rows of coverts, a hackled neck, a hooked two-part beak with a
cere, a bare eye ring and a plumed crest, scaled legs with jointed toes and hooked talons, and long
eyed tail plumes on a three-bone chain.
Run: blender --background --python art/monsters/phoenix.py  ->  assets/monsters/phoenix.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import bird  # noqa: E402

kit.reset()
b, r, clips = bird.build("phoenix", "phoenix")
print("[art] phoenix: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/phoenix.glb", clips, samples=12, dist=0.25, strength=0.4)
