#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ocr_pdf.sh <pdf_path> <lang>

Runs OCR on a scanned PDF and produces <stem>_text.txt next to it.

Arguments:
  pdf_path   Path to the PDF (may contain spaces).
  lang       Tesseract language code: deu, eng, rus, fra, spa, ...
             Combine with '+', e.g. 'deu+eng'.

Output:
  <dir>/<stem>_text.txt with per-page sections separated by
  '========== SEITE/PAGE N =========='.

Requires: pdftoppm (poppler), tesseract with the requested language pack.
EOF
}

if [[ $# -ne 2 ]]; then
    usage
    exit 1
fi

pdf_path="$1"
lang="$2"

if [[ ! -f "$pdf_path" ]]; then
    echo "Error: file not found: $pdf_path" >&2
    exit 1
fi

for tool in pdftoppm tesseract; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: '$tool' not found in PATH. Install with: brew install poppler tesseract tesseract-lang" >&2
        exit 1
    fi
done

dir="$(cd "$(dirname "$pdf_path")" && pwd)"
base="$(basename "$pdf_path")"
stem="${base%.[pP][dD][fF]}"

out_file="$dir/${stem}_text.txt"
tmp_dir="$dir/.ocr_tmp_$$"

cleanup() {
    rm -rf "$tmp_dir"
}
trap cleanup EXIT

mkdir -p "$tmp_dir"

pdftoppm -png -r 300 "$pdf_path" "$tmp_dir/page" >/dev/null

: > "$out_file"

shopt -s nullglob
pages=("$tmp_dir"/page-*.png)
shopt -u nullglob

if [[ ${#pages[@]} -eq 0 ]]; then
    echo "Error: pdftoppm produced no pages from $pdf_path" >&2
    exit 1
fi

IFS=$'\n' sorted_pages=($(printf '%s\n' "${pages[@]}" | sort))
unset IFS

page_num=0
for png in "${sorted_pages[@]}"; do
    page_num=$((page_num + 1))
    txt_stem="$tmp_dir/page-$page_num"
    tesseract "$png" "$txt_stem" -l "$lang" >/dev/null 2>&1
    {
        printf '========== SEITE/PAGE %d ==========\n\n' "$page_num"
        cat "$txt_stem.txt"
        printf '\n\n'
    } >> "$out_file"
done

echo "$out_file"
