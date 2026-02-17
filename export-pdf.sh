#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT="$SCRIPT_DIR/cars-comparison.md"
OUTPUT="$SCRIPT_DIR/cars-comparison.pdf"
TYPST_INTERMEDIATE="$SCRIPT_DIR/cars-comparison.typ"

if [[ ! -f "$INPUT" ]]; then
  echo "Error: $INPUT not found" >&2
  exit 1
fi

TYPST_HEADER=$(mktemp /tmp/pandoc-typst-XXXXXX.typ)
trap 'rm -f "$TYPST_HEADER" "$TYPST_INTERMEDIATE"' EXIT

cat > "$TYPST_HEADER" << 'TYPST'
#set page(flipped: true)
#show figure: set block(breakable: true)
#set table(stroke: 0.5pt)
#show table: set text(size: 7pt)
TYPST

echo "Converting $INPUT → $OUTPUT ..."

# Step 1: Generate intermediate .typ file
pandoc "$INPUT" \
  -o "$TYPST_INTERMEDIATE" \
  --pdf-engine=typst \
  -V mainfont="PT Sans" \
  -V fontsize=9pt \
  -V papersize=a4 \
  -V margin-top=0.25cm -V margin-bottom=0.25cm -V margin-left=0.25cm -V margin-right=0.25cm \
  --include-in-header="$TYPST_HEADER"

# Step 2: Patch margin to 0.25cm (pandoc -V margin-* doesn't work for typst template)
sed -i '' 's/margin: (x: [^)]*)/margin: (x: 0.25cm, y: 0.25cm)/' "$TYPST_INTERMEDIATE"

# Step 3: Patch table columns — make "Модель" (2nd column) twice as wide
sed -i '' 's/columns: ([^)]*)/columns: (auto, 2fr, 1fr, auto, auto, 1fr, auto, auto, auto, 1fr, auto, auto, auto)/' "$TYPST_INTERMEDIATE"

# Step 3: Compile to PDF
typst compile "$TYPST_INTERMEDIATE" "$OUTPUT"

echo "Done: $OUTPUT"
