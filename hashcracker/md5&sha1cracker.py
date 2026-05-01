import hashlib

def crack_hash(hash_to_crack, wordlist_path, hash_type='md5'):
    with open(wordlist_path, 'r', encoding='utf-8', errors='ignore') as f:
        for word in f:
            word = word.strip()
            if hash_type == 'md5':
                hashed_word = hashlib.md5(word.encode()).hexdigest()
            elif hash_type == 'sha1':
                hashed_word = hashlib.sha1(word.encode()).hexdigest()
            else:
                print("Unsupported hash type.")
                return None
            if hashed_word == hash_to_crack:
                print(f"[+] Password found: {word}")
                return word
    print("[-] Password not found in wordlist.")
    return None

if __name__ == "__main__":
    hash_input = input("Enter the hash to crack: ").strip()
    wordlist = input("Enter path to wordlist (e.g., rockyou.txt): ").strip()
    hash_type = input("Hash type (md5/sha1): ").strip().lower()
    crack_hash(hash_input, wordlist, hash_type)
