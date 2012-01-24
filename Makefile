#!/usr/exe/env make -f

COMMON_FILES = src/fifo.e src/configurable.e src/configuration.e

all: exe/pwdsrv exe/menu exe/console

clean:
	rm -f exe/pwdsrv exe/menu exe/console *.ace

exe/pwdsrv: exe pwdsrv.ace src/pwdsrv.e src/key.e src/vault.e
	se c pwdsrv.ace
	mv pwdsrv.exe $@

exe/menu: exe menu.ace src/client.e src/menu.e $(COMMON_FILES)
	se c menu.ace
	mv menu.exe $@

exe/console: exe console.ace src/client.e src/console.e $(COMMON_FILES)
	se c console.ace
	mv console.exe $@

exe:
	mkdir exe

%.ace: make_ace.sh
	./make_ace.sh $@

.PHONY: all clean
.SILENT:
