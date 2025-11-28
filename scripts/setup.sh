#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/tpl/tpl.sh"

# Load environment variables
source_file "../.env"

# Parameter definitions
declare -A PARAMETERS=(
)
declare -A PARAMETER_DESCRIPTIONS=(
)
PARAMETER_ORDER=()

# Flag definitions
declare -A FLAGS=(
    ["help"]="show_help"
    ["h"]="show_help"
)
declare -A FLAG_DESCRIPTIONS=(
    ["help,h"]="Displays all available parameters and flags"
)

# Protection functions
declare -A PROTECTION=(
)

# Command description
description="Pulls the wordpress version and extracts it, then applies custom overwrites."

function run {
    # Define the src directory path (one level above the scripts directory)
    local src_dir="$SCRIPT_DIR/../src"
    
    # Create src directory if it doesn't exist
    if [[ ! -d "$src_dir" ]]; then
        color "yellow" "Creating src directory..."
        mkdir -p "$src_dir"
        color "green" "✓ src directory created at: $src_dir"
    else
        color "cyan" "✓ src directory already exists"
    fi
    
    # Check if WORDPRESS_INSTALL_VERSION is set
    if [[ -z "$WORDPRESS_INSTALL_VERSION" ]]; then
        color "red" "Error: WORDPRESS_INSTALL_VERSION not set in .env file"
        exit 1
    fi
    
    # Change to src directory
    cd "$src_dir" || {
        color "red" "Error: Failed to change to src directory"
        exit 1
    }
    
    color "cyan" "Downloading WordPress version: $WORDPRESS_INSTALL_VERSION"
    
    # Define download URL and file name
    local wp_url="https://wordpress.org/wordpress-${WORDPRESS_INSTALL_VERSION}.tar.gz"
    local wp_archive="wordpress-${WORDPRESS_INSTALL_VERSION}.tar.gz"
    
    # Download WordPress
    if wget -q --show-progress "$wp_url" -O "$wp_archive"; then
        color "green" "✓ WordPress $WORDPRESS_INSTALL_VERSION downloaded successfully"
    else
        color "red" "Error: Failed to download WordPress $WORDPRESS_INSTALL_VERSION"
        color "yellow" "Please verify the version exists at: https://wordpress.org/download/releases/"
        exit 1
    fi
    
    # Extract WordPress
    color "cyan" "Extracting WordPress..."
    if tar -xzf "$wp_archive"; then
        color "green" "✓ WordPress extracted successfully"
    else
        color "red" "Error: Failed to extract WordPress archive"
        exit 1
    fi
    
    # Move WordPress files from wordpress/ to src/ root
    color "cyan" "Moving WordPress files to src root..."
    if mv wordpress/* wordpress/.* . 2>/dev/null; then
        color "green" "✓ WordPress files moved to src root"
    else
        # Fallback if .* fails (no hidden files)
        mv wordpress/* . 2>/dev/null
        color "green" "✓ WordPress files moved to src root"
    fi
    
    # Remove empty wordpress directory
    rmdir wordpress 2>/dev/null
    
    # Clean up archive
    rm "$wp_archive"
    color "green" "✓ Cleaned up archive file"
    
    echo
    color "bright_green" "WordPress $WORDPRESS_INSTALL_VERSION setup complete!"
    color "white" "WordPress files are located at: $(pwd)"
    
    # Apply custom overwrites
    apply_overwrites
}

function apply_overwrites {
    local overwrites_dir="$SCRIPT_DIR/../backups/src_overwrites/${WORDPRESS_INSTALL_VERSION}"
    local src_dir="$SCRIPT_DIR/../src"
    
    echo
    color "cyan" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    color "bright_cyan" "Applying Custom Overwrites"
    color "cyan" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if overwrites directory exists
    if [[ ! -d "$overwrites_dir" ]]; then
        color "yellow" "⚠ No overwrites directory found for version $WORDPRESS_INSTALL_VERSION"
        color "white" "Expected location: $overwrites_dir"
        color "white" "Skipping overwrites..."
        return 0
    fi
    
    color "white" "Overwrites directory: $overwrites_dir"
    
    # Count files to be copied
    local file_count=$(find "$overwrites_dir" -type f | wc -l)
    
    if [[ $file_count -eq 0 ]]; then
        color "yellow" "⚠ No files found in overwrites directory"
        return 0
    fi
    
    color "white" "Found $file_count file(s) to copy"
    echo
    
    # Copy files while preserving directory structure
    local copied_count=0
    local failed_count=0
    
    # Use find to get all files in overwrites directory
    while IFS= read -r -d '' file; do
        # Get relative path from overwrites directory
        local rel_path="${file#$overwrites_dir/}"
        local dest_file="$src_dir/$rel_path"
        local dest_dir=$(dirname "$dest_file")
        
        # Create destination directory if it doesn't exist
        if [[ ! -d "$dest_dir" ]]; then
            mkdir -p "$dest_dir"
        fi
        
        # Copy file
        if cp "$file" "$dest_file"; then
            color "green" "  ✓ $rel_path"
            ((copied_count++))
        else
            color "red" "  ✗ Failed to copy: $rel_path"
            ((failed_count++))
        fi
        
    done < <(find "$overwrites_dir" -type f -print0)
    
    echo
    color "cyan" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ $failed_count -eq 0 ]]; then
        color "bright_green" "✓ Successfully copied $copied_count file(s)"
    else
        color "yellow" "⚠ Copied $copied_count file(s), $failed_count failed"
    fi
    
    color "cyan" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

main "$@"