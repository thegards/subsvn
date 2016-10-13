#!/bin/sh

DESTDIR=${DESTDIR:-/opt/sbin}
COMMAND=${1:-install}

case $COMMAND in
    install)
        mkdir -p $DESTDIR
        ln -s $(pwd)/subsvn.sh $DESTDIR/subsvn || exit 1

        echo "Installed subsvn script to $DESTDIR. Add that folder to your PATH variable to use the script."
    ;;
    uninstall)
        rm -f $DESTDIR/subsvn

        echo "Uninstalled subsvn script from $DESTDIR."
    ;;
    *)
        echo "Unknown command $COMMAND."
    ;;
esac
