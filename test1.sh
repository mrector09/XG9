#!/usr/bin/env bash
set -euo pipefail

# ---------- config ----------
ROOT="$HOME/Tools"
RECON="$ROOT/Recon"
WEB="$ROOT/Web"
WIRELESS="$ROOT/Wireless"
EXPLOIT="$ROOT/Exploit"
WORDLISTS="$ROOT/Wordlists"
SCRIPTS="$ROOT/Scripts"

# Arch packages (lean, widely useful, no bloat)
PACMAN_PKGS=(
  git base-devel jq curl wget
  go
  python-pipx
  # Core tooling
  nmap sqlmap gobuster
  amass
  subfinder httpx naabu
  ffuf
  wifite hcxdumptool hcxtools aircrack-ng
  seclists
)

# Python tools to install with pipx (isolated envs)
PIPX_PKGS=(
  "arjun"
  "xsstrike"
  "photon"
)

# Git repos to clone (dir => url)
# Recon
declare -A GITS_RECON=(
  ["assetfinder"]="https://github.com/tomnomnom/assetfinder"
  ["Amass"]="https://github.com/OWASP/Amass"
  ["httpx"]="https://github.com/projectdiscovery/httpx"
  ["naabu"]="https://github.com/projectdiscovery/naabu"
  ["subfinder"]="https://github.com/projectdiscovery/subfinder"
)

# Web
declare -A GITS_WEB=(
  ["ffuf"]="https://github.com/ffuf/ffuf"
  ["Photon"]="https://github.com/s0md3v/Photon"
  ["Arjun"]="https://github.com/s0md3v/Arjun"
  ["XSStrike"]="https://github.com/s0md3v/XSStrike"
  ["sqlmap-site-packages"]="https://github.com/tennc/sqlmap-site-packages"
)

# Wireless
declare -A GITS_WIRELESS=(
  ["wifite2"]="https://github.com/derv82/wifite2"
  ["hcxdumptool"]="https://github.com/ZerBea/hcxdumptool"
  ["hcxtools"]="https://github.com/ZerBea/hcxtools"
)

# Exploit / privesc / payloads
declare -A GITS_EXPLOIT=(
  ["PEASS-ng"]="https://github.com/peass-ng/PEASS-ng"
  ["PayloadsAllTheThings"]="https://github.com/swisskyrepo/PayloadsAllTheThings"
  ["exploitdb"]="https://github.com/offensive-security/exploitdb"
  ["shellcode-rust"]="https://github.com/t3l3machus/shellcode-rust"
)

# Wordlists (extra beyond seclists package)
declare -A GITS_WORDLISTS=(
  ["probable-wordlists"]="https://github.com/legacy-wd/probable-wordlists"
)

# Misc scripts
declare -A GITS_SCRIPTS=(
  ["nmap-scripts"]="https://github.com/superc03/nmap-scripts"
  ["jwt_tool"]="https://github.com/ticarpi/jwt_tool"
  ["Reverse-Shell-Handler"]="https://github.com/brianlam38/Reverse-Shell-Handler"
)

# ---------- helpers ----------
msg(){ printf "\n\033[1;32m[+] %s\033[0m\n" "$*"; }
warn(){ printf "\n\033[1;33m[!] %s\033[0m\n" "$*"; }
err(){ printf "\n\033[1;31m[-] %s\033[0m\n" "$*"; exit 1; }

ensure_dir(){ mkdir -p "$1"; }

clone_or_update(){
  local dest="$1" url="$2"
  if [[ -d "$dest/.git" ]]; then
    (cd "$dest" && git pull --ff-only >/dev/null) || warn "Update failed: $dest"
  else
    git clone --depth 1 "$url" "$dest" >/dev/null || warn "Clone failed: $url"
  fi
}

install_pacman(){
  msg "Syncing pacman and installing core packages"
  sudo pacman -Syu --needed --noconfirm "${PACMAN_PKGS[@]}"
}

install_pipx(){
  msg "Installing python tools via pipx"
  # ensure pipx path is active for current shell
  python -m pipx ensurepath >/dev/null 2>&1 || true
  for pkg in "${PIPX_PKGS[@]}"; do
    pipx install "$pkg" >/dev/null 2>&1 || pipx upgrade "$pkg" >/dev/null 2>&1 || true
  done
}

clone_category(){
  local base="$1"; shift
  declare -n MAP="$1"
  ensure_dir "$base"
  for name in "${!MAP[@]}"; do
    clone_or_update "$base/$name" "${MAP[$name]}"
  done
}

# ---------- run ----------
msg "Creating clean toolkit directories at $ROOT"
ensure_dir "$RECON" "$WEB" "$WIRELESS" "$EXPLOIT" "$WORDLISTS" "$SCRIPTS"

install_pacman
install_pipx

msg "Cloning Recon repos"
clone_category "$RECON" GITS_RECON

msg "Cloning Web repos"
clone_category "$WEB" GITS_WEB

msg "Cloning Wireless repos"
clone_category "$WIRELESS" GITS_WIRELESS

msg "Cloning Exploit repos"
clone_category "$EXPLOIT" GITS_EXPLOIT

msg "Cloning Wordlist repos"
clone_category "$WORDLISTS" GITS_WORDLISTS

msg "Cloning Misc Scripts"
clone_category "$SCRIPTS" GITS_SCRIPTS

# create a simple updater
UPD="$ROOT/update-tools.sh"
cat > "$UPD" <<'EOF'
#!/usr/bin/env bash
set -e
ROOT="$HOME/Tools"
printf "\n[+] Updating pacman packages...\n"
sudo pacman -Syu --noconfirm
printf "\n[+] Upgrading pipx packages...\n"
pipx upgrade-all || true
printf "\n[+] git pulling every repo under $ROOT...\n"
find "$ROOT" -type d -name ".git" -prune -print0 | \
  xargs -0 -I{} bash -c 'cd "$(dirname "{}")" && git pull --ff-only || true'
echo "[+] Done."
EOF
chmod +x "$UPD"

msg "All set!  Your tools live in $ROOT"
echo "Run:  $ROOT/update-tools.sh  to refresh everything later."
