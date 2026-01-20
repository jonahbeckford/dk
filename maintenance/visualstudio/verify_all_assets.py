#!/usr/bin/env python3
"""
Verify all MSVC assets listed in a plain asset list by invoking `dk0 get-asset`.

Writes failures to `build/tmp/msvc_verification_failures.txt` and exits
with code 0 if all assets verified, non-zero otherwise.

Usage:
  python3 verify_all_assets.py [--asset-list PATH] [--cache-dir PATH] [--workers N] [--retries N]
"""
import argparse
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed


def verify_one(bundle, path, cache_dir, dk0_cmd, retries, backoff):
    dest = os.path.join(cache_dir, path)
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    args = dk0_cmd + ["get-asset", bundle, "-p", path, "-f", dest]
    last_err = None
    for attempt in range(1, retries + 1):
        try:
            res = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            if res.returncode == 0 and os.path.exists(dest):
                return True, None
            last_err = res.stderr.decode(errors="replace")
        except Exception as e:
            last_err = str(e)
        time.sleep(backoff * attempt)
    return False, last_err


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--asset-list", default="build/tmp/msvc_asset_list.txt")
    p.add_argument("--cache-dir", default="build/tmp/msvc_verification_cache")
    p.add_argument("--workers", type=int, default=1)
    p.add_argument("--retries", type=int, default=3)
    p.add_argument("--backoff", type=float, default=1.0)
    p.add_argument("--dk0", default="ext/dk/dk0")
    p.add_argument("--package", default="CommonsBase_VisualStudio")
    p.add_argument("--values-dir", default="ext/dk/etc/dk/v")
    args = p.parse_args()

    # If the asset list is missing, try to generate it using the local make_asset_list.py
    if not os.path.exists(args.asset_list):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        repo_root = os.path.abspath(os.path.join(script_dir, "../../../.."))
        helper_local = os.path.join(script_dir, "make_asset_list.py")
        helper_buildtmp = os.path.join(repo_root, "build/tmp/make_asset_list.py")

        generated = False
        if os.path.exists(helper_local):
            print(f"Asset list {args.asset_list} not found — generating with {helper_local}")
            try:
                subprocess.check_call([sys.executable, helper_local])
                generated = True
            except subprocess.CalledProcessError:
                print(f"make_asset_list.py failed at {helper_local}", file=sys.stderr)
        elif os.path.exists(helper_buildtmp):
            print(f"Asset list {args.asset_list} not found — generating with {helper_buildtmp}")
            try:
                subprocess.check_call([sys.executable, helper_buildtmp])
                generated = True
            except subprocess.CalledProcessError:
                print(f"make_asset_list.py failed at {helper_buildtmp}", file=sys.stderr)
        else:
            print(f"Asset list not found and no make_asset_list.py helper available (checked {helper_local} and {helper_buildtmp})", file=sys.stderr)

        if not generated and not os.path.exists(args.asset_list):
            return 2

    with open(args.asset_list, "r", encoding="utf-8") as f:
        lines = [ln.strip() for ln in f if ln.strip()]

    dk0_cmd = [args.dk0, "--trial", "--trust-local-package", args.package, "-I", args.values_dir]

    failures = []
    total = len(lines)

    # Use requested worker count (default 4). Keep minimum of 1.
    workers = max(1, args.workers)
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futures = {}
        for i, line in enumerate(lines, start=1):
            if ":" not in line:
                failures.append((line, "bad-entry"))
                continue
            bundle, path = line.split(":", 1)
            futures[ex.submit(verify_one, bundle, path, args.cache_dir, dk0_cmd, args.retries, args.backoff)] = (i, bundle, path)

        done = 0
        for fut in as_completed(futures):
            done += 1
            i, bundle, path = futures[fut]
            ok, err = fut.result()
            status = "OK" if ok else "FAIL"
            print(f"[{done}/{total}] {path} {status}", flush=True)
            if not ok:
                failures.append((path, err or "unknown"))

    os.makedirs(os.path.dirname("build/tmp/msvc_verification_failures.txt"), exist_ok=True)
    if failures:
        with open("build/tmp/msvc_verification_failures.txt", "w", encoding="utf-8") as out:
            for path, err in failures:
                out.write(path + "\n")
        print(f"Verification complete: {total - len(failures)} succeeded, {len(failures)} failed (out of {total})")
        print("Failures written to build/tmp/msvc_verification_failures.txt")
        return 3

    print(f"Verification complete: {total} succeeded, 0 failed (out of {total})")
    try:
        os.remove("build/tmp/msvc_verification_failures.txt")
    except FileNotFoundError:
        pass
    return 0


if __name__ == "__main__":
    sys.exit(main())
