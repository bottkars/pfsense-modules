#!bin/bash


function connect_pfsense {
    local username=${2:-admin}
    local password=${3:-$PFSENSE_PASSWORD}
    local pfsensefqdn=${1:-$PFSENSE_FQDN}
    export global PFSENSE_FQDN=$pfsensefqdn
    get_pfs_csrf $pfsensefqdn
    login_pfsense $password $username $url
    refresh_pfsense_token
}


function get_pfs_csrf {
    local pfsensefqdn=${1:-$PFSENSE_FQDN}
    echo "retrieving session cookies from $PFSENSE_FQDN"
    curl -s -L -k --cookie-jar cookies.txt \
     https://$pfsensefqdn \
     | grep "name='__csrf_magic'" \
     | sed 's/.*value="\(.*\)".*/\1/' > csrf.txt
}

function login_pfsense {
    local passwordfld=${1:-PFSENSE_PASSWORD}
    local usernamefld=${2:-admin}
    echo "Login In to $PFSENSE_FQDN as $usernamefld"
    curl -s -L -k --cookie cookies.txt --cookie-jar cookies.txt \
        --data-urlencode "login=Login" \
        --data-urlencode "usernamefld=$usernamefld" \
        --data-urlencode "passwordfld=$passwordfld" \
        --data-urlencode "__csrf_magic=$(cat csrf.txt)" \
     https://$PFSENSE_FQDN  > /dev/null
}

function refresh_pfsense_token {
    local endpoint=${1}
    curl -s -L -k --cookie cookies.txt --cookie-jar cookies.txt \
     https://$PFSENSE_FQDN/$endpoint  \
     | grep "name='__csrf_magic'"   \
     | sed 's/.*value="\(.*\)".*/\1/' > csrf.txt
}


function get_pfsense_backup {
    local endpoint=diag_backup.php
    refresh_pfsense_token $endpoint
    curl -s -L -k --cookie cookies.txt --cookie-jar cookies.txt \
     --data-urlencode "download=download" \
     --data-urlencode "donotbackuprrd=yes" \
     --data-urlencode "__csrf_magic=$(head -n 1 csrf.txt)" \
     https://$PFSENSE_FQDN/$endpoint > config-router-`date +%Y%m%d%H%M%S`.xml
}


function get_pfsense_acme_cert {
            local id=${1:-0}
            local endpoint=system_certmanager.php
            # refresh_pfsense_token $endpoint
            echo "Retrieving certificate with id $id from https://$PFSENSE_FQDN/$endpoint"
            curl -s -L -k --cookie cookies.txt --cookie-jar cookies.txt \
                --data-urlencode "act=key" \
                --data-urlencode "id=$id" \
                --data-urlencode "__csrf_magic=$(head -n 1 csrf.txt)" \
                https://$PFSENSE_FQDN/$endpoint >$id.key
            curl -s -L -k --cookie cookies.txt --cookie-jar cookies.txt \
                --data-urlencode "act=exp" \
                --data-urlencode "id=$id" \
                --data-urlencode "__csrf_magic=$(head -n 1 csrf.txt)" \
                https://$PFSENSE_FQDN/$endpoint >$id.pem  

            certdate=$(echo $(date --date="$(openssl x509 -enddate -noout -in $id.pem|cut -d= -f 2)" --iso-8601))
            certsubject=$(openssl x509 -noout -subject -nameopt multiline -in $id.pem| sed -n 's/ *commonName *= //p' )
            mv $id.key $certsubject-${certdate//-/.}.key
            mv $id.pem $certsubject-${certdate//-/.}.pem
            echo "Certificate on pfsense for $certsubject is valid until $certdate" 
            echo "storing key as $certsubject-${certdate//-/.}.key"    
            echo "storing Certificate as $certsubject-${certdate//-/.}.pem"   
}



function get_pfsense_acme_root {
            local id=${1:-0}
            local endpoint="system_camanager.php"
            # refresh_pfsense_token $endpoint
            echo "Retrieving certificate with id ${id} from https://${PFSENSE_FQDN}/${endpoint}"
            curl -s -L -k --cookie cookies.txt --cookie-jar cookies.txt \
                --data-urlencode "act=exp" \
                --data-urlencode "id=${id}" \
                --data-urlencode "__csrf_magic=$(head -n 1 csrf.txt)" \
                "https://${PFSENSE_FQDN}/${endpoint}" > ca.cer
            certdate=$(echo $(date --date="$(openssl x509 -enddate -noout -in ca.cer | cut -d= -f 2)" --iso-8601))
            certsubject=$(openssl x509 -noout -subject -nameopt multiline -in ca.cer| sed -n 's/ *commonName *= //p' )
            echo "Certificate on pfsense for CA ${certsubject} is valid until ${certdate//-/.}" 

}



function check_cert_expire {
    local days=${2:-15}
    local url=${1:-vmw.pks.home.labbuildr.com:443}
    openssl x509 -noout -issuer -subject -dates  -in <(openssl s_client -showcerts -connect $url </dev/null 2>/dev/null | openssl x509 -outform PEM)
    RESULT="$(openssl x509 -checkend $(( 24*3600*$days )) -noout -in <(openssl s_client -showcerts -connect $url </dev/null 2>/dev/null | openssl x509 -outform PEM))" 
    RC=$?
    
    if [ $RC -eq 0 ]; then
    echo $RESULT
    echo 'good'
    printf $RESULT
    else
    echo 'bad'
    printf $RESULT
    printf " within $days days, "
    fi
}



function renew_pfsense_acme_cert {
    local subject=${1}
    local url=${2:-$PFSENSE_FQDN}
    curl_args=(
    --cookie cookies.txt 
    --cookie-jar cookies.txt  
    -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' 
    --data-urlencode "id=$subject"
    --data-urlencode "action=issuecert"
    --data-urlencode "__csrf_magic=$(head -n 1 csrf.txt)"
)
  curl -k -v "https://$url/acme/acme_certificates.php" \
        "${curl_args[@]}"
}

