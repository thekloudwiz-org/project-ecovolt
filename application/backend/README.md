# EcoVolt Backend API

Backend API for the EcoVolt battery swapping platform.

## Architecture

- **Runtime**: Python 3.11
- **Framework**: AWS Lambda + API Gateway
- **Database**: PostgreSQL (RDS) + DynamoDB
- **Authentication**: AWS Cognito
- **IoT**: AWS IoT Core for device communication

## API Endpoints

### Public Endpoints
- `GET /health` - Health check
- `GET /stations` - List all swap stations
- `GET /stations/{id}` - Get station details
- `GET /stations/nearby` - Find nearby stations

### Authenticated Endpoints (Riders)
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `GET /profile` - Get user profile
- `PUT /profile` - Update user profile
- `GET /bikes/{id}` - Get bike details
- `POST /swaps` - Initiate battery swap
- `GET /swaps/history` - Get swap history
- `GET /wallet` - Get wallet balance
- `POST /wallet/topup` - Top up wallet

### Admin Endpoints
- `GET /admin/stations` - Manage stations
- `POST /admin/stations` - Create station
- `PUT /admin/stations/{id}` - Update station
- `GET /admin/analytics` - View analytics
- `GET /admin/bikes` - Manage bikes
- `GET /admin/users` - Manage users

## Project Structure

```
backend/
├── api/                    # API route handlers
│   ├── stations.py        # Station endpoints
│   ├── swaps.py          # Swap endpoints
│   ├── users.py          # User endpoints
│   └── admin.py          # Admin endpoints
├── functions/             # Lambda function handlers
│   ├── api_handler.py    # Main API handler
│   ├── iot_processor.py  # IoT data processor
│   └── stream_processor.py # Kinesis stream processor
├── models/               # Data models
│   ├── station.py       # Station model
│   ├── bike.py          # Bike model
│   ├── user.py          # User model
│   └── swap.py          # Swap transaction model
├── utils/               # Utility functions
│   ├── db.py           # Database utilities
│   ├── auth.py         # Authentication utilities
│   └── validators.py   # Input validators
├── tests/              # Unit tests
└── requirements.txt    # Python dependencies
```

## Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests
pytest tests/

# Deploy
cd ../../
terraform apply -var-file="environments/dev.tfvars"
```

## Environment Variables

Set via Lambda environment variables (configured in Terraform):
- `DB_ENDPOINT` - RDS endpoint
- `DB_NAME` - Database name
- `DB_SECRET_ARN` - Secrets Manager ARN for DB credentials
- `COGNITO_USER_POOL_ID` - Cognito user pool ID
- `IOT_ENDPOINT` - IoT Core endpoint

## Development

See [Development Guide](../docs/DEVELOPMENT.md) for local development setup.
