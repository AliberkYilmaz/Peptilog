#!/usr/bin/env bash
# peptilog-dev-daemon.sh — keeps Peptilog hot-reloading on Aliberk's phone forever.
#
# Behavior:
#   1. Maintains an `adb` wireless connection to the phone
#   2. Runs `flutter run` reading commands from a FIFO
#   3. Polls GitHub every 30s; on new commit -> git pull + send 'R' (hot restart)
#   4. If flutter run dies (phone sleeps / WiFi blip), waits 10s and restarts
#
# Triggered by ~/Library/LaunchAgents/com.peptilog.devdaemon.plist
# Logs to /tmp/peptilog-daemon.log
#
# Author: Atlas. Last updated 2026-05-08.

set -uo pipefail

PROJECT="$HOME/projects/Peptilog"
DEVICE="192.168.1.21:38565"   # update if wireless port changes
LOG="/tmp/peptilog-daemon.log"
FIFO="/tmp/peptilog-stdin"

export PATH="/opt/homebrew/share/android-commandlinetools/platform-tools:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

SUPABASE_URL="https://idqiuasyxijhdriizhyl.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkcWl1YXN5eGlqaGRyaWl6aHlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NjczODksImV4cCI6MjA5MjU0MzM4OX0.Zw5yjrrNdgFN_ejZyhW5ud43rONLBdo3IoO_4In55Kk"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

cd "$PROJECT" || { log "FATAL: cannot cd to $PROJECT"; exit 1; }

# (Re)create the FIFO that flutter run reads from
rm -f "$FIFO"
mkfifo "$FIFO"

# --- background: poll GitHub for new commits ---
poll_loop() {
  local last
  last=$(git rev-parse HEAD 2>/dev/null)
  log "poll_loop starting at $last"
  while true; do
    sleep 30
    if ! cd "$PROJECT" 2>/dev/null; then continue; fi
    git fetch origin main >/dev/null 2>&1
    local new
    new=$(git rev-parse origin/main 2>/dev/null)
    if [ -n "$new" ] && [ "$new" != "$last" ]; then
      log "new commit detected: $new — pulling + sending hot restart"
      if git pull --ff-only origin main >>"$LOG" 2>&1; then
        echo "R" > "$FIFO" 2>/dev/null || log "FIFO write failed"
        last="$new"
      else
        log "git pull failed (non-ff?), skipping reload"
      fi
    fi
  done
}

# --- main: keep flutter run alive ---
main_loop() {
  while true; do
    log "ensuring adb device $DEVICE is connected"
    adb connect "$DEVICE" >>"$LOG" 2>&1
    if ! adb devices | grep -E "^${DEVICE}\s+device$" >/dev/null; then
      log "device not online — sleeping 60s"
      sleep 60
      continue
    fi
    log "starting flutter run"
    # Keep a writer on the FIFO so flutter run doesn't see EOF
    (sleep 86400 > "$FIFO") &
    local writer=$!
    flutter run -d "$DEVICE" \
      --dart-define=SUPABASE_URL="$SUPABASE_URL" \
      --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
      < "$FIFO" >>"$LOG" 2>&1
    kill "$writer" 2>/dev/null
    log "flutter run exited — restart in 10s"
    sleep 10
  done
}

poll_loop &
POLL_PID=$!
trap "kill $POLL_PID 2>/dev/null; rm -f $FIFO; exit 0" SIGINT SIGTERM EXIT

main_loop
