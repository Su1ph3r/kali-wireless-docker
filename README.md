# Kali Linux Wireless Assessment Docker Environment

A minimal Docker container with only wireless assessment tools for penetration testing.

## Installed Tools

### Core Wireless Tools
- **aircrack-ng** - WiFi security auditing suite (airodump-ng, aireplay-ng, aircrack-ng, etc.)
- **reaver** - WPS brute force attack tool
- **bully** - Alternative WPS brute force tool
- **wifite** - Automated wireless attack tool
- **kismet** - Wireless network detector, sniffer, and IDS
- **hostapd-wpe** - Modified hostapd for WPE (Wireless Pwnage Edition)
- **asleap** - Cisco LEAP/PPTP password recovery
- **mdk4** - Wireless testing and exploitation tool
- **hcxdumptool** - WiFi packet capture tool
- **hcxtools** - Tools to convert captures to hashcat format

### Supporting Tools
- **macchanger** - MAC address spoofing
- **hashcat** - Password cracking
- **tshark/tcpdump** - Packet analysis
- **wireless-tools/iw** - Wireless interface management

## Quick Start

### Build and Start
```bash
# Build the image
docker-compose build

# Start the container
docker-compose up -d

# Access the container
docker-compose exec kali-wireless /bin/bash
```

### Alternative: Direct Run
```bash
# Build
docker build -t kali-wireless .

# Run with host networking and privileges
docker run -it --rm \
  --privileged \
  --network host \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -v $(pwd)/captures:/root/wireless/captures \
  -v $(pwd)/wordlists:/root/wireless/wordlists \
  kali-wireless
```

## Usage Examples

### Put Wireless Interface in Monitor Mode
```bash
# List wireless interfaces
iwconfig

# Kill interfering processes
airmon-ng check kill

# Enable monitor mode
airmon-ng start wlan0
```

### Capture Handshakes with airodump-ng
```bash
# Scan networks
airodump-ng wlan0mon

# Capture specific network
airodump-ng -c 6 --bssid AA:BB:CC:DD:EE:FF -w /root/wireless/captures/capture wlan0mon
```

### Automated Attack with wifite
```bash
wifite --kill --dict /root/wireless/wordlists/rockyou.txt
```

### WPS Attack with reaver
```bash
reaver -i wlan0mon -b AA:BB:CC:DD:EE:FF -vv
```

### Convert Capture for Hashcat
```bash
# Convert pcap to hashcat format
hcxpcapngtool -o /root/wireless/captures/hashes.hc22000 /root/wireless/captures/capture-01.cap

# Crack with hashcat (on host with GPU)
hashcat -m 22000 hashes.hc22000 wordlist.txt
```

## Directory Structure

```
.
├── Dockerfile              # Container definition
├── docker-compose.yml      # Orchestration config
├── captures/              # Packet captures (mounted volume)
├── wordlists/             # Password wordlists (mounted volume)
└── output/                # General output files (mounted volume)
```

## Important Notes

### Wireless Interface Access
- Container runs in **host network mode** to access wireless interfaces
- Requires **privileged mode** and **NET_ADMIN/NET_RAW** capabilities
- Your wireless adapter must support monitor mode
- USB wireless adapters should be passed through to container

### Performance Tips
1. **GPU Cracking**: See [GPU Passthrough](#gpu-passthrough-for-hashcat) section for container GPU acceleration
2. **USB Adapters**: Use `--device=/dev/bus/usb` to pass through USB devices
3. **Wordlists**: Mount your wordlist directory for easy access

## GPU Passthrough for Hashcat

Enable GPU-accelerated password cracking inside the container using NVIDIA Container Toolkit.

### Prerequisites

1. **NVIDIA GPU** with CUDA support
2. **NVIDIA Driver** installed on host (version 470+ recommended)
3. **Docker** version 19.03 or later

### Step 1: Install NVIDIA Container Toolkit

#### Ubuntu/Debian
```bash
# Add NVIDIA package repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

#### RHEL/CentOS/Fedora
```bash
# Add repository
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

# Install toolkit
sudo dnf install -y nvidia-container-toolkit

# Configure Docker runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

#### Arch Linux
```bash
sudo pacman -S nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Step 2: Verify Installation

```bash
# Test NVIDIA runtime
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi
```

You should see your GPU information displayed.

### Step 3: Use GPU-Enabled Configuration

Use the GPU-enabled docker-compose file:

```bash
# Build and start with GPU support
docker-compose -f docker-compose.gpu.yml build
docker-compose -f docker-compose.gpu.yml up -d

# Access container
docker-compose -f docker-compose.gpu.yml exec kali-wireless /bin/bash
```

Or run directly:
```bash
docker run -it --rm \
  --privileged \
  --network host \
  --gpus all \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -v $(pwd)/captures:/root/wireless/captures \
  -v $(pwd)/wordlists:/root/wireless/wordlists \
  kali-wireless
```

### Step 4: Verify GPU in Container

```bash
# Inside the container, check hashcat recognizes GPU
hashcat -I

# Run benchmark
hashcat -b -m 22000
```

### GPU Cracking Examples

#### Crack WPA/WPA2 Handshake (Mode 22000)
```bash
# Using GPU with wordlist
hashcat -m 22000 -a 0 -d 1 /root/wireless/captures/hashes.hc22000 /root/wireless/wordlists/rockyou.txt

# With rules for better coverage
hashcat -m 22000 -a 0 -d 1 -r /usr/share/hashcat/rules/best64.rule \
  /root/wireless/captures/hashes.hc22000 /root/wireless/wordlists/rockyou.txt

# Brute force 8-digit numeric (common WiFi passwords)
hashcat -m 22000 -a 3 -d 1 /root/wireless/captures/hashes.hc22000 ?d?d?d?d?d?d?d?d
```

#### Performance Tuning
```bash
# Force workload profile (1=low, 2=default, 3=high, 4=nightmare)
hashcat -m 22000 -w 3 -d 1 hashes.hc22000 wordlist.txt

# Optimize for specific GPU
hashcat -m 22000 -O -d 1 hashes.hc22000 wordlist.txt

# Use multiple GPUs
hashcat -m 22000 -d 1,2 hashes.hc22000 wordlist.txt
```

### Expected Performance (Approximate)

| GPU Model | WPA2 (22000) Speed |
|-----------|-------------------|
| RTX 4090 | ~2,500,000 H/s |
| RTX 3090 | ~1,200,000 H/s |
| RTX 3080 | ~950,000 H/s |
| RTX 3070 | ~650,000 H/s |
| RTX 2080 Ti | ~650,000 H/s |
| GTX 1080 Ti | ~450,000 H/s |
| GTX 1070 | ~280,000 H/s |

*Actual speeds vary based on driver version, cooling, and power limits.*

### Troubleshooting GPU Issues

#### "No devices found/left"
```bash
# Verify GPU is visible to Docker
docker run --rm --gpus all nvidia/cuda:12.0-base-ubuntu22.04 nvidia-smi

# Check NVIDIA runtime is default
docker info | grep -i runtime

# Ensure nvidia-container-toolkit is installed
nvidia-ctk --version
```

#### "CUDA driver version is insufficient"
```bash
# Update NVIDIA driver on host
sudo apt-get update
sudo apt-get install --upgrade nvidia-driver-535  # or latest version

# Reboot required after driver update
sudo reboot
```

#### Poor Performance
```bash
# Check GPU utilization during cracking
watch -n 1 nvidia-smi

# Ensure GPU isn't thermal throttling
nvidia-smi -q -d TEMPERATURE

# Try different workload profiles
hashcat -m 22000 -w 4 ...  # Maximum performance (high power/heat)
```

#### OpenCL vs CUDA
```bash
# List available backends
hashcat -I

# Force CUDA backend (usually faster for NVIDIA)
hashcat -m 22000 -D 1 ...

# Force OpenCL backend
hashcat -m 22000 -D 2 ...
```

### Alternative: Host-Based GPU Cracking

If container GPU passthrough is problematic, crack on the host:

```bash
# Convert capture inside container
hcxpcapngtool -o /root/wireless/captures/hashes.hc22000 /root/wireless/captures/capture.cap

# Exit container and crack on host (captures directory is mounted)
exit
hashcat -m 22000 ./captures/hashes.hc22000 /path/to/wordlist.txt
```

This approach uses the host's native GPU drivers for maximum compatibility.

## USB Wireless Adapter Passthrough

Pass USB wireless adapters to the container for monitor mode and packet injection.

### Understanding USB Passthrough Methods

There are three approaches to USB passthrough, each with trade-offs:

| Method | Hot-plug Support | Security | Ease of Use |
|--------|-----------------|----------|-------------|
| Full USB bus (`/dev/bus/usb`) | Yes | Low | Easy |
| Specific device (`/dev/bus/usb/XXX/YYY`) | No | Medium | Medium |
| Device cgroup rule | Yes | High | Complex |

### Method 1: Full USB Bus Access (Recommended for Testing)

Pass the entire USB bus to the container. Adapters can be plugged/unplugged while running.

#### docker-compose.yml
```yaml
services:
  kali-wireless:
    # ... other config ...
    volumes:
      - /dev/bus/usb:/dev/bus/usb
    privileged: true
```

#### Direct Docker Run
```bash
docker run -it --rm \
  --privileged \
  --network host \
  -v /dev/bus/usb:/dev/bus/usb \
  -v $(pwd)/captures:/root/wireless/captures \
  kali-wireless
```

### Method 2: Specific Device Passthrough

Pass only a specific USB device. More secure but requires knowing the device path.

#### Find Your Adapter
```bash
# List USB devices on host
lsusb

# Example output:
# Bus 001 Device 005: ID 148f:5370 Ralink Technology, Corp. RT5370 Wireless Adapter
# The path is /dev/bus/usb/001/005
```

#### docker-compose.yml
```yaml
services:
  kali-wireless:
    # ... other config ...
    devices:
      - /dev/bus/usb/001/005:/dev/bus/usb/001/005
    privileged: true
```

#### Direct Docker Run
```bash
docker run -it --rm \
  --privileged \
  --network host \
  --device=/dev/bus/usb/001/005 \
  kali-wireless
```

**Note:** Device numbers change when unplugged/replugged. Use Method 1 or 3 for hot-plug support.

### Method 3: Device Cgroup Rules (Advanced)

Allow access by USB vendor/product ID. Supports hot-plug with better security.

#### Find Vendor and Product ID
```bash
lsusb
# Bus 001 Device 005: ID 148f:5370 Ralink Technology, Corp. RT5370
#                        ^^^^:^^^^
#                        Vendor:Product
```

#### docker-compose.yml
```yaml
services:
  kali-wireless:
    # ... other config ...
    device_cgroup_rules:
      - 'c 189:* rmw'  # USB devices (major 189)
    volumes:
      - /dev/bus/usb:/dev/bus/usb:ro
    privileged: true
```

### Verifying USB Adapter in Container

```bash
# Inside container, list USB devices
lsusb

# Check wireless interfaces
iwconfig

# Or use iw
iw dev

# List all network interfaces
ip link show
```

### Recommended USB Wireless Adapters

These chipsets have excellent Linux/monitor mode support:

| Chipset | Monitor Mode | Packet Injection | Recommended Adapters |
|---------|-------------|------------------|---------------------|
| Atheros AR9271 | Yes | Yes | Alfa AWUS036NHA |
| Ralink RT3070 | Yes | Yes | Alfa AWUS036NH |
| Ralink RT5370 | Yes | Yes | Panda PAU05 |
| Realtek RTL8812AU | Yes | Yes | Alfa AWUS036ACH |
| Realtek RTL8814AU | Yes | Yes | Alfa AWUS1900 |
| MediaTek MT7612U | Yes | Yes | Alfa AWUS036ACM |

### Enabling Monitor Mode

```bash
# Inside container
# Kill interfering processes
airmon-ng check kill

# Enable monitor mode
airmon-ng start wlan0

# Verify monitor mode
iwconfig wlan0mon
# Should show "Mode:Monitor"
```

### Testing Packet Injection

```bash
# Test injection capability
aireplay-ng --test wlan0mon

# Expected output for working injection:
# Injection is working!
```

### Troubleshooting USB Issues

#### Adapter Not Visible in Container

```bash
# On host, verify adapter is recognized
lsusb
dmesg | tail -20

# Check if driver loaded
lsmod | grep -E "(ath9k|rt2800|rtl8812|mt76)"

# Ensure container has USB access
docker inspect kali-wireless | grep -A5 "Devices"
```

#### "Operation not permitted" Errors

```bash
# Verify privileged mode
docker inspect kali-wireless | grep Privileged
# Should show: "Privileged": true

# Check capabilities
docker inspect kali-wireless | grep -A10 "CapAdd"
# Should include NET_ADMIN and NET_RAW
```

#### Monitor Mode Fails

```bash
# Some drivers need rfkill unblocked
rfkill list
rfkill unblock all

# Try manual monitor mode
ip link set wlan0 down
iw dev wlan0 set type monitor
ip link set wlan0 up
```

#### Driver Issues

```bash
# Inside container, check loaded drivers
lsmod | grep wireless
lsmod | grep cfg80211

# Some adapters need firmware
apt-get update && apt-get install firmware-atheros firmware-realtek

# Realtek 8812AU may need manual driver
# This is already included in Kali, but if issues persist:
apt-get install realtek-rtl88xxau-dkms
```

### USB 3.0 Considerations

USB 3.0 adapters in USB 3.0 ports can cause interference on 2.4GHz band:

```bash
# If experiencing 2.4GHz issues, try:
# 1. Use a USB 2.0 port or hub
# 2. Use a USB extension cable to move adapter away from port
# 3. Use 5GHz band if available
```

### Multiple Adapters Setup

Use multiple adapters for simultaneous operations:

```bash
# List all wireless interfaces
iw dev

# Put both in monitor mode
airmon-ng start wlan0
airmon-ng start wlan1

# Use one for monitoring, one for injection
# Terminal 1: Monitor
airodump-ng wlan0mon

# Terminal 2: Deauth attack
aireplay-ng -0 5 -a <BSSID> wlan1mon
```

## Stopping the Container

```bash
# Stop but keep container
docker-compose stop

# Stop and remove container
docker-compose down

# Stop and remove container + volumes
docker-compose down -v
```

## Troubleshooting

### Wireless Interface Not Visible
```bash
# Check if running in privileged mode
docker inspect kali-wireless | grep Privileged

# Verify host networking
docker inspect kali-wireless | grep NetworkMode
```

### Airmon-ng Issues
```bash
# Kill interfering processes
airmon-ng check kill

# Manually bring interface down
ip link set wlan0 down

# Set monitor mode manually
iw dev wlan0 set type monitor
ip link set wlan0 up
```

### Permission Issues
Ensure the container is running with `--privileged` flag and proper capabilities.

## Customization

To add more tools, edit the Dockerfile:
```dockerfile
RUN apt-get update && apt-get install -y \
    your-additional-tool
```

Then rebuild:
```bash
docker-compose build --no-cache
```
