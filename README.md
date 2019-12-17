# A demo how to run HashiCorp Vault inside Intel SGX using SCONE 


To perform this demo, you run the following command:
(see https://sconedocs.github.io/vault/)

```bash
docker-compose up
```

Ensure to execute 

```bash
docker-compose down
```

before starting it with *up* again. Note that the script `start_vault.sh` is used to start Vault server and inject some secrets used for Nginx.

## Details

You can perform the individual steps manually as described below.

Run the demo container using docker-compose:

```bash
docker-compose run scone-vault-nginx sh
```

Go to the deployment directory:

```bash
 cd /build_dir/
```

Install dependencies: 

```bash
 ./install-deps.sh
```

Now, run a benchmark to test SCONE Vault getting configuation for Nginx.

```bash
./bench.sh
```

## Contacts

Send email to info@scontain.com
