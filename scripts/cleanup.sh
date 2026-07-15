#!/usr/bin/env bash
# Usage: ./scripts/cleanup.sh [--purge-state]
#   --purge-state  also deletes the remote state storage account + RG
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/environments/prod" && pwd)"
STATE_RG="${STATE_RG:-raintech-tfstate-rg}"

command -v terraform >/dev/null || { echo "terraform not found"; exit 1; }

cd "$ENV_DIR"
echo "==> terraform destroy"
terraform destroy -input=false

# Key Vault is soft-deleted on destroy; purge so the name can be reused.
if command -v az >/dev/null; then
  KV_NAME="$(terraform output -raw key_vault_name 2>/dev/null || true)"
  if [ -n "${KV_NAME:-}" ]; then
    echo "==> Purging soft-deleted Key Vault $KV_NAME (best effort)"
    az keyvault purge --name "$KV_NAME" --output none 2>/dev/null || true
  fi
fi

if [ "${1:-}" = "--purge-state" ]; then
  echo "==> Deleting remote state resource group $STATE_RG"
  az group delete --name "$STATE_RG" --yes --no-wait
fi

echo "==> Cleanup complete."
