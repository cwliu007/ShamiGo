# 蝦米GO（ShamiGo）

**蝦米GO是嘸蝦米輸入法的免安裝外殼。** 它不是另一套全新的嘸蝦米輸入法，而是讓使用者沿用自己合法取得的嘸蝦米字根資料，在 Windows 上直接啟動輸入。另提供注音、拼音、候選字與其他輔助輸入功能。

<img width="320" height="58" alt="圖片" src="https://github.com/user-attachments/assets/fa324653-fcc4-4f7d-af1e-f89bf0c5b4d5" />
-
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

蝦米GO不隨附嘸蝦米專有字根檔；使用者需自行合法取得。蝦米GO並非嘸蝦米的官方產品。
