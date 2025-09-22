# Dockerfile for building BitrotBruteforce with CUDA support
FROM nvidia/cuda:12.6.0-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    cmake \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install .NET 8 SDK
RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh \
    && chmod +x dotnet-install.sh \
    && ./dotnet-install.sh --version latest --channel 8.0 --install-dir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    && rm dotnet-install.sh

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Make build scripts executable
RUN chmod +x *.sh

# Build the project
RUN ./publish-linux.sh

# Create a runtime stage (optional, for smaller final image)
FROM nvidia/cuda:12.6.0-runtime-ubuntu22.04 AS runtime

# Install .NET runtime dependencies
RUN apt-get update && apt-get install -y \
    libicu70 \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy the built application
COPY --from=0 /app/publish/linux-x64 /app

WORKDIR /app

# Set the entrypoint
ENTRYPOINT ["./run.sh"]