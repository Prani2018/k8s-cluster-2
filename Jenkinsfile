// Define configuration maps and helper functions outside the 'pipeline' block
// to be accessible by the Groovy runtime.

// Configuration Maps
def eastConfig = [
    tf_var_file: 'east.tfvars',
    kubeconfig_region: 'us-east-1',
    cluster_name: 'Cluster-East',
    backend_key: 'eks/cluster-state-us-east-1.tfstate'  // Add explicit backend key
]

def westConfig = [
    tf_var_file: 'west.tfvars',
    kubeconfig_region: 'us-west-2',
    cluster_name: 'Cluster-West',
    backend_key: 'eks/cluster-state-us-west-2.tfstate'  // Add explicit backend key
]

// Helper Functions
def executeTerraformAction(config, action) {
    dir("eks-cluster") {
        def tfVarFile = config.tf_var_file
        def clusterName = config.cluster_name
        def backendKey = config.backend_key

        // Always re-init for the specific region's state file before any action
        sh "rm -rf .terraform"
        sh "rm -f .terraform.lock.hcl"
        
        // Initialize with backend configuration override
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

        echo "Deploying to ${clusterName}..."
        sh "aws eks update-kubeconfig --name ${clusterName} --region ${kubeconfigRegion}"
        sh "cat /var/lib/jenkins/.kube/config"
        sh "kubectl apply -f tomcat-deployment.yaml -n simple-web-app"
        sh "kubectl get service -n simple-web-app"
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
