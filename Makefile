#!/usr/exe/env make -f

all: exe/daemon exe/menu exe/console

clean:
	rm -rf exe *.ace

exe/daemon: exe daemon.ace src/daemon.e src/fifo.e src/key.e src/vault.e
	se c daemon.ace
	mv daemon.exe $@

exe/menu: exe menu.ace src/client.e src/menu.e
	se c menu.ace
	mv menu.exe $@

exe/console: exe console.ace src/client.e src/console.e
	se c console.ace
	mv console.exe $@

exe:
	mkdir exe

%.ace: make_ace.sh
	./make_ace.sh $@

.PHONY: all clean
.SILENT:
