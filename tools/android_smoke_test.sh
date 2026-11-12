#!/usr/bin/env bash
# Runs inside an already-booted Android emulator.
set -euo pipefail
package=com.example.wordnest
apk=build/app/outputs/flutter-apk/app-release.apk
adb logcat -c
adb install -r "$apk"
adb shell am start -W -n "$package/.MainActivity"
# Give Flutter and plugins time to start and show their first screen.
sleep 20
adb shell pidof "$package" > /dev/null || {
  echo 'WordNest is not running after launch.'
  adb logcat -d -v brief AndroidRuntime:E flutter:E '*:S' > "$RUNNER_TEMP/wordnest-crash.log"
  cat "$RUNNER_TEMP/wordnest-crash.log"
  details=$(tail -n 80 "$RUNNER_TEMP/wordnest-crash.log")
  details=${details//'%'/'%25'}
  details=${details//$'\r'/'%0D'}
  details=${details//$'\n'/'%0A'}
  echo "::error title=Android startup crash::$details"
  exit 1
}
if ! adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' | grep -q "$package"; then
  echo 'WordNest is running, but its activity is not in the foreground.'
  adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' || true
  exit 1
fi
echo 'WordNest is running in the foreground on Android 13.'

# Dismiss the first-launch daily reward screen, if present, then select the
# rightmost bottom tab (Settings). This tests Android's actual back dispatch.
adb shell input keyevent KEYCODE_BACK
sleep 3
size=$(adb shell wm size | tail -n 1 | grep -oE '[0-9]+x[0-9]+')
density=$(adb shell wm density | tail -n 1 | grep -oE '[0-9]+')
width=${size%x*}
height=${size#*x}
x=$((width * 7 / 8))
y=$((height - density * 58 / 160))
adb shell input tap "$x" "$y"
sleep 2
adb shell input keyevent KEYCODE_BACK
sleep 3
if ! adb shell pidof "$package" > /dev/null || ! adb shell dumpsys activity activities | grep -E 'mResumedActivity|topResumedActivity' | grep -q "$package"; then
  echo '::error title=Android back navigation::Back from Settings exited the app instead of returning to Home.'
  exit 1
fi
echo 'Back from Settings returned to the app on Android 13.'
