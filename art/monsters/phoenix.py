"""Phoenix / great bird (Ash Phoenix, Thunder Roc, Garden Crane, Storm Hawk, Jade Emperor of Ruin,
Zhu Que the Vermilion Bird ...).  The bird anatomy of art/lib/bird.py: a keeled breast sculpted
in clay with rows of scalloped contour feathers painted into the greys, an S-curved neck, a
hooked two-part beak with a cere and a bare red eye ring, a plumed crest tipped with light, wings
on three-bone chains carrying a few large solid flight feathers - primaries, secondaries,
tertials and two rows of coverts - feathered thighs, scaled shanks and hooked talons, and long
tail plumes on a three-bone chain, each ending in a glowing eye.
Clips: idle (hovering on slow wingbeats), walk (flying forward), attack (a talon dive), hurt, die
(drops from the air and lies with its wings spread) and cast (wings raised in a blaze).
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
