#!/bin/bash

# FreeRDP iOS App Build Script - Setup Directories
# This script sets up the required directories

# Load common functions and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Record script start
log_script_start

# Main function
setup_directories() {
    log_info "Setting up build directories..."
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$EXTERNAL_DIR"
    
    log_success "Directories created"
    return 0
}

# Run the main function
setup_directories

# Record script end
log_script_end 