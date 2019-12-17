#!/bin/sh

set -x

URL="http://vault:8200"
INDEX="nginx"
export VAULT_ADDR=${URL}
export TOKEN=${TOKEN}

#Wait Vault finishes injecting secrets
sleep 20

#Test Vault: curl -sH X-Vault-Token:RootToken -XGET http://vault:8200/v1/tud-secret/nginx/key

#Configuration from Vault
override() {

    # $1 the remote key to fetch from vault
    # $2 the absolute path inside the container to save it as 

    echo "Vault Lookup: ${URL}/v1/tud-secret/${INDEX}/$1 : $2"
    json=$(curl -sH "X-Vault-Token:$TOKEN" -XGET ${URL}/v1/tud-secret/${INDEX}/$1)
    echo $json
    if [[ $? -eq 0 ]]; then
        value=$(echo $json | jq -r .data.value)
        [[ "${value}" != "null" ]] && echo "Vault Lookup: Override found for $2" && echo ${value} > $2
    fi

}

mkdir /etc/nginx/site-available 
mkdir /etc/nginx/sites-enabled 
mkdir -p /etc/pki

#Measure latency 

startVault=`date +%s%6N` #microseconds
override nginx.conf    /etc/nginx/nginx.conf
override default.conf /etc/nginx/sites-enabled/default.conf
override ssl.conf     /etc/nginx/conf.d/ssl.conf
override cert         /etc/pki/cert.crt
override key         /etc/pki/key.key
endVault=`date +%s%6N`
runtime=$((endVault-startVault))
echo $runtime >> vault-latency.dat

# Start Ngnix
startNginx=`date +%s%6N`
nginx -g "master_process off; daemon off;" &
CODE=`curl -o /dev/null -s -w "%{http_code}" http://127.0.0.1:80`
while [ "$CODE" -ne "200" ]; do
    echo -e "\tTest failed, nginx not running."
    CODE=`curl -o /dev/null -s -w "%{http_code}" http://127.0.0.1:80`
done
endNginx=`date +%s%6N`
runtime=$((endNginx-startNginx))
totalTime=$((endNginx-startVault))
echo $runtime >> nginx-latency.dat
echo $totalTime >> total-latency.dat
