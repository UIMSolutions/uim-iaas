#!/bin/bash

# Development script to run all services locally

set -e

echo "Starting UIM IaaS Platform services locally..."

# Start services in the background
services=("auth-service:8084" "compute-service:8081" "storage-service:8082" "network-service:8083" "monitoring-service:8085" "api-gateway:8080")

for service_port in "${services[@]}"; do
    IFS=':' read -r service port <<< "$service_port"
    echo "Starting $service on port $port..."
    cd services/$service
    dub run &
    cd ../..
    sleep 2
done

echo ""
echo "All services started!"
echo ""
echo "Services:"
echo "  - API Gateway: http://localhost:8080"
echo "  - Auth Service: http://localhost:8084"
echo "  - Compute Service: http://localhost:8081"
echo "  - Storage Service: http://localhost:8082"
echo "  - Network Service: http://localhost:8083"
echo "  - Monitoring Service: http://localhost:8085"
echo ""
echo "Press Ctrl+C to stop all services"

wait
