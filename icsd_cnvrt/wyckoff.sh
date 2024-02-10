#!/bin/bash

if [ -z "$CVT_TOP" ]; then
    export CVT_TOP=/home/ehm/src/icsd_cnvrt
fi
#echo "CVT_TOP="$CVT_TOP

if [ $# -eq 0 ]; then
    echo
    echo "####################"
    echo "#    wyckoff.sh    #"
    echo "####################"
    echo
    echo "Version 1.4, 16 Jan 2006"
    echo
    echo "use: wyckoff.sh  -s \"spgrp\" [-f infile] [-x x -y y -z z] "
    echo 
    echo
    echo "    -s --- space group (default P 1)"
    echo "    -f --- file with x y z input"
    echo "    -x --- x atom position"
    echo "    -y --- y atom position"
    echo "    -z --- z atom position"
    echo
    echo "Notes:"
    echo "  1. atom positions can be input as fractions,"
    echo "     such as: 1/2, 2/3, 1/8, etc..."
    echo
    echo "  2. different space group settings can be accessed with,"
    echo "     -s \"88:1\"       or     -s \"88:2\""
    echo "     -s \"I41/a:1\"    or     -s \"I41/a:2\""
    echo
    echo
    echo Eric Majzoub
    echo Sandia National Laboratories
    echo 29 june 2005
    echo updated on 06 july 2005
    echo
    exit
fi

###########################################
# find the executables and set their paths
if [ ! -e /usr/bin/which ]; then
    echo "No file /usr/bin/which found. You must set"
    echo "executable locations in shell file by hand."
    exit 1
fi
SGINFO=`which sginfo`
if [ ! -e $SGINFO ]; then
    echo "WARNING: Executable 'sginfo' not found."
    SGINFO=$CVT_TOP/bin/sginfo
    echo "using "$SGINFO
fi
AWK=`which awk`
if [ ! -e $AWK ]; then
    echo "WARNING: Executable 'awk' not found."
    AWK=/usr/local/bin/awk
    echo "using "$AWK
fi
BC=`which bc`
if [ ! -e $BC ]; then
    echo "WARNING: Executable 'bc' not found."
    BC=/usr/local/bin/bc
    echo "using "$BC
fi
SORT=`which sort`
if [ ! -e $SORT ]; then
    echo "WARNING: Executable 'sort' not found."
    SORT=/usr/local/bin/sort
    echo "using "$SORT
fi
UNIQ=`which uniq`
if [ ! -e $UNIQ ]; then
    echo "WARNING: Executable 'uniq' not found."
    UNIQ=/usr/local/bin/uniq
    echo "using "$UNIQ
fi
CAT=`which cat`
if [ ! -e $CAT ]; then
    echo "WARNING: Executable 'cat' not found."
    CAT=/usr/local/bin/cat
    echo "using "$CAT
fi
RM=`which rm`
if [ ! -e $RM ]; then
    echo "WARNING: Executable 'rm' not found."
    RM=/usr/local/bin/rm
    echo "using "$RM
fi


# defaults
file=input.in
spgp="P 1"
x=-10;
y=-10;
z=-10;

declare SWITCH
while getopts "x:y:z:s:f:" SWITCH; do
    case $SWITCH in
    f) file=$OPTARG ;;
    s) spgp=$OPTARG ;;
    x) x=$OPTARG ;;
    y) y=$OPTARG ;;
    z) z=$OPTARG ;;
    esac
done

function get_equiv {
    $SGINFO "$spgp" -allxyz | $AWK -v X=$x -v Y=$y -v Z=$z -f $CVT_TOP/wyckoff.awk ;
#    $CAT tmpout | $AWK -f $CVT_TOP/three2one.awk | $SORT -n |  $UNIQ;
    $CAT tmpout | $AWK -f $CVT_TOP/three2one.awk | awk -f $CVT_TOP/trim_uniq.awk;
    $RM -f tmpout
}

if [ "$x" != -10 ] || [ "$y" != -10 ] || [ "$z" != -10 ]; then
    get_equiv $x $y $z
    exit
fi

while read x y z; do
    if [ -z $x ] || [ -z $y ] || [ -z $z ]; then
	echo "hit empty line at end of file"
	exit
    fi
    echo equiv postions for input atom: $x $y $z;
    get_equiv $x $y $z
done < $file

exit
