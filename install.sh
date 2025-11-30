#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# BlackArch TUI Group Installer
# -----------------------------
# Presents 10 numbered sections. Each section maps to several BlackArch
# categories. We verify categories exist on your system before installing.
# Requires: sudo, pacman, curl, git, whiptail (libnewt)
# -----------------------------

need() { command -v "$1" >/dev/null 2>&1; }

# 0) Basics
if ! need sudo; then echo "[!] sudo is required"; exit 1; fi
sudo pacman -Sy --needed --noconfirm curl git libnewt >/dev/null

# 1) Ensure BlackArch repo
if ! grep -qi '^\[blackarch\]' /etc/pacman.conf; then
  echo "[*] Adding BlackArch repo…"
  curl -fsSL https://blackarch.org/strap.sh | sudo bash
fi

# helper: does category exist?
cat_exists() {
  local c="$1"
  pacman -Sg 2>/dev/null | awk '{print $1}' | grep -qx "$c"
}

# Define 10 friendly groups (use only categories that actually exist)
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

# Build whiptail checklist
TITLE="BlackArch Group Installer"
DESC="Select the groups (1–10) you want. Use <Space> to toggle, <Tab> to switch buttons."
OPTIONS=()
for i in {1..10}; do
  # a short description for each line
  case "$i" in
    1) d="Recon + OSINT";;
    2) d="Scanners + Fuzzers";;
    3) d="Web App testing";;
    4) d="Wireless / Bluetooth";;
    5) d="Exploitation + Social";;
    6) d="Networking / Sniffers";;
    7) d="Cracking + Crypto";;
    8) d="Forensics + Malware";;
    9) d="Reversing";;
    10) d="Automation / Defensive / Misc";;
  esac
  OPTIONS+=("$i" "$d" "OFF")
done

SEL=$(whiptail --title "$TITLE" --checklist "$DESC" 20 80 12 \
  "${OPTIONS[@]}" 3>&1 1>&2 2>&3) || { echo "Canceled."; exit 0; }

# Parse selection -> categories list, but keep only those that exist
to_install=()
for tag in $SEL; do
  tag="${tag//\"/}"          # remove quotes whiptail adds
  for c in ${GROUPS[$tag]}; do
    if cat_exists "$c"; then
      to_install+=("$c")
    else
      echo "[i] Skipping missing category: $c"
    fi
  done
done

# De-duplicate
readarray -t to_install < <(printf "%s\n" "${to_install[@]}" | sort -u)

if [ ${#to_install[@]} -eq 0 ]; then
  echo "No valid categories selected. Bye."
  exit 0
fi

echo "You chose categories:"
printf '  - %s\n' "${to_install[@]}"
echo
read -rp "Proceed with install? [y/N] " go
[[ "$go" =~ ^[Yy]$ ]] || exit 0

# Install
sudo pacman -S --needed "${to_install[@]}"

echo
echo "✅ Done."
echo "Tip: many tools install to /usr/bin. Try:  locate -b '\\<nmap\\>'  (after installing mlocate)"
