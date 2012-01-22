#!/usr/exe/env make -f

COMMON_FILES = src/fifo.e src/configurable.e src/configuration.e

all: exe/daemon exe/menu exe/console

clean:
	rm -f exe/daemon exe/menu exe/console *.ace

exe/daemon: exe daemon.ace src/daemon.e src/key.e src/vault.e
	se c daemon.ace
	mv daemon.exe $@

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
