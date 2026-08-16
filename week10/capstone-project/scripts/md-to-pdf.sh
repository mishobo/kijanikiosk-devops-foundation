#!/usr/bin/env bash
# Converts a Markdown file to a one-page-friendly PDF using pandoc (to HTML)
# + headless Chrome print-to-pdf, since no LaTeX engine is installed here.
# Usage: ./scripts/md-to-pdf.sh docs/scope.md "Capstone Scope Document"
set -euo pipefail

SRC="$1"
TITLE="${2:-$(basename "$SRC" .md)}"
DIR="$(cd "$(dirname "$SRC")" && pwd)"
BASE="$(basename "$SRC" .md)"
HTML="$DIR/$BASE.html"
PDF="$DIR/$BASE.pdf"
CSS="$DIR/pdf-style.css"

pandoc "$SRC" -o "$HTML" --standalone --metadata title="$TITLE" -c "$(basename "$CSS")"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu \
  --print-to-pdf="$PDF" --no-pdf-header-footer "file://$HTML" >/dev/null 2>&1
rm -f "$HTML"
echo "wrote $PDF"
