# Das Auto — EV search with Claude Code

A personal assistant for finding a used electric car in Germany, built on [Claude Code](https://claude.com/claude-code). Three skills evaluate and search mobile.de listings; a Playwright script monitors for new ads; OCR pipeline handles scanned PDFs (contract, Fahrzeugbrief, CoC, etc.).

## Skills

- **`/ev-eval`** — evaluates a single mobile.de listing against a checklist (dealbreakers + nice-to-have) and returns a verdict.
- **`/ev-search`** — finds new listings via a saved search URL, runs each through `/ev-eval`, updates `evaluations.md`, drafts dealer messages.
- **`/doc-analyze`** — OCRs scanned PDFs via Tesseract (`deu`/`eng`/`rus`); produces raw text, structured Markdown, and a summary next to the PDF.

Plus: `scripts/check_new_listings.py` (Playwright monitor) + macOS LaunchAgent for 30-min auto-check.

## Language note

The project is maintained in Russian: skill definitions, evaluation cards, dealer-message template, and full docs are in Russian. If you're comfortable with that, full install & usage docs are in **[README.md](README.md)**. Otherwise feel free to fork and translate.

## License

[MIT](LICENSE).
