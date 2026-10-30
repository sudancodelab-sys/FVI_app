# Helper scripts

Playwright scripts used while writing the books and the app. They need Node with Playwright (preinstalled in the cloud sessions). `voice_sample.py` is Python and runs in the voices venv (docs/VOICES.md).

| Script | Use |
|---|---|
| `fill.js <book.html>` | How full each page is (%). Every page except a book's last should be at least about 67%. |
| `pages.js <book.html> <prefix> 3 4 5` | Screenshots of chosen pages. |
| `pagetext.js <book.html>` | Each page's text as JSON, to compare two builds of a book page by page. |
| `cover.js <book.html> <out.jpg>` | The cover as a JPEG, 640 px wide, for a download page. |
| `voice_sample.py [--out DIR]` | The voice sample: a few clips of every kind, made and checked by `voices.py`, on one page with the audio inside (`build/voice-sample/voice-sample.html`, published as the Artifact "FVI Voice Sample"). Its page is `voice-sample.html`. |
| `exercise_sample.py [--starter] [--out DIR]` | The exercise samples: the exercises of four lessons, made by `exercises.py`, to try as a student or review with their answers (`build/exercise-sample/exercise-sample.html`, the Artifact "FVI Exercise Sample"; with `--starter`, `starter-exercise-sample.html`, the Artifact "FVI Starter Exercises"). Their page is `exercise-sample.html`; plain Python 3. |
| `appshots.js <prefix> <levelY> <lessonY> <shots> [scroll]` | Walks the app's web build served at http://localhost:8123 (course, then the level card at levelY, then the lesson at lessonY) and screenshots while scrolling. |
| `adminshots.js [dir]` | The admin app's sample walk: the student app's web build at http://localhost:8123 and the admin app's at http://localhost:8124; three requests, codes issued and pasted, a renewal; screenshots `adm-*.png` and the WhatsApp messages in `adm-texts.json` (the Artifact "FVI Admin Sample"). |

`docs/download-page/index.html` is the template of the private download pages (Artifacts) made for each book. Copy it, change the level, units, lessons, page count and file names, and publish it with the `downloads` capability, the cover and the PDF.
