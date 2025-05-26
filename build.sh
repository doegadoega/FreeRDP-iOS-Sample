#!/bin/bash

# FreeRDP iOS App Build Script
# このスクリプトはFreeRDP iOSアプリケーションのビルドを管理します

set -e  # エラーで即終了

# ディレクトリパス設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ヘルプ表示
show_help() {
    echo "FreeRDP iOS App ビルドスクリプト"
    echo ""
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  build     プロジェクト全体のビルド (デフォルト)"
    echo "  clean     ビルド成果物のクリーンアップ"
    echo "  openssl   OpenSSLのみビルド"
    echo "  freerdp   FreeRDPのみビルド"
    echo "  help      このヘルプを表示"
    echo ""
    echo "例:"
    echo "  $0 build    # 全体ビルド"
    echo "  $0 clean    # クリーンアップ"
    echo "  $0 openssl  # OpenSSLのみビルド"
    echo "  $0 freerdp  # FreeRDPのみビルド"
}

# メイン処理
main() {
    # 引数処理
    ACTION="${1:-build}"
    
    # cleanオプションの場合はディレクトリセットアップをスキップ
    if [ "$ACTION" != "clean" ] && [ "$ACTION" != "help" ]; then
        # ディレクトリ設定（clean以外で必要）
        "${SCRIPT_DIR}/scripts/setup_directories.sh"
    fi
    
    # コマンド処理
    case "$ACTION" in
    "build")
            # OpenSSLビルド
            "${SCRIPT_DIR}/scripts/build_openssl.sh"
            # FreeRDPビルド
            "${SCRIPT_DIR}/scripts/build_freerdp.sh"
            # ブリッジングヘッダー作成
            "${SCRIPT_DIR}/scripts/create_bridging_header.sh"
        ;;
    "clean")
            # クリーンアップ
            "${SCRIPT_DIR}/scripts/clean.sh"
        ;;
        "openssl")
            # OpenSSLビルド
            "${SCRIPT_DIR}/scripts/build_openssl.sh"
        ;;
        "freerdp")
            # FreeRDPビルド
            "${SCRIPT_DIR}/scripts/build_freerdp.sh"
        ;;
    "help")
        show_help
        ;;
    *)
            echo "不明なオプション: $ACTION"
        show_help
        exit 1
        ;;
esac
}

# メイン実行
main "$@"
