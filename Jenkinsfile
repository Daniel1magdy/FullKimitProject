// Jenkinsfile
pipeline {
    agent any
    
    environment {
        AWS_REGION = 'eu-west-2'
        CLUSTER_NAME = 'devops-cluster'
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FRONTEND_REPO = "${ECR_REGISTRY}/devops-frontend"
        BACKEND_REPO = "${ECR_REGISTRY}/devops-backend"
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        AWS_ACCOUNT_ID = credentials('aws-account-id')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out source code...'
                checkout scm
                script {
                    env.GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
                }
            }
        }
        
        stage('Build Applications') {
            parallel {
                stage('Build Frontend') {
                    steps {
                        echo '🏗️ Building Frontend Application...'
                        dir('frontend') {
                            sh 'npm install'
                            sh 'npm test --passWithNoTests || true'
                        }
                    }
                }
                stage('Build Backend') {
                    steps {
                        echo '🏗️ Building Backend Application...'
                        dir('backend') {
                            sh 'npm install'
                            sh 'npm test --passWithNoTests || true'
                        }
                    }
                }
            }
        }
        
        stage('Docker Build & Push') {
            steps {
                echo '🐳 Building and pushing Docker images...'
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                                       credentialsId: 'aws-credentials', 
                                       secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        
                        // Login to ECR
                        sh """
                            aws ecr get-login-password --region ${AWS_REGION} | \\
                            docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        """
                        
                        // Build and push frontend
                        sh """
                            echo "Building Frontend Docker image..."
                            docker build -t ${FRONTEND_REPO}:${IMAGE_TAG} -t ${FRONTEND_REPO}:latest ./frontend/
                            docker push ${FRONTEND_REPO}:${IMAGE_TAG}
                            docker push ${FRONTEND_REPO}:latest
                        """
                        
                        // Build and push backend
                        sh """
                            echo "Building Backend Docker image..."
                            docker build -t ${BACKEND_REPO}:${IMAGE_TAG} -t ${BACKEND_REPO}:latest ./backend/
                            docker push ${BACKEND_REPO}:${IMAGE_TAG}
                            docker push ${BACKEND_REPO}:latest
                        """
                        
                        // Clean up local images
                        sh """
                            docker rmi ${FRONTEND_REPO}:${IMAGE_TAG} ${FRONTEND_REPO}:latest || true
                            docker rmi ${BACKEND_REPO}:${IMAGE_TAG} ${BACKEND_REPO}:latest || true
                        """
                    }
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            steps {
                echo '📝 Updating Kubernetes manifests with new image tags...'
                script {
                    // Update frontend deployment
                    sh """
                        sed -i 's|FRONTEND_IMAGE_URI|${FRONTEND_REPO}:${IMAGE_TAG}|g' k8s/frontend-deployment.yaml
                    """
                    
                    // Update backend deployment
                    sh """
                        sed -i 's|BACKEND_IMAGE_URI|${BACKEND_REPO}:${IMAGE_TAG}|g' k8s/backend-deployment.yaml
                    """
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                echo '🚀 Deploying to EKS cluster...'
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                                       credentialsId: 'aws-credentials', 
                                       secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        
                        // Update kubeconfig
                        sh """
                            aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
                        """
                        
                        // Deploy applications
                        sh """
                            echo "Deploying to Kubernetes..."
                            kubectl apply -f k8s/backend-deployment.yaml
                            kubectl apply -f k8s/frontend-deployment.yaml
                            
                            echo "Waiting for deployments to be ready..."
                            kubectl rollout status deployment/backend-deployment --timeout=300s
                            kubectl rollout status deployment/frontend-deployment --timeout=300s
                        """
                    }
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo '🔍 Performing health checks...'
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                                       credentialsId: 'aws-credentials', 
                                       secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        
                        sh """
                            echo "Checking deployment status..."
                            kubectl get deployments
                            kubectl get services
                            kubectl get pods
                            
                            echo "Checking application health..."
                            # Wait for services to be ready
                            sleep 30
                            
                            # Test backend health
                            kubectl exec -it \$(kubectl get pods -l app=backend -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:8080/health || true
                            
                            # Test frontend health
                            kubectl exec -it \$(kubectl get pods -l app=frontend -o jsonpath='{.items[0].metadata.name}') -- wget -qO- http://localhost:3000/health || true
                        """
                    }
                }
            }
        }
        
        stage('Install Monitoring') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    changeset 'k8s/monitoring/**'
                }
            }
            steps {
                echo '📊 Installing/Updating Monitoring Stack...'
                script {
                    withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                                       credentialsId: 'aws-credentials', 
                                       secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        
                        sh """
                            chmod +x k8s/monitoring/install-monitoring.sh
                            ./k8s/monitoring/install-monitoring.sh
                        """
                    }
                }
            }
        }
    }
    
    post {
    success {
        echo '✅ Pipeline completed successfully!'
        script {
            withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                               credentialsId: 'aws-credentials', 
                               secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                sh """
                    echo "=== DEPLOYMENT SUMMARY ==="
                    echo "Frontend Image: ${FRONTEND_REPO}:${IMAGE_TAG}"
                    echo "Backend Image: ${BACKEND_REPO}:${IMAGE_TAG}"
                    echo "Cluster: ${CLUSTER_NAME}"
                    echo "Region: ${AWS_REGION}"
                    echo ""
                    echo "=== SERVICES ==="
                    kubectl get services
                    echo ""
                    echo "=== GET APPLICATION URLs ==="
                    echo "Frontend URL:"
                    kubectl get service frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' || echo "Pending..."
                    echo ""
                """
            }
        }
    }
    failure {
        echo '❌ Pipeline failed!'
        script {
            withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                               credentialsId: 'aws-credentials', 
                               secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                sh """
                    echo "=== DEBUG INFO ==="
                    kubectl get pods
                    kubectl get events --sort-by=.metadata.creationTimestamp | tail -10
                """
            }
        }
    }
    always {
        echo '🧹 Cleaning up...'
        sh 'docker system prune -f || true'
    }
    }
}
