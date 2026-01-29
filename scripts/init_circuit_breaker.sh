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

# Extract CircuitBreaker shared object
CIRCUIT_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::circuit_breaker::CircuitBreaker")
    )
  | .objectId
' circuit.json)

# Extract Circuit Admin Cap
CIRCUIT_ADMIN_CAP=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::circuit_breaker::CircuitAdminCap")
    )
  | .objectId
' circuit.json)

# Safety checks
if [ -z "$CIRCUIT_ID" ] || [ -z "$CIRCUIT_ADMIN_CAP" ]; then
  echo "❌ Failed to extract circuit breaker objects"
  exit 1
fi

# Persist to .env safely
touch .env

if ! grep -q "^CIRCUIT_ID=" .env; then
  echo "CIRCUIT_ID=$CIRCUIT_ID" >> .env
fi

if ! grep -q "^CIRCUIT_ADMIN_CAP=" .env; then
  echo "CIRCUIT_ADMIN_CAP=$CIRCUIT_ADMIN_CAP" >> .env
fi

echo "✅ Circuit breaker initialized"
echo "CIRCUIT_ID=$CIRCUIT_ID"
echo "CIRCUIT_ADMIN_CAP=$CIRCUIT_ADMIN_CAP"
