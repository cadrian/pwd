#!/usr/bin/env make -f

all: bin/daemon bin/menu bin/console

bin/daemon: daemon.ace src/daemon.e src/fifo.e src/key.e src/vault.e
	se c daemon.ace
	mv daemon.exe $@

bin/menu: menu.ace src/client.e src/menu.e
	se c menu.ace
	mv menu.exe $@

bin/console: console.ace src/client.e src/console.e
	se c console.ace
	mv console.exe $@

%.ace: make_ace.sh
	./make_ace.sh $@

.PHONY: all
.SILENT:
