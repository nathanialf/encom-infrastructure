#!/bin/bash

# Script to import existing AWS resources into Terraform state
# Run this from environments/dev directory

set -e

echo "Importing existing Lambda IAM role..."
terraform import module.lambda.aws_iam_role.lambda_role encom-map-generator-dev-role

echo "Importing existing Lambda CloudWatch log group..."
terraform import module.lambda.aws_cloudwatch_log_group.lambda_logs /aws/lambda/encom-map-generator-dev

echo "Import complete! You can now run terraform apply"