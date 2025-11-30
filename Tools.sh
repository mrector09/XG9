#!/bin/bash

echo "[+] Updating system..."
sudo pacman -Syyu --noconfirm

echo "[+] Installing required dependencies..."
sudo pacman -S --noconfirm curl base-devel git

echo "[+] Checking if BlackArch is installed..."
if ! grep -q "\[blackarch\]" /etc/pacman.conf; then
    echo "[+] Adding BlackArch repository..."
    curl -O https://blackarch.org/strap.sh
    chmod +x strap.sh
    sudo ./strap.sh
    sudo pacman -Syyu --noconfirm
else
    echo "[+] BlackArch repository already installed!"
fi

echo "[+] Installing Lightweight Hacker Essentials Toolkit..."
sudo pacman -S --noconfirm \
nmap wireshark-cli aircrack-ng wifite hydra hashcat john \
gobuster sqlmap amass subfinder proxychains-ng nuclei whatweb \
xf86-video-intel

echo "[+] Finished installing core tools!"

echo "[+] Optional recommended extras installed? No."
echo "[+] To add OSINT, WiFi extras, or brute force kits, run:"
echo "    sudo pacman -S mdk4 hcxtools sherlock feroxbuster dirsearch"

echo ""
echo "[+] INSTALL COMPLETE!"
echo "[+] You now have a clean <1GB pentest environment."
echo "[+] Launch tools with commands like: nmap, sqlmap, gobuster, aircrack-ng"
echo ""
