# Автоматическая проверка новых EV объявлений

Скрипт `check_new_listings.py` проверяет mobile.de на наличие новых объявлений и показывает macOS-нотификацию, если они появились.

## Зависимости

```bash
pip3 install playwright
playwright install chromium
```

## Ручной запуск

```bash
# Проверка с нотификацией (если есть новые)
python3 scripts/check_new_listings.py

# Только вывод в консоль, без нотификации
python3 scripts/check_new_listings.py --dry-run
```

Вывод: `TOTAL:N NEW:M` — всего объявлений на странице и сколько из них новых (не в `checkedIds`).

## Автозапуск каждые 30 минут (LaunchAgent)

### Установка

```bash
bash scripts/install-launchagent.sh
```

Скрипт копирует plist в `~/Library/LaunchAgents/` и загружает через `launchctl`. Проверка запускается сразу и далее каждые 30 минут.

### Удаление

```bash
bash scripts/uninstall-launchagent.sh
```

### Логи

```bash
cat /tmp/das-auto-check.log        # stdout
cat /tmp/das-auto-check-error.log  # ошибки
```

### Проверить статус

```bash
launchctl list | grep dasauto
```

## Как это работает

1. Читает URL поиска и список проверенных ID из `search-config.json`
2. Открывает страницу поиска через Playwright Chromium (headed-режим, окно за пределами экрана)
3. Извлекает ID объявлений из DOM, исключая рекомендации ("Ähnliche Fahrzeuge")
4. Сравнивает с `checkedIds` — определяет новые
5. Если есть новые — показывает macOS-нотификацию
6. **Не обновляет `checkedIds`** — это делает только `/ev-search` в Claude Code

## Изменение интервала

Отредактировать `StartInterval` в `launchd/com.dasauto.check-listings.plist` (значение в секундах: 1800 = 30 мин, 3600 = 60 мин), затем переустановить:

```bash
bash scripts/install-launchagent.sh
```
