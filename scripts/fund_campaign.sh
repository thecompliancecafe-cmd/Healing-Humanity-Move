#!/bin/bash
source .env

CAMPAIGN_ID="0xCAMPAIGN_OBJECT_ID"
AMOUNT=100000000   # 0.1 SUI

sui client call \
  --package $PACKAGE_ID \
  --module milestone_escrow \
  --function donate \
  --args $CAMPAIGN_ID $AMOUNT \
  --gas-budget 50000000
