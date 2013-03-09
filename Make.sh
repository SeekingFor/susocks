#!/bin/sh -v
rm -rf build out || exit 1

unset HEADERS
CYTHON=`which cython 2>&1 >/dev/null`
if [ -x $CYTHON ];then
    if [ -e '/usr/include/python2.6/Python.h'       ] &&
       [ -e '/usr/include/python2.6/structmember.h' ] ;then
        HEADERS='/usr/include/python2.6/'
  elif [ -e '/usr/local/include/python2.6/Python.h'       ] &&
       [ -e '/usr/local/include/python2.6/structmember.h' ] ;then
        HEADERS='/usr/local/include/python2.6/'
    fi
fi

mkdir -p /services/susocks || exit 1
mkdir -p build             || exit 1
mkdir -p out               || exit 1

gcc src/susocks.c -o out/susocks || exit 1
gcc src/sustream.c -o out/sustream || exit 1
gcc src/sucurvecp.c -o out/sucurvecp || exit 1
gcc src/sucurvecpWRITE.c -o out/sucurvecpWRITE || exit 1

if [ -z $HEADERS ]; then

  #python -c'import py_compile;\
  #  py_compile.compile("src/suhttpGET.pyx","out/suhttpGET");\
  #  py_compile.compile("src/suhttpPOST.pyx","out/suhttpPOST");\
  #  py_compile.compile("src/suconnect.pyx","out/suconnect");\
  #  py_compile.compile("src/susocks4a.pyx","out/susocks4a");\
  #  py_compile.compile("src/susocks5.pyx","out/susocks5");\
  #  py_compile.compile("src/sudata.pyx","out/sudata");\
  #  py_compile.compile("src/config.pyx","out/config.pyc")' || exit 1

  cp src/suhttpGET.pyx out/suhttpGET   || exit 1
  cp src/suhttpPOST.pyx out/suhttpPOST || exit 1
  cp src/suconnect.pyx out/suconnect   || exit 1
  cp src/susocks4a.pyx out/susocks4a   || exit 1
  cp src/susocks5.pyx  out/susocks5    || exit 1
  cp src/sudata.pyx    out/sudata      || exit 1
  cp src/config.pyx    out/config.py   || exit 1

  chmod +x out/suhttpGET             || exit 1
  chmod +x out/suhttpPOST            || exit 1
  chmod +x out/suconnect             || exit 1
  chmod +x out/susocks               || exit 1
  chmod +x out/susocks4a             || exit 1
  chmod +x out/susocks5              || exit 1
  chmod +x out/sudata                || exit 1

  mv out/* /services/susocks/        || exit 1

  rm -rf build out                   || exit 1
  exit 0
fi

[ -z $HEADERS ] && exit 1

cython --embed src/susocks4a.pyx -o build/susocks4a.c         || exit 1
gcc -O2 -c build/susocks4a.c -I $HEADERS -o build/susocks4a.o || exit 1
gcc -O1 -o out/susocks4a build/susocks4a.o -l python2.6       || exit 1

cython --embed src/suhttpGET.pyx -o build/suhttpGET.c         || exit 1
gcc -O2 -c build/suhttpGET.c -I $HEADERS -o build/suhttpGET.o || exit 1
gcc -O1 -o out/suhttpGET build/suhttpGET.o -l python2.6       || exit 1

cython --embed src/suhttpPOST.pyx -o build/suhttpPOST.c         || exit 1
gcc -O2 -c build/suhttpPOST.c -I $HEADERS -o build/suhttpPOST.o || exit 1
gcc -O1 -o out/suhttpPOST build/suhttpPOST.o -l python2.6       || exit 1

cython --embed src/suconnect.pyx -o build/suconnect.c         || exit 1
gcc -O2 -c build/suconnect.c -I $HEADERS -o build/suconnect.o || exit 1
gcc -O1 -o out/suconnect build/suconnect.o -l python2.6       || exit 1

cython --embed src/susocks5.pyx -o build/susocks5.c         || exit 1
gcc -O2 -c build/susocks5.c -I $HEADERS -o build/susocks5.o || exit 1
gcc -O1 -o out/susocks5 build/susocks5.o -l python2.6       || exit 1

cython --embed src/sudata.pyx -o build/sudata.c         || exit 1
gcc -O2 -c build/sudata.c -I $HEADERS -o build/sudata.o || exit 1
gcc -O1 -o out/sudata build/sudata.o -l python2.6       || exit 1

cython src/config.pyx -o build/config.c                                                                                                   || exit 1
gcc -pthread -fno-strict-aliasing -DNDEBUG -g -fwrapv -O2 -Wall -Wstrict-prototypes -fPIC -I $HEADERS -c build/config.c -o build/config.o || exit 1
gcc -pthread -shared -Wl,-O1 -Wl,-Bsymbolic-functions build/config.o -o out/config.so                                                     || exit 1

mv out/* /services/susocks  || exit 1
rm -rf build out            || exit 1
