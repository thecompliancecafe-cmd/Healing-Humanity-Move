#!/bin/bash
source .env

ORACLE_PUBKEY="0xAI_ORACLE_PUBKEY"

sui client call \
  --package $PACKAGE_ID \
  --module ai_oracle \
  --function register_oracle \
  --args $ORACLE_PUBKEY \
  --gas-budget 50000000
