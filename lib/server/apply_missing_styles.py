#!/usr/bin/env python3
import re
import sys
import shutil
from pathlib import Path
from collections import OrderedDict

# Target styles (from the "second" HTML file)
GLOBAL_HTML_RULE_PROPS = OrderedDict([
    ("scroll-behavior", "smooth"),
    ("scroll-padding-top", "80px"),
])

MEDIA_QUERY_HEADER = "@media (max-width:900px)"
REQUIRED_MEDIA_RULES = OrderedDict([
    (".nav", OrderedDict([
        ("flex-direction", "column"),
        ("align-items", "center"),
        ("gap", "6px"),
        ("padding", "10px 0"),
    ])),
    (".brand", OrderedDict([
        ("font-size", "16px"),
        ("white-space", "nowrap"),
    ])),
    (".nav-links", OrderedDict([
        ("font-size", "13px"),
        ("white-space", "nowrap"),
    ])),
    (".nav-links a", OrderedDict([
        ("margin", "0 4px"),
    ])),
    (".hero-card", OrderedDict([
        ("grid-template-columns", "1fr"),
    ])),
    (".grid", OrderedDict([
        ("grid-template-columns", "1fr"),
    ])),
    ("body", OrderedDict([
        ("padding-top", "85px"),
    ])),
    ("html", OrderedDict([
        ("scroll-padding-top", "95px"),
    ])),
])

# Regex helpers
STYLE_BLOCK_RE = re.compile(r"(?is)<style[^>]*>(.*?)</style>")
MEDIA_BLOCK_RE = re.compile(r"(?is)@media\s*\(\s*max-width\s*:\s*900px\s*\)\s*\{(.*?)\}")
CSS_RULE_RE = re.compile(r"(?s)([^{}]+)\{([^{}]+)\}")
DECL_RE = re.compile(r"(?s)\s*([-\w]+)\s*:\s*([^;]+?)\s*;")

def parse_css_rules(css_text: str):
    """
    Returns list of (selector, OrderedDict(props)).
    Keeps last occurrence of a property for a selector.
    """
    rules = []
    for m in CSS_RULE_RE.finditer(css_text):
        selector = m.group(1).strip()
        body = m.group(2).strip()
        props = OrderedDict()
        if body:
            body_norm = body if body.endswith(";") else body + ";"
            for dm in DECL_RE.finditer(body_norm):
                k = dm.group(1).strip()
                v = dm.group(2).strip()
                props[k] = v
        rules.append((selector, props))
    return rules

def serialize_css_rules(rules):
    out = []
    for selector, props in rules:
        if not props:
            continue
        decls = ";".join([f"{k}:{v}" for k, v in props.items()]) + ";"
        out.append(f"{selector}{{{decls}}}")
    return "\n".join(out) + ("\n" if out else "")

def merge_rule_props(base_props: OrderedDict, add_props: OrderedDict) -> (OrderedDict, bool):
    changed = False
    for k, v in add_props.items():
        if base_props.get(k) != v:
            base_props[k] = v
            changed = True
    return base_props, changed

def ensure_global_html_rule_in_css(css_text: str, media_spans: list) -> (str, bool):
    """
    Merge/overwrite top-level html rule (outside any media block).
    """
    def outside_media(pos):
        for s, e in media_spans:
            if s <= pos < e:
                return False
        return True

    changed = False
    matches = list(CSS_RULE_RE.finditer(css_text))
    html_match = None
    for m in matches:
        if not outside_media(m.start()):
            continue
        selector = m.group(1).strip()
        if selector == "html":
            html_match = m
            break

    if html_match:
        body = html_match.group(2).strip()
        props = OrderedDict()
        body_norm = body if body.endswith(";") else (body + ";") if body else ""
        for dm in DECL_RE.finditer(body_norm):
            props[dm.group(1).strip()] = dm.group(2).strip()
        new_props, ch = merge_rule_props(props, GLOBAL_HTML_RULE_PROPS)
        if ch:
            new_body = ";".join([f"{k}:{v}" for k, v in new_props.items()]) + ";"
            new_rule = f"html{{{new_body}}}"
            start, end = html_match.span()
            css_text = css_text[:start] + new_rule + css_text[end:]
            changed = True
    else:
        # Insert a fresh rule near top (after :root or * if present)
        insertion_point = 0
        m = re.search(r"(?is)(:root\s*\{.*?\}\s*)", css_text)
        if m and outside_media(m.start()):
            insertion_point = m.end()
        else:
            m = re.search(r"(?is)(\*\s*\{.*?\}\s*)", css_text)
            if m and outside_media(m.start()):
                insertion_point = m.end()
        new_rule = "html{scroll-behavior:smooth;scroll-padding-top:80px;}\n"
        css_text = css_text[:insertion_point] + ("\n" if insertion_point else "") + new_rule + css_text[insertion_point:]
        changed = True

    return css_text, changed

def merge_media_inner(existing_inner: str, required_rules: OrderedDict) -> (str, bool):
    """
    Merge REQUIRED_MEDIA_RULES into existing media inner CSS by replacing conflicting
    declarations and adding missing ones.
    """
    changed = False
    rules = parse_css_rules(existing_inner)
    index = {sel: (i, props) for i, (sel, props) in enumerate(rules)}

    for req_sel, req_props in required_rules.items():
        if req_sel in index:
            i, props = index[req_sel]
            merged_props, ch = merge_rule_props(props, req_props)
            if ch:
                rules[i] = (req_sel, merged_props)
                changed = True
        else:
            rules.append((req_sel, req_props.copy()))
            changed = True

    if not changed:
        return existing_inner, False

    return serialize_css_rules(rules), True

def collect_media_blocks(css_text: str):
    """
    Return list of tuples: (full_block_text, inner_text, span)
    """
    blocks = []
    for m in MEDIA_BLOCK_RE.finditer(css_text):
        blocks.append((m.group(0), m.group(1), m.span()))
    return blocks

def consolidate_media_blocks(css_text: str) -> (str, bool):
    """
    Consolidate all @media (max-width:900px) blocks into the first one by merging their rules
    and ensuring REQUIRED_MEDIA_RULES are satisfied. Remove duplicates.
    """
    changed = False
    blocks = collect_media_blocks(css_text)
    if not blocks:
        # Create a new media block at the end
        new_inner = serialize_css_rules(list(REQUIRED_MEDIA_RULES.items()))
        new_block = f"{MEDIA_QUERY_HEADER}{{\n{new_inner}}}\n"
        suffix = "" if css_text.strip().endswith("\n") else "\n"
        return css_text + suffix + new_block, True

    # Merge all existing blocks’ inner CSS
    merged_inner = ""
    for i, (full, inner, span) in enumerate(blocks):
        if i == 0:
            merged_inner = inner
        else:
            # Merge the rest into the first
            merged_inner, _ = merge_media_inner(merged_inner, OrderedDict(parse_css_rules(inner)))

    # Ensure REQUIRED_MEDIA_RULES are present/overwritten
    merged_inner, req_changed = merge_media_inner(merged_inner, REQUIRED_MEDIA_RULES)
    if req_changed:
        changed = True

    # Rebuild CSS: keep first block with merged inner; remove others
    first_full, first_inner, first_span = blocks[0]
    new_first_full = f"{MEDIA_QUERY_HEADER}{{\n{merged_inner}}}"
    s0, e0 = first_span

    # Remove subsequent blocks by slicing
    parts = []
    last_idx = 0
    for i, (full, inner, span) in enumerate(blocks):
        s, e = span
        if i == 0:
            # Insert merged first block
            parts.append(css_text[last_idx:s])
            parts.append(new_first_full)
            last_idx = e
        else:
            # Skip other blocks
            parts.append(css_text[last_idx:s])
            last_idx = e
            changed = True
    parts.append(css_text[last_idx:])
    return "".join(parts), changed

def patch_one_style_block(style_css: str) -> (str, bool):
    """
    Patch a single <style> block content by:
      - consolidating media blocks for max-width:900px
      - ensuring global html rule (outside media) is merged/inserted
    """
    original = style_css

    # Collect media spans first to help identify top-level rules
    media_spans = [span for _, _, span in collect_media_blocks(style_css)]

    # Ensure the global html rule exists/merged (outside media)
    style_css, ch1 = ensure_global_html_rule_in_css(style_css, media_spans)

    # Consolidate and merge media blocks
    style_css2, ch2 = consolidate_media_blocks(style_css)

    return style_css2, (ch1 or ch2) and (style_css2 != original)

def process_html_file(path: Path, make_backup: bool = True) -> bool:
    html = path.read_text(encoding="utf-8", errors="ignore")

    # Find all style blocks
    blocks = list(STYLE_BLOCK_RE.finditer(html))
    if not blocks:
        # No <style> blocks: inject one before </head>
        global_html = "html{scroll-behavior:smooth;scroll-padding-top:80px;}\n"
        media_inner = serialize_css_rules(list(REQUIRED_MEDIA_RULES.items()))
        media_block = f"{MEDIA_QUERY_HEADER}{{\n{media_inner}}}\n"
        new_style = "<style>\n" + global_html + "\n" + media_block + "</style>\n"
        lhtml = html.lower()
        if "</head>" in lhtml:
            idx = lhtml.rfind("</head>")
            new_html = html[:idx] + new_style + html[idx:]
        else:
            new_html = new_style + html
        if make_backup:
            shutil.copy2(path, path.with_suffix(path.suffix + ".bak"))
        path.write_text(new_html, encoding="utf-8")
        return True

    # Patch each style block and also consolidate media across them by performing
    # two passes: first patch independently, then a final global consolidation pass
    # across the combined CSS text is handled indirectly by patching block-wise,
    # then joining unchanged parts. To truly consolidate across blocks, we merge
    # media inside each block and rely on removal of duplicates per block.

    changed_any = False
    new_html_parts = []
    last_idx = 0

    for m in blocks:
        s, e = m.span(1)  # inner content span
        style_inner = m.group(1)
        patched_inner, changed = patch_one_style_block(style_inner)
        new_html_parts.append(html[last_idx:s])
        new_html_parts.append(patched_inner)
        last_idx = e
        if changed:
            changed_any = True

    new_html_parts.append(html[last_idx:])
    new_html = "".join(new_html_parts)

    # Second pass: If multiple style blocks still contain @media (max-width:900px),
    # consolidate by pulling them into the first style block. This is optional,
    # but we’ll do a simple whole-document consolidation here.

    # Extract all style inners again
    blocks2 = list(STYLE_BLOCK_RE.finditer(new_html))
    if len(blocks2) > 1:
        # Build a combined CSS text to detect multiple media blocks at document level
        # and then push a single consolidated media block into the first style block.
        all_css = [b.group(1) for b in blocks2]
        combined = "\n\n".join(all_css)
        combined_consolidated, consolidated_changed = consolidate_media_blocks(combined)
        if consolidated_changed:
            changed_any = True
            # Put consolidated combined back: place into first block, keep others without media duplicates
            # We will simply replace first block inner with the consolidated css and set others to their
            # non-media content (remove media blocks entirely from subsequent ones).
            # Remove media from all but keep their non-media rules.

            def remove_media_from_css(css):
                blocks = collect_media_blocks(css)
                if not blocks:
                    return css
                parts = []
                last = 0
                for full, inner, span in blocks:
                    s, e = span
                    parts.append(css[last:s])
                    last = e
                parts.append(css[last:])
                return "".join(parts)

            non_media_css = [remove_media_from_css(x) for x in all_css]
            # First block gets the full consolidated (includes media + non-media that already exists there if needed).
            # To avoid duplicating non-media rules, we’ll combine: first’s non-media + consolidated media.
            # Extract first’s media-less and then append the media from consolidated.
            first_non_media = non_media_css[0]
            # Extract only the consolidated media block from combined_consolidated
            # and keep everything else (non-media) as in first_non_media.
            # The consolidate_media_blocks ensured there is exactly one target media block.
            media_blocks = collect_media_blocks(combined_consolidated)
            if media_blocks:
                consolidated_media_full, consolidated_media_inner, _ = media_blocks[0]
                # Remove media from combined to get combined non-media (we’ll ignore and keep first’s non-media)
                new_first_inner = first_non_media.strip()
                if new_first_inner and not new_first_inner.endswith("\n"):
                    new_first_inner += "\n"
                new_first_inner += consolidated_media_full + "\n"
            else:
                new_first_inner = first_non_media  # no media found (unlikely)

            # Now rebuild document’s style blocks:
            rebuilt = []
            last_pos = 0
            for i, b in enumerate(blocks2):
                start, end = b.span(1)
                rebuilt.append(new_html[last_pos:start])
                if i == 0:
                    rebuilt.append(new_first_inner)
                else:
                    rebuilt.append(non_media_css[i])
                last_pos = end
            rebuilt.append(new_html[last_pos:])
            new_html = "".join(rebuilt)

    if changed_any:
        shutil.copy2(path, path.with_suffix(path.suffix + ".bak"))
        path.write_text(new_html, encoding="utf-8")
    return changed_any

def main():
    if len(sys.argv) < 2:
        print("Usage: python apply_missing_styles.py /path/to/folder")
        sys.exit(1)
    root = Path(sys.argv[1]).expanduser().resolve()
    if not root.exists():
        print(f"Folder not found: {root}")
        sys.exit(1)

    scanned = 0
    updated = 0
    for p in root.rglob("*"):
        if p.suffix.lower() in {".html", ".htm"} and p.is_file():
            scanned += 1
            try:
                if process_html_file(p):
                    updated += 1
                    print(f"Updated: {p}")
                else:
                    print(f"No change: {p}")
            except Exception as e:
                print(f"Error processing {p}: {e}")

    print(f"\nScanned {scanned} HTML files. Updated {updated} file(s). Backups with .bak extension were created for modified files.")

if __name__ == "__main__":
    main()