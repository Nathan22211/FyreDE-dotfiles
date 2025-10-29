#!/bin/bash

# Safe chmod wrapper - prevents modification of system critical directories
# and user-defined protected paths to avoid system damage

# Configuration file for user-defined protected paths
PROTECTION_CONFIG="/etc/safe-chmod-protected"

# System critical directories that should never have their permissions changed
# Note: We protect the directories themselves, not their contents
SYSTEM_CRITICAL_DIRS=(
    "/"
    "/bin"
    "/sbin"
    "/usr"
    "/etc"
    "/var"
    "/sys"
    "/proc"
    "/dev"
    "/boot"
    "/lib"
    "/lib64"
    "/opt"
    "/root"
    "/run"
    "/tmp"
    "/home"
    "/media"
    "/mnt"
    "/snap"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}" >&2
}

print_info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

print_success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

# Function to check if a path is protected
is_protected() {
    local target_path="$1"
    local real_path
    
    # Get the real path (resolve symlinks)
    if ! real_path=$(realpath "$target_path" 2>/dev/null); then
        # If realpath fails, use the path as-is
        real_path="$target_path"
    fi
    
    # Check against system critical directories
    for critical_dir in "${SYSTEM_CRITICAL_DIRS[@]}"; do
        if [[ "$real_path" == "$critical_dir" ]]; then
            return 0  # Protected
        fi
    done
    
    # Check against user-defined protected paths
    if [[ -f "$PROTECTION_CONFIG" ]]; then
        # Read config file, remove comments and empty lines, then expand environment variables
        mapfile -t USER_PROTECTED_PATHS < <(grep -vE '^#|^$' "$PROTECTION_CONFIG" | while read -r line; do
            # Expand environment variables in the line
            eval "echo \"$line\""
        done)
        
        for protected_path in "${USER_PROTECTED_PATHS[@]}"; do
            if [[ "$real_path" == "$protected_path" ]]; then
                return 0  # Protected
            fi
        done
    fi
    
    return 1  # Not protected
}

# Function to show help
show_help() {
    cat << EOF
Safe chmod wrapper - prevents modification of system critical directories

USAGE:
    safe-chmod [OPTIONS] MODE FILE...

OPTIONS:
    -h, --help          Show this help message
    -l, --list          List protected paths
    -f, --force         Force operation (bypass protection - USE WITH EXTREME CAUTION)
    -v, --verbose       Verbose output
    --dry-run          Show what would be done without actually doing it

PROTECTED PATHS:
    System critical directories are automatically protected:
    /, /bin, /sbin, /usr, /etc, /var, /sys, /proc, /dev, /boot, /lib, /lib64, /opt, /root, /run, /tmp, /home, /media, /mnt, /snap

    User-defined protected paths are stored in: $PROTECTION_CONFIG
    (Edit this file as root to add/remove protected paths)

EXAMPLES:
    safe-chmod 755 /home/user/documents
    safe-chmod +x /home/user/script.sh
    safe-chmod --list
    safe-chmod --dry-run 644 /etc/hostname

EOF
}

# Function to list protected paths
list_protected() {
    print_info "System critical protected directories:"
    for dir in "${SYSTEM_CRITICAL_DIRS[@]}"; do
        echo "  $dir"
    done
    
    if [[ -f "$PROTECTION_CONFIG" ]]; then
        print_info "User-defined protected paths:"
        # Read config file, remove comments and empty lines, then expand environment variables
        mapfile -t USER_PROTECTED_PATHS < <(grep -vE '^#|^$' "$PROTECTION_CONFIG" | while read -r line; do
            # Expand environment variables in the line
            eval "echo \"$line\""
        done)
        
        for protected_path in "${USER_PROTECTED_PATHS[@]}"; do
            echo "  $protected_path"
        done
    else
        print_info "No user-defined protected paths configured"
    fi
}


# Function to perform dry run
dry_run() {
    local mode="$1"
    shift
    local files=("$@")
    local protected_files=()
    local safe_files=()
    
    print_info "DRY RUN - No changes will be made"
    print_info "Mode: $mode"
    print_info "Files to process:"
    
    for file in "${files[@]}"; do
        if is_protected "$file"; then
            protected_files+=("$file")
            print_warning "  $file - PROTECTED (would be blocked)"
        else
            safe_files+=("$file")
            print_success "  $file - OK (would be processed)"
        fi
    done
    
    if [[ ${#protected_files[@]} -gt 0 ]]; then
        print_error "Some files are protected and would be blocked"
        return 1
    fi
    
    print_success "All files are safe to modify"
    return 0
}

# Main function
main() {
    local force=false
    local verbose=false
    local dry_run_mode=false
    local mode=""
    local files=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_protected
                exit 0
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --dry-run)
                dry_run_mode=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$mode" ]]; then
                    mode="$1"
                else
                    files+=("$1")
                fi
                shift
                ;;
        esac
    done
    
    # Check if we have a mode and files
    if [[ -z "$mode" || ${#files[@]} -eq 0 ]]; then
        print_error "Usage: safe-chmod MODE FILE..."
        show_help
        exit 1
    fi
    
    # Handle dry run
    if [[ "$dry_run_mode" == true ]]; then
        dry_run "$mode" "${files[@]}"
        exit $?
    fi
    
    # Check for protected files
    local protected_files=()
    local safe_files=()
    
    for file in "${files[@]}"; do
        if is_protected "$file"; then
            protected_files+=("$file")
        else
            safe_files+=("$file")
        fi
    done
    
    # Report protected files
    if [[ ${#protected_files[@]} -gt 0 ]]; then
        print_error "The following files/directories are protected and cannot be modified:"
        for file in "${protected_files[@]}"; do
            print_error "  $file"
        done
        
        if [[ "$force" == true ]]; then
            print_warning "Force mode enabled - proceeding anyway (THIS IS DANGEROUS!)"
        else
            print_error "Use --force to override protection (NOT RECOMMENDED)"
            exit 1
        fi
    fi
    
    # Execute chmod on safe files
    if [[ ${#safe_files[@]} -gt 0 ]]; then
        if [[ "$verbose" == true ]]; then
            print_info "Executing: chmod $mode ${safe_files[*]}"
        fi
        
        if chmod "$mode" "${safe_files[@]}"; then
            print_success "Successfully changed permissions for: ${safe_files[*]}"
        else
            print_error "Failed to change permissions"
            exit 1
        fi
    fi
    
    # Execute chmod on protected files if force is enabled
    if [[ "$force" == true && ${#protected_files[@]} -gt 0 ]]; then
        print_warning "Force mode: modifying protected files (THIS IS DANGEROUS!)"
        if [[ "$verbose" == true ]]; then
            print_info "Executing: chmod $mode ${protected_files[*]}"
        fi
        
        if chmod "$mode" "${protected_files[@]}"; then
            print_warning "Successfully changed permissions for protected files: ${protected_files[*]}"
        else
            print_error "Failed to change permissions for protected files"
            exit 1
        fi
    fi
}

# Run main function with all arguments
main "$@"
