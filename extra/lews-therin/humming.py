#!/usr/bin/env python3

"""
    Return a random Lews Therin Telamon rave at random
    when opening a new terminal window.

    Add this line to your zsh or bash config.
    /path/to/this/script
    Change QUOTE_DIR path to where to find the quote list

    You must have the terminal markdown render tool glow

"""

import random
import subprocess as sp

HIT_PROBABILITY = 85  # probability of showing quote in percents
QUOTE_DIR = "/home/tem/code/github.com/temataro/dotfiles/extra/lews-therin/all-quotes.txt"
# All quotes generously taken from the repo where r/lews-therin-bot stores them
# https://github.com/Tobuss/Lews-Therin-Bot/blob/master/lews.txt


def main():
    # Read quotes, pick a random one
    with open(QUOTE_DIR, 'r') as f:
        lines = f.readlines()

    # Quick test to see if you have glow on your system
    err = sp.run("which glow".split(), stdout=sp.DEVNULL,
                 stderr=sp.DEVNULL).returncode
    if err:
        print("You don't currently have glow on your system. Install from your"
              "favorite package manager.\n")

    if random.randint(0, 100) < HIT_PROBABILITY:
        with open("/tmp/tmp-quote.md", "w") as f:
            f.write(random.choice(lines))

        sp.run("glow /tmp/tmp-quote.md".split())


if __name__ == "__main__":
    main()
