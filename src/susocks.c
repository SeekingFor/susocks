int main(){
  unsigned char b[1];
  read(0,b,1);
  if (b[0]=='\x05'){
    execvp(
      "/services/susocks/susocks5",
      ("/services/susocks/susocks5",'\x00')
    );
  }
  if (b[0]=='\x04'){
    execvp(
      "/services/susocks/susocks4a",
      ("/services/susocks/susocks4a",'\x00')
    );
  }
  if (b[0]=='\x43'){
    execvp(
      "/services/susocks/suconnect",
      ("/services/susocks/suconnect",'\x00')
    );
  }
  if (b[0]=='\x47'){
    execvp(
      "/services/susocks/suhttpGET",
      ("/services/susocks/suhttpGET",'\x00')
    );
  }
  if (b[0]=='\x50'){
    execvp(
      "/services/susocks/suhttpPOST",
      ("/services/susocks/suhttpPOST",'\x00')
    );
  }
exit(64);}
