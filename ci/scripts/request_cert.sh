#!/bin/bash
set -e
source pfsense-modules/ci/functions/pfsense_functions.sh

connect_pfsense $PFSENSE_FQDN $PFSENSE_USERNAME $PFSENSE_PASSWORD
get_pfsense_acme_cert $CERT_ID
CA_TEXT=$(openssl x509 -noout -issuer -nameopt multiline -in *.pem | sed -n 's/ *commonName *= //p')
varname=CA_ID_$CA_TEXT
echo ${!varname} is ${varname}
get_pfsense_acme_root ${!varname}
echo "storing certificates in CredHub"
credhub set -n $PREFIX/$STORED_CERT -t certificate \
 -c *.pem \
 -p *.key \
 -r  ca.cer
cp *.pem certificates/
