#! /bin/bash

# Vault startup
vault server -dev -dev-root-token-id=root &
export VAULT_ADDR='http://127.0.0.1:8200'
vault status
export VAULT_TOKEN="root"
vault token lookup

# Create policy
cat << EOF > policy.hcl
path "secret/data/mysecret" {
  capabilities = ["read", "create", "update", "delete"]
}
EOF
ls
vault policy write user policy.hcl
vault policy list
vault policy read user
rm policy.hcl

# Create userpass auth method
vault auth enable userpass
vault auth list
vault write auth/userpass/users/mlaruelle password=test policies=user
vault list auth/userpass/users/
vault read auth/userpass/users/mlaruelle
vault write auth/userpass/users/mlaruelle policies=user,default
vault read auth/userpass/users/mlaruelle

# Use userpass auth method
vault login -method=userpass username=mlaruelle
VAULT_TOKEN=$(cat "~/.vault-token") vault kv put secret/mysecret test=test

# Create approle auth method
vault auth enable approle
vault auth list
vault write auth/approle/role/app token_policies="default"
vault list /auth/approle/role
vault read /auth/approle/role/app

# Use approle auth method
vault read auth/approle/role/app/role-id
vault write -f auth/approle/role/app/secret-id
vault write auth/approle/login role_id=$ROLE_ID secret_id=$SECRET_ID

# Stop Vault dev mode
fg
CTRL + C
