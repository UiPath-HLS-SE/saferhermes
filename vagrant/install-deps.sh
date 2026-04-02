#!/bin/bash

set -euo pipefail

: "${AZURE_SUBSCRIPTION_ID:?AZURE_SUBSCRIPTION_ID must be set}"
# Fix some weird hash mismatches happening on `apt update`, only on ARM devices,
# by disabling HTTP pipelining, caching and intermediate proxies.
echo "Acquire::http::Pipeline-Depth 0;" > /etc/apt/apt.conf.d/99custom && \
echo "Acquire::http::No-Cache true;" >> /etc/apt/apt.conf.d/99custom && \
echo "Acquire::BrokenProxy    true;" >> /etc/apt/apt.conf.d/99custom

# Install deps:
apt update
test -x "$(type -p curl)" || apt install -y curl
test -x "$(type -p gpg)"  || apt install -y gpg
test -x "$(type -p git)" || apt install -y git
test -x "$(type -p unzip)" || apt install -y unzip
test -x "$(type -p ca-certificates)" || apt install -y ca-certificates
test -x "$(type -p python3)" || apt install -y python3
apt install -y python3-pip python3-venv jq

## Install Microsoft Defender when an onboarding URL is explicitly provided.
echo "=== Microsoft Defender onboarding ==="
if [[ -n "${MDE_ONBOARDING_URL:-}" ]]; then
    echo "MDE_ONBOARDING_URL is set; attempting Defender install."
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash
    if wget https://raw.githubusercontent.com/microsoft/mdatp-xplat/master/linux/installation/mde_installer.sh \
        -O ~/mde_installer.sh \
        && wget "$MDE_ONBOARDING_URL" -O ~/MicrosoftDefenderATPOnboardingLinuxServer.py; then
        chmod +x ~/mde_installer.sh
        ~/mde_installer.sh \
            --install \
            --channel prod \
            --tag GROUP SAFERHERMES \
            --pre-req \
            -y \
            -p
        echo "Microsoft Defender install completed."
    else
        echo "WARNING: Defender onboarding download failed; continuing without Defender."
    fi
else
    echo "MDE_ONBOARDING_URL is not set; skipping optional Defender onboarding."
fi
echo -e "=== END ===\n"

## Install Azure CLI
echo "=== Installing Azure CLI ==="
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
echo -e "=== END ===\n"

## Install nginx with Lua module
echo "=== Installing nginx ==="
apt install -y nginx libnginx-mod-http-lua
echo -e "=== END ===\n"

## Install fluent-bit
echo "=== Installing fluent-bit ==="
codename=$(
    grep -oP '(?<=VERSION_CODENAME=).*' /etc/os-release 2>/dev/null || \
    lsb_release -cs 2>/dev/null
)
curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/debian/$codename $codename main" | \
    sudo tee /etc/apt/sources.list.d/fluent-bit.list
apt update
apt install -y fluent-bit
echo -e "=== END ===\n"

echo "=== Installing SaferHermes runtime ==="
mkdir -p /opt/saferhermes
python3 -m venv /opt/saferhermes/venv
/opt/saferhermes/venv/bin/pip install --upgrade pip wheel
/opt/saferhermes/venv/bin/pip install "hermes-agent[all]"
ln -sf /opt/saferhermes/venv/bin/hermes /usr/local/bin/hermes
echo -e "=== END ===\n"
