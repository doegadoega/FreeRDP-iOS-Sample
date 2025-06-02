#!/bin/bash

# FreeRDP iOS App Build Script - Build iOS Project
# This script builds the iOS project

# Load common functions and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Record script start
log_script_start

# Main function
build_project() {
    log_info "Building iOS project..."
    
    # Check if workspace exists
    if [ ! -d "${PROJECT_NAME}.xcworkspace" ]; then
        handle_error "Workspace not found. Run setup_xcode_project.sh first"
    fi
    
    # Build for simulator
    log_info "Building for iOS Simulator..."
    xcodebuild -workspace "${PROJECT_NAME}.xcworkspace" \
               -scheme "$PROJECT_NAME" \
               -destination 'platform=iOS Simulator,name=iPhone 14' \
               -configuration Debug \
               build
    
    if [ $? -ne 0 ]; then
        handle_error "Failed to build iOS project for simulator"
    fi
    
    log_success "Project build completed"
    return 0
}

# Run the main function
build_project

# Record script end
log_script_end 