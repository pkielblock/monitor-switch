const LAST = "monitor-switch-last";
const LANG = "monitor-switch-lang";
// Lucide icons (lucide-static 1.65.0, ISC), inlined because the CSP allows no CDN.
const ICONS = {
  desktop: '<rect width="20" height="14" x="2" y="3" rx="2"/><line x1="8" x2="16" y1="21" y2="21"/><line x1="12" x2="12" y1="17" y2="21"/>',
  laptop: '<path d="M18 5a2 2 0 0 1 2 2v8.526a2 2 0 0 0 .212.897l1.068 2.127a1 1 0 0 1-.9 1.45H3.62a1 1 0 0 1-.9-1.45l1.068-2.127A2 2 0 0 0 4 15.526V7a2 2 0 0 1 2-2z"/><path d="M20.054 15.987H3.946"/>',
  server: '<rect width="20" height="8" x="2" y="2" rx="2" ry="2"/><rect width="20" height="8" x="2" y="14" rx="2" ry="2"/><line x1="6" x2="6.01" y1="6" y2="6"/><line x1="6" x2="6.01" y1="18" y2="18"/>',
  tv: '<path d="m17 2-5 5-5-5"/><rect width="20" height="15" x="2" y="7" rx="2"/>',
  console: '<line x1="6" x2="10" y1="11" y2="11"/><line x1="8" x2="8" y1="9" y2="13"/><line x1="15" x2="15.01" y1="12" y2="12"/><line x1="18" x2="18.01" y1="10" y2="10"/><path d="M17.32 5H6.68a4 4 0 0 0-3.978 3.59c-.006.052-.01.101-.017.152C2.604 9.416 2 14.456 2 16a3 3 0 0 0 3 3c1 0 1.5-.5 2-1l1.414-1.414A2 2 0 0 1 9.828 16h4.344a2 2 0 0 1 1.414.586L17 18c.5.5 1 1 2 1a3 3 0 0 0 3-3c0-1.545-.604-6.584-.685-7.258-.007-.05-.011-.1-.017-.151A4 4 0 0 0 17.32 5z"/>',
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
}

function toast(text, isError = false) {
  const el = $("toast");
  el.textContent = text;
  el.className = `show${isError ? " err" : ""}`;
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

async function init() {
  const res = await fetch("api/config").catch(() => null);
  if (!res?.ok) return toast(t("unreachable"), true);
  const { monitor, inputs } = await res.json();
  $("monitor").textContent = monitor;

  const list = $("inputs");
  inputs.forEach((input) => {
    const card = document.createElement("button");
    card.className = "card";
    card.dataset.id = input.id;
    card.dataset.label = input.label;
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
