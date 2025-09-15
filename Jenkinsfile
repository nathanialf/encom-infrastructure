pipeline {
    agent {
        node {
            label 'any'
            customWorkspace '/var/lib/jenkins/workspace/ENCOM-Shared'
        }
    }
    
    options {
        skipDefaultCheckout(true)
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'prod'],
            description: 'Environment to deploy'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform action to perform'
        )
    }
    
    tools {
        terraform 'Terraform-1.5'
    }
    
    environment {
        AWS_REGION = 'us-west-1'
        PROJECT_NAME = 'encom-infrastructure'
    }
    
    stages {
        stage('Checkout') {
            steps {
                // Checkout infrastructure code to subdirectory to avoid overwriting Lambda artifacts
                dir('encom-infrastructure') {
                    checkout scm
                }
                script {
                    def awsCredentials = params.ENVIRONMENT == 'prod' ? 'aws-encom-prod' : 'aws-encom-dev'
                    
                    // Download JAR from S3
                    withAWS(credentials: awsCredentials, region: env.AWS_REGION) {
                        // Create directory for JAR and clean any existing file
                        sh '''
                            mkdir -p encom-lambda/build/libs
                            rm -f encom-lambda/build/libs/encom-lambda-1.0.0-all.jar
                        '''
                        
                        try {
                            // Try to download the latest JAR
                            s3Download bucket: 'encom-build-artifacts-dev-us-west-1',
                                     path: 'artifacts/lambda/encom-lambda-latest.jar',
                                     file: 'encom-lambda/build/libs/encom-lambda-1.0.0-all.jar',
                                     force: true
                            
                            sh 'echo "JAR downloaded from S3: $(ls -la encom-lambda/build/libs/encom-lambda-1.0.0-all.jar)"'
                            
                        } catch (Exception e) {
                            error """Lambda JAR not found in S3. Please build the Lambda first.

To build the JAR:
1. Run ENCOM-Lambda job (any environment)
2. JAR will be automatically uploaded to S3
3. Then retry this Infrastructure deployment

Error: ${e.getMessage()}
Looking for: s3://encom-build-artifacts-dev-us-west-1/artifacts/lambda/encom-lambda-latest.jar"""
                        }
                    }
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                script {
                    def awsCredentials = params.ENVIRONMENT == 'prod' ? 'aws-encom-prod' : 'aws-encom-dev'
                    
                    withAWS(credentials: awsCredentials, region: env.AWS_REGION) {
                        dir("encom-infrastructure/environments/${params.ENVIRONMENT}") {
                            sh '''
                                terraform init
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                script {
                    def awsCredentials = params.ENVIRONMENT == 'prod' ? 'aws-encom-prod' : 'aws-encom-dev'
                    
                    withAWS(credentials: awsCredentials, region: env.AWS_REGION) {
                        dir("encom-infrastructure/environments/${params.ENVIRONMENT}") {
                            sh '''
                                terraform plan -var-file=terraform.tfvars -out=tfplan
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    if (params.ENVIRONMENT == 'prod') {
                        input message: 'Apply to Production?', ok: 'Apply'
                    }
                    
                    def awsCredentials = params.ENVIRONMENT == 'prod' ? 'aws-encom-prod' : 'aws-encom-dev'
                    
                    withAWS(credentials: awsCredentials, region: env.AWS_REGION) {
                        dir("encom-infrastructure/environments/${params.ENVIRONMENT}") {
                            sh '''
                                echo "Importing existing resources to avoid conflicts..."
                                
                                # Import existing IAM role if it exists
                                terraform import -var-file=terraform.tfvars module.lambda.aws_iam_role.lambda_role encom-map-generator-${ENVIRONMENT}-role || echo "IAM role not found or already imported"
                                
                                # Import existing CloudWatch log group if it exists
                                terraform import -var-file=terraform.tfvars module.lambda.aws_cloudwatch_log_group.lambda_logs /aws/lambda/encom-map-generator-${ENVIRONMENT} || echo "Log group not found or already imported"
                                
                                # Import existing Lambda function if it exists
                                terraform import -var-file=terraform.tfvars module.lambda.aws_lambda_function.function encom-map-generator-${ENVIRONMENT} || echo "Lambda function not found or already imported"
                                
                                # Import existing Lambda alias if it exists
                                terraform import -var-file=terraform.tfvars module.lambda.aws_lambda_alias.function_alias encom-map-generator-${ENVIRONMENT}/live || echo "Lambda alias not found or already imported"
                                
                                # Import existing API Gateway CloudWatch log group if it exists
                                terraform import -var-file=terraform.tfvars module.api_gateway.aws_cloudwatch_log_group.api_gateway_logs /aws/apigateway/encom-api-${ENVIRONMENT} || echo "API Gateway log group not found or already imported"
                                
                                echo "Import completed. Generating fresh plan and applying..."
                                terraform plan -var-file=terraform.tfvars -out=tfplan-fresh
                                terraform apply tfplan-fresh
                            '''
                        }
                    }
                }
            }
        }
        
        
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                script {
                    def awsCredentials = params.ENVIRONMENT == 'prod' ? 'aws-encom-prod' : 'aws-encom-dev'
                    
                    echo "WARNING: Destroying ${params.ENVIRONMENT} infrastructure..."
                    
                    withAWS(credentials: awsCredentials, region: env.AWS_REGION) {
                        dir("encom-infrastructure/environments/${params.ENVIRONMENT}") {
                            sh '''
                                terraform destroy -var-file=terraform.tfvars -auto-approve
                            '''
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}