#!/bin/bash
source .env

CAMPAIGN_NAME="Vaccines for Children"
TARGET_GOAL=1000000000   # in MIST

sui client call \
  --package $PACKAGE_ID \
  --module campaign_registry \
  --function create_campaign \
  --args "$CAMPAIGN_NAME" $TARGET_GOAL \
  --gas-budget 50000000
