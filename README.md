# ShamiGo（蝦米 GO）

ShamiGo 是適用於 Windows 與 Linux 的中文輸入法。

## 支援平台

| 平台 | 版本 |
| --- | --- |
| Windows 11（x64） | v0.10.394 |
| Debian 13／LMDE 7（amd64、Fcitx5） | v0.10.366-1 |

## 下載

從本儲存庫取得全部檔案，保留原有的資料夾結構。Windows 與 Linux 的安裝檔分別位於 `Windows/` 和 `Linux/`。

## 安裝與使用

### Windows

1. 將個人使用的 `liu-uni.tab` 放入 `Windows/LicensedTables/`。
2. 執行根目錄的 `Install_Windows.cmd` 安裝。
3. 也可使用 `Run_Windows.cmd` 直接啟動。

移除：執行 `Uninstall_Windows.cmd`。

### Linux

在 Debian 13 或 LMDE 7 的終端機執行：

```sh
sh Install_Linux.sh
```

安裝完成後，匯入個人使用的字根資料：

```sh
shamigo-setup import-data --source /path/to/LicensedTables
```

重新啟動 Fcitx5，並啟用 ShamiGo 輸入法。

移除：執行 `sh Uninstall_Linux.sh`。
