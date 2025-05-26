#!/bin/bash

# FreeRDP iOS App Test Script
# This script helps test the FreeRDP iOS application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    log_error "Xcode is not installed or not in PATH"
    log_info "Please install Xcode from the App Store"
    exit 1
fi

# Check if the project exists
if [ ! -d "MyRDPApp.xcworkspace" ]; then
    log_warning "Xcode workspace not found"
    log_info "Generating Xcode project..."
    ./create_xcode_project.sh setup
fi

# Build the app
log_info "Building the app..."
xcodebuild -workspace MyRDPApp.xcworkspace -scheme MyRDPApp -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -configuration Debug build PRODUCT_BUNDLE_IDENTIFIER=com.example.MyRDPApp

if [ $? -ne 0 ]; then
    log_error "Build failed"
    exit 1
fi

log_success "Build completed successfully"

# Get the path to the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "MyRDPApp.app" -path "*/Build/Products/Debug-iphonesimulator/*" | head -n 1)

if [ -z "$APP_PATH" ]; then
    log_error "Could not find the built app"
    exit 1
fi

log_info "App built at: $APP_PATH"

# Fix Info.plist if needed
if ! /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_PATH/Info.plist" &>/dev/null; then
    log_warning "Bundle ID missing in Info.plist, adding it..."
    /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.example.MyRDPApp" "$APP_PATH/Info.plist"
fi

# Boot the simulator if it's not already running
SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 15" | grep "Booted" | awk -F'[()]' '{print $2}')

if [ -z "$SIMULATOR_ID" ]; then
    log_info "Booting iPhone 15 simulator..."
    SIMULATOR_ID=$(xcrun simctl list devices | grep "iPhone 15" | head -n 1 | awk -F'[()]' '{print $2}')
    xcrun simctl boot "$SIMULATOR_ID"
    sleep 5  # Wait for the simulator to boot
fi

# Install the app on the simulator
log_info "Installing the app on the simulator..."
xcrun simctl install booted "$APP_PATH"

# Launch the app
log_info "Launching the app..."
xcrun simctl launch booted com.example.MyRDPApp

log_success "App launched successfully"

# Show the logs
log_info "Showing app logs (press Ctrl+C to stop):"
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "MyRDPApp"' 