#!/usr/bin/env bash
set -Eeuo pipefail
A=android/app/src/main

python3 - <<'PY'
p="android/app/src/main/AndroidManifest.xml"
s=open(p,encoding="utf-8").read()
perms=""
for n in ["RECORD_AUDIO","MODIFY_AUDIO_SETTINGS","VIBRATE","WAKE_LOCK"]:
    if f"android.permission.{n}" not in s:
        perms+=f'    <uses-permission android:name="android.permission.{n}" />\n'
if "android.hardware.microphone" not in s:
    perms+='    <uses-feature android:name="android.hardware.microphone" android:required="false" />\n'
s=s.replace("</manifest>",perms+"</manifest>")
attrs=""
if "android:largeHeap" not in s: attrs+=' android:largeHeap="true"'
if "android:hardwareAccelerated" not in s: attrs+=' android:hardwareAccelerated="true"'
s=s.replace("<application","<application"+attrs,1)
if "android:screenOrientation" not in s:
    s=s.replace("<activity",'<activity android:screenOrientation="fullUser"',1)
open(p,"w",encoding="utf-8").write(s)
print("manifest patched")
PY

# icons (legacy png icons for every density)
rm -rf $A/res/mipmap-anydpi-v26
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  mkdir -p $A/res/mipmap-$d
  cp resources/android/mipmap-$d/*.png $A/res/mipmap-$d/
done

# fullscreen + keep screen on
D=$A/java/com/premmandir/diwali
mkdir -p "$D"
cat > "$D/MainActivity.java" <<'JAVA'
package com.premmandir.diwali;

import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        hideBars();
    }
    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideBars();
    }
    private void hideBars() {
        getWindow().getDecorView().setSystemUiVisibility(
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            | View.SYSTEM_UI_FLAG_FULLSCREEN
            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    }
}
JAVA

# gradle memory: replace existing line, always start on a fresh line
GP=android/gradle.properties
touch "$GP"
sed -i '/^org\.gradle\.jvmargs/d' "$GP"
printf '\norg.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8\n' >> "$GP"
echo "patch done"
