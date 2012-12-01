#!/usr/bin/env python
import socket, sys, os
sys.path.append('/services/susocks/')
sys.dont_write_bytecode=1
import config

b='\x43'+os.read(0,7)
if b!='\x43\x4F\x4E\x4E\x45\x43\x54\x20':
  sys.exit(0)

b=str()
addr=str()
for n in range(0,256):
  b+=os.read(0,1)
  if b[::-1][0]=='\x3A':
    break
  if n==255:
    sys.exit(0)
addr=b[:len(b)-1]

b=str()
for n in range(0,6):
  b+=os.read(0,1)
  if b[::-1][0]=='\x20':
    break
  if n==5:
    sys.exit(0)

try:
  addr+=chr(int(b)/256)+chr(int(b)%256)
  if os.read(0,1024)[::-1][:2]!='\x0A\x0A':
    sys.exit(0)
  del n
except:
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
os.write(1,'HTTP/1.0 200 \x3A\x2D\x29\n\n')
os.execvp('/services/susocks/sustream',[str()])
