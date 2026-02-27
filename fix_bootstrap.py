#!/usr/bin/env python3
"""
Script post-build : corrige flutter_bootstrap.js après chaque flutter build web
- Supprime les objets {} vides dans le tableau builds
- Ajoute useLocalCanvasKit: true pour éviter les dépendances gstatic.com
"""
import re, json, sys

path = "build/web/flutter_bootstrap.js"
try:
    with open(path, "r") as f:
        content = f.read()
except FileNotFoundError:
    print(f"⚠️  {path} non trouvé, skip")
    sys.exit(0)

match = re.search(r'(_flutter\.buildConfig\s*=\s*)(\{.*?\});', content, re.DOTALL)
if not match:
    print("⚠️  buildConfig non trouvé dans flutter_bootstrap.js")
    sys.exit(0)

cfg = json.loads(match.group(2))
original_builds = len(cfg.get('builds', []))

# Supprimer les objets vides
cfg['builds'] = [b for b in cfg.get('builds', []) if b]

# Ajouter useLocalCanvasKit à chaque build
for build in cfg['builds']:
    build['useLocalCanvasKit'] = True

new_content = content.replace(
    match.group(0),
    match.group(1) + json.dumps(cfg) + ';'
)

with open(path, 'w') as f:
    f.write(new_content)

removed = original_builds - len(cfg['builds'])
print(f"✅ flutter_bootstrap.js corrigé (builds vides supprimés: {removed}, useLocalCanvasKit: True)")
