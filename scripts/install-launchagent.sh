#!/bin/bash
# Устанавливает LaunchAgent для периодической проверки новых EV объявлений.

PLIST_NAME="com.dasauto.check-listings.plist"
SOURCE="$(dirname "$0")/../launchd/$PLIST_NAME"
DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"

# Выгрузить, если уже загружен
launchctl unload "$DEST" 2>/dev/null

cp "$SOURCE" "$DEST"
launchctl load "$DEST"

echo "LaunchAgent установлен: $DEST"
echo "Проверка каждые 30 минут. Логи: /tmp/das-auto-check.log"
