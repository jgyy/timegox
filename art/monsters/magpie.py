"""Magpie (new in Part VIII): the magpies of the bridge over the River of Heaven - the Lost Bridge
Magpies, the Storm-Crowned Magpie and Que Lao's scattered flock.  The bird anatomy of
art/lib/bird.py as the magpie (Pica pica): a crow's compact body with the head sitting on it, a
flat crown and a stout slate bill under its nasal bristles; a black hood, breast and back (the enemy's
dark colour) over a white belly, white scapulars laid along the back at the root of each wing and
white flashes on the primaries (they take the palette's pale underside colour), glossy secondaries in
the secondary colour, and a long graduated tail held nearly closed, the central pair longest.
Clips: idle (hovering), walk (flying forward), attack (a talon dive), hurt, die (drops and lies on
the ground, wings spread) and cast.
Run: blender --background --python art/monsters/magpie.py  ->  assets/monsters/magpie.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import bird  # noqa: E402

kit.reset()
creature.realtime()
b, r, clips = bird.build("magpie", "magpie")
print("[art] magpie: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/magpie.glb", clips, samples=12, dist=0.25, strength=0.4)
