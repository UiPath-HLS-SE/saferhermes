#!/bin/bash

set -euo pipefail

echo
if [[ "${ENABLE_AZURE_LOGGING:-false}" == "true" ]]; then
    : "${AZURE_SUBSCRIPTION_ID:?AZURE_SUBSCRIPTION_ID must be set when ENABLE_AZURE_LOGGING=true}"
    : "${AZURE_BLOB_ACCOUNT_NAME:?AZURE_BLOB_ACCOUNT_NAME must be set when ENABLE_AZURE_LOGGING=true}"

    echo "=== checking if token for logs ingestion needs to be renewed ==="
    SAS_EXPIRY=$(
        grep --only-matching -E "se=[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}" \
        /etc/fluent-bit/azure-monitor.env 2>/dev/null | cut -d= -f2 || true
    )
    TODAY=$(date -d "today" +%Y-%m-%d)
    if [[ -z "${SAS_EXPIRY:-}" || "$SAS_EXPIRY" < "$TODAY" || "$SAS_EXPIRY" == "$TODAY" ]]; then
        echo "==> Log ingestion token missing or expired. Re-running Azure setup..."
        cat <<EOF
                            _  _____ _____ _____ _   _ _____ ___ ___  _   _
     _____ _____ _____     / \|_   _|_   _| ____| \ | |_   _|_ _/ _ \| \ | |  _____ _____ _____
    |_____|_____|_____|   / _ \ | |   | | |  _| |  \| | | |  | | | | |  \| | |_____|_____|_____|
    |_____|_____|_____|  / ___ \| |   | | | |___| |\  | | |  | | |_| | |\  | |_____|_____|_____|
                        /_/__ \_\_|   |_| |_____|_| \_| |_| |___\___/|_| \_|
             _     ___   ____ ___ _   _   _____ ___       _     ____ _   _ ___   _____
            | |   / _ \ / ___|_ _| \ | | |_   _/ _ \     / \   |__  / | | |  _ \| ____|
            | |  | | | | |  _ | ||  \| |   | || | | |   / _ \    / /| | | | |_) |  _|
            | |__| |_| | |_| || || |\  |   | || |_| |  / ___ \  / /_| |_| |  _ <| |___
            |_____\___/ \____|___|_| \_|   |_| \___/  /_/   \_\/____|\___/|_| \_\_____|
EOF
        az login --use-device-code --allow-no-subscriptions --output none --only-show-errors
        az account set -n "$AZURE_SUBSCRIPTION_ID"
        AZURE_BLOB_ACCOUNT_NAME="$AZURE_BLOB_ACCOUNT_NAME" /home/vagrant/utils/setup-azure-monitor.sh
    else
        echo "token up to date."
    fi
else
    echo "=== Azure log shipping disabled; skipping Azure setup ==="
fi

echo
echo "=== enabling logging and saferhermes daemons ==="
systemctl daemon-reload
if [[ "${ENABLE_AZURE_LOGGING:-false}" == "true" ]]; then
    systemctl enable --now fluent-bit
else
    systemctl disable --now fluent-bit 2>/dev/null || true
fi
systemctl enable --now saferhermes
