
## 🔐 Encrypted Command Execution System

This project provides a secure way to encrypt and execute terminal commands using one-time tokens.

### 📁 Files

- `genrate_token.py`: Encrypts a terminal command and stores it with a unique token.
    
- `exec.py`: Decrypts and executes a command based on the provided token.
    

---

### 🛠 Setup

Ensure you have Python and the `cryptography` library installed.

bash


```CopyEdit
pip install cryptography
```

---

### 🧪 Example Usage

#### 1. Generate a Token for a Command

bash

```CopyEdit
python genrate_token.py
```

Example input:

bash

```CopyEdit
Enter your command: echo "Hello, Secure World!"
```

Output:

bash

```CopyEdit
Your command token: a1b2c3d4
```

This token is stored with the encrypted command in `cmdstore.json`.

---

#### 2. Execute the Command via Token

bash

````CopyEdit
python exec.py a1b2c3d4
```

Output:

```CopyEdit
Hello, Secure World!
```

> The token is deleted after execution to prevent reuse.

---

### 🔐 How It Works

- A secret key (`key.txt`) is generated/stored.
    
- Commands are encrypted using Fernet and stored with a token ID in `cmdstore.json`.
    
- Tokens are one-time use only.
    
- `exec.py` decrypts the command and runs it via `subprocess`.
    

---

### ⚠️ Security Notice

- **Only use this in trusted environments.**
    
- Be cautious of command injection or storing sensitive commands.
    

---
