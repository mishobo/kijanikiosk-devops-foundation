output "server_public_ips" {
  description = "Public IP addresses of every provisioned server, keyed by server name"
  value       = { for k, s in module.app_servers : k => s.public_ip }
}

output "server_instance_ids" {
  description = "Instance IDs of every provisioned server, keyed by server name"
  value       = { for k, s in module.app_servers : k => s.instance_id }
}

output "ssh_commands" {
  description = "Ready-to-run SSH commands for each server, keyed by server name"
  value = {
    for k, s in module.app_servers :
    k => "ssh -i ~/.ssh/${var.ssh_key_name}.pem ubuntu@${s.public_ip}"
  }
}

# Individual -raw-friendly outputs so pipeline.sh can extract one IP at a time
# (terraform output -raw api_server_ip) without parsing the map above.
output "api_server_ip" {
  description = "Public IP address of the api server"
  value       = module.app_servers["api"].public_ip
}

output "payments_server_ip" {
  description = "Public IP address of the payments server"
  value       = module.app_servers["payments"].public_ip
}

output "logs_server_ip" {
  description = "Public IP address of the logs server"
  value       = module.app_servers["logs"].public_ip
}
