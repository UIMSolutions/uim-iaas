#!/bin/bash

# Remove all UIM IaaS services from Kubernetes

set -e

echo "Removing UIM IaaS Platform from Kubernetes..."

kubectl delete -f k8s/api-gateway.yaml --ignore-not-found
kubectl delete -f k8s/monitoring-service.yaml --ignore-not-found
kubectl delete -f k8s/network-service.yaml --ignore-not-found
kubectl delete -f k8s/storage-service.yaml --ignore-not-found
kubectl delete -f k8s/compute-service.yaml --ignore-not-found
kubectl delete -f k8s/auth-service.yaml --ignore-not-found
kubectl delete -f k8s/namespace.yaml --ignore-not-found

echo ""
echo "UIM IaaS Platform removed successfully!"
