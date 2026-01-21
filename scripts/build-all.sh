#!/bin/bash

# Build all Docker images for UIM IaaS Platform

set -e

SERVICES=("api-gateway" "compute-service" "storage-service" "network-service" "auth-service" "monitoring-service")

echo "Building Docker images for UIM IaaS Platform..."

for service in "${SERVICES[@]}"; do
    echo ""
    echo "========================================="
    echo "Building $service..."
    echo "========================================="
    cd services/$service
    docker build -t uim-iaas/$service:latest .
    cd ../..
    echo "✓ $service image built successfully"
done

echo ""
echo "========================================="
echo "All images built successfully!"
echo "========================================="
echo ""
echo "Built images:"
docker images | grep uim-iaas
