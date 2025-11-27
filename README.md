# EcoVolt - Electric bike Battery Swapping Platform

> Production-ready AWS infrastructure and applications for EcoVolt's electric bike battery swapping network in Ghana

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-purple?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-eu--central--1-orange?logo=amazon-aws)](https://aws.amazon.com/)
[![React Native](https://img.shields.io/badge/React_Native-0.72-blue?logo=react)](https://reactnative.dev/)
[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://www.python.org/)

## 📋 Overview

EcoVolt is a comprehensive battery swapping platform for electric motorcycles in Ghana. The system enables riders to quickly swap depleted batteries for fully charged ones at strategically located swap stations across Accra and other major cities.

### Key Features

- **Real-time Station Finder** - Locate nearby swap stations with live battery availability
- **Quick Battery Swaps** - Complete battery exchanges in under 2 minutes
- **Mobile Wallet** - Integrated payment system with Mobile Money support
- **Fleet Management** - Admin portal for managing stations, bikes, and operations
- **IoT Integration** - Real-time telemetry from bikes and stations
- **Analytics Dashboard** - Comprehensive business intelligence and reporting

### System Architecture

![Architecture Diagram](docs/architecture.jpeg)

## 🏗️ Platform Components

### 1. Backend API
- **Technology**: Python 3.11, AWS Lambda, API Gateway
- **Database**: PostgreSQL (RDS), DynamoDB
- **Authentication**: AWS Cognito with JWT tokens
- **Features**: 38 REST API endpoints for all operations

### 2. Mobile Application
- **Technology**: React Native, TypeScript, Redux Toolkit
- **Platforms**: iOS and Android
- **Features**: Station finder, swap flow, wallet, bike monitoring, notifications

### 3. Admin Portal
- **Technology**: React, TypeScript, Material-UI
- **Features**: Dashboard, station management, bike fleet, user management, analytics

### 4. Infrastructure
- **Cloud Provider**: AWS (eu-central-1)
- **IaC**: Terraform
- **Services**: Lambda, API Gateway, RDS, DynamoDB, Cognito, IoT Core, SNS, CloudWatch
- **CI/CD**: GitHub Actions with OIDC

## 📚 Documentation

### Core Documentation

| Document | Description |
|----------|-------------|
| **[Architecture](docs/ARCHITECTURE.md)** | System architecture and design decisions |
| **[Infrastructure](docs/INFRASTRUCTURE.md)** | AWS infrastructure setup and Terraform modules |
| **[Backend](docs/BACKEND.md)** | Backend API documentation and implementation |
| **[Frontend](docs/FRONTEND.md)** | Mobile app and admin portal documentation |
| **[Cost Estimation](docs/COST_ESTIMATION.md)** | Detailed cost analysis and optimization |

### Quick Links

- [API Documentation](docs/BACKEND.md#api-endpoints)
- [Deployment Guide](docs/INFRASTRUCTURE.md#deployment)
- [Mobile App Setup](docs/FRONTEND.md#mobile-application)
- [Admin Portal Setup](docs/FRONTEND.md#admin-portal)
- [Troubleshooting](docs/INFRASTRUCTURE.md#troubleshooting)

## 🚀 Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.5
- Node.js >= 18
- Python >= 3.11
- AWS CLI configured

### 1. Clone Repository

```bash
git clone https://github.com/thekloudwiz-org/project-ecovolt.git
cd project-ecovolt
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Deploy to development
make plan dev
make apply dev
```

### 3. Deploy Backend

```bash
cd application/backend
./scripts/package_lambdas.sh
terraform apply -target=module.compute
```

### 4. Run Mobile App

```bash
cd application/mobile/EcoVolt
npm install
npm start
```

### 5. Run Admin Portal

```bash
cd application/admin-portal
npm install
npm run dev
```

## 📊 System Metrics

### Current Deployment

- **Region**: EU Central 1 (Frankfurt)
- **Availability**: Multi-AZ
- **Latency to Nairobi**: ~200ms
- **API Endpoints**: 38 endpoints
- **Database Tables**: 5 tables with 20+ indexes

### Cost Estimates

| Environment | Monthly Cost |
|-------------|--------------|
| Development | $120-130 |
| Staging | $800-1000 |
| Production | $2500-3500 |

See [Cost Estimation](docs/COST_ESTIMATION.md) for detailed breakdown.

## 🔒 Security

- ✅ Encryption at rest (KMS)
- ✅ Encryption in transit (TLS 1.2+)
- ✅ JWT authentication
- ✅ Role-based access control
- ✅ AWS Secrets Manager
- ✅ WAF protection
- ✅ GuardDuty monitoring
- ✅ CloudTrail audit logging

## 🧪 Testing

```bash
# Backend tests
cd application/backend
pytest tests/

# Mobile app tests
cd application/mobile/EcoVolt
npm test

# Admin portal tests
cd application/admin-portal
npm test

# Infrastructure tests
cd test
go test -v
```

## 📦 Project Structure

```
.
├── README.md                    # This file
├── docs/                        # Documentation
│   ├── ARCHITECTURE.md         # System architecture
│   ├── INFRASTRUCTURE.md       # AWS infrastructure
│   ├── BACKEND.md              # Backend API docs
│   ├── FRONTEND.md             # Frontend apps docs
│   ├── COST_ESTIMATION.md      # Cost analysis
│   └── architecture.jpeg       # Architecture diagram
│
├── application/                 # Application code
│   ├── backend/                # Python Lambda functions
│   ├── mobile/                 # React Native app
│   └── admin-portal/           # React admin portal
│
├── modules/                     # Terraform modules
│   ├── networking/             # VPC, subnets
│   ├── compute/                # Lambda, API Gateway
│   ├── database/               # RDS, ElastiCache
│   ├── iot/                    # IoT Core
│   └── ...                     # Other modules
│
├── environments/                # Environment configs
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
│
├── scripts/                     # Utility scripts
├── test/                        # Infrastructure tests
└── .github/workflows/           # CI/CD pipelines
```

## 🌍 Environments

### Development
- **Purpose**: Development and testing
- **Cost**: ~$120/month
- **Features**: Single AZ, minimal resources

### Staging
- **Purpose**: Pre-production testing
- **Cost**: ~$800/month
- **Features**: Multi-AZ, production-like

### Production
- **Purpose**: Live environment
- **Cost**: ~$2500/month
- **Features**: Full HA, multi-AZ, DR enabled

## 🔄 CI/CD

Automated deployment via GitHub Actions:

- **Development**: Auto-deploy on push to `dev` branch
- **Staging**: Auto-deploy on merge to `staging` branch
- **Production**: Auto-deploy on merge to `main` branch

See [Infrastructure Documentation](docs/INFRASTRUCTURE.md#cicd) for setup details.

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📞 Support

- **Documentation**: Check [docs/](docs/) folder
- **Issues**: [GitHub Issues](https://github.com/thekloudwiz-org/project-ecovolt/issues)
- **Email**: support@ecovolt.com

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- AWS for cloud infrastructure
- Terraform for infrastructure as code
- React Native and React communities
- The open-source community

---

**Built with ❤️ for sustainable transportation in Ghana** 🇰🇪

