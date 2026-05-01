import sys, os, json
from cryptography.fernet import Fernet
import subprocess

if len(sys.argv) != 2:
    print("Usage: ./exec.py <token>")
    sys.exit(1)

token = sys.argv[1]

# Load key and command map
with open("key.txt", "rb") as f:
    key = f.read()
fernet = Fernet(key)

with open("cmdstore.json", "r") as f:
    cmdmap = json.load(f)

if token not in cmdmap:
    print("Invalid token.")
    sys.exit(1)

# Decrypt command
enc_cmd = cmdmap[token]
command = fernet.decrypt(enc_cmd.encode()).decode()

# Execute command
subprocess.run(command, shell=True)

# Delete token after execution
del cmdmap[token]
with open("cmdstore.json", "w") as f:
    json.dump(cmdmap, f)
