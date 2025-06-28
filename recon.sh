#!/bin/bash

# =============================
# 🔍 Subdomain Recon Automation
# =============================

# Local output directory (not root/home)
WORKDIR="./recon_output"
mkdir -p "$WORKDIR"

# Ask user for inputs
read -p "Enter target domain (e.g. example.com): " domain
read -p "Enter output filename for live subdomains (e.g. live.txt): " outFile

if [[ -z "$domain" || -z "$outFile" ]]; then
  echo "[!] Both domain and output filename are required."
  exit 1
fi

# Helper to install missing tools
install_if_missing() {
  if ! command -v "$1" &>/dev/null; then
    echo "[*] Installing $1..."
    case "$OSTYPE" in
      linux-android*) pkg install -y "$2" ;;
      linux*) sudo apt install -y "$2" ;;
    esac
  else
    echo "[✔] $1 already installed."
  fi
}

# System dependencies
install_if_missing git git
install_if_missing python3 python3
install_if_missing pip pip
install_if_missing go golang

# Add Go to PATH
export PATH=$PATH:$(go env GOPATH)/bin

# Go-based tools
if ! command -v subfinder &>/dev/null; then
  go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
fi
if ! command -v assetfinder &>/dev/null; then
  go install -v github.com/tomnomnom/assetfinder@latest
fi
if ! command -v httpx &>/dev/null; then
  go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
fi

# Sublist3r setup
if [ ! -d "$WORKDIR/Sublist3r" ]; then
  git clone https://github.com/aboul3la/Sublist3r.git "$WORKDIR/Sublist3r"
  pip install -r "$WORKDIR/Sublist3r/requirements.txt"

  # FIX: Clean regex escape warnings
  sed -i "s/<cite.*?>\(.*?\)<\\/cite>/r'<cite.*?>(.*?)<\/cite>'/g" "$WORKDIR/Sublist3r/sublist3r.py"
fi

# ===========================
# Start Subdomain Enumeration
# ===========================

subfinder -d "$domain" -silent > "$WORKDIR/subfinder.txt"
assetfinder --subs-only "$domain" > "$WORKDIR/assetfinder.txt"
python3 "$WORKDIR/Sublist3r/sublist3r.py" -d "$domain" -o "$WORKDIR/sublister.txt" > /dev/null

# Merge and dedupe results
cat "$WORKDIR/"*.txt | sort -u > "$WORKDIR/all_subdomains.txt"

# Check for live subdomains
httpx -l "$WORKDIR/all_subdomains.txt" -silent -threads 100 -status-code -title > "$WORKDIR/httpx_results.txt"
cut -d ' ' -f1 "$WORKDIR/httpx_results.txt" > "$WORKDIR/$outFile"

# =====================
# Done - Print Summary
# =====================
echo "[✔] Recon complete."
echo "[📁] Output directory: $WORKDIR"
echo "[🌐] Total subdomains found: $(wc -l < "$WORKDIR/all_subdomains.txt")"
echo "[✅] Live subdomains saved to: $WORKDIR/$outFile"
