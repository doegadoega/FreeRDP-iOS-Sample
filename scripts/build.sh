#!/bin/bash

# FreeRDP iOS App Build Script - Main Build Script
# このスクリプトはiOS向けFreeRDPビルドプロセスのメインエントリーポイントです

# 共通設定の読み込み
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
source "${SCRIPT_PATH}/config.sh"

# ログユーティリティ関数
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

# ビルド関数
build_dependencies() {
    # ビルドディレクトリの作成
    mkdir -p "$BUILD_DIR"
    mkdir -p "$EXTERNAL_DIR"

    # OpenSSLのビルド
    log_info "OpenSSLのビルドを開始します..."
    "$SCRIPT_PATH/build_openssl.sh"
    if [ $? -ne 0 ]; then
        handle_error "OpenSSLのビルドに失敗しました"
    fi
    log_success "OpenSSLのビルドが完了しました"

    # FreeRDPのビルド
    log_info "FreeRDPのビルドを開始します..."
    "$SCRIPT_PATH/build_freerdp.sh"
    if [ $? -ne 0 ]; then
        handle_error "FreeRDPのビルドに失敗しました"
    fi
    log_success "FreeRDPのビルドが完了しました"
}

build_xcode_project() {
    log_info "Xcodeプロジェクトのビルドを開始します..."
    
    # プロジェクトのセットアップ
    log_info "プロジェクトのセットアップを開始します..."
    "$SCRIPT_PATH/../create_xcode_project.sh" setup
    if [ $? -ne 0 ]; then
        handle_error "プロジェクトのセットアップに失敗しました"
    fi
    
    # ブリッジングヘッダーの生成
    log_info "ブリッジングヘッダーを生成します..."
    "$SCRIPT_PATH/create_bridging_header.sh"
    if [ $? -ne 0 ]; then
        handle_error "ブリッジングヘッダーの生成に失敗しました"
    fi
    
    # Xcodeビルドの実行
    log_info "Xcodeビルドを開始します..."
    xcodebuild -workspace "$PROJECT_ROOT/MyRDPApp.xcworkspace" \
              -scheme MyRDPApp \
              -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' \
              -configuration Debug \
              build
    
    if [ $? -ne 0 ]; then
        handle_error "Xcodeビルドに失敗しました"
    fi
    
    log_success "Xcodeビルドが完了しました"
}

clean_build() {
    log_info "ビルド成果物をクリーンアップします..."
    rm -rf "$BUILD_DIR"
    rm -rf "$EXTERNAL_DIR"
    log_success "クリーンアップが完了しました"
}

# メイン処理
main() {
    log_script_start
    
    # 依存関係のチェック
    log_info "ビルド環境のチェックを開始します..."
    "$SCRIPT_PATH/check_requirements.sh"
    if [ $? -ne 0 ]; then
        handle_error "ビルド環境のチェックに失敗しました"
    fi
    log_success "ビルド環境のチェックが完了しました"
    
    case "$1" in
        "deps")
            build_dependencies
            ;;
        "xcode")
            build_xcode_project
            ;;
        "build")
            build_dependencies
            build_xcode_project
            ;;
        "clean")
            clean_build
            ;;
        *)
            log_error "無効なコマンド: $1"
            log_info "使用法: $0 {deps|xcode|build|clean}"
            exit 1
            ;;
    esac
    
    log_script_end
}

# スクリプトの実行
main "$@"

# 例: Xcodeプロジェクト存在チェック
if [ ! -d "$XCODEPROJ_PATH" ]; then
    handle_error "Xcodeプロジェクトが見つかりません: $XCODEPROJ_PATH"
fi 