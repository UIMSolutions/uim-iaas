#!/bin/bash

# Development script to run all services locally

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Starting UIM IaaS Platform services locally..."

# Array of services and their ports
declare -a services=(
    "auth:8084"
    "compute:8081"
    "storage:8082"
    "network:8083"
    "monitoring:8085"
    "gateway:8080"
)

# Array to track PIDs
pids=()

# Function to kill all services on exit
cleanup() {
    echo ""
    echo "Stopping all services..."
    for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
        fi
    done
    wait 2>/dev/null || true
    echo "All services stopped."
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

# Start services in the background
for service_port in "${services[@]}"; do
    IFS=':' read -r service port <<< "$service_port"
    echo "Starting $service on port $port..."
    cd "$PROJECT_DIR/$service"
    dub run > "/tmp/uim-iaas-$service.log" 2>&1 &
    pids+=($!)
    cd "$PROJECT_DIR"
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
echo "Logs are available at /tmp/uim-iaas-*.log"
echo "Press Ctrl+C to stop all services"
echo ""

# Wait for all background processes
wait
