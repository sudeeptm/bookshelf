#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Bookshelf Local Docker Build & Deploy${NC}"
echo -e "${YELLOW}========================================${NC}"

# Step 1: Check dependencies
echo -e "${YELLOW}\n[1/5] Checking dependencies...${NC}"
command -v dotnet >/dev/null 2>&1 || { echo -e "${RED}dotnet is not installed${NC}"; exit 1; }
command -v yarn >/dev/null 2>&1 || { echo -e "${RED}yarn is not installed${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}docker is not installed${NC}"; exit 1; }
echo -e "${GREEN}✓ All dependencies found${NC}"

# Step 2: Install frontend dependencies
echo -e "${YELLOW}\n[2/5] Installing frontend dependencies...${NC}"
yarn install --frozen-lockfile --network-timeout 120000
echo -e "${GREEN}✓ Frontend dependencies installed${NC}"

# Step 3: Build frontend
echo -e "${YELLOW}\n[3/5] Building frontend...${NC}"
yarn run build --env production
if [ ! -d "_output/UI" ]; then
    echo -e "${RED}✗ Frontend build failed - _output/UI not created${NC}"
    echo -e "${RED}Checking for errors...${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Frontend built${NC}"

# Step 4: Build .NET backend
echo -e "${YELLOW}\n[4/5] Building .NET backend...${NC}"
dotnet msbuild -restore src/Readarr.sln \
  -p:Configuration=Release \
  -p:Platform=Posix \
  -p:RuntimeIdentifiers=linux-musl-x64 \
  -t:PublishAllRids
if [ ! -d "_output/net6.0/linux-musl-x64" ]; then
    echo -e "${RED}✗ Backend build failed - _output/net6.0/linux-musl-x64 not created${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Backend built${NC}"

# Step 5: Build Docker image
echo -e "${YELLOW}\n[5/5] Building Docker image...${NC}"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local-dev")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

docker build \
  --build-arg TARGETPLATFORM=linux/amd64 \
  --build-arg GIT_BRANCH="${GIT_BRANCH}" \
  --build-arg COMMIT_HASH="${COMMIT_HASH}" \
  --build-arg BUILD_DATE="${BUILD_DATE}" \
  --build-arg METADATA_URL=https://api.bookinfo.pro \
  --build-arg HARDCOVER=true \
  -t bookshelf:local-dev \
  -f docker/Dockerfile \
  .

echo -e "${GREEN}✓ Docker image built${NC}"

echo -e "${GREEN}\n========================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Start with docker-compose:"
echo "     docker-compose up -d"
echo ""
echo "  2. Or run directly:"
echo "     docker run -p 8787:8787 -v ~/.config/bookshelf:/config bookshelf:local-dev"
echo ""
echo "  3. Access the web UI:"
echo "     http://localhost:8787"
echo ""
