# 第三方資料來源與權利聲明

本文件僅識別蝦米GO所使用的第三方資料及上游專案，不代表這些專案或權利人對蝦米GO提供官方授權、推薦、合作或背書。不同資料的授權條件彼此獨立；開放原始碼授權不會自動擴及專有字根、商標或其他資料。

## 小麥注音（McBopomofo）：臺灣國語讀音資料

- 上游來源：https://github.com/openvanilla/McBopomofo
- 本機整理檔：`Phonetics/mcbopomofo_readings.tsv`。
- 使用方式：蝦米GO啟動時離線載入 BPMFBase 衍生的單字讀音資料，建立「注音」與「拼音」共用候選索引；同一漢字可保留多種讀音。此資料不包含嘸蝦米拆碼，也不負責蝦米GO的按鍵攔截、浮動框或選字操作；**不需要安裝或執行**小麥注音。
- 上游專案採 MIT 授權。使用或再散布相關授權內容時，應保留適用的版權與許可聲明。以下保留該專案 LICENSE.txt 文字；若使用的具體資料另有權利標示，仍須依相應條款確認。

### McBopomofo MIT License

```text
MIT License

Copyright (c) 2011-2026 Mengjuei Hsieh et al.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## 萌典相關詞組

- 主要資料檔：`Phrases/phrases.bin`。
- 來源專案：https://github.com/plateaukao/ohmybias-android
- OhMyBias Android README 指出 `phrases.bin` 來自萌典詞組，並標示該資料為 **CC0**：https://www.moedict.tw/ 。蝦米GO離線讀取該檔作為關聯詞與上下文錯碼的參考語料。此項來源描述依上游公開文件，不代表所有可能存在的第三方資料均具有相同權利狀態；使用者再散布前仍應核對所持有檔案的來源與適用權利。

## 嘸蝦米字根及其他專有資料

- `LicensedTables/liu-uni.tab`、`liu-uni2.tab`、`liu-uni3.tab`、`liu-uni4.tab`、`liuphon.tab`、`liuext.tab`，以及備援詞組 `AssociatedPhrases.cin`，屬於獨立的字根／語料資料來源。
- 字根等資料的使用、轉換、複製及散布須遵守其原權利人所定的授權條件。**檔案可由蝦米GO讀取，並不等同於取得將資料公開上傳或重新發行的許可。**
- 「嘸蝦米」為相關權利人的商標／產品名稱，此處僅為說明輸入方式及相容資料；蝦米GO並非官方嘸蝦米輸入法，也未宣稱取得相關產品的官方認可。

本文件不是個別使用行為的法律鑑定。對外公開發布或商業利用含第三方資料的套件前，請先確認取得相應授權。
