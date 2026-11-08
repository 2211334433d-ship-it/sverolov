#!/usr/bin/env bash
# Собирает Android-приложение «Сферолов» из index.html.
# Запускается автоматически на GitHub через .github/workflows/build.yml
set -euo pipefail

SRC=""
for f in index.html sferolov.html; do
  if [ -f "$f" ]; then SRC="$f"; break; fi
done
if [ -z "$SRC" ]; then echo "Не найден index.html с игрой" >&2; exit 1; fi

P=android
M=$P/app/src/main
J=$M/java/ru/sferolov/game
mkdir -p "$M/assets" "$J" "$M/res/values" "$M/res/values-night" "$M/res/drawable" "$M/res/mipmap-anydpi-v26"

# Игра без онлайн-шрифтов, чтобы работала без интернета
grep -v -e 'fonts.googleapis.com' -e 'fonts.gstatic.com' "$SRC" > "$M/assets/index.html"

cat > "$P/settings.gradle" <<'EOF'
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositories { google(); mavenCentral() }
}
rootProject.name = 'Sferolov'
include ':app'
EOF

cat > "$P/build.gradle" <<'EOF'
plugins { id 'com.android.application' version '8.5.2' apply false }
EOF

cat > "$P/gradle.properties" <<'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
EOF

cat > "$P/app/build.gradle" <<'EOF'
plugins { id 'com.android.application' }

android {
    namespace = 'ru.sferolov.game'
    compileSdk = 34
    defaultConfig {
        applicationId = 'ru.sferolov.game'
        minSdk = 26
        targetSdk = 34
        versionCode = (System.getenv('GITHUB_RUN_NUMBER') ?: '1') as int
        versionName = '1.' + (System.getenv('GITHUB_RUN_NUMBER') ?: '0')
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
EOF

cat > "$M/AndroidManifest.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher"
        android:label="Сферолов"
        android:theme="@style/AppTheme">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait"
            android:configChanges="orientation|screenSize|keyboardHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat > "$J/MainActivity.java" <<'EOF'
package ru.sferolov.game;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private WebView web;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);   // сохранение коллекции
        s.setTextZoom(100);             // крупный шрифт системы не ломает экран
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setWebViewClient(new WebViewClient());
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
    }

    @Override protected void onPause() { web.onPause(); super.onPause(); }
    @Override protected void onResume() { super.onResume(); web.onResume(); }
    @Override protected void onDestroy() { web.destroy(); super.onDestroy(); }
}
EOF

cat > "$M/res/values/colors.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="bg">#EEF3EC</color>
</resources>
EOF

cat > "$M/res/values-night/colors.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="bg">#0E1411</color>
</resources>
EOF

cat > "$M/res/values/styles.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="android:Theme.Material.Light.NoActionBar">
        <item name="android:windowBackground">@color/bg</item>
        <item name="android:statusBarColor">@color/bg</item>
        <item name="android:navigationBarColor">@color/bg</item>
        <item name="android:windowLightStatusBar">true</item>
        <item name="android:windowLightNavigationBar">true</item>
    </style>
</resources>
EOF

cat > "$M/res/values-night/styles.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="android:Theme.Material.NoActionBar">
        <item name="android:windowBackground">@color/bg</item>
        <item name="android:statusBarColor">@color/bg</item>
        <item name="android:navigationBarColor">@color/bg</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:windowLightNavigationBar">false</item>
    </style>
</resources>
EOF

# Иконка: золотая сфера с кольцом на фоне неба и травы
cat > "$M/res/drawable/ic_bg.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M0,0 L108,0 L108,108 L0,108 Z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="linear" android:startX="0" android:startY="0" android:endX="0" android:endY="108">
                <item android:offset="0" android:color="#FF8CCAF2" />
                <item android:offset="0.7" android:color="#FFE2F4FF" />
            </gradient>
        </aapt:attr>
    </path>
    <path android:pathData="M0,76 Q54,62 108,76 L108,108 L0,108 Z" android:fillColor="#FF6CB65F" />
</vector>
EOF

cat > "$M/res/drawable/ic_fg.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M28,54 a26,26 0 1,0 52,0 a26,26 0 1,0 -52,0 Z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="radial" android:centerX="54" android:centerY="54" android:gradientRadius="26">
                <item android:offset="0.55" android:color="#99FFD34D" />
                <item android:offset="1" android:color="#00FFD34D" />
            </gradient>
        </aapt:attr>
    </path>
    <group android:rotation="-22" android:pivotX="54" android:pivotY="54">
        <path android:pathData="M28,54 A26,7 0 0,1 80,54"
            android:strokeColor="#B3FFE07A" android:strokeWidth="3.5" android:strokeLineCap="round" />
    </group>
    <path android:pathData="M37,54 a17,17 0 1,0 34,0 a17,17 0 1,0 -34,0 Z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="radial" android:centerX="48" android:centerY="47" android:gradientRadius="22">
                <item android:offset="0" android:color="#FFFFF7CC" />
                <item android:offset="0.6" android:color="#FFF2B632" />
                <item android:offset="1" android:color="#FF8F6100" />
            </gradient>
        </aapt:attr>
    </path>
    <path android:pathData="M44,47 a4,2.4 0 1,0 8,0 a4,2.4 0 1,0 -8,0 Z" android:fillColor="#CCFFFFFF" />
    <group android:rotation="-22" android:pivotX="54" android:pivotY="54">
        <path android:pathData="M80,54 A26,7 0 0,1 28,54"
            android:strokeColor="#FFFFE07A" android:strokeWidth="3.5" android:strokeLineCap="round" />
    </group>
</vector>
EOF

cat > "$M/res/mipmap-anydpi-v26/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_bg" />
    <foreground android:drawable="@drawable/ic_fg" />
</adaptive-icon>
EOF

(cd "$P" && gradle assembleDebug --no-daemon --stacktrace)
cp "$P/app/build/outputs/apk/debug/app-debug.apk" Sferolov.apk
echo "Готово: Sferolov.apk"
