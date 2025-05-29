#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <directory_path>" >&2
    exit 1
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist" >&2
    exit 1
fi

find "$TARGET_DIR" -name "*.tfvars.json.gpg" -type f | while read -r encrypted_file; do
    decrypted_file="${encrypted_file%.gpg}"
    
    echo "Decrypting: $encrypted_file -> $decrypted_file"
    
    if echo "$GPG_PASS" | gpg --batch --yes --quiet --decrypt --passphrase-fd 0 "$encrypted_file" > "$decrypted_file"; then
        echo "Successfully decrypted: $decrypted_file"
    else
        echo "Failed to decrypt: $encrypted_file" >&2
        exit 1
    fi
done

echo "All .tfvars.json.gpg files have been decrypted successfully"
