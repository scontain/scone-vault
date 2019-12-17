#!/bin/sh

set -x
     #vault server -dev -dev-listen-address 0.0.0.0:8200 &
     vault server -tls-skip-verify  -dev -dev-listen-address 0.0.0.0:8200  &
     sleep 6
     PID=$!

     export VAULT_ADDR='http://127.0.0.1:8200'
     #vault secrets enable -path=tud-secret kv
     vault mount -path=tud-secret -local generic
     vault write tud-secret/nginx/default.conf value=@./config/default.conf
     vault write tud-secret/nginx/nginx.conf value=@./config/nginx.conf
     vault write tud-secret/nginx/ssl.conf value=@./config/ssl.conf
     vault write tud-secret/nginx/cert value=@cert.pem
     vault write tud-secret/nginx/key value=@key.pem
     wait $PID
