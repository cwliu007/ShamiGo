# 蝦米GO（ShamiGo）

**蝦米GO是嘸蝦米輸入法的免安裝外殼。** 蝦米GO並非嘸蝦米的官方產品。使用者沿用自己合法取得的嘸蝦米字根資料，在 Windows 上直接啟動輸入。另提供注音、拼音、候選字與其他輔助輸入功能。

<img width="596" height="180" alt="圖片" src="https://github.com/user-attachments/assets/842f0c2d-b53e-44e4-b53b-26c701ddf9dc" />

##

<img width="130" height="329" alt="圖片" src="https://github.com/user-attachments/assets/892a200f-9eca-4b4e-8dde-c3522af4169b" />

## 下載

點選 GitHub 頁面上的 **Code（程式碼）→ Download ZIP（下載 ZIP）**，將整個儲存庫下載並解壓縮。請保留原本的資料夾結構。

## Windows：免安裝直接使用（建議）

**Windows 版不必安裝，雙擊即可啟動。**

1. 將自行合法取得的嘸蝦米字根檔 `liu-uni.tab`，放入 `Windows/LicensedTables/` 資料夾。
2. 雙擊根目錄的 **`Run_Windows.cmd`**，即可直接使用蝦米GO。
3. 使用完畢，可在 Windows 通知區的蝦米GO圖示按右鍵，選擇結束程式。

免安裝方式不需要先執行安裝程式，也不需要設定登入後自動啟動。保留下載的資料夾，日後即可再次啟動。

## Windows：安裝並自動啟動（選用）

如果想在每次登入 Windows 時自動啟動蝦米GO，可以使用安裝方式：

1. 先將 `liu-uni.tab` 放入 `Windows/LicensedTables/`。
2. 雙擊根目錄的 **`Install_Windows.cmd`**，依 Windows 提示同意管理員授權。
3. 安裝程式會將程式複製到受保護的安裝位置，並設定登入後自動啟動。

若要移除安裝版，請先結束蝦米GO，再執行 **`Uninstall_Windows.cmd`**。原本下載的免安裝資料夾不會因此被刪除。

| 檔案 | 用途 |
| --- | --- |
| `Run_Windows.cmd` | **免安裝，直接啟動蝦米GO** |
| `Install_Windows.cmd` | 安裝蝦米GO，並設定登入後自動啟動 |
| `Uninstall_Windows.cmd` | 移除已安裝的程式及自動啟動設定 |

詳細操作可參閱 [Windows 使用說明](Windows/ShamiGo_Help.html)。

## Linux：安裝與使用

Linux 版適用於 **Debian 13／LMDE 7（64 位元、Fcitx5）**，需安裝套件才能使用。

在下載的資料夾開啟終端機，執行：

```sh
sh Install_Linux.sh
```

接著匯入自己合法取得的嘸蝦米字根資料：

```sh
shamigo-setup import-data --source /path/to/LicensedTables
```

請將 `/path/to/LicensedTables` 改成實際存放字根檔的資料夾路徑。重新啟動 Fcitx5，並在輸入法清單中啟用蝦米GO。

移除 Linux 版：

```sh
sh Uninstall_Linux.sh
```

## 版本

| 平台 | 版本 |
| --- | --- |
| Windows 11（64 位元） | v0.10.394 |
| Debian 13／LMDE 7（64 位元） | v0.10.366-1 |

## 病毒掃描與安全性查驗

蝦米GO的公開發行檔可使用 [VirusTotal](https://www.virustotal.com/) 查驗。VirusTotal 彙整多家防毒引擎的偵測結果；下方連結依據各檔案的 SHA-256 雜湊值，直接連到相對應的檔案查詢頁面。

**查驗日期：2026 年 10 月 29 日。** 目前尚未取得可核對的 VirusTotal 完成掃描結果，因此不列示未經確認的偵測數量，也不宣稱已通過掃毒。

| 公開發行檔 | VirusTotal 查詢 | 目前查驗結果 |
| --- | --- | --- |
| Windows 主程式：`ShamiGo_v0.10.394.exe` | [查詢掃描報告](https://www.virustotal.com/gui/file/2d2f0a73b06816080f8275c1304157f9cf3a279a352f1118fd1af4373/detection) | 尚未取得可驗證的掃描數據 |
| Windows 安裝輔助程式：`ShamiGo_AdminSetup.exe` | [查詢掃描報告](https://www.virustotal.com/gui/file/246729bcc5974a5f20fb5cc91ed725e6e57cafc384a3c5f7aa30b900972cb4fe/detection) | 尚未取得可驗證的掃描數據 |
| Linux 套件：`shamigo-fcitx5_0.10.366-1_amd64.deb` | [查詢掃描報告](https://www.virustotal.com/gui/file/f7af230b1f4d6b637a357a465c580975ae9a53cbe87d8ea4493e08c0ca01930f/detection) | 尚未取得可驗證的掃描數據 |

檔案辨識用的完整 SHA-256 值如下：

```text
Windows/ShamiGo_v0.10.394.exe
2d2f0a73b06816080f8275c1304157f9cf3a279a352f1118fd1af4373

Windows/ShamiGo_AdminSetup.exe
246729bcc5974a5f20fb5cc91ed725e6e57cafc384a3c5f7aa30b900972cb4fe

Linux/shamigo-fcitx5_0.10.366-1_amd64.deb
f7af230b1f4d6b637a357a465c580975ae9a53cbe87d8ea4493e08c0ca01930f
```

以上 SHA-256 值依據儲存庫的 [SHA256SUMS.txt](SHA256SUMS.txt) 列示。點開 VirusTotal 連結後，若顯示找不到分析報告，需將對應的發行檔上傳至 VirusTotal 才能產生掃描結果。**「尚未取得報告」不等於「0 個防毒引擎偵測」；即使結果為 0，也不保證軟體絕對安全。**

## 授權

蝦米GO採用**免費使用、保留著作權（Freeware，All Rights Reserved）**的方式提供。使用者可免費下載及使用，Windows 版並支援免安裝直接啟動。免費使用不代表可以任意重新包裝、修改後公開發行或販售作者擁有權利的程式。

完整條款請參閱 [蝦米GO免費使用授權條款](LICENSE.md)。第三方元件、資料及嘸蝦米字根的相關權利，仍依各自的授權規定辦理；資料來源說明請參閱 [第三方資料來源與權利聲明](Windows/THIRD_PARTY_NOTICES.md)。
