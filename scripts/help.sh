#!/bin/bash

# FreeRDP iOS App Build Script - Help
# This script shows help information

# Load common functions and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Record script start
log_script_start

# Main function
show_help() {
    echo "FreeRDP iOS App Build Script"
    echo ""
    echo "Usage: build.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  build         Build the complete project (default)"
    echo "  clean         Clean all build artifacts"
    echo "  deps          Build only dependencies (FreeRDP with iOS Native Security)"
    echo "  project       Build only the iOS project"
    echo "  xcode         Create Xcode project"
    echo "  help          Show this help message"
    echo "  requirements  Check build requirements"
    echo "  directories   Setup build directories"
    echo "  download      Download FreeRDP source code"
    echo "  openssl       Build OpenSSL"
    echo "  freerdp       Build FreeRDP"
    echo "  troubleshoot  Show troubleshooting information"
    echo ""
    echo "Examples:"
    echo "  ./build.sh build    # Full build"
    echo "  ./build.sh clean    # Clean everything"
    echo "  ./build.sh deps     # Build dependencies only"
    echo "  ./build.sh openssl  # Build only OpenSSL"
    echo "  ./build.sh download # Download FreeRDP only"
    echo ""
    echo "Script Directory Structure:"
    echo "  scripts/check_requirements.sh  - Check build requirements"
    echo "  scripts/setup_directories.sh   - Setup build directories"
    echo "  scripts/download_freerdp.sh    - Download FreeRDP source code"
    echo "  scripts/build_openssl.sh       - Build OpenSSL"
    echo "  scripts/build_freerdp.sh       - Build FreeRDP"
    echo "  scripts/setup_xcode_project.sh - Setup Xcode project"
    echo "  scripts/create_bridging_header.sh - Create bridging header"
    echo "  scripts/build_project.sh       - Build iOS project"
    echo "  scripts/clean.sh               - Clean build artifacts"
    echo "  scripts/help.sh                - Show help"
    echo "  scripts/troubleshoot.sh        - Show troubleshooting information"
    echo ""
    echo "For more information, see the documentation in docs/ directory."
}

# Run the main function
show_help

# Record script end
log_script_end 