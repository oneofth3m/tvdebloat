#!/bin/bash
# Back up everything we are about to remove/disable on the TV.
set -uo pipefail
cd "$(dirname "$0")"

STAMP=$(date +%Y%m%d-%H%M%S)
B="backups/$STAMP"
mkdir -p "$B/apks"

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
com.graymatrix.did
com.hungama.movies.xtv
com.mitv.tvhome.mitvplus
co.sensara.tv.mitv"

echo "Backup dir: $B"

adb wait-for-device
adb shell pm list packages -f > "$B/packages-before.txt"
adb shell settings list global > "$B/settings-global-before.txt"
adb shell settings list secure > "$B/settings-secure-before.txt"
adb shell settings list system > "$B/settings-system-before.txt"
adb shell dumpsys package > "$B/dumpsys-package-before.txt" 2>/dev/null
adb shell dumpsys meminfo > "$B/meminfo-before.txt" 2>/dev/null

for p in $REMOVE; do
  mkdir -p "$B/apks/$p"
  paths=$(adb shell pm path "$p" | sed 's/^package://' | tr -d '\r')
  if [ -z "$paths" ]; then
    echo "WARN: no apk path for $p"
    continue
  fi
  while IFS= read -r ap; do
    [ -z "$ap" ] && continue
    out="$B/apks/$p/$(basename "$ap")"
    if adb pull "$ap" "$out" >/dev/null 2>&1; then
      echo "ok  $p/$(basename "$ap")"
    else
      echo "WARN: failed to pull $ap"
    fi
  done <<< "$paths"
done

echo "$STAMP" > backups/LATEST
echo "Done -> $B"
