# Home Infrastructure Automation

A comprehensive Infrastructure as Code solution for home lab automation using Talos Linux on Proxmox VE, featuring GitOps deployment with ArgoCD.

## 🏗️ Architecture Overview

- **Virtualization Platform**: Proxmox VE
- **Kubernetes Distribution**: Talos Linux
- **Infrastructure as Code**: Terraform with modular structure
- **GitOps**: ArgoCD for application deployment
- **Container Networking**: Cilium CNI
- **Task Automation**: Task (taskfile.dev)
- **Template Building**: Packer for Windows Server 2025 templates

## 🚀 Quick Start

### Prerequisites

**Required Tools:**
- [Terraform](https://www.terraform.io/) - Infrastructure provisioning
- [Task](https://taskfile.dev/) - Build automation
- [Packer](https://www.packer.io/) - Template building
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes management
- [talosctl](https://www.talos.dev/v1.9/introduction/getting-started/) - Talos cluster management
- [argocd](https://argo-cd.readthedocs.io/en/stable/cli_installation/) - GitOps application management

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/home-infra.git
   cd home-infra
   ```

2. **Configure credentials:**
   ```bash
   # Terraform secrets
   cp terraform/kubernetes/proxmox.secrets.auto.tfvars.template terraform/kubernetes/proxmox.secrets.auto.tfvars
   cp terraform/windows/proxmox.secrets.auto.tfvars.template terraform/windows/proxmox.secrets.auto.tfvars
   
   # Packer environment
   cp packer/windows_server_2025/.env.template packer/windows_server_2025/.env
   
   # Edit files with your actual credentials
   ```

3. **Customize configuration:**
   - Update `terraform/kubernetes/proxmox.auto.tfvars` with your environment details
   - Modify node configurations in `terraform/kubernetes/main.tf`

4. **Deploy infrastructure:**
   ```bash
   task terraform:init
   task terraform:plan
   task terraform:apply
   ```

## 📁 Repository Structure

```
├── terraform/kubernetes/     # Main Kubernetes cluster IaC
│   ├── modules/             # Reusable Terraform modules
│   │   ├── talos/          # Talos Linux cluster module
│   │   ├── proxmox_csi_plugin/ # Storage integration
│   │   └── volumes/        # Persistent volume management
│   └── output/             # Generated configs (kubeconfig, etc.)
├── k8s/                    # Kubernetes manifests (GitOps)
│   ├── infra/             # Infrastructure components
│   ├── apps/              # Application deployments
│   └── sets/              # ArgoCD ApplicationSets
├── packer/windows_server_2025/ # Windows template automation
└── sensitive-templates/    # Templates for sensitive configs
```

## 🔐 Security Best Practices

### Credential Management
- **Never commit secrets**: All sensitive files are gitignored
- **Use templates**: Provided `.template` files for easy setup
- **Environment variables**: Packer uses `PKR_VAR_*` pattern
- **Sealed secrets**: Kubernetes secrets are sealed with kubeseal

### Network Security
- **Private networks**: Uses RFC 1918 address space
- **Certificate management**: Automatic cert rotation with cert-manager
- **Pod security**: Enforced pod security standards

## 🛠️ Development Workflow

### Infrastructure Changes
```bash
# Plan changes
task terraform:plan

# Apply changes
task terraform:apply

# Destroy (if needed)
task terraform:destroy
```

### Application Deployment
```bash
# Deploy through GitOps (ArgoCD will auto-sync)
kubectl apply -k k8s/sets/

# Manual deployment (for testing)
kubectl kustomize k8s/apps/dev/whoami | kubectl apply -f -
```

### Windows Template Building
```bash
# Validate Packer config
task packer:validate

# Build template
task packer:build

# Interactive menu
./packer/windows_server_2025/packer_build.sh
```

## 📊 Monitoring and Observability

- **Metrics**: Prometheus stack with Grafana dashboards
- **Network observability**: Hubble for Cilium insights
- **Talos metrics**: Dedicated metric server integration
- **Application monitoring**: Built-in health checks and probes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes in your environment
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Heavily inspired by Vegard S. Hagen's Home lab:
- [Blog](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/)
- [Github](https://github.com/vehagn/homelab)

## 🔍 Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.
