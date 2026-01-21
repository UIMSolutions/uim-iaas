#!/bin/bash

# Deploy all services to Kubernetes

set -e

echo "Deploying UIM IaaS Platform to Kubernetes..."

# Create namespace and configmap
echo "Creating namespace and configuration..."
kubectl apply -f k8s/namespace.yaml

# Deploy all services
echo ""
echo "Deploying services..."
kubectl apply -f k8s/auth-service.yaml
kubectl apply -f k8s/compute-service.yaml
kubectl apply -f k8s/storage-service.yaml
kubectl apply -f k8s/network-service.yaml
kubectl apply -f k8s/monitoring-service.yaml
kubectl apply -f k8s/api-gateway.yaml

echo ""
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/auth-service \
    deployment/compute-service \
    deployment/storage-service \
    deployment/network-service \
    deployment/monitoring-service \
    deployment/api-gateway \
    -n uim-iaas

echo ""
echo "========================================="
echo "Deployment completed successfully!"
echo "========================================="
echo ""
echo "Services status:"
kubectl get pods -n uim-iaas
echo ""
echo "Services:"
kubectl get svc -n uim-iaas
echo ""
echo "To access the API Gateway:"
echo "kubectl port-forward -n uim-iaas svc/api-gateway 8080:80"
