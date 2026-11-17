# 蝦米GO（ShamiGo）

**蝦米GO 是嘸蝦米輸入法的輸入輔助外殼，並非嘸蝦米官方產品。** Windows、macOS、Linux 均提供可安裝的公開版。軟體由作者規畫、設計與修改，並使用 AI 工具協助開發。

<img width="754" height="138" alt="蝦米GO Windows 操作畫面" src="https://github.com/user-attachments/assets/1f0cbc51-3e99-4f0d-a3ee-1948f947e821" />

## 下載

- **[Windows／Linux v0.10.616 ZIP](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.616/ShamiGo_v0.10.616_Windows_Linux.zip)**
- **[macOS Apple Silicon v0.10.616 ZIP](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.616/ShamiGo_v0.10.616_macOS.zip)**
- [下載檔案 SHA-256](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.616/SHA256SUMS.txt)

公開版**不包含私人嘸蝦米字根或產品原始碼**。請自行合法取得所需的 `liu-uni.tab`，可參考[嘸蝦米官方網站](https://boshiamy.com/)。沒有字根仍可先安裝，之後再補入並重新啟動即可使用中文輸入。

## Windows：免安裝與安裝

**Windows 11 x64，程式版本 v0.10.616。** 在檔案總管中開啟 ZIP，可直接雙擊 `Install_Windows.cmd` 安裝，或 `Run_Windows.cmd` 免安裝使用；也可以先完整解壓縮再執行。

- `Install_Windows.cmd`：安裝、設定登入時啟動。
- `Run_Windows.cmd`：免安裝使用，不設定開機啟動。
- `Open_LicensedTables.cmd`：開啟使用者字根資料夾，放入合法的 `liu-uni.tab` 後重新啟動蝦米GO即可，不必重裝。
- `Uninstall_Windows.cmd`：關閉蝦米GO並完整移除目前使用者的已安裝檔案、設定、快取及字根副本；保留原始下載 ZIP。

## Linux：Debian 13／LMDE 7

需要 amd64 與 Fcitx5。完整解壓縮後執行：

```sh
sh Install_Linux.sh
```

如需匯入字根，將合法 `liu-uni.tab` 放入根目錄的 `LicensedTables/`，再執行：

```sh
shamigo-setup import-data --source /你的實際路徑/LicensedTables
```

在 Fcitx5 設定中加入蝦米GO；解除安裝執行 `sh Uninstall_Linux.sh`。**此 ZIP 的 Linux 預編譯套件仍為 v0.10.366-1**，不是重新編譯的 v616 Linux 程式。

## macOS：Apple Silicon

適用 Apple Silicon（arm64），macOS 14 或更新版本。已包含編譯好的 v0.10.616 `ShamiGo.app`，**不必自行編譯，也不必手動解壓縮**。

### 終端機自動下載並安裝

開啟「終端機」（Terminal），完整複製以下指令貼上執行。ZIP 會保留在「下載項目」，方便以後解除安裝：

```bash
(
  set -euo pipefail
  BASE='https://github.com/cwliu007/ShamiGo/releases/download/v0.10.616'
  ZIP="$HOME/Downloads/ShamiGo_v0.10.616_macOS.zip"
  SUM="$HOME/Downloads/ShamiGo_v0.10.616_SHA256SUMS.txt"
  mkdir -p "$HOME/Downloads"
  curl -fL --retry 3 -o "$ZIP" "$BASE/ShamiGo_v0.10.616_macOS.zip"
  curl -fL --retry 3 -o "$SUM" "$BASE/SHA256SUMS.txt"
  (cd "$HOME/Downloads"; grep ' ShamiGo_v0.10.616_macOS.zip$' "$SUM" | shasum -a 256 -c -)
  DIR="$(mktemp -d -t shamigo-install)"
  trap 'rm -rf "$DIR"' EXIT
  ditto -x -k "$ZIP" "$DIR"
  /bin/bash "$DIR/Install_ShamiGo_Mac.command"
)
```

安裝完成後，請**登出再登入**，至「系統設定 → 鍵盤 → 文字輸入 → 編輯」加入蝦米GO。

### 一鍵開啟字根資料夾

請在終端機執行下列指令；會自動建立並以 Finder 開啟資料夾，再將自行合法取得的 `liu-uni.tab` 拖入：

```bash
mkdir -p "$HOME/Library/Application Support/ShamiGo/LicensedTables" && open "$HOME/Library/Application Support/ShamiGo/LicensedTables"
```

補入字根後請完整結束輸入法並重新登入，使字根載入生效。

### 終端機完整解除安裝

直接執行下列指令，**優先使用下載項目內原本的 ZIP**；找不到時才重新下載。此操作將**永久刪除**目前使用者的 ShamiGo App、合法字根副本、設定、字典與快取，並在成功後移除已下載的公開 ZIP。請先備份自己需要的資料。

```bash
(
  set -euo pipefail
  BASE='https://github.com/cwliu007/ShamiGo/releases/download/v0.10.616'
  ZIP="$HOME/Downloads/ShamiGo_v0.10.616_macOS.zip"
  SUM="$HOME/Downloads/ShamiGo_v0.10.616_SHA256SUMS.txt"
  printf '確定永久刪除蝦米GO及所有使用者字根和設定？輸入 YES 繼續：'
  read -r CONFIRM
  [ "$CONFIRM" = 'YES' ] || { echo '已取消'; exit 1; }
  if [ ! -f "$ZIP" ]; then
    curl -fL --retry 3 -o "$ZIP" "$BASE/ShamiGo_v0.10.616_macOS.zip"
  fi
  curl -fL --retry 3 -o "$SUM" "$BASE/SHA256SUMS.txt"
  (cd "$HOME/Downloads"; grep ' ShamiGo_v0.10.616_macOS.zip$' "$SUM" | shasum -a 256 -c -)
  DIR="$(mktemp -d -t shamigo-uninstall)"
  trap 'rm -rf "$DIR"' EXIT
  ditto -x -k "$ZIP" "$DIR"
  /bin/bash "$DIR/Uninstall_ShamiGo_Mac.command"
  rm -f -- "$ZIP" "$SUM"
)
```

完成後登出再登入；不會移除 ABC 或其他輸入法。解除安裝僅處理**目前使用者**的安裝位置，不會以管理員權限清除其他帳號或系統共用 App。

**macOS 安全性提醒：** 此版本使用 ad-hoc 簽章，尚未經 Apple Developer ID 正式簽署與公證；終端機安裝不保證避開 Gatekeeper。如遭阻擋，請依 [Apple 官方個別允許方式](https://support.apple.com/zh-tw/102445)操作，不要關閉 macOS 的安全保護。

## 功能與相容性

Windows 版提供繁簡中文輸入、英文拼字檢查與建議、快碼提示、注音／拼音輔助、日文模式、快捷鍵切換、稻穗候選框、查字泡泡框，以及可調整的打字聲。新版 Windows 與 macOS 改善英文搜尋視窗的捲軸、靜音搜尋及搜尋後清空輸入框。不同平台的細部功能可能尚未完全相同。

## 目前版本

| 平台 | 實際程式版本 |
| --- | --- |
| Windows 11（x64） | v0.10.616 |
| macOS 14+（Apple Silicon arm64） | v0.10.616 |
| Debian 13／LMDE 7（amd64） | v0.10.366-1（預編譯套件） |

本次統一發行版號為 **v0.10.616**；Linux 保留原有預編譯檔的真實版號。

## 安全與授權

輸入輔助程式可能因處理鍵盤事件而觸發安全軟體偵測；請核對發行檔 SHA-256，勿任意停用系統保護。蝦米GO**免費使用、保留著作權**；請參閱 [授權條款](LICENSE.md)與[第三方資料來源聲明](THIRD_PARTY_NOTICES.md)。
