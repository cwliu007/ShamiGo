# ShamiGo｜蝦米 GO

適用於 **Windows 11** 與 **Linux** 的非官方輸入法。本儲存庫僅提供精簡安裝包，**不含原始碼及嘸蝦米專有字根**。

**[下載 ShamiGo 安裝包（ZIP）](./ShamiGo_v0.10.394_GitHub_Public_Binary.zip)** · 約 1.9 MiB

| 平台 | 版本 |
| --- | --- |
| Windows 11 x64 | v0.10.394 |
| Debian 13／LMDE 7（amd64） | v0.10.366-1 |

## 安裝

**Windows**
1. 完整解壓 ZIP，將自行合法取得的 `liu-uni.tab` 放入 `Windows/LicensedTables/`。
2. 執行 `Install_Windows.cmd` 安裝，或執行 `Run_Windows.cmd` 使用可攜模式。
3. 解除安裝：`Uninstall_Windows.cmd`。

**Linux**
1. 完整解壓 ZIP，執行 `sh Install_Linux.sh`。
2. 匯入自行合法取得的字根（路徑請改為自己的資料夾）：

   ```sh
   shamigo-setup import-data --source /path/to/LicensedTables
   shamigo-setup check --strict
   ```

3. 重啟 Fcitx5，在輸入法設定中啟用 ShamiGo。解除安裝：`sh Uninstall_Linux.sh`。

## 注意事項

- **不提供 `liu-uni.tab` 等專有字根。** 必須自行合法取得，否則輸入功能無法正常使用；請勿上傳字根至 GitHub。
- 此安裝包不包含歷史檔、日誌、測試資料、原始碼或 VM 映像；macOS 尚未支援。
- 檔案校驗：[SHA256SUMS.txt](./SHA256SUMS.txt)。第三方資料授權聲明見 ZIP 內 `Windows/THIRD_PARTY_NOTICES.md`。
- 本精簡版尚未完成 Windows／Linux 實機安裝驗證。
