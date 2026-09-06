# Script format


[../Resources/scenario.json](../Resources/scenario.json) is a ready-to-use example. Each array element requires:

```json
{
  "id": "intro",
  "number": "1",
  "russian": "Привет!",
  "english": "Hello!"
}
```

Optional fields: `videoRussian`, `videoEnglish`, `voiceStatus`, `voiceNote`.
At least one language must contain text. Block IDs must be nonempty and unique.

For XLSX, put headers in row 1 and data in these columns:

| Column | Content |
| --- | --- |
| A | Display number |
| B | Russian video/editing notes, optional |
| C | English video/editing notes, optional |
| D | Russian voiceover text |
| E | English voiceover text |
| F | Existing voiceover status, optional |
| G | Reserved; not imported |
| H | Notes, optional |

Headers in D1 and E1 must exist. The reader imports `xl/worksheets/sheet1.xml`; it does not resolve the active tab or other worksheets. Use a simple, single-sheet workbook with plain text cells. Formulas are not calculated. Inline/shared strings are supported; each XML entry is limited to 16 MB after decompression. XLSX row IDs are derived from row positions and remain local to the newly created project.

To split a block, put a marker on its own line before **every** spoken segment:

```text
[voice:intro-greeting]
Hello!

[voice:intro-start]
Let's get started.
```

Marker names allow `A–Z`, `a–z`, digits, `.`, `_` and `-`. They must be unique across the entire scenario. If both languages are present, their markers must match in order. Empty segments, duplicate markers and text before the first marker are rejected.
