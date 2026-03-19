#!/bin/bash
#===============================================================================
# Font installer for ESPHome scripts
#===============================================================================
# Downloads TTF font files listed in fonts/requirements.txt
# Similar to pip install -r requirements.txt
#
# Usage:
#   ./install_fonts.sh          # Download all fonts
#   ./install_fonts.sh --check  # Check which fonts are missing
#
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FONTS_DIR="$SCRIPT_DIR/fonts"
REQUIREMENTS_FILE="$FONTS_DIR/requirements.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#-------------------------------------------------------------------------------
# Function to print colored messages
#-------------------------------------------------------------------------------
print_msg() {
    local color="$1"
    local msg="$2"
    echo -e "${color}${msg}${NC}"
}

#-------------------------------------------------------------------------------
# Function to download a font file
#-------------------------------------------------------------------------------
download_font() {
    local filename="$1"
    local url="$2"
    local dest="$FONTS_DIR/$filename"

    if [[ -f "$dest" ]]; then
        print_msg "$YELLOW" "  [SKIP] $filename (already exists)"
        return 0
    fi

    print_msg "$YELLOW" "  [DOWNLOAD] $filename"

    if curl -fsSL --retry 3 --retry-delay 2 -o "$dest" "$url"; then
        print_msg "$GREEN" "  [OK] $filename downloaded successfully"
        return 0
    else
        print_msg "$RED" "  [ERROR] Failed to download $filename"
        rm -f "$dest"  # Clean up failed download
        return 1
    fi
}

#-------------------------------------------------------------------------------
# Function to check which fonts are missing
#-------------------------------------------------------------------------------
check_fonts() {
    local missing=0

    print_msg "$YELLOW" "\nChecking font files..."

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Parse line: filename=URL
        local filename="${line%%=*}"
        local url="${line##*=}"

        local dest="$FONTS_DIR/$filename"
        if [[ -f "$dest" ]]; then
            print_msg "$GREEN" "  [OK] $filename"
        else
            print_msg "$RED" "  [MISSING] $filename"
            ((missing++))
        fi
    done < "$REQUIREMENTS_FILE"

    if [[ $missing -gt 0 ]]; then
        print_msg "$RED" "\n$missing font file(s) missing. Run this script to download them."
        return 1
    else
        print_msg "$GREEN" "\nAll fonts are present."
        return 0
    fi
}

#-------------------------------------------------------------------------------
# Main function
#-------------------------------------------------------------------------------
main() {
    local mode="install"

    # Parse arguments
    if [[ "${1:-}" == "--check" ]]; then
        mode="check"
    fi

    # Check if requirements file exists
    if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
        print_msg "$RED" "Error: requirements.txt not found at $REQUIREMENTS_FILE"
        exit 1
    fi

    # Check if fonts directory exists
    if [[ ! -d "$FONTS_DIR" ]]; then
        print_msg "$RED" "Error: fonts directory not found at $FONTS_DIR"
        exit 1
    fi

    print_msg "$GREEN" "=========================================="
    print_msg "$GREEN" "  ESPHome Font Installer"
    print_msg "$GREEN" "=========================================="

    if [[ "$mode" == "check" ]]; then
        check_fonts
        exit $?
    fi

    # Install mode - download fonts
    print_msg "$YELLOW" "\nDownloading fonts to: $FONTS_DIR"
    print_msg "$YELLOW" "Reading requirements from: $REQUIREMENTS_FILE\n"

    local failed=0
    local downloaded=0

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Parse line: filename=URL
        local filename="${line%%=*}"
        local url="${line##*=}"

        if download_font "$filename" "$url"; then
            ((downloaded++))
        else
            ((failed++))
        fi
    done < "$REQUIREMENTS_FILE"

    echo ""
    print_msg "$GREEN" "=========================================="
    print_msg "$GREEN" "  Summary"
    print_msg "$GREEN" "=========================================="
    print_msg "$GREEN" "  Downloaded: $downloaded"

    if [[ $failed -gt 0 ]]; then
        print_msg "$RED" "  Failed: $failed"
        exit 1
    else
        print_msg "$GREEN" "  Failed: 0"
        print_msg "$GREEN" "\nAll fonts downloaded successfully!"
    fi
}

# Run main function
main "$@"
