#!/bin/bash
# Patch à appliquer après chaque flutter build web
BUILD_DIR="/home/user/flutter_app/build/web"

echo "🔧 Patching Flutter web build..."

# 1. Corriger buildConfig (supprimer objet vide)
python3 -c "
import re
content = open('$BUILD_DIR/flutter_bootstrap.js').read()
content = content.replace(
    '\"builds\":[{\"compileTarget\":\"dart2js\",\"renderer\":\"canvaskit\",\"mainJsPath\":\"main.dart.js\"},{}]',
    '\"builds\":[{\"compileTarget\":\"dart2js\",\"renderer\":\"canvaskit\",\"mainJsPath\":\"main.dart.js\"}]'
)
# Forcer canvasKitBaseUrl local
m = re.search(r'serviceWorkerVersion: \"(\w+)\"', content)
if m:
    ver = m.group(1)
    old = f'_flutter.loader.load({{\n  serviceWorkerSettings: {{\n    serviceWorkerVersion: \"{ver}\"\n  }}\n}});'
    new = f'_flutter.loader.load({{\n  config: {{\n    renderer: \"canvaskit\",\n    canvasKitBaseUrl: \"canvaskit/\"\n  }}\n}});'
    content = content.replace(old, new)
open('$BUILD_DIR/flutter_bootstrap.js','w').write(content)
print('  ✅ flutter_bootstrap.js patché')
"

# 2. Neutraliser le service worker
cat > $BUILD_DIR/flutter_service_worker.js << 'SW'
self.addEventListener('install', e => self.skipWaiting());
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(k => Promise.all(k.map(c => caches.delete(c)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', e => {});
SW
echo "  ✅ Service worker neutralisé"

echo "✅ Patch appliqué !"
