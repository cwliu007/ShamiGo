# 蝦米GO（ShamiGo）

**蝦米GO是嘸蝦米輸入法的免安裝外殼，並非嘸蝦米官方產品。** Windows 版使用 C++／Win32，macOS 版使用 Apple InputMethodKit，Linux 版使用 Fcitx5。軟體由作者規畫、設計與修改，並使用 AI 工具協助開發。

<img width="754" height="138" alt="蝦米GO Windows 操作畫面" src="https://github.com/user-attachments/assets/1f0cbc51-3e99-4f0d-a3ee-1948f947e821" />

## 下載

- **[Windows／Linux 公開版 ZIP](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.607-onefolder/ShamiGo_v0.10.607_OneFolder_Windows_Linux.zip)**
- **[macOS Apple Silicon v0.10.610 公開版 ZIP](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.610-macos/ShamiGo_v0.10.610_macOS_arm64_Public.zip)**

嘸蝦米字根須自行合法取得，可參考[嘸蝦米官方網站](https://boshiamy.com/)；公開版不包含私人字根或開發原始碼。**即使尚無字根，也可以先安裝；之後補入 `liu-uni.tab` 並重新啟動即可使用中文輸入。**

## Windows：免安裝與安裝

1. 可以直接在 Windows 檔案總管開啟下載的 ZIP，雙擊其中的 **`Install_Windows.cmd`** 安裝，不必先手動解壓縮。
2. 若要免安裝使用，執行 **`Run_Windows.cmd`**；它也支援從 ZIP 內直接啟動。免安裝版不會自行設定登入啟動。
3. 字根統一放在 `LicensedTables/`。完整解壓縮後，可將合法取得的 `liu-uni.tab` 放進套件根目錄的此資料夾；若已安裝，也可以執行 **`Open_LicensedTables.cmd`**，將字根放進開啟的使用者資料夾。補入後完整關閉並重新啟動蝦米GO，不必重新安裝。
4. 如需完整解除安裝，執行 **`Uninstall_Windows.cmd`**。它會先關閉正在執行的蝦米GO，再移除自動啟動、已安裝檔案、設定及快取；不會刪除原始下載 ZIP。

沒有字根時仍可安裝並使用英文模式。其他操作說明請參閱 ZIP 中的 `LicensedTables/README.txt` 與 `Packages/Windows/ShamiGo/ShamiGo_Help.html`。

## Linux：Debian 13／LMDE 7

適用 64 位元（amd64），需搭配 Fcitx5。完整解壓縮後，在根目錄執行：

```sh
sh Install_Linux.sh
```

安裝使用套件內的預編譯 `.deb`，不需要自行編譯。日後如需匯入合法字根，將 `liu-uni.tab` 放在套件根目錄的 `LicensedTables/`，執行：

```sh
shamigo-setup import-data --source /path/to/LicensedTables
```

將路徑改為實際字根資料夾，再於 Fcitx5 設定中加入蝦米GO。解除安裝執行 `sh Uninstall_Linux.sh`。若在 Windows 使用 VirtualBox，可使用 `Install_Linux_VM_from_Windows.cmd` 輔助安裝。

## macOS：Apple Silicon

適用 **macOS 14 以上、Apple Silicon（arm64）**，不支援 Intel Mac。公開 ZIP 內已有編譯完成的 `ShamiGo.app`，不需要自行編譯。

### 安裝：終端機下載 ZIP，並保留在「下載項目」

在 Mac 打開「終端機」（Terminal），**複製以下整段指令貼上執行**：

```bash
(
  set -euo pipefail
  ZIP="$HOME/Downloads/ShamiGo_v0.10.610_macOS_arm64_Public.zip"
  URL="https://github.com/cwliu007/ShamiGo/releases/download/v0.10.610-macos/ShamiGo_v0.10.610_macOS_arm64_Public.zip"
  mkdir -p "$HOME/Downloads"
  if [[ ! -f "$ZIP" ]]; then
    curl -fL --retry 3 -o "$ZIP" "$URL"
  fi
  printf '%s  %s\n' '57ed95e9b656d730f021b1c7eadb95c1f9b0693381932bd6f5a91fa88ac346f3' "$ZIP" | shasum -a 256 -c -
  DIR="$(mktemp -d -t shamigo-install)"
  trap 'rm -rf "$DIR"' EXIT
  ditto -x -k "$ZIP" "$DIR"
  /bin/bash "$DIR/Install_ShamiGo_Mac.command"
  echo "完成：安裝 ZIP 已保留在 $ZIP"
)
```

安裝後從 Apple 選單**登出再登入**，到「系統設定 → 鍵盤 → 文字輸入 → 編輯」加入 **蝦米GO／ShamiGo**。**不要使用 `sudo`**。

### 字根資料夾：一鍵用 Finder 開啟

macOS 的 `~/Library` 預設隱藏。要找到自己的字根資料夾，只需在「終端機」執行：

```bash
mkdir -p "$HOME/Library/Application Support/ShamiGo/LicensedTables"
open "$HOME/Library/Application Support/ShamiGo/LicensedTables"
```

Finder 會直接開啟該資料夾。將自己合法取得的 `liu-uni.tab` 放進去，登出再登入即可載入中文輸入；沒有字根也能先安裝。也可在 Finder 按 **Command + Shift + G**，輸入 `~/Library/Application Support/ShamiGo/LicensedTables`。

### 完整解除安裝：先用 Downloads 的 ZIP，找不到才下載

**注意：以下操作會永久刪除目前使用者的蝦米GO程式、私人字根、英文字典、設定與快取，無法還原。請先自行備份需要留下的資料。** 解除安裝不影響 ABC 或其他輸入法。

在「終端機」複製執行：

```bash
(
  set -euo pipefail
  ZIP="$HOME/Downloads/ShamiGo_v0.10.610_macOS_arm64_Public.zip"
  URL="https://github.com/cwliu007/ShamiGo/releases/download/v0.10.610-macos/ShamiGo_v0.10.610_macOS_arm64_Public.zip"
  if [[ ! -f "$ZIP" ]]; then
    echo '下載項目找不到安裝 ZIP，正在重新下載……'
    mkdir -p "$HOME/Downloads"
    curl -fL --retry 3 -o "$ZIP" "$URL"
  fi
  printf '%s  %s\n' '57ed95e9b656d730f021b1c7eadb95c1f9b0693381932bd6f5a91fa88ac346f3' "$ZIP" | shasum -a 256 -c -
  read -r -p '確定永久刪除蝦米GO及所有字根、設定？輸入 YES：' ANSWER
  [[ "$ANSWER" == YES ]] || { echo '已取消'; exit 1; }
  DIR="$(mktemp -d -t shamigo-uninstall)"
  trap 'rm -rf "$DIR"' EXIT
  ditto -x -k "$ZIP" "$DIR"
  /bin/bash "$DIR/Uninstall_ShamiGo_Mac.command"
  launchctl bootout "gui/$(id -u)/tw.shamigo.inputmethod.switcher" >/dev/null 2>&1 || true
  defaults delete tw.shamigo.inputmethod.macos >/dev/null 2>&1 || true
  defaults delete tw.shamigo.inputmethod.mac >/dev/null 2>&1 || true
  for PATH_TO_REMOVE in \
    "$HOME/Library/Application Support/ShamiGo" \
    "$HOME/Library/Caches/ShamiGo" \
    "$HOME/Library/Logs/ShamiGo" \
    "$HOME/Library/LaunchAgents/tw.shamigo.inputmethod.switcher.plist" \
    "$HOME/Library/Preferences/tw.shamigo.inputmethod.macos.plist" \
    "$HOME/Library/Preferences/tw.shamigo.inputmethod.mac.plist" \
    "$HOME/Library/Saved Application State/tw.shamigo.inputmethod.macos.savedState"; do
    [[ ! -L "$PATH_TO_REMOVE" ]] || { echo "發現連結，已停止清除：$PATH_TO_REMOVE"; exit 1; }
    rm -rf -- "$PATH_TO_REMOVE"
  done
  rm -f -- "$ZIP"
  echo '蝦米GO程式、字根、設定與安裝 ZIP 已移除。請登出再登入。'
)
```

若曾由管理員在 `/Library/Input Methods/ShamiGo.app` 安裝系統共用版本，上述**目前使用者**的解除安裝不會動到該全系統檔案；請另外由管理員處理。

### macOS 安全性

目前公開的 v0.10.610 使用 ad-hoc 簽章，未經 Apple Developer ID 簽署與 Apple 公證。終端機下載**不代表可以繞過 Gatekeeper**；若系統阻擋，請依 [Apple 官方個別允許步驟](https://support.apple.com/zh-tw/102445)操作，不要全面關閉 macOS 安全防護。

## 功能與相容性

Windows 版提供繁簡中文嘸蝦米輸入、英文拼字檢查與建議、候選字選取、快碼提示、注音與拼音輔助、日文模式、自訂字碼、快捷鍵切換，以及支援深淺主題的稻穗浮動框。另有英文詞義泡泡框、英漢及漢英搜尋、查字歷史、字級調整與可調音量的打字聲（預設靜音）。部分功能需要使用者自行提供合法字根。

蝦米GO不是 Windows 原生 TSF 輸入法，部分密碼欄位、系統管理員視窗或特殊文字框可能無法正常使用。macOS 與 Linux 版的功能及快捷鍵不一定與 Windows 完全一致。

## 目前版本

| 平台 | 版本 |
| --- | --- |
| Windows 11（64 位元） | v0.10.607 |
| Debian 13／LMDE 7（64 位元） | v0.10.366-1 |
| macOS 14+（Apple Silicon arm64） | v0.10.610 |

目前三平台的**實際執行檔版本尚未相同**。這裡列出的是真實建置版本；必須重新編譯並發佈 Windows、Linux，才能將三者真正統一到同一版本。不能只修改 README 或檔名。

## 安全與授權

輸入輔助程式需要處理按鍵事件，可能觸發防毒軟體偵測。請以 [Windows／Linux SHA-256](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.607-onefolder/RELEASE_SHA256SUMS.txt) 或 [macOS SHA-256](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.610-macos/ShamiGo_macOS_SHA256SUMS.txt) 核對下載檔，勿為了安裝任意關閉系統安全防護。本公開版不包含私人字根、ICQ 原音效或開發原始碼。

蝦米GO採**免費使用、保留著作權**方式提供。使用前請閱讀 [授權條款](LICENSE.md)及[第三方資料來源聲明](THIRD_PARTY_NOTICES.md)。
