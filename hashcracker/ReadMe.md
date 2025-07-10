

# 🔐 Simple Hash Cracker (MD5 / SHA1)

This Python script attempts to crack an MD5 or SHA1 hash using a wordlist (dictionary attack).

## 📌 Features

- Supports **MD5** and **SHA1** hash types.
- Reads a custom wordlist (e.g., `rockyou.txt`).
- Simple CLI interface for quick hash cracking.

## 🛠️ Requirements

- Python 3.x

Install required packages (if needed):

```bash
pip install -r requirements.txt
````

> Note: `hashlib` is part of Python’s standard library, so no additional dependencies are needed.

## 🚀 Usage

```bash
python hash_cracker.py
```

You'll be prompted to enter:

1. The hash to crack
2. The path to your wordlist (like `rockyou.txt`)
3. The hash type (`md5` or `sha1`)

## 📂 Example

```bash
Enter the hash to crack: 5f4dcc3b5aa765d61d8327deb882cf99
Enter path to wordlist (e.g., rockyou.txt): rockyou.txt
Hash type (md5/sha1): md5
[+] Password found: password
```

## 📄 License

This project is for **educational purposes only**. Use responsibly.

````



