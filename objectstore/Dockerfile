# Multi-stage build for D lang application
FROM dlang2/ldc-ubuntu:1.36.0 AS builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    libssl-dev \
    zlib1g-dev \
    libevent-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy dub files first for better caching
COPY dub.json dub.selections.json* ./

# Fetch dependencies
RUN dub fetch

# Copy source code
COPY source ./source

# Build the application
RUN dub build --build=release --compiler=ldc2

# Runtime stage
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl3 \
    zlib1g \
    libevent-2.1-7 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 objectstore && \
    mkdir -p /app/data/storage /app/data/metadata && \
    chown -R objectstore:objectstore /app

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/bin/objectstore-service /app/objectstore-service

# Switch to non-root user
USER objectstore

# Create data directories
RUN mkdir -p /app/data/storage /app/data/metadata

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Set environment variables
ENV PORT=8080 \
    STORAGE_PATH=/app/data/storage \
    METADATA_PATH=/app/data/metadata \
    ENABLE_AUTH=true

# Run the application
CMD ["/app/objectstore-service"]
