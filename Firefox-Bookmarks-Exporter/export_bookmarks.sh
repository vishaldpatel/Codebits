#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

# 1. Locate Firefox profile directory containing "default"
FIREFOX_BASE="$HOME/.mozilla/firefox"

if [ ! -d "$FIREFOX_BASE" ]; then
    echo "Error: Firefox directory not found at $FIREFOX_BASE" >&2
    exit 1
fi

# Find the first directory matching *default*
PROFILE_DIR=$(find "$FIREFOX_BASE" -mindepth 1 -maxdepth 1 -type d -name "*default-release*" | head -n 1)

if [ -z "$PROFILE_DIR" ]; then
    echo "Error: No Firefox profile containing 'default' found." >&2
    exit 1
fi

PLACES_DB="$PROFILE_DIR/places.sqlite"

if [ ! -f "$PLACES_DB" ]; then
    echo "Error: places.sqlite not found in profile: $PROFILE_DIR" >&2
    exit 1
fi

# 2. Copy places.sqlite to ~/Downloads
# DOWNLOADS_DIR="$HOME/Downloads"
DOWNLOADS_DIR="/tmp"
mkdir -p "$DOWNLOADS_DIR"

DEST_DB="$DOWNLOADS_DIR/places_backup.sqlite"
cp "$PLACES_DB" "$DEST_DB"
echo "Successfully copied places.sqlite to: $DEST_DB"

# 3. Parse SQLite and generate styled HTML using Python
OUTPUT_HTML="$DOWNLOADS_DIR/bookmarks.html"

python3 - "$DEST_DB" "$OUTPUT_HTML" << 'EOF'
import sys
import sqlite3
import html
from collections import defaultdict

db_path = sys.argv[1]
output_html_path = sys.argv[2]

# Connect to the copied SQLite database in read-only mode
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Query to fetch both folders (type 2) and bookmarks (type 1) with their parent references
query = """
    SELECT m.id, m.parent, m.type, m.title, p.url 
    FROM moz_bookmarks m
    LEFT JOIN moz_places p ON m.fk = p.id
    WHERE m.type IN (1, 2)
    ORDER BY m.parent, m.position;
"""

try:
    cursor.execute(query)
    rows = cursor.fetchall()
except Exception as e:
    print(f"Database query failed: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    conn.close()

# Organize items by parent ID
# Structure: children[parent_id] = [list of items]
children = defaultdict(list)
items_map = {}

for item_id, parent, item_type, title, url in rows:
    node = {
        "id": item_id,
        "parent": parent,
        "type": item_type, # 1 = bookmark, 2 = folder
        "title": title or "Untitled",
        "url": url or ""
    }
    items_map[item_id] = node
    children[parent].append(node)

# Find root containers (usually toolbar=3, menu=2, unfiled=5, but we trace from known main roots or parent 1)
# Firefox root IDs change, so we dynamically render starting from main top-level nodes (parents that are roots or point to root 1/specials)
# Standard roots: toolbar, menu, unfiled
root_parent_ids = [row[0] for row in rows if row[1] == 1] # Children of root node (id 1)

def build_tree_html(parent_id):
    html_out = ""
    node_list = children.get(parent_id, [])
    
    for node in node_list:
        if node["type"] == 2:  # Folder
            folder_title = html.escape(node["title"])
            # Skip internal/empty system tags root folders if unwanted, or render them
            html_out += f'<li class="folder-item">\n'
            html_out += f'  <details>\n'
            html_out += f'    <summary class="folder-title">📁 {folder_title}</summary>\n'
            html_out += f'    <ul class="sub-list">\n'
            html_out += build_tree_html(node["id"])
            html_out += f'    </ul>\n'
            html_out += f'  </details>\n'
            html_out += f'</li>\n'
            
        elif node["type"] == 1:  # Bookmark
            if not node["url"]:
                continue
            bm_title = html.escape(node["title"])
            bm_url = html.escape(node["url"])
            html_out += f'<li class="bookmark-item">\n'
            html_out += f'  <a class="bookmark-link" href="{bm_url}" target="_blank" rel="noopener noreferrer">🔗 {bm_title}</a>\n'
            html_out += f'  <div class="bookmark-url">{bm_url}</div>\n'
            html_out += f'</li>\n'
            
    return html_out

# Generate tree structure starting from root level references
tree_html = ""
for root_id in root_parent_ids:
    root_node = items_map.get(root_id)
    if root_node:
        tree_html += build_tree_html(root_id)

# Fallback if root layout differs: grab items whose parent isn't mapped to a visible folder
if not tree_html:
    for node_id, node in items_map.items():
        if node["parent"] not in items_map and node["type"] == 1:
            bm_title = html.escape(node["title"])
            bm_url = html.escape(node["url"])
            tree_html += f'<li class="bookmark-item"><a class="bookmark-link" href="{bm_url}" target="_blank">{bm_title}</a></li>\n'

# Complete HTML page wrapper with Dark Theme & tree CSS styling
full_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Firefox Bookmarks Hierarchy</title>
    <style>
        :root {{
            --bg-color: #121212;
            --card-bg: #1e1e1e;
            --text-main: #e0e0e0;
            --text-muted: #9ca3af;
            --accent-color: #AAA999;
            --accent-hover: #60a5fa;
            --border-color: #2a2a2a;
            --folder-color: #fbbf24;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-main);
            margin: 0;
            padding: 40px 20px;
        }}
        .container {{
            max-width: 900px;
            margin: 0 auto;
        }}
        h1 {{
            font-size: 2rem;
            margin-bottom: 8px;
            color: #ffffff;
        }}
        .subtitle {{
            color: var(--text-muted);
            margin-bottom: 30px;
            font-size: 0.95rem;
        }}
        ul {{
            list-style: none;
            padding-left: 0;
            margin: 0;
        }}
        .sub-list {{
            padding-left: 20px;
            margin-top: 8px;
            display: flex;
            flex-direction: column;
            gap: 8px;
            border-left: 1px dashed var(--border-color);
        }}
        details {{
            background-color: var(--card-bg);
            border: 1px solid var--border-color;
            border-radius: 8px;
            padding: 10px 14px;
            margin-bottom: 8px;
        }}
        summary.folder-title {{
            font-weight: 600;
            color: var(--folder-color);
            cursor: pointer;
            font-size: 1.05rem;
            user-select: none;
        }}
        summary.folder-title:hover {{
            color: #fde047;
        }}
        .bookmark-item {{
            background-color: var(--card-bg);
            border: 1px solid var--border-color;
            border-radius: 6px;
            padding: 12px 14px;
            transition: border-color 0.2s ease, transform 0.2s ease;
        }}
        .bookmark-item:hover {{
            border-color: var(--accent-color);
            transform: translateX(4px);
        }}
        .bookmark-link {{
            text-decoration: none;
            color: var(--accent-color);
            font-size: 1rem;
            font-weight: 500;
            display: block;
            margin-bottom: 3px;
            word-break: break-all;
        }}
        .bookmark-link:hover {{
            color: var(--accent-hover);
            text-decoration: underline;
        }}
        .bookmark-url {{
            font-size: 0.8rem;
            color: var(--text-muted);
            word-break: break-all;
        }}
    </style>
</head>
<body>
    <div class="container">
        <ul class="main-tree">
            {tree_html}
        </ul>
    </div>
</body>
</html>
"""

with open(output_html_path, "w", encoding="utf-8") as f:
    f.write(full_html)

print(f"Successfully generated structured hierarchy HTML: {output_html_path}")
EOF

echo "All Done. Check /tmp"
