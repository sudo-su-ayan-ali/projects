
# 🔎 Subdomain Enumeration and Screenshot Tool

This is a Python-based automation script that performs subdomain enumeration, checks for live hosts, and captures screenshots of the discovered subdomains using various tools commonly used in bug bounty and reconnaissance workflows.

---

## ⚠️ Disclaimer

This script is intended for **authorized penetration testing and educational purposes only**. Do not use it against systems you do not own or have permission to test.

---

## ✨ Features

- Enumerate subdomains using:
  - [Subfinder](https://github.com/projectdiscovery/subfinder)
  - [Sublist3r](https://github.com/aboul3la/Sublist3r)
- Aggregate and deduplicate subdomains
- Check which subdomains are alive using [httpx](https://github.com/projectdiscovery/httpx)
- Take screenshots of live subdomains using [gowitness](https://github.com/sensepost/gowitness)

---

## 📦 Requirements

Install the following tools before using this script:

- `subfinder`
- `sublist3r`
- `httpx`
- `gowitness`

You can install them as follows:

### **Subfinder**
```bash
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
```

### **Sublist3r**
```bash
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r
pip install -r requirements.txt
sudo ln -s $(pwd)/sublist3r.py /usr/local/bin/sublist3r
```

### **httpx**
```bash
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
```

### **gowitness**
```bash
go install github.com/sensepost/gowitness@latest
```

Make sure `$GOPATH/bin` is in your system's `PATH`.

---

## 🛠️ Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/bugbounty-recon.git
cd bugbounty-recon
```

2. Ensure Python 3 and required tools are installed.

---

## 🚀 Usage

```bash
python recon.py example.com --verbose
```

### Arguments:

| Argument      | Description                           |
|---------------|---------------------------------------|
| `target`      | The domain name to scan (e.g., `example.com`) |
| `--verbose`   | Optional: display detailed output     |

If the target is not passed as an argument, the script will prompt for user input.

---

## 🧾 Output Structure

All results are saved in a directory called `bugbounty_output/`:

```
bugbounty_output/
├── subfinder.txt            # Raw results from subfinder
├── sublist3r.txt            # Raw results from sublist3r
├── subdomains.txt           # Merged and deduplicated subdomains
├── alive_subdomains.txt     # Subdomains responding to HTTP/S
└── screenshots/             # Screenshots taken by gowitness
```

---

## 🖼 Sample Screenshot Output

Screenshots of live subdomains are saved in:

```bash
bugbounty_output/screenshots/
```

Each file is named based on the domain name.

---

## 📌 Notes

- Make sure all tools used are installed and available in system `PATH`.
- Some tools may require API keys for better enumeration results (especially `subfinder`).
- This is a modular and extendable script you can adapt for your recon workflow.

---

## ✅ License

This project is licensed under the MIT License.

---

## 👨‍💻 Author

Designed with ❤️ for automating reconnaissance tasks.

Feel free to contribute or suggest improvements!
