#! /bin/bash

# Vault startup
vault server -dev -dev-root-token-id=root &
export VAULT_ADDR='http://127.0.0.1:8200'
vault status
export VAULT_TOKEN="root"
vault token lookup

# Token TTL & renew
vault token -h
vault token create -ttl=600s -explicit-max-ttl=1200s -policy=default
vault token lookup $TOKEN_ID
vault token lookup -accessor $ACCESSOR_ID # To compare with previous command
vault token renew $TOKEN_ID
vault token lookup -accessor $ACCESSOR_ID
vault token renew -increment="1h" $TOKEN_ID # Max TTL is set to 20m so your increment will be equal to the max TTL left
vault read sys/auth/token/tune

# Child token
VAULT_TOKEN=$TOKEN_ID vault token create -ttl=600s -policy=default # Don't work because our token doest have rights we will see to the next video
TOKEN_ID=$(vault token create -ttl=60s -explicit-max-ttl=600s -policy=root -field=token)
VAULT_TOKEN=$TOKEN_ID vault token create -ttl=600s -policy=default
vault token lookup -accessor $ACCESSOR_CHILD_ID
vault token revoke $TOKEN_ID # Or wait 1min
vault token lookup -accessor $ACCESSOR_CHILD_ID

# Orphan token
TOKEN_ID=$(vault token create -ttl=60s -explicit-max-ttl=600s -policy=root -field=token)
VAULT_TOKEN=$TOKEN_ID vault token create -orphan -policy=default
vault token revoke $TOKEN_ID # Or wait 1min
vault token lookup -accessor $ACCESSOR_ORPHAN_ID

# Others tokens
vault token create -policy="default" -use-limit=2 -period=1h
vault token create -type=batch -policy="default" -ttl=20m

# Stop Vault dev mode
fg
CTRL + C
