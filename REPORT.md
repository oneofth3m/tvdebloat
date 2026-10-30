# Mi TV AXSO0 — Debloat & Optimization Report

**Date:** 2026-10-30
**Device:** MiTV-AXSO0 (`dangal`), Android 9 (SDK 28), 1 GB RAM, 4.4 GB `/data`
**ADB:** `192.168.0.106:5555` (wireless debugging, authorized)

---

## Results

| Metric | Before | After |
|---|---|---|
| Free storage on `/data` | 753 MB (84% used) | **2.0 GB (54% used)** |
| Free RAM | 60 MB | **142 MB** |
| Available RAM (MemAvailable) | 190 MB | **397 MB** |
| Third-party apps installed | 21 | **8** (7 kept + Projectivy) |
| Disabled system packages | 0 | 31 |
| Animation scales | 1.0x | 0.5x |

~1.25 GB of storage and ~200 MB of RAM reclaimed. Home screen, Settings,
YouTube, Netflix and all kept streaming apps verified working after reboot.

---

## Launcher

The stock Xiaomi/Google TV launcher (PatchWall-flavoured, with Shop tab and
"Hero" ads) was replaced with **Projectivy Launcher 4.72** (`com.spocky.projengmenu`),
installed from the official GitHub release and verified by SHA-256.

- Projectivy is the default HOME activity.
- The stock launcher (`com.google.android.tvlauncher`) is **disabled for user 0**
  because Xiaomi keeps its home task sticky and ignores the default-home setting.
- Home key, reboot and app launching verified against Projectivy.
- HDMI 1–4 input tiles are built in.
- The **Watch Next** row was hidden; home is now just Inputs + TV Apps + wallpaper.
- Screen-off timeout raised from 5 min to **30 min** (`1800000`) so it no longer
  drops into deep standby during normal use.

### Zee5 tile
Zee5's Mi TV build (`com.zee5.xiaomiTV`) has **no launcher intent** — Xiaomi
shipped it to be opened from PatchWall content tiles, so it disappears once
PatchWall is disabled. A tiny helper app (`com.tvdebloat.zee5shortcut`, 232 KB,
source in `zee5-shortcut/`) adds a normal TV tile that starts Zee5's exported
`SplashActivity`. Verified: tile → Zee5 home screen.

`com.aha.mitv` and `com.suntv.sunnxt.mitv` have the same limitation (no launcher
intent). `aha` is still reachable through the `ahaflix.tv` package; SunNXT has no
tile. The same helper approach can add tiles for them if wanted.

### Watch Next
Re-enabled on request. It is Android TV's system-wide **Continue Watching**
row: apps publish in-progress items and recommendations through the TV provider,
so you can resume something from Netflix, Prime Video, JioCinema, YouTube, etc.
without opening each app first. It can occasionally show promoted content.
Hide it again via **Settings → Edit channels → Watch Next → Visible**.

### Everyday use
- Customize apps/order: **Settings (gear) → Edit categories / All apps**.
- Show/hide rows (Watch Next, per-app channels): **Settings → Edit channels**.
- Change wallpaper: **Settings → Projectivy settings → Wallpapers**.
- The Mi remote's battery was weak during setup; replace it (2× AAA on this
  remote) or use the **Mi Remote** phone app as a backup. A dead remote is what
  made the TV look "stuck in standby".

To go back to the stock launcher:

```bash
adb shell pm enable --user 0 com.google.android.tvlauncher
adb shell pm set-home-activity com.google.android.tvlauncher/.MainActivity
```

---

## Apps removed (16)

Uninstalled for user 0. APKs are backed up in `backups/<stamp>/apks/`.

| App | Package |
|---|---|
| Voot | `com.viacom18.tv.voot` |
| Voot Kids | `com.viacom18.atv.vootkids` |
| YouTube Kids | `com.google.android.youtube.tvkids` |
| Play Music | `com.google.android.music` |
| Play Games | `com.google.android.play.games` |
| Play Movies | `com.google.android.videos` |
| MX Player | `com.mxtech.videoplayer.television` |
| Hoichoi | `tv.hooq.androidxiaomi` |
| ShemarooMe | `com.firestick.shemaroome` |
| Eros Now | `com.eros.mitv` |
| ALT Balaji | `com.balaji.alt.partner` |
| EPIC ON | `com.epicchannel.epicon.mi` |
| Discovery+ | `com.graymatrix.did` |
| Hungama | `com.hungama.movies.xtv` |
| Mi TV+ | `com.mitv.tvhome.mitvplus` |
| Sensara | `co.sensara.tv.mitv` |

Kept: Prime Video, JioHotstar, Zee5, SonyLIV, JioCinema, aha (both packages), SunNXT, Netflix, YouTube.

## System packages disabled (30)

**Telemetry / Xiaomi extras**
`com.miui.tv.analytics`, `com.xiaomi.statistic`, `com.xiaomi.mitv.handbook`,
`com.xm.webcontent`, `com.xiaomo.tv.milegal`, `com.xiaomi.floatingframe`,
`com.xiaomi.mimusic2`, `com.mitv.gallery`, `com.android.gallery3d`

**PatchWall / casting / updates (aggressive tier)**
`com.mitv.tvhome.atv` (PatchWall), `com.mitv.milinkservice` (Mi Link),
`com.xiaomi.mitv.smartshare` (Miracast/MiPlay), `com.xiaomi.mitv.updateservice` (OTA checks)

**Recommendations / screensaver / media bloat**
`com.google.android.leanbacklauncher.recommendations`, `com.google.android.tvrecommendations`,
`com.google.android.backdrop`, `com.mitv.dream`, `com.android.dreams.basic`

**One-time / setup / diagnostics**
`android.autoinstalls.config.xioami.dangal`, `com.google.android.onetimeinitializer`,
`com.android.onetimeinitializer`, `com.google.android.tungsten.setupwraith`,
`com.google.android.partnersetup`, `com.google.android.feedback`,
`com.google.android.syncadapters.calendar`, `com.google.android.tv.bugreportsender`,
`com.android.sharedstoragebackup`, `com.android.printspooler`, `com.android.camera2`,
`com.android.smspush`

## Settings changes

```
window_animation_scale      0.5
transition_animation_scale  0.5
animator_duration_scale     0.5
screensaver_enabled         0    (screensaver + backdrop off)
wifi_scan_always_enabled    0    (no background Wi-Fi scanning)
```

Background execution (`RUN_ANY_IN_BACKGROUND`) restricted for the 8 kept streaming
apps + Netflix so they only run when opened.

---

## Restore

Everything is reversible. Full restore (re-enables packages, reinstalls APKs, resets
settings, reboots):

```bash
./restore.sh
```

Restore a specific backup:

```bash
./restore.sh 20261030-060123
```

### Individual fixes

```bash
# Re-enable one system package
adb shell pm enable --user 0 com.mitv.tvhome.atv        # PatchWall
adb shell pm enable --user 0 com.xiaomi.mitv.smartshare # screen casting
adb shell pm enable --user 0 com.mitv.milinkservice     # Mi Link remote app
adb shell pm enable --user 0 com.xiaomi.mitv.updateservice # OTA updates

# Reinstall one removed app
adb install-multiple backups/20261030-060123/apks/<package>/*.apk

# Let Netflix run in the background again (if the remote's Netflix key misbehaves)
adb shell cmd appops set com.netflix.ninja RUN_ANY_IN_BACKGROUND allow
```

## Notes / caveats

- **Casting**: phone screen mirroring (Miracast/MiPlay) and the Mi Link remote app
  are off. Re-enable the two packages above if needed.
- **Firmware updates**: OTA checks are off. The set is on a 2021 build, so this is
  unlikely to matter; re-enable `com.xiaomi.mitv.updateservice` to restore.
- **PatchWall** is disabled but Home is the Google TV launcher, unaffected.
- **Screensaver** is off; the panel turns off after **30 minutes**
  (`screen_off_timeout=1800000`, raised from 5 min).
- **Launcher**: Projectivy 4.72 is Home; the stock Xiaomi launcher is disabled.
  Restore it with the two commands in the Launcher section.
- Google TV **recommendation rows** are gone (that was the point), apps row intact.
- If it gets sluggish in a few months, rerun `adb shell pm trim-caches 4096M`.
- Play Store auto-updates are still enabled; turn them off in Play Store settings
  if you want zero background downloads.
