#!/bin/bash

# FreeRDP iOS App Build Script - Create Bridging Header
# This script creates the Swift bridging header for FreeRDP

# Load common functions and settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Record script start
log_script_start

# Main function
create_bridging_header() {
    log_info "Creating Swift bridging header..."
    
    # ディレクトリの存在確認
    if [ ! -d "$RDP_DIR" ]; then
        log_error "RDP directory not found: $RDP_DIR"
        return 1
    fi
    
    # ブリッジングヘッダーのパス
    BRIDGE_HEADER="$RDP_DIR/MyRDPApp-Bridging-Header.h"
    
    # 既存のファイルをバックアップ
    if [ -f "$BRIDGE_HEADER" ]; then
        mv "$BRIDGE_HEADER" "${BRIDGE_HEADER}.bak"
        log_info "Backed up existing bridging header"
    fi
    
    # ブリッジングヘッダーの作成
    cat > "$BRIDGE_HEADER" << EOF
//
//  MyRDPApp-Bridging-Header.h
//  MyRDPApp
//
//  Created by build script
//

#ifndef MyRDPApp_Bridging_Header_h
#define MyRDPApp_Bridging_Header_h

#import "FreeRDPBridge.h"

#endif /* MyRDPApp_Bridging_Header_h */
EOF
    
    if [ $? -ne 0 ]; then
        log_error "Failed to create bridging header"
        # バックアップから復元
        if [ -f "${BRIDGE_HEADER}.bak" ]; then
            mv "${BRIDGE_HEADER}.bak" "$BRIDGE_HEADER"
            log_info "Restored previous bridging header"
        fi
        return 1
    fi
    
    # バックアップファイルの削除
    if [ -f "${BRIDGE_HEADER}.bak" ]; then
        rm "${BRIDGE_HEADER}.bak"
    fi
    
    log_success "Bridging header created successfully at: $BRIDGE_HEADER"
    return 0
}

# Run the main function
if ! create_bridging_header; then
    log_error "Failed to create bridging header"
    exit 1
fi

# Record script end
log_script_end 