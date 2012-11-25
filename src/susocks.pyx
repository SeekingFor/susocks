#!/usr/bin/env python
import sys, os
sys.argv.append(str())
b=sys.stdin.read(1)
if len(b)<1:
  sys.exit(0)
elif b=='\x04':
  os.execvp('/services/susocks/susocks4a',sys.argv[1:])
elif b=='\x05':
  os.execvp('/services/susocks/susocks5',sys.argv[1:])
