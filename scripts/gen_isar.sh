#!/usr/bin/env bash
# gen_isar.sh — Run Isar code generation (separate pub env to avoid source_gen conflict)
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ="$SCRIPT_DIR/.."
TOOL="$PROJ/tools/isar_codegen"
DOMAINS=(
  "features/peptides/domain/peptide.dart"
  "features/injection_log/domain/injection_log.dart"
  "features/weight/domain/weight_log.dart"
  "features/health/domain/sleep_log.dart"
  "features/health/domain/blood_pressure_log.dart"
  "features/reminders/domain/reminder.dart"
)
for f in "${DOMAINS[@]}"; do
  mkdir -p "$TOOL/lib/$(dirname "$f")"
  cp "$PROJ/lib/$f" "$TOOL/lib/$f"
done
cd "$TOOL"
dart pub get
dart run build_runner build --delete-conflicting-outputs
for f in "${DOMAINS[@]}"; do
  base="${f%.dart}.g.dart"
  cp "$TOOL/lib/$base" "$PROJ/lib/$base"
done
echo "Isar codegen done"
