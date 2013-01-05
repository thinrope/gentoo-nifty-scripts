#!/bin/bash
VERSION="1.0.5"

trap 'echo -ne "\n:::\n:::\tCaught signal, exiting at line $LINENO, while running :${BASH_COMMAND}:\n:::\n"; exit' SIGINT SIGQUIT

eix-sync

demerge --record --comment "update-gentoo.sh-${VERSION} BEGIN"

emerge -Dtuv --newuse --keep-going @system $1
emerge -Dtuv --newuse --keep-going --with-bdeps=y @world $1
FEATURES="-ccache -distcc" MAKEOPTS="-j1" emerge -Dtuv --newuse --keep-going --with-bdeps=y @world $1

perl-cleaner --all
python-updater

revdep-rebuild
emaint -f all

eclean --destructive distfiles --fetch-restricted

demerge --record --comment "update-gentoo.sh-${VERSION} END"
