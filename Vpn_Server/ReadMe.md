
## **OpenVPN Installation Commands on Ubuntu**

### **1. Update your system**

Bash

```
sudo apt update
sudo apt upgrade -y
```

### **2. Install OpenVPN and Easy-RSA**

Bash

```
sudo apt install openvpn easy-rsa -y
```

### **3. Set up Easy-RSA directory**

Bash

```
make-cadir ~/openvpn-ca
cd ~/openvpn-ca
```

### **4. Initialize the PKI**

Bash

```
./easyrsa init-pki
```

### **5. Build the Certificate Authority (CA)**

Bash

```
./easyrsa build-ca
```

_(Follow the prompts and set a password)_

### **6. Generate Server Certificate and Key**

Bash

```
./easyrsa gen-req server nopass
./easyrsa sign-req server server
```

_(Approve the request and enter your CA password)_

### **7. Generate Diffie-Hellman Parameters**

Bash

```
./easyrsa gen-dh
```

### **8. Generate HMAC Key**

Bash

```
openvpn --genkey --secret ta.key
```

### **9. Generate Client Certificate and Key**

Bash

```
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1
```

### **10. Copy Certificates and Keys to OpenVPN Directory**

Bash

```
sudo cp pki/ca.crt pki/issued/server.crt pki/private/server.key pki/dh.pem ta.key /etc/openvpn
```

### **11. Copy and Edit the Server Configuration File**

Bash

```
sudo gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf
sudo nano /etc/openvpn/server.conf
```

_(Edit file paths and settings as needed)_

### **12. Enable IP Forwarding**

Bash

```
sudo nano /etc/sysctl.conf
```

_(Uncomment or add `net.ipv4.ip_forward=1`)_

Bash

```
sudo sysctl -p
```

### **13. Allow OpenVPN Port in Firewall (UFW)**

Bash

```
sudo ufw allow 1194/udp
sudo ufw allow OpenSSH
sudo ufw enable
```

### **14. Start and Enable OpenVPN Service**

Bash

```
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server
```

---

**That’s it!**  
You now have OpenVPN installed and running on your Ubuntu server.  
For client configuration and connection, you’ll need to generate client `.ovpn` files and transfer them to your client devices.
