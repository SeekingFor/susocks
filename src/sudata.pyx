#!/usr/bin/env python
import shelve, sys, re, os
try:
  sudb=shelve.open(sys.argv[1])
except:
  os.write(2,sys.argv[0]+' <sudb>\n')
  sys.exit(64)

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
          if (0>int(PORT)>65535):
            sys.exit(78)
          FORWARD[TYPE][ADDR][PORT].append(re.compile(RULE))
        except:
          os.write(2,'fatal error: bad rule '+RULE+' in conf/FORWARD/'+TYPE+'/'+ADDR+'/'+PORT+'\n')
          sys.exit(78)

try:
  sudb['ALLOW']=ALLOW
  sudb['REJECT']=REJECT
  sudb['FORWARD']=FORWARD
  sudb.close()
except:
  os.write(2,'fatal error: failed to compile '+sys.argv[1]+'\n')
  sys.exit(64)
