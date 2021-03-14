#! /bin/bash

###########################
# Based on Amazon Linux 2 #
###########################

# Docker installation
sudo amazon-linux-extras install -y docker
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Vault dev mode with Docker
docker run --cap-add=IPC_LOCK -d -p 8200:8200 --name=dev-vault vault
docker ps
docker logs dev-vault
curl http://127.0.0.1:8200/v1/sys/health
docker stop dev-vault
docker rm dev-vault

# Vault installation with yum repository
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install vault
vault -version

# Vault dev mode with Vault binary
vault server -dev -dev-root-token-id=root &
export VAULT_ADDR='http://127.0.0.1:8200'
vault status
export VAULT_TOKEN="root"
vault token lookup
fg
CTRL + C
unset VAULT_ADDR
unset VAULT_TOKEN

# Vault Startup
cat /etc/vault.d/vault.hcl
sudo vault server -config=/etc/vault.d/vault.hcl &
export VAULT_ADDR='https://127.0.0.1:8200'
export VAULT_SKIP_VERIFY='true'
vault status

# Vault initialization
vault operator init
vault status
vault operator unseal
...
vault status
vault login
vault token lookup

# Vault check storage backend encryption
fg
CTRL + C
sudo vault server -config=/etc/vault.d/vault.hcl &
vault token lookup
vault status
sudo cat /opt/vault/data/sys/token/id/_
