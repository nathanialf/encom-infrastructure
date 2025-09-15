# AWS Configuration
aws_region = "us-west-1"

# Lambda Configuration
lambda_memory_size         = 512
lambda_timeout            = 30
enable_lambda_function_url = false

# Map Generation Configuration
default_hexagon_count = 50
max_hexagon_count    = 200
corridor_ratio       = 0.7

# API Gateway Configuration
enable_api_key             = false  # Disabled for easier dev testing
api_throttle_rate_limit    = 10     # 10 requests per second
api_throttle_burst_limit   = 20     # Burst up to 20 requests
api_quota_limit           = 1000   # 1000 requests per month

# Frontend Configuration
deploy_frontend = false  # Skip frontend infrastructure for now

# Logging Configuration
log_retention_days = 7  # 7 days for dev environment

