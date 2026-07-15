#!/usr/bin/env bash
# Grant the App Service managed identity a contained user in the Azure SQL
# database. This is a one-time DATA-PLANE step Terraform can't do — Terraform

set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/environments/prod" && pwd)"
SQL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/sql" && pwd)"

command -v az >/dev/null || { echo "az CLI not found"; exit 1; }
command -v sqlcmd >/dev/null || { echo "sqlcmd not found (brew install sqlcmd)"; exit 1; }

cd "$ENV_DIR"
FQDN="$(terraform output -raw sql_server_fqdn)"
DB="$(terraform output -raw sql_database_name)"
APP_NAME="$(terraform output -raw app_name)"
APP_OBJECT_ID="$(terraform output -raw app_principal_id)"

echo "Server   : $FQDN"
echo "Database : $DB"
echo "App user : $APP_NAME ($APP_OBJECT_ID)"
echo "==> Granting managed-identity access (idempotent)..."

# ActiveDirectoryAzCli reuses the current `az login` context — no password.
sqlcmd \
  -S "$FQDN" -d "$DB" \
  --authentication-method ActiveDirectoryAzCli \
  -v APP_NAME="$APP_NAME" APP_OBJECT_ID="$APP_OBJECT_ID" \
  -i "$SQL_DIR/grant-app-access.sql"

echo "==> Done. The app can now connect via its managed identity."
