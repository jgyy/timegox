"""Bifang (new in Part IX): the bird of the Classic of Mountains and Seas whose appearance is an
omen of fire - a crane with a single leg, blue-green with red markings and a white beak (after
Strassberg, A Chinese Bestiary).  The bird anatomy of art/lib/bird.py as a crane: a long S-curved
neck, a long straight white beak, red bars down the neck and a red crown, a short tail, and one
long scaled leg standing under its centre of balance; tongues of fire run along the trailing
edges of its half-open wings and its tail.  The body takes the enemy's colour; the red, the white
beak and the flames keep theirs.
Clips: idle (standing, wings half open, the flames stirring), walk (hops on its one leg, wings
beating for balance), attack (a stabbing beak), hurt, die (the leg buckles and it topples) and
cast (head thrown back, wings spread).
Run: blender --background --python art/monsters/bifang.py  ->  assets/monsters/bifang.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import bird  # noqa: E402

kit.reset()
creature.realtime()
b, r, clips = bird.build("bifang", "bifang")
print("[art] bifang: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/bifang.glb", clips, samples=12, dist=0.25, strength=0.4, floor_y=0.0)
