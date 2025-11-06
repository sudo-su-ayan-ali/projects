#!/usr/bin/env bash
if [ -d "recon" ]; then
  echo "Directory exists."
  mkdir recon_new
  cd recon_new
else
  echo "Directory does not exist."
  mkdir recon
  cd recon
fi
# echo "enter what distro you're using"
# echo "1 for debian and 2 for archlinux: "
# read -p "enter what distro you're using: " distro
# if [ "$distro" -eq 1 ]; then
#   echo "you want to install tools or not" 
#   read -p "1 for install tool and 2 not install" tool_for_debian
#   if [ "$tool_for_debian" -eq 1 ]; then
#     sudo apt install subfinder assetfinder ffuf dirsearch httpx-toolkit aquatone nmap
#   else
#     echo "nothing is going to install"
#   fi
# elif [ "$distro" -eq 2 ]; then
#   echo "you want to install tools or not" 
#   read -p "1 for install tool and 2 not install" tool_for_archlinux
#   if [ "$tool_for_archlinux" -eq 1 ]; then
#     sudo pacman -S subfinder assetfinder ffuf dirsearch httpx aquatone nmap --noconfirm
#   else
#     echo "nothing is going to install"
#   fi
# fi
# # here i am taking input
# read -p "enter your subdomain: " subdomain
# echo "this is your enter subdomain $subdomain"
# subfinder -d $subdomain -o subfinder.txt 
# assetfinder -subs-only $subdomain > assetfinder.txt 
# # finding subdomains using ffuf
# read -p "enter your wordlist_for_subdomain_enum path: " wordlist_for_subdomain_enum
# echo "now running ffuf"
# ffuf -u http://$subdomain/ -H "Host: FUZZ.$subdomain" -w $wordlist_for_subdomain_enum -mc 200,302,301,403 -t 40 -v > ffuf_vhost.txt 
# echo "now mearging all text files into one file"
# grep -oE 'https?://[^/ ]+' ffuf_vhost.txt | sed -E 's#^https?://##I; s#/.*##' | awk '!seen[$0]++' > all_hosts_from_ffuf.txt
# cat subfinder.txt assetfinder.txt all_hosts_from_ffuf.txt | sort -u > all_subs.txt
# echo "unique subs in all_subs.txt"
# cat all_subs.txt | httpx-pd -mc 200,302,301,403 -o final_all_subs.txt
# ip=$subdomain
# echo "you want full port scan so press 1"
# echo "or you want to scan a single port so press 2" 
# read -p "enter a number for your level of scan: " scan

# if [ "$scan" -eq 1 ]; then
#     mkdir -p nmap-full-scan && cd nmap-full-scan || exit 1
#     nmap -Pn -sC -sV -T4 -p- "$ip" -vv -oN nmap-full-scan.txt
# elif [ "$scan" -eq 2 ]; then
#     read -p "specify the port to scan: " singleportscan
#     mkdir -p nmap-single-port-scan && cd nmap-single-port-scan || exit 1
#     nmap -Pn -sV -sC -p "$singleportscan" "$ip" -vv -oN nmap-single-port-scan.txt
# else
#     echo "i think you did a mistake please correct that"
# fi
# echo "now i am directory busting."
# #read -p "enter a path for directory busting: " wordlist_for_directory_busting
# dirsearch -l all_subs.txt -w /usr/share/seclists/Discovery/Web-Content/big.txt -t 40 -o directory_busting.txt
# echo "now i am screenshoting using aquatone"
cat final_all_subs.txt | aquatone -out aquatone_screenshots
