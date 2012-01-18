all: bin/daemon bin/menu bin/console

bin/daemon: daemon.ace
	se c daemon.ace

bin/menu: menu.ace
	se c menu.ace

bin/console: console.ace
	se c console.ace

%.ace: make_ace.sh
	./make_ace.sh $@

.PHONY: all
