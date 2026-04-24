#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: extract_pdf.sh <pdf_path> <lang> [--force-ocr]

Extracts text from a PDF into <stem>_text.txt next to it.
Per page, tries pdftotext first; if the text layer is missing or too
sparse, falls back to Tesseract OCR. With --force-ocr, every page
goes through Tesseract regardless of the text layer.

Arguments:
  pdf_path     Path to the PDF (may contain spaces).
  lang         Tesseract language code: deu, eng, rus, fra, spa, ...
               Combine with '+', e.g. 'deu+eng'.
  --force-ocr  Optional: skip the text-layer path and OCR all pages.

Output:
  <dir>/<stem>_text.txt with per-page sections separated by
  '========== SEITE/PAGE N (text) ==========' or
  '========== SEITE/PAGE N (OCR) =========='.
  Summary line ('Pages: X total, Y text, Z OCR') goes to stderr.

Requires: pdftoppm, pdftotext, pdfinfo (poppler); tesseract with
the requested language pack (only loaded if any page needs OCR).
EOF
}

if [[ $# -lt 2 || $# -gt 3 ]]; then
    usage
    exit 1
fi

pdf_path="$1"
lang="$2"
force_ocr=0

if [[ $# -eq 3 ]]; then
    if [[ "$3" == "--force-ocr" ]]; then
        force_ocr=1
    else
        echo "Error: unknown option: $3" >&2
        usage
        exit 1
    fi
fi

if [[ ! -f "$pdf_path" ]]; then
    echo "Error: file not found: $pdf_path" >&2
    exit 1
fi

required_tools=(pdftoppm pdfinfo)
if [[ $force_ocr -eq 0 ]]; then
    required_tools+=(pdftotext)
fi
for tool in "${required_tools[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Error: '$tool' not found in PATH. Install with: brew install poppler tesseract tesseract-lang" >&2
        exit 1
    fi
done

tesseract_checked=0
ensure_tesseract() {
    if [[ $tesseract_checked -eq 1 ]]; then
        return
    fi
    if ! command -v tesseract >/dev/null 2>&1; then
        echo "Error: 'tesseract' not found in PATH (needed for OCR fallback). Install with: brew install tesseract tesseract-lang" >&2
        exit 1
    fi
    tesseract_checked=1
}

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

num_pages=$(pdfinfo "$pdf_path" 2>/dev/null | awk '/^Pages:/ {print $2}')
if [[ -z "${num_pages:-}" || "$num_pages" -le 0 ]]; then
    echo "Error: could not determine page count for $pdf_path" >&2
    exit 1
fi

MIN_TEXT_CHARS=30

: > "$out_file"

text_pages=0
ocr_pages=0

for ((n=1; n<=num_pages; n++)); do
    use_ocr=0
    page_text=""

    if [[ $force_ocr -eq 1 ]]; then
        use_ocr=1
    else
        page_text=$(pdftotext -layout -f "$n" -l "$n" "$pdf_path" - 2>/dev/null || true)
        non_ws_count=$(printf '%s' "$page_text" | tr -d '[:space:]' | wc -c | tr -d ' ')
        if [[ "${non_ws_count:-0}" -lt "$MIN_TEXT_CHARS" ]]; then
            use_ocr=1
        fi
    fi

    if [[ $use_ocr -eq 1 ]]; then
        ensure_tesseract
        png_stem="$tmp_dir/page_$n"
        pdftoppm -png -r 300 -f "$n" -l "$n" -singlefile "$pdf_path" "$png_stem" >/dev/null

        png_path="${png_stem}.png"
        if [[ ! -f "$png_path" ]]; then
            echo "Error: pdftoppm did not produce $png_path for page $n" >&2
            exit 1
        fi

        tesseract "$png_path" "$png_stem" -l "$lang" >/dev/null 2>&1
        page_text=$(cat "${png_stem}.txt")

        rm -f "$png_path" "${png_stem}.txt"

        marker="OCR"
        ocr_pages=$((ocr_pages + 1))
    else
        marker="text"
        text_pages=$((text_pages + 1))
    fi

    {
        printf '========== SEITE/PAGE %d (%s) ==========\n\n' "$n" "$marker"
        printf '%s\n' "$page_text"
        printf '\n\n'
    } >> "$out_file"
done

echo "$out_file"
echo "Pages: $num_pages total, $text_pages text, $ocr_pages OCR" >&2
