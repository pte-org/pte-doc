import os
import re
from pathlib import Path
import markdown

def compile_lang(srs_dir, output_file, lang):
    if not srs_dir.exists() or not srs_dir.is_dir():
        print(f"[!] Directory '{srs_dir}' not found in: {os.getcwd()}")
        return

    # Find and sort all .md files in the directory
    md_files = sorted(list(srs_dir.glob("*.md")))
    if not md_files:
        print(f"[!] No markdown files found in '{srs_dir}' directory.")
        return

    print(f"[*] Compiling language '{lang}' from '{srs_dir}' into '{output_file}'...")

    compiled_sections = []
    
    # Render each file as a separate <section>
    for md_file in md_files:
        content = md_file.read_text(encoding="utf-8")
        
        # Convert markdown to html using extensions
        html_content = markdown.markdown(content, extensions=['tables', 'fenced_code', 'toc'])
        
        # Extract ID from filename (e.g. "01-introduction" for "01-introduction.md")
        sec_id = md_file.stem
        
        # Wrap in a section container
        section_html = f'<section class="srs-section" id="{sec_id}">{html_content}</section>'
        compiled_sections.append(section_html)

    # Concatenate all section HTML
    all_html = "\n\n".join(compiled_sections)

    # Post-process: Rewrite relative markdown links to local anchors
    def link_replacer(match):
        filename = match.group(1)
        anchor = match.group(2)
        if anchor:
            return f'href="#{anchor}"'
        else:
            return f'href="#{filename}"'

    pattern = r'href="([a-zA-Z0-9_.-]+)\.md(?:#([a-zA-Z0-9_.-]+))?"'
    processed_html = re.sub(pattern, link_replacer, all_html)

    # Define localized strings
    if lang == "vi":
        title_text = "APTIS LMS — Đặc tả Yêu cầu Phần mềm (SRS)"
        search_placeholder = "Tìm kiếm tài liệu..."
        tab_toc = "Mục Lục"
        tab_req = "Yêu Cầu (Hub)"
        filter_all = "Tất cả"
        no_req_found = "Không tìm thấy yêu cầu nào"
        toggle_sidebar_title = "Thu nhỏ"
        toggle_theme_title = "Đổi giao diện"
        open_index_title = "Mở mục lục"
        back_to_top_title = "Về đầu trang"
        lang_switcher = '<a href="srs_view.html" class="control-btn" style="font-weight: 700; font-size: 0.8rem; text-decoration: none; padding: 0.4rem 0.6rem;" title="Switch to English">EN</a>'
    else:
        title_text = "APTIS LMS — Software Requirements Specification"
        search_placeholder = "Search documentation..."
        tab_toc = "Table of Contents"
        tab_req = "Requirements Hub"
        filter_all = "All"
        no_req_found = "No requirements found"
        toggle_sidebar_title = "Collapse"
        toggle_theme_title = "Toggle theme"
        open_index_title = "Open index"
        back_to_top_title = "Back to top"
        lang_switcher = '<a href="srs_view_vi.html" class="control-btn" style="font-weight: 700; font-size: 0.8rem; text-decoration: none; padding: 0.4rem 0.6rem;" title="Chuyển sang Tiếng Việt">VI</a>'

    # HTML Shell with modern CSS (embedded) & JS (embedded) - using raw string
    html_template = r"""<!DOCTYPE html>
<html lang="{{lang}}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>title_placeholder</title>
    
    <!-- Google Fonts: Inter & Outfit -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    
    <style>
        :root {
            --font-sans: 'Inter', system-ui, -apple-system, sans-serif;
            --font-display: 'Outfit', var(--font-sans);
            
            /* Dark Mode (Default) */
            --bg-app: #0f172a;
            --bg-sidebar: #1e293b;
            --bg-card: #1e293b;
            --bg-code: #0f172a;
            --border-color: #334155;
            --text-primary: #f8fafc;
            --text-secondary: #94a3b8;
            --text-muted: #64748b;
            
            --primary: #6366f1;       /* Indigo */
            --primary-glow: rgba(99, 102, 241, 0.15);
            --accent-cyan: #06b6d4;   /* Cyan */
            --accent-emerald: #10b981;/* Emerald */
            --accent-amber: #f59e0b;  /* Amber */
            --accent-rose: #f43f5e;   /* Rose */
            
            --sidebar-width: 340px;
            --transition-speed: 0.25s;
        }

        [data-theme="light"] {
            /* Light Mode */
            --bg-app: #f8fafc;
            --bg-sidebar: #ffffff;
            --bg-card: #ffffff;
            --bg-code: #f1f5f9;
            --border-color: #e2e8f0;
            --text-primary: #0f172a;
            --text-secondary: #475569;
            --text-muted: #94a3b8;
            
            --primary-glow: rgba(99, 102, 241, 0.08);
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: var(--bg-app);
            color: var(--text-primary);
            font-family: var(--font-sans);
            line-height: 1.65;
            display: flex;
            min-height: 100vh;
            overflow-x: hidden;
            transition: background-color var(--transition-speed), color var(--transition-speed);
        }

        /* Sidebar Styling */
        .sidebar {
            width: var(--sidebar-width);
            background-color: var(--bg-sidebar);
            border-right: 1px solid var(--border-color);
            height: 100vh;
            position: fixed;
            top: 0;
            left: 0;
            display: flex;
            flex-direction: column;
            z-index: 100;
            transition: transform var(--transition-speed), background-color var(--transition-speed), border-color var(--transition-speed);
        }

        .sidebar-header {
            padding: 1.5rem;
            border-bottom: 1px solid var(--border-color);
        }

        .sidebar-logo {
            font-family: var(--font-display);
            font-size: 1.5rem;
            font-weight: 800;
            background: linear-gradient(135deg, #818cf8 0%, #22d3ee 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 0.25rem;
        }

        .sidebar-subtitle {
            font-size: 0.75rem;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.05em;
            font-weight: 600;
        }

        .sidebar-search-box {
            padding: 1rem 1.5rem;
            border-bottom: 1px solid var(--border-color);
        }

        .search-input-wrapper {
            position: relative;
        }

        .search-input-wrapper svg {
            position: absolute;
            left: 0.75rem;
            top: 50%;
            transform: translateY(-50%);
            color: var(--text-muted);
            pointer-events: none;
        }

        .search-input {
            width: 100%;
            padding: 0.6rem 1rem 0.6rem 2.25rem;
            background-color: var(--bg-app);
            border: 1px solid var(--border-color);
            border-radius: 6px;
            color: var(--text-primary);
            font-family: var(--font-sans);
            font-size: 0.875rem;
            outline: none;
            transition: border-color var(--transition-speed);
        }

        .search-input:focus {
            border-color: var(--primary);
        }

        .sidebar-tabs {
            display: flex;
            padding: 0.75rem 1.5rem 0.25rem 1.5rem;
            gap: 0.5rem;
        }

        .tab-btn {
            flex: 1;
            padding: 0.5rem;
            background: none;
            border: none;
            border-bottom: 2px solid transparent;
            color: var(--text-muted);
            font-family: var(--font-display);
            font-weight: 600;
            font-size: 0.875rem;
            cursor: pointer;
            outline: none;
            transition: color var(--transition-speed), border-color var(--transition-speed);
            text-align: center;
        }

        .tab-btn.active {
            color: var(--primary);
            border-bottom-color: var(--primary);
        }

        .sidebar-tab-content {
            flex: 1;
            overflow-y: auto;
            padding: 1rem 1.5rem;
        }

        .tab-pane {
            display: none;
        }

        .tab-pane.active {
            display: block;
        }

        /* Table of Contents links */
        .toc-list {
            list-style: none;
        }

        .toc-item {
            margin-bottom: 0.25rem;
        }

        .toc-link {
            display: block;
            padding: 0.4rem 0.75rem;
            color: var(--text-secondary);
            text-decoration: none;
            font-size: 0.875rem;
            border-radius: 6px;
            transition: color 0.15s, background-color 0.15s;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .toc-link:hover {
            background-color: var(--primary-glow);
            color: var(--primary);
        }

        .toc-link.active {
            background-color: var(--primary);
            color: white;
            font-weight: 500;
        }

        .toc-depth-1 { padding-left: 0.75rem; font-weight: 600; }
        .toc-depth-2 { padding-left: 1.5rem; font-size: 0.825rem; }
        .toc-depth-3 { padding-left: 2.25rem; font-size: 0.775rem; display: none; } /* Hide H3s for cleaner TOC, can toggle */

        /* Requirements Hub list */
        .req-list-filters {
            display: flex;
            flex-wrap: wrap;
            gap: 0.25rem;
            margin-bottom: 1rem;
        }

        .filter-pill {
            padding: 0.2rem 0.5rem;
            font-size: 0.7rem;
            font-weight: 600;
            border-radius: 9999px;
            background-color: var(--bg-app);
            border: 1px solid var(--border-color);
            color: var(--text-secondary);
            cursor: pointer;
            transition: all 0.15s;
        }

        .filter-pill.active {
            background-color: var(--primary);
            border-color: var(--primary);
            color: white;
        }

        .sidebar-req-item {
            padding: 0.6rem 0.75rem;
            border: 1px solid var(--border-color);
            border-radius: 6px;
            margin-bottom: 0.5rem;
            cursor: pointer;
            transition: all 0.15s;
            background-color: var(--bg-app);
        }

        .sidebar-req-item:hover {
            border-color: var(--primary);
            transform: translateX(2px);
        }

        .sidebar-req-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 0.25rem;
        }

        .sidebar-req-id {
            font-family: var(--font-display);
            font-weight: 700;
            font-size: 0.8rem;
        }

        .sidebar-req-title {
            font-size: 0.75rem;
            color: var(--text-secondary);
            display: -webkit-box;
            -webkit-line-clamp: 2;
            -webkit-box-orient: vertical;
            overflow: hidden;
        }

        /* Sidebar Footer / Controls */
        .sidebar-footer {
            padding: 1rem 1.5rem;
            border-top: 1px solid var(--border-color);
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 0.5rem;
        }

        .control-btn {
            background: none;
            border: 1px solid var(--border-color);
            color: var(--text-secondary);
            padding: 0.4rem;
            border-radius: 6px;
            cursor: pointer;
            transition: all var(--transition-speed);
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .control-btn:hover {
            color: var(--text-primary);
            border-color: var(--text-secondary);
            background-color: var(--primary-glow);
        }

        /* Main Content Container */
        .main-container {
            margin-left: var(--sidebar-width);
            flex: 1;
            min-width: 0;
            transition: margin-left var(--transition-speed);
        }

        .srs-content-wrapper {
            max-width: 1000px;
            margin: 0 auto;
            padding: 4rem 3rem;
        }

        .srs-content {
            font-size: 1rem;
            color: var(--text-primary);
        }

        /* Collapsed Sidebar State */
        .sidebar-collapsed .sidebar {
            transform: translateX(-100%);
        }

        .sidebar-collapsed .main-container {
            margin-left: 0;
        }

        /* Float expand button */
        .float-expand-btn {
            position: fixed;
            bottom: 2rem;
            left: 2rem;
            z-index: 99;
            background-color: var(--primary);
            color: white;
            border: none;
            padding: 0.75rem;
            border-radius: 50%;
            cursor: pointer;
            box-shadow: 0 4px 10px rgba(0,0,0,0.3);
            display: none;
            align-items: center;
            justify-content: center;
            transition: transform 0.2s;
        }

        .float-expand-btn:hover {
            transform: scale(1.1);
        }

        .sidebar-collapsed .float-expand-btn {
            display: flex;
        }

        /* Typography Styling */
        h1, h2, h3, h4, h5, h6 {
            font-family: var(--font-display);
            font-weight: 700;
            color: var(--text-primary);
            margin-top: 2rem;
            margin-bottom: 1rem;
            line-height: 1.3;
        }

        h1 {
            font-size: 2.25rem;
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 0.5rem;
            margin-top: 3rem;
            background: linear-gradient(135deg, var(--text-primary) 0%, var(--text-secondary) 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }

        h2 {
            font-size: 1.75rem;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 0.25rem;
            margin-top: 2.5rem;
        }

        h3 {
            font-size: 1.35rem;
        }

        h4 {
            font-size: 1.15rem;
        }

        p {
            margin-bottom: 1.25rem;
            color: var(--text-secondary);
        }

        ul, ol {
            margin-bottom: 1.25rem;
            padding-left: 1.5rem;
            color: var(--text-secondary);
        }

        li {
            margin-bottom: 0.4rem;
        }

        hr {
            border: none;
            border-top: 1px solid var(--border-color);
            margin: 2.5rem 0;
        }

        a {
            color: var(--primary);
            text-decoration: none;
            transition: color 0.15s;
        }

        a:hover {
            color: var(--accent-cyan);
            text-decoration: underline;
        }

        /* Table Styling */
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 1.5rem;
            font-size: 0.9rem;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            overflow: hidden;
        }

        th, td {
            padding: 0.75rem 1rem;
            text-align: left;
            border-bottom: 1px solid var(--border-color);
        }

        th {
            background-color: var(--bg-sidebar);
            font-weight: 600;
            color: var(--text-primary);
        }

        tr:last-child td {
            border-bottom: none;
        }

        tr:nth-child(even) {
            background-color: rgba(255, 255, 255, 0.015);
        }

        [data-theme="light"] tr:nth-child(even) {
            background-color: rgba(0, 0, 0, 0.01);
        }

        tr:hover td {
            background-color: var(--primary-glow);
        }

        /* Code Blocks */
        pre {
            background-color: var(--bg-code);
            padding: 1rem;
            border-radius: 8px;
            overflow-x: auto;
            margin-bottom: 1.5rem;
            border: 1px solid var(--border-color);
            position: relative;
        }

        code {
            font-family: Consolas, Monaco, 'Andale Mono', monospace;
            font-size: 0.875rem;
        }

        p code, li code {
            background-color: var(--bg-code);
            padding: 0.15rem 0.35rem;
            border-radius: 4px;
            font-size: 0.85em;
            border: 1px solid var(--border-color);
        }

        /* Copy Code Button */
        .copy-code-btn {
            position: absolute;
            top: 0.5rem;
            right: 0.5rem;
            background-color: var(--bg-sidebar);
            border: 1px solid var(--border-color);
            color: var(--text-secondary);
            padding: 0.25rem 0.5rem;
            border-radius: 4px;
            cursor: pointer;
            font-size: 0.75rem;
            transition: all 0.15s;
        }

        .copy-code-btn:hover {
            color: var(--text-primary);
            border-color: var(--text-secondary);
        }

        /* Section dividers/metadata */
        .srs-section {
            margin-bottom: 4rem;
            scroll-margin-top: 2rem;
        }

        /* Requirement Card Decorations */
        .req-card {
            border: 1px solid var(--border-color);
            border-left: 5px solid var(--primary);
            border-radius: 8px;
            background-color: var(--bg-card);
            padding: 1.5rem;
            margin: 2rem 0;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            transition: transform 0.2s, box-shadow 0.2s, background-color var(--transition-speed), border-color var(--transition-speed);
            position: relative;
            scroll-margin-top: 2rem;
        }

        .req-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        }

        .req-card-title {
            font-family: var(--font-display);
            font-weight: 700;
            font-size: 1.2rem !important;
            margin-top: 0 !important;
            margin-bottom: 1rem !important;
            border-bottom: none !important;
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 1rem;
            flex-wrap: wrap;
        }

        .req-card-actions {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .req-badge {
            font-size: 0.7rem;
            font-weight: 700;
            padding: 0.2rem 0.5rem;
            border-radius: 9999px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            display: inline-block;
        }

        .req-badge-essential {
            background-color: rgba(16, 185, 129, 0.15);
            color: var(--accent-emerald);
        }

        .req-badge-conditional {
            background-color: rgba(245, 158, 11, 0.15);
            color: var(--accent-amber);
        }

        .req-badge-confirmed {
            background-color: rgba(16, 185, 129, 0.15);
            color: var(--accent-emerald);
        }

        .req-badge-tbd {
            background-color: rgba(244, 63, 94, 0.15);
            color: var(--accent-rose);
        }

        .req-badge-open-item {
            background-color: rgba(244, 63, 94, 0.15);
            color: var(--accent-rose);
        }

        .copy-anchor-btn {
            background: none;
            border: 1px solid var(--border-color);
            color: var(--text-secondary);
            padding: 0.25rem;
            border-radius: 4px;
            cursor: pointer;
            transition: all 0.15s;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .copy-anchor-btn:hover {
            color: var(--text-primary);
            border-color: var(--text-secondary);
            background-color: var(--primary-glow);
        }

        .copy-anchor-btn.small {
            padding: 0.15rem;
            border-radius: 3px;
        }

        /* Colors by type */
        .req-type-fr { border-left-color: var(--primary); }
        .req-type-nfr { border-left-color: var(--accent-cyan); }
        .req-type-dc { border-left-color: var(--accent-amber); }
        .req-type-br { border-left-color: var(--accent-emerald); }
        .req-type-oi { border-left-color: var(--accent-rose); }

        /* Text Linkification style */
        .req-link {
            background-color: var(--primary-glow);
            padding: 0.05rem 0.25rem;
            border-radius: 4px;
            font-weight: 600;
            border-bottom: 1px dashed var(--primary);
        }
        
        .req-link:hover {
            text-decoration: none;
            background-color: var(--primary);
            color: white !important;
        }

        /* Scroll flash animation */
        @keyframes flash-highlight {
            0% { background-color: var(--primary-glow); border-color: var(--primary); box-shadow: 0 0 15px var(--primary); }
            50% { background-color: rgba(99, 102, 241, 0.3); border-color: var(--primary); }
            100% { background-color: var(--bg-card); border-color: var(--border-color); }
        }
        .flash-target {
            animation: flash-highlight 1.5s ease-out;
        }

        /* Back to top button */
        .back-to-top-btn {
            position: fixed;
            bottom: 2rem;
            right: 2rem;
            z-index: 99;
            background-color: var(--primary);
            color: white;
            border: none;
            padding: 0.75rem;
            border-radius: 50%;
            cursor: pointer;
            box-shadow: 0 4px 10px rgba(0,0,0,0.3);
            display: none;
            align-items: center;
            justify-content: center;
            transition: transform 0.2s;
        }

        .back-to-top-btn:hover {
            transform: scale(1.1);
        }

        /* Print Media Styles */
        @media print {
            body {
                background-color: white !important;
                color: black !important;
                display: block;
            }

            .sidebar, .float-expand-btn, .back-to-top-btn, .copy-code-btn, .copy-anchor-btn, .sidebar-footer, .sidebar-search-box, .sidebar-tabs {
                display: none !important;
            }

            .main-container {
                margin-left: 0 !important;
            }

            .srs-content-wrapper {
                padding: 0 !important;
                max-width: 100% !important;
            }

            h1, h2, h3, h4 {
                color: black !important;
                page-break-after: avoid;
            }

            .req-card {
                border: 1px solid #ccc !important;
                border-left: 4px solid #333 !important;
                background-color: white !important;
                box-shadow: none !important;
                page-break-inside: avoid;
                margin: 1.5rem 0 !important;
                padding: 1.25rem !important;
            }

            tr {
                page-break-inside: avoid;
            }

            table {
                page-break-inside: auto;
            }
        }

        /* Responsive Design */
        @media (max-width: 1024px) {
            .sidebar {
                transform: translateX(-100%);
            }

            .main-container {
                margin-left: 0;
            }

            .float-expand-btn {
                display: flex;
            }

            .sidebar-expanded .sidebar {
                transform: translateX(0);
            }

            .sidebar-expanded .main-container {
                margin-left: 0;
            }
            
            .srs-content-wrapper {
                padding: 3rem 1.5rem;
            }
        }
    </style>
</head>
<body class="sidebar-collapsed">

    <!-- Floating Expand Button -->
    <button class="float-expand-btn" onclick="toggleSidebar()" title="open_index_title_placeholder">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
    </button>

    <!-- Sidebar -->
    <aside class="sidebar">
        <div class="sidebar-header">
            <div class="sidebar-logo">APTIS LMS</div>
            <div class="sidebar-subtitle">Software Requirements Specification</div>
        </div>
        
        <div class="sidebar-search-box">
            <div class="search-input-wrapper">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                <input type="text" class="search-input" id="search-bar" placeholder="search_placeholder_placeholder" oninput="handleSearch(this.value)">
            </div>
        </div>

        <div class="sidebar-tabs">
            <button class="tab-btn active" id="tab-toc" onclick="switchTab('toc')">tab_toc_placeholder</button>
            <button class="tab-btn" id="tab-req" onclick="switchTab('req')">tab_req_placeholder</button>
        </div>

        <div class="sidebar-tab-content">
            <!-- Table of Contents -->
            <div class="tab-pane active" id="pane-toc">
                <ul class="toc-list" id="toc-container">
                    <!-- TOC elements generated dynamically -->
                </ul>
            </div>

            <!-- Requirements List -->
            <div class="tab-pane" id="pane-req">
                <div class="req-list-filters">
                    <button class="filter-pill active" data-filter="all" onclick="filterReqList('all')">filter_all_placeholder</button>
                    <button class="filter-pill" data-filter="fr" onclick="filterReqList('fr')">FR</button>
                    <button class="filter-pill" data-filter="nfr" onclick="filterReqList('nfr')">NFR</button>
                    <button class="filter-pill" data-filter="dc" onclick="filterReqList('dc')">DC</button>
                    <button class="filter-pill" data-filter="br" onclick="filterReqList('br')">BR</button>
                    <button class="filter-pill" data-filter="oi" onclick="filterReqList('oi')">OI</button>
                </div>
                <div id="req-list-container">
                    <!-- Requirements items generated dynamically -->
                </div>
            </div>
        </div>

        <div class="sidebar-footer">
            <button class="control-btn" onclick="toggleTheme()" title="toggle_theme_title_placeholder">
                <!-- Sun/Moon Icon -->
                <svg id="theme-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <!-- Moon by default (dark theme default) -->
                    <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
                </svg>
            </button>
            lang_switcher_placeholder
            <button class="control-btn" onclick="toggleSidebar()" title="toggle_sidebar_title_placeholder">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
            </button>
        </div>
    </aside>

    <!-- Main Content -->
    <main class="main-container">
        <div class="srs-content-wrapper">
            <article class="srs-content">
                {{content}}
            </article>
        </div>
    </main>

    <!-- Scroll to Top Button -->
    <button class="back-to-top-btn" id="back-to-top" onclick="scrollToTop()" title="back_to_top_title_placeholder">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"></polyline></svg>
    </button>

    <script>
        // Store requirements for search/filter
        let requirementsList = [];
        let currentReqFilter = 'all';
        let currentSearchQuery = '';

        window.addEventListener('DOMContentLoaded', () => {
            // 1. Wrap raw requirements headers/text into card components
            wrapRequirements();
            
            // 2. Parse and register Business Rules from tables
            const brs = registerBusinessRules();
            
            // 3. Linkify mentions of FR-XX, NFR-XX, etc. in plain text
            linkifyRequirements();
            
            // 4. Generate the Table of Contents dynamically
            buildTOC();
            
            // 5. Gather requirements for the Requirements Hub list
            gatherRequirements(brs);
            
            // 6. Setup scrollspy & back-to-top scroll monitor
            initScrollspy();
            window.addEventListener('scroll', handleWindowScroll);
            
            // Handle URL anchor on load
            setTimeout(() => {
                if (window.location.hash) {
                    const hash = window.location.hash.substring(1);
                    highlightRequirement(hash);
                }
            }, 300);

            // Desktop default: keep sidebar open
            if (window.innerWidth > 1024) {
                document.body.classList.remove('sidebar-collapsed');
                document.body.classList.add('sidebar-expanded');
            }
        });

        // ----------------------------------------------------
        // UI Interaction Functions
        // ----------------------------------------------------
        
        function toggleSidebar() {
            if (document.body.classList.contains('sidebar-collapsed')) {
                document.body.classList.remove('sidebar-collapsed');
                document.body.classList.add('sidebar-expanded');
            } else {
                document.body.classList.remove('sidebar-expanded');
                document.body.classList.add('sidebar-collapsed');
            }
        }

        function toggleTheme() {
            const currentTheme = document.documentElement.getAttribute('data-theme');
            const icon = document.getElementById('theme-icon');
            if (currentTheme === 'light') {
                document.documentElement.removeAttribute('data-theme');
                // Set to Moon (dark mode)
                icon.innerHTML = '<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>';
            } else {
                document.documentElement.setAttribute('data-theme', 'light');
                // Set to Sun (light mode)
                icon.innerHTML = '<circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>';
            }
        }

        function switchTab(tab) {
            document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
            document.querySelectorAll('.tab-pane').forEach(pane => pane.classList.remove('active'));
            
            document.getElementById('tab-' + tab).classList.add('active');
            document.getElementById('pane-' + tab).classList.add('active');
        }

        function handleWindowScroll() {
            const btt = document.getElementById('back-to-top');
            if (window.scrollY > 300) {
                btt.style.display = 'flex';
            } else {
                btt.style.display = 'none';
            }
        }

        function scrollToTop() {
            window.scrollTo({ top: 0, behavior: 'smooth' });
        }

        function copyAnchor(id) {
            const url = window.location.origin + window.location.pathname + '#' + id;
            navigator.clipboard.writeText(url).then(() => {
                // Alert user
                const btn = document.querySelector(`.req-card[id="${id}"] .copy-anchor-btn, .br-row[id="${id}"] .copy-anchor-btn`);
                if (btn) {
                    const originalHTML = btn.innerHTML;
                    btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#10b981" stroke-width="2"><polyline points="20 6 9 17 4 12"></polyline></svg>';
                    setTimeout(() => btn.innerHTML = originalHTML, 1500);
                }
            });
        }

        // ----------------------------------------------------
        // DOM Parsing & Enhancement Functions
        // ----------------------------------------------------

        function wrapRequirements() {
            const contentArea = document.querySelector('.srs-content');
            if (!contentArea) return;
            
            const headings = Array.from(contentArea.querySelectorAll('h2, h3, h4'));
            
            headings.forEach(heading => {
                const text = heading.textContent.trim();
                let type = null;
                let id = null;
                let badge = null;
                let cleanTitle = text;
                
                if (text.startsWith('FR-')) {
                    type = 'fr';
                    const idMatch = text.match(/^(FR-\d+)/i);
                    id = idMatch ? idMatch[1].toUpperCase() : null;
                    const badgeMatch = text.match(/\[(.*?)\]/);
                    badge = badgeMatch ? badgeMatch[1] : null;
                    cleanTitle = text.replace(/\[.*?\]/, '').trim();
                }
                else if (text.startsWith('NFR-')) {
                    type = 'nfr';
                    const idMatch = text.match(/^(NFR-\d+)/i);
                    id = idMatch ? idMatch[1].toUpperCase() : null;
                    
                    if (text.toLowerCase().includes('confirmed')) {
                        badge = 'Confirmed';
                    } else if (text.toLowerCase().includes('tbd')) {
                        badge = 'TBD';
                    }
                    cleanTitle = text.replace(/—\s*\*\*Confirmed\*\*/gi, '')
                                     .replace(/—\s*Confirmed/gi, '')
                                     .replace(/—\s*\*\*TBD\*\*/gi, '')
                                     .replace(/—\s*TBD/gi, '').trim();
                }
                else if (text.startsWith('DC-')) {
                    type = 'dc';
                    const idMatch = text.match(/^(DC-\d+)/i);
                    id = idMatch ? idMatch[1].toUpperCase() : null;
                    
                    if (text.toLowerCase().includes('confirmed')) {
                        badge = 'Confirmed';
                    } else if (text.toLowerCase().includes('tbd')) {
                        badge = 'TBD';
                    }
                    cleanTitle = text.replace(/:\s*Confirmed/gi, '')
                                     .replace(/:\s*TBD/gi, '').trim();
                }
                else if (text.startsWith('OI-')) {
                    type = 'oi';
                    const idMatch = text.match(/^(OI-\d+)/i);
                    id = idMatch ? idMatch[1].toUpperCase() : null;
                    badge = 'Open Item';
                }
                
                if (type && id) {
                    const siblings = [];
                    let next = heading.nextElementSibling;
                    const stopTags = ['HR'];
                    
                    if (heading.tagName === 'H4') {
                        stopTags.push('H1', 'H2', 'H3', 'H4');
                    } else if (heading.tagName === 'H3') {
                        stopTags.push('H1', 'H2', 'H3');
                    } else if (heading.tagName === 'H2') {
                        stopTags.push('H1', 'H2');
                    }
                    
                    while (next) {
                        if (stopTags.includes(next.tagName)) {
                            break;
                        }
                        siblings.push(next);
                        next = next.nextElementSibling;
                    }
                    
                    const card = document.createElement('div');
                    card.className = `req-card req-type-${type}`;
                    card.id = id.toLowerCase();
                    card.setAttribute('data-req-id', id);
                    card.setAttribute('data-req-type', type);
                    card.setAttribute('data-req-title', cleanTitle);
                    
                    if (badge) {
                        card.setAttribute('data-req-badge', badge);
                    }
                    
                    heading.parentNode.insertBefore(card, heading);
                    card.appendChild(heading);
                    siblings.forEach(sib => card.appendChild(sib));
                    
                    // Format code blocks in card with Copy button
                    card.querySelectorAll('pre').forEach(pre => {
                        if (!pre.querySelector('.copy-code-btn')) {
                            const btn = document.createElement('button');
                            btn.className = 'copy-code-btn';
                            btn.textContent = 'Copy';
                            btn.onclick = () => {
                                const code = pre.querySelector('code');
                                navigator.clipboard.writeText(code ? code.textContent : pre.textContent);
                                btn.textContent = 'Copied!';
                                setTimeout(() => btn.textContent = 'Copy', 1500);
                            };
                            pre.appendChild(btn);
                        }
                    });
                    
                    heading.className = 'req-card-title';
                    heading.innerHTML = `
                        <span>${cleanTitle}</span>
                        <div class="req-card-actions">
                            ${badge ? `<span class="req-badge req-badge-${badge.toLowerCase().replace(/\s+/g, '-')}">${badge}</span>` : ''}
                            <button class="copy-anchor-btn" onclick="copyAnchor('${id.toLowerCase()}')" title="Copy link to this requirement">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path></svg>
                            </button>
                        </div>
                    `;
                }
            });
        }

        function registerBusinessRules() {
            const rows = document.querySelectorAll('table tr');
            const brs = [];
            
            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                if (cells.length >= 2) {
                    const firstCellText = cells[0].textContent.trim();
                    if (/^BR-\d+$/i.test(firstCellText)) {
                        const id = firstCellText.toUpperCase();
                        const desc = cells[1].textContent.trim();
                        brs.push({ id, desc, element: row });
                        
                        row.id = id.toLowerCase();
                        row.classList.add('br-row');
                        row.setAttribute('data-req-id', id);
                        row.setAttribute('data-req-type', 'br');
                        row.setAttribute('data-req-title', id + ': ' + desc);
                        
                        cells[0].innerHTML = `
                            <div style="display: flex; align-items: center; gap: 0.5rem;">
                                <strong>${id}</strong>
                                <button class="copy-anchor-btn small" onclick="copyAnchor('${id.toLowerCase()}')" title="Copy link">
                                    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path></svg>
                                </button>
                            </div>
                        `;
                    }
                }
            });
            
            return brs;
        }

        function linkifyRequirements() {
            const regex = /\b(FR|NFR|DC|BR|OI)-\d+\b/gi;
            const contentArea = document.querySelector('.srs-content');
            if (!contentArea) return;
            
            const walker = document.createTreeWalker(
                contentArea,
                NodeFilter.SHOW_TEXT,
                {
                    acceptNode: function(node) {
                        let parent = node.parentNode;
                        while (parent && parent !== contentArea) {
                            const tag = parent.tagName.toLowerCase();
                            if (tag === 'a' || tag === 'code' || tag === 'pre' || tag === 'h4' || parent.classList.contains('sidebar')) {
                                return NodeFilter.FILTER_REJECT;
                            }
                            parent = parent.parentNode;
                        }
                        return NodeFilter.FILTER_ACCEPT;
                    }
                }
            );

            const nodesToReplace = [];
            while (walker.nextNode()) {
                nodesToReplace.push(walker.currentNode);
            }

            nodesToReplace.forEach(node => {
                const text = node.nodeValue;
                const parent = node.parentNode;
                
                if (!regex.test(text)) return;
                
                const fragment = document.createDocumentFragment();
                let lastIndex = 0;
                let match;
                
                regex.lastIndex = 0;
                while ((match = regex.exec(text)) !== null) {
                    fragment.appendChild(document.createTextNode(text.substring(lastIndex, match.index)));
                    
                    const id = match[0].toUpperCase();
                    const a = document.createElement('a');
                    a.href = '#' + id.toLowerCase();
                    a.className = 'req-link';
                    a.textContent = match[0];
                    a.onclick = (e) => {
                        e.preventDefault();
                        highlightRequirement(id.toLowerCase());
                        window.history.pushState(null, null, '#' + id.toLowerCase());
                    };
                    fragment.appendChild(a);
                    
                    lastIndex = regex.lastIndex;
                }
                fragment.appendChild(document.createTextNode(text.substring(lastIndex)));
                parent.replaceChild(fragment, node);
            });
        }

        // ----------------------------------------------------
        // Dynamic Table of Contents (TOC)
        // ----------------------------------------------------

        function buildTOC() {
            const tocContainer = document.getElementById('toc-container');
            const sections = document.querySelectorAll('section.srs-section');
            if (!tocContainer || sections.length === 0) return;
            
            tocContainer.innerHTML = '';
            
            sections.forEach(section => {
                const headings = section.querySelectorAll('h1, h2, h3');
                
                headings.forEach(heading => {
                    if (heading.parentNode.classList.contains('req-card') || heading.className === 'req-card-title') {
                        return;
                    }
                    
                    if (!heading.id) {
                        heading.id = heading.textContent.trim().toLowerCase()
                            .replace(/[^a-z0-9]+/g, '-')
                            .replace(/(^-|-$)/g, '');
                    }
                    
                    const text = heading.textContent.replace('¶', '').trim();
                    const depth = heading.tagName === 'H1' ? 1 : (heading.tagName === 'H2' ? 2 : 3);
                    
                    const li = document.createElement('li');
                    li.className = `toc-item toc-depth-${depth}`;
                    
                    const a = document.createElement('a');
                    a.href = `#${heading.id}`;
                    a.className = 'toc-link';
                    a.textContent = text;
                    a.title = text;
                    a.onclick = (e) => {
                        if (window.innerWidth <= 1024) {
                            document.body.classList.remove('sidebar-expanded');
                            document.body.classList.add('sidebar-collapsed');
                        }
                    };
                    
                    li.appendChild(a);
                    tocContainer.appendChild(li);
                });
            });
        }

        function initScrollspy() {
            const sections = document.querySelectorAll('section.srs-section, .req-card, .br-row');
            const navLinks = document.querySelectorAll('.toc-link');
            
            const observerOptions = {
                root: null,
                rootMargin: '-10% 0px -80% 0px',
                threshold: 0
            };
            
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const id = entry.target.id;
                        navLinks.forEach(link => {
                            if (link.getAttribute('href') === `#${id}`) {
                                link.classList.add('active');
                                link.scrollIntoView({ behavior: 'auto', block: 'nearest' });
                            } else {
                                link.classList.remove('active');
                            }
                        });
                    }
                });
            }, observerOptions);
            
            sections.forEach(section => observer.observe(section));
        }

        function highlightRequirement(id) {
            const el = document.getElementById(id);
            if (el) {
                el.scrollIntoView({ behavior: 'smooth', block: 'center' });
                el.classList.remove('flash-target');
                void el.offsetWidth; // Force reflow
                el.classList.add('flash-target');
            }
        }

        // ----------------------------------------------------
        // Requirements Hub (Tab 2)
        // ----------------------------------------------------

        function gatherRequirements(brs) {
            requirementsList = [];
            
            document.querySelectorAll('.req-card').forEach(card => {
                requirementsList.push({
                    id: card.getAttribute('data-req-id'),
                    type: card.getAttribute('data-req-type'),
                    title: card.getAttribute('data-req-title'),
                    badge: card.getAttribute('data-req-badge') || '',
                    element: card
                });
            });
            
            brs.forEach(br => {
                requirementsList.push({
                    id: br.id,
                    type: 'br',
                    title: br.desc,
                    badge: '',
                    element: br.element
                });
            });
            
            renderRequirementsList();
        }

        function renderRequirementsList() {
            const container = document.getElementById('req-list-container');
            if (!container) return;
            
            container.innerHTML = '';
            
            const filtered = requirementsList.filter(req => {
                const matchesType = currentReqFilter === 'all' || req.type === currentReqFilter;
                const matchesSearch = currentSearchQuery === '' || 
                                      req.id.toLowerCase().includes(currentSearchQuery) || 
                                      req.title.toLowerCase().includes(currentSearchQuery);
                return matchesType && matchesSearch;
            });
            
            if (filtered.length === 0) {
                container.innerHTML = `<div style="font-size:0.8rem;color:var(--text-muted);text-align:center;padding:2rem;">no_req_found_placeholder</div>`;
                return;
            }
            
            filtered.forEach(req => {
                const div = document.createElement('div');
                div.className = 'sidebar-req-item';
                div.onclick = () => {
                    highlightRequirement(req.id.toLowerCase());
                    window.history.pushState(null, null, '#' + req.id.toLowerCase());
                    if (window.innerWidth <= 1024) {
                        document.body.classList.remove('sidebar-expanded');
                        document.body.classList.add('sidebar-collapsed');
                    }
                };
                
                div.innerHTML = `
                    <div class="sidebar-req-header">
                        <span class="sidebar-req-id" style="color:var(--accent-${getThemeColorName(req.type)})">${req.id}</span>
                        ${req.badge ? `<span class="req-badge req-badge-${req.badge.toLowerCase().replace(/\s+/g, '-')}">${req.badge}</span>` : ''}
                    </div>
                    <div class="sidebar-req-title">${req.title}</div>
                `;
                container.appendChild(div);
            });
        }

        function getThemeColorName(type) {
            switch(type) {
                case 'fr': return 'indigo';
                case 'nfr': return 'cyan';
                case 'br': return 'emerald';
                case 'dc': return 'amber';
                case 'oi': return 'rose';
                default: return 'primary';
            }
        }

        function filterReqList(filter) {
            currentReqFilter = filter;
            document.querySelectorAll('.filter-pill').forEach(pill => {
                if (pill.getAttribute('data-filter') === filter) {
                    pill.classList.add('active');
                } else {
                    pill.classList.remove('active');
                }
            });
            renderRequirementsList();
        }

        // ----------------------------------------------------
        // Search & Filtering
        // ----------------------------------------------------

        function handleSearch(query) {
            currentSearchQuery = query.toLowerCase().trim();
            
            renderRequirementsList();
            
            const tocLinks = document.querySelectorAll('.toc-link');
            tocLinks.forEach(link => {
                const text = link.textContent.toLowerCase();
                const matches = currentSearchQuery === '' || text.includes(currentSearchQuery);
                link.parentNode.style.display = matches ? 'block' : 'none';
            });
            
            const h3items = document.querySelectorAll('.toc-depth-3');
            h3items.forEach(item => {
                item.style.display = currentSearchQuery !== '' ? 'block' : 'none';
            });
        }
    </script>
</body>
</html>
"""

    # Do substitution
    final_html = html_template \
        .replace("{{lang}}", lang) \
        .replace("title_placeholder", title_text) \
        .replace("search_placeholder_placeholder", search_placeholder) \
        .replace("tab_toc_placeholder", tab_toc) \
        .replace("tab_req_placeholder", tab_req) \
        .replace("filter_all_placeholder", filter_all) \
        .replace("no_req_found_placeholder", no_req_found) \
        .replace("toggle_sidebar_title_placeholder", toggle_sidebar_title) \
        .replace("toggle_theme_title_placeholder", toggle_theme_title) \
        .replace("open_index_title_placeholder", open_index_title) \
        .replace("back_to_top_title_placeholder", back_to_top_title) \
        .replace("lang_switcher_placeholder", lang_switcher) \
        .replace("{{content}}", processed_html)

    # Save output file
    output_file.write_text(final_html, encoding="utf-8")
    print(f"[+] Successfully compiled SRS into: {output_file.absolute()}")


def main():
    # Compile EN
    compile_lang(Path("srs"), Path("srs_view.html"), "en")
    
    # Compile VI
    compile_lang(Path("srs-vi"), Path("srs_view_vi.html"), "vi")

if __name__ == "__main__":
    main()
