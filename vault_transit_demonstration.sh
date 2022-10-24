#! /bin/bash

# Vault startup
vault server -dev -dev-root-token-id=root &
export VAULT_ADDR='http://127.0.0.1:8200'
vault status
export VAULT_TOKEN="root"
vault token lookup

# Enable and configure secret engine Transit
vault secrets enable transit
vault write -f transit/keys/app1
vault read transit/keys/app1

# Encrypt & decrypt secret
vault write transit/encrypt/app1 plaintext=$(echo "test" | base64)
vault write transit/encrypt/app1 plaintext=$(echo "test" | base64)
ENCRYPTED_SECRET=$(vault write -field="ciphertext" transit/encrypt/app1 plaintext=$(echo "test" | base64))
echo $ENCRYPTED_SECRET
vault write -field=plaintext transit/decrypt/app1 ciphertext=$ENCRYPTED_SECRET | base64 --decode

# Rotate key
vault write -f transit/keys/app1/rotate
vault read transit/keys/app1
vault write transit/keys/app1/config auto_rotate_period=24h
vault read transit/keys/app1
vault write transit/encrypt/app1 plaintext=$(echo "test" | base64)

# Rewrap secret with new key
echo $ENCRYPTED_SECRET
vault write transit/rewrap/app1 ciphertext=$ENCRYPTED_SECRET

# Set minimum version to decrypt & encrypt data
vault read transit/keys/app1
vault write transit/keys/app1/config min_decryption_version=2
vault read transit/keys/app1
vault write transit/rewrap/app1 ciphertext=$ENCRYPTED_SECRET

# Generate a datakey
vault write -f transit/datakey/plaintext/app1
## CIPHERTEXT is the ciphertext value return by the previous command
vault write -field=plaintext transit/decrypt/app1 ciphertext=$CIPHERTEXT

# Bring Your Own Key (BYOK): https://developer.hashicorp.com/vault/docs/secrets/transit#bring-your-own-key-byok

# Stop Vault dev mode
fg
CTRL + C
