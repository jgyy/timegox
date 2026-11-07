"""Tiger: the great cats (Bai Hu the White Tiger, Kunlun Snow Tigers, Ice Lynxes, the Jade Guardian
Lions, the Paper Tiger of Qingshi, Kaiming of the Nine Gates).

Feline anatomy (art/lib/feline.py, built on anatomy.py), distinct from the canine ``beast``: a long, low body with
heavy shoulders and a deep chest, a supple waist, powerful haunches; thick forelegs on broad round
paws; a round skull with a short broad muzzle, whisker pads and whiskers, small rounded ears and a
ruff of longer fur on the cheeks; the coat painted with tiger stripes that wrap the flanks in
pairs and narrow towards the spine, the "king" mark on the brow, white cheeks and belly; a long
tail ringed dark towards its tip.  Tinted by the game per enemy; the white markings stay pale.
Run: blender --background --python art/monsters/tiger.py  ->  assets/monsters/tiger.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import feline  # noqa: E402

kit.reset()
b, r, hf, clips = feline.build("tiger")
print("[art] tiger: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/tiger.glb", clips, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
