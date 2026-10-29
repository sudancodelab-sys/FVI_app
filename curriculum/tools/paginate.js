// Splits lessons that are longer than one A4 page. Whole sections (.sec) move
// to a continuation page; a section is never cut in half. Then numbers pages.
window.fviReady = (async () => {
  await document.fonts.ready;
  const overflows = (page) => page.scrollHeight > page.clientHeight + 1;
  const continuation = (page) => {
    const next = document.createElement('div');
    next.className = 'page cont';
    next.append(page.querySelector('.head').cloneNode(true));
    const label = document.createElement('div');
    label.className = 'contd';
    label.textContent = page.dataset.title + ' (continued)';
    next.append(label);
    const flow = document.createElement('div');
    flow.className = 'flow';
    next.append(flow, page.querySelector('.foot').cloneNode(true));
    next.dataset.title = page.dataset.title;
    page.after(next);
    return next;
  };
  for (let i = 0; i < document.querySelectorAll('.page').length; i++) {
    const page = document.querySelectorAll('.page')[i];
    let next = null;
    while (overflows(page)) {
      const sections = page.querySelectorAll('.flow > .sec');
      if (sections.length <= 1) {
        console.warn('section taller than a page: ' + page.dataset.title);
        break;
      }
      next = next || continuation(page);
      next.querySelector('.flow').prepend(sections[sections.length - 1]);
    }
  }
  document.querySelectorAll('.page .pg').forEach((el, i) => { el.textContent = i + 1; });
  return [...document.querySelectorAll('.page')].filter(overflows).length;
})();
