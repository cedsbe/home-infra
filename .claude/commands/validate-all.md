Run pre-commit validation and report results grouped by hook type.

## Usage

`/validate-all [path]`

- No argument: validates all files (`--all-files`)
- With path argument: validates only the specified file(s) (`--files $ARGUMENTS`)

## Steps

1. Run pre-commit:
   ```bash
   # All files
   pre-commit run --all-files

   # Specific path (if $ARGUMENTS provided)
   pre-commit run --files $ARGUMENTS
   ```

2. Parse the output and group failures by hook:

   | Hook | Suggested Fix |
   |------|--------------|
   | `terraform_fmt` | Run `terraform fmt <dir>` |
   | `terraform_validate` | Check for syntax errors in the flagged `.tf` files |
   | `terraform_tflint` | Review tflint warnings, check `.tflint.hcl` config |
   | `yamllint` | Fix indentation or syntax in flagged YAML files |
   | `cspell` | Add unknown words via `task spell_add_word WORD=<word>` or update `.cspell.json` |
   | `gitleaks` | Remove any detected secrets — check `.gitleaks.toml` for allowlist patterns |
   | `trailing-whitespace` | Run `pre-commit run trailing-whitespace --all-files` (it auto-fixes) |
   | `end-of-file-fixer` | Run `pre-commit run end-of-file-fixer --all-files` (it auto-fixes) |
   | `packer-validate` | Run `task packer:validate` for details |
   | `kubernetes-validate` | Check `kubeconform` output for schema violations |

3. **Do not auto-fix** — present the grouped errors and suggested fixes. The user must approve each fix.

4. Report a summary:
   - Hooks passed: N
   - Hooks failed: N (list them)
   - Hooks skipped: N

## Notes

- The `mixed-line-ending` hook can auto-fix; `pretty-format-json` also auto-fixes. These are safe to re-run.
- `gitleaks` failures require careful investigation — never suggest bypassing or allowlisting without user review.
- The `.pre-commit-config.yaml` excludes encrypted files (`*.secrets.auto.tfvars`, `backend.config`, etc.) — failures on those paths indicate a configuration issue.
