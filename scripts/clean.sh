#!/bin/bash

# FreeRDP iOS App Build Script - Clean
# This script cleans all build artifacts

# Load common functions and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Record script start
log_script_start

# Main function
clean() {
    log_info "Cleaning build artifacts..."
    
    # Clean build directories
    if [ -d "${PROJECT_ROOT}/${BUILD_DIR}" ]; then
        log_info "Removing build directory..."
        rm -rf "${PROJECT_ROOT}/${BUILD_DIR}"
    fi
    
    # Clean external directories
    if [ -d "${PROJECT_ROOT}/${EXTERNAL_DIR}" ]; then
        log_info "Removing external directory..."
        rm -rf "${PROJECT_ROOT}/${EXTERNAL_DIR}"
    fi
    
    # Clean libraries
    if [ -d "${PROJECT_ROOT}/libs" ]; then
        log_info "Removing libs directory..."
        rm -rf "${PROJECT_ROOT}/libs"
    fi
    
    # Clean Xcode derived data
    if [ -d "${PROJECT_ROOT}/DerivedData" ]; then
        log_info "Removing DerivedData directory..."
        rm -rf "${PROJECT_ROOT}/DerivedData"
    fi
    
    # Clean CocoaPods
    if [ -f "${PROJECT_ROOT}/Podfile.lock" ]; then
        log_info "Removing Podfile.lock..."
        rm "${PROJECT_ROOT}/Podfile.lock"
    fi
    
    if [ -d "${PROJECT_ROOT}/Pods" ]; then
        log_info "Removing Pods directory..."
        rm -rf "${PROJECT_ROOT}/Pods"
    fi
    
    # Clean OpenSSL (古いパスの場合)
    if [ -d "${PROJECT_ROOT}/openssl-ios" ]; then
        log_info "Removing openssl-ios directory..."
        rm -rf "${PROJECT_ROOT}/openssl-ios"
    fi
    
    log_success "Clean completed"
    return 0
}

# Run the main function
clean

# Record script end
log_script_end 