#! /bin/bash

# Vault startup
vault server -dev -dev-root-token-id=root &
export VAULT_ADDR='http://127.0.0.1:8200'
vault status
export VAULT_TOKEN="root"
vault token lookup

# Token TTL & renew
vault token -h
vault token create -ttl=60s -explicit-max-ttl=600s -policy=default
vault token lookup $PARENT_TOKEN_ID
vault token lookup $PARENT_ACCESSOR_ID
vault token renew $PARENT_TOKEN_ID
vault read sys/auth/token/tune

# Child token
VAULT_TOKEN=$PARENT_TOKEN_ID vault token create -ttl=600s -policy=default
vault token revoke -accessor $PARENT_ACCESSOR_ID
vault token create -orphan

# Others tokens
vault token create -policy="default" -use-limit=2 -period=1h
vault token create -type=batch -policy="default" -ttl=20m
