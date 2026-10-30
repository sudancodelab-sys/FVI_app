# Institute ads

Ads for the institute itself, apart from the app: social posts, WhatsApp statuses and,
later, printed posters. Each ad is one HTML page in `ads/` that sets its own size
(`--w`, `--h`), with the logo's navy and orange, Cairo for Arabic and Lexend for English
(the books' font). Arabic is fine here: the "no Arabic" rule is for the books.

```bash
node marketing/render.js            # every ad to marketing/out/<name>.png
node marketing/render.js 2 english-post   # one ad at twice the size (for print)
```

| Ad | Size | What it says |
|---|---|---|
| `general-post` | 1080×1080 | The institute and its three departments: computer, languages, tutoring |
| `english-post` | 1080×1080 | The English course: ten levels as a staircase, numbered as on the book covers, with CEFR |
| `general-story` | 1080×1920 | `general-post` as a WhatsApp status; the top and bottom 200px stay clear |

The WhatsApp number (`0XXX XXX XXX`) is a placeholder until the institute sends its number.
`out/` is not committed: the PNGs go to the institute on a private Artifact page.
