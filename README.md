# Prem Mandir Diwali Mela 3D — APK build (v40)

## Steps
1. Zip ko repo ke **root** me extract karo (folder ke andar nahi). Purana `game/` folder ho to delete kar do. `resources/icons` aur `web/js` folders bhi repo me hone chahiye.
   `.github/workflows/build-apk.yml` same naam ka hai, purane ko replace karega.
2. Commit + push (`main`/`master`). Actions tab me "Build Prem Mandir APK" chalega (ya Run workflow).
3. Success: **Releases** me `PremMandirDiwali.apk` (ya Actions run -> Artifacts).
4. Fail: Actions run -> Artifacts -> **build-logs** download karke bhej do (`build-full.log` me sab kuch hai).
   Run page ke Summary me error lines bhi dikhengi.

## Game update
Naya single HTML `game/index.html` naam se daal do -> build apne aap `web/` me split kar dega.
(GitHub web upload 25MB tak hi leta hai, bade file ke liye git push use karo.)
Ya khud: `python3 tools/split_game.py naya.html web`
