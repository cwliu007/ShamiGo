蝦米GO macOS Apple Silicon 公開版 (v0.10.611)

安裝（已編譯，不需自行編譯）：
  1. ZIP 完整解壓縮。
  2. /bin/bash Install_ShamiGo_Mac.command
  3. 登出再登入，到「系統設定 → 鍵盤 → 文字輸入」加入蝦米GO。

字根：在 Terminal 輸入以下兩行可用 Finder 直接開啟使用者字根資料夾：
  mkdir -p "$HOME/Library/Application Support/ShamiGo/LicensedTables"
  open "$HOME/Library/Application Support/ShamiGo/LicensedTables"
合法取得的 liu-uni.tab 請放入此資料夾，登出再登入使輸入法重新載入。

完整解除安裝（包含字根、設定、字典和快取）：
  /bin/bash Uninstall_ShamiGo_Mac.command
若透過 GitHub README 的終端機指令安裝，該指令會保留 ZIP 在「下載項目」，解除安裝優先使用此 ZIP；找不到才下載。

注意：目前為 ad-hoc 簽章、未經 Apple Developer ID 簽署及公證；macOS 仍可能阻擋，請依系統提供的個別允許流程處理。
