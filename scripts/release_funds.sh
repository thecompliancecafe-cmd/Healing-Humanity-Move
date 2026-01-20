#!/bin/bash
source .env

CAMPAIGN_ID="0xCAMPAIGN_OBJECT_ID"
MILESTONE=1

sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function release_milestone_funds \
  --args $CAMPAIGN_ID $MILESTONE \
  --gas-budget 50000000
