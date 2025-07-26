# Security Example - Use environment variables instead of plain text files
# 
# Instead of storing secrets in variables.secrets.auto.pkrvars.hcl, use:
#
# export PKR_VAR_proxmox_api_token="your-token-here"
# export PKR_VAR_proxmox_username="terraform@pve!terra"
# export PKR_VAR_winrm_password="your-secure-password"
#
# Or use a .env file (ensure it's in .gitignore):
# PKR_VAR_proxmox_api_token=your-token-here
# PKR_VAR_proxmox_username=terraform@pve!terra
# PKR_VAR_winrm_password=your-secure-password
#
# Load with: source .env && packer build .

# Example of using HashiCorp Vault (if available):
# vault kv get -field=api_token secret/proxmox/terraform
# export PKR_VAR_proxmox_api_token=$(vault kv get -field=api_token secret/proxmox/terraform)

# IMPORTANT: Never commit actual secrets to version control!
