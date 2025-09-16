# Production Environment Configuration

# AWS Configuration
aws_region = "us-west-1"

# Lambda Configuration
lambda_memory_size = 1024   # 1GB memory for production workloads
lambda_timeout     = 60     # 60 seconds timeout

# API Gateway Configuration
enable_api_key              = true    # API key required for production
api_throttle_rate_limit     = 100     # 100 requests per second
api_throttle_burst_limit    = 200     # Burst up to 200 requests
api_quota_limit            = 100000   # 100,000 requests per month

# Frontend Configuration
deploy_frontend = true  # Frontend enabled for production

# Logging Configuration
log_retention_days = 30  # 30 days for production environment