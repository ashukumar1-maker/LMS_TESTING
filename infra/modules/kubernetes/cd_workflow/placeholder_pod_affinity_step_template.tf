locals {
  # Keeps the ReadWriteOnce workspace PVC mounted on a live pod so workspace
  # tasks can use pod affinity to stay on the same node throughout the workflow.
  placeholder_pod_affinity_step_template = {
    name   = "workspace-anchor"
    daemon = true
    metadata = {
      labels = {
        (local.workspace_anchor_label_key) = "true"
      }
    }
    container = {
      image   = "bash:5.2-alpine3.20"
      command = ["bash", "-c"]
      args = [
        <<-EOT
        set -euo pipefail
        trap 'exit 0' TERM INT
        while true; do
          sleep 3600 &
          wait "$!"
        done
        EOT
      ]
      volumeMounts = [
        {
          name      = "workspace"
          mountPath = "/workspace"
        },
      ]
    }
  }
}
