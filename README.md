# 蝦米GO（ShamiGo） · v0.10.607 OneFolder 修訂版

蝦米GO 是嘸蝦米輸入法的輸入輔助外殼，並非嘸蝦米官方產品。軟體作者使用 AI 工具協助開發，請自行合法取得所需字根。

**下載：** [Windows／Linux 公開版 v0.10.607 OneFolder](https://github.com/cwliu007/ShamiGo/releases/download/v0.10.607-onefolder/ShamiGo_v0.10.607_OneFolder_Windows_Linux.zip)

## 唯一的字根資料夾

套件最外層只有一個使用者字根資料夾：`LicensedTables/`。主要字根檔為 `liu-uni.tab`；其他字根及關聯詞組均為選用。**不提供任何字根也可以先安裝 Windows 公開版**，但未載入主字根時無法進行嘸蝦米中文輸入。

## Windows 11 x64

**可直接在 Windows 檔案總管開啟 ZIP，雙擊其中的 `Install_Windows.cmd`，不必手動解壓縮。** 安裝腳本會辨識、驗證完整 ZIP，暫時解壓、安裝後清除暫存檔。私人完整版與公開版皆支援此方式。若 ZIP 放在特殊路徑，安裝器會要求選取原 ZIP。

也可先完整解壓縮 ZIP，再直接在套件根目錄執行：

- `Install_Windows.cmd`：安裝並設定登入自動啟動。無字根也可安裝；空字庫時仍可使用英文模式。
- `Run_Windows.cmd`：免安裝使用；也可直接從 ZIP 開啟（會複製到使用者本機可攜快取）。
- `Uninstall_Windows.cmd`：先關閉正在執行的蝦米GO，再移除登入自動啟動、所有已安裝程式、設定、字典與字根副本、快取及舊備份。**不保留任何已安裝檔案**；不刪除下載的 ZIP 或原始開發專案。
- `Open_LicensedTables.cmd`：開啟固定的使用者字根資料夾，方便後續補入檔案（從 ZIP 或解壓資料夾啟動均可）。

**之後才補字根不需要重裝：**

- 從已解壓縮的資料夾安裝：將 `liu-uni.tab` 放進原套件根目錄的 `LicensedTables/`，或透過 `Open_LicensedTables.cmd` 放進使用者資料夾，完整結束蝦米GO再重新啟動。
- 直接從 ZIP 安裝：因為 ZIP 的暫存解壓目錄會刪除，請從 ZIP 內開啟 `Open_LicensedTables.cmd`，把 `liu-uni.tab` 放到它開啟的 `%LOCALAPPDATA%\ShamiGo\LicensedTables`，然後重新啟動蝦米GO。

新版 Windows 執行檔會在每次啟動時重新找字根；沒找到就保留英文模式，不會因為字根缺失而退出。安裝先進行檔案檢查；更新安裝時會暫存舊版資料供失敗回復，完整解除安裝則不留下這些備份，不呼叫有 Windows error 2 問題的舊原生安裝 helper。若 Windows 安全政策拒絕執行未簽署程式，請不要關閉系統安全保護。

## Linux：Debian 13／LMDE 7

在解壓縮後的根目錄執行 `sh Install_Linux.sh`，安裝套件內預編譯的 v0.10.366-1 `.deb`。即使尚無字根也可以安裝；日後將 `liu-uni.tab` 放入根目錄 `LicensedTables/`，執行 `shamigo-setup import-data --source /你的實際路徑/LicensedTables`，然後重新啟動 Fcitx5。

## 發行與授權

Windows 原生程式版本 0.10.607；Linux 預編譯套件 0.10.366-1。本公開版只提供 Windows 與 Linux。此為 **v607 的 OneFolder 安裝相容性修訂**，不是換成 v608。完整私人 ZIP 保留來源與私人合法字根；公開版不含它們。

授權與第三方來源請參閱 `LICENSE.md`、`THIRD_PARTY_NOTICES.md` 與平台內的 Help。
