# home-infra

Kubernetes (Talos Linux) on Proxmox VE. Terraform for infra, ArgoCD for GitOps, Packer for VM templates, Task for automation. Public GitHub repo — no secrets ever.

## Hard Constraints

- **No secrets in code**: All sensitive files are encrypted with git-crypt and must be committed — never gitignored. This includes `*.secrets.auto.tfvars`, `*.secrets.auto.pkrvars.hcl`, `**/.env`, `backend.config`, `sensitive/**`, `*.key`, `*.pem`. Provide `.template` files alongside them.
- **No `kubectl apply` for ArgoCD apps**: Commit to `main` and let ArgoCD sync. Direct apply only for non-managed resources.
- **No SSH to nodes**: Talos has no SSH — all node management via `talosctl`.
- **No `null_resource`**: Use `terraform_data` instead.
- **No `count` for conditional resources**: Use `for_each`.
- **No `latest` image tags**: Always pin. Renovate manages updates.
- **No `.gitleaks.toml` edits**: Requires explicit user approval.
- **git-crypt**: Binary-looking files are encrypted. Never modify them — user must run `git-crypt unlock` first.
- **`dotenv` in root Taskfile only**: Never declare `dotenv` in included Taskfiles — env vars are inherited automatically.

## Tool Preferences

- **Prefer `task` over raw CLI**: `task azure-global:plan` instead of `terraform plan`. Task handles env, working dir, and secrets.
- **Fish shell** in devcontainer — use Fish syntax in shell snippets unless inside a `.sh` file.
- **Env vars are auto-set**: `KUBECONFIG`, `TALOSCONFIG`, `KUBE_CONFIG_PATH` — no extra flags needed.

## Pre-approved vs. Confirmation-Required

| Pre-approved (runs automatically) | Requires confirmation |
|---|---|
| `terraform plan/validate/fmt` | `terraform apply/destroy` |
| `kubectl get/describe/logs/diff` | `kubectl apply/delete/exec` |
| `talosctl health/get/version` | `talosctl apply-config/reset/upgrade` |
| `argocd app get/list/diff` | `argocd app sync/delete` |
| `packer validate/inspect/init` | `packer build` |
| `git status/diff/log/show` | `git push` |
| `task *` (all) | — |

## Response Format

| Context | Format |
|---|---|
| Terraform | Show `plan` summary; highlight destroys/replaces; never auto-apply |
| Kubernetes | Show `kubectl diff` or ArgoCD diff; note GitOps sync delay |
| Packer | Validate first; warn ISO builds take 1-3h |
| Pre-commit failures | Group by hook type; suggest specific fix per hook |

## Custom Slash Commands

- `/tf-plan <workspace>` — Terraform plan summary (never applies)
- `/validate-all [path]` — Pre-commit hooks grouped by type
- `/k8s-status` — Read-only cluster health report
- `/argocd-sync <app>` — ArgoCD app state and diff (never syncs)
- `/seal-secret <path>` — Seal a secret via Sealed Secrets

## Path-Scoped Rules

Loaded automatically when working in these directories:

- `terraform/**` → `.claude/rules/terraform.md` — workspace inventory, provider notes, git-crypt context
- `k8s/**` → `.claude/rules/kubernetes.md` — GitOps model, sealed secrets, namespace conventions
- `packer/**` → `.claude/rules/packer.md` — build modes, credential pattern, known past mistakes

## MCP Servers

| Server | Capabilities |
|---|---|
| `github` | PRs, issues, code search, Actions workflows |
| `terraform` | Provider/module docs from public registry |

Config: `.mcp.json`. See `.github/copilot-instructions.md` for setup details and optional servers.
