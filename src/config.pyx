#!/usr/bin/env python
import sys, re, os
FORWARD_ADDR=str()
FORWARD_TYPE=str()
FORWARD_PORT=0

def filter(dst):
  req=dst[0]+':'+str(dst[1])
  for RULE in open('conf/ALLOW','rb').read().split('\n'):
    if len(RULE)<1:
      continue
    try:
      if bool(re.match(RULE,req)):
        del req, dst, RULE
        return 1
    except:
      os.write(2,'fatal error: bad rule '+RULE+' in conf/ALLOW\n')
      sys.exit(78)

  for RULE in open('conf/REJECT','rb').read().split('\n'):
    if len(RULE)<1:
      continue
    try:
      if bool(re.match(RULE,req)):
        del req, dst, RULE
        return 0
    except:
      os.write(2,'fatal error: bad rule '+RULE+' in conf/REJECT\n')
      sys.exit(78)
  return 1

def chain(dst):
  global FORWARD_TYPE
  global FORWARD_ADDR
  global FORWARD_PORT
  req=dst[0]+':'+str(dst[1])
  for TYPE in os.listdir('conf/FORWARD'):
    for ADDR in os.listdir('conf/FORWARD/'+TYPE):
      for PORT in os.listdir('conf/FORWARD/'+TYPE+'/'+ADDR):
        for RULE in open('conf/FORWARD/'+TYPE+'/'+ADDR+'/'+PORT,'rb').read().split('\n'):
          try:
            if len(RULE)<1:
              continue
            if bool(re.match(RULE,req)):
              FORWARD_TYPE=TYPE
              FORWARD_ADDR=ADDR
              FORWARD_PORT=int(PORT)
              del req, dst, TYPE, ADDR, PORT, RULE
              return 1
          except:
            os.write(2,'fatal error: bad rule '+RULE+' in conf/FORWARD/'+TYPE+'/'+ADDR+'/'+PORT+'\n')
            sys.exit(78)
  del req, dst
  return 0
