#!/bin/bash

# Bug Bounty Automation Script (NEW VERSION)

# Prerequisites:
# - Nmap, Dirb, Whois, Nikto, SQLMap, Nuclei
# - Recon-ng
# - sublist3r (from apt)

# Functions
# ---------

# Banner
function banner() {
  echo "--------------------------------------------------"
  echo "  Bug Bounty Automation Script (TEST 01)"
  echo "--------------------------------------------------"
}

# Help Menu
function help_menu() {
  banner
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -d <domain>   Specify a single target domain to scan"
  echo "  -o <directory> Specify the output directory path"
  echo "  -h            Display this help menu"
}

# Check Dependencies
function check_dependencies() {
  echo "[+] Checking dependencies..."
  for tool in nmap dirb whois nikto sqlmap nuclei recon-ng sublist3r; do
    if ! command -v "$tool" &> /dev/null; then
      echo "[-] Error: $tool is not installed: $tool Please install it and ensure it's in your PATH."
      exit 1
    fi
  done
  echo "[+] All dependencies are installed."
}

# Create Output Directory
function create_output_dir() {
  if [ ! -d "$output_dir" ]; then
    echo "[+] Creating output directory: $output_dir"
    mkdir -p "$output_dir"
  else
    echo "[+] Output directory already exists: $output_dir"
  fi
}

# Technology Detection with Recon-ng
function detect_tech() {
    echo "[+] Detecting technologies using Recon-ng..."
    recon-ng <<EOF
    # marketplace install all   # Commented out to avoid API key issues
    workspace add $domain
    use recon/domains-contacts/whois_pocs   # Use this module as it may not require an API key
    set SOURCE $domain
    run
    exit
EOF
    echo "[+] Recon-ng completed. Check the Recon-ng database for results."
}

# Subdomain Enumeration
function subdomain_enum() {
  echo "[+] Starting Subdomain Enumeration..."
  mkdir -p "$output_dir/subdomains"

  # Run Sublist3r directly (since it's in your PATH)
  sublist3r -d "$domain" -o "$output_dir/subdomains/sublist3r_output.txt"

  echo "[+] Subdomain Enumeration completed. Results in $output_dir/subdomains/"
}

# Port Scanning
function port_scan() {
  echo "[+] Starting Port Scanning..."
  nmap -T4 -A -p- -oN "$output_dir/nmap_output.txt" "$domain"
  echo "[+] Port Scanning completed. Results in $output_dir/nmap_output.txt"
}

# Directory Bruteforcing
function dir_brute() {
  echo "[+] Starting Directory Bruteforcing..."
  dirb http://"$domain" -o "$output_dir/dirb_output.txt"
  echo "[+] Directory Bruteforcing completed. Results in $output_dir/dirb_output.txt"
}

# Web Server Scanning
function web_scan() {
  echo "[+] Starting Web Server Scanning..."
  nikto -h "$domain" -o "$output_dir/nikto_output.txt"
  echo "[+] Web Server Scanning completed. Results in $output_dir/nikto_output.txt"
}

# Vulnerability Scanning (Nuclei)
function vuln_scan() {
  echo "[+] Starting Vulnerability Scanning (Nuclei)..."
  nuclei -target "$domain" -o "$output_dir/nuclei_output.txt"
  echo "[+] Vulnerability Scanning (Nuclei) completed. Results in $output_dir/nuclei_output.txt"
}

# Main Script Logic
# ------------------

# Parse Arguments
while getopts "hd:o:" opt; do
  case "$opt" in
    d) domain="$OPTARG";;
    o) output_dir="$OPTARG";;
    h) help_menu; exit;;
    \?) echo "Invalid option: -$OPTARG" >&2; help_menu; exit;;
    :) echo "Option -$OPTARG requires an argument." >&2; help_menu; exit;;
  esac
done

# Check if domain is provided
if [ -z "$domain" ]; then
  echo "[-] Error: Please specify a target domain using -d option."
  help_menu
  exit 1
fi

# Set default output directory if not provided
if [ -z "$output_dir" ]; then
  output_dir="$domain-output"
fi

# Script Execution
# ----------------
banner
check_dependencies
create_output_dir
detect_tech       # Run Recon-ng for technology detection
subdomain_enum    # Run Sublist3r for subdomain enumeration 
port_scan         # Port scanning with Nmap 
dir_brute         # Directory brute-forcing with Dirb 
web_scan          # Web server scanning with Nikto 
vuln_scan         # Vulnerability scanning with Nuclei 

echo "[+] Bug bounty automation script completed. All results are in $output_dir"

exit 0

