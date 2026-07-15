#!/usr/bin/env bash

# Usage:   ./scripts/setup.sh [apply]
#   - no arg : init + plan only (safe, no changes)
#   - apply  : init + plan + apply
set -euo pipefail

# ---- Config (override via env) ----------------------------------------------
LOCATION="${LOCATION:-southeastasia}"
STATE_RG="${STATE_RG:-raintech-tfstate-rg}"
STATE_SA="${STATE_SA:-raintechtfstate}"
STATE_CONTAINER="${STATE_CONTAINER:-tfstate}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$SCRIPT_DIR/../infra/environments/prod"
ENV_DIR="$(cd "$ENV_DIR" && pwd)"

command -v az >/dev/null || { echo "az CLI not found"; exit 1; }
command -v terraform >/dev/null || { echo "terraform not found"; exit 1; }

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
echo "Subscription : $SUBSCRIPTION_ID"
echo "Location     : $LOCATION"
echo "State backend: $STATE_RG / $STATE_SA / $STATE_CONTAINER"

# ---- 1. Remote state backend (idempotent) -----------------------------------
echo "==> Ensuring state resource group..."
az group create --name "$STATE_RG" --location "$LOCATION" --output none

echo "==> Ensuring state storage account..."
if ! az storage account show --name "$STATE_SA" --resource-group "$STATE_RG" --output none 2>/dev/null; then
  az storage account create \
    --name "$STATE_SA" --resource-group "$STATE_RG" --location "$LOCATION" \
    --sku Standard_LRS --encryption-services blob --min-tls-version TLS1_2 \
    --allow-blob-public-access false --output none
fi

echo "==> Ensuring state container..."
az storage container create \
  --name "$STATE_CONTAINER" --account-name "$STATE_SA" \
  --auth-mode login --output none

# ---- 2. Terraform init + plan -----------------------------------------------
cd "$ENV_DIR"
echo "==> terraform init"
terraform init -backend-config=backend.config -input=false

echo "==> terraform plan"
terraform plan -input=false -out=tfplan

if [ "${1:-}" = "apply" ]; then
  echo "==> terraform apply"
  terraform apply -input=false tfplan

  # Data-plane step: grant the app's managed identity a SQL user (Terraform can't).
  echo "==> Granting SQL access to the app managed identity..."
  if command -v sqlcmd >/dev/null; then
    "$SCRIPT_DIR/grant-sql-access.sh"
  else
    echo "  sqlcmd not found — after 'brew install sqlcmd', run: scripts/grant-sql-access.sh"
  fi

  echo "==> Done. App URL:"
  terraform output -raw app_url
else
  echo
  echo "Plan written to tfplan. Review it, then apply with:"
  echo "  cd $ENV_DIR && terraform apply tfplan"
fi
