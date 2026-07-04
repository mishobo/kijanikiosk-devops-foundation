# Environment Setup

**Path used**: Optional cloud path (AWS), not the primary Multipass path. All of Week 4
(Monday through Friday) was built against real AWS infrastructure, so Friday's pipeline
continues on the same path rather than switching to local VMs. Everywhere the lab brief
says "Multipass," the AWS equivalent was used instead (EC2 instances in place of local
VMs, an S3 backend in place of local MinIO).

## Control node (this machine)

| Tool | Version |
|------|---------|
| OS | macOS 15.7.7 (Darwin 24.6.0) |
| Terraform | v1.15.7 |
| Ansible | ansible-core 2.21.1 |
| ansible.posix collection | 2.2.0 |
| community.general collection | 13.0.1 |
| AWS CLI | aws-cli/2.35.15 |

## Target servers

| Item | Value |
|------|-------|
| Cloud provider | AWS |
| Region | ap-south-1 (Mumbai) |
| OS image | Ubuntu 22.04 LTS (jammy), looked up dynamically via `aws_ami` data source - no hardcoded AMI ID |
| Instance type | t3.micro (free-tier eligible) |
| Instance count | 3 (api, payments, logs), one service per server |

## Remote state backend

| Item | Value |
|------|-------|
| Backend type | AWS S3 |
| Bucket | kijanikiosk-tfstate-493627063797-ap-south-1 |
| State key (this project) | week4/friday/terraform.tfstate |
| Locking | Native S3 conditional-write locking (`use_lockfile = true`, requires Terraform >= 1.10) - no DynamoDB table needed |
| Encryption | SSE-S3 (AES256), bucket versioning enabled, public access blocked |

This is the cloud-path equivalent of the primary MinIO backend described in the
assignment. Because it is real AWS S3 rather than a local MinIO container, it gets
genuine state locking without the limitation called out for MinIO in
`hardening-decisions.md`.

## Reproducing this environment

1. Configure AWS credentials for account `493627063797`, region `ap-south-1`.
2. Ensure the `aws-moringa` EC2 key pair exists in that region and the matching
   private key is at `~/.ssh/aws-moringa.pem` locally.
3. `terraform/terraform.tfvars` (gitignored) must set `ssh_key_name`,
   `allowed_ssh_cidr` (your current IP), and `subnet_id`.
4. Run `./pipeline.sh` from `week4/friday/`.
