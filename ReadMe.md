# 🛠️ Projects Repository

Welcome to the **Projects** repository by [sudo-su-ayan-ali](https://github.com/sudo-su-ayan-ali)!  
This repository is a collection of various cybersecurity and infosec-related tools and experiments.

---

## 🔍 Project Overview

This repository showcases a variety of Python-based cybersecurity tools built for **learning**, **research**, and **ethical hacking** purposes. These projects cover core areas such as reconnaissance, web vulnerability testing, keylogging, and cryptographic hash cracking. They aim to help beginners and intermediate learners understand how real-world hacking techniques work—while emphasizing ethical usage.

Each tool is designed with simplicity and modularity in mind, making it easy to explore and modify for educational penetration testing scenarios or Capture The Flag (CTF) competitions.

> ⚠️ All tools are strictly for legal and authorized testing in controlled environments.

---

## 📁 Projects

### 🔍 Recon + Subdomain Enumerator
A tool focused on reconnaissance and subdomain enumeration. Useful for asset discovery and information gathering during a penetration test or bug bounty.

**Features:**
- Collects hosts using OSINT
- Subdomain enumeration
- Passive and active scanning

---

### 🖥️ Keylogger
A basic keylogger for educational or ethical testing purposes.

**Features:**
- Logs keystrokes
- Saves activity in a file
- Minimal & easy-to-use implementation

> ⚠️ Note: **Only use this module in a controlled, ethical, and legal environment.**

---

### 🧪 XSS Hardcore Lab
A set of scripts and tools focused on testing and practicing **Cross-Site Scripting (XSS)** attacks.

**Features:**
- Lab-like environment
- Payload injection
- Filters and bypass testing

---

### 🕵️ XSS Scanner
A script or tool built to scan targets for XSS vulnerabilities.

**Features:**
- Detects reflective/stored XSS
- Payload-based detection
- Simple and fast scanning

---

### 🔐 Hash Cracker (MD5 / SHA1)
A command-line tool to crack hashes using a wordlist attack (dictionary attack).

**Features:**
- Supports `md5` and `sha1`
- Uses custom wordlists (e.g., rockyou.txt)
- Simple interface for learning and testing

---

### 🧾 Encrypted Command Executor
A secure one-time-token based command execution system. This tool encrypts shell commands and allows them to be executed only once using a token.

**Features:**
- Encrypts commands with Fernet (symmetric encryption)
- Generates one-time tokens
- Deletes token after use to prevent reuse
- Useful in secure scripting scenarios

#### 🔧 Usage

1. **Generate a Token**
   ```bash
   python genrate_token.py
   ```
**Example Input:**

bash

```CopyEdit

Enter your command: echo "Secret Ops" Your command token: 9xG3JzPp
```
2. **Execute the Token**
    
    bash
    
    ```CopyEdit
    
    python exec.py 9xG3JzPp
    ```
    **Output:**
    
    nginx
    
    ```CopyEdit
    
    Secret Ops
    ```

> ⚠️ Important: Tokens are deleted after use. This tool is for controlled and ethical use only.

---

## 📦 Requirements

Install dependencies with:

bash

```CopyEdit

pip install -r requirements.txt
```
Make sure Python 3 is installed before setup.

---

✅ **Disclaimer**  
This project is intended only for educational and ethical penetration testing purposes.  
**Unauthorized access or usage of these tools against systems without permission is illegal.** Use them only in test environments or with explicit authorization.

---

🙌 **Contributions**  
Feel free to fork this repository and submit pull requests. Suggestions and improvements are always welcome!

---

📜 **License**  
This repository does not currently have a license. Please contact me for usage permissions.

