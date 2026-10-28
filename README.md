# ShamiGo（蝦米 GO）

**下載安裝包：** [ShamiGo v0.10.394 公開精簡 ZIP](./ShamiGo_v0.10.394_GitHub_Public_Binary.zip)（Windows 11 x64 / Debian 13、LMDE 7 amd64；約 1.90 MiB）

此儲存庫只發行必要二進位安裝檔及說明，不公開 C++ 原始碼，也**不包含嘸蝦米專有字根**。請先下載 ZIP 並完整解壓，再依下方步驟安裝；首次使用需自行提供合法取得的 `liu-uni.tab`。

下載後可依根目錄 [SHA256SUMS.txt](./SHA256SUMS.txt) 驗證 ZIP 完整性。

---


**Windows v0.10.394（2026-10-28） | Linux v0.10.366-1（amd64）**

此 ZIP 僅包含執行檔、必要安裝／解除安裝腳本、Linux `.deb`、自由授權的讀音／詞組資料，以及必要的授權聲明。**不包含 C++ 原始碼／IDE 專案、舊版本、測試檔、日誌、私人字根與任何內嵌的嘸蝦米專有資料。** macOS 尚未提供可安裝版本。

> **必要提醒：蝦米 GO 不隨附嘸蝦米字根。** 首次使用前必須自行備妥合法取得的 `liu-uni.tab`。本發行包不提供取得、破解或散布專有字根的方式；沒有此檔的 Windows 主程式會拒絕啟動輸入核心，Linux 套件可安裝，但輸入功能尚未可用。

## Windows 11 x64

1. **先完整解壓 ZIP**。這是 GitHub 精簡版，**不支援在 ZIP 內直接雙擊 CMD**（原版 CMD 夾帶受限資料的內嵌 ZIP，已全部移除）。
2. 首次使用前，在解壓後的 `Windows/LicensedTables/` 放入**自己合法取得**的 `liu-uni.tab`。可選擇自行放入 `liu-uni2.tab`、`liu-uni3.tab`、`liu-uni4.tab`、`liuphon.tab`、`liuext.tab` 或 `AssociatedPhrases.cin`；**請勿提交到 GitHub**。此資料夾發行時只有 `README.txt`。
3. 雙擊最外層的 `Install_Windows.cmd`。依照 Windows UAC 提示授權。會使用原本的管理員安裝／登入排程邏輯，安裝到 `C:\Program Files\ShamiGo\<使用者 SID>\`。若已有安裝，原有私有字庫會保留，不從公開包覆蓋。
4. 或選擇執行 `Run_Windows.cmd` 使用可攜執行檔（仍須把私人 `liu-uni.tab` 放到相鄰的 `Windows/LicensedTables/`）。
5. 移除時先從系統匣**結束正在執行的 ShamiGo**，再執行 `Uninstall_Windows.cmd`。現有個人設定／字庫依原管理腳本備份保留。

若先安裝程式、後來才取得字根，可由系統管理員將自己的 `liu-uni.tab` 放入受保護安裝目錄中的 `LicensedTables`，或在安裝前先備妥字根。請勿藉由更改此 ZIP 發行內容重新散布字根。

本精簡版的安裝 CMD **不內嵌原程式或字庫**，因此沒有「只解出 CMD 就直接從 ZIP 執行」的功能。不要直接執行 `Windows/ShamiGo_AdminSetup.exe`；請使用根目錄安裝入口。

## Linux：Debian 13 / LMDE 7（amd64）

1. 完整解壓 ZIP，開啟終端機進入解壓目錄。
2. 執行 `sh Install_Linux.sh`，按照提示安裝 `Linux/shamigo-fcitx5_0.10.366-1_amd64.deb` 與相依套件（使用當前桌面帳號，不要先下 `sudo`）。
3. 自行準備合法取得的字根檔，在自己的目錄建立 `LicensedTables/liu-uni.tab`，然後執行：

   ```sh
   shamigo-setup import-data --source /path/to/your/private-folder
   shamigo-setup check --strict
   ```

   `--source` 指向內含 `LicensedTables` 子資料夾的目錄，或直接指向 `LicensedTables` 本身。私人資料儲存在目前使用者的 `~/.local/share/fcitx5/shamigo/`（若設定 `XDG_DATA_HOME` 則依該設定）。
4. 重啟 Fcitx5 或登出再登入，並在輸入法設定啟用 ShamiGo。解除安裝：`sh Uninstall_Linux.sh`。

Linux `.deb` 版號仍為 **v0.10.366**，未宣稱包含 Windows v0.10.394 的新功能；本 ZIP **沒有** VM 自動安裝器與 VirtualBox 映像。

## 權利、隱私與來源

- 字根檔（`liu-uni*.tab`、`liuext.tab`、`liuphon.tab`、`AssociatedPhrases.cin` 等）為各自權利人所有；**本包沒有提供**，使用者只應使用獲合法授權的私人副本。
- `Windows/Phonetics/mcbopomofo_readings.tsv` 依 McBopomofo 資料整理，相關 MIT 授權資訊見 `Windows/THIRD_PARTY_NOTICES.md`。
- `Windows/Phrases/phrases.bin` 與 Linux 套件內同名資料的來源標示為萌典詞組（CC0）；來源與注意事項見相同聲明。不同資料的授權不互相涵蓋。
- 本包不含歷史備份、日誌、測試樣本、開發專案或原始碼。`.gitignore` 另阻止誤將日後放入的私人字根提交到 GitHub。
- **這是原始 v394 Windows 與 v366 Linux 已有二進位檔的重新封裝**；只更換公開發行入口，並在安裝腳本加入缺字根說明與舊版私人 `liu.box` 保護。未在 Windows 11／LMDE 7 實機安裝測試，仍需在真機驗證 UAC、排程與 Fcitx5 行為。

## 檔案驗證

`SHA256SUMS.txt` 記錄本包各檔案的 SHA-256。Linux 可執行 `sha256sum -c SHA256SUMS.txt`。個人自行放入的私有資料不在校驗清單中。

**非官方相容軟體。** ShamiGo 不是官方嘸蝦米產品，亦不代表上游資料專案提供背書。請自行確認對外散布本軟體二進位檔及第三方資料時適用的權利與授權。