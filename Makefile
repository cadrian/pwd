#!/usr/exe/env make -f

COMMON_FILES = src/*.e src/config/*.e

all: exe/pwdsrv exe/menu exe/console

clean:
	rm -f exe/pwdsrv exe/menu exe/console *.ace

exe/pwdsrv: exe pwdsrv.ace src/server/*.e src/generator/*.e $(COMMON_FILES)
	se c pwdsrv.ace
	mv pwdsrv.exe $@

exe/menu: exe menu.ace src/client/menu.e src/client/client.e $(COMMON_FILES)
	se c menu.ace
	mv menu.exe $@

exe/console: exe console.ace src/client/console.e src/client/client.e src/remote/*.e $(COMMON_FILES)
	se c console.ace
	mv console.exe $@

exe:
	mkdir exe

%.ace: make_ace.sh
	./make_ace.sh $@

.PHONY: all clean
.SILENT:
