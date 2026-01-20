#!/bin/bash
source .env

SIG1="0xSIGNER1"
SIG2="0xSIGNER2"
SIG3="0xSIGNER3"

sui client call \
  --package $PACKAGE_ID \
  --module treasury \
  --function create_multisig_treasury \
  --args $SIG1 $SIG2 $SIG3 2 \
  --gas-budget 50000000
