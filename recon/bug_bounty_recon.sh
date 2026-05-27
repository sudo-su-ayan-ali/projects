#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
#  RECON AUTOMATION SCRIPT
#  Tools: subfinder, assetfinder, ffuf, dirsearch
#         httpx / httpx-toolkit, aquatone, nmap 
#         seclists wordlists  
# ─────────────────────────────────────────────

# ── Colors ──────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[*]${NC} $*"; }
success() { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[-]${NC} $*"; exit 1; }

# ── Working Directory ────────────────────────
# Always creates a timestamped folder so previous runs are never overwritten
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORKDIR="recon_${TIMESTAMP}"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
success "Working directory created: $WORKDIR"

# ── Distro Selection ─────────────────────────
echo ""
echo "  1) Debian / Ubuntu / Kali"
echo "  2) Arch Linux / BlackArch"
echo ""
read -rp "Select your distro [1/2]: " distro

case "$distro" in
  1)
    read -rp "Install required tools? [1=yes / 2=no]: " install_tools
    if [[ "$install_tools" -eq 1 ]]; then
      info "Installing tools via apt..."
      sudo apt update -y
      sudo apt install -y subfinder assetfinder ffuf dirsearch httpx-toolkit aquatone nmap seclists
      success "Tools installed."
    else
      warn "Skipping tool installation."
    fi
    # on Debian httpx-toolkit installs the binary as 'httpx'
    HTTPX_BIN="httpx"
    ;;
  2)
    read -rp "Install required tools? [1=yes / 2=no]: " install_tools
    if [[ "$install_tools" -eq 1 ]]; then
      info "Installing tools via pacman..."
      sudo pacman -S --noconfirm subfinder assetfinder ffuf dirsearch httpx aquatone nmap seclists
      success "Tools installed."
    else
      warn "Skipping tool installation."
    fi
    HTTPX_BIN="httpx"
    ;;
  *)
    error "Invalid distro choice. Please enter 1 or 2."
    ;;
esac

# ── Check if httpx-pd exists; if yes prefer it ──
# If the user has a custom binary called httpx-pd, this honours it.
# Otherwise falls back to the standard httpx binary confirmed above.
if command -v httpx-pd &>/dev/null; then
  HTTPX_BIN="httpx-pd"
  warn "Found custom binary 'httpx-pd' — using it instead of httpx."
fi

# ── Target Input ─────────────────────────────
echo ""
read -rp "Enter target domain (e.g. example.com): " subdomain

[[ -z "$subdomain" ]] && error "No domain entered. Exiting."

info "Target: $subdomain"

# ── Subdomain Enumeration ────────────────────
info "Running subfinder..."
subfinder -d "$subdomain" -o subfinder.txt || warn "subfinder returned no results."

info "Running assetfinder..."
assetfinder --subs-only "$subdomain" > assetfinder.txt || warn "assetfinder returned no results."

# ── FFUF vhost brute-force ───────────────────
echo ""
#[[ ! -f "$wordlist_for_subdomain_enum" ]] && error "Wordlist not found: $wordlist_for_subdomain_enum"

info "Running ffuf vhost brute-force..."
ffuf \
  -u "http://$subdomain/" \
  -H "Host: FUZZ.$subdomain" \
  -w /usr/share/seclists/Discovery/Web-Content/big.txt \
  -mc 200,301,302,403 \
  -t 40 \
  -of json \
  -o ffuf_vhost.json \
  -s || warn "ffuf returned no results."

# Parse ffuf JSON output safely (no fragile regex on raw text)
if [[ -s ffuf_vhost.json ]]; then
  python3 - <<'EOF' ffuf_vhost.json > all_hosts_from_ffuf.txt
import json, sys

with open(sys.argv[1]) as f:
    data = json.load(f)

seen = set()
for result in data.get("results", []):
    host = result.get("host", "").strip()
    if host and host not in seen:
        seen.add(host)
        print(host)
EOF
  success "ffuf hosts extracted to all_hosts_from_ffuf.txt"
else
  warn "ffuf JSON output is empty. Skipping ffuf host extraction."
  touch all_hosts_from_ffuf.txt
fi

# ── Merge & Deduplicate ──────────────────────
info "Merging all subdomain lists..."
cat subfinder.txt assetfinder.txt all_hosts_from_ffuf.txt 2>/dev/null \
  | sort -u \
  > all_subs.txt
success "Unique subdomains saved to all_subs.txt ($(wc -l < all_subs.txt) entries)"

# ── HTTP Probing ─────────────────────────────
info "Probing live hosts with $HTTPX_BIN..."
"$HTTPX_BIN" \
  -l all_subs.txt \
  -mc 200,301,302,403 \
  -o final_all_subs.txt || warn "$HTTPX_BIN probe returned no live hosts."

success "Live hosts saved to final_all_subs.txt ($(wc -l < final_all_subs.txt 2>/dev/null || echo 0) entries)"

# ── Nmap Port Scan ───────────────────────────
echo ""
echo "  1) Full port scan  (-p-)"
echo "  2) Single port scan"
echo ""
read -rp "Select scan type [1/2]: " scan

mkdir -p nmap_results

case "$scan" in
  1)
    info "Running full port scan on $subdomain ..."
    nmap -Pn -sC -sV -T4 -p- "$subdomain" -vv \
      -oN "nmap_results/nmap_full_scan.txt"
    success "Full scan saved to nmap_results/nmap_full_scan.txt"
    ;;
  2)
    read -rp "Enter port number to scan: " singleportscan
    [[ -z "$singleportscan" ]] && error "No port entered."
    info "Running single port scan ($singleportscan) on $subdomain ..."
    nmap -Pn -sC -sV -p "$singleportscan" "$subdomain" -vv \
      -oN "nmap_results/nmap_port_${singleportscan}.txt"
    success "Single port scan saved to nmap_results/nmap_port_${singleportscan}.txt"
    ;;
  *)
    warn "Invalid choice for scan type. Skipping nmap."
    ;;
esac

# ── Directory Busting ────────────────────────
info "Running dirsearch on all subdomains..."
dirsearch \
  -l all_subs.txt \
  -w /usr/share/seclists/Discovery/Web-Content/big.txt \
  -t 40 \
  -o directory_busting.txt || warn "dirsearch returned no results."

# ── Aquatone Screenshots ─────────────────────
if [[ -s final_all_subs.txt ]]; then
  info "Taking screenshots with aquatone..."
  mkdir -p aquatone_screenshots
  cat final_all_subs.txt | aquatone -out aquatone_screenshots
  success "Screenshots saved to aquatone_screenshots/"
else
  warn "final_all_subs.txt is empty. Skipping aquatone."
fi

# ── Summary ──────────────────────────────────
echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  RECON COMPLETE — $WORKDIR${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "  all_subs.txt          → all discovered subdomains"
echo "  final_all_subs.txt    → live/responding hosts"
echo "  nmap_results/         → port scan output"
echo "  directory_busting.txt → dirsearch results"
echo "  aquatone_screenshots/ → visual screenshots"
echo ""
