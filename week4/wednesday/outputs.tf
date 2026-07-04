output "server_public_ips" {
  description = "Public IP addresses of every provisioned server, keyed by server name"
  value       = { for k, s in module.app_servers : k => s.public_ip }
}

output "server_instance_ids" {
  description = "Instance IDs of every provisioned server, keyed by server name"
  value       = { for k, s in module.app_servers : k => s.instance_id }
}
