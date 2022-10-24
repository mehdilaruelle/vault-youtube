#! /bin/bash

# PostgreSQL startup
docker pull postgres:latest
docker run \
      --name postgres \
      --env POSTGRES_USER=root \
      --env POSTGRES_PASSWORD=secretpassword \
      --detach  \
      --publish 5432:5432 \
      postgres
docker ps


# Vault startup
vault server -dev -dev-root-token-id=root &
export VAULT_ADDR='http://127.0.0.1:8200'
vault status
export VAULT_TOKEN="root"
vault token lookup

# Config the secret engine with PostgreSQL
vault secrets enable database
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url="postgresql://{{username}}:{{password}}@127.0.0.1:5432/postgres?sslmode=disable" \
    username="root" \
    password="secretpassword"
vault write -force database/rotate-root/postgresql

# Configure the Role
tee readonly.sql <<EOF
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO "{{name}}";
EOF
cat readonly.sql

vault write database/roles/readonly \
      db_name=postgresql \
      creation_statements=@readonly.sql \
      default_ttl=1h \
      max_ttl=24h

# Use credentials and renew/revoke it
vault read database/creds/readonly
vault read database/creds/readonly
vault list sys/leases/lookup/database/creds/readonly
vault lease renew database/creds/readonly/$LEASE_ID
vault lease lookup database/creds/readonly/$LEASE_ID
vault lease revoke database/creds/readonly/$LEASE_ID
vault list sys/leases/lookup/database/creds/readonly
vault lease revoke -prefix database/creds/readonly
vault list sys/leases/lookup/database/creds/readonly

# Static Roles creation (with an existing DB user)
docker exec -i \
    postgres \
    psql -U root -c "CREATE ROLE \"service-db\" WITH LOGIN PASSWORD 'mypassword';"

docker exec -i \
    postgres \
    psql -U root -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"service-db\";"


tee static_role.sql <<EOF
ALTER USER "{{name}}" WITH PASSWORD '{{password}}';
EOF

vault write database/static-roles/app \
    db_name=postgresql \
    rotation_statements=@static_role.sql \
    username="service-db" \
    rotation_period=86400
vault read database/static-roles/app

# Static Roles password usage and rotation
vault read database/static-creds/app
vault read database/static-creds/app
vault write -f database/rotate-role/app
vault read database/static-creds/app

# Stop PostgreSQL container
docker stop $(docker ps -f name=postgres -q)
docker rm $(docker ps -a -f name=postgres -q)

# Stop Vault dev mode
fg
CTRL + C
