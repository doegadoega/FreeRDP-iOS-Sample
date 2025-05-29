#!/bin/bash

# FreeRDP for iOS build script
# 参照先: https://github.com/FreeRDP/FreeRDP/wiki/Build-on-macOS

# 共通設定の読み込み
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
source "${SCRIPT_PATH}/config.sh"

# CMakeが利用可能かチェック
check_cmake() {
    log_info "CMakeが利用可能か確認しています..."
    
    # CMakeのビルドディレクトリ
    CMAKE_BUILD_DIR="${BUILD_DIR}/cmake"
    CMAKE_INSTALL_DIR="${EXTERNAL_DIR}/cmake"
    
    # CMakeが既にインストールされているかチェック
    if command -v cmake &> /dev/null; then
        CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
        log_info "システムにインストールされているCMakeバージョン: $CMAKE_VERSION"
        
        # バージョンチェック（3.13以上が必要）
        if [ "$(printf '%s\n' "3.13" "$CMAKE_VERSION" | sort -V | head -n1)" = "3.13" ]; then
            log_success "CMakeのバージョン要件を満たしています"
            return 0
        fi
    fi
    
    # CMakeのビルドとインストール
    log_info "CMakeをソースからビルドします..."
    
    # ビルドディレクトリの作成
    mkdir -p "${CMAKE_BUILD_DIR}"
    cd "${CMAKE_BUILD_DIR}" || handle_error "ディレクトリの変更に失敗: ${CMAKE_BUILD_DIR}"
    
    # CMakeのクローン（既に存在する場合は更新）
    if [ -d "cmake" ]; then
        log_info "CMakeリポジトリを更新します..."
        cd cmake || handle_error "ディレクトリの変更に失敗: cmake"
        git fetch --all
    else
        log_info "CMakeリポジトリをクローンします..."
        git clone https://github.com/Kitware/CMake.git
        cd cmake || handle_error "ディレクトリの変更に失敗: cmake"
    fi
    
    # 最新の安定版をチェックアウト
    git checkout $(git describe --tags --abbrev=0)
    
    # ビルドとインストール
    log_info "CMakeをビルドします..."
    ./bootstrap --prefix="${CMAKE_INSTALL_DIR}" --parallel=$(sysctl -n hw.ncpu)
    make -j$(sysctl -n hw.ncpu)
    make install
    
    # パスを通す
    export PATH="${CMAKE_INSTALL_DIR}/bin:$PATH"
    
    # インストール確認
    if ! command -v cmake &> /dev/null; then
        handle_error "CMakeのインストールに失敗しました"
    fi
    
    CMAKE_VERSION=$(cmake --version | head -n1 | cut -d' ' -f3)
    log_success "CMake $CMAKE_VERSION のインストールが完了しました"
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗しました"
}

# FreeRDPリポジトリのクローン
clone_freerdp_repo() {
    log_info "FreeRDPリポジトリを準備しています..."
    
    # ビルドディレクトリが存在するか確認
    mkdir -p "${FREERDP_BUILD_DIR}"
    mkdir -p "${EXTERNAL_DIR}"
    
    # FreeRDPディレクトリが既に存在するか確認（EXTERNALディレクトリの場合）
    if [ -d "${EXTERNAL_DIR}/FreeRDP" ]; then
        log_info "FreeRDPソースコードは既に${EXTERNAL_DIR}/FreeRDPに存在します"
        
        # CMakeLists.txtの存在確認
        if [ ! -f "${EXTERNAL_DIR}/FreeRDP/CMakeLists.txt" ]; then
            log_warning "EXTERNALディレクトリのFreeRDPソースコードが不完全です。再クローンします..."
            rm -rf "${EXTERNAL_DIR}/FreeRDP"
            cd "${EXTERNAL_DIR}" || handle_error "ディレクトリの変更に失敗: ${EXTERNAL_DIR}"
            git clone --depth 1 --branch "${FREERDP_VERSION}" "${FREERDP_REPO}" FreeRDP || handle_error "FreeRDPリポジトリのクローンに失敗しました"
        fi
        
        # ビルドディレクトリにFreeRDPソースをコピー
        log_info "ビルドディレクトリにFreeRDPソースをコピーします..."
        rm -rf "${FREERDP_BUILD_DIR}/FreeRDP"
        cp -R "${EXTERNAL_DIR}/FreeRDP" "${FREERDP_BUILD_DIR}/"
        
    # ビルドディレクトリに既に存在するか確認
    elif [ -d "${FREERDP_BUILD_DIR}/FreeRDP" ]; then
        log_info "FreeRDPディレクトリが既にビルドディレクトリに存在します。更新します..."
        cd "${FREERDP_BUILD_DIR}/FreeRDP" || handle_error "ディレクトリの変更に失敗: ${FREERDP_BUILD_DIR}/FreeRDP"
        git fetch --all
    
    # どちらにも存在しない場合は新規クローン
    else
        log_info "FreeRDPリポジトリをクローンしています..."
        cd "${FREERDP_BUILD_DIR}" || handle_error "ディレクトリの変更に失敗: ${FREERDP_BUILD_DIR}"
        git clone --depth 1 --branch "${FREERDP_VERSION}" "${FREERDP_REPO}" FreeRDP || handle_error "FreeRDPリポジトリのクローンに失敗しました"
        
        # EXTERNALディレクトリにも同じソースをコピー
        log_info "EXTERNALディレクトリにFreeRDPソースをコピーします..."
        cp -R "${FREERDP_BUILD_DIR}/FreeRDP" "${EXTERNAL_DIR}/"
    fi
    
    # CMakeLists.txtの存在確認
    if [ ! -f "${FREERDP_BUILD_DIR}/FreeRDP/CMakeLists.txt" ]; then
        handle_error "FreeRDPのソースコードが正しくコピーされていません。CMakeLists.txtが見つかりません。"
    fi
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗しました"
    log_success "FreeRDPリポジトリの準備が完了しました"
}

# Record script start
log_script_start

# CMakeをチェック
check_cmake

# Create build directories
mkdir -p "${FREERDP_INSTALL_DIR}"

# Clone FreeRDP repository
clone_freerdp_repo

# Clean previous build directories if they exist
log_info "古いビルドディレクトリをクリーンアップしています..."
rm -rf "${FREERDP_BUILD_DIR}/ios"
rm -rf "${FREERDP_BUILD_DIR}/ios-sim"

# FreeRDPのビルド設定
# ====================
# このスクリプトでは2つの異なるビルドターゲットに対してFreeRDPをビルドします：
# 1. 実機向けビルド（OS）
# 2. シミュレータ向けビルド（SIMULATOR）
#
# 主要な設定項目：
# ----------------
# 1. 基本設定
#    - CMAKE_TOOLCHAIN_FILE: iOS用のツールチェイン
#    - CMAKE_BUILD_TYPE: リリースビルド
#    - CMAKE_OSX_DEPLOYMENT_TARGET: 最小iOSバージョン
#
# 2. OpenSSL関連設定
#    - OPENSSL_ROOT_DIR: OpenSSLのルートディレクトリ
#    - OPENSSL_INCLUDE_DIR: インクルードディレクトリ
#    - OPENSSL_CRYPTO_LIBRARY: 暗号化ライブラリ
#    - OPENSSL_SSL_LIBRARY: SSLライブラリ
#
# 3. プラットフォーム設定
#    - PLATFORM: OS（実機）またはSIMULATOR（シミュレータ）
#
# 4. 機能の有効/無効化
#    - WITH_CLIENT_CHANNELS: クライアントチャネル有効
#    - WITH_SERVER_CHANNELS: サーバーチャネル有効
#    - WITH_CLIENT: クライアント機能有効
#    - WITH_SERVER: サーバー機能無効
#    - WITH_CLIENT_IOS: iOSクライアント無効（独自実装のため）
#
# 5. 不要な機能の無効化
#    - WITH_JPEG: JPEGサポート無効
#    - WITH_MANPAGES: マニュアルページ無効
#    - WITH_PULSE: PulseAudio無効
#    - WITH_CUPS: CUPS無効
#    - WITH_FFMPEG: FFmpeg無効
#    - WITH_OPUS: Opus無効
#    - WITH_LAME: LAME無効
#    - WITH_FAAD2: FAAD2無効
#    - WITH_FAAC: FAAC無効
#    - WITH_SOXR: SOXR無効
#
# 重要なポイント：
# --------------
# 1. 最小限の機能セット
#    - 必要最小限の機能のみを有効化
#    - 不要な依存関係を排除
#
# 2. 静的リンク
#    - BUILD_SHARED_LIBS=OFFで静的リンクを指定
#    - アプリに直接組み込むため
#
# 3. プラットフォーム別ビルド
#    - 実機用とシミュレータ用で別々にビルド
#    - それぞれの環境に最適化されたバイナリを生成

# Build for iOS
log_info "Building FreeRDP for iOS..."
mkdir -p "${FREERDP_BUILD_DIR}/ios"
cd "${FREERDP_BUILD_DIR}/ios" || handle_error "ディレクトリの変更に失敗: ${FREERDP_BUILD_DIR}/ios"

cmake "../FreeRDP" \
    -DCMAKE_TOOLCHAIN_FILE="../FreeRDP/cmake/ios.toolchain.cmake" \
    -DCMAKE_INSTALL_PREFIX="${FREERDP_INSTALL_DIR}" \
    -DCMAKE_PREFIX_PATH="${OPENSSL_DIR}" \
    -DOPENSSL_ROOT_DIR="${OPENSSL_DIR}" \
    -DOPENSSL_INCLUDE_DIR="${OPENSSL_DIR}/include" \
    -DOPENSSL_CRYPTO_LIBRARY="${OPENSSL_DIR}/lib/libcrypto.a" \
    -DOPENSSL_SSL_LIBRARY="${OPENSSL_DIR}/lib/libssl.a" \
    -DAPPLE=ON \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${IOS_MIN_VERSION}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPLATFORM=OS \
    -DWITH_CLIENT_CHANNELS=ON \
    -DWITH_SERVER_CHANNELS=ON \
    -DCHANNEL_URBDRC=OFF \
    -DWITH_OPENSSL=ON \
    -DWITH_CLIENT=ON \
    -DWITH_SERVER=OFF \
    -DWITH_SAMPLE=OFF \
    -DWITH_JPEG=ON \
    -DWITH_MANPAGES=OFF \
    -DWITH_PULSE=OFF \
    -DWITH_CUPS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_FFMPEG=OFF \
    -DWITH_DSP_FFMPEG=OFF \
    -DWITH_SWSCALE=OFF \
    -DWITH_OPUS=OFF \
    -DWITH_LAME=OFF \
    -DWITH_FAAD2=OFF \
    -DWITH_FAAC=OFF \
    -DWITH_SOXR=OFF \
    -DWITH_CLIENT_IOS=OFF \
    -DWITH_GDI=ON \
    -DCHANNEL_DISPLAY=ON \
    -DCHANNEL_GRAPHICS=ON \

# Build
cmake --build . --config Release || handle_error "FreeRDPのビルドに失敗しました"

# Install
cmake --install . || handle_error "FreeRDPのインストールに失敗しました"

# Build for iOS Simulator
log_info "Building FreeRDP for iOS Simulator..."
mkdir -p "${FREERDP_BUILD_DIR}/ios-sim"
cd "${FREERDP_BUILD_DIR}/ios-sim" || handle_error "ディレクトリの変更に失敗: ${FREERDP_BUILD_DIR}/ios-sim"

mkdir -p "${FREERDP_SIM_INSTALL_DIR}"

# シミュレータ向けビルド設定
# ========================
# 実機向けビルドとほぼ同じ設定ですが、以下の点が異なります：
#
# 1. インストール先
#    - CMAKE_INSTALL_PREFIX: シミュレータ用のインストールディレクトリ
#
# 2. OpenSSL設定
#    - シミュレータ用のOpenSSLライブラリを参照
#    - OPENSSL_ROOT_DIR: シミュレータ用OpenSSLディレクトリ
#    - OPENSSL_INCLUDE_DIR: シミュレータ用インクルードディレクトリ
#    - OPENSSL_CRYPTO_LIBRARY: シミュレータ用暗号化ライブラリ
#    - OPENSSL_SSL_LIBRARY: シミュレータ用SSLライブラリ
#
# 3. プラットフォーム設定
#    - PLATFORM=SIMULATOR: シミュレータ向けビルドを指定
#
# その他の設定（機能の有効/無効化など）は実機向けと同じです。

cmake "../FreeRDP" \
    -DCMAKE_TOOLCHAIN_FILE="../FreeRDP/cmake/ios.toolchain.cmake" \
    -DCMAKE_INSTALL_PREFIX="${FREERDP_SIM_INSTALL_DIR}" \
    -DCMAKE_PREFIX_PATH="${OPENSSL_SIM_DIR}" \
    -DOPENSSL_ROOT_DIR="${OPENSSL_SIM_DIR}" \
    -DOPENSSL_INCLUDE_DIR="${OPENSSL_SIM_DIR}/include" \
    -DOPENSSL_CRYPTO_LIBRARY="${OPENSSL_SIM_DIR}/lib/libcrypto.a" \
    -DOPENSSL_SSL_LIBRARY="${OPENSSL_SIM_DIR}/lib/libssl.a" \
    -DAPPLE=ON \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${IOS_MIN_VERSION}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPLATFORM=SIMULATOR \
    -DWITH_CLIENT_CHANNELS=ON \
    -DWITH_SERVER_CHANNELS=ON \
    -DCHANNEL_URBDRC=OFF \
    -DWITH_OPENSSL=ON \
    -DWITH_CLIENT=ON \
    -DWITH_SERVER=OFF \
    -DWITH_SAMPLE=OFF \
    -DWITH_JPEG=OFF \
    -DWITH_MANPAGES=OFF \
    -DWITH_PULSE=OFF \
    -DWITH_CUPS=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_FFMPEG=OFF \
    -DWITH_DSP_FFMPEG=OFF \
    -DWITH_SWSCALE=OFF \
    -DWITH_OPUS=OFF \
    -DWITH_LAME=OFF \
    -DWITH_FAAD2=OFF \
    -DWITH_FAAC=OFF \
    -DWITH_SOXR=OFF \
    -DWITH_CLIENT_IOS=OFF

# Build
cmake --build . --config Release || handle_error "FreeRDP（シミュレータ）のビルドに失敗しました"

# Install
cmake --install . || handle_error "FreeRDP（シミュレータ）のインストールに失敗しました"

# Clean up
cd "${PROJECT_ROOT}"
# FreeRDPのソースコードは保持しておく（再ビルド時に使用）
log_info "FreeRDPのソースコードは ${FREERDP_BUILD_DIR}/FreeRDP に保持されています"

# ライブラリファイルを適切なディレクトリにコピー
log_info "ビルドしたライブラリファイルをXcodeインポート用ディレクトリにコピーしています..."

# # デバイス用ライブラリをコピー
# log_info "デバイス用ライブラリを ${FREERDP_INSTALL_DIR} にコピーしています..."
# mkdir -p "${FREERDP_INSTALL_DIR}/include"
# mkdir -p "${FREERDP_INSTALL_DIR}/lib"

# # freerdp3とwinpr3のライブラリとヘッダーをコピー
# cp -R "${FREERDP_INSTALL_DIR}/include/freerdp3" "${FREERDP_INSTALL_DIR}/include/"
# cp -R "${FREERDP_INSTALL_DIR}/include/winpr3" "${FREERDP_INSTALL_DIR}/include/"
# cp -R "${FREERDP_INSTALL_DIR}/lib/libfreerdp3.a" "${FREERDP_INSTALL_DIR}/lib/" 2>/dev/null || :
# cp -R "${FREERDP_INSTALL_DIR}/lib/libwinpr3.a" "${FREERDP_INSTALL_DIR}/lib/" 2>/dev/null || :
# # 必要に応じて他のライブラリもコピー
# find "${FREERDP_INSTALL_DIR}/lib" -name "*.a" -exec cp {} "${EXTERNAL_DIR}/freerdp/lib/" \; 2>/dev/null || :

# # シミュレータ用ライブラリをコピー
# log_info "シミュレータ用ライブラリを ${EXTERNAL_DIR}/freerdp-simulator にコピーしています..."
# mkdir -p "${EXTERNAL_DIR}/freerdp-simulator/include"
# mkdir -p "${EXTERNAL_DIR}/freerdp-simulator/lib"

# # freerdp3とwinpr3のライブラリとヘッダーをコピー
# cp -R "${FREERDP_SIM_INSTALL_DIR}/include/freerdp3" "${EXTERNAL_DIR}/freerdp-simulator/include/"
# cp -R "${FREERDP_SIM_INSTALL_DIR}/include/winpr3" "${EXTERNAL_DIR}/freerdp-simulator/include/"
# cp -R "${FREERDP_SIM_INSTALL_DIR}/lib/libfreerdp3.a" "${EXTERNAL_DIR}/freerdp-simulator/lib/" 2>/dev/null || :
# cp -R "${FREERDP_SIM_INSTALL_DIR}/lib/libwinpr3.a" "${EXTERNAL_DIR}/freerdp-simulator/lib/" 2>/dev/null || :
# # 必要に応じて他のライブラリもコピー
# find "${FREERDP_SIM_INSTALL_DIR}/lib" -name "*.a" -exec cp {} "${EXTERNAL_DIR}/freerdp-simulator/lib/" \; 2>/dev/null || :

log_success "FreeRDP build completed!"
log_info "iOS device installation directory: ${FREERDP_INSTALL_DIR}"
log_info "iOS simulator installation directory: ${FREERDP_SIM_INSTALL_DIR}"
log_info "Xcode import device directory: ${EXTERNAL_DIR}/freerdp"
log_info "Xcode import simulator directory: ${EXTERNAL_DIR}/freerdp-simulator"
log_info "FreeRDPのソースコードは ${FREERDP_BUILD_DIR}/FreeRDP に保持されています"

# Record script end
log_script_end 