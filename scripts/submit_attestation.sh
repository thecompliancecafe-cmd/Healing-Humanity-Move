#!/bin/bash
set -e
source .env

MILESTONE=1
HASH="AI_HASH_STRING"

# Safety check
if [ -z "$ORACLE_REGISTRY_ID" ] || [ -z "$CAMPAIGN_ID" ]; then
  echo "❌ Missing ORACLE_REGISTRY_ID or CAMPAIGN_ID"
  exit 1
fi

echo "Submitting AI Attestation..."

sui client call \
  --package $PACKAGE_ID \
  --module ai_attestation \
  --function submit \
  --args \
    $ORACLE_REGISTRY_ID \
    $CAMPAIGN_ID \
    $MILESTONE \
    "$HASH" \
  --gas-budget 50000000 \
  --json > attestation.json

# Confirm attestation object creation
ATTESTATION_ID=$(jq -r '
  .effects.changes[]
  | select(
      .type=="created"
      and .objectType
      | endswith("::ai_attestation::Attestation")
    )
  | .objectId
' attestation.json)

if [ -z "$ATTESTATION_ID" ]; then
  echo "❌ Attestation failed or oracle not authorized"
  exit 1
fi

echo "✅ Attestation submitted"
echo "   Attestation ID: $ATTESTATION_ID"
