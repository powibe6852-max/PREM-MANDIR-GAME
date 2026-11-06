# Prem Mandir Diwali Mela 3D — APK build

1. Is zip ko apni repo me extract karo (root me) aur push karo (`main` branch).
2. GitHub → **Actions** tab → "Build Prem Mandir APK" apne aap chalega (ya "Run workflow").
3. 8-15 min baad: **Releases** me `PremMandirDiwali.apk` milegi (ya Actions run → Artifacts).
4. APK phone me install karo ("Install unknown apps" allow karna padega).

## Game update karna
- Naya HTML aaye to `game/index.html` naam se rakh do (ye parts se pehle use hota hai)
  aur purane `game/part_*` delete kar do. Note: GitHub web upload 25MB tak hi leta hai,
  isliye bade file ke liye git push / parts use karo.
- Ya `split -b 20M -d -a 3 naya.html game/part_` se parts bana lo.

## Notes
- App ID: `com.premmandir.diwali`, debug-signed APK (direct install ke liye).
- Mic permission voice chat ke liye, fullscreen + screen-on enabled.
- three.js/GLTFLoader/PeerJS build time pe download hote hain; multiplayer ke liye internet chahiye.
