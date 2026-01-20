#!/usr/bin/env python3
import re, json, os

# Compute repo root relative to this helper script
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "../../../.."))
values_path = os.path.join(REPO_ROOT, 'ext/dk/etc/dk/v/CommonsBase_VisualStudio/MSVC.Bundle.values.jsonc')
out_path = os.path.join(REPO_ROOT, 'build/tmp/msvc_asset_list.txt')

os.makedirs(os.path.dirname(out_path), exist_ok=True)

with open(values_path, 'r', encoding='utf-8') as f:
    s = f.read()
# remove block comments
s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
# remove full-line // comments (leading whitespace allowed)
s = re.sub(r'(?m)^[ \t]*//.*$', '', s)
obj = json.loads(s)
bundle = obj['bundles'][0]['id']
with open(out_path, 'w', encoding='utf-8') as out:
    for a in obj['bundles'][0].get('assets', []):
        path = a.get('path')
        if path:
            out.write(f"{bundle}:{path}\n")
print(f'WROTE {out_path}')
