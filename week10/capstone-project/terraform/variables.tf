variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used to reach the target cluster."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "kubeconfig context to use. Pinned explicitly so this never targets an unintended cluster (see docs/runbook.md)."
  type        = string
  default     = "minikube"
}

variable "staging_namespace" {
  description = "Name of the isolated staging namespace."
  type        = string
  default     = "kijani-staging"
}

variable "stage" {
  description = "Deployment stage name, shared with serverless.yml's custom.stage and the receipts bucket name."
  type        = string
  default     = "staging"
}
