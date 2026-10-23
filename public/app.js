const LAST = "monitor-switch-last";
const LANG = "monitor-switch-lang";
// Rosé Pine: foam, rose, iris, gold, pine, love.
const ACCENTS = ["#9ccfd8", "#ebbcba", "#c4a7e7", "#f6c177", "#31748f", "#eb6f92"];

const ICONS = {
  desktop: '<rect x="3" y="4" width="18" height="12" rx="2"/><path d="M8 20h8M12 16v4"/>',
  laptop: '<rect x="5" y="5" width="14" height="10" rx="1.5"/><path d="M2.5 19h19l-2-4h-15z"/>',
  server: '<rect x="4" y="3.5" width="16" height="7" rx="1.5"/><rect x="4" y="13.5" width="16" height="7" rx="1.5"/><path d="M8 7h.01M8 17h.01M12 7h4M12 17h4"/>',
  tv: '<rect x="2.5" y="5" width="19" height="13" rx="2"/><path d="m8 2 4 3 4-3M7 21h10"/>',
  console: '<path d="M7 8h10a5 5 0 0 1 4.6 7l-.6 1.4a2.5 2.5 0 0 1-4.3.4L15 15H9l-1.7 1.8a2.5 2.5 0 0 1-4.3-.4L2.4 15A5 5 0 0 1 7 8Z"/><path d="M7 11v3M5.5 12.5h3M16 12h.01M18 13h.01"/>',
};

const $ = (id) => document.getElementById(id);

let lang = localStorage.getItem(LANG) in STRINGS ? localStorage.getItem(LANG) : "en";
const t = (key, arg) => STRINGS[lang][key].replace("{0}", arg);

function applyLang() {
  document.documentElement.lang = lang;
  $("inputs").setAttribute("aria-label", t("inputs"));
  $("lang").setAttribute("aria-label", t("language"));
  document.querySelectorAll("#lang button").forEach((b) => b.setAttribute("aria-pressed", b.dataset.lang === lang));
  document.querySelectorAll(".badge").forEach((b) => (b.textContent = t("lastSent")));
  document.querySelector("#power .power-label")?.replaceChildren(t("power"));
  document.querySelectorAll(".power-btn").forEach((b) => (b.textContent = STRINGS[lang].powerState[b.dataset.state]));
}

function toast(text, isError = false) {
  const el = $("toast");
  el.textContent = text;
  el.className = `panel show${isError ? " err" : ""}`;
  clearTimeout(toast.t);
  toast.t = setTimeout(() => el.classList.remove("show"), 2200);
}

function markLast(id) {
  document.querySelectorAll(".card").forEach((c) => c.classList.toggle("last", c.dataset.id === id));
}

async function switchTo(card) {
  card.classList.add("busy");
  try {
    const res = await fetch(`api/input/${card.dataset.id}`, { method: "POST" });
    if (!res.ok) {
      toast(t("failed", res.status), true);
    } else {
      localStorage.setItem(LAST, card.dataset.id);
      markLast(card.dataset.id);
      toast(t("switched", card.dataset.label));
    }
  } catch {
    toast(t("unreachable"), true);
  } finally {
    card.classList.remove("busy");
  }
}

async function powerTo(btn) {
  btn.classList.add("busy");
  try {
    const res = await fetch(`api/power/${btn.dataset.state}`, { method: "POST" });
    if (!res.ok) {
      toast(t("failed", res.status), true);
    } else {
      toast(t("powerSent", STRINGS[lang].powerState[btn.dataset.state]));
    }
  } catch {
    toast(t("unreachable"), true);
  } finally {
    btn.classList.remove("busy");
  }
}

async function init() {
  const res = await fetch("api/config").catch(() => null);
  if (!res?.ok) return toast(t("unreachable"), true);
  const { monitor, inputs, power } = await res.json();
  $("monitor").textContent = monitor;

  const panel = $("power");
  panel.innerHTML = `<span class="power-label"></span>`;
  power.forEach((state) => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "power-btn";
    btn.dataset.state = state;
    btn.addEventListener("click", () => powerTo(btn));
    panel.append(btn);
  });

  const list = $("inputs");
  inputs.forEach((input, i) => {
    const card = document.createElement("button");
    card.className = "card panel";
    card.dataset.id = input.id;
    card.dataset.label = input.label;
    card.style.setProperty("--accent", ACCENTS[i % ACCENTS.length]);
    card.innerHTML = `
      <span class="glyph"><svg viewBox="0 0 24 24">${ICONS[input.icon] ?? ICONS.desktop}</svg></span>
      <span class="text"><span class="label"></span><span class="port"></span></span>
      <span class="badge"></span>`;
    card.querySelector(".label").textContent = input.label;
    card.querySelector(".port").textContent = input.port;
    card.addEventListener("click", () => switchTo(card));
    list.append(card);
  });
  markLast(localStorage.getItem(LAST));
  applyLang();
}

$("lang").addEventListener("click", (e) => {
  const code = e.target.closest("button")?.dataset.lang;
  if (!code) return;
  lang = code;
  localStorage.setItem(LANG, code);
  applyLang();
});

applyLang();
init();
