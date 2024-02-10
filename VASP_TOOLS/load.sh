#!/bin/sh

QUEUE=$1

# Old qhost code
# qhost | gawk --source 'BEGIN{load=0;}(NF==8){load+=$4}END{print load}'

# echo "QUEUE= "$QUEUE
/usr/bin/squeue -o "%i %.9P %.8j %.u %.t %.M %.C %.D %.r" | grep $QUEUE | gawk 'BEGIN{cpu=0;}($5=="R"){cpu += $7;}END{printf("%d ",cpu);}'

exit
