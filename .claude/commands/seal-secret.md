Seal a Kubernetes secret using the Sealed Secrets controller.

## Usage

`/seal-secret <path-to-secret-file>`

The argument should be the path to a plaintext Kubernetes Secret manifest in the `sensitive/` directory.

## Steps

1. Validate that the file path is inside `sensitive/` — refuse to process files outside this directory.

2. Run the seal task:
   ```bash
   task k8s:seal:secret FILE=$ARGUMENTS
   ```

3. Show the output path of the sealed secret file.

4. Remind the user of the correct destination path based on the secret type:

   | Secret Type | Destination in k8s/ |
   |-------------|---------------------|
   | Infrastructure secrets (TLS, credentials) | `k8s/infra/<component>/` |
   | Application secrets | `k8s/apps/<app-name>/` |
   | Cluster-wide secrets | `k8s/infra/sealed-secrets/` |

5. Remind the user to:
   - Copy the sealed secret to the appropriate `k8s/` path
   - Commit only the **sealed** secret (not the plaintext from `sensitive/`)
   - The `sensitive/` directory is gitignored — never commit files from it

## Security Notes

- **Never read, display, or reference the contents of files in `sensitive/`** — they contain plaintext secrets.
- The sealed secret is safe to commit — it is encrypted with the cluster's public key and can only be decrypted by the Sealed Secrets controller in the cluster.
- If the seal command fails, the Sealed Secrets controller may not be running — check with `kubectl get pods -n kube-system -l app.kubernetes.io/name=sealed-secrets`.
