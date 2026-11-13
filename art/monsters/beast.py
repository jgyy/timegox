"""Beast: the wolves and hounds (Bamboo Wolf, Frost Wolf, Gale Wolf of the Heights, Grave Hound,
the Crimson Hellhound, the Mossback Boar's pack).  Canine anatomy from art/lib/canine.py, sculpted
in clay after the grey wolf: lean and long-legged, a deep narrow keel of a chest with the ground
further below it than the chest is deep, a tucked waist, the stifle forward and the hock high
behind; a broad skull with a flat forehead and a gentle stop, a muzzle as long as the skull with
the mouth closed at rest along a dark lip line (the jaw fitted under the lip, so it opens only
to bite or howl), oblique almond eyes under a brow, pointed ears set wide; a collar of soft fur
tufts making the neck as wide as the head, cheek ruffs, and a brush of a tail hanging straight
to the hocks.  The coat is painted into the greys - dark guard hairs over the back and the top of
the tail, a darker crown and muzzle bridge, pale cheeks, lips, eyebrow spots, throat, belly and
inner legs, a black tail tip - so every recolour still reads as a wolf.
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
