# Local Docker Setup for Bookshelf

This guide walks you through building and deploying Bookshelf locally using Docker.

## Prerequisites

- **Docker**: [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose**: [Install Docker Compose](https://docs.docker.com/compose/install/)
- **.NET 6 SDK**: For building the application
- **Node.js & Yarn**: For building the frontend
- **Git**: For repository operations (optional, for git metadata in builds)

## Quick Start - Using Docker Compose

The easiest way to build and deploy locally:

```bash
# Make the build script executable
chmod +x build-local.sh

# Run the build script (builds backend, frontend, and Docker image)
./build-local.sh

# Start the container with docker-compose
docker-compose up -d

# View logs
docker-compose logs -f bookshelf

# Stop the container
docker-compose down
```

Access the web UI at: **http://localhost:8787**

## Manual Build Steps

If you prefer to build step-by-step:

### 1. Install Frontend Dependencies
```bash
cd frontend
yarn install --frozen-lockfile --network-timeout 120000
```

### 2. Build Frontend
```bash
yarn run build --env production
cd ..
```

### 3. Build .NET Backend
```bash
dotnet msbuild -restore src/Readarr.sln \
  -p:Configuration=Release \
  -p:Platform=Posix \
  -p:RuntimeIdentifiers=linux-musl-x64 \
  -t:PublishAllRids
```

### 4. Build Docker Image
```bash
docker build \
  --build-arg TARGETPLATFORM=linux/amd64 \
  --build-arg GIT_BRANCH=main \
  --build-arg COMMIT_HASH=local-dev \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg METADATA_URL=https://api.bookinfo.pro \
  --build-arg HARDCOVER=true \
  -t bookshelf:local-dev \
  -f docker/Dockerfile \
  .
```

### 5. Run the Container
```bash
docker run -p 8787:8787 -v ~/.config/bookshelf:/config bookshelf:local-dev
```

## Configuration

### Environment Variables

Edit `docker-compose.yml` or set when running:

```bash
# Using docker-compose
export PUID=1000           # User ID
export PGID=1000           # Group ID
export TZ=UTC              # Timezone
export METADATA_URL=https://api.bookinfo.pro  # Metadata provider
export HARDCOVER=true      # Use Hardcover metadata (true) or Goodreads (false)
docker-compose up -d
```

### Volume Mounting

By default, config is stored in a Docker volume (`bookshelf-config`).

To use a local directory instead:

```bash
# Edit docker-compose.yml and change:
volumes:
  - ~/my-bookshelf-config:/config
```

Or with `docker run`:
```bash
docker run -p 8787:8787 -v ~/my-bookshelf-config:/config bookshelf:local-dev
```

## Development Workflow

For active development, you can:

1. **Run the application directly** (without Docker):
   ```bash
   cd src
   dotnet run --project Readarr.Console/Readarr.Console.csproj
   ```

2. **Or use Docker with hot-reload**:
   ```bash
   # Rebuild and restart container when code changes
   docker-compose up -d --build
   ```

## Troubleshooting

### Container exits immediately
Check logs for errors:
```bash
docker logs bookshelf
```

### Port 8787 already in use
Change the port mapping in `docker-compose.yml`:
```yaml
ports:
  - "9999:8787"  # Maps container port 8787 to host port 9999
```

### Permission issues with volumes
Adjust `PUID` and `PGID` to match your user:
```bash
id  # Shows your UID and GID
export PUID=<your-uid>
export PGID=<your-gid>
docker-compose up -d
```

### Database not persisting
Ensure the volume is mounted and Docker has write permissions:
```bash
docker inspect bookshelf-config  # Check volume details
```

## Useful Commands

```bash
# View container logs
docker logs -f bookshelf

# Open a shell in the running container
docker exec -it bookshelf /bin/sh

# View container resource usage
docker stats bookshelf

# Stop the container gracefully
docker-compose down

# Remove all containers and volumes
docker-compose down -v

# Rebuild image without cache
docker-compose build --no-cache

# Remove unused Docker resources
docker system prune -a
```

## Metadata Providers

### Hardcover (Default)
- Higher quality metadata
- Not backward-compatible with Goodreads databases
- Better matching and series support

### Goodreads
Set `HARDCOVER=false` in `docker-compose.yml` or when running:
```bash
docker run -p 8787:8787 \
  -e HARDCOVER=false \
  -v ~/.config/bookshelf:/config \
  bookshelf:local-dev
```

## Building for Different Platforms

The default setup builds for `linux/amd64`. To build for other platforms:

### Linux ARM64 (e.g., Raspberry Pi)
```bash
# Edit build-local.sh and change linux-musl-x64 to linux-musl-arm64
# Then rebuild with:
./build-local.sh
```

### Building Multi-Platform Images
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t bookshelf:latest \
  -f docker/Dockerfile \
  .
```

## Additional Resources

- [Bookshelf GitHub](https://github.com/pennydreadful/bookshelf)
- [Readarr Documentation](https://wiki.servarr.com/readarr)
- [Docker Documentation](https://docs.docker.com/)
