#!/bin/bash
cat /dev/null > ~/.bash_history && history -c && kill -9 $PPID