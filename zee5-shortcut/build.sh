#!/bin/bash
# Build the Zee5 shortcut APK.
#
# Requirements:
#   - JDK (javac, keytool)
#   - Android SDK with build-tools 34.0.0 and platforms/android-28
#     (or the local ./tools/sdk used during the original build)
#
# Usage:
#   ./build.sh
#   ANDROID_SDK=/path/to/sdk ./build.sh
set -euo pipefail
cd "$(dirname "$0")"

SDK="${ANDROID_SDK:-$HOME/Library/Android/sdk}"
if [ ! -d "$SDK/build-tools" ]; then
  SDK="$(cd .. && pwd)/tools/sdk"
fi

BT="$SDK/build-tools/34.0.0"
AJ="$SDK/platforms/android-28/android.jar"

if [ ! -x "$BT/aapt" ] || [ ! -f "$AJ" ]; then
  echo "Android SDK not found (need build-tools;34.0.0 and platforms;android-28)." >&2
  echo "Set ANDROID_SDK or install them with sdkmanager." >&2
  exit 1
fi

# The icon is committed; fall back to extracting it from a pulled Zee5 APK.
if [ ! -f res/mipmap-xxxhdpi/ic_launcher.png ]; then
  if [ -f ../zee5-base.apk ]; then
    mkdir -p res/mipmap-xxxhdpi
    unzip -p ../zee5-base.apk res/mipmap-xxxhdpi-v4/ic_launcher.png \
      > res/mipmap-xxxhdpi/ic_launcher.png
  else
    echo "Missing res/mipmap-xxxhdpi/ic_launcher.png" >&2
    exit 1
  fi
fi

rm -rf build
mkdir -p build/classes build/dex

echo "==> compile"
javac -source 8 -target 8 -bootclasspath "$AJ" -d build/classes \
  src/com/tvdebloat/zee5shortcut/MainActivity.java

echo "==> dex"
"$BT/d8" --lib "$AJ" --min-api 21 --output build/dex \
  build/classes/com/tvdebloat/zee5shortcut/MainActivity.class

echo "==> package"
"$BT/aapt" package -f -M AndroidManifest.xml -S res -I "$AJ" -F build/unsigned.apk
(cd build/dex && zip -q -j ../unsigned.apk classes.dex)

echo "==> align + sign"
"$BT/zipalign" -f 4 build/unsigned.apk build/aligned.apk
if [ ! -f build/debug.keystore ]; then
  keytool -genkeypair -keystore build/debug.keystore -alias androiddebugkey \
    -storepass android -keypass android -keyalg RSA -keysize 2048 \
    -validity 10000 -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
fi
"$BT/apksigner" sign --ks build/debug.keystore --ks-pass pass:android \
  --key-pass pass:android --ks-key-alias androiddebugkey \
  --out zee5-shortcut.apk build/aligned.apk
"$BT/apksigner" verify --print-certs zee5-shortcut.apk | head -3

echo
echo "Built: $(pwd)/zee5-shortcut.apk"
echo "Install: adb install -r zee5-shortcut.apk"
