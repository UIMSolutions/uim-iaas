#!/bin/bash
# Deployment script for Object Store Service

set -e

echo "========================================="
echo "Object Store Service Deployment Script"
echo "========================================="

# Configuration
NAMESPACE="objectstore"
IMAGE_NAME="objectstore-service"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "docker not found. Please install docker."
        exit 1
    fi
    
    log_info "Prerequisites check passed!"
}

# Build Docker image
build_image() {
    log_info "Building Docker image..."
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
    
    if [ $? -eq 0 ]; then
        log_info "Docker image built successfully!"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

# Deploy to Kubernetes
deploy_k8s() {
    log_info "Deploying to Kubernetes..."
    
    # Create namespace
    log_info "Creating namespace..."
    kubectl apply -f k8s/namespace.yaml
    
    # Create PVC
    log_info "Creating persistent volume claim..."
    kubectl apply -f k8s/pvc.yaml
    
    # Create ConfigMap
    log_info "Creating config map..."
    kubectl apply -f k8s/configmap.yaml
    
    # Create Secret (warn user to update it)
    log_warn "Please ensure you've updated the AUTH_TOKEN in k8s/secret.yaml"
    read -p "Press enter to continue..."
    kubectl apply -f k8s/secret.yaml
    
    # Deploy application
    log_info "Deploying application..."
    kubectl apply -f k8s/deployment.yaml
    kubectl apply -f k8s/service.yaml
    
    # Deploy HPA
    log_info "Deploying horizontal pod autoscaler..."
    kubectl apply -f k8s/hpa.yaml
    
    # Optionally deploy ingress
    read -p "Do you want to deploy ingress? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Please ensure you've updated the host in k8s/ingress.yaml"
        read -p "Press enter to continue..."
        kubectl apply -f k8s/ingress.yaml
    fi
    
    log_info "Deployment completed!"
}

# Wait for deployment to be ready
wait_for_ready() {
    log_info "Waiting for deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s \
        deployment/objectstore-service -n ${NAMESPACE}
    
    if [ $? -eq 0 ]; then
        log_info "Deployment is ready!"
    else
        log_error "Deployment failed to become ready"
        exit 1
    fi
}

# Show status
show_status() {
    log_info "Deployment Status:"
    echo "==================="
    
    echo -e "\n${GREEN}Pods:${NC}"
    kubectl get pods -n ${NAMESPACE}
    
    echo -e "\n${GREEN}Services:${NC}"
    kubectl get svc -n ${NAMESPACE}
    
    echo -e "\n${GREEN}Ingress:${NC}"
    kubectl get ingress -n ${NAMESPACE} 2>/dev/null || echo "No ingress found"
    
    echo -e "\n${GREEN}HPA:${NC}"
    kubectl get hpa -n ${NAMESPACE}
}

# Port forward for local access
port_forward() {
    log_info "Setting up port forwarding..."
    log_info "Access the service at: http://localhost:8080"
    log_info "Press Ctrl+C to stop"
    kubectl port-forward svc/objectstore-service 8080:80 -n ${NAMESPACE}
}

# Main menu
show_menu() {
    echo ""
    echo "What would you like to do?"
    echo "1) Build Docker image"
    echo "2) Deploy to Kubernetes"
    echo "3) Build and Deploy (full deployment)"
    echo "4) Show deployment status"
    echo "5) Port forward (access locally)"
    echo "6) View logs"
    echo "7) Delete deployment"
    echo "8) Exit"
    echo ""
}

# View logs
view_logs() {
    log_info "Viewing logs (Ctrl+C to exit)..."
    kubectl logs -f deployment/objectstore-service -n ${NAMESPACE}
}

# Delete deployment
delete_deployment() {
    log_warn "This will delete the entire deployment including data!"
    read -p "Are you sure? (yes/no) " -r
    echo
    if [[ $REPLY == "yes" ]]; then
        log_info "Deleting deployment..."
        kubectl delete -f k8s/
        log_info "Deployment deleted!"
    else
        log_info "Deletion cancelled"
    fi
}

# Main execution
main() {
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                build_image
                ;;
            2)
                deploy_k8s
                wait_for_ready
                show_status
                ;;
            3)
                build_image
                deploy_k8s
                wait_for_ready
                show_status
                ;;
            4)
                show_status
                ;;
            5)
                port_forward
                ;;
            6)
                view_logs
                ;;
            7)
                delete_deployment
                ;;
            8)
                log_info "Goodbye!"
                exit 0
                ;;
            *)
                log_error "Invalid choice. Please try again."
                ;;
        esac
    done
}

# Run main function
main
