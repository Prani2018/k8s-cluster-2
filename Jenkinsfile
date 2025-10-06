// Define configuration maps and helper functions outside the 'pipeline' block
// to be accessible by the Groovy runtime.

// Configuration Maps
def eastConfig = [
    tf_var_file: 'east.tfvars',
    kubeconfig_region: 'us-east-1',
    cluster_name: 'Cluster-East',
    backend_key: 'eks/cluster-state-us-east-1.tfstate',
    work_dir: 'eks-cluster-east'  // Separate working directory
]

def westConfig = [
    tf_var_file: 'west.tfvars',
    kubeconfig_region: 'us-west-2',
    cluster_name: 'Cluster-West',
    backend_key: 'eks/cluster-state-us-west-2.tfstate',
    work_dir: 'eks-cluster-west'  // Separate working directory
]

// Helper Functions
def executeTerraformAction(config, action) {
    def tfVarFile = config.tf_var_file
    def clusterName = config.cluster_name
    def backendKey = config.backend_key
    def workDir = config.work_dir
    
    // Create isolated working directory for this cluster
    sh "mkdir -p ${workDir}"
    sh "cp -r eks-cluster/* ${workDir}/ 2>/dev/null || true"
    
    dir(workDir) {
        // Clean up any existing state
        sh "rm -rf .terraform"
        sh "rm -f .terraform.lock.hcl"
        
        // Initialize with backend configuration override
        // tfvars file is now in the current directory after being copied
        sh """
            terraform init -reconfigure \
            -backend-config="key=${backendKey}" \
            -var-file=${tfVarFile}
        """

        if (action == 'apply') {
            echo "Applying Terraform configuration for ${clusterName} using ${tfVarFile}..."
            sh "terraform apply -auto-approve -var-file=${tfVarFile}"
        } else if (action == 'destroy') {
            echo "Destroying Terraform infrastructure for ${clusterName} using ${tfVarFile}..."
            sh "terraform destroy -auto-approve -var-file=${tfVarFile}"
        }
    }
}

def deployKubernetes(config) {
    dir("Kubernetes") {
        def clusterName = config.cluster_name
        def kubeconfigRegion = config.kubeconfig_region
        def kubeconfigFile = "${env.WORKSPACE}/kubeconfig-${clusterName}"

        echo "Deploying to ${clusterName}..."
        
        // Create cluster-specific kubeconfig file
        sh "aws eks update-kubeconfig --name ${clusterName} --region ${kubeconfigRegion} --kubeconfig ${kubeconfigFile}"
        
        // Set KUBECONFIG environment variable for all kubectl commands
        withEnv(["KUBECONFIG=${kubeconfigFile}"]) {
            // Create namespace first
            sh "kubectl create namespace simple-web-app --dry-run=client -o yaml | kubectl apply -f -"
            
            // Create or update Docker registry secret
            withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', 
                                              usernameVariable: 'DOCKER_USER', 
                                              passwordVariable: 'DOCKER_PASS')]) {
                sh """
                    kubectl create secret docker-registry private-docker-registry \
                      --docker-server=docker.io \
                      --docker-username=\${DOCKER_USER} \
                      --docker-password=\${DOCKER_PASS} \
                      --docker-email=gcpa2279@gmail.com \
                      -n simple-web-app \
                      --dry-run=client -o yaml | kubectl apply -f -
                """
            }
            
            // Deploy application
            sh "kubectl apply -f tomcat-deployment.yaml"
            
            // Wait for LoadBalancer to be ready
            sh "kubectl get service -n simple-web-app"
            
            echo "Waiting for LoadBalancer External IP for ${clusterName}..."
            sh "sleep 5"  // Give a moment for status to update
            sh "kubectl get service simple-web-app-service -n simple-web-app -o wide"
        }
        
        // Cleanup kubeconfig file
        sh "rm -f ${kubeconfigFile}"
    }
}

def cleanupKubernetes(config) {
    dir("Kubernetes") {
        def clusterName = config.cluster_name
        def kubeconfigRegion = config.kubeconfig_region
        
        sh '''
            if aws eks describe-cluster --name ''' + clusterName + ''' --region ''' + kubeconfigRegion + ''' >/dev/null 2>&1;
            then
                echo "EKS cluster ''' + clusterName + ''' exists, updating kubeconfig..."
                aws eks update-kubeconfig --name ''' + clusterName + ''' --region ''' + kubeconfigRegion + '''
                echo "Cleaning up Kubernetes resources..."
                kubectl delete -f tomcat-deployment.yaml -n simple-web-app --ignore-not-found=true
            else
                echo "EKS cluster ''' + clusterName + ''' does not exist, skipping Kubernetes cleanup"
            fi
        '''
    }
}

// Start the declarative pipeline block
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Choose whether to apply or destroy the Terraform infrastructure'
        )
    }
    
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = "us-east-1"
        DOCKER_IMAGE = 'myapp'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials'
    }
    
    stages {
        stage("Parallel Cluster Action") {
            parallel {
                stage("Cluster-East Action") {
                    steps {
                        script {
                            executeTerraformAction(eastConfig, params.ACTION)
                        }
                    }
                }
                
                stage("Cluster-West Action") {
                    steps {
                        script {
                            executeTerraformAction(westConfig, params.ACTION)
                        }
                    }
                }
            }
        }
        
        stage("Parallel Deploy to EKS") {
            when {
                expression { params.ACTION == 'apply' }
            }
            parallel {
                stage("Deploy to Cluster-East") {
                    steps {
                        script {
                            deployKubernetes(eastConfig)
                        }
                    }
                }
                stage("Deploy to Cluster-West") {
                    steps {
                        script {
                            deployKubernetes(westConfig)
                        }
                    }
                }
            }
        }
        
        stage("Parallel Cleanup Kubernetes Resources") {
            when {
                expression { params.ACTION == 'destroy' }
            }
            parallel {
                stage("Cleanup Cluster-East K8s") {
                    steps {
                        script {
                            cleanupKubernetes(eastConfig)
                        }
                    }
                }
                stage("Cleanup Cluster-West K8s") {
                    steps {
                        script {
                            cleanupKubernetes(westConfig)
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "Pipeline completed with action: ${params.ACTION}"
            // Clean up temporary working directories
            sh 'rm -rf eks-cluster-east eks-cluster-west || true'
        }
        success {
            script {
                if (params.ACTION == 'apply') {
                    echo "Infrastructure successfully created and applications deployed!"
                } else {
                    echo "Infrastructure successfully destroyed!"
                }
            }
        }
        failure {
            script {
                if (params.ACTION == 'apply') {
                    echo "Failed to create infrastructure or deploy applications"
                } else {
                    echo "Failed to destroy infrastructure"
                }
            }
        }
    }
}
