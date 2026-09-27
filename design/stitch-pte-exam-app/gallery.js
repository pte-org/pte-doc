"use strict";

const manifest = window.STITCH_EXPORT;
const grid = document.getElementById("screens");
const resultCount = document.getElementById("result-count");
const cards = [];

function link(label, path) {
  const anchor = document.createElement("a");
  anchor.textContent = label;
  anchor.href = path;
  anchor.target = "_blank";
  anchor.rel = "noreferrer";
  return anchor;
}

document.getElementById("summary").textContent =
  `${manifest.imageCount} màn hình PNG đầy đủ · ${manifest.htmlCount} file HTML · ` +
  `${manifest.hiddenScreenCount} tài liệu bổ sung từ các mục ẩn trong Stitch`;

for (const screen of manifest.screens) {
  const card = document.createElement("article");
  if (screen.screenshot) {
    const preview = link("", screen.screenshot);
    preview.className = "preview";
    preview.setAttribute("aria-label", `Mở ảnh gốc: ${screen.title}`);
    const image = document.createElement("img");
    image.src = screen.screenshot;
    image.alt = screen.title;
    image.loading = "lazy";
    preview.append(image);
    card.append(preview);
  }

  const title = document.createElement("h2");
  title.textContent = `${String(screen.order).padStart(2, "0")}. ${screen.title}`;
  const meta = document.createElement("p");
  meta.className = "meta";
  meta.textContent = screen.screenshot
    ? `${screen.width} × ${screen.height} px · ID: ${screen.id.slice(0, 8)}`
    : `Tài liệu ẩn · ${screen.sourceMimeType} · ID: ${screen.id.slice(0, 8)}`;

  const links = document.createElement("div");
  links.className = "links";
  if (screen.screenshot) links.append(link("PNG gốc", screen.screenshot));
  if (screen.sourceCode) links.append(link(screen.html ? "HTML Stitch" : "Mở tài liệu", screen.sourceCode));
  links.append(link("Metadata", screen.metadata));
  card.append(title, meta, links);
  grid.append(card);
  cards.push({ card, title: screen.title.toLocaleLowerCase() });
}

function filter() {
  const query = document.getElementById("search").value.trim().toLocaleLowerCase();
  let visible = 0;
  for (const entry of cards) {
    entry.card.hidden = !entry.title.includes(query);
    if (!entry.card.hidden) visible++;
  }
  resultCount.textContent = `Hiển thị ${visible}/${cards.length} mục`;
}

document.getElementById("search").addEventListener("input", filter);
filter();
