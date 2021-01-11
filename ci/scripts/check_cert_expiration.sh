#!/bin/bash
set -e
source pfsense-modules/ci/functions/pfsense_functions.sh
echo "checking certs on $SUBJECT"
check_cert_expire "${SUBJECT}:${PORT}" "$EXPIRE_DAYS"