output "api_server_public_ip" {
  description = "Public IP address of the KijaniKiosk API server"
  value       = aws_instance.kk_api.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the API server"
  value       = "ssh -i ~/.ssh/aws-moringa.pem ubuntu@${aws_instance.kk_api.public_ip}"
  sensitive   = false   # Set to true for outputs that contain secrets
}