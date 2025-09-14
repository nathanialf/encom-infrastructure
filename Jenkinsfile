pipeline {
    agent {
        node {
            label 'any'
            customWorkspace '/var/lib/jenkins/workspace/ENCOM-Shared'
        }
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
                    // Verify JAR file exists
                    sh '''
                        if [ -f /var/lib/jenkins/workspace/ENCOM-Shared/build/libs/encom-lambda-1.0.0-all.jar ]; then
                            echo "JAR file found: $(ls -la /var/lib/jenkins/workspace/ENCOM-Shared/build/libs/encom-lambda-1.0.0-all.jar)"
                        else
                            echo "ERROR: JAR file not found - run ENCOM-Lambda with BUILD_ONLY=true first"
                            echo "Looking for: /var/lib/jenkins/workspace/ENCOM-Shared/build/libs/encom-lambda-1.0.0-all.jar"
                            exit 1
                        fi
                    '''
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