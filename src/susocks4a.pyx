#!/usr/bin/env python
import socket, select, fcntl, sys, os
sys.path.append('/services/susocks/')
sys.dont_write_bytecode=1
import config

b=os.read(0,8)
if (len(b)<8)|(b[:2]!='\x04\01'):
  sys.exit(0)
addr=b[2:4]
b=str()
for n in range(0,1024):
  if os.read(0,1)=='\x00':
    b=os.read(0,1024)
    addr=b[:len(b)-1]+addr
    del n
    break
if len(b)<1:
  sys.exit(0)

s=socket.socket(2,1)
s.setsockopt(1,2,1)

dst=(
  addr[:len(addr)-2],
  ord(addr[::-1][1])*256+ord(addr[::-1][0])
)
if config.filter(dst)<1:
  sys.exit(0)
errno=s.connect_ex(dst)
del dst, addr
if errno>0:
  sys.exit(0)
os.write(1,'\x00\x5A\x00\x00\x00\x00\x00\x00')
del errno

s.setblocking(0)
s_POLLIN=select.poll()
s_POLLIN.register(3,3)
s_eagain=str()

c_POLLIN=select.poll()
c_POLLIN.register(0,3)
c_eagain=str()

fcntl.fcntl(0,fcntl.F_SETFL,2050)
fcntl.fcntl(1,fcntl.F_SETFL,2050)

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
  if len(s_eagain)+len(c_eagain)>65536*128:
    break
