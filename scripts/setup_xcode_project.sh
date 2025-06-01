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
        
    # Remove old project if it exists
    if [ -d "MyRDPApp/Project/MyRDPApp.xcodeproj" ]; then
        log_info "Removing existing Xcode project..."
        rm -rf MyRDPApp/Project/MyRDPApp.xcodeproj
    fi
        
    # Generate project using XcodeGen
    log_info "Generating project with XcodeGen..."
    cd "$XCODE_PROJECT_DIR"
    xcodegen generate
    
    log_success "Xcode project setup completed"
    return 0
}

# Run the main function
setup_xcode_project

# Record script end
log_script_end 