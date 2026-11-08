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
MIIJbwIBAzCCCSgGCSqGSIb3DQEHAaCCCRkEggkVMIIJETCCBW0GCSqGSIb3DQEHAaCCBV4EggVa
MIIFVjCCBVIGCyqGSIb3DQEMCgECoIIE+zCCBPcwKQYKKoZIhvcNAQwBAzAbBBQCgjLyli+F9DQN
/euAdbXUZYhpVQIDAMNQBIIEyNy7YJBc/lHRbhDE2amqPZvyKHNnl3k4IZQ+Nlfs16KtStB4kd1P
/5MCPchJLuf3chKn+cVQj8Fm11YnZc7Y77z223CWRf2Xzf88IBntHf7fGkn5SUEKPE+iQvMp6hru
3AeooUSK/LKie5OzotzFtI+nmN1mJLAd3Gwc1VMZr759mK9/D+kV4ZymDGR8Vmv9PYqJ5mPao3u7
7NhGthZImXYqp1mm+m4AW872MpIb3lnUWQVm09TnTgJ0WkO037uIEwRlqMMP/dIqjlj3yVIFCsKE
E7JmKZ4HEqb1RuAsq2cZLfg2zbrXuU0002cEF+6OTk9Bm1uZu0BD/pgQF0cOBwSbcfWK+kEIfWZm
RCG67TTkzBjtZwj9APCLPkYgkrVc1P/QfifCvoR8c9G2mhoGmpH0J2QB+0S1ZF8o7qqMurx0yShg
VglxTda9obwsC2t6LMMcQv/rV9HXSIM8JfhalWMIsqodSYTTwa3b3OdgX45a5KF9rrkTB9AfWlC9
s+4ZTOuAemFZXs8B/QLn4+CYcpXntkcb0hWMsx7YZJFdMy6Go/jEnFYcxp/515wWGVZNd7MIPYAc
oXG2UWBntc0tqpWPwBMcYv8cTIsUOQ1IwfohJ0RdOK9SJ6vWmW50KFRYq2w0qMYMhLNnyDdAMcRR
83W59D2aYhWNOyKHHnZ0MpBAsjIPW8b6OfMQlR8vuPuM+7lZy8OhFF7TSHlPEQxEA43KcIW6JY/0
Kw2tbU66H/1cHXcvrvm6sWTIV2ziGVKmyCB77PoKRPdE6o8GExZpfsxJBRk1hvBvxnOAKAU2Qhpv
+wWnYjSnjoihU++aiqTCZPSCNLanmncN4lvXxn1nsMIb6OsPCVbipHCoVD2rHR6Rcf/udDzjfx0E
QwuJD2Kfziw8fTSSnD4A7zp8XTpJCOqUau0gd2dZHAhJ156grr18YJHPUGPbDfkrJ5xqt6gOiwAh
Hgk62Kub208xLvnfAnbL0sLet/albgfdFkUa76BDX2pzEx876N50cDYOYegf9bzcsPS54BcWgdSl
yTPwwGkdzvmYfSbEYQDdHlO7vMD1Ln/dz+JwcNIctNAMUQu77vaGWQfJ6mGYTSnsBQOSrD7AsbLW
vyHNV0ekGN3xuYyHurRW6Kh5X586WEPRNqWiC+2hHwfjhYD7JhAiwfs1olaiDxpN06rvDjWb/rac
Oigs646PXWtYmMBggcyP8GBi6bTuuPAVZOetTeoO4gehVdYHoQw5HrFYfpxpI8Kp6RTLg3Jrf3Ig
3jzoFNrWOcqUHxIRCb5eqBcrKzA2peYhpLLkBlHi7sbdPLs3F8xIB+lg8ryFpKhegy56BkBsfTZn
IkRFhphSNXgFQGeVP+LS7IdFapevxsnbfuzkLZctkB2F/zrL2LwSIWx1vngV39N+GRRjhxnxgMoP
glCddecnNSPjYG68j96TKovGuyCESLGFUuuAezYfAT15+44urn50AfOHpPx1O7brcKuJ7WGDy9Ev
xnixSa7sHPKmXM16tDtAf9CWXmNxOlNbeL7MMZcyD4ARRdgErKcLbUDbBggZDtyZ4d9+4njG6Ehh
3VXqg6rwdA24CoVbLdixeiUpSxh1YpMdhf8z4jqdzakboMGRszpAjHe2PKxW9DFEMB8GCSqGSIb3
DQEJFDESHhAAcwBmAGUAcgBvAGwAbwB2MCEGCSqGSIb3DQEJFTEUBBJUaW1lIDE3OTQxNjAyMzk0
MDUwggOcBgkqhkiG9w0BBwagggONMIIDiQIBADCCA4IGCSqGSIb3DQEHATApBgoqhkiG9w0BDAEG
MBsEFGTdIHDhbDaYgwqgNgOoD4BxQlSqAgMAw1CAggNIwYjb4LJeMZZEd6zDvsTnoO9o3FMFOnNM
Noi6MQmhVvvgjKiKet7rCPhi67/xSdxZQ0rDV+Nnn+ZripNDGzV8Iu2ecTWluQwewNWNgnvxSWtW
1zwU5NS0WjjlzuDtgAY8D7ehNqk2CQYej3FSyTRGjEso4L2o9pwR2yM+oHZn+zzq7LUKbqY6MfD4
7qBSVddanPeE5BH0QGxMJcl5BC0i1x+LkMTuvBzQN8o1w8OtQcG7ut0MqqWBnAB1L2/er5b4sCKd
L0Xgo5vem1GaUKWWF9i8UIFans9Yt19EL8v0RaP2eCu7++ys4fuyBvFyYFPqI8HqyLHMtuqNBS/P
WnTNiOBek/NXzVTeXqP6g1x7AwkucrFeSmEuwdLOKzxtns2f1BeKcBn/7gV+7Ke2h2rgI1q5gwb4
4oDkD7tBrYy7IdmHU4iFa0fWEya2a7qP3ouuGOO+Ch4mWUZzY0wwR3IqIbZEKJGlHIgssD7PZjFu
SJSPNR/pf/3jCzHuoZyBDsY/1KXAE1PHIBHYjj820P1FaU+TqOvFh9Md5O6uxv0tzTYqQZITMct2
4rvlvFgtmtyllVzxYlfBknFBKUMA1aKEd0rMUDWhgoTkBZ6s285Is6AgYvlaOD/ZWJyaUSkMIYRi
2cGbJBUDxT4e4rrYke7tBFezIK8CxEmZyzMCjEJU78x9zsr42ku6vcxe38MKUNHSUpAZFQ5RbyDM
leEbMf+BI/rNcPnuIfxf4QtLs/AQBumWzDAcgWu1XQ6u/q5DeRMTlQ7JxB8D/2b92Es+oX7pTGPd
AfiyB1kHp+Uj2Frh015pttcJ3sgaPIcXQZkmbRR/X346UuwKi8dK30YKeYGo33VpYVUsByeD1oal
I9QRL50cfXksAs4ryKYRcWezYEA+RLdI3SXLXRpMW6olUc8n+8j9wxwJL1vi40Z2WJftkePd85g+
LSCjDgwXQ2/AH95IpfEV+cmK07X3sE3+WvbpNDk9TRJsCI+7oMdtKlzr+VWqcTT358/H9NPuEoNv
38/NA+hYc7JoXNzUs0O/2fTMwtFdIRenPdYpOCpuJggdheL0UQCtoXN5y+aAxuutfzp+MKNaeO72
xQxd9vwnqdpRgavRSl5B5NMGMD4wITAJBgUrDgMCGgUABBQoL+GVHXIHH95E1wWdv4Ao394I9wQU
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
