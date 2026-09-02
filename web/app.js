/* 100 Pompes Challenge — version web.
   Même logique que l'app iPhone : une journée court de minuit à minuit, les
   totaux sont rangés sous la date locale du jour, un jour est validé quand
   TOUS les exercices du défi ont atteint leur objectif.
   Tout est stocké dans le navigateur (localStorage) : rien ne part ailleurs. */

const KINDS = {
  pushups: { name: 'Pompes', unit: 'pompes', goal: 100, quick: [5, 10, 20], step: 10, max: 500 },
  pullups: { name: 'Tractions', unit: 'tractions', goal: 20, quick: [1, 2, 5], step: 1, max: 100 },
  abs:     { name: 'Abdos', unit: 'abdos', goal: 150, quick: [10, 20, 30], step: 10, max: 600 },
};
const KIND_ORDER = ['pushups', 'pullups', 'abs'];
const STORAGE_KEY = 'pompes.challenge.web.v1';

/* ---------- état ---------- */

function startOfToday() {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

function dayKey(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function addDays(date, n) {
  const d = new Date(date.getTime());
  d.setDate(d.getDate() + n);
  d.setHours(0, 0, 0, 0);
  return d;
}

function freshState() {
  return {
    startDate: dayKey(startOfToday()),
    durationDays: 30,
    exercises: [{ kind: 'pushups', dailyGoal: 100 }],
    logs: {},
    reminders: [
      { title: 'Réveil musculaire', hour: 7, minute: 30, weight: 0.30 },
      { title: 'Pause déjeuner', hour: 13, minute: 0, weight: 0.35 },
      { title: 'Dernière ligne droite', hour: 20, minute: 30, weight: 0.35 },
    ],
    tone: 'absurd',
    appearance: 'light',
    celebrated: [],
  };
}

let state = load();
let tab = 'today';

function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return freshState();
    return Object.assign(freshState(), JSON.parse(raw));
  } catch (e) {
    return freshState();
  }
}

function save() {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch (e) { /* mode privé */ }
}

/* ---------- calculs ---------- */

const startDate = () => { const [y, m, d] = state.startDate.split('-').map(Number); return new Date(y, m - 1, d); };
const count = (kind, date) => (state.logs[dayKey(date)] || {})[kind] || 0;
const goalOf = (kind) => (state.exercises.find(e => e.kind === kind) || {}).dailyGoal || 0;
const remaining = (ex, date) => Math.max(0, ex.dailyGoal - count(ex.kind, date));
const progressOf = (ex, date) => ex.dailyGoal > 0 ? Math.min(1, count(ex.kind, date) / ex.dailyGoal) : 1;
const isValidated = (date) => state.exercises.length > 0 && state.exercises.every(e => count(e.kind, date) >= e.dailyGoal);
const totalReps = (date) => state.exercises.reduce((s, e) => s + count(e.kind, date), 0);
const dayProgress = (date) => state.exercises.length
  ? state.exercises.reduce((s, e) => s + progressOf(e, date), 0) / state.exercises.length : 0;

function rawDayIndex() {
  const diff = startOfToday().getTime() - startDate().getTime();
  return Math.floor(diff / 86400000) + 1;
}
const dayIndex = () => Math.min(Math.max(rawDayIndex(), 1), state.durationDays);
const indexFor = (date) => Math.floor((date.getTime() - startDate().getTime()) / 86400000) + 1;

function days() {
  const today = startOfToday();
  const out = [];
  for (let i = 0; i < state.durationDays; i++) {
    const date = addDays(startDate(), i);
    let status;
    if (isValidated(date)) status = 'done';
    else if (date.getTime() === today.getTime()) status = 'now';
    else if (date < today) status = 'miss';
    else status = 'next';
    out.push({ n: i + 1, date, status, progress: dayProgress(date), reps: totalReps(date) });
  }
  return out;
}

const validatedCount = () => days().filter(d => d.status === 'done').length;
const challengeProgress = () => state.durationDays > 0 ? validatedCount() / state.durationDays : 0;
const totalAll = () => days().reduce((s, d) => s + d.reps, 0);

function currentStreak() {
  let streak = 0;
  const list = days();
  for (let i = list.length - 1; i >= 0; i--) {
    const d = list[i];
    if (d.status === 'next') continue;
    if (d.status === 'done') streak++;
    else if (d.status === 'now') continue;
    else break;
  }
  return streak;
}

function bestStreak() {
  let best = 0, run = 0;
  for (const d of days()) {
    if (d.status === 'done') { run++; best = Math.max(best, run); }
    else if (d.status === 'now') continue;
    else run = 0;
  }
  return best;
}

function focusExercise() {
  const today = startOfToday();
  const pending = state.exercises.filter(e => remaining(e, today) > 0);
  if (!pending.length) return null;
  return pending.reduce((a, b) => remaining(b, today) > remaining(a, today) ? b : a);
}

function shareText(reminder) {
  return state.exercises
    .map(e => `${Math.max(1, Math.round(e.dailyGoal * reminder.weight))} ${KINDS[e.kind].unit}`)
    .join(', ');
}

const grouped = (n) => n.toLocaleString('fr-FR').replace(/ |\s/g, ' ');

/* ---------- écriture ---------- */

function setCount(kind, value, date) {
  const key = dayKey(date);
  const was = isValidated(date);
  const log = Object.assign({}, state.logs[key] || {});
  log[kind] = Math.min(9999, Math.max(0, value));
  state.logs[key] = log;
  save();
  if (isValidated(date) && !was && !state.celebrated.includes(key)) {
    state.celebrated.push(key);
    save();
    showCelebration(date);
  }
}

const addReps = (kind, amount) => setCount(kind, count(kind, startOfToday()) + amount, startOfToday());

function setGoal(kind, value) {
  const ex = state.exercises.find(e => e.kind === kind);
  if (!ex) return;
  ex.dailyGoal = Math.min(KINDS[kind].max, Math.max(1, value));
  save();
  render();
}

function startChallenge(duration, exercises) {
  if (!exercises.length) return;
  state.startDate = dayKey(startOfToday());
  state.durationDays = Math.min(365, Math.max(1, duration));
  state.exercises = exercises;
  state.logs = {};
  state.celebrated = [];
  save();
}

/* ---------- motivation ---------- */

function pick(list, seed) {
  if (!list.length) return '';
  let v = Math.abs(Math.imul(seed, 2654435761)) >>> 0;
  v = (v ^ (v >>> 15)) >>> 0;
  return list[v % list.length];
}

const absurdStart = (unit) => [
  `Zéro ${unit} au compteur. Tous les milliardaires ont commencé exactement comme ça, un mardi.`,
  `Rien de fait. Pourtant, quelque part, une voiture de sport attend que tu signes.`,
  `Toujours à zéro. Ton double dans l'univers parallèle en a déjà fait 200 et il est insupportable.`,
  `Zéro. Le sol t'attend. Il a même passé l'aspirateur.`,
  `Rien encore. Un jury de prix international a mis ton dossier en attente, il s'impatiente.`,
  `Zéro ${unit}. Ton lit t'a menti. Il ne t'aime pas vraiment.`,
  `Pas commencé. Le tapis commence à se sentir humilié.`,
  `Toujours rien. Ton chat te juge. Et il a raison.`,
  `Zéro. À la première série, la météo passe au grand soleil sur toute la région.`,
  `Rien de fait. Tes ancêtres te regardent depuis un nuage, légèrement déçus.`,
  `Compteur à zéro. Trois personnes très importantes attendent ta première pompe pour changer d'avis sur toi.`,
  `Zéro ${unit}. L'humanité retient son souffle. Enfin, une partie de l'humanité.`,
];

const absurdGoing = (r, unit) => [
  `Plus que ${r} ${unit} et tu deviens officiellement milliardaire. Enfin, presque.`,
  `Encore ${r} ${unit}. Après ça, on t'attend à la maison avec le meilleur plat du monde.`,
  `${r} ${unit} et les portes automatiques s'ouvriront avant même que tu arrives.`,
  `Il reste ${r} ${unit}. Une compagnie aérienne va te surclasser sans aucune raison.`,
  `${r} ${unit} avant que ton banquier ne t'appelle spontanément « Maître ».`,
  `Encore ${r}. Les feux passeront au vert sur ton passage pendant 48 heures.`,
  `${r} ${unit} et tu récupères enfin la caution d'appartement de 2009.`,
  `Plus que ${r}. À la fin, un inconnu te proposera un poste de PDG dans l'ascenseur.`,
  `${r} ${unit} restantes. Ton pantalon préféré vient de se retailler tout seul.`,
  `Encore ${r} ${unit} et la file de la boulangerie s'écartera devant toi comme la mer Rouge.`,
  `${r} ${unit}. Après ça, tu comprendras enfin les règles du cricket.`,
  `Il reste ${r} ${unit}. Un notaire cherche activement ton adresse pour un héritage.`,
  `Plus que ${r} ${unit} et tu ouvriras les bocaux de cornichons d'un simple regard.`,
  `${r} restantes. Le voisin du dessus va enfin arrêter de déplacer ses meubles la nuit.`,
  `Encore ${r} ${unit} : ton wifi va doubler de vitesse. Ce n'est prouvé par personne.`,
  `${r} ${unit} et les moustiques changeront de trottoir en te voyant.`,
  `Il te reste ${r} ${unit} avant que la gravité ne t'accorde une remise de 12 %.`,
  `${r} ${unit} et ton nom entre dans une légende urbaine du 15e arrondissement.`,
  `Plus que ${r}. Ensuite, les serveurs t'apporteront le pain sans que tu demandes.`,
  `${r} ${unit} et tu gagnes le droit de dire « à mon époque » sans être ridicule.`,
  `Encore ${r} ${unit}. Ton ostéopathe s'apprête à fermer boutique par manque de travail.`,
  `${r} ${unit} restantes avant que ton téléphone ne tienne trois jours sur une charge.`,
  `Il reste ${r} ${unit}. Une chorale répète en ce moment même une chanson à ta gloire.`,
  `${r} ${unit} et les escaliers du métro te présenteront leurs excuses.`,
];

const absurdDone = (day) => [
  `Jour ${day} terminé. Quelque part, un parfait inconnu vient de t'ajouter à son testament.`,
  `C'est fait. Ton reflet dans le miroir t'a fait un clin d'œil.`,
  `Terminé. Les pigeons du quartier ont décidé de te suivre partout.`,
  `Journée bouclée. Ton banquier vient d'appeler juste pour te féliciter.`,
  `Fini. Ton canapé te regarde avec un respect entièrement nouveau.`,
  `Objectif atteint. La gravité a accepté de baisser de 4 % pour toi ce soir.`,
  `C'est plié. Trois inconnus vont te tenir la porte demain sans raison.`,
  `Terminé. Le wifi passe désormais à travers les murs porteurs chez toi.`,
  `Journée validée. Un chef étoilé prépare ton dîner à cet instant, sans le savoir.`,
  `Fini. Ton nom vient d'apparaître dans un livre d'histoire, page 412, note de bas de page.`,
  `C'est bon. Ta photo de profil a spontanément pris trois ans de moins.`,
  `Terminé. Le soleil s'est levé une deuxième fois, uniquement par politesse.`,
  `Journée pliée. Ton frigo s'est rempli tout seul de choses parfaitement saines.`,
  `Objectif atteint. Une plaque commémorative est en cours de gravure quelque part.`,
  `Fini. Les chaussettes de la machine à laver reviendront toutes par paires.`,
];

function motivationLine() {
  const today = startOfToday();
  const focus = focusExercise();
  const day = dayIndex();
  const c = focus ? count(focus.kind, today) : 0;
  const r = focus ? remaining(focus, today) : 0;
  const unit = focus ? KINDS[focus.kind].unit : '';
  const seed = day * 131 + c;

  if (state.tone === 'absurd') {
    if (!focus) return pick(absurdDone(day), seed);
    if (c === 0) return pick(absurdStart(unit), seed);
    return pick(absurdGoing(r, unit), seed);
  }
  if (!focus) {
    if (state.tone === 'cash') return `Objectif plié. Jour ${day} dans la poche.`;
    if (state.tone === 'coach') return `Journée validée. C'est exactement comme ça qu'on construit une habitude.`;
    return `C'est fait. Rien à ajouter, la journée est complète.`;
  }
  if (c === 0) {
    if (state.tone === 'cash') return `Rien de fait pour l'instant. La première série coûte 90 secondes.`;
    if (state.tone === 'coach') return `On démarre doucement : le plus dur est de commencer.`;
    return `Commence par une seule série. Le reste suivra.`;
  }
  if (state.tone === 'cash') return `Plus que ${r} ${unit}. C'est 3 minutes de ta journée, pas plus.`;
  if (state.tone === 'coach') return `${c} de faites, ${r} ${unit} restantes. Coupe ça en deux séries.`;
  return `${c} derrière toi. Avance à ton rythme, il reste ${r} ${unit}.`;
}

function celebrationMessage(day) {
  const left = Math.max(0, state.durationDays - day);
  const total = totalAll();
  if (left === 0) return `Défi terminé. ${grouped(total)} répétitions.\nLe monde te doit officiellement quelque chose.`;
  if (state.tone === 'absurd') {
    return pick([
      `Jour ${day} validé.\nUne statue de toi vient d'être commandée dans une petite commune.`,
      `${grouped(total)} répétitions au total.\nUn fonds d'investissement veut te rencontrer.`,
      `Encore ${left} jours.\nLes lois de la physique commencent à négocier avec toi.`,
      `Jour ${day} dans la poche.\nTon nom circule déjà dans les couloirs du pouvoir.`,
      `${grouped(total)} répétitions.\nDeux inconnus ont pleuré de fierté sans savoir pourquoi.`,
      `Plus que ${left} jours.\nTa légende s'écrit, et l'auteur a du mal à suivre.`,
      `Jour ${day} terminé.\nLe monde tourne 0,3 % plus vite depuis ta dernière série.`,
      `Encore ${left} jours.\nLes miroirs de la ville se disputent ton reflet.`,
    ], day * 17);
  }
  if (day * 2 === state.durationDays) return `Tu viens de passer la moitié du défi.\n${grouped(total)} répétitions depuis le jour 1.`;
  return `${left} jours avant la fin du défi.\nTotal : ${grouped(total)} répétitions.`;
}

/* ---------- fragments ---------- */

const ICON = {
  today: '<svg viewBox="0 0 24 24"><path d="M4 13h3l2-5 3 9 2.5-6 1.5 2h4"/></svg>',
  calendar: '<svg viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="16" rx="3"/><path d="M3 10h18M8 3v4M16 3v4"/></svg>',
  settings: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3.2"/><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-1.8-.3 1.6 1.6 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1A1.6 1.6 0 0 0 9 19.4a1.6 1.6 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.6 1.6 0 0 0 .3-1.8 1.6 1.6 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1A1.6 1.6 0 0 0 4.6 9a1.6 1.6 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.6 1.6 0 0 0 1.8.3H9a1.6 1.6 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 1 1.5 1.6 1.6 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0-.3 1.8V9a1.6 1.6 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1z"/></svg>',
  star: '<svg viewBox="0 0 24 24"><path d="M12 2.4l2.95 5.98 6.6.96-4.78 4.66 1.13 6.57L12 17.47l-5.9 3.1 1.13-6.57L2.45 9.34l6.6-.96z"/></svg>',
  flame: '<svg viewBox="0 0 24 24" style="width:15px;height:15px;fill:var(--orange-light);stroke:none"><path d="M12 2c.6 3 2.3 4.2 3.6 5.7 1.4 1.6 2.2 3.1 2.2 5.1a5.8 5.8 0 0 1-11.6 0c0-1.9.8-3.3 2-4.8C9.7 6.3 10.4 4.5 12 2Zm0 10.2c-.7 1.2-1.6 1.8-1.6 3a1.6 1.6 0 0 0 3.2 0c0-1.2-.9-1.8-1.6-3Z"/></svg>',
};

function ringSVG(progress, size, stroke) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const half = size / 2;
  return `<svg class="ring" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
    <circle class="ring-track" cx="${half}" cy="${half}" r="${r}" style="stroke-width:${stroke}px"/>
    <circle class="ring-arc" cx="${half}" cy="${half}" r="${r}"
      style="stroke-width:${stroke}px;stroke-dasharray:${c.toFixed(1)};stroke-dashoffset:${(c * (1 - progress)).toFixed(1)}"/>
  </svg>`;
}

/* ---------- écrans ---------- */

function screenToday() {
  const today = startOfToday();
  const n = Math.max(state.exercises.length, 1);
  const size = n === 1 ? 250 : (n === 2 ? 158 : 104);
  const stroke = n === 1 ? 20 : (n === 2 ? 15 : 12);
  const numSize = n === 1 ? 82 : (n === 2 ? 44 : 30);
  const streak = currentStreak();

  const rings = state.exercises.map(e => `
    <div class="ring-wrap">
      <div class="ring-box" style="width:${size}px;height:${size}px">
        ${ringSVG(progressOf(e, today), size, stroke)}
        <div class="ring-label">
          <div class="ring-num" style="font-size:${numSize}px">${count(e.kind, today)}</div>
          <div class="ring-goal" style="font-size:${n === 1 ? 15 : 12}px">/ ${e.dailyGoal}</div>
        </div>
      </div>
      <div class="ring-name" style="font-size:${n === 1 ? 13 : 11}px;letter-spacing:${n === 1 ? 2.4 : 1.2}px">${KINDS[e.kind].name}</div>
    </div>`).join('');

  const cards = state.exercises.map(e => {
    const c = count(e.kind, today);
    const done = c >= e.dailyGoal;
    return `<div class="card">
      <div class="ex-head">
        <span class="ex-name">${KINDS[e.kind].name}</span>
        ${done ? '<span style="color:var(--orange);font-weight:700">✓</span>' : ''}
        <button class="ex-count" data-act="editday"><b>${c}</b><span>/ ${e.dailyGoal}</span></button>
      </div>
      <div class="bar"><i style="width:${(progressOf(e, today) * 100).toFixed(1)}%"></i></div>
      <div class="chips">
        ${KINDS[e.kind].quick.map(a => `<button class="chip" data-act="add" data-kind="${e.kind}" data-n="${a}">+${a}</button>`).join('')}
      </div>
    </div>`;
  }).join('');

  return `
    <div class="h-row">
      <div>
        <div class="title-lg">JOUR ${dayIndex()}</div>
        <div class="sub">SUR ${state.durationDays}</div>
      </div>
      <div class="badge">${ICON.flame}<b>${streak}</b><span>${streak > 1 ? 'jours' : 'jour'}</span></div>
    </div>
    <div class="rings">${rings}</div>
    <div class="motiv"><h4>MOTIVATION DU JOUR</h4><p>${motivationLine()}</p></div>
    <div class="section">${state.exercises.length > 1 ? 'MES EXERCICES' : "AUJOURD'HUI"}</div>
    ${cards}
    <button class="btn ghost" data-act="reset" style="margin-top:14px">Remettre la journée à zéro</button>
    <div class="total">
      <span class="lbl">DÉFI ${state.durationDays} JOURS</span>
      <span class="val"><b>${validatedCount()}</b> / ${state.durationDays} jours validés</span>
    </div>
    <div class="bar big"><i style="width:${(challengeProgress() * 100).toFixed(1)}%"></i></div>`;
}

function screenCalendar() {
  const cells = days().map(d => {
    if (d.status === 'done') return `<div class="day done" data-act="editold" data-day="${d.n}">${ICON.star}<b>${d.n}</b></div>`;
    if (d.status === 'now') return `<div class="day now" data-act="editold" data-day="${d.n}"><b>${d.n}</b><span>${Math.round(d.progress * 100)} %</span><i style="width:${(d.progress * 100).toFixed(1)}%"></i></div>`;
    if (d.status === 'miss') return `<div class="day miss" data-act="editold" data-day="${d.n}">${d.n}</div>`;
    return `<div class="day next">${d.n}</div>`;
  }).join('');

  const months = new Intl.DateTimeFormat('fr-FR', { month: 'long' });
  const first = months.format(startDate());
  const last = months.format(addDays(startDate(), state.durationDays - 1));
  const range = first === last ? first : `${first} – ${last}`;
  const sub = state.exercises.map(e => `${e.dailyGoal} ${KINDS[e.kind].unit.toUpperCase()}`)
    .concat([`${state.durationDays} JOURS`]).join(' · ');

  return `
    <div class="title">${range.toUpperCase()}</div>
    <div class="sub">${sub}</div>
    <div class="total" style="margin-top:18px">
      <span class="val"><b style="font-size:17px;color:var(--orange-light)">${validatedCount()}</b> jours validés</span>
      <span class="val"><b>${Math.round(challengeProgress() * 100)} %</b></span>
    </div>
    <div class="bar big" style="height:12px;border-radius:6px"><i style="width:${(challengeProgress() * 100).toFixed(1)}%"></i></div>
    <div class="legend">
      <div><span class="sw" style="background:linear-gradient(160deg,var(--orange),var(--orange-deep))"></span>Validé</div>
      <div><span class="sw" style="background:var(--missed-fill);border:1px solid var(--border)"></span>Manqué</div>
      <div><span class="sw" style="background:var(--surface-alt);border:2px solid var(--orange)"></span>En cours</div>
    </div>
    <div class="grid">${cells}</div>
    <div class="stats">
      <div class="stat"><b class="hi">${currentStreak()}</b><span>SÉRIE EN COURS</span></div>
      <div class="stat"><b>${bestStreak()}</b><span>MEILLEURE SÉRIE</span></div>
      <div class="stat"><b>${grouped(totalAll())}</b><span>RÉPÉTITIONS AU TOTAL</span></div>
    </div>`;
}

function screenSettings() {
  const goals = state.exercises.map(e => `
    <div class="goal-row">
      <span class="nm">${KINDS[e.kind].name}</span>
      <div class="stepper">
        <button class="step" data-act="goal" data-kind="${e.kind}" data-d="-1">−</button>
        <span class="v">${e.dailyGoal}</span>
        <button class="step" data-act="goal" data-kind="${e.kind}" data-d="1">+</button>
      </div>
    </div>`).join('');

  const slots = state.reminders.map(r => `
    <div class="slot">
      <span class="tm">${String(r.hour).padStart(2, '0')} : ${String(r.minute).padStart(2, '0')}</span>
      <span class="ds">${r.title}<br>${shareText(r)}</span>
    </div>`).join('');

  const tones = [['cash', 'Cash'], ['coach', 'Coach'], ['zen', 'Zen'], ['absurd', 'Absurde']];
  const looks = [['light', 'Clair'], ['dark', 'Sombre'], ['system', 'Système']];

  return `
    <div class="title">RÉGLAGES</div>
    <div class="sub">DÉFI, RAPPELS ET APPARENCE</div>

    <div class="section">MON DÉFI</div>
    <div class="card">
      <div class="h-row"><b style="font-size:14px">Jour ${dayIndex()} sur ${state.durationDays}</b>
        <span class="ds" style="font-size:12px;color:var(--muted)">${validatedCount()} validés</span></div>
      ${goals}
    </div>
    <button class="btn" data-act="newchallenge" style="margin-top:10px">Créer un nouveau défi</button>

    <div class="section">MES 3 CRÉNEAUX</div>
    <div class="note">
      <b>Sur le web, iOS n'autorise pas les rappels automatiques.</b><br>
      Ces trois horaires sont ton plan de bataille — mets-les en alarme dans l'app Horloge,
      ça prend une minute. La vraie app iPhone, elle, envoie les notifications toute seule.
    </div>
    <div class="card" style="margin-top:10px">${slots}</div>

    <div class="section">TON DES MESSAGES</div>
    <div class="pick">
      ${tones.map(([v, l]) => `<button class="${state.tone === v ? 'on' : ''}" data-act="tone" data-v="${v}">${l}</button>`).join('')}
    </div>

    <div class="section">APPARENCE</div>
    <div class="pick">
      ${looks.map(([v, l]) => `<button class="${state.appearance === v ? 'on' : ''}" data-act="look" data-v="${v}">${l}</button>`).join('')}
    </div>

    <div class="section">INSTALLER SUR L'ÉCRAN D'ACCUEIL</div>
    <div class="note">
      Dans Safari : bouton <b>Partager</b> en bas, puis <b>Sur l'écran d'accueil</b>.
      L'icône apparaît comme une vraie app et tes données restent sur ton téléphone.
    </div>`;
}

/* ---------- feuilles modales ---------- */

let sheetState = null;

function openDaySheet(date) {
  const values = {};
  state.exercises.forEach(e => { values[e.kind] = count(e.kind, date); });
  sheetState = { type: 'day', date, values };
  renderSheet();
}

function openNewChallenge() {
  const goals = {};
  KIND_ORDER.forEach(k => { goals[k] = KINDS[k].goal; });
  const on = new Set();
  state.exercises.forEach(e => { goals[e.kind] = e.dailyGoal; on.add(e.kind); });
  sheetState = { type: 'new', duration: state.durationDays, goals, on };
  renderSheet();
}

function renderSheet() {
  const host = document.getElementById('sheet');
  if (!sheetState) { host.innerHTML = ''; return; }

  if (sheetState.type === 'day') {
    const d = sheetState.date;
    const label = new Intl.DateTimeFormat('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' }).format(d);
    const rows = state.exercises.map(e => {
      const v = sheetState.values[e.kind] || 0;
      return `<div class="card">
        <div class="ex-head"><span class="ex-name">${KINDS[e.kind].name}</span>
          <span style="margin-left:auto;font-size:12px;color:var(--muted)">objectif ${e.dailyGoal}</span></div>
        <div class="big-step">
          <button class="step" data-act="sv" data-kind="${e.kind}" data-n="-1">−</button>
          <span class="v">${v}</span>
          <button class="step" data-act="sv" data-kind="${e.kind}" data-n="1">+</button>
        </div>
        <div class="chips">
          ${KINDS[e.kind].quick.map(a => `<button class="chip" style="height:40px" data-act="sv" data-kind="${e.kind}" data-n="${a}">+${a}</button>`).join('')}
          <button class="chip" style="height:40px" data-act="sgoal" data-kind="${e.kind}">Objectif</button>
        </div>
      </div>`;
    }).join('');
    host.innerHTML = `<div class="sheet-bg" data-act="closesheet"><div class="sheet" data-stop>
      <h3>Jour ${indexFor(d)}</h3><p class="sh-sub">${label.charAt(0).toUpperCase() + label.slice(1)}</p>
      ${rows}
      <button class="btn" data-act="savesheet" style="margin-top:16px">ENREGISTRER</button>
    </div></div>`;
    return;
  }

  const rows = KIND_ORDER.map(k => {
    const on = sheetState.on.has(k);
    const g = sheetState.goals[k];
    return `<div class="card ${on ? '' : 'dim'}">
      <div class="sw-row">
        <span class="ex-name">${KINDS[k].name}</span>
        <span class="toggle ${on ? 'on' : ''}" data-act="togglekind" data-kind="${k}"><i></i></span>
      </div>
      ${on ? `<div class="goal-row"><span class="ds" style="font-size:12px;color:var(--muted)">par jour</span>
        <div class="stepper">
          <button class="step" data-act="ngoal" data-kind="${k}" data-d="-1">−</button>
          <span class="v">${g}</span>
          <button class="step" data-act="ngoal" data-kind="${k}" data-d="1">+</button>
        </div></div>` : ''}
    </div>`;
  }).join('');

  const presets = [7, 14, 21, 30, 60, 90];
  host.innerHTML = `<div class="sheet-bg" data-act="closesheet"><div class="sheet" data-stop>
    <h3>NOUVEAU DÉFI</h3><p class="sh-sub">Durée et exercices</p>
    <div class="big-step">
      <button class="step" data-act="dur" data-n="-1">−</button>
      <span class="v">${sheetState.duration}<small>${sheetState.duration > 1 ? 'JOURS' : 'JOUR'}</small></span>
      <button class="step" data-act="dur" data-n="1">+</button>
    </div>
    <div class="presets">${presets.map(p => `<button class="${sheetState.duration === p ? 'on' : ''}" data-act="durset" data-n="${p}">${p}</button>`).join('')}</div>
    <div class="section">EXERCICES</div>
    ${rows}
    <button class="btn" data-act="startchallenge" style="margin-top:16px" ${sheetState.on.size ? '' : 'disabled'}>DÉMARRER LE DÉFI</button>
    <p style="text-align:center;font-size:12px;color:var(--muted);margin:10px 0 0">
      ${sheetState.on.size ? "Remplace le défi en cours et efface son historique" : 'Choisis au moins un exercice'}</p>
  </div></div>`;
}

/* ---------- célébration ---------- */

function showCelebration(date) {
  const day = indexFor(date);
  const box = document.getElementById('celeb');
  const summary = state.exercises.map(e => `<span>${count(e.kind, date)} ${KINDS[e.kind].unit}</span>`).join('');
  const streak = currentStreak();
  box.innerHTML = `
    <div class="star"><div>${ICON.star}</div></div>
    <div class="kicker">JOUR ${day} SUR ${state.durationDays}</div>
    <div class="big">VALIDÉ</div>
    <div class="sum">${summary}</div>
    <div class="sum"><span>${streak} ${streak > 1 ? "jours d'affilée" : "jour d'affilée"}</span></div>
    <div class="msg">${celebrationMessage(day)}</div>
    <button class="go" data-act="closeceleb">CONTINUER</button>`;
  box.classList.remove('hidden');
  if (navigator.vibrate) navigator.vibrate([12, 40, 18]);
}

/* ---------- rendu ---------- */

function render() {
  document.documentElement.setAttribute('data-theme', state.appearance);
  document.getElementById('app').innerHTML =
    tab === 'today' ? screenToday() : tab === 'calendar' ? screenCalendar() : screenSettings();
  document.getElementById('tabs').innerHTML = [
    ['today', "Aujourd'hui", ICON.today],
    ['calendar', 'Calendrier', ICON.calendar],
    ['settings', 'Réglages', ICON.settings],
  ].map(([id, label, icon]) =>
    `<button class="${tab === id ? 'on' : ''}" data-act="tab" data-v="${id}">${icon}<span>${label}</span></button>`
  ).join('');
  renderSheet();
}

/* ---------- interactions ---------- */

function buzz() { if (navigator.vibrate) navigator.vibrate(8); }

document.addEventListener('click', (event) => {
  const el = event.target.closest('[data-act]');
  if (!el) return;
  const act = el.dataset.act;
  const kind = el.dataset.kind;

  if (act === 'closesheet' && event.target.closest('[data-stop]')) return;

  switch (act) {
    case 'tab': tab = el.dataset.v; render(); return;
    case 'add': addReps(kind, Number(el.dataset.n)); buzz(); render(); return;
    case 'reset':
      if (confirm(`Remettre le jour ${dayIndex()} à zéro ?\n\nLes compteurs d'aujourd'hui repartent de zéro. Les autres jours ne sont pas touchés.`)) {
        state.exercises.forEach(e => setCount(e.kind, 0, startOfToday()));
        render();
      }
      return;
    case 'goal': setGoal(kind, goalOf(kind) + Number(el.dataset.d) * KINDS[kind].step); buzz(); return;
    case 'tone': state.tone = el.dataset.v; save(); buzz(); render(); return;
    case 'look': state.appearance = el.dataset.v; save(); buzz(); render(); return;
    case 'editday': openDaySheet(startOfToday()); return;
    case 'editold': openDaySheet(addDays(startDate(), Number(el.dataset.day) - 1)); return;
    case 'newchallenge': openNewChallenge(); return;
    case 'closesheet': sheetState = null; renderSheet(); return;
    case 'closeceleb': document.getElementById('celeb').classList.add('hidden'); render(); return;

    case 'sv':
      sheetState.values[kind] = Math.min(9999, Math.max(0, (sheetState.values[kind] || 0) + Number(el.dataset.n)));
      buzz(); renderSheet(); return;
    case 'sgoal':
      sheetState.values[kind] = goalOf(kind); buzz(); renderSheet(); return;
    case 'savesheet': {
      const { date, values } = sheetState;
      sheetState = null;
      state.exercises.forEach(e => setCount(e.kind, values[e.kind] || 0, date));
      render();
      return;
    }

    case 'dur':
      sheetState.duration = Math.min(365, Math.max(1, sheetState.duration + Number(el.dataset.n)));
      buzz(); renderSheet(); return;
    case 'durset': sheetState.duration = Number(el.dataset.n); buzz(); renderSheet(); return;
    case 'togglekind':
      if (sheetState.on.has(kind)) sheetState.on.delete(kind); else sheetState.on.add(kind);
      buzz(); renderSheet(); return;
    case 'ngoal':
      sheetState.goals[kind] = Math.min(KINDS[kind].max,
        Math.max(1, sheetState.goals[kind] + Number(el.dataset.d) * KINDS[kind].step));
      buzz(); renderSheet(); return;
    case 'startchallenge': {
      if (!sheetState.on.size) return;
      if (!confirm('Démarrer ce nouveau défi ?\n\nLe défi en cours et tout son historique seront effacés. Le nouveau défi démarre aujourd\'hui, au jour 1.')) return;
      const exercises = KIND_ORDER.filter(k => sheetState.on.has(k))
        .map(k => ({ kind: k, dailyGoal: sheetState.goals[k] }));
      const duration = sheetState.duration;
      sheetState = null;
      startChallenge(duration, exercises);
      tab = 'today';
      render();
      return;
    }
  }
});

/* Bascule de jour à minuit, et au retour sur l'onglet. */
let lastDay = dayKey(startOfToday());
setInterval(() => {
  const now = dayKey(startOfToday());
  if (now !== lastDay) { lastDay = now; render(); }
}, 30000);
document.addEventListener('visibilitychange', () => { if (!document.hidden) render(); });

render();

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js').catch(() => {});
}
