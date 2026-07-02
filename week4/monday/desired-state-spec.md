# KijaniKiosk API Server - Desired State Specification

## Identity
- Name: kijanikiosk-api-staging
- Environment tag: staging
- Owner tag: amina

## Compute
- Provider: aws
- Region: ap-south-1 (Asia Pacific – Mumbai)
- Instance type: t3.micro
- Operating system: ubuntu-26.04-lts (exact image ID: [fill in — look up the AMI ID for ap-south-1 via `aws ec2 describe-images` on Tuesday])
# Note: this becomes a Terraform data source on Tuesday — you will look this up dynamically

## Networking
- VPC: Default VPC, 172.31.0.0/16
- Subnet: Default subnet in ap-south-1, 172.31.0.0/20 range (instance received 172.31.15.170)
- Assign public IP: yes

## Access Control
- SSH access: port 22, source 41.139.230.133/32 only (observed client IP at time of login — see open questions)
- HTTP access: port 80, source 0.0.0.0/0
- All other inbound: deny
- All outbound: allow
- Security group: sg-0a7e2797c1ba416a2 (rule set above is intent from the lab constraints, not yet verified rule-by-rule against the console)

## Storage
- Root volume: ~8GB (default), type gp3 — exact size unconfirmed in console, only inferred from `df -h` filesystem usage (6.7G, 39% used)

## Authentication
- SSH key pair name: aws-moringa

## What must NOT exist on this server after provisioning
- No default password authentication
- No services listening other than sshd
- No world-writable directories outside /tmp

## Open questions (things that will need decisions before Terraform can encode this)
- OS version mismatch: the lab's provisioning constraint specifies Ubuntu 22.04 LTS, but `lsb_release -a` on the running instance reports Ubuntu 26.04 LTS ("resolute"). Need to decide whether Tuesday's Terraform should pin 22.04 (per the original constraint) or match the actual 26.04 image — and confirm with Tendo/Amina which is correct.
- Root EBS volume size was never confirmed directly in the console (only inferred from `df -h`); need to check the EC2 console or `aws ec2 describe-volumes` for the real value.
- Security group sg-0a7e2797c1ba416a2's actual rule set (source CIDRs, ports) was not re-verified against the console — only the intended rules from the lab constraints are recorded above.
- SSH source IP (41.139.230.133) is my current client IP, not guaranteed static — Terraform will need either a stable IP/CIDR or a VPN range instead of a hardcoded /32.
- No Environment/Owner tags were applied during manual provisioning even though the Identity section above specifies them — should Terraform enforce tagging that the manual process skipped, or should manual provisioning have matched it exactly?
- Default VPC was reused rather than a dedicated project VPC — worth deciding whether Tuesday's Terraform should create a purpose-built VPC instead.

## Hardest Decision and Why
The hardest decision wasn't really a decision at all — it was the operating system, and I didn't realize I'd gotten it wrong until I cross-referenced the spec against the running instance. The lab's constraint called for Ubuntu 22.04 LTS, but when I picked an image in the AWS console AMI selector, I didn't pin the exact version carefully, and lsb_release -a on the running VM came back as 26.04 LTS. In the console, the AMI picker just shows "Ubuntu Server" with a version dropdown that's easy to click past without checking, so the mismatch was invisible until I actually SSH'd in and ran verification commands. This is exactly the failure mode Tendo warned about: doing it by hand should surface the decisions that automation would otherwise silently get wrong, and here the manual process caught a mistake I wouldn't have noticed if I'd jumped straight to Terraform with an unpinned ubuntu-22.04-lts filter that happened to match whatever image was "latest" at apply time.

