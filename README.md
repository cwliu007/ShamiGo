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

## VirusTotal 公開掃描結果

以下為 [VirusTotal](https://www.virustotal.com/) 依檔案 SHA-256 提供的查詢結果。**Windows 主程式已出現 5 個防毒引擎的惡意軟體偵測，因此目前不能宣稱整套蝦米GO已通過掃毒。**

| 發行檔 | 已取得的掃描資訊 | 公開報告 |
| --- | --- | --- |
| Windows 主程式 `ShamiGo_v0.10.394.exe` | **75 個引擎：5 個判定惡意、66 個未偵測、4 個不支援**。分析時間：2026-10-29 01:47（臺灣時間） | [VirusTotal 掃描報告](https://www.virustotal.com/gui/file/2d2f0a73b06816080f8275c1304157f9cf7c1cf9f3a279a352f1118fd1af4373/detection) |
| Windows 安裝輔助程式 `ShamiGo_AdminSetup.exe` | 有檔案查詢紀錄，但**沒有分析日期與防毒引擎結果**；不能判定安全 | [VirusTotal 檔案查詢](https://www.virustotal.com/gui/file/246729bcc5974a5f20fb5cc91ed725e6e57cafc384a3c5f7aa30b900972cb4fe/detection) |
| Linux 安裝套件 `shamigo-fcitx5_0.10.366-1_amd64.deb` | 有檔案查詢紀錄，但**沒有分析日期與防毒引擎結果**；不能判定安全 | [VirusTotal 檔案查詢](https://www.virustotal.com/gui/file/f7af230b1f4d6b637a357a465c580975ae9a53cbe87d8ea4493e08c0ca01930f/detection) |

查詢日期：**2026 年 10 月 29 日（臺灣時間）**。Windows 主程式的偵測包含泛用型木馬及啟發式判定，但目前**沒有證據可以確定是誤判或實際惡意程式**。建議在原因釐清之前暫緩安裝或執行。其餘兩個檔案缺少有效掃描結果，不能將「0 個引擎報告」解讀為「0 個威脅」。

所有檔案的 SHA-256 可參閱 [SHA256SUMS.txt](SHA256SUMS.txt)。VirusTotal 的偵測數量可能隨重新分析而改變，應以連結中的最新報告為準。

## 授權

蝦米GO採用**免費使用、保留著作權（Freeware，All Rights Reserved）**的方式提供。使用者可免費下載及使用，Windows 版並支援免安裝直接啟動。免費使用不代表可以任意重新包裝、修改後公開發行或販售作者擁有權利的程式。

完整條款請參閱 [蝦米GO免費使用授權條款](LICENSE.md)。第三方元件、資料及嘸蝦米字根的相關權利，仍依各自的授權規定辦理；資料來源說明請參閱 [第三方資料來源與權利聲明](Windows/THIRD_PARTY_NOTICES.md)。
