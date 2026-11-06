#!/usr/bin/env bash
set -euo pipefail
A=android/app/src/main
M=$A/AndroidManifest.xml

# Permissions (mic for voice chat) + big heap for the 90MB game
python3 - <<'PY'
p="android/app/src/main/AndroidManifest.xml"
s=open(p).read()
perms='''    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-feature android:name="android.hardware.microphone" android:required="false" />
'''
if "RECORD_AUDIO" not in s:
    s=s.replace("</manifest>",perms+"</manifest>")
s=s.replace("<application","<application android:largeHeap=\"true\" android:hardwareAccelerated=\"true\"",1)
s=s.replace("<activity","<activity android:screenOrientation=\"fullUser\"",1) if "screenOrientation" not in s else s
open(p,"w").write(s)
PY

# Icons
rm -rf $A/res/mipmap-anydpi-v26
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  mkdir -p $A/res/mipmap-$d
  cp resources/android/mipmap-$d/*.png $A/res/mipmap-$d/
done

# Fullscreen immersive MainActivity
PKG_DIR=$A/java/com/premmandir/diwali
mkdir -p $PKG_DIR
cat > $PKG_DIR/MainActivity.java <<'JAVA'
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

# Gradle memory for the huge asset
echo "org.gradle.jvmargs=-Xmx4g -Dfile.encoding=UTF-8" >> android/gradle.properties
echo "android.enableJetifier=false" >> android/gradle.properties
