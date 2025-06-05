#!/bin/bash

# FreeRDP iOS App Build Script - Main Build Script
# このスクリプトはiOS向けFreeRDPビルドプロセスのメインエントリーポイントです

set -e  # エラーで即終了

# 共通設定の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/config.sh"

# ヘルプ表示
show_help() {
    echo "FreeRDP iOS App ビルドスクリプト"
    echo ""
    echo "使用方法: $0 [オプション] [ターゲット]"
    echo ""
    echo "オプション:"
    echo "  build     プロジェクト全体のビルド (デフォルト)"
    echo "  clean     ビルド成果物のクリーンアップ"
    echo "  deps      依存関係のみビルド (OpenSSL + FreeRDP)"
    echo "  openssl   OpenSSLのみビルド"
    echo "  freerdp   FreeRDPのみビルド"
    echo "  xcode     Xcodeプロジェクト設定とビルド"
    echo "  config    設定情報の表示"
    echo "  help      このヘルプを表示"
    echo ""
    echo "ターゲット (オプション):"
    echo "  --target device     実機向けのみビルド"
    echo "  --target simulator  シミュレータ向けのみビルド"
    echo "  --target all        両方ビルド (デフォルト)"
    echo ""
    echo "例:"
    echo "  $0 build                    # 全体ビルド"
    echo "  $0 build --target device    # 実機向けのみ"
    echo "  $0 deps                     # 依存関係のみ"
    echo "  $0 clean                    # クリーンアップ"
    echo "  $0 config                   # 設定確認"
}

# 引数解析
parse_arguments() {
    ACTION="${1:-build}"
    TARGET="all"
    
    # ターゲット指定の解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target)
                TARGET="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # ターゲットの妥当性チェック
    case "$TARGET" in
        device|simulator|all) ;;
        *)
            log_error "無効なターゲット: $TARGET"
            log_info "有効なターゲット: device, simulator, all"
            exit 1
            ;;
    esac
}

# 依存関係のビルド
build_dependencies() {
    log_info "=== 依存関係のビルドを開始します ==="
    
    # ディレクトリ作成
    create_build_directories
    
    # OpenSSLのビルド
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        log_info "OpenSSL (実機向け) のビルドを開始します..."
        "${SCRIPT_DIR}/scripts/build_openssl.sh" device
        if [ $? -ne 0 ]; then
            handle_error "OpenSSL (実機向け) のビルドに失敗しました"
        fi
        log_success "OpenSSL (実機向け) のビルドが完了しました"
    fi
    
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        log_info "OpenSSL (シミュレータ向け) のビルドを開始します..."
        "${SCRIPT_DIR}/scripts/build_openssl.sh" simulator
        if [ $? -ne 0 ]; then
            handle_error "OpenSSL (シミュレータ向け) のビルドに失敗しました"
        fi
        log_success "OpenSSL (シミュレータ向け) のビルドが完了しました"
    fi
    
    # FreeRDPのビルド
    if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
        log_info "FreeRDP (実機向け) のビルドを開始します..."
        "${SCRIPT_DIR}/scripts/build_freerdp.sh" device
        if [ $? -ne 0 ]; then
            handle_error "FreeRDP (実機向け) のビルドに失敗しました"
        fi
        log_success "FreeRDP (実機向け) のビルドが完了しました"
    fi
    
    if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
        log_info "FreeRDP (シミュレータ向け) のビルドを開始します..."
        "${SCRIPT_DIR}/scripts/build_freerdp.sh" simulator
        if [ $? -ne 0 ]; then
            handle_error "FreeRDP (シミュレータ向け) のビルドに失敗しました"
        fi
        log_success "FreeRDP (シミュレータ向け) のビルドが完了しました"
    fi
    
    log_success "=== 依存関係のビルドが完了しました ==="
}

# Xcodeプロジェクトの設定とビルド
build_xcode_project() {
    log_info "=== Xcodeプロジェクトのビルドを開始します ==="
    
    # Xcodeプロジェクトの存在確認
    if [ ! -d "$XCODEPROJ_PATH" ]; then
        log_warning "Xcodeプロジェクトが見つかりません: $XCODEPROJ_PATH"
        log_info "Xcodeプロジェクトを手動で作成してください:"
        log_info "1. Xcode を開く"
        log_info "2. 'Create a new Xcode project' を選択"
        log_info "3. 'iOS' > 'App' を選択"
        log_info "4. Product Name: 'MyRDPApp'"
        log_info "5. Organization Identifier: 'com.example'"
        log_info "6. Language: 'Swift', Interface: 'Storyboard'"
        log_info "7. プロジェクトを ${XCODE_PROJECT_DIR} に保存"
        log_info ""
        log_info "プロジェクト作成後、再度このスクリプトを実行してください。"
        return 1
    fi
    
    # CocoaPodsの確認とインストール
    if [ ! -f "${XCODE_PROJECT_DIR}/Podfile" ]; then
        log_info "Podfileが見つかりません。CocoaPodsセットアップをスキップします。"
    else
        if ! command -v pod &> /dev/null; then
            log_info "CocoaPodsをインストールしています..."
            if command -v gem &> /dev/null; then
                sudo gem install cocoapods
            else
                handle_error "Ruby gems not available. Please install CocoaPods manually"
            fi
        fi
        
        log_info "CocoaPods依存関係をインストールしています..."
        cd "${XCODE_PROJECT_DIR}" || handle_error "ディレクトリの変更に失敗: ${XCODE_PROJECT_DIR}"
        pod install
        cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗"
    fi
    
    # ブリッジングヘッダーの生成
    log_info "ブリッジングヘッダーを生成します..."
    "${SCRIPT_DIR}/scripts/create_bridging_header.sh"
    if [ $? -ne 0 ]; then
        handle_error "ブリッジングヘッダーの生成に失敗しました"
    fi
    
    # Xcodeビルドの実行
    log_info "Xcodeビルドを開始します..."
    cd "${XCODE_PROJECT_DIR}" || handle_error "ディレクトリの変更に失敗: ${XCODE_PROJECT_DIR}"
    
    # ワークスペースまたはプロジェクトの選択
    local build_target
    if [ -d "${XCODE_PROJECT_NAME}.xcworkspace" ]; then
        build_target="-workspace ${XCODE_PROJECT_NAME}.xcworkspace"
    else
        build_target="-project ${XCODE_PROJECT_NAME}.xcodeproj"
    fi
    
    # ビルド実行
    case "$TARGET" in
        device)
            xcodebuild $build_target \
                      -scheme "$XCODE_PROJECT_NAME" \
                      -destination 'generic/platform=iOS' \
                      -configuration Debug \
                      build
            ;;
        simulator)
            xcodebuild $build_target \
                      -scheme "$XCODE_PROJECT_NAME" \
                      -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
                      -configuration Debug \
                      build
            ;;
        all)
            # シミュレータ向けビルド
            xcodebuild $build_target \
                      -scheme "$XCODE_PROJECT_NAME" \
                      -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
                      -configuration Debug \
                      build
            
            # 実機向けビルド
            xcodebuild $build_target \
                      -scheme "$XCODE_PROJECT_NAME" \
                      -destination 'generic/platform=iOS' \
                      -configuration Debug \
                      build
            ;;
    esac
    
    if [ $? -ne 0 ]; then
        handle_error "Xcodeビルドに失敗しました"
    fi
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗"
    log_success "=== Xcodeビルドが完了しました ==="
}

# クリーンアップ処理
clean_build() {
    log_info "=== ビルド成果物をクリーンアップします ==="
    
    # ビルドディレクトリのクリーンアップ
    if [ -d "$BUILD_DIR" ]; then
        log_info "ビルドディレクトリを削除しています: $BUILD_DIR"
        rm -rf "$BUILD_DIR"
    fi
    
    # 外部ライブラリディレクトリのクリーンアップ
    if [ -d "$EXTERNAL_DIR" ]; then
        log_info "外部ライブラリディレクトリを削除しています: $EXTERNAL_DIR"
        rm -rf "$EXTERNAL_DIR"
    fi
    
    # Xcodeプロジェクトのクリーンアップ
    if [ -d "${XCODE_PROJECT_DIR}/DerivedData" ]; then
        log_info "Xcode DerivedDataを削除しています..."
        rm -rf "${XCODE_PROJECT_DIR}/DerivedData"
    fi
    
    # CocoaPodsのクリーンアップ
    if [ -f "${XCODE_PROJECT_DIR}/Podfile.lock" ]; then
        log_info "Podfile.lockを削除しています..."
        rm "${XCODE_PROJECT_DIR}/Podfile.lock"
    fi
    
    if [ -d "${XCODE_PROJECT_DIR}/Pods" ]; then
        log_info "Podsディレクトリを削除しています..."
        rm -rf "${XCODE_PROJECT_DIR}/Pods"
    fi
    
    log_success "=== クリーンアップが完了しました ==="
}

# メイン処理
main() {
    log_script_start
    
    # 引数解析
    parse_arguments "$@"
    
    log_info "アクション: $ACTION, ターゲット: $TARGET"
    
    # 基本的な依存関係チェック（clean以外）
    if [[ "$ACTION" != "clean" && "$ACTION" != "help" && "$ACTION" != "config" ]]; then
        log_info "=== ビルド環境のチェックを開始します ==="
        check_dependencies
        validate_config
        log_success "=== ビルド環境のチェックが完了しました ==="
    fi
    
    # アクションの実行
    case "$ACTION" in
        "build")
            build_dependencies
            build_xcode_project
            ;;
        "deps")
            build_dependencies
            ;;
        "openssl")
            create_build_directories
            if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
                "${SCRIPT_DIR}/scripts/build_openssl.sh" device
            fi
            if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
                "${SCRIPT_DIR}/scripts/build_openssl.sh" simulator
            fi
            ;;
        "freerdp")
            create_build_directories
            if [[ "$TARGET" == "all" || "$TARGET" == "device" ]]; then
                "${SCRIPT_DIR}/scripts/build_freerdp.sh" device
            fi
            if [[ "$TARGET" == "all" || "$TARGET" == "simulator" ]]; then
                "${SCRIPT_DIR}/scripts/build_freerdp.sh" simulator
            fi
            ;;
        "xcode")
            build_xcode_project
            ;;
        "clean")
            clean_build
            ;;
        "config")
            show_config
            ;;
        "help")
            show_help
            ;;
        *)
            log_error "不明なオプション: $ACTION"
            show_help
            exit 1
            ;;
    esac
    
    log_script_end
}

# スクリプトの実行
main "$@"
