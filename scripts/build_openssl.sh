#!/bin/bash

# OpenSSL 3.x iOS Build Script
set -e

# 共通設定の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# OpenSSL build configuration - 共通設定から取得
OPENSSL_VERSION_NUMBER="${OPENSSL_VERSION}"
OPENSSL_DIR_NAME="openssl-${OPENSSL_VERSION_NUMBER}"
OPENSSL_BUILD_DIR="${BUILD_DIR}/openssl"

# OpenSSLバージョンの確認
check_openssl_version() {
    log_info "OpenSSLのビルド情報を確認しています..."
    
    # システムにインストールされているOpenSSLのバージョンを表示（参考情報）
    if command -v openssl &> /dev/null; then
        local INSTALLED_VERSION=$(openssl version | cut -d' ' -f2)
        log_info "システムにインストールされているOpenSSLバージョン: $INSTALLED_VERSION (参考情報)"
    fi
    
    log_info "ビルドするOpenSSLバージョン: $OPENSSL_VERSION_NUMBER"
    log_info "このスクリプトはiOS向けにOpenSSL $OPENSSL_VERSION_NUMBER をソースからビルドします"
    log_info "出力先: ${OPENSSL_DIR} (実機用) / ${OPENSSL_SIM_DIR} (シミュレータ用)"
}

# OpenSSLリポジトリのクローンとチェックアウト
clone_openssl_repo() {
    log_info "OpenSSLリポジトリを準備しています..."
    
    # Create build directory if it doesn't exist
    mkdir -p "${OPENSSL_BUILD_DIR}"
    
    # Check if OpenSSL directory already exists
    if [ -d "${OPENSSL_BUILD_DIR}/openssl" ]; then
        log_info "OpenSSLディレクトリが既に存在します。更新します..."
        cd "${OPENSSL_BUILD_DIR}/openssl" || handle_error "ディレクトリの変更に失敗: ${OPENSSL_BUILD_DIR}/openssl"
        git fetch --all
    else
        log_info "OpenSSLリポジトリをクローンしています: ${OPENSSL_BUILD_DIR}/openssl..."
        cd "${OPENSSL_BUILD_DIR}" || handle_error "ディレクトリの変更に失敗: ${OPENSSL_BUILD_DIR}"
        git clone "${OPENSSL_REPO}" openssl
        cd openssl || handle_error "ディレクトリの変更に失敗: openssl"
    fi
    
    # Checkout specific version
    log_info "OpenSSLバージョン ${OPENSSL_VERSION_NUMBER} をチェックアウトしています..."
    git checkout "openssl-${OPENSSL_VERSION_NUMBER}" || git checkout "tags/openssl-${OPENSSL_VERSION_NUMBER}" || handle_error "OpenSSLバージョン ${OPENSSL_VERSION_NUMBER} のチェックアウトに失敗しました"
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗しました"
    log_success "OpenSSLリポジトリのクローンとバージョン ${OPENSSL_VERSION_NUMBER} のチェックアウトが完了しました"
}

# Record script start
log_script_start

# OpenSSLバージョンをチェック
check_openssl_version

# Create build directories
mkdir -p "${OPENSSL_DIR}"

# Clone OpenSSL repository
clone_openssl_repo

# Build for iOS
log_info "Building for iOS..."
cd "${OPENSSL_BUILD_DIR}/openssl" || handle_error "ディレクトリの変更に失敗: ${OPENSSL_BUILD_DIR}/openssl"
./Configure \
    ios64-cross \
    no-shared \
    no-tests \
    no-asm \
    no-weak-ssl-ciphers \
    no-ssl3 \
    no-ssl3-method \
    --prefix="${OPENSSL_DIR}" \
    --openssldir="${OPENSSL_DIR}" \
    -isysroot "${IOS_SDK_PATH}" \
    -miphoneos-version-min="${IOS_MIN_VERSION}"

make -j$(sysctl -n hw.ncpu)
make install_sw

# Build for iOS Simulator
log_info "Building for iOS Simulator..."
cd "${OPENSSL_BUILD_DIR}/openssl" || handle_error "ディレクトリの変更に失敗: ${OPENSSL_BUILD_DIR}/openssl"
./Configure \
    iossimulator-xcrun \
    no-shared \
    no-tests \
    no-asm \
    no-weak-ssl-ciphers \
    no-ssl3 \
    no-ssl3-method \
    --prefix="${OPENSSL_SIM_DIR}" \
    --openssldir="${OPENSSL_SIM_DIR}" \
    -isysroot "${IOS_SIM_SDK_PATH}" \
    -miphoneos-version-min="${IOS_MIN_VERSION}"

make -j$(sysctl -n hw.ncpu)
make install_sw

# Create universal binary
log_info "Note: Skipping universal binary creation as both device and simulator are arm64..."
# Universal binary creation is disabled since both iOS and Simulator are arm64 on Apple Silicon
# Simply keep both libraries in their separate directories

# Clean up
cd "${PROJECT_ROOT}"
# OpenSSLのソースコードは保持しておく（再ビルド時に使用）
log_info "OpenSSLのソースコードは ${OPENSSL_BUILD_DIR}/openssl に保持されています"

log_success "OpenSSL build completed!"
log_info "iOS device installation directory: ${OPENSSL_DIR}"
log_info "iOS simulator installation directory: ${OPENSSL_SIM_DIR}"

# Record script end
log_script_end 