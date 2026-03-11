#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"

PIPELINE_PS1="$SCRIPT_DIR/run_pipeline.ps1"
if [[ ! -f "$PIPELINE_PS1" ]]; then
  echo "Pipeline script not found: $PIPELINE_PS1" >&2
  exit 1
fi

# Prefer pwsh (PowerShell 7+) for Linux/macOS cron environments.
if command -v pwsh >/dev/null 2>&1; then
  POWERSHELL_CMD="$(command -v pwsh)"
elif command -v powershell >/dev/null 2>&1; then
  POWERSHELL_CMD="$(command -v powershell)"
else
  echo "PowerShell executable not found. Install pwsh or powershell first." >&2
  exit 1
fi

CRON_COMMENT="# Teradata_Boston_Pipeline_530_IST"
CRON_JOB="CRON_TZ=Asia/Kolkata 30 5 * * * cd '$ROOT_DIR' ; '$POWERSHELL_CMD' -NoProfile -ExecutionPolicy Bypass -File '$PIPELINE_PS1' >> '$LOG_DIR/cron_pipeline.log' 2>&1"

TMP_CRON_FILE="$(mktemp)"
crontab -l 2>/dev/null | grep -v "Teradata_Boston_Pipeline_530_IST" > "$TMP_CRON_FILE" || true
{
  echo "$CRON_COMMENT"
  echo "$CRON_JOB"
} >> "$TMP_CRON_FILE"

crontab "$TMP_CRON_FILE"
rm -f "$TMP_CRON_FILE"

echo "Cron job registered: daily at 05:30 IST"
echo "Log file: $LOG_DIR/cron_pipeline.log"
