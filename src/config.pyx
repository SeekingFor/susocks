#!/usr/bin/env python
import sys, re, os

ALLOW=list()
for RULE in open('conf/ALLOW','rb').read().split('\n'):
  if len(RULE)<1:
    continue
  try:
    ALLOW.append(re.compile(RULE))
  except:
    os.write(2,'fatal error: bad rule in conf/ALLOW\n')
    sys.exit(0)

REJECT=list()
for RULE in open('conf/REJECT','rb').read().split('\n'):
  if len(RULE)<1:
    continue
  try:
    REJECT.append(re.compile(RULE))
  except:
    os.write(2,'fatal error: bad rule in conf/REJECT\n')
    sys.exit(0)
del RULE

def filter(dst):
  req=dst[0]+':'+str(dst[1])
  for rule in ALLOW:
    if bool(re.match(rule,req)):
      del req
      return 1
  for rule in REJECT:
    if bool(re.match(rule,req)):
      del req
      return 0
  del req
  return 1
