#!/bin/bash
set -euo pipefail

initialize_dataset "$END_USER_BASE_URL" "$TMP_END_USER_DATASET" "$END_USER_ENDPOINT_URL"
initialize_dataset "$ADMIN_BASE_URL" "$TMP_ADMIN_DATASET" "$ADMIN_ENDPOINT_URL"
purge_backend_cache "$END_USER_VARNISH_SERVICE"
purge_backend_cache "$ADMIN_VARNISH_SERVICE"

# access is unauthorized

curl -k -w "%{http_code}\n" -o /dev/null -s \
  -E "${AGENT_CERT_FILE}":"${AGENT_CERT_PWD}" \
  -H "Accept: application/n-triples" \
  -X DELETE \
  "${END_USER_BASE_URL}" \
| grep -q "${STATUS_FORBIDDEN}"

pushd . > /dev/null && cd "$SCRIPT_ROOT/admin/acl"

# create authorization

./create-authorization.sh \
  -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$ADMIN_BASE_URL" \
  --label "DELETE authorization" \
  --agent "$AGENT_URI" \
  --to "$END_USER_BASE_URL" \
  --write

popd > /dev/null

pushd . > /dev/null && cd "$SCRIPT_ROOT"

# create container

slug="test"

container=$(./create-container.sh \
 -f "$OWNER_CERT_FILE" \
  -p "$OWNER_CERT_PWD" \
  -b "$END_USER_BASE_URL" \
  --title "Test" \
  --slug "$slug" \
  --parent "$END_USER_BASE_URL")

popd > /dev/null

# access is allowed after authorization is created

curl -k -w "%{http_code}\n" -o /dev/null -f -s \
  -E "${AGENT_CERT_FILE}":"${AGENT_CERT_PWD}" \
  -H "Accept: application/n-triples" \
  -X DELETE \
  "$container" \
| grep -q "${STATUS_NO_CONTENT}"