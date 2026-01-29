#!/bin/bash
set -e
source .env

echo "Initializing Access Control..."

RESULT=$(sui client call \
  --package $PACKAGE_ID \
  --module access_control \
  --function init \
  --gas-budget 50000000 \
  --json)

# Extract shared Roles object
ROLES_ID=$(echo "$RESULT" | jq -r '
  .objectChanges[]
  | select(.type == "published" or .type == "created")
  | select(.objectType | contains("Roles"))
  | .objectId
')

# Extract AdminCap (owned by sender)
ACCESS_ADMIN_CAP=$(echo "$RESULT" | jq -r '
  .objectChanges[]
  | select(.type == "created")
  | select(.objectType | contains("AdminCap"))
  | .objectId
')

if [ -z "$ROLES_ID" ] || [ -z "$ACCESS_ADMIN_CAP" ]; then
  echo "❌ Failed to extract Access Control objects"
  exit 1
fi

echo "ROLES_ID=$ROLES_ID" >> .env
echo "ACCESS_ADMIN_CAP=$ACCESS_ADMIN_CAP" >> .env

echo "✅ Access Control initialized"
echo "   Roles (shared): $ROLES_ID"
echo "   AdminCap: $ACCESS_ADMIN_CAP"
