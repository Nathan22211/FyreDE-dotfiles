#!/bin/bash

CONFIG_FILE="/etc/safe-rm/rm-blacklist.conf"
LOG_FILE="/var/log/safe-rm.log"

# Directories where "rm *" is forbidden
PROTECTED_DIRS=("/" "/bin" "/boot" "/dev" "/etc" "/lib" "/lib64" "/proc" "/root" "/sbin" "/sys" "/usr" "/var")

# Load blacklist from config file
if [[ -f "$CONFIG_FILE" ]]; then
    # Read config file, remove comments and empty lines, then expand environment variables
    mapfile -t BLACKLIST < <(grep -vE '^#|^$' "$CONFIG_FILE" | while read -r line; do
        # Expand environment variables in the line
        eval "echo \"$line\""
    done)
else
    echo "Warning: Blacklist config file not found ($CONFIG_FILE), skipping checks." >&2
    BLACKLIST=()
fi

# Function to check if a file matches any blacklist pattern
is_blacklisted() {
    local file="$1"
    for pattern in "${BLACKLIST[@]}"; do
        if [[ "$file" == "$pattern" ]]; then
            return 0  # Match found
        fi
    done
    return 1  # No match
}

# Function to check if "rm *" is run in a dangerous directory
is_protected_directory() {
    local dir="$1"
    for protected in "${PROTECTED_DIRS[@]}"; do
        if [[ "$dir" == "$protected" ]]; then
            return 0  # It's a protected directory
        fi
    done
    return 1  # Not a protected directory
}

# Check if user is trying to run "rm *" in a critical directory
if [[ "$#" -eq 1 && "$1" == "*" ]]; then
    current_dir=$(pwd)
    if is_protected_directory "$current_dir"; then
        echo "Error: Attempt to delete everything while in a protected system directory ($current_dir) is blocked!" >&2
        echo "$(date) - BLOCKED: rm * in $current_dir" >> "$LOG_FILE"
        exit 1
    fi
fi

if is_protected_directory "$file" && "$file" == "/*"; then
    echo "Error: Attempt to delete a protected system directory ($file) is blocked!" >&2
    echo "$(date) - BLOCKED: rm * in $file" >> "$LOG_FILE"
    exit 1
fi

# Check each file argument
for file in "$@"; do
    if is_blacklisted "$file"; then
        echo "Error: Attempt to delete blacklisted file or directory: $file" >&2
        echo "$(date) - BLOCKED: $file" >> "$LOG_FILE"
        exit 1
    fi
done

# Run rm with safe parameters
/bin/rm "$@"
