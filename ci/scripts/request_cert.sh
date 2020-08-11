#!/bin/bash
set -x
source pfsense_modules/ci/functions/pfsense_functions.sh

connect_pfsense $PFSENSE_FQDN $PFSENSE_USERNAME $PFSENSE_PASSWORD
renew_pfsense_acme_cert $SUBJECT
get_pfsense_acme_cert $CERT_ID


sleep 3000
