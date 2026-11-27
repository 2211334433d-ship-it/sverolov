#!/usr/bin/env bash
# Собирает Android-приложение «Сферолов» из index.html.
# Запускается автоматически на GitHub через .github/workflows/build.yml
set -euo pipefail

# Берём HTML-файл игры с самой новой версией (метка sferolov-version внутри файла),
# поэтому имя файла не важно: index.html, index (1).html, sferolov-4.html и т. д.
SRC=""; BEST=-1
for f in *.html; do
  [ -f "$f" ] || continue
  v=$(grep -o 'name="sferolov-version" content="[0-9]*"' "$f" | grep -o '[0-9][0-9]*' | head -n 1 || true)
  v=${v:-0}
  if [ "$v" -gt "$BEST" ]; then BEST=$v; SRC="$f"; fi
done
if [ -z "$SRC" ]; then echo "Не найден HTML-файл с игрой" >&2; exit 1; fi
echo "Собираю игру из файла: $SRC (версия $BEST)"

P=android
M=$P/app/src/main
J=$M/java/ru/sferolov/game
mkdir -p "$M/assets" "$J" "$M/res/values" "$M/res/values-night" "$M/res/drawable" "$M/res/drawable-nodpi" "$M/res/mipmap-anydpi-v26" "$M/res/mipmap-anydpi-v33"

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
    signingConfigs {
        stable {
            storeFile = file('sferolov.p12')
            storeType = 'pkcs12'
            storePassword = 'sferolov123'
            keyAlias = 'sferolov'
            keyPassword = 'sferolov123'
        }
    }
    buildTypes {
        debug { signingConfig = signingConfigs.stable }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
EOF

# Постоянный ключ подписи: новые версии ставятся поверх старой без удаления
base64 -d > "$P/app/sferolov.p12" <<'EOF'
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
XPsm8FmMWI8LOoXcrOHp7aOiNWQCAwGGoA==
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

    // «Назад» сначала закрывает открытый раздел или окно игры, а на охоте сворачивает игру
    @Override
    public void onBackPressed() {
        web.evaluateJavascript("(window.sferolovBack && window.sferolovBack()) ? 'closed' : 'none'", value -> {
            if (value == null || !value.contains("closed")) MainActivity.super.onBackPressed();
        });
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

# Иконка: Пухляш ★★★ в венке и радужная сфера на ярком сине-фиолетовом фоне с лучами.
# Нарисована кодом самой игры (те же зверьки и сферы). Фон — вектор, чёткий на любом экране,
# передний слой — картинка WebP 432×432, одноцветный слой — для «тематических значков» Android 13+.
cat > "$M/res/drawable/ic_bg.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<!-- Фон иконки: сине-фиолетовое небо, лучи из центра, свечение за зверьком и затемнение по краям -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:aapt="http://schemas.android.com/aapt"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M0,0 L108,0 L108,108 L0,108 Z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="radial" android:centerX="54.00" android:centerY="50.76" android:gradientRadius="77.76">
                <item android:offset="0.056" android:color="#FFB8FBFF" />
                <item android:offset="0.320" android:color="#FF45A3FF" />
                <item android:offset="0.736" android:color="#FF5A2BE0" />
                <item android:offset="1.000" android:color="#FF3A0F9E" />
            </gradient>
        </aapt:attr>
    </path>
    <path android:fillColor="#1FFFFFFF" android:pathData="M54.00,49.68 L214.00,49.68 L210.93,80.89 Z M54.00,49.68 L201.82,110.91 L187.04,138.57 Z M54.00,49.68 L167.14,162.82 L142.89,182.72 Z M54.00,49.68 L115.23,197.50 L85.21,206.61 Z M54.00,49.68 L54.00,209.68 L22.79,206.61 Z M54.00,49.68 L-7.23,197.50 L-34.89,182.72 Z M54.00,49.68 L-59.14,162.82 L-79.04,138.57 Z M54.00,49.68 L-93.82,110.91 L-102.93,80.89 Z M54.00,49.68 L-106.00,49.68 L-102.93,18.47 Z M54.00,49.68 L-93.82,-11.55 L-79.04,-39.21 Z M54.00,49.68 L-59.14,-63.46 L-34.89,-83.36 Z M54.00,49.68 L-7.23,-98.14 L22.79,-107.25 Z M54.00,49.68 L54.00,-110.32 L85.21,-107.25 Z M54.00,49.68 L115.23,-98.14 L142.89,-83.36 Z M54.00,49.68 L167.14,-63.46 L187.04,-39.21 Z M54.00,49.68 L201.82,-11.55 L210.93,18.47 Z" />
    <path android:pathData="M0,0 L108,0 L108,108 L0,108 Z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="radial" android:centerX="54.00" android:centerY="50.76" android:gradientRadius="38.88">
                <item android:offset="0" android:color="#6BFFFFFF" />
                <item android:offset="1" android:color="#00FFFFFF" />
            </gradient>
        </aapt:attr>
    </path>
    <path android:pathData="M0,0 L108,0 L108,108 L0,108 Z">
        <aapt:attr name="android:fillColor">
            <gradient android:type="radial" android:centerX="54" android:centerY="54" android:gradientRadius="66.96">
                <item android:offset="0.484" android:color="#0019055A" />
                <item android:offset="1" android:color="#8019055A" />
            </gradient>
        </aapt:attr>
    </path>
</vector>
EOF

base64 -d > "$M/res/drawable-nodpi/ic_fg.webp" <<'EOF'
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
mFPKhKf3TAAAPwKwBI94WgAAAAACR6Ed0AAA
EOF

base64 -d > "$M/res/drawable-nodpi/ic_mono.png" <<'EOF'
iVBORw0KGgoAAAANSUhEUgAAAbAAAAGwCAQAAABiR/ihAAAtKUlEQVR42u2dd7hcVbn/P+/ee04S
Qg0gIVFI6CR0RKT8uNKRZoOLBVERvcVrxXbvtaEPil4Fy8UucCMqigoqREgCKNIRUITQg4BAEgiQ
fs6Zvdf398fsmTNzWk7Zp828n3n0CafN3nvWd71lvetd4DiO4ziO4ziO4ziO4ziO4ziO4ziO4ziO
4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO
4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO
4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO
4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO
4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4zhNjPkj2DCqPSWTPw3HKVZeSf2/FTflPUaK
/JN2CzYGA88CgDbOTdlakDWTHatMGJbl/1Llfh1nlAafYp2j27RCz+sFLdV3dCwoVlNMTLLqfWhX
zehprx1npOV1kO5Wdy4AJRNfYhWnUEfqm7pW0guar09qv3rZOc6IDj+9WisldSpTyF9llSWdD4on
cjQmUwk0XTd2mzxSfbzyfR8BzsgG/abZeklSuYcF65T09XyYTsjUQMUN1Da6T1JZqVJJQanKyiT9
RKVmcYKdcTsEFem7uZh6kkr6g47tShJMqKkjAm2h0/S3Xu4vqF3SVzwWc0baPdxaHQrqi1SStFDb
TyyJVa5VH9FTkqSslzsLSrVGM6oxmuOMiAulM2sy6ktimaTVOmGiSKzi0Gp3LZKk3B3sjXI1kVOk
w+2jyukaECXQ//TpIDbasVSvnwiJ+zxn+DGtkNTZj22WMgU96aOgGNwN6Iv2AfxMTMC4QvMsY1wn
t5VY0DTdxFeYRkZpAwUGRmeR1kuH6BWtmpl0gfU5Mgb4/IyMt+tnFhi3jpBiS7Ul13IIKWIgDm1x
d2ImzuHltGjVkAus12BeEVMGOoCIKfNm/cSy8TlLq2SZTuN+XklGMtBhXsydyJC2YDbHALGPNac2
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
vMI+Iqq3NvX/rW05iN3Zg4MITGJGw995lnYibudeHuJme7a3v+UCcyaatI9kYZ4CHy73soirud+W
5e6v6oWhCKs6xKAIsRHH1o0dsYC1WG1NzYhdWi6wCe6eEjGJ+3lFzV4OPQ6rinQZN7GIW+xeUIK6
RFWTWUTWt3AUERMaxek4EzfNgr437BLdSilWp9prpVvr9EPt2hXt9eYSy5Q0vPK1PcdpphRLpBn6
e78SC8ryyv2Q/7vy/6kypf0uJC/SOzTZn7K7iK0sscRSncYlTCbrUbiV0ZV86Y/nEcatLGMOd1Hm
eBawnmm8k4y/cBXXcHdXdOW4wFrMilnQTlzMoX38wFoeArZmCluS8SQvsS3PUyYQcQ+38g/+hCFb
Vy9aAE0CpjKFtfaSrHmb0rjAnA1KDPQ63spxbFT78otcz53cwVJ7BLQZG7E1GY/bOm1lz/eanjDL
lGBWVoIhS/3ZusCcijhkAm1Tt1myvSojRVC/rmWhtpfYqLXyMVX2ClT/vytl4bbLBeagGGu0Ofmp
lrKQi8UAmdzdc4E5QxNZ/XqYXEaO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO
4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO
4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO
4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO4ziO
4ziO4ziO4ziO4ziO4ziO4ziO4ziO4zity/8Hl84yydItG60AAAAASUVORK5CYII=
EOF

cat > "$M/res/mipmap-anydpi-v26/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_bg" />
    <foreground android:drawable="@drawable/ic_fg" />
</adaptive-icon>
EOF

cat > "$M/res/mipmap-anydpi-v33/ic_launcher.xml" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_bg" />
    <foreground android:drawable="@drawable/ic_fg" />
    <monochrome android:drawable="@drawable/ic_mono" />
</adaptive-icon>
EOF

(cd "$P" && gradle assembleDebug --no-daemon --stacktrace)
cp "$P/app/build/outputs/apk/debug/app-debug.apk" Sferolov.apk
echo "Готово: Sferolov.apk"
