locals {
  oidc_enabled = coalesce(local.talos_cluster_enriched.oidc_issuer_url, "") != "" && coalesce(local.talos_cluster_enriched.oidc_client_id, "") != ""
  kube_config_oidc_user = local.oidc_enabled ? {
    users = [
      {
        name = "oidc-user"
        user = {
          exec = {
            apiVersion      = "client.authentication.k8s.io/v1"
            command         = "kubectl"
            interactiveMode = "Never"
            args = [
              "oidc-login",
              "get-token",
              "--oidc-issuer-url=${local.talos_cluster_enriched.oidc_issuer_url}",
              "--oidc-client-id=${local.talos_cluster_enriched.oidc_client_id}",
              "--oidc-extra-scope=groups",
              "--oidc-extra-scope=email",
              "--oidc-extra-scope=name",
              "--oidc-extra-scope=sub",
              "--oidc-extra-scope=email_verified"
            ]
          }
        }
      }
    ]
  } : null

  kube_config_oidc_context = local.oidc_enabled ? {
    contexts = [
      {
        name = "oidc-context"
        context = {
          cluster   = local.talos_cluster_enriched.name
          namespace = "default"
          user      = local.kube_config_oidc_user.users[0].name
        }
      }
    ],
    current-context = "oidc-context"
  } : null
}

data "utils_yaml_merge" "kube_config_oidc" {

  input = [
    talos_cluster_kubeconfig.this.kubeconfig_raw,
    yamlencode(local.kube_config_oidc_user),
    yamlencode(local.kube_config_oidc_context)
  ]
}
