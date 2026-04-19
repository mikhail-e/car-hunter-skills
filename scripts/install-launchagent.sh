#!/bin/bash
# Устанавливает LaunchAgent для периодической проверки новых EV объявлений.
# Генерирует plist из шаблона с подстановкой абсолютных путей.
#
# Переопределение Python (опционально):
#   PYTHON=/opt/anaconda3/bin/python3 bash scripts/install-launchagent.sh

set -euo pipefail

PLIST_NAME="com.dasauto.check-listings.plist"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$PROJECT_DIR/launchd/$PLIST_NAME.template"
DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"
PYTHON="${PYTHON:-$(command -v python3)}"

if [[ ! -f "$TEMPLATE" ]]; then
    echo "Error: шаблон не найден: $TEMPLATE" >&2
    exit 1
fi

if [[ -z "$PYTHON" ]]; then
    echo "Error: python3 не найден в PATH. Задай явно через PYTHON=..." >&2
    exit 1
fi

# Выгрузить, если уже загружен
launchctl unload "$DEST" 2>/dev/null || true

sed -e "s|{{PROJECT_DIR}}|$PROJECT_DIR|g" -e "s|{{PYTHON}}|$PYTHON|g" "$TEMPLATE" > "$DEST"
launchctl load "$DEST"

echo "LaunchAgent установлен: $DEST"
echo "  PROJECT_DIR: $PROJECT_DIR"
echo "  PYTHON: $PYTHON"
echo "Проверка каждые 30 минут. Логи: /tmp/das-auto-check.log"
