# Kubernetes CRDs

Installs cluster-level Kubernetes extensions that must exist before typed
`kubernetes_manifest` resources can be planned.

This module currently installs External Secrets Operator, cert-manager,
ingress-nginx, Argo Workflows, and their CRDs. Keep cluster extension
controllers here so config modules can use typed `kubernetes_manifest`
resources after the extensions exist.

cert-manager and ingress-nginx provide the portable ingress path for both GKE
and AKS. The config module creates a `ClusterIssuer` and backend `Ingress`; this
module only installs the reusable controllers they depend on.

Environment roots can pass `ingress_nginx_load_balancer_ip` to assign a
reserved static public IP to the ingress-nginx controller service. DNS for
`api.<domain_name>` should point at that same IP.
