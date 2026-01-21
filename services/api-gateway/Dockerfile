FROM dlang2/ldc-ubuntu:latest

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libevent-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy dub configuration
COPY dub.sdl .

# Copy source code
COPY source/ ./source/

# Build the application
RUN dub build --build=release --compiler=ldc2

# Expose port
EXPOSE 8080

# Run the application
CMD ["./api-gateway"]
