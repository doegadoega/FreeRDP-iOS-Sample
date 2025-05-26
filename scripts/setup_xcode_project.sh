#!/bin/bash

# FreeRDP iOS App Build Script - Setup Xcode Project
# This script sets up the Xcode project

# Load common functions and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Record script start
log_script_start

# Log warning function
log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# XcodeGenのインストール
install_xcodegen() {
    log_info "XcodeGenをソースからビルドします..."
    
    # XcodeGenのビルドディレクトリ
    XCODEGEN_BUILD_DIR="${BUILD_DIR}/xcodegen"
    XCODEGEN_INSTALL_DIR="${EXTERNAL_DIR}/xcodegen"
    
    # ビルドディレクトリの作成
    mkdir -p "${XCODEGEN_BUILD_DIR}"
    cd "${XCODEGEN_BUILD_DIR}" || handle_error "ディレクトリの変更に失敗: ${XCODEGEN_BUILD_DIR}"
    
    # XcodeGenのクローン（既に存在する場合は更新）
    if [ -d "XcodeGen" ]; then
        log_info "XcodeGenリポジトリを更新します..."
        cd XcodeGen || handle_error "ディレクトリの変更に失敗: XcodeGen"
        git fetch --all
    else
        log_info "XcodeGenリポジトリをクローンします..."
        git clone https://github.com/yonaskolb/XcodeGen.git
        cd XcodeGen || handle_error "ディレクトリの変更に失敗: XcodeGen"
    fi
    
    # 最新の安定版をチェックアウト
    git checkout $(git describe --tags --abbrev=0)
    
    # ビルドとインストール
    log_info "XcodeGenをビルドします..."
    make install PREFIX="${XCODEGEN_INSTALL_DIR}"
    
    # パスを通す
    export PATH="${XCODEGEN_INSTALL_DIR}/bin:$PATH"
    
    # インストール確認
    if ! command -v xcodegen &> /dev/null; then
        handle_error "XcodeGenのインストールに失敗しました"
    fi
    
    XCODEGEN_VERSION=$(xcodegen version)
    log_success "XcodeGen $XCODEGEN_VERSION のインストールが完了しました"
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗しました"
}

# Main function
setup_xcode_project() {
    log_info "Creating Xcode project using XcodeGen..."
    
    # Check if XcodeGen is installed
    if ! command -v xcodegen &> /dev/null; then
        log_info "XcodeGenがインストールされていません。ソースからビルドします..."
        install_xcodegen
    fi
    
    # Create Project directory if it doesn't exist
    mkdir -p "MyRDPApp/Project"
    
    # Remove old project if it exists
    if [ -d "MyRDPApp/Project/MyRDPApp.xcodeproj" ]; then
        log_info "Removing existing Xcode project..."
        rm -rf MyRDPApp/Project/MyRDPApp.xcodeproj
    fi
    
    # Remove old workspace if it exists
    if [ -d "MyRDPApp/Project/MyRDPApp.xcworkspace" ]; then
        log_info "Removing existing Xcode workspace..."
        rm -rf MyRDPApp/Project/MyRDPApp.xcworkspace
    fi
    
    # Generate project using XcodeGen
    log_info "Generating project with XcodeGen..."
    cd "$XCODE_PROJECT_DIR"
    xcodegen generate
    
    if [ $? -ne 0 ]; then
        handle_error "Failed to generate Xcode project with XcodeGen"
    fi
    
    if [ -d "$XCODEPROJ_PATH" ]; then
        log_success "Xcode project created successfully!"
        log_info "Project location: $XCODEPROJ_PATH"
        
        # Install CocoaPods dependencies
        log_info "Installing CocoaPods dependencies..."
        pod install
        
        if [ $? -ne 0 ]; then
            handle_error "Failed to install CocoaPods dependencies"
        fi
        
        if [ -d "$XCWORKSPACE_PATH" ]; then
            log_success "CocoaPods dependencies installed successfully!"
            log_info "Workspace location: $XCWORKSPACE_PATH"
            log_info "Please open the workspace instead of the project file."
            
            # プロジェクトの最適化
            log_info "Optimizing project settings..."
            xcodebuild -workspace "${XCWORKSPACE_PATH}" \
                -scheme "${XCODE_PROJECT_NAME}" \
                -configuration Debug \
                -destination "platform=iOS Simulator,name=iPhone 15 Pro,OS=17.4" \
                clean build \
                ENABLE_BITCODE=NO \
                ONLY_ACTIVE_ARCH=NO \
                VALID_ARCHS=arm64 \
                IPHONEOS_DEPLOYMENT_TARGET=15.0 \
                SWIFT_VERSION=5.0 \
                SWIFT_OPTIMIZATION_LEVEL=-Onone \
                SWIFT_COMPILATION_MODE=debug \
                GCC_OPTIMIZATION_LEVEL=0 \
                DEBUG_INFORMATION_FORMAT=dwarf-with-dsym \
                ENABLE_STRICT_OBJC_MSGSEND=YES \
                ENABLE_TESTABILITY=YES \
                CLANG_ENABLE_MODULES=YES \
                CLANG_ENABLE_OBJC_ARC=YES \
                CLANG_ENABLE_OBJC_WEAK=YES \
                CLANG_WARN_DOCUMENTATION_COMMENTS=YES \
                CLANG_WARN_STRICT_PROTOTYPES=YES \
                CLANG_WARN_UNGUARDED_AVAILABILITY=YES_AGGRESSIVE \
                CLANG_WARN_UNREACHABLE_CODE=YES \
                GCC_NO_COMMON_BLOCKS=YES \
                GCC_WARN_64_TO_32_BIT_CONVERSION=YES \
                GCC_WARN_ABOUT_RETURN_TYPE=YES \
                GCC_WARN_UNDECLARED_SELECTOR=YES \
                GCC_WARN_UNINITIALIZED_AUTOS=YES_AGGRESSIVE \
                GCC_WARN_UNUSED_FUNCTION=YES \
                GCC_WARN_UNUSED_VARIABLE=YES || {
                log_warning "Failed to optimize project settings, but continuing anyway"
            }
        else
            handle_error "Failed to create Xcode workspace"
        fi
    else
        handle_error "Failed to create Xcode project"
    fi
    
    log_success "Xcode project setup completed"
    return 0
}

# Run the main function
setup_xcode_project

# Record script end
log_script_end 