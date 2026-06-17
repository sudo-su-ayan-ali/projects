#!/bin/bash

read -p "Enter the hash: " hash
echo "here is your hash: $hash"
hash-identifier 
echo $hash > hash.txt

echo "now identifing which type of hash is this :)"

hash-identifier $hash

