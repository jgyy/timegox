"""Rebuild every generated asset in assets/ from its script in art/.

    python art/build_all.py                          # with the bpy wheel (pip install bpy)
    blender --background --python art/build_all.py   # with a Blender install

Each asset script runs in its own process so every build starts from an empty scene; the
processes run in parallel (one worker per CPU, or ``ART_JOBS``), and the log is printed in the same
order as a serial build.  Exits non-zero if any script fails or does not produce its .glb.
"""
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

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


def jobs():
    want = os.environ.get("ART_JOBS", "")
    if want.isdigit() and int(want) > 0:
        return int(want)
    return max(1, os.cpu_count() or 1)


def build_one(cmd, group, name):
    script = os.path.join(ART, group, name)
    out = os.path.join(ROOT, "assets", group, name[:-3] + ".glb")
    t0 = time.time()
    r = subprocess.run(cmd(script), cwd=ROOT, capture_output=True, text=True)
    ok = r.returncode == 0 and os.path.exists(out)
    log = "" if ok else r.stdout[-2000:] + r.stderr[-4000:]
    return group, name, ok, time.time() - t0, log


def main():
    cmd = runner()
    todo = []
    for group in GROUPS:
        folder = os.path.join(ART, group)
        for name in sorted(os.listdir(folder)):
            if name.endswith(".py"):
                todo.append((group, name))
    failed = []
    built = 0
    t0 = time.time()
    with ThreadPoolExecutor(max_workers=jobs()) as pool:
        futures = [pool.submit(build_one, cmd, group, name) for group, name in todo]
        # report in the serial order, as each finishes
        for fut in futures:
            group, name, ok, secs, log = fut.result()
            print("[build_all] %s/%s (%.1fs)" % (group, name, secs), flush=True)
            if ok:
                built += 1
            else:
                failed.append("%s/%s" % (group, name))
                sys.stderr.write(log)
    print("[build_all] built %d assets, %d failed in %.0fs with %d workers" % (built, len(failed), time.time() - t0, jobs()))
    if failed:
        print("[build_all] failed: " + ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
