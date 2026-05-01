
# 🧪 XSS Practice Lab

This is a complete, minimal XSS (Cross-Site Scripting) Practice Lab for testing and demonstrating both **vulnerable** and **secure** code. It includes a toggle to switch between safe and unsafe rendering modes. Built using HTML, JavaScript, and Node.js (Express backend).

---

## 📁 Project Structure

```

xss-lab/
├── index.html        # Frontend for testing XSS
├── package.json      # Node.js metadata and dependencies
├── server.js         # (You need to add this) Express server to serve the HTML

````

---

## 🚀 Features

- ✅ **Secure Mode** — Uses `textContent` and DOMPurify to prevent XSS.
- ❌ **Vulnerable Mode** — Uses `innerHTML` to simulate real-world XSS.
- 🔁 Toggle between modes via a checkbox.
- 🧪 Good for beginners and advanced XSS payload practice.
- 🛡️ CSP (`Content-Security-Policy`) header added for real-world testing.

---

## 🔧 Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/your-username/xss-lab.git
cd xss-lab
````

### 2. Install dependencies

```bash
npm install
```

### 3. Add a `server.js` file (if not already)

Create a simple Express server to serve `index.html`:

```js
// server.js
const express = require('express');
const path = require('path');
const app = express();

app.use(express.static(__dirname));
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(3000, () => {
  console.log('🚀 XSS Lab running at http://localhost:3000');
});
```

### 4. Start the server

```bash
npm start
```

Then visit: [http://localhost:3000](http://localhost:3000)

---

## 🛠 Tech Stack

* **Frontend**: HTML, CSS, JavaScript
* **Security Library**: [DOMPurify](https://github.com/cure53/DOMPurify)
* **Backend**: Node.js + Express

---

## 📦 Dependencies

From `package.json`:

* [`express`](https://www.npmjs.com/package/express)
* [`body-parser`](https://www.npmjs.com/package/body-parser)
* [`isomorphic-dompurify`](https://www.npmjs.com/package/isomorphic-dompurify)

---

## 🔐 Security Concepts Practiced

* Reflected XSS
* DOM-based XSS
* CSP enforcement
* Safe DOM manipulation (`textContent`)
* Unsafe DOM manipulation (`innerHTML`)

---

## 📷 Screenshot (Optional)

> ![Screenshot Placeholder](screenshot.png)
> *(You can take a screenshot of the page in secure and insecure modes and include it here.)*

---

## ⚠️ Disclaimer

This project is for **educational purposes only**. Do not deploy on production or expose to untrusted networks.


