#!/bin/bash


: "${GATEWAY_PORT:?GATEWAY_PORT must be set}"
: "${OPENCLAW_ENV_PATH:?OPENCLAW_ENV_PATH must be set}"

set -a
source $OPENCLAW_ENV_PATH
set +a
: "${OPENCLAW_CONFIG_PATH:?OPENCLAW_CONFIG_PATH must be set in openclaw service environment file}"
: "${OPENCLAW_HOME:?OPENCLAW_HOME must be set in openclaw service environment file}"

# [Migrations]
echo "=== Running migrations ==="
openclaw --log-level fatal config set gateway.controlUi.allowedOrigins "[\"http://localhost:$GATEWAY_PORT\"]"
echo "=== Done ==="
# END

# we're running the migrations as root instead of the openclaw user due to some
# missing permissions on the OPENCLAW_HOME dir at this point in the system's state
# running them as root will assign ownership to root for some files/dirs.
chown -R openclaw:openclaw $OPENCLAW_CONFIG_PATH
chown -R openclaw:openclaw $OPENCLAW_HOME
