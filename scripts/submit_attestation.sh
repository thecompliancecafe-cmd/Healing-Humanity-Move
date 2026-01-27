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
  --gas-budget 50000000
