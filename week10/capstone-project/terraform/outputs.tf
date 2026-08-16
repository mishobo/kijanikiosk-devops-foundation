output "staging_namespace" {
  description = "Name of the staging namespace, consumed by the Ansible inventory and the Jenkins staging deploy stage."
  value       = kubernetes_namespace.staging.metadata[0].name
}

output "receipts_bucket" {
  description = "Staging receipts bucket name, consumed by Ansible when rendering the kk-payments-config-staging ConfigMap and by serverless.yml's custom.receiptsBucket."
  value       = local.receipts_bucket
}
