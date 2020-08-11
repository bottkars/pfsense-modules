#!/bin/bash
set -e
source pfsense_modules/ci/functions/pfsense_functions.sh
checking certs on $SUBJECT
check_cert_expire "${SUBJECT}:${PORT}" "$EXPIRE_DAYS"