/* ГРЕЙТ ТАЙ СПА — интерактив (без зависимостей) */
(function () {
  'use strict';
  const $ = (s, r) => (r || document).querySelector(s);
  const $$ = (s, r) => Array.from((r || document).querySelectorAll(s));

  /* ---------- Шапка: тень при скролле ---------- */
  const header = $('.header');
  const onScroll = () => header && header.classList.toggle('is-scrolled', window.scrollY > 8);
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  /* ---------- Мобильное меню ---------- */
  const mobile = $('.mobile-menu');
  $$('[data-menu-open]').forEach(b => b.addEventListener('click', () => { mobile.classList.add('is-open'); document.body.style.overflow = 'hidden'; }));
  $$('[data-menu-close]').forEach(b => b.addEventListener('click', () => { mobile.classList.remove('is-open'); document.body.style.overflow = ''; }));

  /* ---------- Выбор филиала (хранится в localStorage) ---------- */
  const BRANCH_KEY = 'gts_branch';
  const branchSelects = $$('select[data-branch-select]');
  const getBranch = () => { try { return localStorage.getItem(BRANCH_KEY) || ''; } catch (e) { return ''; } };
  const applyBranch = (val) => {
    branchSelects.forEach(s => { s.value = val; });
    // карточки прайса, относящиеся к конкретному филиалу
    $$('[data-branch]').forEach(el => {
      const b = el.getAttribute('data-branch');
      el.classList.toggle('is-filtered', !!val && !!b && b !== val);
    });
    // подсветка филиала в контактах
    $$('[data-branch-card]').forEach(el => el.classList.toggle('is-selected', !!val && el.getAttribute('data-branch-card') === val));
    // предвыбор в форме записи
    const radio = $('.form input[name="branch"][value="' + val + '"]');
    if (radio) radio.checked = true;
  };
  branchSelects.forEach(s => s.addEventListener('change', () => { try { localStorage.setItem(BRANCH_KEY, s.value); } catch (e) {} applyBranch(s.value); }));
  applyBranch(getBranch());

  /* ---------- Hero: смена фото ---------- */
  const hero = $('.hero__photo');
  if (hero) {
    const imgs = $$('img', hero), dots = $$('.hero__dots button'), caps = $$('.hero__caption span', hero);
    let i = 0, timer;
    const show = (n) => {
      i = (n + imgs.length) % imgs.length;
      imgs.forEach((im, k) => im.classList.toggle('is-active', k === i));
      dots.forEach((d, k) => d.classList.toggle('is-active', k === i));
      caps.forEach((c, k) => { c.style.display = k === i ? '' : 'none'; });
    };
    const start = () => { clearInterval(timer); timer = setInterval(() => show(i + 1), 5500); };
    dots.forEach((d, k) => d.addEventListener('click', () => { show(k); start(); }));
    show(0); start();
  }

  /* ---------- Табы ---------- */
  $$('[data-tabs]').forEach(root => {
    const btns = $$('.tabs button', root), panels = $$('.tab-panel', root);
    btns.forEach((b, k) => b.addEventListener('click', () => {
      btns.forEach(x => x.classList.remove('is-active'));
      panels.forEach(x => x.classList.remove('is-active'));
      b.classList.add('is-active');
      panels[k].classList.add('is-active');
      b.scrollIntoView({ block: 'nearest', inline: 'center', behavior: 'smooth' });
    }));
  });

  /* ---------- Раскрытие описаний ---------- */
  document.addEventListener('click', e => {
    const t = e.target.closest('[data-toggle-card]');
    if (!t) return;
    const card = t.closest('.price-card, .master');
    card.classList.toggle('is-open');
    t.textContent = card.classList.contains('is-open') ? 'Свернуть' : 'Подробнее';
  });

  /* ---------- Галерея: показать ещё + лайтбокс ---------- */
  $$('[data-gallery-more]').forEach(btn => btn.addEventListener('click', () => {
    const g = btn.closest('.tab-panel') || document;
    $$('.gallery a.is-hidden', g).forEach(a => a.classList.remove('is-hidden'));
    btn.remove();
  }));
  const lb = $('.lightbox');
  if (lb) {
    const img = $('img', lb), count = $('.lb-count', lb);
    let list = [], idx = 0;
    const open = (links, n) => { list = links; idx = n; render(); lb.classList.add('is-open'); document.body.style.overflow = 'hidden'; };
    const close = () => { lb.classList.remove('is-open'); document.body.style.overflow = ''; };
    const render = () => { img.src = list[idx].href; count.textContent = (idx + 1) + ' / ' + list.length; };
    const step = (d) => { idx = (idx + d + list.length) % list.length; render(); };
    document.addEventListener('click', e => {
      const a = e.target.closest('.gallery a');
      if (!a) return;
      e.preventDefault();
      const links = $$('a', a.closest('.gallery'));
      open(links, links.indexOf(a));
    });
    $('.lb-close', lb).addEventListener('click', close);
    $('.lb-prev', lb).addEventListener('click', () => step(-1));
    $('.lb-next', lb).addEventListener('click', () => step(1));
    lb.addEventListener('click', e => { if (e.target === lb) close(); });
    document.addEventListener('keydown', e => {
      if (!lb.classList.contains('is-open')) return;
      if (e.key === 'Escape') close();
      if (e.key === 'ArrowLeft') step(-1);
      if (e.key === 'ArrowRight') step(1);
    });
  }

  /* ---------- Модальное окно записи ---------- */
  const modal = $('#booking');
  if (modal) {
    const openModal = (preset) => {
      modal.classList.remove('is-sent');
      if (preset) { const f = $('input[name="program"]', modal); if (f) f.value = preset; }
      modal.classList.add('is-open');
      document.body.style.overflow = 'hidden';
      setTimeout(() => { const n = $('input[name="name"]', modal); n && n.focus(); }, 50);
    };
    const closeModal = () => { modal.classList.remove('is-open'); document.body.style.overflow = ''; };
    document.addEventListener('click', e => {
      const b = e.target.closest('[data-book]');
      if (!b) return;
      e.preventDefault();
      openModal(b.getAttribute('data-book') || '');
    });
    $$('[data-modal-close]', modal).forEach(b => b.addEventListener('click', closeModal));
    modal.addEventListener('click', e => { if (e.target === modal) closeModal(); });
    document.addEventListener('keydown', e => { if (e.key === 'Escape' && modal.classList.contains('is-open')) closeModal(); });

    // Маска телефона
    const phone = $('input[name="phone"]', modal);
    if (phone) phone.addEventListener('input', () => {
      let d = phone.value.replace(/\D/g, '');
      if (d.startsWith('8')) d = '7' + d.slice(1);
      if (!d.startsWith('7')) d = '7' + d;
      d = d.slice(0, 11);
      let out = '+7';
      if (d.length > 1) out += ' (' + d.slice(1, 4);
      if (d.length >= 4) out += ') ' + d.slice(4, 7);
      if (d.length >= 7) out += '-' + d.slice(7, 9);
      if (d.length >= 9) out += '-' + d.slice(9, 11);
      phone.value = out;
    });

    // Отправка. Бэкенда у статического прототипа нет: здесь нужно подключить
    // реальный обработчик (например, fetch('/api/booking', {method:'POST', body: new FormData(form)})).
    $('form', modal).addEventListener('submit', e => {
      e.preventDefault();
      const form = e.target;
      const data = Object.fromEntries(new FormData(form).entries());
      console.info('Заявка на запись (демо, не отправляется):', data);
      modal.classList.add('is-sent');
      form.reset();
    });
  }

  /* ---------- Прочие формы (франшиза) ---------- */
  $$('form[data-demo-form]').forEach(f => f.addEventListener('submit', e => {
    e.preventDefault();
    f.querySelector('.form-success').style.display = 'block';
    f.querySelector('.form__fields').style.display = 'none';
  }));

  /* ---------- Появление блоков ---------- */
  if ('IntersectionObserver' in window) {
    const io = new IntersectionObserver(es => es.forEach(en => { if (en.isIntersecting) { en.target.classList.add('is-in'); io.unobserve(en.target); } }), { threshold: 0, rootMargin: '0px 0px -40px 0px' });
    $$('.reveal').forEach(el => io.observe(el));
    // страховка: что бы ни случилось, контент не должен остаться невидимым
    setTimeout(() => $$('.reveal:not(.is-in)').forEach(el => { if (el.getBoundingClientRect().top < window.innerHeight) el.classList.add('is-in'); }), 1500);
  } else {
    $$('.reveal').forEach(el => el.classList.add('is-in'));
  }
})();
