
all: thumbnail_grab.py.bz2 system_info_extract.py.bz2

ARCH_FLAGS=-arch i386

thumbnail_grab.py.bz2: thumbnail_grab.template.py iconextractor
	python build_script.py thumbnail_grab.template.py iconextractor | bzip2 -9 -c > thumbnail_grab.py.bz2
	
iconextractor.o: iconextractor.m
	/usr/bin/gcc -O0 -g -c -isystem /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 $(ARCH_FLAGS) -o iconextractor.o iconextractor.m
	
iconextractor: iconextractor.o
	/usr/bin/gcc -O0 -g -isystem /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -framework Cocoa -framework QuickLook -arch i386 -o iconextractor iconextractor.o
	
systeminfoextractor.o: systeminfoextractor.m
	/usr/bin/gcc -O0 -g -c -isystem /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5  $(ARCH_FLAGS) -o systeminfoextractor.o systeminfoextractor.m
	
systeminfoextractor: systeminfoextractor.o
	/usr/bin/gcc -O0 -g -isystem /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -framework Cocoa $(ARCH_FLAGS) -o systeminfoextractor systeminfoextractor.o

system_info_extract.py.bz2: system_info_extract.template.py systeminfoextractor
	python build_script.py system_info_extract.template.py systeminfoextractor | bzip2 -9 -c > system_info_extract.py.bz2

clean:
	rm -f iconextractor thumbnail_grab.py.bz2 *.o
