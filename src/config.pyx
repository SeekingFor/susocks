#!/usr/bin/env python
import sys, re, os
FORWARD_ADDR=str()
FORWARD_TYPE=str()
FORWARD_PORT=0
RULE=str()
ADDR=str()
PORT=str()

ALLOW=list()
for RULE in open('conf/ALLOW','rb').read().split('\n'):
  if len(RULE)<1:
    continue
  try:
    ALLOW.append(re.compile(RULE))
  except:
    os.write(2,'fatal error: bad rule '+RULE+' in conf/ALLOW\n')
    sys.exit(78)

REJECT=list()
for RULE in open('conf/REJECT','rb').read().split('\n'):
  if len(RULE)<1:
    continue
  try:
    REJECT.append(re.compile(RULE))
  except:
    os.write(2,'fatal error: bad rule '+RULE+' in conf/REJECT\n')
    sys.exit(78)

FORWARD=dict()
for TYPE in os.listdir('conf/FORWARD'):
  for ADDR in os.listdir('conf/FORWARD/'+TYPE):
    for PORT in os.listdir('conf/FORWARD/'+TYPE+'/'+ADDR):
      for RULE in open('conf/FORWARD/'+TYPE+'/'+ADDR+'/'+PORT,'rb').read().split('\n'):
        if len(RULE)<1:
          continue
        if not TYPE in FORWARD.keys():
          FORWARD[TYPE]=dict()
          FORWARD[TYPE][ADDR]=dict()
          FORWARD[TYPE][ADDR][PORT]=list()
        if not ADDR in FORWARD[TYPE].keys():
          FORWARD[TYPE][ADDR]=dict()
          FORWARD[TYPE][ADDR][PORT]=list()
        if not PORT in FORWARD[TYPE][ADDR].keys():
          FORWARD[TYPE][ADDR][PORT]=list()
        try:
          int(PORT)
          FORWARD[TYPE][ADDR][PORT].append(re.compile(RULE))
        except:
          os.write(2,'fatal error: bad rule '+RULE+' in conf/FORWARD/'+TYPE+'/'+ADDR+'/'+PORT+'\n')
          sys.exit(78)

def filter(dst):
  req=dst[0]+':'+str(dst[1])
  for RULE in ALLOW:
    if bool(re.match(RULE,req)):
      del req, dst
      return 1
  for RULE in REJECT:
    if bool(re.match(RULE,req)):
      del req, dst
      return 0
  return 1

def chain(dst):
  global FORWARD_TYPE
  global FORWARD_ADDR
  global FORWARD_PORT
  req=dst[0]+':'+str(dst[1])
  for TYPE in FORWARD.keys():
    for ADDR in FORWARD[TYPE].keys():
      for PORT in FORWARD[TYPE][ADDR].keys():
        for RULE in FORWARD[TYPE][ADDR][PORT]:
          if bool(re.match(RULE,req)):
            FORWARD_TYPE=TYPE
            FORWARD_ADDR=ADDR
            FORWARD_PORT=int(PORT)
            del req, dst
            return 1
  del req, dst
  return 0
