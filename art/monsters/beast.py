"""Beast: the wolves and hounds (Bamboo Wolf, Frost Wolf, Gale Wolf of the Heights, Grave Hound,
the Crimson Hellhound, the Mossback Boar's pack).  Canine anatomy from art/lib/canine.py, sculpted
in clay: a deep keel of a chest, a tucked waist, long legs with the stifle forward and the hock
high behind, four-toed paws with claws; a domed skull with a clear stop, a long tapering muzzle
with a black nose, almond eyes and tall ears; a heavy ruff of broad fur locks round the neck, a
pale bib, elbow and thigh tufts and a brush of a tail.  The coat is painted into the greys - a
dark grizzled saddle, pale cheeks, underside and inner legs, a dark muzzle top and tail tip - so
every recolour still reads as a wolf.
Clips: idle (panting, ears flicking), walk (four-beat with planted paws), attack (a lunging bite),
hurt, die and a howl (cast).
Run: blender --background --python art/monsters/beast.py  ->  assets/monsters/beast.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import canine  # noqa: E402

kit.reset()
creature.realtime()
b, r, hf, clips = canine.build("beast", "wolf")
print("[art] beast: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/beast.glb", clips, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
