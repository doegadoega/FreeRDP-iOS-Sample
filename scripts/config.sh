#!/bin/bash

# FreeRDP iOS App 共通設定ファイル
# このファイルはプロジェクト全体で使用される共通の変数や設定を定義します

# プロジェクトのルートディレクトリを一度だけ設定
if [ -z "$PROJECT_ROOT" ]; then
    # スクリプトの場所に基づいてプロジェクトルートを決定
    if [[ "${BASH_SOURCE[0]}" == */scripts/* ]]; then
        # scriptsディレクトリ内から呼び出された場合
        PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    else
        # ルートディレクトリから呼び出された場合
        PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi
fi

# ディレクトリ設定
BUILD_DIR="${PROJECT_ROOT}/build"
EXTERNAL_DIR="${PROJECT_ROOT}/iOSApp/Libraries"

# バージョン設定（統一）
CMAKE_VERSION="v3.28.3"
CMAKE_MIN_VERSION="3.13"
FREERDP_VERSION="3.15.0"
OPENSSL_VERSION="3.4.0"
FFMPEG_VERSION="release/6.1"
OPENH264_VERSION="2.4.0"
IOS_MIN_VERSION="16.0"

# リポジトリURL
FREERDP_REPO="https://github.com/FreeRDP/FreeRDP.git"
OPENSSL_REPO="https://github.com/openssl/openssl.git"

# ビルド関連ディレクトリ
CMAKE_BUILD_DIR="${BUILD_DIR}/cmake"
CMAKE_INSTALL_DIR="${BUILD_DIR}/cmake-install"

# FreeRDP関連ディレクトリ（build配下でビルド）
FREERDP_BUILD_DIR="${BUILD_DIR}/freerdp"
FREERDP_INSTALL_DIR="${EXTERNAL_DIR}/freerdp-device"
FREERDP_SIM_INSTALL_DIR="${EXTERNAL_DIR}/freerdp-simulator"

# OpenSSL関連ディレクトリ
OPENSSL_DIR="${EXTERNAL_DIR}/openssl"
OPENSSL_SIM_DIR="${EXTERNAL_DIR}/openssl-simulator"

# FFmpeg関連ディレクトリ
FFMPEG_BUILD_DIR="${BUILD_DIR}/freerdp/FFmpeg"
FFMPEG_INSTALL_DIR="${BUILD_DIR}/freerdp/ffmpeg-install"

# OpenH264関連ディレクトリ
OPENH264_BUILD_DIR="${BUILD_DIR}/freerdp/openh264"
OPENH264_INSTALL_DIR="${BUILD_DIR}/freerdp/openh264-install"

# iOS SDK設定
IOS_SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || echo "")
IOS_SIM_SDK_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path 2>/dev/null || echo "")

# Xcodeプロジェクト関連パス
XCODE_PROJECT_DIR="${PROJECT_ROOT}/iOSApp"
XCODE_PROJECT_NAME="MyRDPApp"
XCODEPROJ_PATH="${XCODE_PROJECT_DIR}/${XCODE_PROJECT_NAME}.xcodeproj"
XCWORKSPACE_PATH="${XCODE_PROJECT_DIR}/${XCODE_PROJECT_NAME}.xcworkspace"

# RDPディレクトリパス
RDP_DIR="${XCODE_PROJECT_DIR}/${XCODE_PROJECT_NAME}/RDP"

# ===============================
# 共通ユーティリティ関数
# ===============================

# ログ関数（カラー出力対応）
log_info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# スクリプト開始/終了ログ
log_script_start() {
    log_info "スクリプト開始: $(basename "${BASH_SOURCE[1]}")"
    log_info "開始時刻: $(date '+%Y-%m-%d %H:%M:%S')"
}

log_script_end() {
    log_info "スクリプト完了: $(basename "${BASH_SOURCE[1]}")"
    log_info "終了時刻: $(date '+%Y-%m-%d %H:%M:%S')"
}

# エラーハンドリング
handle_error() {
    log_error "$1"
    exit 1
}

# バージョン比較関数
version_compare() {
    local version1="$1"
    local version2="$2"
    
    # Remove 'v' prefix if present
    version1="${version1#v}"
    version2="${version2#v}"
    
    if [[ "$version1" == "$version2" ]]; then
        return 0  # equal
    fi
    
    local sorted_versions
    sorted_versions=$(printf '%s\n%s\n' "$version1" "$version2" | sort -V)
    
    if [[ $(echo "$sorted_versions" | head -n1) == "$version1" ]]; then
        return 2  # version1 < version2
    else
        return 1  # version1 > version2
    fi
}

# ディレクトリ作成関数
create_build_directories() {
    log_info "ビルドディレクトリを作成しています..."
    mkdir -p "$BUILD_DIR"
    mkdir -p "$EXTERNAL_DIR"
    mkdir -p "$CMAKE_BUILD_DIR"
    mkdir -p "$FREERDP_BUILD_DIR"
    mkdir -p "$FREERDP_INSTALL_DIR"
    mkdir -p "$FREERDP_SIM_INSTALL_DIR"
    mkdir -p "$OPENSSL_DIR"
    mkdir -p "$OPENSSL_SIM_DIR"
    log_success "ディレクトリ作成完了"
}

# 依存関係チェック関数
check_dependencies() {
    log_info "依存関係をチェックしています..."
    
    # Xcode
    if ! command -v xcodebuild &> /dev/null; then
        handle_error "Xcode is not installed or not in PATH. Please install Xcode from the App Store"
    fi
    
    # Git
    if ! command -v git &> /dev/null; then
        handle_error "Git is not installed. Please install Git from: https://git-scm.com/download/mac"
    fi
    
    # コアコマンド
    if ! command -v make &> /dev/null; then
        handle_error "make command not found. Please install Xcode Command Line Tools"
    fi
    
    log_success "依存関係チェック完了"
}

# 設定情報表示関数
show_config() {
    log_info "=== FreeRDP iOS App ビルド設定 ==="
    echo "プロジェクトルート: ${PROJECT_ROOT}"
    echo "ビルドディレクトリ: ${BUILD_DIR}"
    echo "外部ライブラリディレクトリ: ${EXTERNAL_DIR}"
    echo ""
    echo "=== バージョン情報 ==="
    echo "CMake: ${CMAKE_VERSION} (最小要求: ${CMAKE_MIN_VERSION})"
    echo "FreeRDP: ${FREERDP_VERSION}"
    echo "OpenSSL: ${OPENSSL_VERSION}"
    echo "iOS最小バージョン: ${IOS_MIN_VERSION}"
    echo ""
    echo "=== パス情報 ==="
    echo "Xcodeプロジェクト: ${XCODEPROJ_PATH}"
    echo "iOS SDK: ${IOS_SDK_PATH}"
    echo "iOS Simulator SDK: ${IOS_SIM_SDK_PATH}"
    echo "================================="
}

# 設定検証関数
validate_config() {
    local errors=0
    
    # 必須ディレクトリの存在確認
    if [[ ! -d "$PROJECT_ROOT" ]]; then
        log_error "プロジェクトルートディレクトリが見つかりません: $PROJECT_ROOT"
        ((errors++))
    fi
    
    # iOS SDKの存在確認
    if [[ -z "$IOS_SDK_PATH" ]]; then
        log_error "iOS SDKが見つかりません。Xcodeが正しくインストールされているか確認してください"
        ((errors++))
    fi
    
    if [[ -z "$IOS_SIM_SDK_PATH" ]]; then
        log_error "iOS Simulator SDKが見つかりません。Xcodeが正しくインストールされているか確認してください"
        ((errors++))
    fi
    
    if [[ $errors -gt 0 ]]; then
        handle_error "設定検証でエラーが発生しました。上記のエラーを修正してください。"
    fi
    
    log_success "設定検証完了"
}

# このスクリプトが直接実行された場合の処理
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_config
    validate_config
fi