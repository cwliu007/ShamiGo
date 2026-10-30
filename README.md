# 蝦米GO（ShamiGo）

**蝦米GO是嘸蝦米輸入法的免安裝外殼，並非嘸蝦米官方產品。** Windows 版使用 C++／Win32，Linux 版使用 Fcitx5。軟體由作者規畫、設計與修改，並使用 AI 工具協助開發。

<img width="754" height="138" alt="蝦米GO Windows 操作畫面" src="https://github.com/user-attachments/assets/1f0cbc51-3e99-4f0d-a3ee-1948f947e821" />

## 下載

按 GitHub 頁面的 **Code → Download ZIP**，完整解壓縮並保留原有資料夾結構。嘸蝦米字根須由使用者自行合法取得，可參考[嘸蝦米官方網站](https://boshiamy.com/)。

## Windows：免安裝與安裝

1. 將合法取得的 `liu-uni.tab` 放入 `Packages/Windows/ShamiGo_v0.10.394/LicensedTables/`。
2. 雙擊根目錄 **`Run_Windows.cmd`**，即可免安裝使用。
3. 若希望登入 Windows 後自動啟動，執行 **`Install_Windows.cmd`**，並依提示確認管理員權限。
4. 如需解除安裝，先結束程式，再執行 **`Uninstall_Windows.cmd`**。

免安裝版不會自行設定登入啟動。其他選用字表請參閱[字根資料夾說明](Packages/Windows/ShamiGo_v0.10.394/LicensedTables/README.txt)；詳細操作見 [Windows 使用說明](Packages/Windows/ShamiGo_v0.10.394/ShamiGo_Help.html)。

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

Windows 版提供字根輸入、候選字選取與翻頁、注音與拼音輔助、關聯詞、錯碼提示、自訂字碼、成對標點，以及可調整的浮動候選框。部分功能需對應的合法字根資料。

蝦米GO不是 Windows 原生 TSF 輸入法，部分密碼欄位、系統管理員視窗或特殊文字框可能無法正常使用。Linux 版的功能與快捷鍵尚未完全與 Windows 一致。

## 目前版本

| 平台 | 版本 |
| --- | --- |
| Windows 11（64 位元） | v0.10.394 |
| Debian 13／LMDE 7（64 位元） | v0.10.366-1 |
| macOS | 尚未推出 |

## 安全與授權

輸入輔助程式需要處理按鍵事件，可能觸發防毒軟體偵測；警報是否誤判仍須自行查證。可參考 VirusTotal 的 [Windows 主程式](https://www.virustotal.com/gui/file/2d2f0a73b06816080f8275c1304157f9cf7c1cf9f3a279a352f1118fd1af4373/detection)、[安裝工具](https://www.virustotal.com/gui/file/246729bcc5974a5f20fb5cc91ed725e6e57cafc384a3c5f7aa30b900972cb4fe/detection)及 [Linux 套件](https://www.virustotal.com/gui/file/f7af230b1f4d6b637a357a465c580975ae9a53cbe87d8ea4493e08c0ca01930f/detection)掃描紀錄，並以 [SHA256SUMS.txt](SHA256SUMS.txt) 核對檔案。

蝦米GO採**免費使用、保留著作權**方式提供。使用前請閱讀 [授權條款](LICENSE.md)及[第三方資料來源聲明](Packages/Windows/ShamiGo_v0.10.394/THIRD_PARTY_NOTICES.md)。
