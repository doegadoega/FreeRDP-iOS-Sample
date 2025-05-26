#!/bin/bash

# FreeRDP iOS App Build Script - Troubleshoot
# This script shows troubleshooting information

# Load common functions and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Record script start
log_script_start

# Main function
show_troubleshooting() {
    echo "FreeRDP iOS App Troubleshooting Guide"
    echo ""
    echo "Common Issues and Solutions:"
    echo ""
    
    echo "1. CMake Version Issues"
    echo "   Problem: Incompatible CMake version"
    echo "   Solution: Install CMake 3.13.0 or later"
    echo "     $ brew install cmake"
    echo ""
    
    echo "2. OpenSSL Build Fails"
    echo "   Problem: OpenSSL configuration or build fails"
    echo "   Solutions:"
    echo "     - Check iOS SDK path: $ xcrun --sdk iphoneos --show-sdk-path"
    echo "     - Ensure proper permissions in the build directory"
    echo "     - Try with a different OpenSSL version (edit scripts/common.sh)"
    echo ""
    
    echo "3. FreeRDP Build Fails"
    echo "   Problem: FreeRDP build fails with CMake errors"
    echo "   Solutions:"
    echo "     - Check OpenSSL paths"
    echo "     - Ensure iOS toolchain file exists"
    echo "     - Verify dependencies are correctly installed"
    echo ""
    
    echo "4. Xcode Project Generation Fails"
    echo "   Problem: XcodeGen fails to generate project"
    echo "   Solutions:"
    echo "     - Install or update XcodeGen: $ brew install xcodegen"
    echo "     - Check project.yml syntax"
    echo "     - Verify project directory permissions"
    echo ""
    
    echo "5. CocoaPods Issues"
    echo "   Problem: pod install fails"
    echo "   Solutions:"
    echo "     - Update CocoaPods: $ sudo gem install cocoapods"
    echo "     - Delete Podfile.lock and try again"
    echo "     - Check Podfile syntax"
    echo ""
    
    echo "6. Build Script Exits Without Error"
    echo "   Problem: Script exits without showing an error"
    echo "   Solution: Run individual steps to isolate the issue:"
    echo "     $ ./build.sh requirements"
    echo "     $ ./build.sh directories"
    echo "     $ ./build.sh download"
    echo "     $ ./build.sh openssl"
    echo "     $ ./build.sh freerdp"
    echo ""
    
    echo "For detailed logs, run scripts with output redirection:"
    echo "  $ ./build.sh deps > build.log 2>&1"
    echo ""
    
    echo "If all else fails, try cleaning everything and starting fresh:"
    echo "  $ ./build.sh clean"
    echo ""
    
    echo "For more help, check the documentation in docs/ directory."
}

# Run the main function
show_troubleshooting

# Record script end
log_script_end 