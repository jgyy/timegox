"""Sun crow (new in Part IX): Jinwu, the three-legged golden crow that lives in the sun, as the Han
pictures show it (the crow standing in the sun's disc).  The bird anatomy of art/lib/bird.py as a
raven: a heavy, slightly hooked bill under its nasal bristles, a flat forehead, a shaggy throat of
hackles laid on the neck, a wedge-shaped tail and broad fingered wings whose primaries end in tongues
of flame (the accent colour); golden plumage that takes the enemy's colour, the wings deeper; three
legs, the third behind the other two, each with golden scaled toes and hooked talons; and behind it
the sun - a faint disc of light inside a ring of fire with flames licking out and back - on a bone of
its own, so that when the crow dies the sun falls with it and lies guttering round it on the ground.
The flames keep their own colour.
Clips: idle (hovering on slow wingbeats), walk (flying forward), attack (a talon dive), hurt, die
(falls out of the air into its fallen sun) and cast (wings raised in a blaze).
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
