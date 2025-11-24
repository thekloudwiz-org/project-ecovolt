# EcoVolt AWS Infrastructure

> Production-ready AWS infrastructure for EcoVolt's electric vehicle battery swapping platform in Kenya

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-eu--central--1-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Documentation](#documentation)
- [Modules](#modules)
- [Environments](#environments)
- [CI/CD](#cicd)
- [Security](#security)
- [Cost Optimization](#cost-optimization)
- [Contributing](#contributing)
- [Support](#support)

## 🎯 Overview

EcoVolt's AWS infrastructure supports a battery swapping network for electric vehicles in Kenya. The infrastructure handles:

- **IoT Device Management**: 1000+ electric bikes and battery swap stations
- **Real-time Telemetry**: High-velocity data streaming and processing
- **Analytics Pipeline**: Time-series data storage and analysis
- **User Management**: Mobile app and admin portal authentication
- **API Backend**: RESTful APIs for all operations
- **Monitoring & Alerts**: Comprehensive observability

### Key Metrics

- **Region**: EU Central 1 (Frankfurt) - Primary
- **DR Region**: EU West 1 (Ireland)
- **Availability**: Multi-AZ deployment
- **Latency to Nairobi**: ~200ms
- **Estimated Cost**: $200-2000/month (dev to prod)

## 🏗️ Architecture

![Architecture Diagram](docs/architecture-diagram.png)

### High-Level Components

```
┌─────────────────────────────────────────────────────────────┐
│                     EcoVolt Platform                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  IoT Devices → IoT Core → Kinesis → Lambda → Timestream    │
│                    ↓                    ↓                    │
│              IoT Greengrass        DynamoDB                  │
│                                         ↓                    │
│  Mobile App → API Gateway → Lambda → RDS PostgreSQL         │
│                    ↓                    ↓                    │
│              CloudFront            ElastiCache               │
│                                                              │
│  Monitoring: CloudWatch + X-Ray + SNS Alerts               │
│  Security: Cognito + WAF + GuardDuty + Secrets Manager     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

For detailed architecture, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## ✨ Features

### Infrastructure

- ✅ **Multi-AZ VPC** with public, private, and data subnets
- ✅ **IoT Core** for device connectivity (MQTT)
- ✅ **IoT Greengrass** for edge computing
- ✅ **Kinesis Data Streams** for telemetry ingestion
- ✅ **Timestream** for time-series data storage
- ✅ **RDS PostgreSQL** with automatic backups
- ✅ **DynamoDB** for high-velocity operational data
- ✅ **ElastiCache Redis** for caching
- ✅ **Lambda** functions for serverless compute
- ✅ **API Gateway** with Cognito authentication
- ✅ **CloudFront** CDN with WAF protection
- ✅ **S3** data lake with lifecycle policies

### Security

- ✅ **Cognito** user pools for authentication
- ✅ **Secrets Manager** for credential management
- ✅ **KMS** encryption for data at rest
- ✅ **WAF** for API and CloudFront protection
- ✅ **GuardDuty** for threat detection
- ✅ **CloudTrail** for audit logging
- ✅ **VPC Flow Logs** for network monitoring

### Monitoring & Operations

- ✅ **CloudWatch** dashboards and alarms
- ✅ **X-Ray** distributed tracing
- ✅ **SNS** notifications (email + SMS)
- ✅ **AWS Budgets** with cost alerts
- ✅ **AWS Config** for compliance

### DevOps

- ✅ **GitHub Actions** CI/CD with OIDC
- ✅ **Terraform** infrastructure as code
- ✅ **Property-based testing** with Terratest
- ✅ **Automated security scanning** (tfsec + Checkov)
- ✅ **Multi-environment** support (dev/staging/prod)

## 📦 Prerequisites

### Required Tools

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) >= 2.0
- [Go](https://golang.org/dl/) >= 1.21 (for testing)
- [Python](https://www.python.org/downloads/) >= 3.11 (for Lambda functions)
- [Make](https://www.gnu.org/software/make/) (usually pre-installed)

### AWS Account Setup

1. AWS Account with appropriate permissions
2. S3 bucket for Terraform state: `thekloudwiz-tf-state-bucket`
3. DynamoDB table for state locking: `terraform-state-locks`
4. IAM roles for GitHub Actions (OIDC)

### Installation

```bash
# macOS
brew install terraform awscli go python@3.11

# Verify installations
terraform version
aws --version
go version
python3 --version
```

## 🚀 Quick Start

### 1. Clone and Initialize

```bash
# Clone the repository
git clone https://github.com/thekloudwiz-org/ecovolt-infrastructure.git
cd ecovolt-infrastructure

# Initialize Terraform for dev environment
make init-dev
```

### 2. Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="eu-central-1"
```

### 3. Review and Deploy

```bash
# Validate configuration
make validate

# Plan changes
make plan dev

# Apply changes
make apply dev
```

### 4. Test with IoT Simulator

```bash
# Install dependencies
pip install boto3

# Run simulator
python scripts/iot_simulator.py --bikes 5 --stations 2
```

## 📁 Project Structure

```
.
├── README.md                    # This file
├── CONTRIBUTING.md              # Contribution guidelines
├── Makefile                     # Build automation
├── backend.tf                   # Terraform backend configuration
├── main.tf                      # Root module orchestration
├── providers.tf                 # Provider configurations
├── variables.tf                 # Root variables
├── outputs.tf                   # Root outputs
├── locals.tf                    # Local values
├── data.tf                      # Data sources
│
├── environments/                # Environment-specific configurations
│   ├── dev.tfvars              # Development environment
│   ├── staging.tfvars          # Staging environment
│   └── prod.tfvars             # Production environment
│
├── modules/                     # Terraform modules
│   ├── networking/             # VPC, subnets, routing
│   ├── security/               # KMS, CloudTrail, GuardDuty
│   ├── cognito/                # User authentication
│   ├── iot/                    # IoT Core, Greengrass
│   ├── analytics/              # Kinesis, Timestream, Athena
│   ├── database/               # RDS, ElastiCache
│   ├── dynamodb/               # DynamoDB tables
│   ├── compute/                # Lambda, API Gateway
│   ├── monitoring/             # CloudWatch, X-Ray
│   ├── billing/                # AWS Budgets
│   ├── edge-computing/         # IoT Greengrass
│   ├── content-delivery/       # CloudFront, S3
│   ├── waf/                    # Web Application Firewall
│   ├── compliance/             # AWS Config
│   └── disaster-recovery/      # Cross-region replication
│
├── docs/                        # Documentation
│   ├── ARCHITECTURE.md         # Architecture overview
│   ├── DEPLOYMENT_GUIDE.md     # Deployment instructions
│   ├── CICD_SETUP.md          # CI/CD configuration
│   ├── SECRETS_MANAGEMENT.md   # Secrets Manager guide
│   ├── BACKEND_CONFIGURATION.md # Terraform backend setup
│   ├── REGION_CONFIGURATION.md # Region selection rationale
│   ├── GITHUB_SECRETS_SETUP.md # GitHub Actions secrets
│   ├── DISASTER_RECOVERY.md    # DR procedures
│   └── TROUBLESHOOTING.md      # Common issues and solutions
│
├── scripts/                     # Utility scripts
│   ├── iot_simulator.py        # IoT device simulator
│   ├── verify-oidc-setup.sh    # OIDC verification
│   └── README.md               # Scripts documentation
│
├── test/                        # Infrastructure tests
│   ├── properties/             # Property-based tests
│   └── README.md               # Testing guide
│
└── .github/                     # GitHub Actions workflows
    └── workflows/
        ├── terraform-reusable.yml  # Reusable workflow
        ├── dev.yml                 # Dev environment
        ├── staging.yml             # Staging environment
        └── prod.yml                # Production environment
```

## 📚 Documentation

### Core Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | System architecture and design decisions |
| [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) | Step-by-step deployment instructions |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common issues and solutions |

### Setup Guides

| Document | Description |
|----------|-------------|
| [CI/CD Setup](docs/CICD_SETUP.md) | GitHub Actions configuration with OIDC |
| [GitHub Secrets](docs/GITHUB_SECRETS_SETUP.md) | Setting up GitHub Actions secrets |
| [Backend Configuration](docs/BACKEND_CONFIGURATION.md) | Terraform state management |
| [Secrets Management](docs/SECRETS_MANAGEMENT.md) | Database credentials and rotation |

### Operations

| Document | Description |
|----------|-------------|
| [Disaster Recovery](docs/DISASTER_RECOVERY.md) | DR procedures and failover |
| [Region Configuration](docs/REGION_CONFIGURATION.md) | Region selection rationale |

## 🧩 Modules

Each module is self-contained with its own README, variables, and outputs.

### Core Modules

- **[networking](modules/networking/)** - VPC, subnets, NAT gateways, routing
- **[security](modules/security/)** - KMS, CloudTrail, GuardDuty, IAM
- **[cognito](modules/cognito/)** - User pools, identity pools, OAuth
- **[iot](modules/iot/)** - IoT Core, device management, rules
- **[analytics](modules/analytics/)** - Kinesis, Timestream, Firehose, Athena
- **[database](modules/database/)** - RDS PostgreSQL, ElastiCache Redis
- **[dynamodb](modules/dynamodb/)** - DynamoDB tables and streams
- **[compute](modules/compute/)** - Lambda functions, API Gateway
- **[monitoring](modules/monitoring/)** - CloudWatch, alarms, dashboards
- **[billing](modules/billing/)** - AWS Budgets and cost alerts

### Additional Modules

- **[edge-computing](modules/edge-computing/)** - IoT Greengrass for edge processing
- **[content-delivery](modules/content-delivery/)** - CloudFront CDN
- **[waf](modules/waf/)** - Web Application Firewall
- **[compliance](modules/compliance/)** - AWS Config rules
- **[disaster-recovery](modules/disaster-recovery/)** - Cross-region replication

## 🌍 Environments

### Development (dev)

- **Purpose**: Development and testing
- **Cost**: ~$200/month
- **Features**: Minimal resources, single AZ, no DR
- **State**: `s3://thekloudwiz-tf-state-bucket/project-ecovolt/dev-tf.state`

### Staging (staging)

- **Purpose**: Pre-production testing
- **Cost**: ~$800/month
- **Features**: Production-like, multi-AZ, optional DR
- **State**: `s3://thekloudwiz-tf-state-bucket/project-ecovolt/staging-tf.state`

### Production (prod)

- **Purpose**: Live production environment
- **Cost**: ~$2000/month
- **Features**: Full HA, multi-AZ, DR enabled, auto-scaling
- **State**: `s3://thekloudwiz-tf-state-bucket/project-ecovolt/prod-tf.state`

## 🔄 CI/CD

### GitHub Actions Workflows

The infrastructure uses GitHub Actions with OIDC for secure, keyless authentication.

#### Workflow Behavior

| Branch | Event | Jobs | Apply? |
|--------|-------|------|--------|
| `dev` | Push | init → validate → security → plan → **apply** | ✅ |
| `dev` | PR | init → validate → security → plan | ❌ |
| `staging` | PR | init → validate → security → plan | ❌ |
| `staging` | Merge | init → validate → security → plan → **apply** | ✅ |
| `main` | PR | init → validate → security → plan | ❌ |
| `main` | Merge | init → validate → security → plan → **apply** | ✅ |

#### Setup

See [docs/CICD_SETUP.md](docs/CICD_SETUP.md) for complete setup instructions.

Quick setup:
```bash
# Add GitHub secrets
gh secret set AWS_ROLE_ARN_DEV --body "arn:aws:iam::ACCOUNT:role/github-actions-dev"
gh secret set AWS_ROLE_ARN_STAGING --body "arn:aws:iam::ACCOUNT:role/github-actions-staging"
gh secret set AWS_ROLE_ARN_PROD --body "arn:aws:iam::ACCOUNT:role/github-actions-prod"
```

## 🔒 Security

### Implemented Security Controls

- **Encryption at Rest**: All data encrypted with KMS
- **Encryption in Transit**: TLS 1.2+ for all connections
- **Network Isolation**: Private subnets for databases and compute
- **Least Privilege IAM**: Minimal permissions for all roles
- **Secrets Management**: AWS Secrets Manager with rotation
- **WAF Protection**: Rate limiting and geo-blocking
- **Threat Detection**: GuardDuty monitoring
- **Audit Logging**: CloudTrail for all API calls
- **Compliance**: AWS Config rules for validation

### Security Scanning

```bash
# Run security scan
make security-scan

# Scan with tfsec
tfsec .

# Scan with Checkov
checkov -d .
```

## 💰 Cost Optimization

### Estimated Monthly Costs

| Environment | Compute | Storage | Database | IoT | Total |
|-------------|---------|---------|----------|-----|-------|
| Dev | $50 | $20 | $30 | $30 | **$200** |
| Staging | $200 | $100 | $150 | $100 | **$800** |
| Prod | $600 | $300 | $500 | $300 | **$2000** |

### Cost Optimization Features

- **Auto-scaling**: Lambda and DynamoDB scale to zero
- **Reserved Instances**: RDS reserved for prod
- **S3 Lifecycle**: Automatic archival to Glacier
- **Budget Alerts**: Email and SMS notifications
- **Right-sizing**: Appropriate instance types per environment

### Monitor Costs

```bash
# Estimate costs
make cost-estimate dev

# View current costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make changes and test: `make plan dev`
4. Run tests: `make test`
5. Commit changes: `git commit -am 'Add feature'`
6. Push to branch: `git push origin feature/my-feature`
7. Create Pull Request

### Code Standards

- Follow Terraform best practices
- Use meaningful variable names
- Add comments for complex logic
- Update documentation
- Run `terraform fmt` before committing
- Ensure all tests pass

## 📞 Support

### Getting Help

- **Documentation**: Check [docs/](docs/) folder
- **Issues**: [GitHub Issues](https://github.com/thekloudwiz-org/ecovolt-infrastructure/issues)
- **Discussions**: [GitHub Discussions](https://github.com/thekloudwiz-org/ecovolt-infrastructure/discussions)

### Common Commands

```bash
# Initialize
make init-dev

# Validate
make validate

# Format code
make fmt

# Plan changes
make plan dev

# Apply changes
make apply dev

# Show outputs
make output dev

# Run tests
make test

# Security scan
make security-scan

# Cost estimate
make cost-estimate dev

# Clean up
make clean
```

### Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues and solutions.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- AWS for cloud infrastructure
- Terraform for infrastructure as code
- The open-source community

---

**Built with ❤️ for sustainable transportation in Kenya** 🇰🇪
