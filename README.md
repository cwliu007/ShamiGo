# 蝦米GO（ShamiGo）

**蝦米GO是嘸蝦米輸入法的免安裝外殼，不是一套新的嘸蝦米輸入法，也不是官方產品。** 它以 C++／Win32 提供 Windows 可攜式輸入介面，Linux 使用 Fcitx5；作者負責實際規畫、設計與修改，並利用 AI 工具協助撰寫程式。

<img width="754" height="138" alt="蝦米GO Windows 操作畫面" src="https://github.com/user-attachments/assets/1f0cbc51-3e99-4f0d-a3ee-1948f947e821" />

**本儲存庫不含嘸蝦米版權字根，使用者必須自行合法取得字根資料。** 可參考[嘸蝦米官方網站](https://boshiamy.com/)的合法取得方式。本專案並未獲得嘸蝦米官方認可或背書。

## 下載

點選 GitHub 頁面上 **Code → Download ZIP**，下載後**完整解壓縮**並保留資料夾結構。Windows 版可免安裝執行；Linux 版須安裝 `.deb`。請勿只從壓縮檔檢視器執行個別檔案，否則可能找不到程式或字根。

## Windows：免安裝（建議）

1. 將自行合法取得的 `liu-uni.tab` 放入 `Packages/Windows/ShamiGo_v0.10.394/LicensedTables/`；其他選用字根資料請參照[字根資料夾說明](Packages/Windows/ShamiGo_v0.10.394/LicensedTables/README.txt)。
2. 雙擊根目錄的 **`Run_Windows.cmd`**，即可直接啟動。無須安裝，也不會設定自動啟動。
3. 在 Windows 通知區的蝦米GO圖示按右鍵，可調整設定或結束程式。

若需要登入後自動啟動，請改執行 **`Install_Windows.cmd`**，並依提示確認 Windows 管理員權限（UAC）。解除安裝可執行 **`Uninstall_Windows.cmd`**；不影響原本下載的可攜式資料夾。若使用者的登入帳號與 UAC 管理員帳號不同，受保護安裝可能因安全限制而拒絕，請參考操作提示。

完整功能及操作請見 [Windows 使用說明](Packages/Windows/ShamiGo_v0.10.394/ShamiGo_Help.html)。

## Linux：Debian 13／LMDE 7

適用 64 位元（amd64），搭配 Fcitx5。在下載資料夾開啟終端機，執行：

```sh
sh Install_Linux.sh
```

接著匯入自行合法取得的字根資料：

```sh
shamigo-setup import-data --source /path/to/LicensedTables
```

將 `/path/to/LicensedTables` 換成實際資料夾，再重新啟動 Fcitx5，於輸入法設定加入蝦米GO。移除時執行 `sh Uninstall_Linux.sh`。Windows VirtualBox 來賓系統的安裝輔助入口為 `Install_Linux_VM_from_Windows.cmd`，請依相關畫面操作；Linux／Wayland 的實際操作可能與 Windows 版有所差異。

## 主要功能與限制

Windows 版提供嘸蝦米字根輸入、候選選字與翻頁、注音與拼音輔助、自訂字碼、錯碼提示、關聯詞、成對標點以及可調整的候選框與顯示時間。部分功能需使用者自行提供合法的附加字根檔。Linux 版目前與 Windows 的功能及快捷鍵**尚未完全一致**。

本程式是可攜式輸入外殼，並非 Windows 原生 TSF 輸入法；在密碼欄位、權限較高的視窗、特殊文字框或部分遊戲內可能有相容性限制。

## 版本

| 項目 | 版本 |
| --- | --- |
| 個人完整 ZIP 封裝（不公開散布） | v0.10.395 |
| Windows 11 x64 主程式 | **v0.10.394** |
| Linux Debian 13／LMDE 7 amd64 | **v0.10.366-1** |
| macOS | 尚未推出 |

此輪更新主要為文件與 GitHub 發行安全性維護；Windows／Linux 執行檔未重新編譯。封裝版號與程式版號不同，並不表示輸入核心已更新。

## VirusTotal 與安全查驗

輸入法需要處理按鍵事件並與視窗互動，這類行為可能觸發防毒軟體的啟發式偵測，**不能直接認定警報是誤判**。若有疑慮請勿執行。以下是原有執行檔的公開掃描紀錄，檢查結果可能隨日期變化：

- [Windows v0.10.394 主程式掃描報告](https://www.virustotal.com/gui/file/2d2f0a73b06816080f8275c1304157f9cf7c1cf9f3a279a352f1118fd1af4373/detection)
- [Windows 安裝輔助程式掃描報告](https://www.virustotal.com/gui/file/246729bcc5974a5f20fb5cc91ed725e6e57cafc384a3c5f7aa30b900972cb4fe/detection)
- [Linux v0.10.366-1 套件掃描報告](https://www.virustotal.com/gui/file/f7af230b1f4d6b637a357a465c580975ae9a53cbe87d8ea4493e08c0ca01930f/detection)

掃描與雜湊值對應特定執行檔；請使用 [SHA256SUMS.txt](SHA256SUMS.txt) 核對下載的檔案。原報告登錄於 2026 年 10 月 29 日，最新偵測結果以 VirusTotal 網頁為準。

## 授權

蝦米GO採用**免費使用、保留著作權（Freeware / All Rights Reserved）**。免費使用不等於開放原始碼，也不代表能任意修改、重新包裝或販售。詳細條款請見 [授權文件](LICENSE.md) 與 [第三方資料來源聲明](Packages/Windows/ShamiGo_v0.10.394/THIRD_PARTY_NOTICES.md)。字根資料須由使用者自行合法取得，並遵守原權利人的授權規定。
