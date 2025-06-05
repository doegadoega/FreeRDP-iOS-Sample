#!/bin/bash

# FreeRDP for iOS build script
# iOS向けFreeRDPのビルドスクリプト

set -e

# 共通設定の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# 引数の解析
TARGET="${1:-all}"

# ターゲットの妥当性チェック
validate_target() {
    case "$TARGET" in
        device|simulator|all) ;;
        *)
            log_error "無効なターゲット: $TARGET"
            log_info "有効なターゲット: device, simulator, all"
            exit 1
            ;;
    esac
}

# ヘルプ表示
show_help() {
    echo "FreeRDP iOS Build Script"
    echo ""
    echo "使用方法: $0 [TARGET]"
    echo ""
    echo "TARGET:"
    echo "  device     実機向けFreeRDPのみビルド"
    echo "  simulator  シミュレータ向けFreeRDPのみビルド"
    echo "  all        両方ビルド (デフォルト)"
    echo ""
    echo "例:"
    echo "  $0              # 両方ビルド"
    echo "  $0 device       # 実機向けのみ"
    echo "  $0 simulator    # シミュレータ向けのみ"
}

# CMakeの確認とインストール
ensure_cmake() {
    log_info "CMakeの確認を行っています..."
    
    # CMakeが既にインストールされているかチェック
    if command -v cmake &> /dev/null; then
        local cmake_version=$(cmake --version | head -n1 | cut -d' ' -f3)
        log_info "システムにインストールされているCMakeバージョン: $cmake_version"
        
        # バージョンチェック（3.13以上が必要）
        version_compare "$cmake_version" "$CMAKE_MIN_VERSION"
        local compare_result=$?
        
        if [ $compare_result -ne 2 ]; then
            log_success "CMakeのバージョン要件を満たしています"
            return 0
        else
            log_warning "CMakeのバージョンが古いため、最新版をビルドします"
        fi
    else
        log_info "CMakeが見つかりません。ソースからビルドします"
    fi
    
    # 公式CMakeバイナリをダウンロード
    log_info "公式CMakeバイナリをダウンロードしています..."
    
    # ビルドディレクトリの作成
    mkdir -p "${CMAKE_BUILD_DIR}"
    cd "${CMAKE_BUILD_DIR}" || handle_error "ディレクトリの変更に失敗: ${CMAKE_BUILD_DIR}"
    
    # 既存のCMakeディレクトリを削除
    rm -rf cmake-*-macos-universal*
    
    # 最新の安定版CMakeバイナリをダウンロード
    local cmake_version="3.30.5"
    local cmake_archive="cmake-${cmake_version}-macos-universal.tar.gz"
    local cmake_url="https://github.com/Kitware/CMake/releases/download/v${cmake_version}/${cmake_archive}"
    
    log_info "CMake ${cmake_version} をダウンロードしています..."
    curl -L -O "$cmake_url"
    
    if [ $? -ne 0 ]; then
        handle_error "CMakeのダウンロードに失敗しました"
    fi
    
    # アーカイブを展開
    tar xzf "$cmake_archive"
    
    if [ $? -ne 0 ]; then
        handle_error "CMakeアーカイブの展開に失敗しました"
    fi
    
    # CMakeのインストールディレクトリを設定
    local cmake_dir="cmake-${cmake_version}-macos-universal"
    export CMAKE_INSTALL_DIR="${CMAKE_BUILD_DIR}/${cmake_dir}/CMake.app/Contents"
    
    # パスを通す
    export PATH="${CMAKE_INSTALL_DIR}/bin:$PATH"
    
    # インストール確認
    if ! command -v cmake &> /dev/null; then
        handle_error "CMakeのインストールに失敗しました"
    fi
    
    local installed_version=$(cmake --version | head -n1 | cut -d' ' -f3)
    log_success "CMake $installed_version のインストールが完了しました"
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗"
}

# FreeRDPソースの準備
prepare_freerdp_source() {
    log_info "FreeRDPリポジトリを準備しています..."
    
    # ビルドディレクトリの確認と作成
    mkdir -p "${FREERDP_BUILD_DIR}"
    
    # EXTERNALディレクトリのFreeRDPを確認
    if [ -d "${EXTERNAL_DIR}/FreeRDP" ]; then
        log_info "FreeRDPソースコードは既に${EXTERNAL_DIR}/FreeRDPに存在します"
        
        # CMakeLists.txtの存在確認
        if [ ! -f "${EXTERNAL_DIR}/FreeRDP/CMakeLists.txt" ]; then
            log_warning "EXTERNALディレクトリのFreeRDPソースコードが不完全です。再クローンします..."
            rm -rf "${EXTERNAL_DIR}/FreeRDP"
            cd "${EXTERNAL_DIR}" || handle_error "ディレクトリの変更に失敗: ${EXTERNAL_DIR}"
            git clone --depth 1 --branch "${FREERDP_VERSION}" "${FREERDP_REPO}" FreeRDP
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
        git checkout "${FREERDP_VERSION}"
    
    # どちらにも存在しない場合は新規クローン
    else
        log_info "FreeRDPリポジトリをクローンしています..."
        cd "${FREERDP_BUILD_DIR}" || handle_error "ディレクトリの変更に失敗: ${FREERDP_BUILD_DIR}"
        git clone --depth 1 --branch "${FREERDP_VERSION}" "${FREERDP_REPO}" FreeRDP
        
        # EXTERNALディレクトリにも同じソースをコピー
        log_info "EXTERNALディレクトリにFreeRDPソースをコピーします..."
        mkdir -p "${EXTERNAL_DIR}"
        cp -R "${FREERDP_BUILD_DIR}/FreeRDP" "${EXTERNAL_DIR}/"
    fi
    
    # CMakeLists.txtの存在確認
    if [ ! -f "${FREERDP_BUILD_DIR}/FreeRDP/CMakeLists.txt" ]; then
        handle_error "FreeRDPのソースコードが正しく準備されていません。CMakeLists.txtが見つかりません。"
    fi
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗"
    log_success "FreeRDPリポジトリの準備が完了しました"
}

# FreeRDP共通CMake設定
get_common_cmake_options() {
    echo "\
        -DCMAKE_TOOLCHAIN_FILE=../FreeRDP/cmake/ios.toolchain.cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=${IOS_MIN_VERSION} \
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
        -DWITH_CLIENT_SDL=OFF \
        -DWITH_SDL=OFF \
        -DWITH_GDI=ON \
        -DCHANNEL_DISPLAY=ON \
        -DCHANNEL_GRAPHICS=ON"
}

# iOS実機向けFreeRDPビルド
build_freerdp_device() {
    log_info "=== iOS実機向けFreeRDPビルド開始 ==="
    
    # OpenSSLの存在確認
    if [ ! -f "${OPENSSL_DIR}/lib/libssl.a" ] || [ ! -f "${OPENSSL_DIR}/lib/libcrypto.a" ]; then
        handle_error "iOS実機向けOpenSSLライブラリが見つかりません。先にOpenSSLをビルドしてください。"
    fi
    
    # ビルドディレクトリの準備
    local build_dir="${FREERDP_BUILD_DIR}/ios"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir" || handle_error "ディレクトリの変更に失敗: $build_dir"
    
    # CMake設定
    log_info "iOS実機向けビルド設定を行っています..."
    local common_options=$(get_common_cmake_options)
    
    # iOS deployment targetを環境変数でも設定
    export IPHONEOS_DEPLOYMENT_TARGET="${IOS_MIN_VERSION}"
    
    cmake ../FreeRDP \
        $common_options \
        -DCMAKE_INSTALL_PREFIX="${FREERDP_INSTALL_DIR}" \
        -DCMAKE_PREFIX_PATH="${OPENSSL_DIR}" \
        -DOPENSSL_ROOT_DIR="${OPENSSL_DIR}" \
        -DOPENSSL_INCLUDE_DIR="${OPENSSL_DIR}/include" \
        -DOPENSSL_CRYPTO_LIBRARY="${OPENSSL_DIR}/lib/libcrypto.a" \
        -DOPENSSL_SSL_LIBRARY="${OPENSSL_DIR}/lib/libssl.a" \
        -DPLATFORM=OS \
        -DAPPLE=ON \
        -DCMAKE_C_FLAGS="-miphoneos-version-min=${IOS_MIN_VERSION}" \
        -DCMAKE_CXX_FLAGS="-miphoneos-version-min=${IOS_MIN_VERSION}"
    
    if [ $? -ne 0 ]; then
        handle_error "iOS実機向けFreeRDP設定に失敗しました"
    fi
    
    # ビルド実行
    log_info "iOS実機向けFreeRDPをビルドしています..."
    cmake --build . --config Release --verbose
    
    if [ $? -ne 0 ]; then
        handle_error "iOS実機向けFreeRDPビルドに失敗しました"
    fi
    
    # ビルド成果物の確認
    log_info "ビルド成果物を確認しています..."
    find . -name "*.a" | head -10
    
    # インストール
    log_info "iOS実機向けFreeRDPをインストールしています..."
    cmake --install . --verbose
    
    # インストール結果の確認
    if [ ! -f "${FREERDP_INSTALL_DIR}/lib/libfreerdp3.a" ]; then
        log_warning "CMakeインストールが不完全でした。手動でライブラリをコピーします..."
        
        # 手動でライブラリをコピー
        mkdir -p "${FREERDP_INSTALL_DIR}/lib"
        mkdir -p "${FREERDP_INSTALL_DIR}/include"
        
        # 必要なライブラリを検索してコピー
        find . -name "libfreerdp3.a" -exec cp {} "${FREERDP_INSTALL_DIR}/lib/" \; 2>/dev/null || true
        find . -name "libwinpr3.a" -exec cp {} "${FREERDP_INSTALL_DIR}/lib/" \; 2>/dev/null || true
        find . -name "libfreerdp-client3.a" -exec cp {} "${FREERDP_INSTALL_DIR}/lib/" \; 2>/dev/null || true
        
        # ヘッダーファイルをコピー
        if [ -d "../FreeRDP/include" ]; then
            cp -R ../FreeRDP/include/* "${FREERDP_INSTALL_DIR}/include/" 2>/dev/null || true
        fi
        
        # 生成されたヘッダーファイルもコピー
        find . -name "*.h" -path "*/include/*" | while read -r header; do
            # ヘッダーファイルのディレクトリ構造を維持してコピー
            rel_path=$(echo "$header" | sed 's|^\./||')
            target_dir="${FREERDP_INSTALL_DIR}/$(dirname "$rel_path")"
            mkdir -p "$target_dir"
            cp "$header" "$target_dir/" 2>/dev/null || true
        done
        
        log_info "手動コピーが完了しました"
    fi
    
    # 最終確認
    if [ ! -f "${FREERDP_INSTALL_DIR}/lib/libfreerdp3.a" ]; then
        handle_error "iOS実機向けFreeRDPライブラリの生成に失敗しました"
    fi
    
    log_success "=== iOS実機向けFreeRDPビルド完了 ==="
}

# iOSシミュレータ向けFreeRDPビルド
build_freerdp_simulator() {
    log_info "=== iOSシミュレータ向けFreeRDPビルド開始 ==="
    
    # OpenSSLの存在確認
    if [ ! -f "${OPENSSL_SIM_DIR}/lib/libssl.a" ] || [ ! -f "${OPENSSL_SIM_DIR}/lib/libcrypto.a" ]; then
        handle_error "iOSシミュレータ向けOpenSSLライブラリが見つかりません。先にOpenSSLをビルドしてください。"
    fi
    
    # ビルドディレクトリの準備
    local build_dir="${FREERDP_BUILD_DIR}/ios-sim"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir" || handle_error "ディレクトリの変更に失敗: $build_dir"
    
    # インストールディレクトリの作成
    mkdir -p "${FREERDP_SIM_INSTALL_DIR}"
    
    # CMake設定
    log_info "iOSシミュレータ向けビルド設定を行っています..."
    local common_options=$(get_common_cmake_options)
    
    # iOS deployment targetを環境変数でも設定
    export IPHONEOS_DEPLOYMENT_TARGET="${IOS_MIN_VERSION}"
    
    cmake ../FreeRDP \
        $common_options \
        -DCMAKE_INSTALL_PREFIX="${FREERDP_SIM_INSTALL_DIR}" \
        -DCMAKE_PREFIX_PATH="${OPENSSL_SIM_DIR}" \
        -DOPENSSL_ROOT_DIR="${OPENSSL_SIM_DIR}" \
        -DOPENSSL_INCLUDE_DIR="${OPENSSL_SIM_DIR}/include" \
        -DOPENSSL_CRYPTO_LIBRARY="${OPENSSL_SIM_DIR}/lib/libcrypto.a" \
        -DOPENSSL_SSL_LIBRARY="${OPENSSL_SIM_DIR}/lib/libssl.a" \
        -DPLATFORM=SIMULATOR \
        -DAPPLE=ON \
        -DCMAKE_C_FLAGS="-mios-simulator-version-min=${IOS_MIN_VERSION}" \
        -DCMAKE_CXX_FLAGS="-mios-simulator-version-min=${IOS_MIN_VERSION}"
    
    if [ $? -ne 0 ]; then
        handle_error "iOSシミュレータ向けFreeRDP設定に失敗しました"
    fi
    
    # ビルド実行
    log_info "iOSシミュレータ向けFreeRDPをビルドしています..."
    cmake --build . --config Release
    
    if [ $? -ne 0 ]; then
        handle_error "iOSシミュレータ向けFreeRDPビルドに失敗しました"
    fi
    
    # インストール
    log_info "iOSシミュレータ向けFreeRDPをインストールしています..."
    cmake --install .
    
    if [ $? -ne 0 ]; then
        handle_error "iOSシミュレータ向けFreeRDPインストールに失敗しました"
    fi
    
    log_success "=== iOSシミュレータ向けFreeRDPビルド完了 ==="
}

# ビルド結果の確認
verify_build() {
    log_info "=== ビルド結果を確認しています ==="
    
    local issues=0
    
    # 実機向けライブラリの確認
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        local device_libs=("libfreerdp3.a" "libfreerdp-client3.a" "libwinpr3.a")
        for lib in "${device_libs[@]}"; do
            if [ -f "${FREERDP_INSTALL_DIR}/lib/$lib" ]; then
                local size=$(ls -lh "${FREERDP_INSTALL_DIR}/lib/$lib" | awk '{print $5}')
                log_success "iOS実機向け: $lib ($size)"
            else
                log_error "iOS実機向け: $lib が見つかりません"
                ((issues++))
            fi
        done
        
        # ヘッダーファイルの確認
        if [ -d "${FREERDP_INSTALL_DIR}/include/freerdp3" ]; then
            log_success "iOS実機向けヘッダーファイル: freerdp3"
        else
            log_error "iOS実機向けヘッダーファイルが見つかりません"
            ((issues++))
        fi
    fi
    
    # シミュレータ向けライブラリの確認
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        local sim_libs=("libfreerdp3.a" "libfreerdp-client3.a" "libwinpr3.a")
        for lib in "${sim_libs[@]}"; do
            if [ -f "${FREERDP_SIM_INSTALL_DIR}/lib/$lib" ]; then
                local size=$(ls -lh "${FREERDP_SIM_INSTALL_DIR}/lib/$lib" | awk '{print $5}')
                log_success "iOSシミュレータ向け: $lib ($size)"
            else
                log_error "iOSシミュレータ向け: $lib が見つかりません"
                ((issues++))
            fi
        done
        
        # ヘッダーファイルの確認
        if [ -d "${FREERDP_SIM_INSTALL_DIR}/include/freerdp3" ]; then
            log_success "iOSシミュレータ向けヘッダーファイル: freerdp3"
        else
            log_error "iOSシミュレータ向けヘッダーファイルが見つかりません"
            ((issues++))
        fi
    fi
    
    if [ $issues -gt 0 ]; then
        handle_error "ビルド検証で問題が発見されました"
    fi
    
    log_success "=== ビルド結果確認完了 ==="
}

# メイン処理
main() {
    # ヘルプ表示の確認
    if [[ "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    log_script_start
    
    # ターゲット検証
    validate_target
    
    # ビルド情報表示
    log_info "=== FreeRDP iOS ビルド開始 ==="
    log_info "ターゲット: $TARGET"
    log_info "FreeRDPバージョン: $FREERDP_VERSION"
    log_info "iOS最小バージョン: $IOS_MIN_VERSION"
    
    # CMakeの確認とインストール
    ensure_cmake
    
    # インストールディレクトリの作成
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        mkdir -p "${FREERDP_INSTALL_DIR}"
    fi
    
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        mkdir -p "${FREERDP_SIM_INSTALL_DIR}"
    fi
    
    # FreeRDPソースの準備
    prepare_freerdp_source
    
    # 古いビルドディレクトリのクリーンアップ
    log_info "古いビルドディレクトリをクリーンアップしています..."
    rm -rf "${FREERDP_BUILD_DIR}/ios" "${FREERDP_BUILD_DIR}/ios-sim"
    
    # ターゲット別ビルド実行
    case "$TARGET" in
        device)
            build_freerdp_device
            ;;
        simulator)
            build_freerdp_simulator
            ;;
        all)
            build_freerdp_device
            build_freerdp_simulator
            ;;
    esac
    
    # ビルド結果確認
    verify_build
    
    # 完了メッセージ
    log_success "=== FreeRDP iOS ビルド完了 ==="
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        log_info "iOS実機向けインストール先: ${FREERDP_INSTALL_DIR}"
    fi
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        log_info "iOSシミュレータ向けインストール先: ${FREERDP_SIM_INSTALL_DIR}"
    fi
    log_info "FreeRDPのソースコードは ${FREERDP_BUILD_DIR}/FreeRDP に保持されています"
    
    log_script_end
}

# スクリプト実行
main "$@"