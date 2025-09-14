# Jenkins CI/CD Setup for ENCOM Projects

This document provides instructions for setting up Jenkins jobs for all ENCOM components with proper AWS security isolation.

## AWS Account Security Setup

### Root Account Security (Recommended Architecture)

```
Root AWS Account (Domain Owner)
├── Route 53 (Domain management)
├── Organizations (Account management)
└── IAM (Cross-account roles)

ENCOM Development Account
├── Lambda Functions
├── API Gateway
├── S3 Buckets
├── CloudFront
└── CloudWatch

ENCOM Production Account
├── Lambda Functions
├── API Gateway  
├── S3 Buckets
├── CloudFront
└── CloudWatch
```

### 1. Create Dedicated AWS Accounts

```bash
# Using AWS Organizations (in root account)
aws organizations create-account \
  --account-name "ENCOM-Development" \
  --email "encom-dev@yourdomain.com"

aws organizations create-account \
  --account-name "ENCOM-Production" \
  --email "encom-prod@yourdomain.com"
```

### 2. Set Up Cross-Account IAM Roles

Starting from scratch, you'll create roles in each account following this order:

#### Step 2a: In Jenkins Account (671341084972) - Create Jenkins Service User

First, create a dedicated IAM user for Jenkins (do NOT use your personal user or root account):

```bash
# 1. Create jenkins-user with programmatic access
aws iam create-user --user-name jenkins-user --path "/service/"

# 2. Create access keys for the user (save these securely for Jenkins configuration)
aws iam create-access-key --user-name jenkins-user

# 3. Tag the user for identification
aws iam tag-user --user-name jenkins-user --tags Key=Purpose,Value=Jenkins Key=Project,Value=ENCOM
```

#### Step 2b: In ROOT Account - Create Jenkins Cross-Account Role

This role will be assumed by your Jenkins server to access child accounts.

```bash
# 1. Create trust policy for Jenkins (replace YOUR-JENKINS-SERVER-IP)
cat > jenkins-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ROOT-ACCOUNT-ID:user/jenkins-user"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# 2. Create the role
aws iam create-role \
  --role-name JenkinsCrossAccountRole \
  --assume-role-policy-document file://jenkins-trust-policy.json

# 3. Attach policy to assume roles in child accounts
cat > jenkins-cross-account-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": [
        "arn:aws:iam::DEV-ACCOUNT-ID:role/ENCOMDeploymentRole",
        "arn:aws:iam::PROD-ACCOUNT-ID:role/ENCOMDeploymentRole"
      ]
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name JenkinsCrossAccountRole \
  --policy-name CrossAccountAssumePolicy \
  --policy-document file://jenkins-cross-account-policy.json

# 4. The jenkins-user was already created in Step 2a

# 5. Allow user to assume the cross-account role
cat > jenkins-user-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::ROOT-ACCOUNT-ID:role/JenkinsCrossAccountRole"
    }
  ]
}
EOF

aws iam put-user-policy \
  --user-name jenkins-user \
  --policy-name AssumeJenkinsRole \
  --policy-document file://jenkins-user-policy.json
```

#### Step 2b: In DEVELOPMENT Account - Create Deployment Role

Switch to your Development AWS account and create the deployment role.

```bash
# 1. Create trust policy allowing ROOT account role to assume this role
cat > dev-deployment-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ROOT-ACCOUNT-ID:role/JenkinsCrossAccountRole"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "encom-dev-deployment"
        }
      }
    }
  ]
}
EOF

# 2. Create the deployment role
aws iam create-role \
  --role-name ENCOMDeploymentRole \
  --assume-role-policy-document file://dev-deployment-trust-policy.json

# 3. Create and attach deployment policy
cat > encom-deployment-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:*",
        "apigateway:*",
        "s3:*",
        "cloudfront:*",
        "cloudwatch:*",
        "logs:*",
        "iam:PassRole",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy", 
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListAttachedRolePolicies",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:ListPolicyVersions",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-west-1"
        }
      }
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name ENCOMDeploymentRole \
  --policy-name ENCOMDeploymentPolicy \
  --policy-document file://encom-deployment-policy.json
```

#### Step 2c: In PRODUCTION Account - Create Deployment Role

Switch to your Production AWS account and create the deployment role.

```bash
# 1. Create trust policy (same as dev but different external ID)
cat > prod-deployment-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ROOT-ACCOUNT-ID:role/JenkinsCrossAccountRole"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "encom-prod-deployment"
        }
      }
    }
  ]
}
EOF

# 2. Create the deployment role
aws iam create-role \
  --role-name ENCOMDeploymentRole \
  --assume-role-policy-document file://prod-deployment-trust-policy.json

# 3. Attach the same deployment policy (reuse the JSON from step 2b)
aws iam put-role-policy \
  --role-name ENCOMDeploymentRole \
  --policy-name ENCOMDeploymentPolicy \
  --policy-document file://encom-deployment-policy.json
```

#### Step 2d: Account ID Reference

Replace these placeholders with your actual account IDs:

```bash
# Find your account IDs
aws sts get-caller-identity --query Account --output text  # Current account

# Or list all organization accounts (from root account)
aws organizations list-accounts --query 'Accounts[*].[Name,Id]' --output table
```

**Account ID Mapping:**
- `ROOT-ACCOUNT-ID`: Your root/main AWS account ID
- `DEV-ACCOUNT-ID`: Your ENCOM Development account ID  
- `PROD-ACCOUNT-ID`: Your ENCOM Production account ID

### 3. Route 53 Delegation (Root Account)

```bash
# Create hosted zone in development account
aws route53 create-hosted-zone \
  --name "dev.encom.yourdomain.com" \
  --caller-reference "encom-dev-$(date +%s)"

# Create hosted zone in production account  
aws route53 create-hosted-zone \
  --name "encom.yourdomain.com" \
  --caller-reference "encom-prod-$(date +%s)"
```

## Jenkins Server Setup

### 1. Jenkins Installation (Docker)

```yaml
# docker-compose.yml
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: encom-jenkins
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
      - JENKINS_OPTS=--httpPort=8080

volumes:
  jenkins_home:
```

### 2. Required Jenkins Plugins

```bash
# Install via Jenkins CLI or UI
jenkins-plugin-cli --plugins \
  aws-credentials \
  pipeline-aws \
  terraform \
  gradle \
  nodejs \
  docker-pipeline \
  github \
  slack \
  timestamper \
  workspace-cleanup
```

### 3. Jenkins Global Configuration

#### AWS Credentials Setup
1. **Manage Jenkins** → **Manage Credentials** → **Global**
2. Add AWS credentials for each account:

```
ID: aws-encom-dev
Description: ENCOM Development Account
Access Key ID: [DEV_ACCOUNT_ACCESS_KEY]
Secret Access Key: [DEV_ACCOUNT_SECRET_KEY]

ID: aws-encom-prod  
Description: ENCOM Production Account
Access Key ID: [PROD_ACCOUNT_ACCESS_KEY]
Secret Access Key: [PROD_ACCOUNT_SECRET_KEY]
```

#### Global Tools Configuration
- **Gradle**: Auto-install Gradle 8.x
- **NodeJS**: Auto-install Node.js 18.x
- **Terraform**: Auto-install Terraform 1.5.x

## ENCOM Project Jenkins Jobs

### 1. ENCOM Lambda Pipeline

#### Jenkinsfile for Lambda
```groovy
// encom-lambda/Jenkinsfile
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'prod'],
            description: 'Deployment environment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip unit tests'
        )
    }
    
    environment {
        AWS_REGION = 'us-west-1'
        PROJECT_NAME = 'encom-lambda'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.BUILD_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
                }
            }
        }
        
        stage('Test') {
            when {
                not { params.SKIP_TESTS }
            }
            steps {
                sh '''
                    chmod +x gradlew
                    ./gradlew test
                '''
                publishTestResults testResultsPattern: 'build/test-results/test/*.xml'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'build/reports/tests/test',
                    reportFiles: 'index.html',
                    reportName: 'Test Report'
                ])
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                    chmod +x gradlew
                    ./gradlew fatJar
                '''
                archiveArtifacts artifacts: 'build/libs/*.jar'
            }
        }
        
        stage('Deploy to Development') {
            when {
                expression { params.ENVIRONMENT == 'dev' }
            }
            steps {
                withAWS(credentials: 'aws-encom-dev', region: env.AWS_REGION) {
                    dir('../encom-infrastructure/environments/dev') {
                        sh '''
                            terraform init
                            terraform plan -var-file=terraform.tfvars
                            terraform apply -var-file=terraform.tfvars -auto-approve
                        '''
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            when {
                expression { params.ENVIRONMENT == 'dev' }
            }
            steps {
                withAWS(credentials: 'aws-encom-dev', region: env.AWS_REGION) {
                    script {
                        def apiEndpoint = sh(
                            script: 'cd ../encom-infrastructure/environments/dev && terraform output -raw api_gateway_endpoint',
                            returnStdout: true
                        ).trim()
                        
                        sh """
                            curl -X POST "${apiEndpoint}" \
                                -H "Content-Type: application/json" \
                                -d '{"hexagonCount": 10}' \
                                --fail --silent --show-error
                        """
                    }
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                allOf {
                    expression { params.ENVIRONMENT == 'prod' }
                    branch 'main'
                }
            }
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
                withAWS(credentials: 'aws-encom-prod', region: env.AWS_REGION) {
                    dir('../encom-infrastructure/environments/prod') {
                        sh '''
                            terraform init
                            terraform plan -var-file=terraform.tfvars
                            terraform apply -var-file=terraform.tfvars -auto-approve
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            slackSend(
                channel: '#encom-alerts',
                color: 'danger',
                message: "❌ ${env.PROJECT_NAME} build failed: ${env.BUILD_URL}"
            )
        }
        success {
            slackSend(
                channel: '#encom-deployments',
                color: 'good', 
                message: "✅ ${env.PROJECT_NAME} deployed to ${params.ENVIRONMENT}: ${env.BUILD_URL}"
            )
        }
    }
}
```

#### Jenkins Job Configuration
```bash
# Create Pipeline Job
Job Name: ENCOM-Lambda-Pipeline
Type: Pipeline
GitHub Repository: https://github.com/nathanialf/encom-lambda
Branch: main
Script Path: Jenkinsfile

# Build Triggers
- GitHub hook trigger for GITScm polling
- Build periodically: H/15 * * * * (every 15 minutes)
```

### 2. ENCOM Frontend Pipeline

#### Jenkinsfile for Frontend
```groovy
// encom-frontend/Jenkinsfile  
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'prod'],
            description: 'Deployment environment'
        )
    }
    
    tools {
        nodejs 'NodeJS-18'
    }
    
    environment {
        AWS_REGION = 'us-west-1'
        PROJECT_NAME = 'encom-frontend'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                sh '''
                    npm ci
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    npm run test:coverage
                '''
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'coverage',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ])
            }
        }
        
        stage('Build') {
            steps {
                sh '''
                    npm run build
                    npm run export
                '''
                archiveArtifacts artifacts: 'out/**/*'
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    def awsCredentials = params.ENVIRONMENT == 'prod' ? 'aws-encom-prod' : 'aws-encom-dev'
                    
                    withAWS(credentials: awsCredentials, region: env.AWS_REGION) {
                        // Get S3 bucket name from Terraform output
                        def bucketName = sh(
                            script: """cd ../encom-infrastructure/environments/${params.ENVIRONMENT} && 
                                      terraform output -raw frontend_bucket_name 2>/dev/null || echo ''""",
                            returnStdout: true
                        ).trim()
                        
                        if (bucketName) {
                            // Deploy to S3
                            sh """
                                aws s3 sync out/ s3://${bucketName} --delete
                            """
                            
                            // Invalidate CloudFront
                            def distributionId = sh(
                                script: """cd ../encom-infrastructure/environments/${params.ENVIRONMENT} && 
                                          terraform output -raw cloudfront_distribution_id 2>/dev/null || echo ''""",
                                returnStdout: true
                            ).trim()
                            
                            if (distributionId) {
                                sh """
                                    aws cloudfront create-invalidation \
                                        --distribution-id ${distributionId} \
                                        --paths "/*"
                                """
                            }
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
        failure {
            slackSend(
                channel: '#encom-alerts',
                color: 'danger',
                message: "❌ ${env.PROJECT_NAME} build failed: ${env.BUILD_URL}"
            )
        }
        success {
            slackSend(
                channel: '#encom-deployments',
                color: 'good',
                message: "✅ ${env.PROJECT_NAME} deployed to ${params.ENVIRONMENT}: ${env.BUILD_URL}"
            )
        }
    }
}
```

### 3. ENCOM Infrastructure Pipeline

#### Jenkinsfile for Infrastructure
```groovy
// encom-infrastructure/Jenkinsfile
pipeline {
    agent any
    
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
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                script {
                    def awsCredentials = params.ENVIRONMENT == 'prod' ? 'aws-encom-prod' : 'aws-encom-dev'
                    
                    withAWS(credentials: awsCredentials, region: env.AWS_REGION) {
                        dir("environments/${params.ENVIRONMENT}") {
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
                        dir("environments/${params.ENVIRONMENT}") {
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
                        dir("environments/${params.ENVIRONMENT}") {
                            sh '''
                                terraform apply tfplan
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
                input message: 'Destroy infrastructure? This cannot be undone!', ok: 'Destroy'
                script {
                    def awsCredentials = params.ENVIRONMENT == 'prod' ? 'aws-encom-prod' : 'aws-encom-dev'
                    
                    withAWS(credentials: awsCredentials, region: env.AWS_REGION) {
                        dir("environments/${params.ENVIRONMENT}") {
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
        failure {
            slackSend(
                channel: '#encom-alerts',
                color: 'danger',
                message: "❌ ${env.PROJECT_NAME} ${params.ACTION} failed for ${params.ENVIRONMENT}: ${env.BUILD_URL}"
            )
        }
        success {
            slackSend(
                channel: '#encom-deployments',
                color: 'good',
                message: "✅ ${env.PROJECT_NAME} ${params.ACTION} completed for ${params.ENVIRONMENT}: ${env.BUILD_URL}"
            )
        }
    }
}
```

## Jenkins Job Creation Commands

### Using Jenkins CLI

```bash
# Install Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Create Lambda Pipeline Job
java -jar jenkins-cli.jar -s http://localhost:8080/ create-job ENCOM-Lambda-Pipeline < lambda-job.xml

# Create Frontend Pipeline Job  
java -jar jenkins-cli.jar -s http://localhost:8080/ create-job ENCOM-Frontend-Pipeline < frontend-job.xml

# Create Infrastructure Pipeline Job
java -jar jenkins-cli.jar -s http://localhost:8080/ create-job ENCOM-Infrastructure-Pipeline < infrastructure-job.xml
```

### Jenkins Job Templates

#### Lambda Job XML
```xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>ENCOM Lambda Function CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/nathanialf/encom-lambda</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
</flow-definition>
```

## Security Best Practices

1. **Separate AWS Accounts**: Never mix development and production resources
2. **IAM Role Assumption**: Use cross-account roles instead of long-lived keys
3. **Least Privilege**: Grant only necessary permissions to Jenkins roles
4. **Secret Management**: Store sensitive data in Jenkins credentials, not in code
5. **Network Isolation**: Run Jenkins in private subnet with VPN access
6. **Audit Logging**: Enable CloudTrail in all AWS accounts
7. **MFA**: Require MFA for production deployments

## Monitoring and Alerting

```yaml
# Jenkins Monitoring (via Prometheus + Grafana)
version: '3.8'
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

This setup provides a secure, isolated, and automated CI/CD pipeline for all ENCOM components while maintaining proper separation between development and production environments.