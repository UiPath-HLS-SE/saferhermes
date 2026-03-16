#!/bin/bash
# Logs in to Azure via device code flow, fetches Log Analytics workspace credentials,
# and writes them to Fluent Bit's environment file.
# Runs automatically during `vagrant up --provision`.

set -euo pipefail

: "${AZURE_BLOB_ACCOUNT_NAME:?AZURE_BLOB_ACCOUNT_NAME must be set}"

# use user-id as the name of the container under which logs will be written
AZURE_BLOB_CONTAINER_NAME=$(az ad signed-in-user show --query id -o tsv)
CONTAINER_EXISTS=$(az storage container exists --auth-mode login \
    --account-name ${AZURE_BLOB_ACCOUNT_NAME} \
    -n ${AZURE_BLOB_CONTAINER_NAME} \
    | jq .exists
)
if [ "$CONTAINER_EXISTS" = "false" ]; then
    CREATED=$(az storage container create --auth-mode login \
        --account-name ${AZURE_BLOB_ACCOUNT_NAME} \
        -n ${AZURE_BLOB_CONTAINER_NAME} \
        | jq .created
    )
    if [ "$CREATED" = "false" ]; then
        echo "Failed to create storage container for logs"
        exit 1
    fi
fi

SAS_EXPIRY_DATE=$(date -d "+7 days" +%Y-%m-%d)
AZURE_STORAGE_SAS_TOKEN=$(az storage container generate-sas \
    --auth-mode login \
    --as-user \
    --account-name ${AZURE_BLOB_ACCOUNT_NAME} \
    -n ${AZURE_BLOB_CONTAINER_NAME} \
    --expiry "$SAS_EXPIRY_DATE" \
    --permissions w | tr -d ' "'
)
az logout

echo "==> Writing credentials to /etc/fluent-bit/azure-monitor.env"
mkdir -p /etc/fluent-bit
cat >/etc/fluent-bit/azure-monitor.env <<EOF
AZURE_BLOB_CONTAINER_NAME=${AZURE_BLOB_CONTAINER_NAME}
AZURE_STORAGE_SAS_TOKEN=${AZURE_STORAGE_SAS_TOKEN}
AZURE_BLOB_ACCOUNT_NAME=${AZURE_BLOB_ACCOUNT_NAME}
EOF
chmod 644 /etc/fluent-bit/azure-monitor.env

echo "==> Configuring Fluent Bit systemd unit..."
mkdir -p /etc/systemd/system/fluent-bit.service.d
cat >/etc/systemd/system/fluent-bit.service.d/azure-monitor.conf <<EOF
[Service]
EnvironmentFile=/etc/fluent-bit/azure-monitor.env
ExecStart=
ExecStart=/opt/fluent-bit/bin/fluent-bit -c /etc/fluent-bit/conf.yaml
EOF

echo "==> Done. Fluent Bit is now set to forward logs to Azure."

echo "==> Setting Microsoft Defender Device Identifier"
echo $AZURE_BLOB_CONTAINER_NAME > /etc/hostname # use the entra id as the hostname
~/mde_installer.sh \
    --onboard ~/MicrosoftDefenderATPOnboardingLinuxServer.py \
    -y
systemctl restart mdatp
