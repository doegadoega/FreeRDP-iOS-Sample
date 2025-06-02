#!/bin/bash

# FreeRDP iOS App Build Script - Setup Xcode Project
# This script sets up the Xcode project

# Load config functions and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Record script start
log_script_start

# Log warning function
log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

# XcodeGenのインストール
install_xcodegen() {
    log_info "XcodeGenをソースからビルドします..."
    
    # XcodeGenのビルドディレクトリ
    XCODEGEN_BUILD_DIR="${BUILD_DIR}/xcodegen"
    XCODEGEN_INSTALL_DIR="${EXTERNAL_DIR}/xcodegen"
    
    # ビルドディレクトリの作成
    mkdir -p "${XCODEGEN_BUILD_DIR}"
    cd "${XCODEGEN_BUILD_DIR}" || handle_error "ディレクトリの変更に失敗: ${XCODEGEN_BUILD_DIR}"
    
    # XcodeGenのクローン（既に存在する場合は更新）
    if [ -d "XcodeGen" ]; then
        log_info "XcodeGenリポジトリを更新します..."
        cd XcodeGen || handle_error "ディレクトリの変更に失敗: XcodeGen"
        git fetch --all
    else
        log_info "XcodeGenリポジトリをクローンします..."
        git clone https://github.com/yonaskolb/XcodeGen.git
        cd XcodeGen || handle_error "ディレクトリの変更に失敗: XcodeGen"
    fi
    
    # 最新の安定版をチェックアウト
    git checkout $(git describe --tags --abbrev=0)
    
    # ビルドとインストール
    log_info "XcodeGenをビルドします..."
    make install PREFIX="${XCODEGEN_INSTALL_DIR}"
    
    # パスを通す
    export PATH="${XCODEGEN_INSTALL_DIR}/bin:$PATH"
    
    # インストール確認
    if ! command -v xcodegen &> /dev/null; then
        handle_error "XcodeGenのインストールに失敗しました"
    fi
    
    XCODEGEN_VERSION=$(xcodegen version)
    log_success "XcodeGen $XCODEGEN_VERSION のインストールが完了しました"
    
    cd "${PROJECT_ROOT}" || handle_error "プロジェクトルートディレクトリへの移動に失敗しました"
}

# XcodeGenで生成されたプロジェクトの設定を修正
fix_xcode_project_settings() {
    local PROJ_FILE="$XCODE_PROJECT_DIR/MyRDPApp.xcodeproj/project.pbxproj"
    
    # プロジェクトファイルが存在するかチェック
    if [ ! -f "$PROJ_FILE" ]; then
        log_error "Project file not found: $PROJ_FILE"
        return 1
    fi
    
    log_info "プロジェクトファイルのバックアップを作成しています..."
    cp "$PROJ_FILE" "${PROJ_FILE}.backup"
    
    # 1. 条件付きリンクフラグの追加
    log_info "条件付きリンクフラグを追加しています..."
    add_conditional_linker_flags "$PROJ_FILE"
    
    # 2. プリプロセッサ定義の追加
    log_info "プリプロセッサ定義を追加しています..."
    add_preprocessor_definitions "$PROJ_FILE"
    
    # 3. アーキテクチャ設定の追加
    log_info "アーキテクチャ除外設定を追加しています..."
    add_architecture_settings "$PROJ_FILE"
    
    log_success "プロジェクトファイルの修正が完了しました"
}

# 条件付きリンクフラグの追加
add_conditional_linker_flags() {
    local PROJ_FILE="$1"
    
    # 一時ファイルに条件付きフラグを作成
    cat > /tmp/conditional_flags.txt << 'EOF'
				"OTHER_LDFLAGS[sdk=iphoneos*]" = (
					"$(inherited)",
					"-framework Foundation",
					"-framework CoreGraphics", 
					"-framework UIKit",
					"-framework SystemConfiguration",
					"-framework Security",
					"$(PROJECT_DIR)/Libraries/freerdp-device/lib/libfreerdp3.a",
					"$(PROJECT_DIR)/Libraries/freerdp-device/lib/libfreerdp-client3.a",
					"$(PROJECT_DIR)/Libraries/freerdp-device/lib/libwinpr3.a",
					"$(PROJECT_DIR)/Libraries/openssl/lib/libssl.a",
					"$(PROJECT_DIR)/Libraries/openssl/lib/libcrypto.a",
					"-lz",
					"-lc++",
					"-ObjC",
				);
				"OTHER_LDFLAGS[sdk=iphonesimulator*]" = (
					"$(inherited)",
					"-framework Foundation",
					"-framework CoreGraphics",
					"-framework UIKit", 
					"-framework SystemConfiguration",
					"-framework Security",
					"$(PROJECT_DIR)/Libraries/freerdp-simulator/lib/libfreerdp3.a",
					"$(PROJECT_DIR)/Libraries/freerdp-simulator/lib/libfreerdp-client3.a",
					"$(PROJECT_DIR)/Libraries/freerdp-simulator/lib/libwinpr3.a",
					"$(PROJECT_DIR)/Libraries/openssl-simulator/lib/libssl.a",
					"$(PROJECT_DIR)/Libraries/openssl-simulator/lib/libcrypto.a",
					"-lz",
					"-lc++",
					"-ObjC",
				);
EOF
    
    # 既存のOTHER_LDFLAGSを条件付きフラグに置換
    # macOSのsedコマンドに対応した処理
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS版sed
        sed -i '' '/OTHER_LDFLAGS = (/,/);/d' "$PROJ_FILE"
        
        # Debug設定に条件付きフラグを挿入
        sed -i '' '/name = Debug/,/name = Release/{
            /TARGETED_DEVICE_FAMILY = "1,2";/r /tmp/conditional_flags.txt
        }' "$PROJ_FILE"
        
        # Release設定にも挿入
        sed -i '' '/name = Release/,/}/{
            /TARGETED_DEVICE_FAMILY = "1,2";/r /tmp/conditional_flags.txt
        }' "$PROJ_FILE"
    else
        # Linux版sed
        sed -i '/OTHER_LDFLAGS = (/,/);/d' "$PROJ_FILE"
        sed -i '/name = Debug/,/name = Release/{
            /TARGETED_DEVICE_FAMILY = "1,2";/r /tmp/conditional_flags.txt
        }' "$PROJ_FILE"
        sed -i '/name = Release/,/}/{
            /TARGETED_DEVICE_FAMILY = "1,2";/r /tmp/conditional_flags.txt
        }' "$PROJ_FILE"
    fi
    
    # クリーンアップ
    rm -f /tmp/conditional_flags.txt
}

# プリプロセッサ定義の追加
add_preprocessor_definitions() {
    local PROJ_FILE="$1"
    
    # 新しいプリプロセッサ定義を作成
    cat > /tmp/preprocessor_defs.txt << 'EOF'
				GCC_PREPROCESSOR_DEFINITIONS = (
					"$(inherited)",
					"FREERDP_API_VERSION=3",
					"WITH_FREERDP3=1",
					"DEBUG=1",
				);
EOF
    
    # Release用の定義（DEBUGフラグなし）
    cat > /tmp/preprocessor_defs_release.txt << 'EOF'
				GCC_PREPROCESSOR_DEFINITIONS = (
					"$(inherited)",
					"FREERDP_API_VERSION=3", 
					"WITH_FREERDP3=1",
				);
EOF
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # 既存のGCC_PREPROCESSOR_DEFINITIONSを削除
        sed -i '' '/GCC_PREPROCESSOR_DEFINITIONS = (/,/);/d' "$PROJ_FILE"
        
        # Debug設定に追加
        sed -i '' '/name = Debug/,/name = Release/{
            /ENABLE_TESTABILITY = YES;/r /tmp/preprocessor_defs.txt
        }' "$PROJ_FILE"
        
        # Release設定に追加
        sed -i '' '/name = Release/,/}/{
            /CLANG_ENABLE_OBJC_ARC = YES;/r /tmp/preprocessor_defs_release.txt
        }' "$PROJ_FILE"
    else
        sed -i '/GCC_PREPROCESSOR_DEFINITIONS = (/,/);/d' "$PROJ_FILE"
        sed -i '/name = Debug/,/name = Release/{
            /ENABLE_TESTABILITY = YES;/r /tmp/preprocessor_defs.txt
        }' "$PROJ_FILE"
        sed -i '/name = Release/,/}/{
            /CLANG_ENABLE_OBJC_ARC = YES;/r /tmp/preprocessor_defs_release.txt
        }' "$PROJ_FILE"
    fi
    
    # クリーンアップ
    rm -f /tmp/preprocessor_defs.txt /tmp/preprocessor_defs_release.txt
}

# アーキテクチャ設定の追加
add_architecture_settings() {
    local PROJ_FILE="$1"
    
    # アーキテクチャ除外設定を作成
    cat > /tmp/arch_settings_debug.txt << 'EOF'
				"EXCLUDED_ARCHS[sdk=iphonesimulator*]" = "";
				ONLY_ACTIVE_ARCH = NO;
EOF
    
    cat > /tmp/arch_settings_release.txt << 'EOF'
				"EXCLUDED_ARCHS[sdk=iphonesimulator*]" = "";
EOF
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Debug設定に追加
        sed -i '' '/name = Debug/,/name = Release/{
            /ENABLE_TESTABILITY = YES;/r /tmp/arch_settings_debug.txt
        }' "$PROJ_FILE"
        
        # Release設定に追加
        sed -i '' '/name = Release/,/}/{
            /CLANG_ENABLE_OBJC_ARC = YES;/r /tmp/arch_settings_release.txt  
        }' "$PROJ_FILE"
    else
        sed -i '/name = Debug/,/name = Release/{
            /ENABLE_TESTABILITY = YES;/r /tmp/arch_settings_debug.txt
        }' "$PROJ_FILE"
        sed -i '/name = Release/,/}/{
            /CLANG_ENABLE_OBJC_ARC = YES;/r /tmp/arch_settings_release.txt  
        }' "$PROJ_FILE"
    fi
    
    # クリーンアップ
    rm -f /tmp/arch_settings_debug.txt /tmp/arch_settings_release.txt
}

# Main function
setup_xcode_project() {
    log_info "Creating Xcode project using XcodeGen..."
    
    # Check if XcodeGen is installed
    if ! command -v xcodegen &> /dev/null; then
        log_info "XcodeGenがインストールされていません。ソースからビルドします..."
        install_xcodegen
    fi
        
    # Remove old project if it exists
    if [ -d "$XCODE_PROJECT_DIR/MyRDPApp.xcodeproj" ]; then
        log_info "Removing existing Xcode project..."
        rm -rf "$XCODE_PROJECT_DIR/MyRDPApp.xcodeproj"
    fi
        
    # Generate project using XcodeGen
    log_info "Generating project with XcodeGen..."
    cd "$XCODE_PROJECT_DIR" || handle_error "ディレクトリの変更に失敗: $XCODE_PROJECT_DIR"
    xcodegen generate
    
    # XcodeGenの後処理 - プロジェクトファイルの修正
    log_info "XcodeGenで生成されたプロジェクトファイルを修正しています..."
    fix_xcode_project_settings
    
    log_success "Xcode project setup completed"
    return 0
}

# Run the main function
setup_xcode_project

# Record script end
log_script_end