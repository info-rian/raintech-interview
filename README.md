# Azure DevOps Challenge — Node.js on App Service

A minimal Node.js web app deployed to **Azure App Service (Free F1)** with an
**Azure SQL Database (serverless)** backend, provisioned entirely by **Terraform**
and shipped by **GitHub Actions**. The app reaches SQL with **no password anywhere** —
it authenticates via its **managed identity** (Entra ID). It also includes Key Vault,
Azure Monitor alerts, Log Analytics, enforced HTTPS, a health endpoint, and a rollback
mechanism.


## Overview
- **App** (`app/`): Express server.
- **Infra** (`infra/`): Terraform, two-layer — a thin `environments/prod` composition
  root over reusable, categorized `modules/` (resource-group, key-vault, mssql,
  log-analytics, alerts, app-service).
- **CI/CD** (`.github/workflows/`):
  - `ci.yml` — fast gate on every push/PR: gitleaks secret scan, app test + build,
    Terraform fmt/validate/tflint/tfsec.
  - `cd.yml` — path-aware continuous deployment on push to `main`.
  - `rollback.yml` — manual, SHA-pinned app redeploy.


## CI/CD pipeline
`cd.yml` detects which part of the monorepo changed and acts accordingly — all in a
single workflow so ordering is guaranteed:

- **`app/**` changed** → build, test, and deploy the app to App Service (OIDC).
- **`infra/**` changed** → `terraform plan`, then `terraform apply` **behind a manual
  approval gate** (the `production-infra` environment's required reviewers).
- **Both changed** → the **app deploys first**; the infra apply `needs` it and won't
  proceed if the app deploy fails.

Authentication is **OIDC** end-to-end (no stored credentials); the Terraform backend
uses AAD auth (no storage keys). Rollback details below.

## Prerequisites
- Azure subscription (`az login`), Azure CLI
- Terraform ≥ 1.13
- Node.js ≥ 24
- `sqlcmd` (go-sqlcmd) — for the one-time managed-identity DB grant (`brew install sqlcmd`)
- A GitHub repo with Actions enabled

## Setup instructions

### 1. Clone
```bash
git clone <this-repo> && cd iac-azure
```

### 2. Provision the infrastructure (Terraform)
```bash
cd infra/environments/prod
cp terraform.tfvars.example terraform.tfvars   # set subscription_id + alert_email
```

```bash
../../../scripts/setup.sh apply
```
Or manually:
```bash
terraform init -backend-config=backend.config
terraform plan  -out=tfplan
terraform apply tfplan
../../../scripts/grant-sql-access.sh   # create the app's contained SQL user
```
Key outputs:
```bash
terraform output app_url               # public URL
terraform output app_name              # -> GitHub variable AZURE_WEBAPP_NAME
terraform output resource_group_name   # -> GitHub variable AZURE_RESOURCE_GROUP
```

### 3. Database access is passwordless
The App Service **managed identity** is a least-privilege contained user
(`db_datareader`/`db_datawriter`) in the database; SQL password auth is disabled
(Entra-only). `scripts/grant-sql-access.sh` creates that user — a one-time data-plane
step Terraform can't do, run as the SQL Entra admin (whoever ran `terraform apply`).
No connection string or password lives in Key Vault or app settings.

### 4. Configure GitHub Actions (OIDC — no stored credentials)
Create an Entra app registration with **federated credentials** for this repo
and grant its service principal:
- **Contributor** (subscription) — manage resources
- **User Access Administrator** (subscription) — the stack creates a Key Vault role assignment
- **Storage Blob Data Contributor** (state storage account) — AAD auth for the TF backend

Then set in the GitHub repo (Settings → Secrets and variables → Actions):

| Kind | Name | Value |
|------|------|-------|
| Secret | `AZURE_CLIENT_ID` | federated app client ID |
| Secret | `AZURE_TENANT_ID` | tenant ID |
| Secret | `AZURE_SUBSCRIPTION_ID` | subscription ID |
| Variable | `ALERT_EMAIL` | address for Azure Monitor alerts |
| Variable | `AZURE_WEBAPP_NAME` | `terraform output app_name` |
| Variable | `AZURE_RESOURCE_GROUP` | `terraform output resource_group_name` |

Create an environment named **`production-infra`** with **required reviewers** — this is
the infra approval gate. 


### 5. Access the app
```bash
curl "$(terraform output -raw app_url)"          # Hello World + DB read
curl "$(terraform output -raw app_url)/healthz"  # {"status":"ok",...}
```

## Monitoring & logging
Log Analytics collects App Service logs/metrics (capped at 0.5 GB/day to respect the
~5 GB free grant). Azure Monitor alerts fire on **CPU > 80%** (plan) and **HTTP 5xx >
10** (app) to an email action group. `/healthz` is the health probe.

## Security measures
**Passwordless database access** — the app authenticates to Azure SQL with its
managed identity.
credential to store or rotate anywhere. 
**OIDC** for CI/CD (no publish profile/secret)
**AAD auth** for the Terraform backend (no storage keys). Key Vault (RBAC) is available
**HTTPS enforced**, TLS 1.2, FTPS disabled.
**DevSecOps** `gitleaks` secret scan + `tfsec`


## Cleanup instructions
Avoid consuming free-tier limits when done:
```bash
./scripts/cleanup.sh                 # terraform destroy + purge Key Vault
./scripts/cleanup.sh --purge-state   # also delete the remote-state storage
```

## Rollback mechanism
Manual **Rollback** workflow (`rollback.yml`) rebuilds and redeploys any previous
commit by SHA — works for any commit at any time, app-only (never touches infra).
Every deploy stamps the live commit into `APP_COMMIT_SHA` (shown on `GET /`) so you
can confirm what's running. For a quick "undo the last deploy," re-running the previous
CD run from the Actions history also works


## Disaster recovery plan
The single most important thing here is that **everything is reproducible from Git**. The
infrastructure is Terraform, the app is source code plus the pipeline, and the state is
stored safely in Azure. That one fact is what makes recovery fast.

Now, for a full **region outage**, there are two levels of strategy, and the right one
depends on your budget and how much downtime you can tolerate.

**Cold DR — the low-cost option.** You keep *nothing* running in the second region. If
the primary region goes down, you change the `location` in `locals.tf`, run
`terraform apply` to stand the whole stack up somewhere else, and redeploy the app
through the pipeline. Because it's all code, this genuinely works — recovery is on the
order of minutes to tens of minutes. You pay almost nothing until the day you need it.
The trade-off is a slower recovery and a fresh database from your last restore point.

**Warm DR — the faster, pricier option.** Here you keep a secondary region *partly
alive*. You'd add SQL **geo-replication** or a failover group so a standby database is
continuously kept in sync, run a second App Service in the other region, and put **Azure
Front Door** in front to route traffic and fail over automatically. When the primary
fails, traffic shifts to the standby in seconds to a minute, with almost no data loss.
The trade-off is simply cost — you're paying for that standby capacity all the time.
