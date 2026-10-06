"""Generate submission-ready DOCX files from the PTE Prep Markdown reports.

The source DOCX files in template-doc are used as the document shell.  This
keeps their page size, cover logo, theme, heading styles, table conventions,
TOC control, and other Word package settings while replacing the generic body
with the project-specific Markdown content.
"""

from __future__ import annotations

import re
import os
import subprocess
import tempfile
from copy import deepcopy
from pathlib import Path
from typing import Iterable, Iterator, Sequence

from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[2]
TEMPLATE_DIR = ROOT / "template-doc"
REPORT_DIR = ROOT / "pte-doc" / "report"
OUTPUT_DIR = REPORT_DIR / "docx"

DATE_LINE = "— Ho Chi Minh City, October 2026 —"
GROUP_CODE = "FA26SE182"
OWNER = "Ngô Đăng Quang — Project Leader"


REPORTS = {
    "03": {
        "template": "Report3_Software Requirement Specification.docx",
        "folder": "report03",
        "title": "Software Requirement Specification",
        "major_heading": "II. Software Requirement Specification",
        "section_titles": [
            "1. Product Overview",
            "2. User Requirements",
            "3. Functional Requirements",
            "4. Non-Functional Requirements",
            "5. Requirement Appendix",
        ],
        "output": "FA26SE182_Report3_PTE-Prep_Software-Requirement-Specification.docx",
    },
    "04": {
        "template": "Report4_Software Design Document.docx",
        "folder": "report04",
        "title": "Software Design Document",
        "major_heading": "II. Software Design Document",
        "section_titles": [
            "1. System Design",
            "2. Database Design",
            "3. Detailed Design",
        ],
        "output": "FA26SE182_Report4_PTE-Prep_Software-Design-Document.docx",
    },
    "05": {
        "template": "Report5_Test Documentation.docx",
        "folder": "report05",
        "title": "Software Test Documentation",
        "major_heading": "II. Testing Documentation",
        "section_titles": [
            "1. Scope of Testing",
            "2. Test Strategy",
            "3. Test Plan",
            "4. Test Cases",
            "5. Test Reports",
        ],
        "output": "FA26SE182_Report5_PTE-Prep_Software-Test-Documentation.docx",
    },
    "06": {
        "template": "Report6_Software User Guides.docx",
        "folder": "report06",
        "title": "Software User Guides",
        "major_heading": "II. Release Package & User Guides",
        "section_titles": [
            "1. Deliverable Package",
            "2. Installation Guides",
            "3. User Manual",
        ],
        "output": "FA26SE182_Report6_PTE-Prep_Software-User-Guides.docx",
    },
}


def clear_paragraph(paragraph) -> None:
    """Remove runs/content while preserving paragraph properties."""

    for child in list(paragraph._p):
        if child.tag != qn("w:pPr"):
            paragraph._p.remove(child)


def set_cover_paragraph(paragraph, text: str, *, size: float, bold: bool = False,
                        color: str | None = None, italic: bool = False) -> None:
    clear_paragraph(paragraph)
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = paragraph.add_run(text)
    run.font.name = "Arial"
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    if color:
        run.font.color.rgb = RGBColor.from_string(color)


def set_update_fields(document: Document) -> None:
    settings = document.settings._element
    for child in list(settings):
        if child.tag == qn("w:updateFields"):
            settings.remove(child)
    update = OxmlElement("w:updateFields")
    update.set(qn("w:val"), "true")
    settings.append(update)


def remove_body_after_toc(document: Document) -> None:
    """Keep the template cover and existing TOC control, remove old content."""

    body = document.element.body
    toc = body.find(qn("w:sdt"))
    sect_pr = body.find(qn("w:sectPr"))
    if toc is None:
        # The current samples contain an SDT TOC.  If a future sample does not,
        # keep every cover paragraph and remove the old body after paragraph 20.
        children = list(body)
        for child in children[21:]:
            if child is not sect_pr:
                body.remove(child)
        return

    seen_toc = False
    for child in list(body):
        if child is toc:
            seen_toc = True
            continue
        if seen_toc and child is not sect_pr:
            body.remove(child)


def replace_toc_content(document: Document, entries: Sequence[tuple[int, str]]) -> None:
    """Replace cached template TOC text with the current project outline.

    Word's TOC content control in the supplied files contains cached entries
    from the original sample project.  Keeping those entries would show stale
    names until a manual refresh.  The control is retained for the template's
    styling, while its cached outline is replaced with the PTE Prep headings.
    The document settings still request a Word refresh when opened.
    """

    body = document.element.body
    sdt = body.find(qn("w:sdt"))
    if sdt is None:
        return
    content = sdt.find(qn("w:sdtContent"))
    if content is None:
        content = OxmlElement("w:sdtContent")
        sdt.append(content)
    for child in list(content):
        content.remove(child)

    title_para = OxmlElement("w:p")
    title_pr = OxmlElement("w:pPr")
    title_style = OxmlElement("w:pStyle")
    title_style.set(qn("w:val"), "TOCHeading")
    title_pr.append(title_style)
    title_para.append(title_pr)
    title_run = OxmlElement("w:r")
    title_run_pr = OxmlElement("w:rPr")
    title_run_pr.append(OxmlElement("w:b"))
    title_run.append(title_run_pr)
    title_text = OxmlElement("w:t")
    title_text.text = "Table of Contents"
    title_run.append(title_text)
    title_para.append(title_run)
    content.append(title_para)

    for level, text in entries:
        paragraph = OxmlElement("w:p")
        p_pr = OxmlElement("w:pPr")
        p_style = OxmlElement("w:pStyle")
        p_style.set(qn("w:val"), f"TOC{min(max(level, 1), 3)}")
        p_pr.append(p_style)
        paragraph.append(p_pr)
        run = OxmlElement("w:r")
        run_pr = OxmlElement("w:rPr")
        run.append(run_pr)
        text_node = OxmlElement("w:t")
        text_node.text = text
        run.append(text_node)
        paragraph.append(run)
        content.append(paragraph)

    note = OxmlElement("w:p")
    note_pr = OxmlElement("w:pPr")
    note_style = OxmlElement("w:pStyle")
    note_style.set(qn("w:val"), "TOC3")
    note_pr.append(note_style)
    note.append(note_pr)
    note_run = OxmlElement("w:r")
    note_run_pr = OxmlElement("w:rPr")
    color = OxmlElement("w:color")
    color.set(qn("w:val"), "666666")
    note_run_pr.append(color)
    note_run.append(note_run_pr)
    note_text = OxmlElement("w:t")
    note_text.text = "Page numbers are intentionally omitted from this generated outline so the cached page references cannot become stale."
    note_run.append(note_text)
    note.append(note_run)
    content.append(note)


def set_cell_shading(cell, fill: str) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top: int = 70, start: int = 90, bottom: int = 70,
                     end: int = 90) -> None:
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for side, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{side}"))
        if node is None:
            node = OxmlElement(f"w:{side}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_cell_width(cell, width_inches: float) -> None:
    width = int(width_inches * 1440)
    cell.width = Inches(width_inches)
    tc_pr = cell._tc.get_or_add_tcPr()
    tc_w = tc_pr.find(qn("w:tcW"))
    if tc_w is None:
        tc_w = OxmlElement("w:tcW")
        tc_pr.append(tc_w)
    tc_w.set(qn("w:w"), str(width))
    tc_w.set(qn("w:type"), "dxa")


def mark_header_row(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    if tr_pr.find(qn("w:tblHeader")) is None:
        header = OxmlElement("w:tblHeader")
        header.set(qn("w:val"), "true")
        tr_pr.append(header)


def mark_no_split(row) -> None:
    tr_pr = row._tr.get_or_add_trPr()
    if tr_pr.find(qn("w:cantSplit")) is None:
        tr_pr.append(OxmlElement("w:cantSplit"))


def markdown_cell_text(value: str) -> str:
    value = value.replace("\\|", "|")
    value = value.replace("<br>", "\n").replace("<br/>", "\n").replace("<br />", "\n")
    return value.strip()


def split_table_row(line: str) -> list[str]:
    content = line.strip()
    if content.startswith("|"):
        content = content[1:]
    if content.endswith("|"):
        content = content[:-1]
    cells: list[str] = []
    current: list[str] = []
    in_code = False
    escaped = False
    for char in content:
        if char == "`" and not escaped:
            in_code = not in_code
        if char == "|" and not in_code and not escaped:
            cells.append(markdown_cell_text("".join(current)))
            current = []
        else:
            current.append(char)
        escaped = char == "\\" and not escaped
        if char != "\\":
            escaped = False
    cells.append(markdown_cell_text("".join(current)))
    return cells


def is_table_separator(line: str) -> bool:
    cells = split_table_row(line)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell.replace(" ", "")) for cell in cells)


def clean_inline(text: str) -> str:
    text = re.sub(r"!\[([^]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"\[([^]]+)\]\([^)]*\)", r"\1", text)
    text = text.replace("\\`", "`").replace("\\|", "|")
    return text


INLINE_TOKEN = re.compile(r"(\*\*[^*]+\*\*|__[^_]+__|`[^`]+`|\*[^*]+\*|_[^_]+_)")


def add_inline_runs(paragraph, text: str, *, size: float = 9.5, color: str | None = None) -> None:
    text = clean_inline(text)
    position = 0
    for match in INLINE_TOKEN.finditer(text):
        if match.start() > position:
            run = paragraph.add_run(text[position:match.start()])
            run.font.size = Pt(size)
            if color:
                run.font.color.rgb = RGBColor.from_string(color)
        token = match.group(0)
        bold = token.startswith("**") or token.startswith("__")
        italic = token.startswith("*") and not bold or token.startswith("_") and not bold
        code = token.startswith("`")
        value = token[2:-2] if bold else token[1:-1] if italic or code else token
        run = paragraph.add_run(value)
        run.font.size = Pt(8.8 if code else size)
        if code:
            run.font.name = "Consolas"
        run.bold = bold
        run.italic = italic
        if color:
            run.font.color.rgb = RGBColor.from_string(color)
        position = match.end()
    if position < len(text):
        run = paragraph.add_run(text[position:])
        run.font.size = Pt(size)
        if color:
            run.font.color.rgb = RGBColor.from_string(color)


def add_body_paragraph(document: Document, text: str, *, style: str = "Normal",
                       italic: bool = False, small: bool = False) -> object:
    paragraph = document.add_paragraph(style=style if style in [s.name for s in document.styles] else "Normal")
    paragraph.paragraph_format.space_after = Pt(4)
    paragraph.paragraph_format.line_spacing = 1.0
    if italic:
        add_inline_runs(paragraph, text, size=8.8 if small else 9.2, color="666666")
        for run in paragraph.runs:
            run.italic = True
    else:
        add_inline_runs(paragraph, text, size=8.8 if small else 9.5)
    return paragraph


def add_list_paragraph(document: Document, text: str, *, ordered: bool = False,
                       level: int = 0) -> object:
    paragraph = document.add_paragraph(style="List Paragraph")
    p_pr = paragraph._p.get_or_add_pPr()
    num_pr = p_pr.find(qn("w:numPr"))
    if num_pr is not None:
        p_pr.remove(num_pr)
    num_pr = OxmlElement("w:numPr")
    ilvl = OxmlElement("w:ilvl")
    ilvl.set(qn("w:val"), str(min(level, 2)))
    num_id = OxmlElement("w:numId")
    # These lists are present in the sample DOCX numbering definitions.
    num_id.set(qn("w:val"), "18" if ordered else "17")
    num_pr.extend([ilvl, num_id])
    p_pr.append(num_pr)
    paragraph.paragraph_format.space_after = Pt(2)
    add_inline_runs(paragraph, text, size=9.3)
    return paragraph


def set_heading(document: Document, text: str, level: int) -> object:
    level = max(1, min(level, 5))
    paragraph = document.add_heading(text, level=level)
    paragraph.paragraph_format.keep_with_next = True
    paragraph.paragraph_format.page_break_before = False
    return paragraph


def table_weights(headers: Sequence[str], total_width: float) -> list[float]:
    weights: list[float] = []
    for header in headers:
        normalized = header.lower().strip().replace("`", "")
        if normalized in {"id", "no", "no.", "#", "stt", "type", "priority", "status"}:
            weights.append(0.75)
        else:
            weights.append(max(1.0, min(4.0, len(normalized) / 11)))
    scale = total_width / sum(weights)
    return [round(weight * scale, 3) for weight in weights]


def set_table_cell_text(cell, value: str, *, header: bool, font_size: float) -> None:
    cell.text = ""
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.TOP
    set_cell_margins(cell)
    paragraph = cell.paragraphs[0]
    if header and "Table Head" in [s.name for s in paragraph.part.document.styles]:
        paragraph.style = "Table Head"
    elif not header and "Table Text" in [s.name for s in paragraph.part.document.styles]:
        paragraph.style = "Table Text"
    paragraph.paragraph_format.space_after = Pt(0)
    paragraph.paragraph_format.line_spacing = 1.0
    if header:
        set_cell_shading(cell, "FFE8E1")
    for index, line in enumerate(value.splitlines() or [""]):
        if index:
            paragraph.add_run().add_break()
        add_inline_runs(paragraph, line, size=font_size)
    for run in paragraph.runs:
        run.bold = header or run.bold


def add_markdown_table(document: Document, rows: Sequence[Sequence[str]]) -> object:
    if not rows:
        return None
    headers = list(rows[0])
    column_count = max(len(row) for row in rows)
    headers += [""] * (column_count - len(headers))
    normalized_rows = [list(row) + [""] * (column_count - len(row)) for row in rows]
    table = document.add_table(rows=1, cols=column_count)
    table.style = "Normal Table"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    tbl_pr = table._tbl.tblPr
    layout = tbl_pr.find(qn("w:tblLayout"))
    if layout is None:
        layout = OxmlElement("w:tblLayout")
        tbl_pr.append(layout)
    layout.set(qn("w:type"), "fixed")
    width = 6.75
    widths = table_weights(headers, width)
    font_size = 7.4 if column_count >= 8 else 8.2 if column_count >= 6 else 8.8
    for index, cell in enumerate(table.rows[0].cells):
        set_cell_width(cell, widths[index])
        set_table_cell_text(cell, headers[index], header=True, font_size=font_size)
    mark_header_row(table.rows[0])
    mark_no_split(table.rows[0])
    for values in normalized_rows[1:]:
        row = table.add_row()
        mark_no_split(row)
        for index, cell in enumerate(row.cells):
            set_cell_width(cell, widths[index])
            set_table_cell_text(cell, values[index], header=False, font_size=font_size)
    document.add_paragraph().paragraph_format.space_after = Pt(1)
    return table


def render_mermaid(code: str, temporary_dir: Path, name: str) -> Path | None:
    """Render a Mermaid block to a PNG for embedding in the DOCX.

    Mermaid is an authoring format in the Markdown bundle.  The submitted
    DOCX should show the figure itself, so the CLI is used only during
    generation; the resulting PNG is embedded into the document package.
    """

    source = temporary_dir / f"{name}.mmd"
    output = temporary_dir / f"{name}.png"
    render_code = code
    # Mermaid's ER grammar treats a few SQL words as reserved entity names.
    # Keep the Markdown source unchanged but use readable aliases in the
    # rendered figure so the diagram remains visible in the submission DOCX.
    if code.lstrip().startswith("erDiagram"):
        for original, alias in (("CLASS", "PTE_CLASS"), ("ORDER", "EXAM_ORDER"), ("REPORT", "SCORE_REPORT")):
            render_code = re.sub(rf"\b{original}\b", alias, render_code)
    source.write_text(render_code.rstrip() + "\n", encoding="utf-8")
    command = [
        "npx.cmd" if os.name == "nt" else "npx",
        "--yes",
        "@mermaid-js/mermaid-cli",
        "-i",
        str(source),
        "-o",
        str(output),
        "-e",
        "png",
        "--quiet",
    ]
    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            check=False,
            capture_output=True,
            text=True,
            timeout=90,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if completed.returncode != 0 or not output.exists() or output.stat().st_size == 0:
        return None
    return output


def add_code_block(document: Document, code: str, language: str | None = None,
                   *, diagram_path: Path | None = None) -> None:
    if language == "mermaid" and diagram_path is not None:
        caption = add_body_paragraph(document, "Figure — PTE Prep process/design diagram", italic=True, small=True)
        caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
        caption.paragraph_format.space_after = Pt(2)
        paragraph = document.add_paragraph()
        paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = paragraph.add_run()
        run.add_picture(str(diagram_path), width=Inches(6.55))
        paragraph.paragraph_format.space_after = Pt(5)
        return

    caption = "Diagram source" if language == "mermaid" else "Reference block"
    caption_para = add_body_paragraph(document, caption, italic=True, small=True)
    caption_para.paragraph_format.space_after = Pt(1)
    table = document.add_table(rows=1, cols=1)
    table.style = "Normal Table"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    cell = table.cell(0, 0)
    set_cell_width(cell, 6.75)
    set_cell_shading(cell, "F4F4F4")
    set_cell_margins(cell, top=90, start=120, bottom=90, end=120)
    cell.text = ""
    paragraph = cell.paragraphs[0]
    paragraph.paragraph_format.space_after = Pt(0)
    paragraph.paragraph_format.line_spacing = 1.0
    for index, line in enumerate(code.rstrip().splitlines()):
        if index:
            paragraph.add_run().add_break()
        run = paragraph.add_run(line)
        run.font.name = "Consolas"
        run.font.size = Pt(7.2)
        run.font.color.rgb = RGBColor(55, 55, 55)
    document.add_paragraph().paragraph_format.space_after = Pt(1)


def parse_blocks(text: str) -> Iterator[tuple[str, object]]:
    lines = text.replace("\r\n", "\n").split("\n")
    index = 0
    while index < len(lines):
        line = lines[index]
        if not line.strip():
            index += 1
            continue
        if line.startswith("```"):
            language = line[3:].strip().lower() or None
            index += 1
            code: list[str] = []
            while index < len(lines) and not lines[index].startswith("```"):
                code.append(lines[index])
                index += 1
            if index < len(lines):
                index += 1
            yield "code", (language, "\n".join(code))
            continue
        heading = re.match(r"^(#{1,6})\s+(.+?)\s*$", line)
        if heading:
            yield "heading", (len(heading.group(1)), heading.group(2).strip())
            index += 1
            continue
        if line.lstrip().startswith("|") and index + 1 < len(lines) and is_table_separator(lines[index + 1]):
            rows = [split_table_row(line)]
            index += 2
            while index < len(lines) and lines[index].lstrip().startswith("|") and lines[index].rstrip().endswith("|"):
                rows.append(split_table_row(lines[index]))
                index += 1
            yield "table", rows
            continue
        list_match = re.match(r"^(\s*)([-*+]\s+|\d+[.)]\s+)(.+)$", line)
        if list_match:
            items: list[tuple[bool, int, str]] = []
            while index < len(lines):
                m = re.match(r"^(\s*)([-*+]\s+|\d+[.)]\s+)(.+)$", lines[index])
                if not m:
                    break
                level = len(m.group(1).replace("\t", "    ")) // 2
                ordered = m.group(2)[0].isdigit()
                items.append((ordered, level, m.group(3).strip()))
                index += 1
            yield "list", items
            continue
        if re.fullmatch(r"\s*(---+|\*\*\*+)\s*", line):
            yield "rule", None
            index += 1
            continue
        if line.startswith(">"):
            quote: list[str] = []
            while index < len(lines) and lines[index].startswith(">"):
                quote.append(re.sub(r"^>\s?", "", lines[index]))
                index += 1
            yield "quote", " ".join(quote)
            continue
        paragraph_lines = [line.strip()]
        index += 1
        while index < len(lines) and lines[index].strip():
            next_line = lines[index]
            if (next_line.startswith("```") or re.match(r"^#{1,6}\s+", next_line)
                    or re.match(r"^\s*[-*+]\s+", next_line)
                    or re.match(r"^\s*\d+[.)]\s+", next_line)
                    or (next_line.lstrip().startswith("|") and index + 1 < len(lines)
                        and is_table_separator(lines[index + 1]))):
                break
            paragraph_lines.append(next_line.strip())
            index += 1
        yield "paragraph", " ".join(paragraph_lines)


def add_markdown_file(document: Document, path: Path, section_title: str,
                      *, temporary_dir: Path, diagram_counter: list[int]) -> None:
    first_heading = True
    for kind, payload in parse_blocks(path.read_text(encoding="utf-8")):
        if kind == "heading":
            level, text = payload
            if level == 1 and first_heading:
                set_heading(document, section_title, 2)
                first_heading = False
                continue
            first_heading = False
            # The Markdown section files start at H1.  The Word templates put
            # those sections under the document-level H1, so shift by one.
            set_heading(document, text, min(level + 1, 5))
        elif kind == "table":
            add_markdown_table(document, payload)
        elif kind == "paragraph":
            add_body_paragraph(document, payload)
        elif kind == "quote":
            paragraph = add_body_paragraph(document, payload, italic=True)
            paragraph.paragraph_format.left_indent = Inches(0.25)
        elif kind == "list":
            for ordered, level, text in payload:
                add_list_paragraph(document, text, ordered=ordered, level=level)
        elif kind == "code":
            language, code = payload
            diagram_path = None
            if language == "mermaid":
                diagram_counter[0] += 1
                diagram_path = render_mermaid(code, temporary_dir, f"diagram-{diagram_counter[0]:03d}")
            add_code_block(document, code, language, diagram_path=diagram_path)
        elif kind == "rule":
            paragraph = document.add_paragraph()
            paragraph.paragraph_format.space_after = Pt(3)
            p_pr = paragraph._p.get_or_add_pPr()
            p_bdr = OxmlElement("w:pBdr")
            bottom = OxmlElement("w:bottom")
            bottom.set(qn("w:val"), "single")
            bottom.set(qn("w:sz"), "4")
            bottom.set(qn("w:space"), "1")
            bottom.set(qn("w:color"), "D9D9D9")
            p_bdr.append(bottom)
            p_pr.append(p_bdr)


def add_record_of_changes(document: Document, report_dir: Path) -> None:
    record_file = report_dir / "00-record-of-changes.md"
    tables = [payload for kind, payload in parse_blocks(record_file.read_text(encoding="utf-8")) if kind == "table"]
    set_heading(document, "I. Record of Changes", 1)
    if tables:
        add_markdown_table(document, tables[0])
    note = add_body_paragraph(document, "* A — Added; M — Modified; D — Deleted.", italic=True, small=True)
    note.paragraph_format.space_after = Pt(8)


def collect_toc_entries(report_dir: Path, config: dict) -> list[tuple[int, str]]:
    entries: list[tuple[int, str]] = [
        (1, "I. Record of Changes"),
        (1, config["major_heading"]),
    ]
    section_files = [
        p for p in sorted(report_dir.glob("*.md"))
        if p.name not in {"00-project-report.md", "00-record-of-changes.md"}
    ]
    for section_file, section_title in zip(section_files, config["section_titles"]):
        entries.append((2, section_title))
        for kind, payload in parse_blocks(section_file.read_text(encoding="utf-8")):
            if kind == "heading":
                level, text = payload
                if level == 2:
                    entries.append((3, text))
    return entries


def prepare_cover(document: Document, report_number: str, title: str) -> None:
    paragraphs = document.paragraphs
    # The four source templates share the same cover paragraph layout.  Keep
    # the first paragraph containing the school logo unchanged.
    if len(paragraphs) < 21:
        raise RuntimeError("The supplied DOCX template does not contain the expected cover layout")
    set_cover_paragraph(paragraphs[9], "Capstone Project Report", size=25.5, bold=True, color="C00000")
    set_cover_paragraph(paragraphs[10], f"Report {report_number} — {title}", size=20, bold=True, color="C00000")
    set_cover_paragraph(paragraphs[11], "PTE Prep", size=15, bold=True, color="1F4D78")
    set_cover_paragraph(paragraphs[12], GROUP_CODE, size=11, color="666666")
    set_cover_paragraph(paragraphs[13], "Version 1.0 · 06 October 2026", size=10, color="666666")
    date_paragraph = next((paragraph for paragraph in paragraphs if "Hanoi" in paragraph.text or "August 2019" in paragraph.text), None)
    if date_paragraph is None:
        date_paragraph = paragraphs[20]
    set_cover_paragraph(date_paragraph, DATE_LINE, size=12)


def generate_one(report_number: str, config: dict) -> Path:
    template_path = TEMPLATE_DIR / config["template"]
    report_dir = REPORT_DIR / config["folder"]
    output_path = OUTPUT_DIR / config["output"]
    document = Document(template_path)
    set_update_fields(document)
    display_report_number = report_number.lstrip("0") or "0"
    prepare_cover(document, display_report_number, config["title"])
    replace_toc_content(document, collect_toc_entries(report_dir, config))
    remove_body_after_toc(document)
    document.core_properties.title = f"PTE Prep — Report {display_report_number} — {config['title']}"
    document.core_properties.subject = "FA26SE182 Capstone Project — PTE Prep"
    document.core_properties.author = OWNER
    document.core_properties.comments = "Generated from the approved PTE Prep Markdown report bundle using the supplied DOCX template."

    # Leave the template's Table of Contents control in place; the document
    # setting above asks Word to refresh it when the file is opened.
    document.add_page_break()
    add_record_of_changes(document, report_dir)
    set_heading(document, config["major_heading"], 1)
    add_body_paragraph(
        document,
        "Product: PTE Prep · Independent organization-based PTE-style practice and mock-exam simulation platform.",
        italic=True,
        small=True,
    )
    add_body_paragraph(
        document,
        "Document baseline: Version 1.0 · Owner: Ngô Đăng Quang — Project Leader · Group: FA26SE182.",
        italic=True,
        small=True,
    )

    section_files = [p for p in sorted(report_dir.glob("*.md")) if p.name not in {"00-project-report.md", "00-record-of-changes.md"}]
    if len(section_files) != len(config["section_titles"]):
        raise RuntimeError(f"{report_dir} has {len(section_files)} section files; expected {len(config['section_titles'])}")
    with tempfile.TemporaryDirectory(prefix=f"pte-prep-report-{report_number}-") as temp:
        diagram_counter = [0]
        for section_file, section_title in zip(section_files, config["section_titles"]):
            add_markdown_file(
                document,
                section_file,
                section_title,
                temporary_dir=Path(temp),
                diagram_counter=diagram_counter,
            )

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    document.save(output_path)
    return output_path


def main() -> None:
    generated: list[Path] = []
    for report_number, config in REPORTS.items():
        generated.append(generate_one(report_number, config))
    for path in generated:
        print(path)


if __name__ == "__main__":
    main()
