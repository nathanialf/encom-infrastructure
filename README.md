# ENCOM Infrastructure

Terraform modules and configurations for deploying the ENCOM hexagonal map generator to AWS.

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   CloudFront    │───▶│      S3          │    │                 │
│   (Frontend)    │    │  (React App)     │    │                 │
└─────────────────┘    └──────────────────┘    │                 │
                                               │                 │
┌─────────────────┐    ┌──────────────────┐    │   AWS Lambda    │
│  API Gateway    │───▶│    Lambda        │◄───┤  Map Generator  │
│ (REST API +     │    │   Function       │    │  (Java 17)      │
│  Rate Limiting) │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │   CloudWatch     │
                       │ (Logs & Metrics) │
                       └──────────────────┘
```

## Modules

### `modules/lambda/`
- AWS Lambda function with Java 17 runtime
- IAM roles and policies with least privilege
- CloudWatch log groups with configurable retention
- Environment variable configuration
- Function URL support (optional)

### `modules/api-gateway/`
- REST API with CORS support
- Rate limiting and usage plans
- API key authentication (optional)
- CloudWatch access logging
- Proper error handling and responses

### `modules/frontend/`
- S3 bucket for static website hosting
- CloudFront distribution with caching and SPA routing
- Custom domain support with SSL certificate
- ACM certificate with DNS validation
- Origin Access Control for secure S3 access

## Environments

### Development (`environments/dev/`)
- Cost-optimized configuration
- Short log retention (7 days)
- No API key required
- Low rate limits
- Frontend deployment with custom domain: `dev.encom.riperoni.com`

### Production (`environments/prod/`)
- Production-grade configuration
- Extended log retention (30 days)
- API key authentication
- Higher rate limits
- Full monitoring and alerting

## Prerequisites

1. **AWS CLI configured** with appropriate credentials
2. **Terraform >= 1.0** installed
3. **Lambda JAR built** - run from `encom-lambda/`:
   ```bash
   gradle fatJar
   ```

## Quick Start

### 1. Deploy Development Environment

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy infrastructure
terraform apply
```

### 2. Test the Deployment

```bash
# Get the API endpoint
terraform output api_gateway_endpoint

# Test map generation
curl -X POST "$(terraform output -raw api_gateway_endpoint)" \
  -H "Content-Type: application/json" \
  -d '{
    "seed": "test123",
    "hexagonCount": 25,
    "options": {
      "corridorRatio": 0.7
    }
  }'
```

## Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-west-1` |
| `lambda_memory_size` | Lambda memory in MB | `512` |
| `lambda_timeout` | Lambda timeout in seconds | `30` |
| `enable_api_key` | Enable API key auth | `false` (dev) |
| `api_throttle_rate_limit` | Requests per second | `10` (dev) |
| `deploy_frontend` | Deploy S3+CloudFront | `false` |

### Environment Variables (Lambda)

| Variable | Description | Default |
|----------|-------------|---------|
| `DEFAULT_HEXAGON_COUNT` | Default map size | `50` |
| `MAX_HEXAGON_COUNT` | Maximum map size | `200` |
| `CORRIDOR_RATIO` | Default corridor ratio | `0.7` |
| `ENVIRONMENT` | Environment name | `dev`/`prod` |

## Deployment

### Manual Deployment
```bash
# Build Lambda JAR first
cd ../../encom-lambda
gradle fatJar

# Deploy infrastructure
cd ../encom-infrastructure/environments/dev
terraform apply
```

### Automated Deployment
```bash
# Using deployment script (when available)
../../scripts/deploy-infrastructure.sh dev
```

## Monitoring

The infrastructure includes:
- **CloudWatch Logs** for Lambda and API Gateway
- **CloudWatch Metrics** for performance monitoring
- **API Gateway Access Logs** for request tracking
- **Lambda Function Metrics** for performance and errors

## Costs

### Development Environment (Estimated Monthly)
- Lambda: $0.04 (10K requests)
- API Gateway: $0.04 (10K requests)
- CloudWatch Logs: $0.01 (0.1GB)
- **Total: ~$0.09/month**

### Production Environment (Estimated Monthly)
- Lambda: $0.44 (100K requests)
- API Gateway: $0.35 (100K requests)
- CloudWatch: $2.50 (monitoring + logs)
- **Total: ~$3.29/month**

## Cleanup

```bash
# Destroy all resources
terraform destroy
```

## Security

- **IAM Roles**: Least privilege access for Lambda execution
- **API Gateway**: Rate limiting and optional API key authentication
- **CloudWatch**: Secure log storage with configurable retention
- **VPC**: Not used (cost optimization) - Lambda runs in AWS-managed VPC

## Troubleshooting

### Common Issues

1. **JAR file not found**
   ```bash
   cd ../../encom-lambda
   gradle fatJar
   ```

2. **AWS credentials not configured**
   ```bash
   aws configure
   # or
   export AWS_PROFILE=your-profile
   ```

3. **Region mismatch**
   - Ensure `aws_region` variable matches your AWS CLI region

4. **Terraform state issues**
   ```bash
   terraform refresh
   terraform plan
   ```