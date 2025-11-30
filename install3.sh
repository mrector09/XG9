#!/usr/bin/env bash
set -euo pipefail

shopt -s extglob

# --------- REQUIREMENTS ----------
if ! command -v whiptail >/dev/null 2>&1; then
  echo "[*] Installing whiptail (libnewt)..."
  sudo pacman -Sy --needed --noconfirm libnewt
fi

sudo pacman -Sy --needed --noconfirm curl git

# --------- ENSURE BLACKARCH ---------
if ! grep -qi '^\[blackarch\]' /etc/pacman.conf; then
  echo "[*] Adding BlackArch repo…"
  curl -fsSL https://blackarch.org/strap.sh | sudo bash
fi

# --------- CATEGORY CHECK ----------
cat_exists() {
  pacman -Sg | awk '{print $1}' | grep -qx "$1"
}

# --------- GROUP DEFINITIONS ----------
declare -A GROUPS=(
  [1]="blackarch-recon blackarch-osint"
  [2]="blackarch-scanner blackarch-fuzzer"
  [3]="blackarch-webapp"
  [4]="blackarch-wireless blackarch-bluetooth"
  [5]="blackarch-exploitation blackarch-social"
  [6]="blackarch-networking blackarch-sniffer"
  [7]="blackarch-cracker blackarch-crypto"
  [8]="blackarch-forensic blackarch-malware"
  [9]="blackarch-reversing"
  [10]="blackarch-automation blackarch-defensive blackarch-misc"
)

# --------- TUI MENU ----------
OPTIONS=(
  1 "Recon + OSINT" OFF
  2 "Scanners + Fuzzers" OFF
  3 "Webapp Testing" OFF
  4 "Wireless / Bluetooth" OFF
  5 "Exploitation + Social" OFF
  6 "Networking / Sniffers" OFF
  7 "Cracking + Crypto" OFF
  8 "Forensics + Malware" OFF
  9 "Reversing" OFF
  10 "Automation / Misc" OFF
)

SEL=$(whiptail --title "BlackArch Installer" \
  --checklist "Select groups to install (space = select)" \
  20 80 12 \
  "${OPTIONS[@]}" \
  3>&1 1>&2 2>&3) || { echo "Canceled."; exit 0; }

# --------- BUILD SAFE INSTALL LIST ----------
to_install=()

for raw in $SEL; do
  tag="${raw//\"/}"   # remove quotes

  # VALIDATE TAG
  if [[ ! "$tag" =~ ^(1|2|3|4|5|6|7|8|9|10)$ ]]; then
    echo "[i] Ignoring invalid selection: $tag"
    continue
  fi

  for c in ${GROUPS[$tag]}; do
    if cat_exists "$c"; then
      to_install+=("$c")
    else
      echo "[i] Skipping missing category: $c"
    fi
  done
done

# Deduplicate
readarray -t to_install < <(printf "%s\n" "${to_install[@]}" | sort -u)

if [[ ${#to_install[@]} -eq 0 ]]; then
  echo "No valid categories selected."
  exit 0
fi

echo "Installing:"
printf " - %s\n" "${to_install[@]}"

sudo pacman -S --needed "${to_install[@]}"

echo "✔ DONE"
