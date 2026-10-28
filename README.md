# 蝦米GO（ShamiGo）

**蝦米GO是嘸蝦米輸入法的免安裝外殼。** 蝦米GO並非嘸蝦米的官方產品。核心程式由C++語言完成。使用者沿用自己合法取得的嘸蝦米字根資料，在 Windows 上直接啟動輸入。另提供注音、拼音、候選字與其他輔助輸入功能。

<img width="596" height="180" alt="圖片" src="https://github.com/user-attachments/assets/842f0c2d-b53e-44e4-b53b-26c701ddf9dc" />

##

<img width="130" height="329" alt="圖片" src="https://github.com/user-attachments/assets/892a200f-9eca-4b4e-8dde-c3522af4169b" />

## 下載

點選 GitHub 頁面上的 **Code（程式碼）→ Download ZIP（下載 ZIP）**，將整個儲存庫下載並解壓縮。請保留原本的資料夾結構。

## Windows：免安裝直接使用（建議）

**Windows 版不必安裝，雙擊即可啟動。**

1. 將自行合法取得的嘸蝦米字根檔 `liu-uni.tab`，放入 `Windows/LicensedTables/` 資料夾。(請至行易有限公司購買嘸蝦米https://boshiamy.com/)
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

## VirusTotal 公開掃描與安全說明

以下是 [VirusTotal](https://www.virustotal.com/) 對目前 GitHub 發行檔的掃描紀錄，依 SHA-256 對應特定檔案。**若對蝦米GO程式有疑慮，請勿使用。**

| 發行檔 | 防毒引擎結果 | 掃描報告 |
| --- | --- | --- |
| Windows 主程式 `ShamiGo_v0.10.394.exe` | **5 個判定惡意、66 個未偵測、4 個不支援**（共 75） | [VirusTotal](https://www.virustotal.com/gui/file/2d2f0a73b06816080f8275c1304157f9cf7c1cf9f3a279a352f1118fd1af4373/detection) |
| Windows 安裝輔助程式 `ShamiGo_AdminSetup.exe` | **1 個判定惡意、70 個未偵測、4 個不支援**（共 75） | [VirusTotal](https://www.virustotal.com/gui/file/246729bcc5974a5f20fb5cc91ed725e6e57cafc384a3c5f7aa30b900972cb4fe/detection) |
| Linux 套件 `shamigo-fcitx5_0.10.366-1_amd64.deb` | **0 個判定惡意、61 個未偵測、14 個不支援**（共 75） | [VirusTotal](https://www.virustotal.com/gui/file/f7af230b1f4d6b637a357a465c580975ae9a53cbe87d8ea4493e08c0ca01930f/detection) |

掃描時間：**2026 年 10 月 29 日約 01:47（臺灣時間）**。報告會隨防毒引擎更新而改變，最新狀態請以連結為準。

### 為什麼輸入法可能出現防毒偵測？

蝦米GO是嘸蝦米輸入法的免安裝外殼，為了提供快捷鍵、候選字選取及輸出文字等功能，需要處理鍵盤事件並與目前使用中的程式互動。部分安全防護工具會將這類行為與鍵盤監控、自動輸入等具有雙重用途的功能一起檢查，因此**有可能**產生啟發式或機器學習偵測。

另外，`Install_Windows.cmd` 是**選用**的安裝方式，會在使用者同意 Windows 管理員授權後，設定登入時自動啟動。若不需要自動啟動，可以直接使用 `Run_Windows.cmd` 免安裝執行；兩者的作用不同。

**上述只是可能的技術原因，尚未證實是本次各防毒引擎判定的實際原因。** 若對蝦米GO有疑慮，請勿使用。

### 使用者如何查驗？

請從本 GitHub 儲存庫取得發行檔，核對 [SHA256SUMS.txt](SHA256SUMS.txt)，並開啟上方 VirusTotal 報告自行查看。


## 授權

蝦米GO採用**免費使用、保留著作權（Freeware，All Rights Reserved）**的方式提供。使用者可免費下載及使用，Windows 版並支援免安裝直接啟動。免費使用不代表可以任意重新包裝、修改後公開發行或販售作者擁有權利的程式。

完整條款請參閱 [蝦米GO免費使用授權條款](LICENSE.md)。第三方元件、資料及嘸蝦米字根的相關權利，仍依各自的授權規定辦理；資料來源說明請參閱 [第三方資料來源與權利聲明](Windows/THIRD_PARTY_NOTICES.md)。
