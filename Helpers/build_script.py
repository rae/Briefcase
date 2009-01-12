
import base64, sys

# Read the template script
f = file(sys.argv[1], 'r')
script = f.read()
f.close()

# Read the binary to encode
f = file(sys.argv[2], 'rb')
binary = f.read()
f.close()

# Encode the binary
data = base64.b64encode(binary)

# Stick it in the template script
script = script.replace('EXEDATA',data)

sys.stdout.write(script)