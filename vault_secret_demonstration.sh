#! /bin/bash

# Vault startup
vault server -dev -dev-root-token-id=root &
export VAULT_ADDR='http://127.0.0.1:8200'
vault status
export VAULT_TOKEN="root"
vault token lookup

# Create engine & manage secrets
vault secrets enable -version=1 kv
vault secrets list -detailed
vault kv put kv/test key=value
vault kv list kv/
vault kv get kv/test
vault kv put kv/test key=new
vault kv get kv/test
vault kv delete kv/test

# Upgrade to kv v2
vault kv enable-versioning kv/
vault secrets list -detailed

# Use versioning from kv v2
vault kv put kv/test key=v1
vault kv get kv/test
vault kv put kv/test key=v2
vault kv get kv/test
vault kv get -version=1 kv/test
vault kv metadata get kv/test

# Delete and restaure a secret
vault kv delete kv/test
vault kv get kv/test
vault kv get -version=1 kv/test
vault kv get -version=2 kv/test
vault kv undelete -versions=2 kv/test
vault kv get kv/test

# Wrap secret
vault kv get -wrap-ttl=120 kv/test
vault unwrap $WRAP_TOKEN

# Destroy secret
vault kv destroy -versions=2 kv/test
vault kv get kv/test
vault kv get -version=1 kv/test
vault kv undelete -versions=2 kv/test
vault kv get kv/test
vault kv metadata delete kv/test
vault kv get kv/test

# Stop Vault dev mode
fg
CTRL + C
