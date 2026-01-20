#!/bin/bash
source .env

CAMPAIGN_ID="0xCAMPAIGN_OBJECT_ID"

sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function create_vault \
  --args $CAMPAIGN_ID \
  --gas-budget 50000000
