// Pages of a Kids book. The blocks of #flow (lesson starts, sections, letter
// cards) fill A4 pages one after another, so no page is left half empty. A
// block marked .keep (a lesson start or a heading) never ends a page: it moves
// with the block after it; a long conversation goes on on the next page,
// and a block marked data-break starts a new page.
// Then each page names what it holds, the pages are
// numbered and the contents get their page numbers.
window.fviReady = (async () => {
  await document.fonts.ready;
  const src = document.getElementById('flow');
  const blank = document.getElementById('page').content.firstElementChild;
  const overflows = (page) => page.scrollHeight > page.clientHeight + 1;
  const flowOf = (page) => page.querySelector('.flow');
  const newPage = () => {
    const page = blank.cloneNode(true);
    src.before(page);
    return page;
  };

  // A long conversation (.split) may go on on the next page, under its
  // heading and "(continued)", keeping at least three lines on each page.
  const split = (block, page) => {
    const box = block.querySelector('.items');
    if (!overflows(page) || !block.classList.contains('split') || box.children.length <= 3) return null;
    const tail = block.cloneNode(false);
    const heading = block.querySelector('h2').cloneNode(true);
    heading.querySelectorAll('small').forEach((el) => el.remove());
    heading.append(' (continued)');
    const rest = box.cloneNode(false);
    tail.append(heading, rest);
    while (overflows(page) && box.children.length > 3) rest.prepend(box.lastElementChild);
    while (rest.children.length < 3 && box.children.length > 3) rest.prepend(box.lastElementChild);
    if (!overflows(page) && rest.children.length >= 3) return tail;
    [...rest.children].forEach((el) => box.append(el));
    return null;
  };

  let page = newPage();
  const queue = [...src.children];
  while (queue.length) {
    const block = queue.shift();
    // data-break: the block starts a page (two letters on each page).
    if (block.hasAttribute('data-break') && flowOf(page).children.length) page = newPage();
    flowOf(page).append(block);
    if (!overflows(page)) continue;
    let tail = split(block, page);
    if (!tail) {
      const group = [block];
      while (group[0].previousElementSibling && group[0].previousElementSibling.classList.contains('keep')) {
        group.unshift(group[0].previousElementSibling);
      }
      if (group.length < flowOf(page).children.length) {
        page = newPage();
        group.forEach((el) => flowOf(page).append(el));
        tail = split(block, page);
      }
    }
    if (tail) {
      page = newPage();
      queue.unshift(tail);
    } else if (overflows(page)) {
      console.warn('a block taller than a page: ' + (block.dataset.where || block.className));
    }
  }
  src.remove();

  // "Letters A–E", or the names of the lessons on the page.
  const pages = [...document.querySelectorAll('.page')];
  pages.filter((p) => p.querySelector('.flow')).forEach((p) => {
    const names = [];
    const letters = [];
    for (const el of flowOf(p).children) {
      if (el.dataset.letter) letters.push(el.dataset.letter);
      const name = el.dataset.letter ? 'letters' : el.dataset.where;
      if (name && !names.includes(name)) names.push(name);
    }
    const range = letters.length > 1 ? `Letters ${letters[0]}–${letters[letters.length - 1]}` : `Letter ${letters[0]}`;
    const label = names.map((n) => (n === 'letters' ? range : n)).join(' · ');
    const part = flowOf(p).firstElementChild.dataset.part;
    p.querySelector('.where small').textContent = label;
    p.querySelector('.foot span').lastChild.textContent = ` · ${part} · ${label}`;
  });

  pages.forEach((p, i) => {
    const pg = p.querySelector('.pg');
    if (pg) pg.textContent = i + 1;
  });
  document.querySelectorAll('[data-toc-ref]').forEach((el) => {
    const target = document.querySelector(`[data-toc="${el.dataset.tocRef}"]`);
    el.textContent = target ? pages.indexOf(target.closest('.page')) + 1 : '';
  });
  return pages.filter(overflows).length;
})();
