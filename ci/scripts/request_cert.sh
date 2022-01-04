#!/bin/bash
set -e
source pfsense-modules/ci/functions/pfsense_functions.sh

connect_pfsense $PFSENSE_FQDN $PFSENSE_USERNAME $PFSENSE_PASSWORD
get_pfsense_acme_cert $CERT_ID
get_pfsense_acme_root $CA_ID
echo "storing certificates in CredHub"
credhub set -n /concourse/main/pksdemo/$STORED_CERT -t certificate \
 -c *.pem \
 -p *.key \
 -r  ca.cer
cp *.pem certificates/
