#!/bin/bash

set -euo pipefail

install -d -m 0700 -o saferhermes -g saferhermes /var/lib/saferhermes/.hermes

sudo -u saferhermes -H env HOME=/var/lib/saferhermes bash <<'SCRIPT'
set -euo pipefail
mkdir -p \
  "$HOME/.hermes/cron" \
  "$HOME/.hermes/sessions" \
  "$HOME/.hermes/logs" \
  "$HOME/.hermes/memories" \
  "$HOME/.hermes/skills" \
  "$HOME/.hermes/pairing" \
  "$HOME/.hermes/hooks" \
  "$HOME/.hermes/image_cache" \
  "$HOME/.hermes/audio_cache"
touch "$HOME/.hermes/.env"
chmod 700 "$HOME/.hermes"
chmod 600 "$HOME/.hermes/.env"
SCRIPT
