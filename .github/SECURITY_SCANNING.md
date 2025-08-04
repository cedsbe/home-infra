# Security Scanning Configuration

## Private Repository Security Scanning

This repository uses **Trivy** for infrastructure security scanning. Since this is a private repository, GitHub Advanced Security features (Code Scanning, Security tab) are not available without an Enterprise license.

## Current Workflow Features

Our `.github/workflows/pre-commit.yml` includes:

- ✅ **Trivy security scanning** with table and SARIF output
- ✅ **Workflow artifact upload** for result storage
- ✅ **Console output** for immediate feedback
- ✅ **Private repository optimized** (no SARIF upload attempts)

## Workflow Behavior

### Security Scan Results:
- ✅ Results displayed in workflow console output
- ✅ Detailed results saved as workflow artifacts
- ✅ Both human-readable (table) and machine-readable (SARIF) formats
- ✅ 30-day artifact retention for historical analysis

## Accessing Results

### Workflow Console (immediate feedback):
1. Go to **Actions** → Select workflow run
2. Click on **Security scan** job
3. View results in **Display Trivy scan summary** step

### Workflow Artifacts (detailed analysis):
1. Go to **Actions** → Select workflow run
2. Download **trivy-security-scan** artifact
3. Contains both `trivy-results.txt` and `trivy-results.sarif`

## GitHub Advanced Security (Enterprise Feature)

To enable GitHub Code Scanning and Security tab integration, you would need:

### Requirements:
- GitHub Enterprise Cloud or GitHub Enterprise Server
- Advanced Security license for private repositories
- Repository admin permissions

### Setup (if available):
1. Navigate to **Settings** → **Code security and analysis**
2. Enable **Code scanning alerts**
3. Workflow would automatically upload SARIF results to Security tab

## Troubleshooting

### No Security Results:
- Check that Trivy found configuration files to scan
- Review **Run Trivy vulnerability scanner** step logs
- Ensure repository contains infrastructure files (Terraform, Kubernetes, etc.)

### Understanding Results:
- **HIGH/CRITICAL** findings should be addressed promptly
- **MEDIUM** findings should be reviewed and planned
- **LOW/INFO** findings are informational
- SARIF format can be imported into security analysis tools

## Integration with Pre-commit

The security scan runs parallel to pre-commit hooks:
- **Pre-commit**: Validates code quality, format, and secrets
- **Trivy**: Scans for infrastructure security vulnerabilities
- **Gitleaks**: Prevents secret leakage (via pre-commit hook)
- All must pass for successful CI/CD pipeline

## Alternative Security Tools for Private Repos

Since GitHub Advanced Security isn't available, consider:

### Local Security Scanning:
```bash
# Run Trivy locally
task trivy_install  # If implemented
trivy config .

# Run gitleaks locally
task gitleaks_detect
```

### Third-party Integrations:
- **Snyk**: Infrastructure as Code scanning
- **Checkov**: Policy-as-code validation
- **Terrascan**: Terraform security scanning
- **KICS**: Infrastructure security scanning
