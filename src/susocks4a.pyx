#!/usr/bin/env python
import socket, select, fcntl, sys, os
sys.path.append('/services/susocks/')
sys.dont_write_bytecode=1
import config

b='\x04'+os.read(0,7)
if (len(b)<8)|(b[:2]!='\x04\01'):
  sys.exit(0)

if b[4:]!='\x00\x00\x00\x01':
  addr=b[4:]+b[2:4]
  if os.read(0,1024)[::-1][0]!='\x00':
    sys.exit(0)
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
    s.connect((config.FORWARD_ADDR,config.FORWARD_PORT))
    if config.FORWARD_TYPE=='SOCKS5':
      os.write(3,'\x05\x01\x00')
      if os.read(3,2)!='\x05\x00':
        sys.exit(0)
      if os.read(3,os.write(3,
        '\x05\x01\x03'
        +chr(len(dst[0]))+dst[0]+addr[len(addr)-2:]))[:2]!='\x05\x00':
        sys.exit(0)
    elif config.FORWARD_TYPE=='SOCKS4A':
      os.write(3,
        '\x04\x01'
        +addr[len(addr)-2:]
        +'\x00\x00\x00\x01'
        +'\x73\x75\x73\x6F\x63\x6B\x73\x00'
        +addr[:len(addr)-2]+'\x00'
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

del addr, dst
os.write(1,'\x00\x5A\x00\x00\x00\x00\x00\x00')

s.setblocking(0)
s_POLLIN=select.poll()
s_POLLIN.register(3,3)
s_eagain=str()

c_POLLIN=select.poll()
c_POLLIN.register(0,3)
c_eagain=str()

fcntl.fcntl(0,4,2050)
fcntl.fcntl(1,4,2050)

def s_time():
  return len(s_POLLIN.poll(0))*128
def c_time():
  return len(c_POLLIN.poll(0))*128

while 1:
  if len(s_POLLIN.poll(128-c_time()))>0:
    b=os.read(3,65536)
    if len(b)<1:
      break
    c_eagain+=b
  if len(c_POLLIN.poll(128-s_time()))>0:
    b=os.read(0,65536)
    if len(b)<1:
      break
    s_eagain+=b
  if len(s_eagain)>0:
    try:
      s_eagain=s_eagain[os.write(3,s_eagain[:65536]):]
    except OSError as ex:
      if ex.errno!=11:
        break
  if len(c_eagain)>0:
    try:
      c_eagain=c_eagain[os.write(1,c_eagain[:65536]):]
    except OSError as ex:
      if ex.errno!=11:
        break
  if len(s_eagain)+len(c_eagain)>131072:
    break
