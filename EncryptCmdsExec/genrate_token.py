import os, json, base64, secrets
from cryptography.fernet import Fernet

# Load or generate key
if not os.path.exists("key.txt"):
    key = Fernet.generate_key()
    with open("key.txt", "wb") as f:
        f.write(key)
else:
    with open("key.txt", "rb") as f:
        key = f.read()

fernet = Fernet(key)

# Input command
command = input("Enter your command: ").strip()

# Encrypt
token_id = secrets.token_urlsafe(6)
enc_cmd = fernet.encrypt(command.encode()).decode()

# Save encrypted command
if os.path.exists("cmdstore.json"):
    with open("cmdstore.json", "r") as f:
        cmdmap = json.load(f)
else:
    cmdmap = {}

cmdmap[token_id] = enc_cmd

with open("cmdstore.json", "w") as f:
    json.dump(cmdmap, f)

print(f"Your command token: {token_id}")
