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

## Install Microsoft Defender
echo "=== Installing Microsoft Defender ==="
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
wget https://raw.githubusercontent.com/microsoft/mdatp-xplat/master/linux/installation/mde_installer.sh \
    -O ~/mde_installer.sh
wget 'https://dfescripts.blob.core.windows.net/dfelinuxscript/MicrosoftDefenderATPOnboardingLinuxServer.py?sp=r&st=2023-03-16T10:58:06Z&se=2026-04-01T17:58:06Z&spr=https&sv=2021-12-02&sr=b&sig=NIflnJXmjU%2Fl2h7UNBJddDuFaf67TzG0Wxl7H%2BnLjN8%3D' \
    -O ~/MicrosoftDefenderATPOnboardingLinuxServer.py
chmod +x ~/mde_installer.sh
~/mde_installer.sh \
    --install \
    --channel prod \
    --tag GROUP SAFERHERMES \
    --pre-req \
    -y \
    -p
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
