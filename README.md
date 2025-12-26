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

### Legal Notice
⚠️ **WARNING**: These tools are for authorized security testing only. Unauthorized access to computer networks is illegal. Always obtain proper authorization before conducting wireless assessments.

### Performance Tips
1. **GPU Cracking**: Use hashcat on the host system for GPU acceleration
2. **USB Adapters**: Use `--device=/dev/bus/usb` to pass through USB devices
3. **Wordlists**: Mount your wordlist directory for easy access

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
