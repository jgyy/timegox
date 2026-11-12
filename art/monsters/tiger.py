"""Tiger: the great cats (Bai Hu the White Tiger, Kunlun Snow Tigers, Ice Lynxes, the Jade Guardian
Lions, the Paper Tiger of Qingshi, Kaiming of the Nine Gates).

Feline anatomy (art/lib/feline.py, sculpted in clay over the muscle masses), distinct from the
canine ``beast``: a long body hung between heavy forequarters and powerful haunches on legs long
enough that the chest floor is at the elbows, the shoulder blades riding above the spine, the
head right in front of the shoulders on a short thick neck; a broad round skull with wide
cheekbones, a long broad nose bridge, the muzzle a box with whisker pads either side of a wide
nose leather and the mouth closed under them, high forward-looking eyes, small round ears set to
the sides and a white cheek ruff; thick forearms tapering to the wrist, broad paws; the
coat painted into the greys - stripes that wrap the flanks and narrow towards a white belly,
rings on the legs and tail, the "king" mark on the brow, white eye spots and muzzle, black ear
backs with a white spot and a black tail tip - so every recolour still reads as a tiger.
Clips: idle, walk (a four-beat stalking walk with planted paws), attack (a pounce), hurt, die
and a roar (cast).
Run: blender --background --python art/monsters/tiger.py  ->  assets/monsters/tiger.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import feline  # noqa: E402

kit.reset()
creature.realtime()
b, r, hf, clips = feline.build("tiger")
print("[art] tiger: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/tiger.glb", clips, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
