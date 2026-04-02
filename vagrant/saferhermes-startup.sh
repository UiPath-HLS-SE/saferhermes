#!/bin/bash

set -euo pipefail

: "${HOME:?HOME must be set}"
: "${PATH:?PATH must be set}"

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

exec /opt/saferhermes/venv/bin/hermes gateway
