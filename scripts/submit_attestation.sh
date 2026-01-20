#!/bin/bash
source .env

CAMPAIGN_ID="0xCAMPAIGN_OBJECT_ID"
MILESTONE=1
AI_HASH="0xAI_ATTESTATION_HASH"

sui client call \
  --package $PACKAGE_ID \
  --module ai_attestation \
  --function submit_attestation \
  --args $CAMPAIGN_ID $MILESTONE $AI_HASH \
  --gas-budget 50000000
