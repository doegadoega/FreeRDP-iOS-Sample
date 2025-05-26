#!/bin/bash

# FreeRDP iOS App Build Script - Requirements Check
# This script checks if all requirements are met

# Load common functions and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Record script start
log_script_start

# Main function
check_requirements() {
    log_info "Checking build requirements..."
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        handle_error "Xcode is not installed or not in PATH. Please install Xcode from the App Store"
    fi
    
    # Check Xcode version
    XCODE_VERSION=$(xcodebuild -version | head -n1 | cut -d' ' -f2)
    log_info "Xcode version: $XCODE_VERSION"
    
    # Check CMake
    if ! command -v cmake &> /dev/null; then
        log_warning "CMake is not installed"
        log_info "CMake will be built from source during the build process"
    fi
    
    # Check CMake version if installed
    if command -v cmake &> /dev/null; then
        CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
        log_info "CMake version: $CMAKE_VERSION"
        
        # バージョン比較のデバッグ情報
        log_info "Comparing CMake version $CMAKE_VERSION with minimum required $CMAKE_MIN_VERSION"
        
        # Compare CMake versions
        version_compare "$CMAKE_VERSION" "$CMAKE_MIN_VERSION"
        COMPARE_RESULT=$?
        log_info "Version compare result: $COMPARE_RESULT (0=equal, 1=greater, 2=less)"
        
        if [ $COMPARE_RESULT -eq 2 ]; then
            log_warning "CMake version $CMAKE_VERSION は古すぎます。ビルド時に最新版が自動的にインストールされます"
        fi
    fi
    
    # Check CocoaPods
    if ! command -v pod &> /dev/null; then
        log_warning "CocoaPods is not installed. Installing..."
        if command -v gem &> /dev/null; then
            sudo gem install cocoapods
        else
            handle_error "Ruby gems not available. Please install CocoaPods manually"
        fi
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        handle_error "Git is not installed. Please install Git from: https://git-scm.com/download/mac"
    fi
    
    log_success "All requirements satisfied"
    return 0
}

# Run the main function
check_requirements

# Record script end
log_script_end 