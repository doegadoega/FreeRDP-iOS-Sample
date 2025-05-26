#!/bin/bash

# FreeRDP iOS App 共通設定ファイル
# このファイルはプロジェクト全体で使用される共通の変数や設定を定義します

# プロジェクトのルートディレクトリ
if [ -z "$PROJECT_ROOT" ]; then
    # このスクリプトが直接実行された場合、または他のスクリプトから呼び出された場合のパスを設定
    SCRIPT_PATH="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"
    PROJECT_ROOT="$( cd "$SCRIPT_PATH/.." ; pwd -P )"
fi

# ディレクトリ設定
BUILD_DIR="${PROJECT_ROOT}/build"
EXTERNAL_DIR="${PROJECT_ROOT}/iOSApp/Libraries"

# FreeRDP関連の設定
FREERDP_VERSION="3.15.0"
FREERDP_REPO="https://github.com/FreeRDP/FreeRDP.git"
FREERDP_BUILD_DIR="${BUILD_DIR}/freerdp"
FREERDP_INSTALL_DIR="${EXTERNAL_DIR}/freerdp"
FREERDP_SIM_INSTALL_DIR="${EXTERNAL_DIR}/freerdp-simulator"

# OpenSSL関連の設定
OPENSSL_VERSION="3.4.0"
OPENSSL_REPO="https://github.com/openssl/openssl.git"
OPENSSL_DIR="${EXTERNAL_DIR}/openssl"
OPENSSL_SIM_DIR="${EXTERNAL_DIR}/openssl-simulator"

# iOS SDK Configuration
IOS_MIN_VERSION="15.0"
IOS_SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
IOS_SIM_SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)

# Xcodeプロジェクト共通パス
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_PROJECT_DIR="$PROJECT_ROOT/iOSApp"
XCODE_PROJECT_NAME="MyRDPApp"
XCODEPROJ_PATH="$XCODE_PROJECT_DIR/$XCODE_PROJECT_NAME.xcodeproj"
XCWORKSPACE_PATH="$XCODE_PROJECT_DIR/$XCODE_PROJECT_NAME.xcworkspace"

# RDPディレクトリの共通パス変数
RDP_DIR="$XCODE_PROJECT_DIR/$XCODE_PROJECT_NAME/RDP"

# ログ関連の関数
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

log_script_start() {
    log_info "スクリプト開始: $(basename "$0")"
    log_info "開始時刻: $(date +%Y-%m-%d\ %H:%M:%S)"
}

log_script_end() {
    log_info "スクリプト完了: $(basename "$0")"
    log_info "終了時刻: $(date +%Y-%m-%d\ %H:%M:%S)"
}

handle_error() {
    log_error "$1"
    exit 1
}

# この設定ファイルが直接実行された場合は、設定内容を表示
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "FreeRDP iOS App 共通設定ファイル"
    log_info "プロジェクトルート: ${PROJECT_ROOT}"
    log_info "ビルドディレクトリ: ${BUILD_DIR}"
    log_info "外部ライブラリディレクトリ: ${EXTERNAL_DIR}"
    log_info "FreeRDPバージョン: ${FREERDP_VERSION}"
    log_info "OpenSSLバージョン: ${OPENSSL_VERSION}"
    log_info "iOS最小バージョン: ${IOS_MIN_VERSION}"
fi 