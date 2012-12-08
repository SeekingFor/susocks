#!/usr/bin/env python
import shelve, sys, re, os
FORWARD_ADDR=str()
FORWARD_TYPE=str()
FORWARD_PORT=0

sudb=shelve.open('sudb','r')
def filter(dst):
  global sudb
  req=dst[0]+':'+str(dst[1])
  for RULE in sudb['ALLOW']:
    try:
      if bool(re.search(RULE,req)):
        del req, dst, RULE
        return 1
    except:
      os.write(2,'fatal error: bad rule '+RULE+' in conf/ALLOW\n')
      sys.exit(78)

  for RULE in sudb['REJECT']:
    try:
      if bool(re.search(RULE,req)):
        del req, dst, RULE
        sudb.close()
        del sudb
        return 0
    except:
      os.write(2,'fatal error: bad rule '+RULE+' in conf/REJECT\n')
      sys.exit(78)
  del req, dst
  return 1

def chain(dst):
  global sudb
  global FORWARD_TYPE
  global FORWARD_ADDR
  global FORWARD_PORT
  req=dst[0]+':'+str(dst[1])
  for TYPE in sudb['FORWARD']:
    for ADDR in sudb['FORWARD'][TYPE]:
      for PORT in sudb['FORWARD'][TYPE][ADDR]:
        for RULE in sudb['FORWARD'][TYPE][ADDR][PORT]:
          try:
            if bool(re.search(RULE,req)):
              FORWARD_TYPE=TYPE
              FORWARD_ADDR=ADDR
              FORWARD_PORT=int(PORT)
              del req, dst, TYPE, ADDR, PORT, RULE
              sudb.close()
              del sudb
              return 1
          except:
            os.write(2,'fatal error: bad rule '+RULE+' in conf/FORWARD/'+TYPE+'/'+ADDR+'/'+PORT+'\n')
            sys.exit(78)
  del req, dst
  sudb.close()
  del sudb
  return 0
