"""Rebuild every generated asset in assets/ from its script in art/.

    python art/build_all.py                          # with the bpy wheel (pip install bpy)
    blender --background --python art/build_all.py   # with a Blender install

Each asset script runs in its own process so every build starts from an empty scene.  Exits
non-zero if any script fails or does not produce its .glb.
"""
import os
import subprocess
import sys

ART = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(ART)
GROUPS = ("characters", "monsters", "props")


def runner():
    try:
        import bpy  # noqa: F401
        in_blender = bool(getattr(bpy.app, "binary_path", "")) and not os.path.basename(sys.executable).startswith("python")
    except ImportError:
        in_blender = False
    if in_blender:
        return lambda script: [bpy.app.binary_path, "--background", "--factory-startup", "--python", script]
    return lambda script: [sys.executable, script]


def main():
    cmd = runner()
    failed = []
    built = 0
    for group in GROUPS:
        folder = os.path.join(ART, group)
        for name in sorted(os.listdir(folder)):
            if not name.endswith(".py"):
                continue
            script = os.path.join(folder, name)
            out = os.path.join(ROOT, "assets", group, name[:-3] + ".glb")
            print("[build_all] %s/%s" % (group, name), flush=True)
            r = subprocess.run(cmd(script), cwd=ROOT, capture_output=True, text=True)
            if r.returncode != 0 or not os.path.exists(out):
                failed.append("%s/%s" % (group, name))
                sys.stderr.write(r.stdout[-2000:] + r.stderr[-4000:])
            else:
                built += 1
    print("[build_all] built %d assets, %d failed" % (built, len(failed)))
    if failed:
        print("[build_all] failed: " + ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
