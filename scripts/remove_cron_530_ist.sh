#!/usr/bin/env bash
set -euo pipefail

CRON_TAG="Teradata_Boston_Pipeline_530_IST"
TMP_CRON_FILE="$(mktemp)"

crontab -l 2>/dev/null | grep -v "$CRON_TAG" > "$TMP_CRON_FILE" || true
crontab "$TMP_CRON_FILE"
rm -f "$TMP_CRON_FILE"

echo "Removed cron entries tagged with: $CRON_TAG"
