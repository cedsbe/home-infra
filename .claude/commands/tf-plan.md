Run a Terraform plan for the specified workspace and summarize the results.

## Usage

`/tf-plan <workspace>`

Valid workspaces: `kubernetes`, `azure-global`, `azure-landing`

## Steps

1. Validate the workspace argument is one of the known workspaces listed above.

2. Check that `backend.config` exists in the workspace directory. If it does not exist, inform the user that the backend is not initialized and they should run `task <workspace>:init` first.

3. Run the plan via Task:
   ```bash
   task <workspace>:plan
   ```

4. Parse and summarize the plan output:
   - Total resources: to add, to change, to destroy
   - List any **destroy** operations with their resource addresses — these require explicit human review before applying
   - List any **replace** (destroy + create) operations
   - Note any data source refreshes (informational only)

5. If there are destroys or replacements, add a clear warning:
   > ⚠ **Human review required**: The plan includes N destroy/replace operations. Review each carefully before running `task <workspace>:apply`.

6. **Never run `terraform apply` or `task <workspace>:apply`** — present the plan summary and tell the user to apply manually if they approve.

## Notes

- If the `$ARGUMENTS` placeholder is empty, ask the user which workspace to plan.
- If credentials are missing (`.secrets.auto.tfvars` not present or git-crypt locked), the plan will fail — remind the user to unlock git-crypt or provide credentials.
- Fish shell is used inside the devcontainer — `task` commands work directly.
