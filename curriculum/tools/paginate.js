// Splits lessons that are longer than one A4 page, then numbers the pages.
// Sections (.sec) move to a continuation page whole. A section of letter
// teams that does not fit is split between teams instead, so a long list
// (like the R lesson) fills the page and continues under "(continued)".
window.fviReady = (async () => {
  await document.fonts.ready;
  const overflows = (page) => page.scrollHeight > page.clientHeight + 1;
  const flowOf = (page) => page.querySelector('.flow');
  const items = (sec) => sec.querySelectorAll(':scope > .team');
  document.querySelectorAll('.sec').forEach((sec, i) => { sec.dataset.sid = i; });

  const continuation = (page) => {
    const next = document.createElement('div');
    next.className = 'page cont';
    next.append(page.querySelector('.head').cloneNode(true));
    const label = document.createElement('div');
    label.className = 'contd';
    label.textContent = page.dataset.title + ' (continued)';
    const flow = document.createElement('div');
    flow.className = 'flow';
    next.append(label, flow, page.querySelector('.foot').cloneNode(true));
    next.dataset.title = page.dataset.title;
    page.after(next);
    return next;
  };

  // The part of a split section that already moved to `next`, if any.
  const tailOf = (sec, next) => {
    const first = flowOf(next).firstElementChild;
    return first && first.dataset.tailOf === sec.dataset.sid ? first : null;
  };

  for (let i = 0; i < document.querySelectorAll('.page').length; i++) {
    const page = document.querySelectorAll('.page')[i];
    let next = null;
    while (overflows(page)) {
      const sections = flowOf(page).querySelectorAll(':scope > .sec');
      const last = sections[sections.length - 1];
      if (!last) break;
      if (items(last).length > 1) {
        next = next || continuation(page);
        let tail = tailOf(last, next);
        if (!tail) {
          tail = document.createElement('div');
          tail.className = 'sec';
          tail.dataset.tailOf = last.dataset.sid;
          const heading = last.querySelector('h2').cloneNode(true);
          heading.append(' (continued)');
          tail.append(heading);
          flowOf(next).prepend(tail);
        }
        const moving = items(last)[items(last).length - 1];
        tail.insertBefore(moving, tail.children[1] || null);
      } else if (sections.length > 1) {
        next = next || continuation(page);
        const tail = tailOf(last, next);
        if (tail) {  // re-join the section with its already-moved part
          [...items(tail)].forEach((item) => last.append(item));
          tail.remove();
        }
        flowOf(next).prepend(last);
      } else {
        console.warn('section taller than a page: ' + page.dataset.title);
        break;
      }
    }
  }
  document.querySelectorAll('.page .pg').forEach((el, i) => { el.textContent = i + 1; });
  return [...document.querySelectorAll('.page')].filter(overflows).length;
})();
