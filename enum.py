import os
import subprocess
import argparse

TARGET = "example.com"  # Default target
OUTPUT_DIR = "bugbounty_output"
SUBDOMAINS_FILE = os.path.join(OUTPUT_DIR, "subdomains.txt")
ALIVE_FILE = os.path.join(OUTPUT_DIR, "alive_subdomains.txt")
SCREENSHOT_DIR = os.path.join(OUTPUT_DIR, "screenshots")

def run_tool(cmd, outfile, verbose=True):
    try:
        if verbose:
            print(f"[VERBOSE] Running: {' '.join(cmd)} > {outfile}")
        with open(outfile, "a") as f:
            subprocess.run(cmd, stdout=f, stderr=subprocess.DEVNULL, check=True)
    except Exception as e:
        print(f"[!] Failed to run {' '.join(cmd)}: {e}")

def aggregate_subdomains(files, out_file, verbose=True):
    subdomains = set()
    for file in files:
        if os.path.isfile(file):
            with open(file) as f:
                for line in f:
                    sub = line.strip()
                
                    if sub and not sub.startswith("#"):
                        subdomains.add(sub)
    with open(out_file, "w") as f:
        for sub in sorted(subdomains):
            f.write(sub + "\n")
    print(f"[*] Aggregated {len(subdomains)} unique subdomains to {out_file}")
    if verbose:
        print(f"[VERBOSE] Subdomains: {sorted(subdomains)}")

def screenshot_alive(alive_file, screenshot_dir, verbose=False):
    os.makedirs(screenshot_dir, exist_ok=True)
    print("[*] Taking screenshots of alive domains with gowitness...")
    try:
        cmd = [
            "gowitness", "screenshot", "-f", alive_file, "-P", screenshot_dir, "--disable-db"
        ]
        if verbose:
            print(f"[VERBOSE] Running: {' '.join(cmd)}")
        subprocess.run(cmd, check=True)
        print(f"[*] Screenshots saved in {screenshot_dir}")
    except FileNotFoundError:
        print(f"[!] Screenshotting failed: gowitness not found. Please install gowitness to enable screenshots.")
    except Exception as e:
        print(f"[!] Screenshotting failed: {e}")
def main():
    parser = argparse.ArgumentParser(description="Subdomain enumeration and screenshot tool")
    parser.add_argument("target", nargs="?", default=None, help="Target domain")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose output")
    args = parser.parse_args()

    global TARGET
    if args.target:
        TARGET = args.target
    else:
        TARGET = input("Enter target domain: ").strip()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("[*] Running subdomain enumeration tools...")

    subfinder_out = os.path.join(OUTPUT_DIR, "subfinder.txt")
    sublist3r_out = os.path.join(OUTPUT_DIR, "sublist3r.txt")

    # Run subfinder
    run_tool(["subfinder", "-d", TARGET, "-silent"], subfinder_out, args.verbose)
    # Run sublist3r
    run_tool(["sublist3r", "-d", TARGET, "-o", sublist3r_out], sublist3r_out, args.verbose)

    # Aggregate and deduplicate
    aggregate_subdomains([subfinder_out, sublist3r_out], SUBDOMAINS_FILE, args.verbose)

    try:
        cmd = ["httpx", "-list", SUBDOMAINS_FILE, "-silent", "-o", ALIVE_FILE]
        if args.verbose:
            print(f"[VERBOSE] Running: {' '.join(cmd)}")
        subprocess.run(cmd, check=True)
        print(f"[*] Alive subdomains saved to {ALIVE_FILE}")
    except Exception as e:
        print(f"[!] httpx failed: {e}")
        print(f"[!] httpx failed: {e}")

    # Screenshot alive domains
    screenshot_alive(ALIVE_FILE, SCREENSHOT_DIR, args.verbose)

if __name__ == "__main__":
    main()
