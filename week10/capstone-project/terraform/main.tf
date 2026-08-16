terraform {
  required_version = ">= 1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }
}

# IMPORTANT: this repo's kubectl default context has previously pointed at a
# foreign production cluster (see docs/runbook.md). We pin the Terraform
# kubernetes provider to the minikube context explicitly rather than relying
# on whatever the ambient kubeconfig current-context happens to be.
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

# kijani-staging is provisioned here, isolated from the kijani-project
# (production) namespace that Week 9 created manually with kubectl. Staging
# only ever exists if this module has been applied — there is no manual
# fallback.
resource "kubernetes_namespace" "staging" {
  metadata {
    name = var.staging_namespace
    labels = {
      environment = "staging"
      managed-by  = "terraform"
      app         = "kijanikiosk"
    }
  }
}

# Bucket names are declared once here and read by Ansible (via terraform
# output) and by the Kubernetes ConfigMap the Ansible role renders, so the
# receipts bucket name can never drift between the k8s layer and the
# serverless.yml custom.receiptsBucket value. See docs/runbook.md
# "Integration seam" for the failure mode this prevents.
locals {
  receipts_bucket = "kijani-payments-receipts-${var.stage}"
}
