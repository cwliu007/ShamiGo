# 蝦米GO（ShamiGo）

**蝦米GO是嘸蝦米輸入法的免安裝外殼，並非嘸蝦米官方產品。** Windows 版使用 C++／Win32，macOS 版使用 Apple InputMethodKit，Linux 版使用 Fcitx5。軟體由作者規畫、設計與修改，並使用 AI 工具協助開發。

<img width="754" height="138" alt="蝦米GO Windows 操作畫面" src="https://github.com/user-attachments/assets/1f0cbc51-3e99-4f0d-a3ee-1948f947e821" />

## 下載

- **[Windows／Linux v0.10.607 OneFolder 公開版 ZIP](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.607-onefolder/ShamiGo_v0.10.607_OneFolder_Windows_Linux.zip)**
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

適用 **macOS 14 或更新版本、Apple Silicon（arm64）**，不支援 Intel Mac。公開版已包含編譯完成的 `ShamiGo.app`，使用者**不需要自行編譯，也不必手動搬移 App**。

### 複製指令到終端機，自動下載並安裝（建議）

開啟 Mac 的「終端機」（Terminal），**完整複製以下整段指令，貼上後按 Return**：

```bash
(
  set -e
  DIR="$(mktemp -d -t shamigo-install)"
  trap 'rm -rf "$DIR"' EXIT
  curl -fL --retry 3 -o "$DIR/ShamiGo.zip" \
    "https://github.com/cwliu007/ShamiGo/releases/download/v0.10.610-macos/ShamiGo_v0.10.610_macOS_arm64_Public.zip"
  printf '%s  %s\n' \
    "57ed95e9b656d730f021b1c7eadb95c1f9b0693381932bd6f5a91fa88ac346f3" \
    "$DIR/ShamiGo.zip" | shasum -a 256 -c -
  ditto -x -k "$DIR/ShamiGo.zip" "$DIR"
  /bin/bash "$DIR/Install_ShamiGo_Mac.command"
)
```

指令會從**本專案 GitHub Release**下載 v0.10.610、驗證 SHA-256、暫時解壓，然後執行套件內的安裝程式；成功或失敗後都會清理暫存資料。安裝在**目前使用者**的 `~/Library/Input Methods/ShamiGo.app`，不用以 `sudo` 執行指令。若校驗失敗，安裝會自動停止。

**安裝完成後，請從 Apple 選單登出再登入**，接著到「系統設定 → 鍵盤 → 文字輸入 → 編輯 → ＋」加入 **蝦米GO／ShamiGo**。如果仍找不到，請重新啟動 Mac，再檢查輸入來源清單。

### 字根與更新

沒有字根也能先安裝，英文模式仍可使用。日後自行合法取得 `liu-uni.tab`，放入：

`~/Library/Application Support/ShamiGo/LicensedTables/liu-uni.tab`

在 Finder 按 **Command + Shift + G** 可直接開啟上述資料夾位置（不含最後的檔名），沒有資料夾時請自行建立。補入字根後登出再登入，讓輸入法重新載入。

若已下載並解壓縮 ZIP，也可在「終端機」進入解壓後的資料夾，執行 `/bin/bash Install_ShamiGo_Mac.command`。解除安裝可在相同資料夾執行 `/bin/bash Uninstall_ShamiGo_Mac.command`。

**已知問題：** macOS v0.10.610 的英文詞典搜尋欄，在中文輸入模式下可能無法正常輸入英文字母。v0.10.611 的修正正在進行 Mac 原生編譯驗證；完成前，GitHub 仍提供 v0.10.610，不會以未修正的執行檔冒充新版。

### macOS 安全性提醒

**此公開版使用 ad-hoc 簽章，尚未經 Apple Developer ID 正式簽署及公證。** 終端機自動安裝並不表示可繞過 Gatekeeper。若系統阻擋開啟，請先確認來源與檔案校驗，並依 [Apple 官方「隱私權與安全性」個別允許步驟](https://support.apple.com/zh-tw/102445)處理；若系統提示程式損壞或含惡意軟體，請停止安裝。**不要使用 `sudo`、關閉 Gatekeeper，或移除系統的安全性檢查來強行安裝。**

## 功能與相容性

Windows 版提供繁簡中文嘸蝦米輸入、英文拼字檢查與建議、候選字選取、快碼提示、注音與拼音輔助、日文模式、自訂字碼、快捷鍵切換，以及支援深淺主題的稻穗浮動框。另有英文詞義泡泡框、英漢及漢英搜尋、查字歷史、字級調整與可調音量的打字聲（預設靜音）。部分功能需要使用者自行提供合法字根。

蝦米GO不是 Windows 原生 TSF 輸入法，部分密碼欄位、系統管理員視窗或特殊文字框可能無法正常使用。macOS 與 Linux 版的功能及快捷鍵不一定與 Windows 完全一致。

## 目前版本

| 平台 | 版本 |
| --- | --- |
| Windows 11（64 位元） | v0.10.607 OneFolder |
| Debian 13／LMDE 7（64 位元） | v0.10.366-1 |
| macOS 14+（Apple Silicon arm64） | v0.10.610 |

## 安全與授權

輸入輔助程式需要處理按鍵事件，可能觸發防毒軟體偵測。請以 [Windows／Linux SHA-256](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.607-onefolder/RELEASE_SHA256SUMS.txt) 或 [macOS SHA-256](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.610-macos/ShamiGo_macOS_SHA256SUMS.txt) 核對下載檔，勿為了安裝任意關閉系統安全防護。本公開版不包含私人字根、ICQ 原音效或開發原始碼。

蝦米GO採**免費使用、保留著作權**方式提供。使用前請閱讀 [授權條款](LICENSE.md)及[第三方資料來源聲明](THIRD_PARTY_NOTICES.md)。
