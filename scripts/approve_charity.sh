#!/bin/bash
set -e
source .env

CHARITY_ADDRESS="0xCHARITY_ADDRESS"

echo "Approving charity..."

sui client call \
  --package $PACKAGE_ID \
  --module compliance \
  --function approve \
  --args $COMPLIANCE_ADMIN_CAP $COMPLIANCE_ID $CHARITY_ADDRESS \
  --gas-budget 50000000
