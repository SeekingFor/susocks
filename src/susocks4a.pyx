#!/usr/bin/env python
import socket, sys, os
sys.path.append('/services/susocks/')
sys.dont_write_bytecode=1
import config

b='\x04'+os.read(0,7)
if (len(b)<8)|(b[:2]!='\x04\01'):
  sys.exit(0)

if (b[7]!='\x00')&\
   (b[4:7]!='\x00\x00\x00'):
  addr=b[4:]+b[2:4]
  if os.read(0,1024)[::-1][0]!='\x00':
    sys.exit(0)
  dst=(
    socket.inet_ntoa(addr[:4]),
    ord(addr[4])*256+ord(addr[5])
  )

else:
  addr=b[2:4]
  b=str()
  for n in range(0,1024):
    if os.read(0,1)=='\x00':
      b=os.read(0,1024)
      if b[::-1][0]!='\x00':
        sys.exit(0)
      addr=b[:len(b)-1]+addr
      del n
      break
  if len(b)<1:
    sys.exit(0)
  dst=(
    addr[:len(addr)-2],
    ord(addr[::-1][1])*256+ord(addr[::-1][0])
  )

if config.filter(dst)<1:
  sys.exit(0)

s=socket.socket(2,1)
s.setsockopt(1,2,1)

if config.chain(dst)>0:
  try:
    if config.FORWARD_TYPE=='CURVECP':
      s.close()
      os.write(1,'\x00\x5A\x00\x00\x00\x00\x00\x00') # assumes success
      os.dup2(0,6)
      os.dup2(1,7)
      os.execvp('curvecpclient',[
        'curvecpclient',
        config.CURVECP_SERVER,
        config.CURVECP_PUBKEY,
        config.FORWARD_ADDR,
        str(config.FORWARD_PORT),
        config.CURVECP_EXTENSION,
        'curvecpmessage',
        '/services/susocks/sucurvecp'
      ])

    s.connect((config.FORWARD_ADDR,config.FORWARD_PORT))

    if config.FORWARD_TYPE=='SOCKS5':
      os.write(3,'\x05\x01\x00')
      if os.read(3,2)!='\x05\x00':
        sys.exit(0)
      os.write(3,
        '\x05\x01\x00\x03'
        +chr(len(dst[0]))+dst[0]+addr[len(addr)-2:]
      )
      if os.read(3,1024)[:2]!='\x05\x00':
        sys.exit(0)

    elif config.FORWARD_TYPE=='SOCKS4A':
      os.write(3,
        '\x04\x01'
        +addr[len(addr)-2:]
        +'\x00\x00\x00\x01'
        +'\x73\x75\x73\x6F\x63\x6B\x73\x00'
        +dst[0]+'\x00'
      )
      if os.read(3,8)[:2]!='\x00\x5A':
        sys.exit(0)

    elif config.FORWARD_TYPE=='SOCKS4':
      os.write(3,
        '\x04\x01'
        +addr[len(addr)-2:]
        +socket.inet_aton(socket.gethostbyname(dst[0]))
        +'\x73\x75\x73\x6F\x63\x6B\x73\x00'
      )
      if os.read(3,8)[:2]!='\x00\x5A':
        sys.exit(0)

    elif config.FORWARD_TYPE=='CONNECT':
      os.write(3,'CONNECT '+dst[0]+':'+str(dst[1])+' HTTP/1.0\n\n')
      if not(' 200 'in os.read(3,1024)):
        sys.exit(0)

    else:
      sys.exit(0)
  except:
    sys.exit(0)

else:
  try:
    s.connect(dst)
  except:
    sys.exit(0)

del b, addr, dst
os.write(1,'\x00\x5A\x00\x00\x00\x00\x00\x00')
os.execvp('/services/susocks/sustream',[str()])
