FROM kalilinux/kali-rolling:latest

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install only essential wireless tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    # Core wireless tools
    aircrack-ng \
    reaver \
    bully \
    wifite \
    kismet \
    kismet-plugins \
    hostapd-wpe \
    asleap \
    mdk4 \
    hcxdumptool \
    hcxtools \
    # Additional utilities
    macchanger \
    wireless-tools \
    iw \
    net-tools \
    iproute2 \
    # Cracking support
    hashcat \
    hashcat-utils \
    # Packet analysis
    tshark \
    tcpdump \
    # Useful additions
    nano \
    tmux \
    wget \
    curl && \
    # Clean up to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create working directory
WORKDIR /root/wireless

# Set up volume mount points
VOLUME ["/root/wireless/captures", "/root/wireless/wordlists"]

# Default command
CMD ["/bin/bash"]
