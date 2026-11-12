"""Fox: the nine-tailed fox spirit of the Maple Gorge (Part VI) and the Hounds of the Ten Courts.
A slender red fox from art/lib/canine.py, sculpted in clay: a light body on long legs in black
stockings, a narrow muzzle with a flat bridge and the mouth closed along a black lip line,
slit-pupilled eyes with a dark tear line, big ears with black backs, white cheeks, throat and
belly, and - as the Classic of Mountains and Seas has it - nine tails, fanned behind it like a
train: smooth bushy brushes (each its own clay and four-bone chain, so the fan ripples like
flames), every one tipped in white with a tongue of fox-fire.  Tinted by the game per
enemy; the white, the black points and the fox-fire keep their own colours.
Clips: idle, walk, attack (a lunging bite with the tails flaring), hurt, die and cast (the tails
fan out into fox-fire).
Run: blender --background --python art/monsters/fox.py  ->  assets/monsters/fox.glb"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "lib"))
import kit  # noqa: E402
import creature  # noqa: E402
import canine  # noqa: E402

kit.reset()
creature.realtime()
b, r, hf, clips = canine.build("fox", "fox", n_tails=9)
print("[art] fox: %d triangles" % b.tri_count())
kit.finish_rigged(b, r, "monsters/fox.glb", clips, samples=16, dist=0.3, strength=0.5, floor_y=0.0)
