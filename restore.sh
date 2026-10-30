#!/bin/bash
# Restore the TV to its pre-debloat state.
# Usage: ./restore.sh            # restore latest backup
#        ./restore.sh 20261030-123456
set -uo pipefail
cd "$(dirname "$0")"

STAMP=${1:-$(cat backups/LATEST 2>/dev/null)}
B="backups/$STAMP"
if [ -z "$STAMP" ] || [ ! -d "$B" ]; then
  echo "No backup found. Run ./backup.sh first."
  exit 1
fi

echo "Restoring from $B"
adb wait-for-device

# Restore the stock launcher as default and drop Projectivy from Home
adb shell pm enable --user 0 com.google.android.tvlauncher >/dev/null 2>&1
adb shell pm set-home-activity com.google.android.tvlauncher/.MainActivity >/dev/null 2>&1
adb shell am force-stop com.spocky.projengmenu >/dev/null 2>&1
# adb uninstall com.spocky.projengmenu   # uncomment to remove Projectivy entirely

# Re-enable system packages
for p in \
  android.autoinstalls.config.xioami.dangal \
  com.google.android.onetimeinitializer \
  com.android.onetimeinitializer \
  com.google.android.tungsten.setupwraith \
  com.google.android.partnersetup \
  com.google.android.feedback \
  com.google.android.syncadapters.calendar \
  com.google.android.tv.bugreportsender \
  com.android.sharedstoragebackup \
  com.android.printspooler \
  com.android.camera2 \
  com.android.smspush \
  com.android.dreams.basic \
  com.mitv.dream \
  com.google.android.backdrop \
  com.google.android.tvrecommendations \
  com.google.android.leanbacklauncher.recommendations \
  com.miui.tv.analytics \
  com.xiaomi.statistic \
  com.xiaomi.mitv.handbook \
  com.xm.webcontent \
  com.xiaomo.tv.milegal \
  com.mitv.milinkservice \
  com.xiaomi.mitv.smartshare \
  com.xiaomi.floatingframe \
  com.xiaomi.mitv.updateservice \
  com.mitv.tvhome.atv \
  com.xiaomi.mimusic2 \
  com.mitv.gallery \
  com.android.gallery3d \
  com.zee5.xiaomiTV ; do
  adb shell pm enable --user 0 "$p" >/dev/null 2>&1 && echo "enabled  $p"
done

# Reinstall removed apps (data apps need their APKs)
for d in "$B"/apks/*/; do
  p=$(basename "$d")
  if adb shell pm install-existing --user 0 "$p" >/dev/null 2>&1; then
    echo "restored $p (system)"
    continue
  fi
  files=("$d"*.apk)
  if [ -e "${files[0]}" ]; then
    adb install-multiple -r "${files[@]}" >/dev/null 2>&1 \
      && echo "restored $p (apk)" \
      || echo "FAILED   $p"
  fi
done

# Undo background restrictions
for p in com.aha.mitv ahaflix.tv com.jio.media.stb.ondemand com.sonyliv \
         com.suntv.sunnxt.mitv com.zee5.xiaomiTV in.startv.hotstar \
         com.amazon.amazonvideo.livingroom com.netflix.ninja ; do
  adb shell cmd appops set "$p" RUN_ANY_IN_BACKGROUND allow >/dev/null 2>&1
done

# Restore settings
adb shell settings put system screen_off_timeout 300000
adb shell settings put global animator_duration_scale 1.0
adb shell settings put global transition_animation_scale 1.0
adb shell settings put global window_animation_scale 1.0
adb shell settings put global wifi_scan_always_enabled 1
adb shell settings put secure screensaver_enabled 1

echo "Restore complete. Rebooting TV..."
adb reboot
