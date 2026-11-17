# 蝦米GO（ShamiGo）

**蝦米GO是嘸蝦米輸入法的免安裝外殼，並非嘸蝦米官方產品。** Windows 版使用 C++／Win32，Linux 版使用 Fcitx5。軟體由作者規畫、設計與修改，並使用 AI 工具協助開發。

<img width="754" height="138" alt="蝦米GO Windows 操作畫面" src="https://github.com/user-attachments/assets/1f0cbc51-3e99-4f0d-a3ee-1948f947e821" />

## 下載

下載 **[ShamiGo v0.10.607 公開安裝 ZIP](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.607/ShamiGo_v0.10.607_Public.zip)**，完整解壓縮並保留資料夾結構。嘸蝦米字根須自行合法取得，可參考[嘸蝦米官方網站](https://boshiamy.com/)；本公開版不含字根與開發原始碼。

## Windows：免安裝與安裝

1. 將合法取得的 `liu-uni.tab` 放入 `Packages/Windows/ShamiGo/LicensedTables/`。
2. 雙擊根目錄 **`Run_Windows.cmd`**，即可免安裝使用。
3. 若希望登入 Windows 後自動啟動，執行 **`Install_Windows.cmd`**，並依提示確認管理員權限。
4. 如需解除安裝，先結束程式，再執行 **`Uninstall_Windows.cmd`**。

免安裝版不會自行設定登入啟動。其他字根說明與完整 Windows 操作說明，請參閱下載 ZIP 內的 `LicensedTables/README.txt` 與 `ShamiGo_Help.html`。

## Linux：Debian 13／LMDE 7

適用 64 位元（amd64），需搭配 Fcitx5。解壓縮後，在根目錄執行：

```sh
sh Install_Linux.sh
```

安裝完成後，匯入合法取得的字根資料：

```sh
shamigo-setup import-data --source /path/to/LicensedTables
```

請將路徑替換為實際字根資料夾，再於 Fcitx5 設定中加入蝦米GO。解除安裝執行 `sh Uninstall_Linux.sh`。若在 Windows 使用 VirtualBox，可使用 `Install_Linux_VM_from_Windows.cmd` 輔助安裝。

## 功能與相容性

Windows 版提供繁簡中文嘸蝦米輸入、英文拼字檢查與建議、候選字選取、快碼提示、注音與拼音輔助、日文模式、自訂字碼、快捷鍵切換，以及支援深淺主題的稻穗浮動框。另有英文詞義泡泡框、英漢及漢英搜尋、查字歷史、字級調整與可調音量的打字聲（預設靜音）。部分功能需要使用者自行提供合法字根。

蝦米GO不是 Windows 原生 TSF 輸入法，部分密碼欄位、系統管理員視窗或特殊文字框可能無法正常使用。Linux 版的功能與快捷鍵尚未完全與 Windows 一致。

## 目前版本

| 平台 | 版本 |
| --- | --- |
| Windows 11（64 位元） | v0.10.607 |
| Debian 13／LMDE 7（64 位元） | v0.10.366-1 |
| macOS | 此公開 ZIP 尚未提供可直接安裝版本 |

## 安全與授權

輸入輔助程式需要處理按鍵事件，可能觸發防毒軟體偵測。請以 [SHA256SUMS.txt](SHA256SUMS.txt) 核對此版下載檔，勿為了安裝任意關閉系統安全防護。本公開版不含私人字根、ICQ 原音效或開發原始碼。

蝦米GO採**免費使用、保留著作權**方式提供。使用前請閱讀 [授權條款](LICENSE.md)及[第三方資料來源聲明](THIRD_PARTY_NOTICES.md)。
