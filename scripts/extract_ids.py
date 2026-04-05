"""Извлекает ID объявлений mobile.de из snapshot-файла.

Использование: python3 scripts/extract_ids.py <snapshot_file> [checked_id1,checked_id2,...]

Выводит:
- По одному новому ID на строку
- Последняя строка: TOTAL:<число> NEW:<число>
"""

import re
import sys

if len(sys.argv) < 2:
    print("Usage: python3 scripts/extract_ids.py <snapshot_file> [checked_ids_comma_separated]")
    sys.exit(1)

snapshot_path = sys.argv[1]
checked_ids = set(sys.argv[2].split(",")) if len(sys.argv) > 2 and sys.argv[2] else set()

text = open(snapshot_path).read()

# Ищем ID в URL-ах mobile.de
ids = []
# Формат: /auto-inserat/.../ID.html
ids += re.findall(r"/auto-inserat/[^/]+/(\d+)\.html", text)
# Формат: details.html?id=ID или id=ID в параметрах
ids += re.findall(r"id=(\d{6,})", text)

# Дедупликация с сохранением порядка
seen = set()
unique = []
for i in ids:
    if i not in seen:
        seen.add(i)
        unique.append(i)

new_ids = [i for i in unique if i not in checked_ids]

for i in new_ids:
    print(i)

print(f"TOTAL:{len(unique)} NEW:{len(new_ids)}")
