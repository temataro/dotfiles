"""
    Split Meditations my Marcus Aurelius into verses that can be randomly read
    by zsh every time I open a new terminal window.

    I suppose I'm in my mid 20s philosopher era.
    I will accept this as well.
"""

#!/usr/bin/env python3
import os

with open("./meditations.mb.txt") as file:
    txt = file.read()
    split = txt.split("\n\n")

try:
    os.mkdir("./verses")
except:
    pass

verse_no = 1
book_id = split[0]
for s, verse in enumerate(split[1:]):
    verse_out = f"""
# *{book_id}*\n
###  **Verse {verse_no}**\n

{verse}
                 """
    filename = f"./verses/{book_id}_Verse{verse_no}.md".replace(" ", "").lower()

    with open(filename, 'w') as out:
        out.write(verse_out)

    verse_no += 1

    if "BOOK" in split[s-1]:
        verse_no = 1
        book_id = split[s-1]


# Once this is done, link zsh with `qotd.sh`
