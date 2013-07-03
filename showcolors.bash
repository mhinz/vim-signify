#!/bin/bash

if ! hash tput 2>/dev/null; then
    echo "I cannot find the 'tput' program." \
        'You might find it in one of the ncurses packages.' >&2
    exit 1
fi

for i in {0..255}; do
    tput setab $i && echo -n " $i "
done

tput sgr0
echo
