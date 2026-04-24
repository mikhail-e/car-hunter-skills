# Car Hunter Skills — поиск электромобиля на mobile.de с Claude Code

Персональный ассистент для поиска подержанного электромобиля в Германии на базе [Claude Code](https://claude.com/claude-code). Три скилла для оценки и поиска объявлений на mobile.de + Playwright-мониторинг новых машин + OCR документов (контракт, Fahrzeugbrief, CoC и т.д.).

[English tl;dr](README.en.md)

## Что внутри

Три Claude Code скилла (в `.claude/skills/`):

- **[`/ev-eval`](.claude/skills/ev-eval/SKILL.md)** — оценка одного объявления с mobile.de по чек-листу (dealbreakers + nice-to-have), выдаёт вердикт ✅/⚠️/❌.
- **[`/ev-search`](.claude/skills/ev-search/SKILL.md)** — поиск новых объявлений по сохранённому URL, прогоняет каждое через `/ev-eval`, обновляет `evaluations.md` и готовит черновики писем дилерам.
- **[`/doc-analyze`](.claude/skills/doc-analyze/SKILL.md)** — OCR сканированных PDF через Tesseract (deu/eng/rus). Создаёт `*_text.txt` (сырой), `*_text.md` (структурированный) и `*_resume.md` (резюме) рядом с PDF.

Плюс инфраструктура:

- **`scripts/check_new_listings.py`** — Playwright-скрипт, проверяет mobile.de и показывает macOS-нотификацию при появлении новых объявлений. Подробности — в [`scripts/README.md`](scripts/README.md).
- **LaunchAgent** — запускает проверку каждые 30 минут.
- **`templates/dealer-message.md`** — шаблон письма дилеру на немецком (заполняется скиллом `/ev-search`).

## Зависимости

- [Claude Code CLI](https://claude.com/claude-code)
- Python 3 + Playwright:
  ```bash
  pip3 install playwright
  playwright install chromium
  ```
- Для OCR (`/doc-analyze`):
  ```bash
  brew install poppler tesseract tesseract-lang
  ```
- Для macOS-нотификаций (опционально, только если ставишь LaunchAgent):
  ```bash
  brew install terminal-notifier
  ```

## Установка

```bash
git clone https://github.com/mikhail-e/car-hunter-skills.git
cd car-hunter-skills

# Скопировать примеры в рабочие файлы (они в .gitignore)
cp search-config.example.json search-config.json
cp evaluations.example.md evaluations.md

# Установить зависимости (см. выше)
pip3 install playwright && playwright install chromium
brew install poppler tesseract tesseract-lang terminal-notifier
```

Отредактировать `search-config.json`:
- `searchUrl` — вставить свой URL поиска с mobile.de (настрой фильтры в браузере и скопируй URL результатов).
- `checkedIds` — оставить `[]`; скилл `/ev-search` сам будет пополнять этот список.

(Опционально) Установить LaunchAgent для автопроверки каждые 30 минут:

```bash
bash scripts/install-launchagent.sh
```

Если `python3` не в PATH или нужен конкретный интерпретатор:

```bash
PYTHON=/opt/anaconda3/bin/python3 bash scripts/install-launchagent.sh
```

Удалить: `bash scripts/uninstall-launchagent.sh`.

## Использование

В Claude Code, открытом в корне проекта:

```
# Оценить одно объявление
/ev-eval https://suchen.mobile.de/fahrzeuge/details.html?id=...

# Проверить все новые объявления и оценить их
/ev-search

# Разобрать PDF-документ (контракт, Fahrzeugbrief, и т.д.)
/doc-analyze путь/к/файлу.pdf
```

## Адаптация под себя

Проект заточен под конкретный профиль (семейный кроссовер, Южная Германия), но легко правится:

- **Критерии оценки** — [`.claude/skills/ev-eval/SKILL.md`](.claude/skills/ev-eval/SKILL.md): таблица dealbreakers (минимальная ёмкость батареи, число мест, наличие ACC, рейтинг дилера и т.д.) и nice-to-have. Меняй пороги под свои предпочтения.
- **Шаблон письма дилеру** — [`templates/dealer-message.md`](templates/dealer-message.md): плейсхолдеры `{{DEALER_NAME}}`, `{{CAR_MODEL}}`, `{{SENDER_NAME}}` и т.д.
- **URL и фильтры поиска** — `search-config.json`: задаётся URL результатов mobile.de со всеми твоими фильтрами (цена, пробег, год, марка, радиус, локация).
- **Интервал автопроверки** — `launchd/com.dasauto.check-listings.plist.template`, ключ `StartInterval` (в секундах).

## Структура

```
.claude/skills/        # Три Claude Code скилла
├── ev-eval/
├── ev-search/
└── doc-analyze/       # + scripts/ocr_pdf.sh

scripts/               # Python + shell
├── check_new_listings.py
├── cleanup.py
├── extract_ids.py
├── dismiss_cookie.js
├── install-launchagent.sh
├── uninstall-launchagent.sh
└── README.md

launchd/               # macOS LaunchAgent шаблон
templates/             # Шаблон письма дилеру
```

## Лицензия

MIT — см. [LICENSE](LICENSE).
