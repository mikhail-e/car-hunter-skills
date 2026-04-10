#!/usr/bin/env python3
"""Проверяет наличие новых EV объявлений на mobile.de и показывает macOS-нотификацию.

Использование:
    python3 scripts/check_new_listings.py           # проверка + нотификация
    python3 scripts/check_new_listings.py --dry-run  # только вывод в stdout
"""

import json
import subprocess
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
CONFIG_PATH = PROJECT_DIR / "search-config.json"
BROWSER_PROFILE = Path("/tmp/das-auto-browser-profile")

DRY_RUN = "--dry-run" in sys.argv

# JS для извлечения ID только из реальных результатов поиска,
# исключая рекомендации (data-testid="srx-result-list-container")
EXTRACT_IDS_JS = """() => {
    const srxContainer = document.querySelector('[data-testid="srx-result-list-container"]');
    const allLinks = document.querySelectorAll('a[href*="/fahrzeuge/details.html?id="]');
    const ids = [];
    for (const link of allLinks) {
        if (srxContainer && srxContainer.contains(link)) continue;
        const match = link.href.match(/id=(\\d{6,})/);
        if (match && !ids.includes(match[1])) ids.push(match[1]);
    }
    return ids;
}"""


def load_config():
    with open(CONFIG_PATH) as f:
        return json.load(f)


def notify(title, message):
    subprocess.run([
        "terminal-notifier",
        "-title", title,
        "-message", message,
        "-sound", "Glass",
    ])


def main():
    config = load_config()
    search_url = config["searchUrl"]
    checked_ids = set(config["checkedIds"])

    # Запомнить активное приложение до запуска браузера
    prev_app = subprocess.run(
        ["osascript", "-e", 'tell application "System Events" to get name of first application process whose frontmost is true'],
        capture_output=True, text=True,
    ).stdout.strip()

    with sync_playwright() as p:
        ctx = p.chromium.launch_persistent_context(
            str(BROWSER_PROFILE),
            headless=False,
            channel="chrome",
            args=["--disable-blink-features=AutomationControlled"],
        )
        page = ctx.pages[0] if ctx.pages else ctx.new_page()

        # Вернуть фокус на предыдущее приложение (браузер уходит на задний план)
        if prev_app:
            subprocess.run([
                "osascript", "-e",
                'tell application "System Events" to set frontmost of '
                f'process "{prev_app}" to true',
            ])

        page.goto(search_url, wait_until="domcontentloaded")

        # Закрыть cookie-баннер
        try:
            btn = page.wait_for_selector('button:has-text("Einverstanden")', timeout=5000)
            if btn:
                btn.click()
                page.wait_for_timeout(2000)
        except Exception:
            pass

        # Дождаться появления результатов
        try:
            page.wait_for_selector('a[href*="/fahrzeuge/details.html?id="]', timeout=15000)
        except Exception:
            print("ERROR: не удалось загрузить результаты (возможно, rate limit)")
            ctx.close()
            return

        all_ids = page.evaluate(EXTRACT_IDS_JS)
        ctx.close()

    new_ids = [i for i in all_ids if i not in checked_ids]
    total = len(all_ids)
    new = len(new_ids)

    print(f"TOTAL:{total} NEW:{new}")
    for i in new_ids:
        print(f"  {i}")

    if new > 0 and not DRY_RUN:
        word = "объявление" if new == 1 else "объявлений" if new >= 5 else "объявления"
        notify("Das Auto", f"Найдено {new} новых {word} EV на mobile.de")


if __name__ == "__main__":
    main()
