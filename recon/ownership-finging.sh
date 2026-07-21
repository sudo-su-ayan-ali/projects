while read -r domain; do
    org=$(whois "$domain" 2>/dev/null | grep -i "Registrant Organization" | head -1 | cut -d: -f2 | xargs)
    if echo "$org" | grep -qi "klarna"; then
        echo "[KLARNA] $domain — $org"
    else
        echo "[SKIP] $domain — $org"
    fi
done < subfinder-domains.txt | tee ownership_results.txt
