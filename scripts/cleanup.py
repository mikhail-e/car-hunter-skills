"""Удаляет временные файлы из .playwright-mcp/ и temp/."""

import glob
import os

for f in glob.glob(".playwright-mcp/*") + glob.glob("temp/*"):
    os.remove(f)
