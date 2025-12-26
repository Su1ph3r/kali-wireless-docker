#!/bin/bash

# Wireless Assessment Helper Script
# Quick access to common wireless testing workflows

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_banner() {
    echo -e "${GREEN}"
    echo "======================================"
    echo "  Kali Wireless Assessment Helper"
    echo "======================================"
    echo -e "${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] This script must be run as root${NC}"
        exit 1
    fi
}

list_interfaces() {
    echo -e "${YELLOW}[*] Available wireless interfaces:${NC}"
    iwconfig 2>&1 | grep -E "^[a-z]" | cut -d' ' -f1
    echo ""
}

enable_monitor_mode() {
    list_interfaces
    echo -e "${YELLOW}[?] Enter interface name (e.g., wlan0):${NC}"
    read -r iface
    
    if [[ -z "$iface" ]]; then
        echo -e "${RED}[!] No interface specified${NC}"
        return
    fi
    
    echo -e "${GREEN}[+] Killing interfering processes...${NC}"
    airmon-ng check kill
    
    echo -e "${GREEN}[+] Enabling monitor mode on $iface...${NC}"
    airmon-ng start "$iface"
    
    echo -e "${GREEN}[+] Monitor mode enabled!${NC}"
    iwconfig 2>&1 | grep -E "Mode:Monitor"
}

disable_monitor_mode() {
    list_interfaces
    echo -e "${YELLOW}[?] Enter monitor interface name (e.g., wlan0mon):${NC}"
    read -r iface
    
    if [[ -z "$iface" ]]; then
        echo -e "${RED}[!] No interface specified${NC}"
        return
    fi
    
    echo -e "${GREEN}[+] Disabling monitor mode on $iface...${NC}"
    airmon-ng stop "$iface"
    
    echo -e "${GREEN}[+] Restarting NetworkManager...${NC}"
    systemctl restart NetworkManager 2>/dev/null || service network-manager restart 2>/dev/null
}

scan_networks() {
    list_interfaces
    echo -e "${YELLOW}[?] Enter monitor interface name (e.g., wlan0mon):${NC}"
    read -r iface
    
    if [[ -z "$iface" ]]; then
        echo -e "${RED}[!] No interface specified${NC}"
        return
    fi
    
    echo -e "${GREEN}[+] Scanning networks on $iface...${NC}"
    echo -e "${YELLOW}[*] Press Ctrl+C to stop scanning${NC}"
    airodump-ng "$iface"
}

capture_handshake() {
    echo -e "${YELLOW}[?] Enter monitor interface (e.g., wlan0mon):${NC}"
    read -r iface
    echo -e "${YELLOW}[?] Enter target BSSID (e.g., AA:BB:CC:DD:EE:FF):${NC}"
    read -r bssid
    echo -e "${YELLOW}[?] Enter channel number:${NC}"
    read -r channel
    echo -e "${YELLOW}[?] Enter output filename (without extension):${NC}"
    read -r filename
    
    if [[ -z "$iface" ]] || [[ -z "$bssid" ]] || [[ -z "$channel" ]] || [[ -z "$filename" ]]; then
        echo -e "${RED}[!] Missing required information${NC}"
        return
    fi
    
    output_path="/root/wireless/captures/$filename"
    
    echo -e "${GREEN}[+] Starting capture...${NC}"
    echo -e "${YELLOW}[*] Capture will be saved to: $output_path${NC}"
    echo -e "${YELLOW}[*] Press Ctrl+C to stop capture${NC}"
    
    airodump-ng -c "$channel" --bssid "$bssid" -w "$output_path" "$iface"
}

run_wifite() {
    echo -e "${GREEN}[+] Starting Wifite automated attack...${NC}"
    echo -e "${YELLOW}[?] Use wordlist? (y/n):${NC}"
    read -r use_wordlist
    
    if [[ "$use_wordlist" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[?] Enter wordlist path (e.g., /root/wireless/wordlists/rockyou.txt):${NC}"
        read -r wordlist
        if [[ -f "$wordlist" ]]; then
            wifite --kill --dict "$wordlist"
        else
            echo -e "${RED}[!] Wordlist not found${NC}"
        fi
    else
        wifite --kill
    fi
}

convert_to_hashcat() {
    echo -e "${YELLOW}[?] Enter capture file path (e.g., /root/wireless/captures/capture-01.cap):${NC}"
    read -r capfile
    
    if [[ ! -f "$capfile" ]]; then
        echo -e "${RED}[!] Capture file not found${NC}"
        return
    fi
    
    output_file="${capfile%.cap}.hc22000"
    
    echo -e "${GREEN}[+] Converting to hashcat format...${NC}"
    hcxpcapngtool -o "$output_file" "$capfile"
    
    if [[ -f "$output_file" ]]; then
        echo -e "${GREEN}[+] Conversion complete: $output_file${NC}"
        echo -e "${YELLOW}[*] Use this file with hashcat:${NC}"
        echo -e "    hashcat -m 22000 $output_file wordlist.txt"
    fi
}

change_mac() {
    list_interfaces
    echo -e "${YELLOW}[?] Enter interface name:${NC}"
    read -r iface
    
    echo -e "${YELLOW}[?] Random MAC (r) or specify (s)?${NC}"
    read -r choice
    
    echo -e "${GREEN}[+] Bringing interface down...${NC}"
    ip link set "$iface" down
    
    if [[ "$choice" == "r" ]]; then
        echo -e "${GREEN}[+] Setting random MAC address...${NC}"
        macchanger -r "$iface"
    else
        echo -e "${YELLOW}[?] Enter new MAC address (e.g., AA:BB:CC:DD:EE:FF):${NC}"
        read -r mac
        echo -e "${GREEN}[+] Setting MAC to $mac...${NC}"
        macchanger -m "$mac" "$iface"
    fi
    
    echo -e "${GREEN}[+] Bringing interface up...${NC}"
    ip link set "$iface" up
}

show_menu() {
    echo ""
    echo -e "${YELLOW}Choose an option:${NC}"
    echo "1. List wireless interfaces"
    echo "2. Enable monitor mode"
    echo "3. Disable monitor mode"
    echo "4. Scan for networks"
    echo "5. Capture handshake"
    echo "6. Run Wifite (automated)"
    echo "7. Convert capture to hashcat format"
    echo "8. Change MAC address"
    echo "9. Exit"
    echo ""
    echo -e "${YELLOW}Enter choice [1-9]:${NC}"
}

main() {
    check_root
    show_banner
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1) list_interfaces ;;
            2) enable_monitor_mode ;;
            3) disable_monitor_mode ;;
            4) scan_networks ;;
            5) capture_handshake ;;
            6) run_wifite ;;
            7) convert_to_hashcat ;;
            8) change_mac ;;
            9) echo -e "${GREEN}[+] Exiting...${NC}"; exit 0 ;;
            *) echo -e "${RED}[!] Invalid choice${NC}" ;;
        esac
        
        echo ""
        echo -e "${YELLOW}Press Enter to continue...${NC}"
        read -r
    done
}

main
