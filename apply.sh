#!/bin/bash
# Debloat + tune the Mi TV (reversible via ./restore.sh)
set -uo pipefail
cd "$(dirname "$0")"

REMOVE="com.viacom18.tv.voot
com.viacom18.atv.vootkids
com.google.android.youtube.tvkids
com.google.android.music
com.google.android.play.games
com.google.android.videos
com.mxtech.videoplayer.television
tv.hooq.androidxiaomi
com.firestick.shemaroome
com.eros.mitv
com.balaji.alt.partner
com.epicchannel.epicon.mi
com.hungama.movies.xtv
com.mitv.tvhome.mitvplus
co.sensara.tv.mitv"

DISABLE="android.autoinstalls.config.xioami.dangal
com.google.android.onetimeinitializer
com.android.onetimeinitializer
com.google.android.tungsten.setupwraith
com.google.android.partnersetup
com.google.android.feedback
com.google.android.syncadapters.calendar
com.google.android.tv.bugreportsender
com.android.sharedstoragebackup
com.android.printspooler
com.android.camera2
com.android.smspush
com.android.dreams.basic
com.mitv.dream
com.google.android.backdrop
com.google.android.tvrecommendations
com.google.android.leanbacklauncher.recommendations
com.miui.tv.analytics
com.xiaomi.statistic
com.xiaomi.mitv.handbook
com.xm.webcontent
com.xiaomo.tv.milegal
com.mitv.milinkservice
com.xiaomi.mitv.smartshare
com.xiaomi.floatingframe
com.xiaomi.mitv.updateservice
com.mitv.tvhome.atv
com.xiaomi.mimusic2
com.mitv.gallery
com.android.gallery3d
com.zee5.xiaomiTV"

echo "== Removing unused apps =="
for p in $REMOVE; do
  out=$(adb shell pm uninstall --user 0 "$p" 2>&1 | tr -d '\r')
  echo "$p -> $out"
done

echo
echo "== Disabling bloat / telemetry =="
for p in $DISABLE; do
  out=$(adb shell pm disable-user --user 0 "$p" 2>&1 | tr -d '\r')
  echo "$p -> $out"
done

echo
echo "== UI + power tweaks =="
adb shell settings put global window_animation_scale 0.5
adb shell settings put global transition_animation_scale 0.5
adb shell settings put global animator_duration_scale 0.5
adb shell settings put secure screensaver_enabled 0
adb shell settings put global wifi_scan_always_enabled 0
adb shell settings put global development_settings_enabled 1

echo "== Trimming caches =="
adb shell pm trim-caches 4096M
adb shell 'df -h /data'

echo
echo "== Remaining third-party apps =="
adb shell 'cmd package list packages -3' | sed 's/package://' | sort
