import re
import json

# Read JS file
with open("excel-addin/src/guidelines-default.js", "r") as f:
    js_content = f.read()

# Very naive extraction, better to just recreate it manually or via a quick script
