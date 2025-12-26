#!/bin/bash

# Kali Wireless Docker Setup Script
# This script initializes the environment and provides quick access

set -e

echo "==================================="
echo "Kali Wireless Docker Setup"
echo "==================================="
echo ""

# Create necessary directories
echo "[+] Creating directory structure..."
mkdir -p captures wordlists output

# Set proper permissions
chmod 755 captures wordlists output

echo "[+] Directory structure created:"
echo "    - ./captures   (for packet captures)"
echo "    - ./wordlists  (for password lists)"
echo "    - ./output     (for general output)"
echo ""

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "[!] docker-compose not found. Please install docker-compose first."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "[!] Docker daemon is not running. Please start Docker first."
    exit 1
fi

# Build the image
echo "[+] Building Kali Wireless image..."
echo "    This may take several minutes..."
docker-compose build

echo ""
echo "[+] Setup complete!"
echo ""
echo "Quick Commands:"
echo "  Start container:  docker-compose up -d"
echo "  Access shell:     docker-compose exec kali-wireless /bin/bash"
echo "  View logs:        docker-compose logs -f"
echo "  Stop container:   docker-compose stop"
echo "  Remove all:       docker-compose down"
echo ""
echo "Wireless Interface Tips:"
echo "  1. Container uses host networking mode"
echo "  2. Requires privileged access for monitor mode"
echo "  3. Your wireless adapter must support monitor mode"
echo "  4. Use 'airmon-ng' to manage monitor mode"
echo ""
echo "Would you like to start the container now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "[+] Starting container..."
    docker-compose up -d
    echo "[+] Container started!"
    echo ""
    echo "Access the container with:"
    echo "  docker-compose exec kali-wireless /bin/bash"
else
    echo "[+] Container not started. Run 'docker-compose up -d' when ready."
fi
