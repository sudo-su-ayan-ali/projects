#!/usr/bin/env python3
"""
bug_bounty_recon.py

A Python translation of the bash recon script. Interactive prompts:
 - create ./recon and operate inside it
 - (optionally) install tools (calls package manager)
 - run subfinder/assetfinder/ffuf/httpx/dirsearch/aquatone/nmap steps if available

Notes:
 - This script calls external tools via subprocess. It checks whether each tool exists
   before calling it and prints helpful messages if a tool is missing.
 - It is defensive about quoted paths, empty inputs, and missing files.
 - It tries to match the behavior of your original script but with safer checks.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

# ---------- helpers ----------
def strip_quotes(s: str) -> str:
    if s is None:
        return ""
    s = s.strip()
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        return s[1:-1]
    # remove stray quotes anywhere
    return s.replace('"', "").replace("'", "")

def ask(prompt: str, default: str = "") -> str:
    try:
        val = input(prompt).strip()
    except EOFError:
        val = default
    return strip_quotes(val) if val else default

def cmd_exists(name: str) -> bool:
    return shutil.which(name) is not None

def run_cmd(cmd, stdout_file: Path = None, stderr_file: Path = None, shell=False):
    """Run a command. If stdout_file is provided, stream stdout there."""
    print(f"[RUN] {' '.join(cmd) if isinstance(cmd, (list, tuple)) else cmd}")
    try:
        if stdout_file:
            with open(stdout_file, "wb") as outfh, open(stderr_file or os.devnull, "wb") as errfh:
                return subprocess.run(cmd, stdout=outfh, stderr=errfh, check=False, shell=shell)
        else:
            return subprocess.run(cmd, check=False, shell=shell)
    except Exception as e:
        print(f"[ERROR] Running command failed: {e}")
        return None

def safe_read_lines(path: Path):
    if not path.exists():
        return []
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]

# ---------- setup ----------
WORKDIR = Path("recon")
WORKDIR.mkdir(parents=True, exist_ok=True)
os.chdir(WORKDIR)

print("Working directory:", Path.cwd())

# ---------- distro & optional installs ----------
distro = ask("enter what distro you're using (1 for debian, 2 for archlinux): ", "")
try:
    distro_i = int(distro)
except Exception:
    distro_i = None

if distro_i == 1:
    tool_for_debian = ask("you want to install tools? 1 = install, 2 = don't install: ", "2")
    try:
        if int(tool_for_debian) == 1:
            print("[INFO] Installing (apt) - you may be asked for sudo password.")
            # Be explicit about packages - do not auto-yes unless you want to
            packages = [
                "subfinder", "assetfinder", "ffuf", "dirsearch", "httpx", "aquatone", "nmap", "jq", "curl"
            ]
            run_cmd(["sudo", "apt", "update"])
            run_cmd(["sudo", "apt", "install", "-y"] + packages)
    except Exception:
        print("[WARN] Skipping install step or invalid input.")
elif distro_i == 2:
    tool_for_arch = ask("you want to install tools? 1 = install, 2 = don't install: ", "2")
    try:
        if int(tool_for_arch) == 1:
            print("[INFO] You chose archlinux install branch. This script will NOT auto-install AUR packages.")
            print("Please install tools manually (pacman / yay).")
    except Exception:
        print("[WARN] Skipping install step or invalid input.")
else:
    print("[WARN] Unknown distro choice; continuing without attempting installs.")

# ---------- domain input ----------
subdomain = ask("enter your subdomain (e.g. example.com): ")
if not subdomain:
    print("[ERROR] No domain provided. Exiting.")
    sys.exit(1)
print(f"this is your entered subdomain: {subdomain}")

# ---------- subdomain enumeration ----------
subfinder_out = Path("subfinder.txt")
assetfinder_out = Path("assetfinder.txt")
ffuf_vhost_out = Path("ffuf_vhost.txt")

# run subfinder
if cmd_exists("subfinder"):
    run_cmd(["subfinder", "-d", subdomain, "-silent", "-o", str(subfinder_out)], stdout_file=None)
else:
    print("[WARN] subfinder not found; skipping subfinder step.")

# run assetfinder
if cmd_exists("assetfinder"):
    # assetfinder writes to stdout; capture into a file
    with open(assetfinder_out, "wb") as f:
        try:
            subprocess.run(["assetfinder", "-subs-only", subdomain], stdout=f, check=False)
        except Exception as e:
            print(f"[WARN] assetfinder run failed: {e}")
else:
    print("[WARN] assetfinder not found; skipping assetfinder.")

# ---------- ffuf vhost brute ----------
wordlist_for_subdomain_enum = ask("enter your wordlist_for_subdomain_enum path (or press Enter to skip ffuf): ", "")
if wordlist_for_subdomain_enum:
    wordlist_for_subdomain_enum = strip_quotes(wordlist_for_subdomain_enum)
    wl_path = Path(wordlist_for_subdomain_enum)
    if not wl_path.exists():
        print(f"[ERROR] Wordlist not found: {wl_path}. Skipping ffuf.")
    elif not cmd_exists("ffuf"):
        print("[WARN] ffuf not installed. Skipping ffuf step.")
    else:
        # use Host header vhost fuzzing pattern; write verbose output to ffuf_vhost_out
        # ffuf syntax: -u http://<IP-or-host>/ -H "Host: FUZZ.<domain>"
        cmd = [
            "ffuf",
            "-u", f"http://{subdomain}/",
            "-H", f"Host: FUZZ.{subdomain}",
            "-w", str(wl_path),
            "-mc", "200,302,301,403",
            "-t", "40",
            "-v"
        ]
        run_cmd(cmd, stdout_file=ffuf_vhost_out, stderr_file=None)

# extract hosts from ffuf output into only_subs_ffuf.txt
only_subs_ffuf = Path("only_subs_ffuf.txt")
if ffuf_vhost_out.exists():
    text = ffuf_vhost_out.read_text()
    # basic extraction: find http(s)://... up to the first slash
    import re
    hosts = set()
    for m in re.findall(r"https?://([^/ \n\r\t]+)", text, flags=re.IGNORECASE):
        hosts.add(m.strip())
    only_subs_ffuf.write_text("\n".join(sorted(hosts)))
    print(f"[INFO] Extracted {len(hosts)} hosts from ffuf into {only_subs_ffuf}")
else:
    print("[INFO] No ffuf output file; skipping ffuf parsing.")

# ---------- merge subs ----------
all_subs = Path("all_subs.txt")
parts = []
if subfinder_out.exists():
    parts.append(subfinder_out)
if assetfinder_out.exists():
    parts.append(assetfinder_out)
if only_subs_ffuf.exists():
    parts.append(only_subs_ffuf)

if not parts:
    print("[WARN] No subdomain source files found (subfinder/assetfinder/ffuf). all_subs.txt will be empty.")
    all_subs.write_text("")
else:
    merged = set()
    for p in parts:
        for ln in safe_read_lines(p):
            merged.add(ln.strip())
    all_subs.write_text("\n".join(sorted(merged)))
    print(f"[INFO] Wrote {len(merged)} unique entries to {all_subs}")

# ---------- httpx probing to final_all_subs.txt ----------
final_all_subs = Path("final_all_subs.txt")
if all_subs.exists() and all_subs.stat().st_size > 0:
    if cmd_exists("httpx"):
        run_cmd(["httpx", "-l", str(all_subs), "-mc", "200,302,301,403", "-silent", "-o", str(final_all_subs)])
    elif cmd_exists("httpx-pd"):
        run_cmd(["httpx-pd", "-l", str(all_subs), "-mc", "200,302,301,403", "-silent", "-o", str(final_all_subs)])
    else:
        # fallback by using curl probes (slow)
        print("[WARN] httpx not found; falling back to curl-based probing (slow).")
        final_lines = []
        for host in safe_read_lines(all_subs):
            # try http then https
            for scheme in ("http", "https"):
                try:
                    r = subprocess.run(["curl", "-s", "--max-time", "6", "-I", f"{scheme}://{host}"], capture_output=True, check=False)
                    hdr = r.stdout.decode(errors="ignore").splitlines()[0] if r.stdout else ""
                    if any(code in hdr for code in ("200", "301", "302", "403")):
                        final_lines.append(f"{scheme}://{host}")
                        break
                except Exception:
                    continue
        final_all_subs.write_text("\n".join(final_lines))
else:
    print("[WARN] all_subs.txt is missing or empty. Skipping httpx/curl probing.")

# ---------- safe check & display final results ----------
if final_all_subs.exists() and final_all_subs.stat().st_size > 0:
    count = len(safe_read_lines(final_all_subs))
    print(f"{count} subdomains found in {final_all_subs}.")
    print(final_all_subs.read_text())
else:
    print(f"[ERROR] '{final_all_subs}' does not exist or is empty. Upstream steps likely failed.")
    # do not exit immediately; continue so user can choose other steps or fix inputs
    # sys.exit(1)

# ---------- port scanning (nmap) ----------
ip = subdomain  # original behavior used the original subdomain as nmap target
scan = ask("you want full port scan so press 1 or single port press 2 (other to skip): ", "")
try:
    scan_i = int(scan)
except Exception:
    scan_i = None

if scan_i == 1:
    if not cmd_exists("nmap"):
        print("[WARN] nmap not installed; skipping nmap full scan.")
    else:
        outdir = Path("nmap-full-scan")
        outdir.mkdir(exist_ok=True)
        # scanning the original domain; you may prefer to scan each host in final_all_subs
        print(f"[INFO] Running full nmap scan on {ip} (this may take a long time).")
        run_cmd(["nmap", "-Pn", "-sC", "-sV", "-T4", "-p-", ip, "-vv", "-oN", str(outdir / "nmap-full-scan.txt")])
elif scan_i == 2:
    if not cmd_exists("nmap"):
        print("[WARN] nmap not installed; skipping nmap single-port scan.")
    else:
        singleportscan = ask("specify that port to scan (e.g. 443): ", "")
        if singleportscan:
            outdir = Path("nmap-single-port-scan")
            outdir.mkdir(exist_ok=True)
            run_cmd(["nmap", "-Pn", "-sV", "-sC", "-p", singleportscan, ip, "-vv", "-oN", str(outdir / "nmap-single-port-scan.txt")])
        else:
            print("[WARN] No port specified. Skipping nmap single-port scan.")
else:
    print("[INFO] Skipping nmap scan.")

# ---------- directory busting (dirsearch) ----------
print("now i am directory busting")
wordlist_for_directory_busting = ask("enter a path for directory busting wordlist (or press Enter to skip): ", "")
if wordlist_for_directory_busting and cmd_exists("dirsearch") and final_all_subs.exists() and final_all_subs.stat().st_size > 0:
    print("[INFO] Running dirsearch on each URL in final_all_subs.txt")
    out = Path("directory_busting.txt")
    # dirsearch supports -l list file; provide final_all_subs as -l
    run_cmd(["dirsearch", "-l", str(final_all_subs), "-w", wordlist_for_directory_busting, "-t", "40", "-o", str(out)])
else:
    print("[WARN] Skipping dirsearch (missing wordlist, dirsearch, or final_all_subs).")

# ---------- screenshots with aquatone ----------
print("now i am screenshoting using aquatone")
if cmd_exists("aquatone") and final_all_subs.exists() and final_all_subs.stat().st_size > 0:
    # aquatone expects lines of urls on stdin or a file redirect. We'll call aquatone with input redirection.
    # To emulate piping the file content, pass it via -out and feed file via stdin
    run_cmd(["aquatone", "-out", "aquatone_output", "-ports", "80,443"], stdout_file=None, shell=False)
    # Many aquatone installs expect input from stdin; user may run: cat final_all_subs.txt | aquatone -out aquatone_output
    print("[NOTE] Some aquatone installations read from stdin. If the above didn't capture targets, run:")
    print("      cat final_all_subs.txt | aquatone -out aquatone_output -ports 80,443")
else:
    print("[WARN] aquatone not found or final_all_subs missing; skipping screenshots.")

print("Done. Results are in:", Path.cwd())
