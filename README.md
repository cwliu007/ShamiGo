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

適用 **macOS 14 或更新版本的 Apple Silicon（arm64）Mac**，不支援 Intel Mac。公開版已包含編譯完成的 `ShamiGo.app`，不需要自行編譯。

### 自動下載與安裝（終端機）

開啟 Mac 的「終端機」（Terminal），**複製以下整段指令並貼上執行**。不需要事先下載或解壓縮 ZIP：

```bash
(
  set -e
  DIR="$(mktemp -d -t shamigo-install)"
  trap 'rm -rf "$DIR"' EXIT
  curl -fL --retry 3 -o "$DIR/ShamiGo.zip" \
    "https://github.com/cwliu007/ShamiGo/releases/download/v0.10.610-macos/ShamiGo_v0.10.610_macOS_arm64_Public.zip"
  printf '%s  %s\n' \
    '57ed95e9b656d730f021b1c7eadb95c1f9b0693381932bd6f5a91fa88ac346f3' \
    "$DIR/ShamiGo.zip" | shasum -a 256 -c -
  ditto -x -k "$DIR/ShamiGo.zip" "$DIR"
  /bin/bash "$DIR/Install_ShamiGo_Mac.command"
)
```

指令會從 [GitHub macOS 公開版](https://github.com/cwliu007/ShamiGo/releases/tag/v0.10.610-macos) 下載 ZIP，驗證 SHA-256，暫時解壓並執行安裝程式，最後清理暫存檔。**不需要使用 `sudo`。**

安裝完成後，請從 Apple 選單**登出再登入**，再到「系統設定 → 鍵盤 → 文字輸入 → 編輯」加入 **蝦米GO／ShamiGo**。

### 自動下載與解除安裝（終端機）

若要解除安裝，直接在「終端機」貼上以下整段指令，**不需要保留之前下載的 ZIP**：

```bash
(
  set -e
  DIR="$(mktemp -d -t shamigo-uninstall)"
  trap 'rm -rf "$DIR"' EXIT
  curl -fL --retry 3 -o "$DIR/ShamiGo.zip" \
    "https://github.com/cwliu007/ShamiGo/releases/download/v0.10.610-macos/ShamiGo_v0.10.610_macOS_arm64_Public.zip"
  printf '%s  %s\n' \
    '57ed95e9b656d730f021b1c7eadb95c1f9b0693381932bd6f5a91fa88ac346f3' \
    "$DIR/ShamiGo.zip" | shasum -a 256 -c -
  ditto -x -k "$DIR/ShamiGo.zip" "$DIR"
  /bin/bash "$DIR/Uninstall_ShamiGo_Mac.command"
)
```

這會重新下載並驗證同一份公開版 ZIP，再執行內附的解除安裝程式。解除安裝會停止並移除目前使用者的 ShamiGo 輸入法 App；**個人字根和設定資料會保留**，也不會移除其他輸入法。完成後請登出再登入。

### 字根資料

沒有字根也能先安裝。日後將自行合法取得的 `liu-uni.tab` 放在：

`~/Library/Application Support/ShamiGo/LicensedTables/liu-uni.tab`

補入後登出再登入，讓蝦米GO重新載入字根資料。

### macOS 安全性提醒

**目前 GitHub 上公開的 macOS v0.10.610 使用 ad-hoc 簽章，尚未經 Apple Developer ID 正式簽署與公證。** 透過終端機下載和安裝**不保證避開 Gatekeeper 的安全檢查**。若 macOS 阻擋開啟，請核對來源並依 [Apple 官方個別允許步驟](https://support.apple.com/zh-tw/102445)處理；請勿全面關閉系統防護。若系統顯示 App 已損壞或含惡意軟體，請停止安裝。

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
