#!/bin/bash

# iOS用 cJSON ビルドスクリプト

set -e

# 共通設定の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# cJSON設定
CJSON_VERSION="1.7.18"
CJSON_REPO="https://github.com/DaveGamble/cJSON.git"
CJSON_TAG="v${CJSON_VERSION}"

# 引数解析
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

# cJSONソースの準備
prepare_cjson_source() {
    log_info "cJSONリポジトリを準備しています..."
    
    local cjson_build_dir="${BUILD_DIR}/cjson"
    
    # ビルドディレクトリが存在しない場合は作成
    mkdir -p "${cjson_build_dir}"
    
    # cJSONディレクトリの確認
    if [ -d "${cjson_build_dir}/cjson" ]; then
        log_info "cJSONディレクトリが既に存在します。更新します..."
        cd "${cjson_build_dir}/cjson" || handle_error "ディレクトリの変更に失敗: ${cjson_build_dir}/cjson"
        
        # リポジトリの状態確認とクリーン
        git status --porcelain | grep -q . && git reset --hard HEAD
        git fetch --all
    else
        log_info "cJSONリポジトリをクローンしています..."
        cd "${cjson_build_dir}" || handle_error "ディレクトリの変更に失敗: ${cjson_build_dir}"
        git clone "${CJSON_REPO}" cjson
        cd cjson || handle_error "ディレクトリの変更に失敗: cjson"
    fi
    
    # 指定バージョンのチェックアウト
    log_info "cJSONバージョン ${CJSON_TAG} をチェックアウトしています..."
    git checkout "${CJSON_TAG}" || handle_error "cJSONバージョン ${CJSON_TAG} のチェックアウトに失敗しました"
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗"
    log_success "cJSONリポジトリの準備が完了しました"
}

# iOS実機向けcJSONビルド
build_cjson_device() {
    log_info "=== iOS実機向けcJSONビルド開始 ==="
    
    local cjson_source_dir="${BUILD_DIR}/cjson/cjson"
    local cjson_install_dir="${EXTERNAL_DIR}/cjson"
    
    # ソースディレクトリに移動
    cd "${cjson_source_dir}" || handle_error "ディレクトリの変更に失敗: ${cjson_source_dir}"
    
    # ビルドディレクトリの準備
    local build_dir="build-ios"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir" || handle_error "ディレクトリの変更に失敗: $build_dir"
    
    # iOS実機向け設定（CMakeを使わずに直接コンパイル）
    log_info "iOS実機向けビルドを行っています..."
    
    # 手動コンパイル（CMakeの複雑さを回避）
    local ios_sdk_path=$(xcrun --sdk iphoneos --show-sdk-path)
    local min_version="${IOS_MIN_VERSION}"
    
    # cJSONソースをコンパイル
    xcrun -sdk iphoneos clang -c ../cJSON.c \
        -arch arm64 \
        -miphoneos-version-min=$min_version \
        -isysroot $ios_sdk_path \
        -O2 \
        -o cJSON.o
    
    if [ $? -ne 0 ]; then
        handle_error "iOS実機向けcJSONコンパイルに失敗しました"
    fi
    
    # スタティックライブラリの作成
    xcrun -sdk iphoneos ar rcs libcjson.a cJSON.o
    
    if [ $? -ne 0 ]; then
        handle_error "iOS実機向けcJSONライブラリ作成に失敗しました"
    fi
    
    # インストール
    log_info "iOS実機向けcJSONをインストールしています..."
    mkdir -p "${cjson_install_dir}/lib"
    mkdir -p "${cjson_install_dir}/include"
    
    cp libcjson.a "${cjson_install_dir}/lib/"
    cp ../cJSON.h "${cjson_install_dir}/include/"
    
    # インストール確認
    if [ ! -f "${cjson_install_dir}/lib/libcjson.a" ]; then
        handle_error "iOS実機向けcJSONライブラリが正しく生成されませんでした"
    fi
    
    log_success "=== iOS実機向けcJSONビルド完了 ==="
    log_info "インストール先: ${cjson_install_dir}"
}

# iOSシミュレータ向けcJSONビルド
build_cjson_simulator() {
    log_info "=== iOSシミュレータ向けcJSONビルド開始 ==="
    
    local cjson_source_dir="${BUILD_DIR}/cjson/cjson"
    local cjson_sim_install_dir="${EXTERNAL_DIR}/cjson-simulator"
    
    # ソースディレクトリに移動
    cd "${cjson_source_dir}" || handle_error "ディレクトリの変更に失敗: ${cjson_source_dir}"
    
    # ビルドディレクトリの準備
    local build_dir="build-ios-sim"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir" || handle_error "ディレクトリの変更に失敗: $build_dir"
    
    # iOSシミュレータ向け設定
    log_info "iOSシミュレータ向けビルドを行っています..."
    
    # 手動コンパイル
    local ios_sim_sdk_path=$(xcrun --sdk iphonesimulator --show-sdk-path)
    local min_version="${IOS_MIN_VERSION}"
    
    # cJSONソースをコンパイル
    xcrun -sdk iphonesimulator clang -c ../cJSON.c \
        -arch arm64 \
        -mios-simulator-version-min=$min_version \
        -isysroot $ios_sim_sdk_path \
        -O2 \
        -o cJSON.o
    
    if [ $? -ne 0 ]; then
        handle_error "iOSシミュレータ向けcJSONコンパイルに失敗しました"
    fi
    
    # スタティックライブラリの作成
    xcrun -sdk iphonesimulator ar rcs libcjson.a cJSON.o
    
    if [ $? -ne 0 ]; then
        handle_error "iOSシミュレータ向けcJSONライブラリ作成に失敗しました"
    fi
    
    # インストール
    log_info "iOSシミュレータ向けcJSONをインストールしています..."
    mkdir -p "${cjson_sim_install_dir}/lib"
    mkdir -p "${cjson_sim_install_dir}/include"
    
    cp libcjson.a "${cjson_sim_install_dir}/lib/"
    cp ../cJSON.h "${cjson_sim_install_dir}/include/"
    
    # インストール確認
    if [ ! -f "${cjson_sim_install_dir}/lib/libcjson.a" ]; then
        handle_error "iOSシミュレータ向けcJSONライブラリが正しく生成されませんでした"
    fi
    
    log_success "=== iOSシミュレータ向けcJSONビルド完了 ==="
    log_info "インストール先: ${cjson_sim_install_dir}"
}

# ビルド結果の確認
verify_build() {
    log_info "=== ビルド結果を確認しています ==="
    
    local issues=0
    
    # 実機向けライブラリの確認
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        if [ -f "${EXTERNAL_DIR}/cjson/lib/libcjson.a" ]; then
            local size=$(ls -lh "${EXTERNAL_DIR}/cjson/lib/libcjson.a" | awk '{print $5}')
            log_success "iOS実機向けライブラリ: libcjson.a (${size})"
        else
            log_error "iOS実機向けライブラリが見つかりません"
            ((issues++))
        fi
    fi
    
    # シミュレータ向けライブラリの確認
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        if [ -f "${EXTERNAL_DIR}/cjson-simulator/lib/libcjson.a" ]; then
            local size=$(ls -lh "${EXTERNAL_DIR}/cjson-simulator/lib/libcjson.a" | awk '{print $5}')
            log_success "iOSシミュレータ向けライブラリ: libcjson.a (${size})"
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
        echo "cJSON iOS Build Script"
        echo ""
        echo "使用方法: $0 [TARGET]"
        echo ""
        echo "TARGET:"
        echo "  device     実機向けcJSONのみビルド"
        echo "  simulator  シミュレータ向けcJSONのみビルド"
        echo "  all        両方ビルド (デフォルト)"
        exit 0
    fi
    
    log_script_start
    
    # ターゲット検証
    validate_target
    
    # ビルド情報表示
    log_info "=== cJSON iOS ビルド開始 ==="
    log_info "ターゲット: $TARGET"
    log_info "cJSONバージョン: $CJSON_VERSION"
    log_info "iOS最小バージョン: $IOS_MIN_VERSION"
    
    # インストールディレクトリの作成
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        mkdir -p "${EXTERNAL_DIR}/cjson"
    fi
    
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        mkdir -p "${EXTERNAL_DIR}/cjson-simulator"
    fi
    
    # cJSONソースの準備
    prepare_cjson_source
    
    # ターゲット別ビルド実行
    case "$TARGET" in
        device)
            build_cjson_device
            ;;
        simulator)
            build_cjson_simulator
            ;;
        all)
            build_cjson_device
            build_cjson_simulator
            ;;
    esac
    
    # ビルド結果確認
    verify_build
    
    # 完了メッセージ
    log_success "=== cJSON iOS ビルド完了 ==="
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        log_info "iOS実機向けインストール先: ${EXTERNAL_DIR}/cjson"
    fi
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        log_info "iOSシミュレータ向けインストール先: ${EXTERNAL_DIR}/cjson-simulator"
    fi
    
    log_script_end
}

# スクリプト実行
main "$@"