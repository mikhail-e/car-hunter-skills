#!/bin/bash
# Удаляет LaunchAgent проверки EV объявлений.

PLIST_NAME="com.dasauto.check-listings.plist"
DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"

launchctl unload "$DEST" 2>/dev/null
rm -f "$DEST"

echo "LaunchAgent удалён."
