#!/bin/sh

gamesslog=$1;

if [ "$gamesslog" == "" ]; then
    if [ -s OSZICAR ]; then
	cat OSZICAR | awk '($0~"F"){print $1,$3}' | xgraph -P &
    else
	echo "No files worth plotting were found..."
	exit
    fi
else
    cat $gamesslog | grep ENERGY | grep FINAL | gawk '{print NR,$5}' | xgraph -P &
fi


