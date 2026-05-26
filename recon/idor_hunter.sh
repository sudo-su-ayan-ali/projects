#!/bin/bash

# ==============================================================================
# IDOR Hunter
# Automated tool for discovering potential IDOR endpoints and parameters.
# ==============================================================================

# Terminal Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
DOMAIN=""
WORDLIST=""
OUT_DIR="idor_results_$(date +%s)"
PAYLOAD="FUZZ_IDOR"
IDOR_PARAMS="id|user|account|number|order|doc|profile|uuid|key|email|uuid|userid"

# Helper Functions
print_info() { echo -e "${BLUE}[*] $1${NC}"; }
print_success() { echo -e "${GREEN}[+] $1${NC}"; }
print_error() { echo -e "${RED}[!] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[!] $1${NC}"; }

usage() {
    echo -e "${YELLOW}IDOR Hunter - Automated IDOR Parameter & Endpoint Discovery${NC}"
    echo -e "Usage: $0 -d <domain> [-w <fuzz_wordlist>] [-o <output_dir>] [-p <payload>]"
    echo -e "  -d  Target domain (e.g., example.com)"
    echo -e "  -w  Wordlist for parameter fuzzing (Optional but recommended)"
    echo -e "  -o  Output directory (Default: idor_results_<timestamp>)"
    echo -e "  -p  Payload for qsreplace (Default: FUZZ_IDOR)"
    echo -e "  -h  Show this help message"
    exit 1
}

# Parse Arguments
while getopts "d:w:o:p:h" opt; do
    case "$opt" in
        d) DOMAIN="$OPTARG" ;;
        w) WORDLIST="$OPTARG" ;;
        o) OUT_DIR="$OPTARG" ;;
        p) PAYLOAD="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [ -z "$DOMAIN" ]; then
    print_error "Target domain is required!"
    usage
fi

# ==============================================================================
# 1. Initialization & Dependency Check
# ==============================================================================
install_prerequisites() {
    local req=$1
    if [[ "$req" == "go" ]] && ! command -v go &> /dev/null; then
        print_warning "Go is not installed, which is required to install this tool."
        read -p "Do you want to install golang? (Requires sudo) (y/n): " choice </dev/tty
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y golang
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y golang
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm go
            else
                print_error "Unsupported package manager. Please install Go manually."
            fi
        fi
    fi
    
    if [[ "$req" == "pip3" ]] && ! command -v pip3 &> /dev/null; then
        print_warning "pip3 is not installed, which is required to install this tool."
        read -p "Do you want to install python3-pip? (Requires sudo) (y/n): " choice </dev/tty
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y python3-pip
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y python3-pip
            elif command -v pacman &> /dev/null; then
                sudo pacman -S --noconfirm python-pip
            else
                print_error "Unsupported package manager. Please install pip3 manually."
            fi
        fi
    fi
}

install_tool() {
    local tool=$1
    read -p "Do you want to attempt to install $tool? (y/n): " choice </dev/tty
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        print_info "Attempting to install $tool..."
        case $tool in
            gau)
                install_prerequisites "go"
                if command -v go &> /dev/null; then
                    go install github.com/lc/gau/v2/cmd/gau@latest
                else
                    print_error "Go is still not installed. Cannot install gau."
                fi
                ;;
            waybackurls)
                install_prerequisites "go"
                if command -v go &> /dev/null; then
                    go install github.com/tomnomnom/waybackurls@latest
                else
                    print_error "Go is still not installed. Cannot install waybackurls."
                fi
                ;;
            katana)
                install_prerequisites "go"
                if command -v go &> /dev/null; then
                    go install github.com/projectdiscovery/katana/cmd/katana@latest
                else
                    print_error "Go is still not installed. Cannot install katana."
                fi
                ;;
            qsreplace)
                install_prerequisites "go"
                if command -v go &> /dev/null; then
                    go install github.com/tomnomnom/qsreplace@latest
                else
                    print_error "Go is still not installed. Cannot install qsreplace."
                fi
                ;;
            ffuf)
                install_prerequisites "go"
                if command -v go &> /dev/null; then
                    go install github.com/ffuf/ffuf/v2@latest
                else
                    print_error "Go is still not installed. Cannot install ffuf."
                fi
                ;;
            uro)
                install_prerequisites "pip3"
                if command -v pip3 &> /dev/null; then
                    pip3 install uro --break-system-packages 2>/dev/null || pip3 install uro
                else
                    print_error "pip3 is still not installed. Cannot install uro."
                fi
                ;;
            *)
                print_error "Automated installation for $tool is not supported. Please install it manually."
                ;;
        esac
        # check again
        if ! command -v "$tool" &> /dev/null; then
             print_warning "Installation attempted. If it succeeded, $tool might not be in your PATH."
        else
             print_success "$tool installed successfully."
        fi
    else
        print_error "Skipping installation of $tool."
    fi
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    # Export paths temporarily in case things were installed previously but aren't in path
    export PATH=$PATH:$HOME/go/bin:$HOME/.local/bin
    
    if command -v gau &> /dev/null; then
        ARCHIVE_TOOL="gau"
    elif command -v waybackurls &> /dev/null; then
        ARCHIVE_TOOL="waybackurls"
    else
        print_error "Neither 'gau' nor 'waybackurls' is installed."
        install_tool "gau"
        if command -v gau &> /dev/null; then
            ARCHIVE_TOOL="gau"
        else
            print_error "Failed to resolve archive tool dependency. Exiting."
            exit 1
        fi
    fi

    local tools=("katana" "uro" "qsreplace" "curl" "grep" "awk")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            print_error "$tool is missing!"
            if [[ "$tool" == "katana" || "$tool" == "uro" || "$tool" == "qsreplace" ]]; then
                 install_tool "$tool"
                 if ! command -v "$tool" &> /dev/null; then
                     print_error "Required dependency $tool is missing. Exiting."
                     exit 1
                 fi
            else
                 print_error "Please install $tool manually."
                 exit 1
            fi
        fi
    done

    if [ -n "$WORDLIST" ]; then
        if ! command -v ffuf &> /dev/null; then
             print_warning "ffuf is missing! Parameter fuzzing will be skipped."
             install_tool "ffuf"
             if ! command -v ffuf &> /dev/null; then
                 print_warning "ffuf still missing, fuzzing will be skipped."
             fi
        fi
    fi

    print_success "All dependencies satisfied."
}

# ==============================================================================
# 2. Reconnaissance & Endpoint Discovery
# ==============================================================================
run_recon() {
    print_info "Starting Reconnaissance on $DOMAIN..."
    
    # Passive Discovery
    print_info "Fetching archive URLs using $ARCHIVE_TOOL..."
    if [ "$ARCHIVE_TOOL" == "gau" ]; then
        echo "$DOMAIN" | gau --subs > "$OUT_DIR/archive_urls.txt"
    else
        echo "$DOMAIN" | waybackurls > "$OUT_DIR/archive_urls.txt"
    fi
    
    # Active Discovery
    print_info "Crawling live endpoints with katana..."
    katana -u "https://$DOMAIN" -silent -jc -kf all -d 3 > "$OUT_DIR/katana_urls.txt"

    # Aggregation and Deduplication
    print_info "Aggregating and deduplicating URLs with uro..."
    cat "$OUT_DIR/archive_urls.txt" "$OUT_DIR/katana_urls.txt" 2>/dev/null | uro > "$OUT_DIR/all_unique_urls.txt"
    
    print_success "Recon completed. Total unique URLs found: $(wc -l < "$OUT_DIR/all_unique_urls.txt")"
}

# ==============================================================================
# 3. JavaScript Analysis
# ==============================================================================
analyze_js() {
    print_info "Starting JavaScript Analysis for hidden endpoints and parameters..."
    
    grep -iE "\.js$" "$OUT_DIR/all_unique_urls.txt" > "$OUT_DIR/js_files.txt"
    local js_count=$(wc -l < "$OUT_DIR/js_files.txt")
    
    if [ "$js_count" -eq 0 ]; then
        print_warning "No JS files found to analyze."
        return
    fi
    
    print_info "Downloading and parsing $js_count JS files..."
    
    # Extract paths/endpoints from JS using grep (finding relative paths like /api/v1/user)
    # and extract parameter names (like ?user_id=)
    mkdir -p "$OUT_DIR/js_downloads"
    while read -r url; do
        curl -s -k -m 10 "$url" | grep -a -oE "(/[a-zA-Z0-9_.-]+)+/?" >> "$OUT_DIR/js_hidden_paths.txt"
        curl -s -k -m 10 "$url" | grep -a -oE "\?[a-zA-Z0-9_.-]+=" >> "$OUT_DIR/js_params.txt"
    done < "$OUT_DIR/js_files.txt"

    if [ -f "$OUT_DIR/js_hidden_paths.txt" ]; then
        sort -u "$OUT_DIR/js_hidden_paths.txt" > "$OUT_DIR/js_hidden_paths_clean.txt"
        print_success "Extracted $(wc -l < "$OUT_DIR/js_hidden_paths_clean.txt") potential hidden paths from JS."
    fi
}

# ==============================================================================
# 4. Parameter Extraction & IDOR Filtering
# ==============================================================================
extract_parameters() {
    print_info "Extracting URLs with parameters and filtering for IDOR candidates..."
    
    # Extract URLs that have query parameters
    grep "=" "$OUT_DIR/all_unique_urls.txt" > "$OUT_DIR/param_urls.txt"
    
    # Filter for IDOR specific keywords
    grep -iE "($IDOR_PARAMS)=" "$OUT_DIR/param_urls.txt" > "$OUT_DIR/idor_candidates.txt"
    
    print_success "Found $(wc -l < "$OUT_DIR/idor_candidates.txt") URLs with high-potential IDOR parameters."
}

# ==============================================================================
# 5. Parameter Fuzzing (Active Discovery)
# ==============================================================================
fuzz_parameters() {
    if [ -z "$WORDLIST" ]; then
        print_warning "No wordlist provided (-w). Skipping parameter fuzzing."
        return
    fi

    if ! command -v ffuf &> /dev/null; then
        print_warning "ffuf is not installed. Skipping parameter fuzzing."
        return
    fi

    print_info "Starting Parameter Fuzzing for hidden IDOR parameters..."
    
    # Create a list of clean base endpoints (without parameters)
    awk -F"?" '{print $1}' "$OUT_DIR/all_unique_urls.txt" | sort -u > "$OUT_DIR/base_endpoints.txt"
    
    # Randomly sample a few endpoints to fuzz (to avoid sending too many requests blindly in a bash script)
    # For a real tool, maybe fuzz all, but here we limit to top 20 interesting ones
    head -n 20 "$OUT_DIR/base_endpoints.txt" > "$OUT_DIR/fuzz_targets.txt"
    
    print_info "Fuzzing a sample of $(wc -l < "$OUT_DIR/fuzz_targets.txt") endpoints..."
    while read -r endpoint; do
        # Simple ffuf run checking for parameters that change response length or status
        ffuf -w "$WORDLIST" -u "${endpoint}?FUZZ=1" -mc 200,301,302 -ac -s -o "$OUT_DIR/ffuf_results.json" 2>/dev/null
    done < "$OUT_DIR/fuzz_targets.txt"
    
    print_success "Fuzzing complete. Check $OUT_DIR/ffuf_results.json for details."
}

# ==============================================================================
# 6. Payload Generation
# ==============================================================================
generate_payloads() {
    print_info "Generating ready-to-test payloads..."
    
    if [ ! -s "$OUT_DIR/idor_candidates.txt" ]; then
        print_warning "No IDOR candidates found. Skipping payload generation."
        return
    fi

    # Replace parameter values with the target payload using qsreplace
    cat "$OUT_DIR/idor_candidates.txt" | qsreplace "$PAYLOAD" > "$OUT_DIR/ready_to_test_payloads.txt"
    
    print_success "Generated $(wc -l < "$OUT_DIR/ready_to_test_payloads.txt") payload URLs in $OUT_DIR/ready_to_test_payloads.txt"
}

# ==============================================================================
# Main Execution Flow
# ==============================================================================
main() {
    mkdir -p "$OUT_DIR"
    print_info "Output directory created: $OUT_DIR"
    
    check_dependencies
    run_recon
    analyze_js
    extract_parameters
    fuzz_parameters
    generate_payloads
    
    print_success "IDOR Hunter has finished! All results are saved in $OUT_DIR"
}

main
