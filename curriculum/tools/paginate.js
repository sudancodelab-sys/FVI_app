// Splits lessons that are longer than one A4 page, then numbers the pages.
// Sections (.sec) move to a continuation page whole. A section of letter
// teams that does not fit is split between teams instead, so a long list
// (like the R lesson) fills the page and continues under "(continued)".
// Then lessons on .stream pages run on: the next lesson starts under the end
// of the one before when it fits, so no page is left half empty.
window.fviReady = (async () => {
  await document.fonts.ready;
  const overflows = (page) => page.scrollHeight > page.clientHeight + 1;
  const flowOf = (page) => page.querySelector('.flow');
  // A section may split between its letter teams or its rule boxes. One with
  // other content (a grid of sound cards) keeps that content and may hand on
  // every box; a plain list keeps at least its first one.
  const items = (sec) => sec.querySelectorAll(':scope > .team, :scope > .rule');
  const minKeep = (sec) => ([...sec.children].some((el) =>
    !el.matches('h2, .partbar, .team, .rule')) ? 0 : 1);
  const canSplit = (sec) => items(sec).length > minKeep(sec);
  document.querySelectorAll('.sec').forEach((sec, i) => { sec.dataset.sid = i; });

  // One-page lessons (.fit) first try tighter spacing before anything moves.
  document.querySelectorAll('.page.fit').forEach((page) => {
    for (const step of ['dense', 'denser']) {
      if (overflows(page)) page.classList.add(step);
    }
  });

  const continuation = (page) => {
    const next = document.createElement('div');
    next.className = 'page cont' + (page.classList.contains('stream') ? ' stream' : '');
    next.dataset.part = page.dataset.part || '';
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

  // An empty "(continued)" part of `sec` at the start of `next`.
  const newTail = (sec, next) => {
    const tail = document.createElement('div');
    tail.className = 'sec';
    // Every part of a section shares its id, so any part can take the next one back.
    tail.dataset.tailOf = sec.dataset.sid;
    tail.dataset.sid = sec.dataset.sid;
    tail.dataset.lesson = sec.dataset.lesson;
    const heading = sec.querySelector('h2').cloneNode(true);
    if (!sec.dataset.tailOf) heading.append(' (continued)');
    tail.append(heading);
    flowOf(next).prepend(tail);
    return tail;
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
      if (canSplit(last)) {
        next = next || continuation(page);
        const tail = tailOf(last, next) || newTail(last, next);
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
  // Pull content up from the next stream page while it fits. A lesson's start
  // (strip and title) never ends a page alone: it moves with the section after
  // it, or at least with the part of that section that fits.
  const streamPages = () => [...document.querySelectorAll('.page.stream')];
  // Moves boxes from the start of `tail` to the end of `sec` while they fit.
  const pullItems = (page, sec, tail) => {
    while (items(tail).length) {
      const item = items(tail)[0];
      sec.append(item);
      if (overflows(page)) {
        tail.insertBefore(item, tail.children[1] || null);
        return false;
      }
    }
    tail.remove();
    return true;
  };
  // `sec` was just moved to the end of `page` from the start of `next`. Hands
  // its last boxes back to `next` until the page fits; false (and everything
  // put back together) when even the smallest part does not fit.
  const fitBySplitting = (page, sec, next) => {
    if (!overflows(page)) return true;
    if (!canSplit(sec)) return false;
    const tail = newTail(sec, next);
    while (overflows(page) && items(sec).length > minKeep(sec)) {
      tail.insertBefore(items(sec)[items(sec).length - 1], tail.children[1] || null);
    }
    if (!overflows(page)) {
      if (!items(tail).length) tail.remove();
      return true;
    }
    [...items(tail)].forEach((item) => sec.append(item));
    tail.remove();
    return false;
  };
  // A stream page that opens in the middle of a lesson says "(continued)". The
  // label is set before the page is filled, since it takes room too.
  const titles = {};
  document.querySelectorAll('.lstart').forEach((el) => { titles[el.dataset.lesson] = el.dataset.title; });
  const relabel = (page) => {
    page.querySelectorAll(':scope > .contd').forEach((el) => el.remove());
    const first = flowOf(page).firstElementChild;
    if (first && !first.classList.contains('lstart')) {
      const label = document.createElement('div');
      label.className = 'contd';
      label.textContent = titles[first.dataset.lesson] + ' (continued)';
      flowOf(page).before(label);
    }
  };
  const pull = (page, next) => {
    for (;;) {
      const first = flowOf(next).firstElementChild;
      if (!first) return;
      const last = flowOf(page).lastElementChild;
      if (first.dataset.tailOf && last && last.dataset.sid === first.dataset.tailOf) {
        if (!pullItems(page, last, first)) return;
        continue;
      }
      const group = first.classList.contains('lstart') && first.nextElementSibling
        ? [first, first.nextElementSibling] : [first];
      group.forEach((el) => flowOf(page).append(el));
      const sec = group[group.length - 1];
      if (!fitBySplitting(page, sec, next)) {
        group.reverse().forEach((el) => flowOf(next).prepend(el));
        return;
      }
      if (flowOf(next).firstElementChild && flowOf(next).firstElementChild.dataset.tailOf) return;
    }
  };
  for (let i = 0; i < streamPages().length - 1; i++) {
    const page = streamPages()[i];
    const next = page.nextElementSibling;
    relabel(page);
    if (!next || !next.classList.contains('stream')) continue;
    pull(page, next);
    if (!flowOf(next).firstElementChild) {
      next.remove();
      i--;  // keep filling this page from the page after
    }
  }
  streamPages().forEach(relabel);  // the last page may have lost its start too

  // Each stream page names the lessons it holds.
  streamPages().forEach((page) => {
    const lessons = [...new Set([...flowOf(page).children].map((el) => el.dataset.lesson))];
    const nums = lessons.length > 1 ? `Lessons ${lessons[0]}–${lessons[lessons.length - 1]}` : `Lesson ${lessons[0]}`;
    page.querySelector('.where small').textContent = `${page.dataset.part} · ${nums}`;
    const foot = page.querySelector('.foot span');
    foot.lastChild.textContent = ` · ${page.dataset.part} · ` + lessons.map((n) => titles[n]).join(' · ');
  });

  // Page numbers count every page (the cover too, though it shows none).
  const pages = [...document.querySelectorAll('.page')];
  pages.forEach((page, i) => {
    const pg = page.querySelector('.pg');
    if (pg) pg.textContent = i + 1;
  });
  document.querySelectorAll('[data-toc-ref]').forEach((el) => {
    const target = document.querySelector(`[data-toc="${el.dataset.tocRef}"]`);
    el.textContent = target ? pages.indexOf(target.closest('.page')) + 1 : '';
  });
  return [...document.querySelectorAll('.page')].filter(overflows).length;
})();
