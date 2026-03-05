Show the current state and pending diff for an ArgoCD application. Does NOT trigger a sync.

## Usage

`/argocd-sync <app-name>`

## Steps

1. Get application details:
   ```bash
   argocd app get $ARGUMENTS
   ```

2. Show the diff between live state and desired state:
   ```bash
   argocd app diff $ARGUMENTS
   ```

3. Summarize the output:
   - **App name, project, namespace**
   - **Sync status**: Synced / OutOfSync / Unknown
   - **Health status**: Healthy / Progressing / Degraded / Suspended / Missing / Unknown
   - **Last sync**: timestamp and commit SHA
   - **Diff summary**: list of resources that would change (added/modified/deleted)

4. If the app is OutOfSync, present the diff clearly and add:
   > ℹ To sync this application, run manually:
   > ```bash
   > argocd app sync $ARGUMENTS
   > ```
   > Or let ArgoCD auto-sync if enabled for this app.

5. **Never run `argocd app sync`** — this command is in the deny list and must be triggered manually by the user.

## Notes

- ArgoCD manages apps from the `k8s/` directory in this repo. Changes are deployed by pushing to `main`, not by manual syncing.
- If the app shows `OutOfSync` but the repo is up to date, check for drift (manual changes made outside GitOps).
- If `$ARGUMENTS` is empty, list all apps with `argocd app list` and ask the user which one to inspect.
