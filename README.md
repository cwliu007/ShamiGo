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

適用 **macOS 14 或更新版本、Apple Silicon（arm64）**，不支援 Intel Mac。下載 macOS 公開版 ZIP 並完整解壓縮，在「終端機」切換至該資料夾後執行：

```sh
/bin/bash Install_ShamiGo_Mac.command
```

此版包含已編譯的 `ShamiGo.app`，**不需要自行編譯**。安裝後請登出並重新登入，再到「系統設定 → 鍵盤 → 文字輸入」加入蝦米GO。

沒有字根也能先安裝。若要補入合法的 `liu-uni.tab`，可將它放入解壓縮套件的 `LicensedTables/`，再執行 `/bin/bash Install_External_Tables.sh LicensedTables` 匯入，並重新登入。

**注意：macOS 公開版目前使用 ad-hoc 簽章，尚未經 Apple 公證。** 如果遭到 macOS 安全性功能阻擋，請依「系統設定 → 隱私權與安全性」中的個別允許流程處理，勿全面關閉系統保護。

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
