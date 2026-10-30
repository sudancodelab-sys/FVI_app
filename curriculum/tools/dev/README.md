# Helper scripts

Playwright scripts used while writing the books and the app. They need Node with Playwright (preinstalled in the cloud sessions). `voice_sample.py` is Python.

| Script | Use |
|---|---|
| `fill.js <book.html>` | How full each page is (%). Every page except a book's last should be at least about 67%. |
| `pages.js <book.html> <prefix> 3 4 5` | Screenshots of chosen pages. |
| `pagetext.js <book.html>` | Each page's text as JSON, to compare two builds of a book page by page. |
| `cover.js <book.html> <out.jpg>` | The cover as a JPEG, 640 px wide, for a download page. |
| `appshots.js <prefix> <levelY> <lessonY> <shots> [scroll]` | Walks the app's web build served at http://localhost:8123 (course, then the level card at levelY, then the lesson at lessonY) and screenshots while scrolling. |
| `voice_sample.py <export> <out>` | The voice sample with Gemini (Python, needs `GEMINI_API_KEY`): makes the clips, checks each by listening and by pitch, writes `sample.json`. `docs/voice-sample/build_page.py` makes the listening page from it. |

`docs/download-page/index.html` is the template of the private download pages (Artifacts) made for each book. Copy it, change the level, units, lessons, page count and file names, and publish it with the `downloads` capability, the cover and the PDF.
