#!/usr/bin/env python
import socket, sys, os
sys.path.append('/services/susocks/')
sys.dont_write_bytecode=1
import config

# POST http:// => \x50\x4F\x53\x54\x20\x68\x74\x74\x70\x3A\x2F\x2F
out='\x50'+os.read(0,11)
if out!='\x50\x4F\x53\x54\x20\x68\x74\x74\x70\x3A\x2F\x2F':
  sys.exit(0)

b=str()
addr=str()
# read up to / or : (whatever comes first and calculate port)
for n in range(0,1024):
  b+=os.read(0,1)
  out+=b[::-1][0]
  if b[::-1][0]=='\x3A':
    addr=b[:len(b)-1]
    b=str()
    for m in range(0,6):
      b+=os.read(0,1)
      out+=b[::-1][0]
      if b[::-1][0]=='\x2F':
        try:
          addr+=chr(int(b[:-1])/256)+chr(int(b[:-1])%256)
        except:
          sys.exit(0)
        del m
        break
      if m==5:
        sys.exit(0)
    break
  if b[::-1][0]=='\x2F':
    addr=b[:len(b)-1]
    addr+=chr(0)+chr(80)
    break  
  if n==1023:
    sys.exit(0)

del n, b

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
        '/services/susocks/sucurvecpWRITE',
        out,
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

os.write(3,out)
del addr, dst, out
os.execvp('/services/susocks/sustream',[str()])
