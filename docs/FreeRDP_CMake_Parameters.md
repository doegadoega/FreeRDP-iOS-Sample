# FreeRDP CMakeパラメータ一覧

## 目次
1. [基本設定](#基本設定)
2. [ビデオ関連](#ビデオ関連)
3. [オーディオ関連](#オーディオ関連)
4. [入力デバイス関連](#入力デバイス関連)
5. [セキュリティ関連](#セキュリティ関連)
6. [デバッグ関連](#デバッグ関連)
7. [その他の機能](#その他の機能)

## 基本設定

### プラットフォーム設定
```cmake
-DPLATFORM=OS              # 実機向けビルド
-DPLATFORM=SIMULATOR       # シミュレータ向けビルド
-DCMAKE_BUILD_TYPE=Release # リリースビルド
```

### クライアント/サーバー設定
```cmake
-DWITH_CLIENT=ON           # クライアント機能
-DWITH_SERVER=OFF          # サーバー機能
-DWITH_CLIENT_CHANNELS=ON  # クライアントチャネル
-DWITH_SERVER_CHANNELS=ON  # サーバーチャネル
-DWITH_CLIENT_IOS=OFF      # iOSクライアント（独自実装のためOFF）
```

## ビデオ関連

### ビデオサポート
```cmake
-DWITH_X11=OFF             # X11サポート
-DWITH_WAYLAND=OFF         # Waylandサポート
-DWITH_VAAPI=OFF           # VA-APIサポート
-DWITH_NVENC=OFF           # NVIDIAエンコーディング
-DWITH_NVDEC=OFF           # NVIDIAデコーディング
-DWITH_SWSCALE=OFF         # FFmpegスケーリング
```

### 画像フォーマット
```cmake
-DWITH_JPEG=OFF            # JPEGサポート
-DWITH_PNG=OFF             # PNGサポート
-DWITH_WEBP=OFF            # WebPサポート
```

## オーディオ関連

### オーディオサポート
```cmake
-DWITH_ALSA=OFF            # ALSAサポート
-DWITH_OSS=OFF             # OSSサポート
-DWITH_PULSE=OFF           # PulseAudioサポート
-DWITH_GSM=OFF             # GSMコーデック
-DWITH_GSTREAMER=OFF       # GStreamerサポート
```

### オーディオコーデック
```cmake
-DWITH_OPUS=OFF            # Opusコーデック
-DWITH_LAME=OFF            # MP3エンコーディング
-DWITH_FAAD2=OFF           # AACデコーディング
-DWITH_FAAC=OFF            # AACエンコーディング
-DWITH_SOXR=OFF            # リサンプリング
```

## 入力デバイス関連

### 入力サポート
```cmake
-DWITH_XI=OFF              # X Input Extension
-DWITH_XRANDR=OFF          # X RandR
-DWITH_XEXT=OFF            # X Extension
-DWITH_XCURSOR=OFF         # X Cursor
```

## セキュリティ関連

### 暗号化サポート
```cmake
-DWITH_OPENSSL=ON          # OpenSSLサポート
-DWITH_SSE2=ON             # SSE2サポート
-DWITH_NEON=ON             # NEONサポート
-DWITH_CRYPTO=ON           # 暗号化サポート
-DWITH_GSS=OFF             # GSSAPIサポート
```

## デバッグ関連

### デバッグオプション
```cmake
-DWITH_DEBUG_ALL=OFF       # 全デバッグ機能
-DWITH_DEBUG_CHANNELS=OFF  # チャネルデバッグ
-DWITH_DEBUG_DVC=OFF       # DVCデバッグ
-DWITH_DEBUG_KBD=OFF       # キーボードデバッグ
```

## その他の機能

### 追加機能
```cmake
-DWITH_PCSC=OFF            # PC/SCサポート
-DWITH_SMARTCARD=OFF       # スマートカードサポート
-DWITH_CUPS=OFF            # CUPSサポート
-DWITH_MANPAGES=OFF        # マニュアルページ
-DWITH_SAMPLE=OFF          # サンプルコード
```

## 現在の設定方針

### 1. 最小限の機能セット
- 必要最小限の機能のみを有効化
- 不要な依存関係を排除
- アプリサイズの最適化

### 2. iOSの特性を考慮
- iOS標準機能を優先
- プラットフォーム固有の機能を無効化
- ライセンスの簡素化

### 3. パフォーマンス最適化
- 必要な機能のみをビルド
- メモリ使用量の削減
- 起動時間の短縮

## 注意事項

1. パラメータの変更は慎重に行う必要があります
2. 新しいパラメータを有効化する場合は、依存関係の確認が必要です
3. ライセンスの互換性に注意してください
4. パフォーマンスへの影響を考慮してください 