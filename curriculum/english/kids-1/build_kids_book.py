#!/usr/bin/env python3
"""Build the standalone Kids English 1 handwriting workbook."""
from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml
from jinja2 import Environment, FileSystemLoader, select_autoescape
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
CURRICULUM = HERE.parents[1]
REPO = CURRICULUM.parent
TEMPLATE_DIR = CURRICULUM / 'templates'
TEMPLATE_FILE = 'kids_book.html.j2'
DIST = HERE / 'dist'
HTML_OUT = DIST / 'kids1-book.html'
PDF_OUT = DIST / 'kids1-book.pdf'
COVER_OUT = DIST / 'kids1-cover.pdf'


def read_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding='utf-8'))


def validate(level: dict, content: dict) -> list[dict]:
    letters = content.get('letters', [])
    expected = list('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
    actual = [item.get('upper') for item in letters]
    errors = []
    if actual != expected:
        errors.append(f'letters must be A–Z in order; got {actual!r}')
    if len(content.get('conversations', [])) != 2:
        errors.append('the book must contain exactly two short conversations')
    if level.get('page_count') != 34:
        errors.append('level.yaml must declare the approved 34-page plan')

    wordlists_path = CURRICULUM / 'wordlists.yaml'
    wordlists = read_yaml(wordlists_path) if wordlists_path.exists() else {}
    banned = {str(word).lower() for words in wordlists.values() for word in (words or [])}
    for index, item in enumerate(letters, start=1):
        upper = item.get('upper', '')
        lower = item.get('lower', '')
        example = str(item.get('example', '')).strip()
        if lower != upper.lower():
            errors.append(f'letter {index}: lower form does not match {upper!r}')
        if not example or not example[0].lower() == lower:
            errors.append(f'letter {upper}: example {example!r} must begin with {lower!r}')
        for token in re.findall(r'[a-z]+', example.lower()):
            if token in banned:
                errors.append(f'letter {upper}: example contains restricted word {token!r}')

    for conversation in content.get('conversations', []):
        for line in conversation.get('lines', []):
            speaker = str(line.get('speaker', '')).strip()
            line['initial'] = 'MA' if speaker == 'Mr. Ali' else ('C' if speaker == 'Class' else speaker[:1].upper())
            if not line.get('text'):
                errors.append(f'conversation {conversation.get("title")!r}: empty dialogue line')

    for index, item in enumerate(letters, start=1):
        item['number'] = index
        item['page_number'] = index + 4
        item['upper_repeat'] = ' '.join([item['upper']] * 4)
        item['lower_repeat'] = ' '.join([item['lower']] * 4)
        item['wide_cap'] = item['upper'] in {'M', 'W'}
        item['wide_small'] = item['lower'] in {'m', 'w'}
        item['long_word'] = len(str(item['example'])) >= 8

    return errors


def main() -> int:
    level = read_yaml(HERE / 'level.yaml')
    content = read_yaml(HERE / 'content.yaml')
    errors = validate(level, content)
    if errors:
        for error in errors:
            print('ERROR:', error)
        return 1

    art_path = HERE / 'assets' / 'kids1-cover-art.png'
    logo_path = CURRICULUM / 'assets' / 'institute-logo.png'
    if not art_path.is_file() or not logo_path.is_file():
        print('ERROR: the approved cover art or institute logo is missing')
        return 1

    # These relative URLs keep the generated HTML reproducible inside the repo.
    level['cover_art'] = '../assets/kids1-cover-art.png'
    level['logo'] = '../../../assets/institute-logo.png'
    env = Environment(
        loader=FileSystemLoader(str(TEMPLATE_DIR)),
        autoescape=select_autoescape(enabled_extensions=('html', 'j2')),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    template = env.get_template(TEMPLATE_FILE)
    html_text = template.render(level=level, content=content, letters=content['letters'],
                                conversations=content['conversations'])
    if re.search(r'[\u0600-\u06ff]', html_text):
        print('ERROR: Arabic text is not permitted in student-facing book pages')
        return 1

    expected_pages = 34
    DIST.mkdir(parents=True, exist_ok=True)
    HTML_OUT.write_text(html_text, encoding='utf-8')

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(
            executable_path='/usr/bin/chromium', args=['--no-sandbox'])
        page = browser.new_page(viewport={'width': 794, 'height': 1123}, device_scale_factor=2)
        page.goto(HTML_OUT.as_uri(), wait_until='load', timeout=120000)
        page.evaluate('document.fonts.ready')
        page_count = page.locator('.page').count()
        heights = page.locator('.page').evaluate_all(
            '(pages) => pages.map((el) => ({page: el.dataset.page, scroll: el.scrollHeight, client: el.clientHeight}))')
        if page_count != expected_pages:
            browser.close()
            print(f'ERROR: expected {expected_pages} pages, rendered {page_count}')
            return 1
        overflow = [item for item in heights if item['scroll'] > item['client'] + 1]
        if overflow:
            browser.close()
            print('ERROR: page content exceeds A4:', overflow)
            return 1

        # Ensure the four repeated models fit inside each writing band and do not
        # collide with the MODEL label. Vertical glyph overhang is intentional
        # so capital letters meet the top line and descenders reach the bottom.
        model_metrics = page.locator('.letter-page').evaluate_all(
            """(pages) => pages.flatMap((p) => [...p.querySelectorAll('.model')].map((m) => {
              const row = m.closest('.writing-row');
              const label = row.querySelector('.write-label');
              const mb = m.getBoundingClientRect();
              const rb = row.getBoundingClientRect();
              const lb = label ? label.getBoundingClientRect() : null;
              return {letter: p.dataset.letter, className: m.className,
                right: mb.right, rowRight: rb.right,
                labelLeft: lb ? lb.left : null};
            }))""")
        colliding = [metric for metric in model_metrics
                     if metric['right'] > (metric['labelLeft'] - 3 if metric['labelLeft'] else metric['rowRight'] - 6)]
        if colliding:
            browser.close()
            print('ERROR: a letter or word model collides with the row label:', colliding)
            return 1

        page.pdf(path=str(PDF_OUT), format='A4', print_background=True,
                 prefer_css_page_size=True,
                 margin={'top': '0mm', 'right': '0mm', 'bottom': '0mm', 'left': '0mm'})
        browser.close()

    # Extract the approved cover as a separate print-ready PDF.
    cover_pattern = DIST / 'kids1-cover-%d.pdf'
    subprocess.run(['pdfseparate', '-f', '1', '-l', '1', str(PDF_OUT), str(cover_pattern)], check=True)
    generated_cover = DIST / 'kids1-cover-1.pdf'
    if COVER_OUT.exists():
        COVER_OUT.unlink()
    generated_cover.replace(COVER_OUT)

    # Keep two convenient print previews next to the PDFs.
    subprocess.run(['pdftoppm', '-f', '1', '-l', '1', '-singlefile', '-r', '140', '-png',
                    str(PDF_OUT), str(DIST / 'kids1-cover-preview')], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(['pdftoppm', '-f', '5', '-l', '5', '-singlefile', '-r', '140', '-png',
                    str(PDF_OUT), str(DIST / 'kids1-letter-a-preview')], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    info = subprocess.run(['pdfinfo', str(PDF_OUT)], capture_output=True, text=True, check=True).stdout
    pages_match = re.search(r'^Pages:\s+(\d+)$', info, re.MULTILINE)
    size_match = re.search(r'^Page size:\s+(.+)$', info, re.MULTILINE)
    if not pages_match or int(pages_match.group(1)) != expected_pages:
        print('ERROR: PDF page count does not match the 34-page plan')
        return 1
    if not size_match or 'A4' not in size_match.group(1):
        # pdfinfo reports point dimensions rather than the word A4 on some versions.
        dimensions = size_match.group(1) if size_match else ''
        if not ('594' in dimensions and '841' in dimensions):
            print(f'ERROR: unexpected PDF page size: {dimensions}')
            return 1

    print(f'Built {PDF_OUT} ({expected_pages} A4 pages)')
    print(f'Cover: {COVER_OUT}')
    print(f'HTML source: {HTML_OUT}')
    print(f'Checked 26 letters, 26 examples, two conversations, and all page boundaries.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
