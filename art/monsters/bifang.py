"""Bifang (new in Part IX): the bird of the Classic of Mountains and Seas whose appearance is an
omen of fire - like a crane, with a single leg, red markings on a blue-green body and a white beak
(after Strassberg, A Chinese Bestiary).  The bird anatomy of art/lib/bird.py as a crane (the
red-crowned crane): a long, slender S-curved neck, a small head with a long white dagger of a bill and
a red crown, a level body with its wings folded along it (each flight feather turned on its own bone
to lie back along the flank), a red bar across the coverts, a bustle of long drooping tertials over
the short tail, and one long scaled leg standing under its centre of balance; flames lick off the
bustle and the primaries.  The body takes the enemy's colour; the red markings, the white beak and
the flames keep theirs.
Clips: idle (standing, wings folded, the bustle and the flames stirring), walk (hops on its one leg,
the wings opening and beating once each hop), attack (a stabbing beak), hurt, die (the leg buckles
and it topples onto its side) and cast (head thrown back, wings spread wide).
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
