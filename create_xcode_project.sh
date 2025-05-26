#!/bin/bash

# Xcode Project Creation Script for MyRDPApp
# This script creates a new Xcode project and sets up all necessary files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="MyRDPApp"
BUNDLE_ID="com.example.MyRDPApp"
ORGANIZATION_NAME="MyRDPApp"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode is not installed or not in PATH"
        exit 1
    fi
    
    log_info "Xcode version: $(xcodebuild -version | head -n1)"
}

cleanup_existing() {
    log_info "Cleaning up existing project files..."
    
    if [ -d "${PROJECT_NAME}.xcodeproj" ]; then
        rm -rf "${PROJECT_NAME}.xcodeproj"
        log_info "Removed existing .xcodeproj"
    fi
    
    if [ -d "${PROJECT_NAME}.xcworkspace" ]; then
        rm -rf "${PROJECT_NAME}.xcworkspace"
        log_info "Removed existing .xcworkspace"
    fi
    
    if [ -d "Pods" ]; then
        rm -rf "Pods"
        log_info "Removed existing Pods directory"
    fi
    
    if [ -f "Podfile.lock" ]; then
        rm "Podfile.lock"
        log_info "Removed existing Podfile.lock"
    fi
}

create_project_structure() {
    log_info "Creating Xcode project manually..."
    
    log_info "Please follow these steps to create a new Xcode project:"
    log_info "1. Open Xcode"
    log_info "2. Select 'Create a new Xcode project'"
    log_info "3. Choose 'App' template under iOS"
    log_info "4. Set Product Name to 'MyRDPApp'"
    log_info "5. Set Organization Identifier to 'com.example'"
    log_info "6. Set Language to 'Swift'"
    log_info "7. Set Interface to 'Storyboard'"
    log_info "8. Set Life Cycle to 'UIKit App Delegate'"
    log_info "9. Uncheck all test-related options"
    log_info "10. Choose a location to save the project (use the current directory)"
    
    # Open Xcode
    open -a Xcode
    
    log_info "After creating the project, you need to:"
    log_info "1. Add existing source files from the MyRDPApp directory"
    log_info "2. Configure the Bridging Header"
    log_info "3. Set up library search paths and other build settings"
    
    # Wait for user confirmation
    read -p "Press Enter once you've created the project in Xcode..." 
    
    if [ -d "${PROJECT_NAME}.xcodeproj" ]; then
        log_success "Xcode project created successfully!"
    else
        log_error "Could not find ${PROJECT_NAME}.xcodeproj. Please make sure you created the project with the correct name."
        exit 1
    fi
}

setup_existing_project() {
    log_info "Setting up existing Xcode project..."
    
    if [ ! -d "${PROJECT_NAME}.xcodeproj" ]; then
        log_error "Xcode project not found. Please create it first using Xcode GUI."
        log_info "See XCODE_SETUP.md for detailed instructions."
        exit 1
    fi
    
    # Check if MyRDPApp directory exists
    if [ ! -d "${PROJECT_NAME}" ]; then
        log_error "${PROJECT_NAME} directory not found"
        exit 1
    fi
    
    log_success "Project structure verified"
}

install_dependencies() {
    log_info "Installing CocoaPods dependencies..."
    
    if [ ! -f "Podfile" ]; then
        log_error "Podfile not found"
        exit 1
    fi
    
    # Install CocoaPods if not installed
    if ! command -v pod &> /dev/null; then
        log_info "Installing CocoaPods..."
        sudo gem install cocoapods
    fi
    
    # Install dependencies
    pod install
    
    log_success "Dependencies installed"
}

verify_project() {
    log_info "Verifying project setup..."
    
    # Check if workspace was created
    if [ ! -d "${PROJECT_NAME}.xcworkspace" ]; then
        log_error "Workspace not found after pod install"
        exit 1
    fi
    
    # Try to build the project
    log_info "Testing project build..."
    xcodebuild -workspace "${PROJECT_NAME}.xcworkspace" \
               -scheme "${PROJECT_NAME}" \
               -destination 'platform=iOS Simulator,name=iPhone 14' \
               -configuration Debug \
               clean build > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "Project builds successfully"
    else
        log_warning "Project build failed - manual configuration may be needed"
        log_info "See XCODE_SETUP.md for troubleshooting"
    fi
}

open_project() {
    log_info "Opening project in Xcode..."
    
    if [ -d "${PROJECT_NAME}.xcworkspace" ]; then
        open "${PROJECT_NAME}.xcworkspace"
        log_success "Opened workspace in Xcode"
    else
        open "${PROJECT_NAME}.xcodeproj"
        log_success "Opened project in Xcode"
    fi
}

show_help() {
    echo "Xcode Project Creation Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  create    Create new Xcode project (requires manual steps)"
    echo "  setup     Setup existing Xcode project with dependencies"
    echo "  verify    Verify project setup and build"
    echo "  open      Open project in Xcode"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 create   # Start project creation process"
    echo "  $0 setup    # Setup existing project"
    echo "  $0 verify   # Verify project works"
    echo "  $0 open     # Open in Xcode"
}

# Main execution
case "${1:-help}" in
    "create")
        log_info "Starting Xcode project creation..."
        check_xcode
        cleanup_existing
        create_project_structure
        ;;
    "setup")
        log_info "Setting up existing Xcode project..."
        check_xcode
        setup_existing_project
        install_dependencies
        verify_project
        log_success "Project setup completed!"
        ;;
    "verify")
        log_info "Verifying project..."
        check_xcode
        verify_project
        ;;
    "open")
        open_project
        ;;
    "help")
        show_help
        ;;
    *)
        log_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
