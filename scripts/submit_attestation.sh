#!/bin/bash
set -e
source .env

MILESTONE=1
HASH="AI_HASH_STRING"

echo "Submitting AI Attestation..."

sui client call \
  --package $PACKAGE_ID \
  --module ai_attestation \
  --function submit \
  --args $CAMPAIGN_ID $MILESTONE "$HASH" \
  --gas-budget 50000000 \
  --json > attestation.json

# Optional: confirm attestation object creation
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
  echo "⚠️ Attestation submitted, but object ID not detected (check attestation.json)"
else
  echo "✅ Attestation submitted"
  echo "   Attestation ID: $ATTESTATION_ID"
fi
