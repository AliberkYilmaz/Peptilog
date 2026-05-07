#!/usr/bin/env bash
# Helper: run Peptilog on your phone with hot reload.
# Usage:    ./run-dev.sh
# Once running:  press r = hot reload   |  R = full restart   |  q = quit
set -e
cd "$(dirname "$0")"
export PATH="/opt/homebrew/share/android-commandlinetools/platform-tools:$PATH"

# Re-establish wireless ADB connection (in case phone reconnected to WiFi)
adb connect 192.168.1.21:43787 2>/dev/null || true

flutter run \
  -d 192.168.1.21:43787 \
  --dart-define=SUPABASE_URL=https://idqiuasyxijhdriizhyl.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkcWl1YXN5eGlqaGRyaWl6aHlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NjczODksImV4cCI6MjA5MjU0MzM4OX0.Zw5yjrrNdgFN_ejZyhW5ud43rONLBdo3IoO_4In55Kk
