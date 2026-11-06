#!/usr/bin/env bash
set -euo pipefail
rm -rf www && mkdir -p www/libs
if [ -f game/index.html ]; then
  cp game/index.html www/index.html
else
  cat game/part_* > www/index.html
fi
echo "index.html size: $(du -h www/index.html | cut -f1)"

# Download JS libs so the game works with less internet dependency (PeerJS multiplayer still needs internet)
ok=1
curl -fsSL --retry 3 -o www/libs/three.min.js https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js || ok=0
curl -fsSL --retry 3 -o www/libs/GLTFLoader.js https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js || ok=0
curl -fsSL --retry 3 -o www/libs/peerjs.min.js https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js || ok=0
if [ "$ok" = "1" ]; then
python3 - <<'PY'
p="www/index.html"
s=open(p,encoding="utf-8").read()
for a,b in [
 ("https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js","libs/three.min.js"),
 ("https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js","libs/GLTFLoader.js"),
 ("https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js","libs/peerjs.min.js")]:
    s=s.replace(a,b)
open(p,"w",encoding="utf-8").write(s)
print("CDN libs localised")
PY
else
  echo "WARNING: lib download failed, keeping CDN links"
  rm -rf www/libs
fi
