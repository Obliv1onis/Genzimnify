const DOCS = [
  { title: "Welcome to Genzimnify", url: "index.html", section: "Overview", text: "Native Python-free runtime, quick start, features" },
  { title: "Install Genzimnify", url: "installation.html", section: "Get started", text: "Homebrew macOS Windows PowerShell Ubuntu Kali Linux manual releases PATH" },
  { title: "Your first vibe", url: "getting-started.html", section: "Get started", text: "create run check project hello fizzbuzz command line" },
  { title: "Language guide", url: "language-guide.html", section: "Language", text: "variables values operators control flow functions classes exceptions imports async types" },
  { title: "Native standard library", url: "stdlib.html", section: "Reference", text: "builtins collections math system luck clock timing files" },
  { title: "Packages and projects", url: "packages.html", section: "Tools", text: "gzim.toml dependencies Git local path add install remove package manager" },
  { title: "Python interoperability", url: "python-interop.html", section: "Interop", text: "optional Python libraries py numpy json keyword arguments native core" },
  { title: "Command-line tools", url: "cli.html", section: "Tools", text: "gzim run check repl init doctor emit-python arguments exit code" },
  { title: "Editor and language server", url: "tooling.html", section: "Tools", text: "LSP Zed diagnostics hover completion definition editor" },
  { title: "Native runtime architecture", url: "native-runtime.html", section: "Concepts", text: "Nim lexer parser semantic interpreter no Python portability modules" }
];

const groups = [
  ["Overview", [["Home", "index.html"]]],
  ["Get started", [["Installation", "installation.html"], ["Your first vibe", "getting-started.html"]]],
  ["Language", [["Language guide", "language-guide.html"], ["Standard library", "stdlib.html"]]],
  ["Tools", [["Command-line interface", "cli.html"], ["Packages & projects", "packages.html"], ["Editor & LSP", "tooling.html"]]],
  ["Interop", [["Python libraries", "python-interop.html"]]],
  ["Concepts", [["Native runtime", "native-runtime.html"]]]
];

const page = location.pathname.split("/").pop() || "index.html";
const theme = localStorage.getItem("genzimnify.theme") || (matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light");
document.documentElement.dataset.theme = theme;

function renderChrome() {
  document.getElementById("siteHeader").innerHTML = `
    <header class="topbar">
      <button class="mobile-menu" id="menuBtn" aria-label="Open navigation">☰</button>
      <a class="brand" href="index.html"><span class="brand-mark">G</span><span>GENZIMNIFY</span><span class="version">2.1</span></a>
      <nav class="toplinks"><a class="active" href="index.html">Docs</a><a href="https://github.com/Obliv1onis/Genzimnify">Source</a></nav>
      <div class="top-actions">
        <button class="search-button" id="searchBtn"><span>⌕</span><span>Search documentation</span><kbd>⌘K</kbd></button>
        <button class="icon-button" id="themeBtn" aria-label="Toggle theme">${theme === "dark" ? "☼" : "◐"}</button>
        <a class="github-link" href="https://github.com/Obliv1onis/Genzimnify">GitHub ↗</a>
      </div>
    </header>`;
  document.getElementById("siteSidebar").innerHTML = groups.map(([title, links]) => `
    <div class="nav-group"><div class="nav-title">${title}</div>${links.map(([label, url]) => `<a class="nav-link ${page === url ? "active" : ""}" href="${url}">${label}</a>`).join("")}</div>`).join("") +
    `<div class="nav-group"><div class="nav-title">Project</div><a class="nav-link" href="https://github.com/Obliv1onis/Genzimnify">GitHub repository ↗</a></div>`;
}

function highlightCode() {
  document.querySelectorAll("pre code.language-gzim").forEach((block) => {
    const escape = (value) => value.replace(/[&<>]/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;" })[char]);
    const source = block.textContent;
    const pattern = /(#[^\n]*|glow"(?:\\.|[^"\\])*"|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\b(?:for real|up in|send it|call up|throw shade|on timing|wait up|fit check|yap back|how many|same as|let|lock|be|vibecheck|otherwise|vibe|cook|yo|clique|pull up|outta|as|f_around|find_out|no_matter_what|both|either|aint)\b|\b(?:nocap|cap|ghost)\b|\b(?:yap|vibes|ranked|add up|round up)\b)/g;
    let html = "", last = 0;
    for (const match of source.matchAll(pattern)) {
      html += escape(source.slice(last, match.index));
      const raw = match[0];
      const cls = raw.startsWith("#") ? "tok-comment" : /^(?:glow)?["']/.test(raw) ? "tok-string" : /^(?:nocap|cap|ghost)$/.test(raw) ? "tok-value" : /^(?:yap|vibes|ranked|add up|round up)$/.test(raw) ? "tok-builtin" : "tok-keyword";
      html += `<span class="${cls}">${escape(raw)}</span>`;
      last = match.index + raw.length;
    }
    block.innerHTML = html + escape(source.slice(last));
  });
}

function addCopyButtons() {
  document.querySelectorAll("pre").forEach((pre) => {
    const button = document.createElement("button");
    button.className = "copy-button"; button.textContent = "Copy";
    button.addEventListener("click", async () => {
      await navigator.clipboard.writeText(pre.querySelector("code")?.textContent || pre.textContent);
      button.textContent = "Copied"; setTimeout(() => button.textContent = "Copy", 1200);
    });
    pre.appendChild(button);
  });
}

function setupToc() {
  const toc = document.getElementById("pageToc");
  if (!toc) return;
  const headings = [...document.querySelectorAll("article h2, article h3")];
  toc.innerHTML = '<div class="toc-title">On this page</div>' + headings.map((heading) => {
    if (!heading.id) heading.id = heading.textContent.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");
    return `<a href="#${heading.id}" style="padding-left:${heading.tagName === "H3" ? 10 : 0}px">${heading.textContent}</a>`;
  }).join("");
  const links = [...toc.querySelectorAll("a")];
  const observer = new IntersectionObserver((entries) => entries.forEach((entry) => {
    if (entry.isIntersecting) { links.forEach((link) => link.classList.toggle("active", link.hash === `#${entry.target.id}`)); }
  }), { rootMargin: "-15% 0px -75%" });
  headings.forEach((heading) => observer.observe(heading));
}

function setupSearch() {
  const wrapper = document.createElement("div");
  wrapper.className = "search-backdrop"; wrapper.hidden = true;
  wrapper.innerHTML = '<div class="search-dialog" role="dialog" aria-label="Search documentation"><input id="searchInput" placeholder="Search Genzimnify docs…" autocomplete="off"><div class="search-results" id="searchResults"></div></div>';
  document.body.appendChild(wrapper);
  const input = wrapper.querySelector("input"), results = wrapper.querySelector(".search-results");
  const render = () => {
    const query = input.value.trim().toLowerCase();
    const matches = DOCS.filter((item) => !query || `${item.title} ${item.section} ${item.text}`.toLowerCase().includes(query));
    results.innerHTML = matches.length ? matches.map((item, index) => `<a class="search-result ${index === 0 ? "selected" : ""}" href="${item.url}"><b>${item.title}</b><span>${item.section} · ${item.text}</span></a>`).join("") : '<div class="search-empty">No docs found. That search is cap.</div>';
  };
  const open = () => { wrapper.hidden = false; input.value = ""; render(); setTimeout(() => input.focus(), 0); };
  const close = () => { wrapper.hidden = true; };
  document.getElementById("searchBtn").addEventListener("click", open);
  wrapper.addEventListener("click", (event) => { if (event.target === wrapper) close(); });
  input.addEventListener("input", render);
  input.addEventListener("keydown", (event) => {
    if (event.key === "Escape") close();
    if (event.key === "Enter") results.querySelector("a")?.click();
  });
  addEventListener("keydown", (event) => {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k") { event.preventDefault(); wrapper.hidden ? open() : close(); }
    if (event.key === "Escape" && !wrapper.hidden) close();
  });
}

renderChrome();
document.getElementById("themeBtn").addEventListener("click", () => {
  const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
  document.documentElement.dataset.theme = next; localStorage.setItem("genzimnify.theme", next);
  document.getElementById("themeBtn").textContent = next === "dark" ? "☼" : "◐";
});
document.getElementById("menuBtn").addEventListener("click", () => document.body.classList.toggle("nav-open"));
document.addEventListener("click", (event) => { if (document.body.classList.contains("nav-open") && !event.target.closest(".sidebar, #menuBtn")) document.body.classList.remove("nav-open"); });
highlightCode(); addCopyButtons(); setupToc(); setupSearch();
