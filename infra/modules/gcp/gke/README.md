# GKE Module

Creates the GCP Kubernetes cluster infrastructure used by the GCP deployment
module.

This module is intentionally GCP-specific. Kubernetes-facing names needed by
the cluster, such as backend and External Secrets namespaces and service
accounts, are defaulted in this module and exposed through outputs for later
root-level Kubernetes modules. Environment roots and deployment wrapper modules
do not pass these names through Terraform variables.
