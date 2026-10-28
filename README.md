# ShamiGo（蝦米 GO）

適用於 **Windows 11** 與 **Debian 13／LMDE 7** 的非官方輸入法。

| 平台 | 版本 |
| --- | --- |
| Windows 11 x64 | v0.10.394 |
| Linux（amd64，Fcitx5） | v0.10.366-1 |

## 下載

點選頁面右上方 **Code → Download ZIP**，下載並完整解壓整個儲存庫；也可用 `git clone`。安裝所需檔案已直接放在 `Windows/`、`Linux/` 資料夾中。

## 安裝

**Windows：** 將自行合法取得的 `liu-uni.tab` 放入 `Windows/LicensedTables/`，再執行根目錄的 `Install_Windows.cmd`。可攜執行使用 `Run_Windows.cmd`；移除使用 `Uninstall_Windows.cmd`。

**Linux：** 執行 `sh Install_Linux.sh`，再匯入自己合法取得的字根：

```sh
sh Install_Linux.sh
shamigo-setup import-data --source /path/to/LicensedTables
shamigo-setup check --strict
```

重啟 Fcitx5 並啟用 ShamiGo。移除使用 `sh Uninstall_Linux.sh`。

## 注意

- **不包含嘸蝦米專有字根**，必須自行合法取得 `liu-uni.tab`，否則輸入功能無法正常使用。請勿上傳私人字根。
- 不包含 C++ 原始碼、IDE 專案、歷史版本、記錄檔或測試資料；macOS 尚未支援。
- 檔案完整性可用 [SHA256SUMS.txt](./SHA256SUMS.txt) 驗證；第三方資料的授權聲明見 `Windows/THIRD_PARTY_NOTICES.md`。
- 精簡安裝包尚未在 Windows 與 Linux 圖形環境完成實機安裝測試。
