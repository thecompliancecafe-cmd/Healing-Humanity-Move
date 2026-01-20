#!/bin/bash
source .env

CHARITY_NAME="UNICEF-India"
CHARITY_WALLET="0xCHARITY_ADDRESS"

sui client call \
  --package $PACKAGE_ID \
  --module compliance \
  --function approve_charity \
  --args "$CHARITY_NAME" $CHARITY_WALLET \
  --gas-budget 50000000
