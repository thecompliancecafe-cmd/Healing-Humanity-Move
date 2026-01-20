#!/bin/bash
source .env

echo "Initializing compliance registry..."

sui client call \
  --package $PACKAGE_ID \
  --module compliance \
  --function init_compliance \
  --gas-budget 50000000
