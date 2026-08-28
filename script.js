document.addEventListener('DOMContentLoaded', () => {

  /* LEGENDA: toggle evidenziazione entità nel testo
     Ogni .leg-voce ha un data-target. Cliccandola,
     si aggiunge/rimuove quella classe dal <body>,
     che il CSS usa per evidenziare tutti gli elementi di quel tipo */
  const voci = document.querySelectorAll('.leg-voce');

  voci.forEach(voce => {
    const toggle = () => {
      document.body.classList.toggle(voce.dataset.target);
      voce.classList.toggle('attiva');
    };
    voce.addEventListener('click', toggle);
    voce.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); }
    });
  });

  const reset = document.querySelector('.legenda-reset');
  if (reset) reset.addEventListener('click', () => {
    [...document.body.classList].forEach(c => {
      if (c.startsWith('show-')) document.body.classList.remove(c);
    });
    voci.forEach(v => v.classList.remove('attiva'));
  });


  /* CORRISPONDENZA TESTO - IMMAGINE: al passaggio del mouse
     su una riga di testo (span[data-zone]), si evidenzia la
     zona corrispondente sull'immagine facsimile e viceversa
     hovering sulla zona evidenzia la riga */

  // Trova l'elemento .facs-coords più vicino dentro lo stesso .pagina
  const didascalia = el => {
    const pagina = el.closest('.pagina');
    return pagina ? pagina.querySelector('.facs-coords') : null;
  };

  // Accende o spegne la coppia zona-hot - riga di testo
  const accendi = (zona, on) => {
    const elementi = document.querySelectorAll(`[data-zone="${zona}"]`);
    let coords = null;

    elementi.forEach(el => {
      if (el.classList.contains('zona-hot')) {
        el.classList.toggle('on', on);       // riquadro sull'immagine
        coords = el.dataset.coords;
      } else {
        el.classList.toggle('evidenziata', on);   // riga di testo
      }
    });

    // Aggiorna la didascalia con le coordinate della zona
    const primo = elementi[0];
    if (!primo) return;
    const cap = didascalia(primo);
    if (!cap) return;

    if (on && coords) {
      cap.textContent = coords;
      cap.classList.add('attiva');
    } else {
      cap.textContent = cap.dataset.vuoto || '';
      cap.classList.remove('attiva');
    }
  };

  document.querySelectorAll('[data-zone]').forEach(el => {
    const zona = el.dataset.zone;
    el.addEventListener('mouseenter', () => accendi(zona, true));
    el.addEventListener('mouseleave', () => accendi(zona, false));
    el.addEventListener('focus',      () => accendi(zona, true));
    el.addEventListener('blur',       () => accendi(zona, false));
  });


  /* BARRA PAGINE: segnala quale pagina è in viewport.
     Usa IntersectionObserver per aggiungere .corrente al link
     della pagina attualmente visibile */
  const pagine = document.querySelectorAll('article.pagina');
  const vociNav = {};
  document.querySelectorAll('.pagine a').forEach(a => {
    vociNav[a.getAttribute('href').slice(1)] = a;
  });

  if ('IntersectionObserver' in window && pagine.length) {
    const obs = new IntersectionObserver(entries => {
      entries.forEach(e => {
        const a = vociNav[e.target.id];
        if (a) a.classList.toggle('corrente', e.isIntersecting);
      });
    }, { rootMargin: '-35% 0px -55% 0px' });
    pagine.forEach(p => obs.observe(p));
  }


  /* SOMMARIO: evidenzia l'articolo in lettura. Usa un
     secondo IntersectionObserver sulle <section> articolo
     per marcare la voce attiva nel sommario */
  const sezioni = document.querySelectorAll('.articolo-wrap');
  const linkSommario = {};
  document.querySelectorAll('.sommario a').forEach(a => {
    linkSommario[a.getAttribute('href').slice(1)] = a;
  });

  if ('IntersectionObserver' in window && sezioni.length) {
    const obsSez = new IntersectionObserver(entries => {
      entries.forEach(e => {
        const a = linkSommario[e.target.id];
        if (a) {
          a.parentElement.style.borderLeftColor = e.isIntersecting
            ? 'var(--bordeaux)' : 'transparent';
          a.parentElement.style.borderLeftWidth = e.isIntersecting
            ? '3px' : '0';
          a.parentElement.style.borderLeftStyle = 'solid';
          a.parentElement.style.paddingLeft = e.isIntersecting
            ? '.5rem' : '0';
        }
      });
    }, { rootMargin: '-20% 0px -70% 0px' });
    sezioni.forEach(s => obsSez.observe(s));
  }


  /* APPENDICE: quando si clicca un link .int nel testo, la voce
     target nell'appendice riceve un'animazione di evidenziazione */
  document.querySelectorAll('a.int').forEach(link => {
    link.addEventListener('click', e => {
      const target = document.querySelector(link.getAttribute('href'));
      if (!target) return;
      target.classList.remove('flash');
      void target.offsetWidth;           // forza reflow per rilanciare l'animazione
      target.classList.add('flash');
    });
  });

  // Stile CSS per l'animazione flash
  const flashStyle = document.createElement('style');
  flashStyle.textContent = `
    @keyframes voce-flash {
      0%   { background: var(--t-persona); }
      100% { background: transparent; }
    }
    .app-lista li.flash {
      animation: voce-flash 1.8s ease-out;
    }
  `;
  document.head.appendChild(flashStyle);


  /* TOOLTIP ENTITÀ: popup informativo al hover
     Per ogni <a class="... int"> nel testo, mostra un tooltip
     col contenuto della voce corrispondente nell'appendice */
  let tooltip = null;

  const creaTooltip = () => {
    tooltip = document.createElement('div');
    tooltip.className = 'tooltip-entita';
    tooltip.setAttribute('role', 'tooltip');
    document.body.appendChild(tooltip);

    const stile = document.createElement('style');
    stile.textContent = `
      .tooltip-entita {
        position: fixed;
        z-index: 100;
        max-width: 320px;
        padding: .6rem .8rem;
        background: var(--inchiostro);
        color: var(--carta-chiara);
        font-family: var(--testo);
        font-size: .8rem;
        line-height: 1.45;
        border: 1px solid var(--oro);
        box-shadow: 2px 3px 8px rgba(0,0,0,.25);
        pointer-events: none;
        opacity: 0;
        transition: opacity .15s;
        display: none;
      }
      .tooltip-entita.visibile {
        opacity: 1;
        display: block;
      }
      .tooltip-entita .tt-nome {
        font-weight: 700;
        font-size: .85rem;
        display: block;
        margin-bottom: .2rem;
        color: var(--oro-chiaro, #d4bc76);
      }
      .tooltip-entita .tt-meta {
        font-family: var(--mono);
        font-size: .68rem;
        color: var(--pergamena, #d5c7ab);
        display: block;
        margin-bottom: .15rem;
      }
      .tooltip-entita .tt-nota {
        font-style: italic;
        font-size: .76rem;
        color: var(--carta, #f1e8d8);
      }
    `;
    document.head.appendChild(stile);
  };

  const mostraTooltip = (e, target) => {
    if (!tooltip) creaTooltip();

    const href = target.getAttribute('href');
    if (!href || !href.startsWith('#voce-')) return;
    const voce = document.querySelector(href);
    if (!voce) return;

    const nome = voce.querySelector('.app-nome');
    const date = voce.querySelector('.app-date');
    const tipo = voce.querySelector('.app-tipo');
    const nota = voce.querySelector('.app-nota') || voce.querySelector('.app-desc');

    if (!nome && !nota) return;

    let html = '';
    if (nome) html += `<span class="tt-nome">${nome.textContent}</span>`;
    const meta = [date, tipo].filter(Boolean).map(el => el.textContent.trim()).join(' ');
    if (meta) html += `<span class="tt-meta">${meta}</span>`;
    if (nota) {
      const testoNota = nota.textContent.trim();
      html += `<span class="tt-nota">${testoNota.length > 150 ? testoNota.slice(0, 147) + '…' : testoNota}</span>`;
    }

    tooltip.innerHTML = html;
    tooltip.classList.add('visibile');

    // Posizionamento
    const rect = target.getBoundingClientRect();
    let top = rect.top - tooltip.offsetHeight - 8;
    let left = rect.left + (rect.width / 2) - (tooltip.offsetWidth / 2);
    if (top < 4) top = rect.bottom + 8;
    if (left < 4) left = 4;
    if (left + tooltip.offsetWidth > window.innerWidth - 4) {
      left = window.innerWidth - tooltip.offsetWidth - 4;
    }
    tooltip.style.top = top + 'px';
    tooltip.style.left = left + 'px';
  };

  const nascondiTooltip = () => {
    if (tooltip) tooltip.classList.remove('visibile');
  };

  document.querySelectorAll('a.int').forEach(link => {
    link.addEventListener('mouseenter', e => mostraTooltip(e, link));
    link.addEventListener('mouseleave', nascondiTooltip);
    link.addEventListener('focus', e => mostraTooltip(e, link));
    link.addEventListener('blur', nascondiTooltip);
  });


  /* TORNA IN CIMA: bottone flottante che appare
     dopo il primo scroll significativo */
  const btnTop = document.createElement('button');
  btnTop.className = 'btn-top';
  btnTop.setAttribute('aria-label', 'Torna in cima');
  btnTop.textContent = '▲';
  document.body.appendChild(btnTop);

  const stileTop = document.createElement('style');
  stileTop.textContent = `
    .btn-top {
      position: fixed;
      bottom: 1.2rem;
      right: 1.2rem;
      z-index: 50;
      width: 2.4rem; height: 2.4rem;
      background: var(--inchiostro);
      color: var(--oro);
      border: 1px solid var(--oro);
      font-size: 1rem;
      cursor: pointer;
      opacity: 0;
      pointer-events: none;
      transition: opacity .2s;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .btn-top.visibile { opacity: 1; pointer-events: auto; }
    .btn-top:hover { background: var(--bordeaux); border-color: var(--bordeaux); color: #fff; }
  `;
  document.head.appendChild(stileTop);

  btnTop.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));
  window.addEventListener('scroll', () => {
    btnTop.classList.toggle('visibile', window.scrollY > 600);
  }, { passive: true });

});