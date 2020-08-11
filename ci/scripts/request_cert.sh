#!/bin/bash
set -e
source pfsense_modules/ci/functions/pfsense_functions.sh

connect_pfsense $PFSENSE_FQDN $PFSENSE_USERNAME $PFSENSE_PASSWORD
renew_pfsense_acme_cert $SUBJECT
get_pfsense_acme_cert $CERT_ID
get_pfsense_acme_root $CA_ID

credhub set -n /concourse/main/pksdemo/pks_cert -t certificate \
 -c *.pem \
 -p *.key \
 -r  ca.cer

sleep 3000
