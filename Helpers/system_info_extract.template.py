#!/usr/bin/python

import base64, sys, tempfile, os, stat

def main():
    global exe
    
    handle, path = tempfile.mkstemp()
    f = os.fdopen(handle, 'w')
    f.write(exe)
    f.close()
    
    os.chmod(path, stat.S_IRUSR|stat.S_IXUSR)
    
    os.system(path)
    
    os.unlink(path)

exe = base64.b64decode("""
EXEDATA
""")

if __name__ == '__main__':
    main()

