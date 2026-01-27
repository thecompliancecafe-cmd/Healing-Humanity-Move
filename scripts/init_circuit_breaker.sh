#!/bin/bash
set -e
source .env

echo "Initializing Circuit Breaker..."

sui client call \
  --package $PACKAGE_ID \
  --module circuit_breaker \
  --function init \
  --gas-budget 50000000 \
  --json > circuit.json

CIRCUIT_ID=$(jq -r '.objectChanges[] | select(.objectType | contains("CircuitBreaker")) | .objectId' circuit.json)
CIRCUIT_ADMIN_CAP=$(jq -r '.objectChanges[] | select(.objectType | contains("CircuitAdminCap")) | .objectId' circuit.json)

echo "CIRCUIT_ID=$CIRCUIT_ID" >> .env
echo "CIRCUIT_ADMIN_CAP=$CIRCUIT_ADMIN_CAP" >> .env
