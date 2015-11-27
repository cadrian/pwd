Notes for future developpers.

The clients (console, menu, webclient) will automatically try to start
the server if it is not started.

To debug the server, be sure to start it in a separate window.

Usual sequence:

    vi make_ace.sh
    # make changes to the server config: usually trace=yes, rescue=no, assert=require - save file
    MOCK=no EXE=server bootstrap.sh
    make exe/server
    exe/server -no_detach
