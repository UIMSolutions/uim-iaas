MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PROJECT_DIR := $(dir $(MAKEFILE_PATH))

.PHONY: all build clean test run docker-build docker-run k8s-deploy k8s-undeploy help

# Default target
all: build

# Build all services
build:
	@echo "Building all services..."
	@for service in api-gateway compute-service storage-service network-service auth-service monitoring-service; do \
		echo "Building $$service..."; \
		cd services/$$service && dub build --build=release && cd ../..; \
	done
	@echo "Build complete!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@for service in api-gateway compute-service storage-service network-service auth-service monitoring-service; do \
		cd services/$$service && dub clean && cd ../..; \
	done
	@echo "Clean complete!"

# Run tests
test:
	@echo "Running tests..."
	@for service in api-gateway compute-service storage-service network-service auth-service monitoring-service; do \
		echo "Testing $$service..."; \
		cd services/$$service && dub test && cd ../..; \
	done
	@echo "Tests complete!"

# Run services locally
run:
	@chmod +x scripts/dev-run.sh
	@./scripts/dev-run.sh

# Build Docker images
docker-build:
	@chmod +x scripts/build-all.sh
	@./scripts/build-all.sh

# Run with Docker Compose
docker-run:
	docker-compose up --build

# Stop Docker Compose
docker-stop:
	docker-compose down

# Deploy to Kubernetes
k8s-deploy:
	@chmod +x scripts/deploy-k8s.sh
	@./scripts/deploy-k8s.sh

# Remove from Kubernetes
k8s-undeploy:
	@chmod +x scripts/undeploy-k8s.sh
	@./scripts/undeploy-k8s.sh

# Show Kubernetes status
k8s-status:
	@echo "Pods:"
	@kubectl get pods -n uim-iaas
	@echo ""
	@echo "Services:"
	@kubectl get svc -n uim-iaas

# View logs from a specific service
logs:
	@if [ -z "$(SERVICE)" ]; then \
		echo "Usage: make logs SERVICE=<service-name>"; \
		echo "Available services: api-gateway, compute-service, storage-service, network-service, auth-service, monitoring-service"; \
	else \
		kubectl logs -f -n uim-iaas -l app=$(SERVICE); \
	fi

# Help target
help:
	@echo "UIM IaaS Platform - Available targets:"
	@echo ""
	@echo "  make build          - Build all services"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make test           - Run tests"
	@echo "  make run            - Run services locally"
	@echo "  make docker-build   - Build Docker images"
	@echo "  make docker-run     - Run with Docker Compose"
	@echo "  make docker-stop    - Stop Docker Compose"
	@echo "  make k8s-deploy     - Deploy to Kubernetes"
	@echo "  make k8s-undeploy   - Remove from Kubernetes"
	@echo "  make k8s-status     - Show Kubernetes status"
	@echo "  make logs SERVICE=<name> - View logs for a service"
	@echo "  make help           - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make docker-build"
	@echo "  make k8s-deploy"
	@echo "  make logs SERVICE=api-gateway"
