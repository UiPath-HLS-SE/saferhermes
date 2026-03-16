#!/bin/bash
# don't delete this line, otherwise the gateway will have a placeholder value
export OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
exec openclaw gateway
