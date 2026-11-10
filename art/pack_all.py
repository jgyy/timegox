"""Pack every exported .glb in assets/ smaller, in place (see art/lib/pack.py; needs only numpy).

    python art/pack_all.py                # everything in assets/
    python art/pack_all.py assets/characters/lin_feng.glb

``kit.export`` already packs what it writes, so this is only needed for files exported with
``ART_PACK=0``.  Packing a packed file changes nothing.
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "lib"))
import pack  # noqa: E402

if __name__ == "__main__":
    targets = sys.argv[1:] or [os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")]
    for t in targets:
        if os.path.isdir(t):
            pack.pack_all(t)
        else:
            pack.pack(t, quiet=False)
