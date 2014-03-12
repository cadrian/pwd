#!/usr/exe/env make -f

COMMON_FILES = src/*.e src/config/*.e src/extern/*.e

all: exe/server exe/menu exe/console

clean:
	test -e server.ace && se clean server.ace
	test -e menu.ace && se clean menu.ace
	test -e console.ace && se clean console.ace
	rm -f exe/server exe/menu exe/console *.ace

exe/server: exe server.ace src/server/*.e src/generator/*.e $(COMMON_FILES)
	se c server.ace
	mv server.exe $@

exe/menu: exe menu.ace src/client/menu.e src/client/client.e $(COMMON_FILES)
	se c menu.ace
	mv menu.exe $@

exe/console: exe console.ace src/client/console.e src/client/client.e src/client/remote/*.e src/client/command/*.e src/client/command/remote/*.e $(COMMON_FILES)
	se c console.ace
	mv console.exe $@

exe:
	mkdir exe

%.ace: make_ace.sh
	./make_ace.sh $@

.PHONY: all clean
.SILENT:
