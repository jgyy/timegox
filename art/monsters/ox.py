"""Ox: the oxen of the land the party meets as foes (the Underclothes release): the Oxen of the Corvee worked until they
forgot whose they were, and the Whole Ox of Part XXVI that no cook could find a gap in.  The same water buffalo as the
draught ox of the cart (art/mounts/ox.py: the hump of muscle the highest point of it, the head carried low on a short
thick neck, a barrel of a body on short heavy legs with cloven hooves, horns sweeping out, back and up in a crescent, a
dewlap and a tufted tail), with nothing on it: no yoke, no blanket, no rosette.  Its hide is painted in greys, so the
game gives each ox its own colour, and as a monster its coat is split into the underside and the markings.
Clips: idle, walk, run, attack, hurt and die.
Run: blender --background --python art/monsters/ox.py  ->  assets/monsters/ox.glb"""
import os
import runpy

runpy.run_path(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "mounts", "ox.py"), init_globals={"OX_WILD": True}, run_name="__main__")
