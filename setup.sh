#!/bin/bash

# Kali Wireless Docker Setup Script
# This script initializes the environment and provides quick access

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
USE_GPU=false
COMPOSE_FILE="docker-compose.yml"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --gpu)
            USE_GPU=true
            COMPOSE_FILE="docker-compose.gpu.yml"
            shift
            ;;
        --help|-h)
            echo "Kali Wireless Docker Setup Script"
            echo ""
            echo "Usage: ./setup.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --gpu     Enable GPU support for hashcat acceleration"
            echo "  --help    Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./setup.sh          # Standard setup without GPU"
            echo "  ./setup.sh --gpu    # Setup with NVIDIA GPU support"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "==================================="
echo "Kali Wireless Docker Setup"
echo "==================================="
echo ""

# Create necessary directories
echo -e "${GREEN}[+]${NC} Creating directory structure..."
mkdir -p captures wordlists output

# Set proper permissions
chmod 755 captures wordlists output

echo -e "${GREEN}[+]${NC} Directory structure created:"
echo "    - ./captures   (for packet captures)"
echo "    - ./wordlists  (for password lists)"
echo "    - ./output     (for general output)"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}[!]${NC} docker-compose not found. Please install docker-compose first."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo -e "${RED}[!]${NC} Docker daemon is not running. Please start Docker first."
    exit 1
fi

# GPU-specific checks
if [ "$USE_GPU" = true ]; then
    echo -e "${BLUE}[*]${NC} GPU mode enabled. Checking requirements..."
    echo ""

    # Check for NVIDIA GPU
    if ! command -v nvidia-smi &> /dev/null; then
        echo -e "${RED}[!]${NC} nvidia-smi not found. NVIDIA drivers may not be installed."
        echo "    Please install NVIDIA drivers first."
        echo "    See README.md GPU Passthrough section for instructions."
        exit 1
    fi

    # Display GPU info
    echo -e "${GREEN}[+]${NC} Detected NVIDIA GPU(s):"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader | while read line; do
        echo "    $line"
    done
    echo ""

    # Check for NVIDIA Container Toolkit
    if ! docker info 2>/dev/null | grep -q "nvidia"; then
        echo -e "${YELLOW}[!]${NC} NVIDIA Container Toolkit may not be configured."
        echo "    Testing GPU access in Docker..."

        if docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
            echo -e "${GREEN}[+]${NC} GPU access verified in Docker!"
        else
            echo -e "${RED}[!]${NC} Cannot access GPU in Docker."
            echo ""
            echo "    Please install NVIDIA Container Toolkit:"
            echo "    1. curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
            echo "    2. sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit"
            echo "    3. sudo nvidia-ctk runtime configure --runtime=docker"
            echo "    4. sudo systemctl restart docker"
            echo ""
            echo "    See README.md for detailed instructions."
            exit 1
        fi
    else
        echo -e "${GREEN}[+]${NC} NVIDIA Container Toolkit detected."
    fi

    echo ""
    COMPOSE_FILE="docker-compose.gpu.yml"
fi

# Build the image
echo -e "${GREEN}[+]${NC} Building Kali Wireless image..."
if [ "$USE_GPU" = true ]; then
    echo -e "    Using: ${BLUE}${COMPOSE_FILE}${NC} (GPU-enabled)"
else
    echo -e "    Using: ${BLUE}${COMPOSE_FILE}${NC}"
fi
echo "    This may take several minutes..."
docker-compose -f "$COMPOSE_FILE" build

echo ""
echo -e "${GREEN}[+]${NC} Setup complete!"
echo ""
echo "Quick Commands:"
echo -e "  Start container:  ${BLUE}docker-compose -f $COMPOSE_FILE up -d${NC}"
echo -e "  Access shell:     ${BLUE}docker-compose -f $COMPOSE_FILE exec kali-wireless /bin/bash${NC}"
echo -e "  View logs:        ${BLUE}docker-compose -f $COMPOSE_FILE logs -f${NC}"
echo -e "  Stop container:   ${BLUE}docker-compose -f $COMPOSE_FILE stop${NC}"
echo -e "  Remove all:       ${BLUE}docker-compose -f $COMPOSE_FILE down${NC}"
echo ""

if [ "$USE_GPU" = true ]; then
    echo "GPU Commands (inside container):"
    echo -e "  Check GPU:        ${BLUE}hashcat -I${NC}"
    echo -e "  Benchmark:        ${BLUE}hashcat -b -m 22000${NC}"
    echo -e "  Crack WPA2:       ${BLUE}hashcat -m 22000 -a 0 hashes.hc22000 wordlist.txt${NC}"
    echo ""
fi

echo "Wireless Interface Tips:"
echo "  1. Container uses host networking mode"
echo "  2. Requires privileged access for monitor mode"
echo "  3. Your wireless adapter must support monitor mode"
echo "  4. Use 'airmon-ng' to manage monitor mode"
echo ""
echo "Would you like to start the container now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}[+]${NC} Starting container..."
    docker-compose -f "$COMPOSE_FILE" up -d
    echo -e "${GREEN}[+]${NC} Container started!"
    echo ""
    echo "Access the container with:"
    echo -e "  ${BLUE}docker-compose -f $COMPOSE_FILE exec kali-wireless /bin/bash${NC}"
else
    echo -e "${GREEN}[+]${NC} Container not started. Run 'docker-compose -f $COMPOSE_FILE up -d' when ready."
fi
