#!/bin/sh

set -x

URL="http://vault:8200"
INDEX="nginx"
export VAULT_ADDR=${URL}
export TOKEN=${TOKEN}

#Wait for Vault
echo "Waiting for Vault to become ready..."
RET=0
timeout 120 sh -c 'until curl -sH X-Vault-Token:RootToken -XGET http://vault:8200/v1/tud-secret/nginx/key 2>&1 |grep "data"; do sleep 0.4; done' || RET=$? || true
if [ $RET -ne 0 ]; then
    echo "FAIL! Vault did not become available within two minutes"
    exit 1
fi
echo "Vault is ready!"

#Configuration from Vault
override() {
    # $1 the remote key to fetch from vault
    # $2 the absolute path inside the container to save it as 
    echo "Vault Lookup: ${URL}/v1/tud-secret/${INDEX}/$1 : $2"
    json=$(curl -sH "X-Vault-Token:$TOKEN" -XGET ${URL}/v1/tud-secret/${INDEX}/$1)
    echo $json
    if [[ $? -eq 0 ]]; then
        value=$(echo $json | jq -r .data.value)
        [[ "${value}" != "null" ]] && echo "Vault Lookup: Override found for $2" && echo "${value}" > $2
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

#Start Ngnix
startNginx=`date +%s%6N`
nginx -g "master_process off; daemon off;" &
timeout 60 sh -c 'until [ `curl -o /dev/null -s -w "%{http_code}" http://127.0.0.1:80` -eq 200 ]; do sleep 0.4; done'
CODE=`curl -o /dev/null -s -w "%{http_code}" http://127.0.0.1:80`
if [ $CODE -ne "200" ]; then
    echo "\tTest failed, nginx not running within one minute"
    exit 1
fi
echo -e "\tTest succeeded!, nginx is running with configuration from Vault."
endNginx=`date +%s%6N`
runtime=$((endNginx-startNginx))
totalTime=$((endNginx-startVault))
echo $runtime >> nginx-latency.dat
echo $totalTime >> total-latency.dat
