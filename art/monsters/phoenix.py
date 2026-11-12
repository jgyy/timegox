"""Phoenix / great bird (Ash Phoenix, Thunder Roc, Garden Crane, Storm Hawk, Jade Emperor of Ruin,
Zhu Que the Vermilion Bird ...): the game's phoenix and every other "bird".  The bird anatomy of
art/lib/bird.py as the fenghuang of the Ming pictures crossed with a bird of prey, so that it reads as
a phoenix in fire's colours and as a hawk, a crane or a crow in theirs: a keeled breast and a back
sloping to the rump, the neck an S hidden under a cape of rounded feathers (the golden pheasant's), a
raptor's head - a brow ridge over a large amber eye, a hooked bill over a yellow cere - and a crest of
backswept plumes; broad fingered wings of layered feathers on a bone each (coverts, secondaries,
tertials, emarginated primaries); a tail fan under five long plumes that stream back and down,
twisting to stand on edge so their banded flags and glowing eyes show from the side.
Clips: idle (hovering on slow wingbeats, the wrist flexed on each upstroke), walk (flying forward),
attack (a talon dive), hurt, die (drops out of the air and lies on the ground, wings spread on it)
and cast (wings raised in a blaze).
Run: blender --background --python art/monsters/phoenix.py  ->  assets/monsters/phoenix.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import bird  # noqa: E402

kit.reset()
creature.realtime()
b, r, clips = bird.build("phoenix", "phoenix")
print("[art] phoenix: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/phoenix.glb", clips, samples=12, dist=0.25, strength=0.4)
