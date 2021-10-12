# extracts paint kit literals to sourcemod translations
#
# needs a file to parse

import re

regex = r'(?:(?:\"9_)([0-9]{1,3})(?:_))(?:.+)(?:(?:\t\t\")(.+)(?:\"))$'

f = None
try:
    f = open('./paintkits.txt')
except:
    print("ERROR: paintkits.txt not present. Not executing.")
    exit(0)

paints = re.findall(regex, f.read(), flags=re.M)

entries = ""
for paint in paints:
    entries += f'	"{paint[0]}"\n	{{\n	    "en"		"{paint[1]}"\n	}}\n '
print(entries)
