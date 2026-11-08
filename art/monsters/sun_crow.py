"""Sun crow (new in Part IX): Jinwu, the three-legged golden crow that lives in the sun.  The bird
anatomy of art/lib/bird.py as a big crow - a stout golden beak, bright plumage that takes the
enemy's colour (gold for the crow of the sun), the primaries a shade deeper - with its three
legs, each ending in golden scaled toes and hooked talons; its wings and tail edged in tongues
of sun-fire and a ring of fire blazing behind it.  The flames keep their own colour.
Clips: idle (hovering on slow wingbeats), walk (flying forward), attack (a talon dive), hurt, die
(falls from the air) and cast (wings raised in a blaze).
Run: blender --background --python art/monsters/sun_crow.py  ->  assets/monsters/sun_crow.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import bird  # noqa: E402

kit.reset()
creature.realtime()
b, r, clips = bird.build("sun_crow", "sun_crow")
print("[art] sun_crow: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/sun_crow.glb", clips, samples=12, dist=0.25, strength=0.4)
