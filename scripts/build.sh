#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
mkdir -p logs out
stage(){ printf '\n========== %s ==========\n' "$*"; }
trap 'echo "!!! FAILED at line $LINENO: $BASH_COMMAND"' ERR
trap 'c=$?; cp -r android/app/build/reports logs/gradle-reports 2>/dev/null || true; echo "build.sh exit code: $c"' EXIT

stage "ENVIRONMENT"
date -u; node -v; npm -v; (java -version 2>&1 | head -2) || true
echo "ANDROID_HOME=${ANDROID_HOME:-unset}"
ls "${ANDROID_HOME:-/nonexistent}/platforms" 2>&1 | head -5 || true
ls "${ANDROID_HOME:-/nonexistent}/build-tools" 2>&1 | head -5 || true
df -h . | tail -1; free -m | head -2

stage "ANDROID SDK CHECK"
SDKM="${ANDROID_HOME:-/nonexistent}/cmdline-tools/latest/bin/sdkmanager"
if [ -x "$SDKM" ]; then
  set +o pipefail
  yes | "$SDKM" --licenses >/dev/null 2>&1 || true
  "$SDKM" "platforms;android-34" "build-tools;34.0.0" 2>&1 | tail -3 || true
  set -o pipefail
else
  echo "sdkmanager not found, skipping"
fi

stage "GAME FILES"
if [ -f game/index.html ]; then
  echo "game/index.html found -> splitting into web/"
  python3 tools/split_game.py game/index.html web
fi
test -f web/index.html
rm -rf www; mkdir -p www; cp -r web/. www/
echo "index.html bytes: $(stat -c%s www/index.html)"; du -sh www

stage "LOCALISE JS LIBS (optional, falls back to CDN)"
mkdir -p www/libs
ok=1
get(){ curl -fsSL --retry 3 --max-time 120 -o "$2" "$1" && [ "$(stat -c%s "$2")" -gt 10000 ]; }
get https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js www/libs/three.min.js || ok=0
get https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js www/libs/GLTFLoader.js || ok=0
get https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js www/libs/peerjs.min.js || ok=0
if [ "$ok" = "1" ]; then
python3 - <<'PY'
p="www/index.html"
s=open(p,encoding="utf-8",newline="").read()
for a,b in [
 ("https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js","libs/three.min.js"),
 ("https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js","libs/GLTFLoader.js"),
 ("https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js","libs/peerjs.min.js")]:
    s=s.replace(a,b)
open(p,"w",encoding="utf-8",newline="").write(s)
print("CDN libs localised")
PY
else
  echo "WARNING: lib download failed -> keeping CDN links (internet needed in app)"
  rm -rf www/libs
fi

stage "NPM INSTALL"
npm install --no-audit --no-fund

stage "CAP ADD ANDROID"
npx cap add android

stage "PATCH ANDROID"
bash scripts/patch_android.sh

stage "CAP SYNC"
npx cap sync android

stage "GRADLE assembleDebug"
cd android
chmod +x gradlew
./gradlew assembleDebug --no-daemon --stacktrace
cd ..

stage "COLLECT APK"
APK=android/app/build/outputs/apk/debug/app-debug.apk
test -f "$APK"
cp "$APK" out/PremMandirDiwali.apk
ls -lh out
echo "BUILD OK"
