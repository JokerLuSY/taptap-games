# -*- coding: utf-8 -*-
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")
src = open(r"E:\projects\taptap\ember_oath\scripts\chapter1.gd", encoding="utf-8").read()
for name in ("MAP", "LEVELS"):
    m = re.search(r"const %s := \[(.*?)\]" % name, src, re.S)
    rows = re.findall(r'"([^"]+)"', m.group(1))
    print("==", name, "==")
    for i, row in enumerate(rows):
        flag = "" if len(row) == 15 else "  !!! 长度错误"
        print(i, len(row), repr(row), flag)