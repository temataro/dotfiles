# sample ipython_config.py
c = get_config()

c.TerminalIPythonApp.display_banner = False
c.InteractiveShellApp.log_level = 20
c.InteractiveShellApp.exec_lines = [
    'import numpy as np',
    'import scipy as sp',
    'import matplotlib.pyplot as plt',
]
c.InteractiveShell.autoindent = True
c.InteractiveShell.colors = 'LightBG'
c.InteractiveShell.confirm_exit = False

c.InteractiveShell.deep_reload = True
c.InteractiveShell.editor = '/usr/bin/vim'
c.InteractiveShell.xmode = 'Context'

c.PrefilterManager.multi_line_specials = True
c.AliasManager.user_aliases = [
 ('la', 'ls -al'),
 ('c', 'clear'),
]
c.InteractiveShellApp.exec_lines = [
    'clear'
]
