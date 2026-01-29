#!/bin/bash
set -e
source .env

CHARITY_ADDRESS="0xCHARITY_ADDRESS"

echo "Approving charity for compliance..."

sui client call \
  --package $PACKAGE_ID \
  --module compliance \
  --function approve \
  --args $COMPLIANCE_ADMIN_CAP $COMPLIANCE_ID $CHARITY_ADDRESS \
  --gas-budget 50000000 \
  --json > compliance_approve.json

echo "✅ Charity approved for compliance"
echo "   Charity address: $CHARITY_ADDRESS"
