# Manual Provisioning Decisions - KijaniKiosk API Server

| Decision          | Value I chose | Reason |
|-------------------|---------------|--------|
| Cloud provider    | AWS (EC2) | Free-tier eligible, well-documented, and the provider the team will target in Tuesday's Terraform session |
| Region            | ap-south-1 (Asia Pacific – Mumbai) | Closest full-service AWS region to Nairobi with free-tier availability |
| Operating system  | Ubuntu 26.04 LTS (confirmed via `lsb_release -a`, codename "resolute") | Latest LTS available in the AMI picker at launch time |
| Instance type     | t3.micro | Free-tier eligible, 1 vCPU / 1GiB RAM (confirmed via `free -h`: 908Mi total) — smallest size adequate for a staging API server |
| VPC               | Default VPC (172.31.0.0/16) | Reused the account's default VPC instead of creating a new one; no dedicated Week 2 VPC was available to reuse |
| Subnet            | Default subnet in ap-south-1, 172.31.0.0/20 range (instance got 172.31.15.170) | Default subnet auto-assigns a public IP, simplest path for a single staging instance |
| Security group    | sg-0a7e2797c1ba416a2 | Assigned to control inbound access (intent: SSH 22 restricted to my IP, HTTP 80 open, all else denied) |
| SSH key pair      | aws-moringa (aws-moringa.pem) | Existing key pair, private key held locally, used for all SSH access |
| Root volume size  | ~8GB (default gp3, unconfirmed in console — `df -h` shows 6.7G filesystem after overhead) | Default EBS root size for the Ubuntu AMI, sufficient for OS + small app footprint |
| Public IP?        | Yes | Auto-assigned by the default subnet; required to SSH in from my local machine (observed client IP 41.139.230.133) |
| Tags / labels     | Name: moringadevops14 | Only a Name tag was set at launch; no Environment/Owner tags applied |