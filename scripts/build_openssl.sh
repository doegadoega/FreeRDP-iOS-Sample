#!/bin/bash

# OpenSSL 3.x iOS Build Script
# iOS向けOpenSSLのビルドスクリプト

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
    echo "OpenSSL iOS Build Script"
    echo ""
    echo "使用方法: $0 [TARGET]"
    echo ""
    echo "TARGET:"
    echo "  device     実機向けOpenSSLのみビルド"
    echo "  simulator  シミュレータ向けOpenSSLのみビルド"
    echo "  all        両方ビルド (デフォルト)"
    echo ""
    echo "例:"
    echo "  $0              # 両方ビルド"
    echo "  $0 device       # 実機向けのみ"
    echo "  $0 simulator    # シミュレータ向けのみ"
}

# OpenSSLリポジトリのクローンとチェックアウト
prepare_openssl_source() {
    log_info "OpenSSLリポジトリを準備しています..."
    
    local openssl_build_dir="${BUILD_DIR}/openssl"
    
    # ビルドディレクトリが存在しない場合は作成
    mkdir -p "${openssl_build_dir}"
    
    # OpenSSLディレクトリの確認
    if [ -d "${openssl_build_dir}/openssl" ]; then
        log_info "OpenSSLディレクトリが既に存在します。更新します..."
        cd "${openssl_build_dir}/openssl" || handle_error "ディレクトリの変更に失敗: ${openssl_build_dir}/openssl"
        
        # リポジトリの状態確認とクリーン
        git status --porcelain | grep -q . && git reset --hard HEAD
        git fetch --all
    else
        log_info "OpenSSLリポジトリをクローンしています..."
        cd "${openssl_build_dir}" || handle_error "ディレクトリの変更に失敗: ${openssl_build_dir}"
        git clone "${OPENSSL_REPO}" openssl
        cd openssl || handle_error "ディレクトリの変更に失敗: openssl"
    fi
    
    # 指定バージョンのチェックアウト
    log_info "OpenSSLバージョン ${OPENSSL_VERSION} をチェックアウトしています..."
    git checkout "openssl-${OPENSSL_VERSION}" || \
    git checkout "tags/openssl-${OPENSSL_VERSION}" || \
    handle_error "OpenSSLバージョン ${OPENSSL_VERSION} のチェックアウトに失敗しました"
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗"
    log_success "OpenSSLリポジトリの準備が完了しました"
}

# iOS実機向けOpenSSLビルド
build_openssl_device() {
    log_info "=== iOS実機向けOpenSSLビルド開始 ==="
    
    local openssl_source_dir="${BUILD_DIR}/openssl/openssl"
    
    # ソースディレクトリに移動
    cd "${openssl_source_dir}" || handle_error "ディレクトリの変更に失敗: ${openssl_source_dir}"
    
    # 前回のビルドをクリーン
    make clean > /dev/null 2>&1 || true
    
    # iOS実機向け設定
    log_info "iOS実機向けビルド設定を行っています..."
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
    
    if [ $? -ne 0 ]; then
        handle_error "iOS実機向けOpenSSL設定に失敗しました"
    fi
    
    # ビルド実行
    log_info "iOS実機向けOpenSSLをビルドしています..."
    make -j$(sysctl -n hw.ncpu)
    
    if [ $? -ne 0 ]; then
        handle_error "iOS実機向けOpenSSLビルドに失敗しました"
    fi
    
    # インストール
    log_info "iOS実機向けOpenSSLをインストールしています..."
    make install_sw
    
    if [ $? -ne 0 ]; then
        handle_error "iOS実機向けOpenSSLインストールに失敗しました"
    fi
    
    # インストール確認
    if [ ! -f "${OPENSSL_DIR}/lib/libssl.a" ] || [ ! -f "${OPENSSL_DIR}/lib/libcrypto.a" ]; then
        handle_error "iOS実機向けOpenSSLライブラリが正しく生成されませんでした"
    fi
    
    log_success "=== iOS実機向けOpenSSLビルド完了 ==="
    log_info "インストール先: ${OPENSSL_DIR}"
}

# iOSシミュレータ向けOpenSSLビルド
build_openssl_simulator() {
    log_info "=== iOSシミュレータ向けOpenSSLビルド開始 ==="
    
    local openssl_source_dir="${BUILD_DIR}/openssl/openssl"
    
    # ソースディレクトリに移動
    cd "${openssl_source_dir}" || handle_error "ディレクトリの変更に失敗: ${openssl_source_dir}"
    
    # 前回のビルドをクリーン
    make clean > /dev/null 2>&1 || true
    
    # iOSシミュレータ向け設定
    log_info "iOSシミュレータ向けビルド設定を行っています..."
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
    
    if [ $? -ne 0 ]; then
        handle_error "iOSシミュレータ向けOpenSSL設定に失敗しました"
    fi
    
    # ビルド実行
    log_info "iOSシミュレータ向けOpenSSLをビルドしています..."
    make -j$(sysctl -n hw.ncpu)
    
    if [ $? -ne 0 ]; then
        handle_error "iOSシミュレータ向けOpenSSLビルドに失敗しました"
    fi
    
    # インストール
    log_info "iOSシミュレータ向けOpenSSLをインストールしています..."
    make install_sw
    
    if [ $? -ne 0 ]; then
        handle_error "iOSシミュレータ向けOpenSSLインストールに失敗しました"
    fi
    
    # インストール確認
    if [ ! -f "${OPENSSL_SIM_DIR}/lib/libssl.a" ] || [ ! -f "${OPENSSL_SIM_DIR}/lib/libcrypto.a" ]; then
        handle_error "iOSシミュレータ向けOpenSSLライブラリが正しく生成されませんでした"
    fi
    
    log_success "=== iOSシミュレータ向けOpenSSLビルド完了 ==="
    log_info "インストール先: ${OPENSSL_SIM_DIR}"
}

# ビルド結果の確認
verify_build() {
    log_info "=== ビルド結果を確認しています ==="
    
    local issues=0
    
    # 実機向けライブラリの確認
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        if [ -f "${OPENSSL_DIR}/lib/libssl.a" ] && [ -f "${OPENSSL_DIR}/lib/libcrypto.a" ]; then
            local ssl_size=$(ls -lh "${OPENSSL_DIR}/lib/libssl.a" | awk '{print $5}')
            local crypto_size=$(ls -lh "${OPENSSL_DIR}/lib/libcrypto.a" | awk '{print $5}')
            log_success "iOS実機向けライブラリ: libssl.a (${ssl_size}), libcrypto.a (${crypto_size})"
        else
            log_error "iOS実機向けライブラリが見つかりません"
            ((issues++))
        fi
    fi
    
    # シミュレータ向けライブラリの確認
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        if [ -f "${OPENSSL_SIM_DIR}/lib/libssl.a" ] && [ -f "${OPENSSL_SIM_DIR}/lib/libcrypto.a" ]; then
            local ssl_sim_size=$(ls -lh "${OPENSSL_SIM_DIR}/lib/libssl.a" | awk '{print $5}')
            local crypto_sim_size=$(ls -lh "${OPENSSL_SIM_DIR}/lib/libcrypto.a" | awk '{print $5}')
            log_success "iOSシミュレータ向けライブラリ: libssl.a (${ssl_sim_size}), libcrypto.a (${crypto_sim_size})"
        else
            log_error "iOSシミュレータ向けライブラリが見つかりません"
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
    log_info "=== OpenSSL iOS ビルド開始 ==="
    log_info "ターゲット: $TARGET"
    log_info "OpenSSLバージョン: $OPENSSL_VERSION"
    log_info "iOS最小バージョン: $IOS_MIN_VERSION"
    
    # インストールディレクトリの作成
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        mkdir -p "${OPENSSL_DIR}"
    fi
    
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        mkdir -p "${OPENSSL_SIM_DIR}"
    fi
    
    # OpenSSLソースの準備
    prepare_openssl_source
    
    # ターゲット別ビルド実行
    case "$TARGET" in
        device)
            build_openssl_device
            ;;
        simulator)
            build_openssl_simulator
            ;;
        all)
            build_openssl_device
            build_openssl_simulator
            ;;
    esac
    
    # ビルド結果確認
    verify_build
    
    # 完了メッセージ
    log_success "=== OpenSSL iOS ビルド完了 ==="
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        log_info "iOS実機向けインストール先: ${OPENSSL_DIR}"
    fi
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        log_info "iOSシミュレータ向けインストール先: ${OPENSSL_SIM_DIR}"
    fi
    
    log_script_end
}

# スクリプト実行
main "$@"
