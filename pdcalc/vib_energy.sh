#!/bin/bash

# Change this line only
BASE=/home/majzoube

if [ -d $BASE ]; then
#    echo "Using BASE= "$BASE "to set PDTOP"
    PDTOP=$BASE/src/pdcalc
    export AWKPATH=$AWKPATH:$BASE/src/pdcalc:$BASE/awkfiles
    ORDER=$BASE/awkfiles/poscar_order.awk
else
#    echo "Using HOME to set PDTOP"
    PDTOP=$HOME/src/pdcalc
    export AWKPATH=$AWKPATH:$HOME/src/pdcalc:$HOME/awkfiles
    ORDER=$HOME/awkfiles/poscar_order.awk
fi

script_name="vib_energy.sh"
script_version="1.2"
script_date="Mon 24 July 2017"

# v 1.2, 24 July 2017
#   add -e switch to use existing data in modes and ccar directories
#   to reconstruct the vibrational data file.
#

# default values
CONTCAR="CONTCAR";
cutoff=8.0; # default cutoff in cm-1
dbg=0;
existing="";
help=0;
nargs=$#;
IgnoreSoftModes=0;
inc=10;
isgas=0; # is this a gas molecule
namepat="";
OUTCAR="OUTCAR";
Tmax=100;

MODS=info/modes
CARS=info/ccar

declare SWITCH
while getopts "de:f:g:hC:c:T:u:Ii:p:" SWITCH; do
    case $SWITCH in
    C) cutoff=$OPTARG ;;
    c) CONTCAR=$OPTARG;;
    d) dbg=1 ;;
    e) existing=$OPTARG; OUTCAR=$MODS/$existing.mods.dat; CONTCAR=$CARS/ccar-$existing ;;
    f) OUTCAR=$OPTARG;;
    g) isgas=$OPTARG;;
    h) help=1 ;;
    p) namepat=$OPTARG; OUTCAR=OUTCAR-$namepat-dynamic; CONTCAR=CONTCAR-$namepat ;;
    T) Tmax=$OPTARG;;
    u) fu=$OPTARG;;
    i) inc=$OPTARG;;
    I) IgnoreSoftModes=1;;
    esac
done


if [ $help -eq 1 ] || [ $nargs -eq 0 ]; then
    echo
    echo "########################"
    echo "#      "$script_name
    echo "########################"
    echo
    echo "version "$script_version
    echo $script_date
    echo
    echo "use: "$script_name"  -[df:g:hC:c:T:u:Ii:]"
    echo "                       : denotes option requires an argument"
    echo
    echo "    -d --- debug (default off)"
    echo "    -h --- print this help message"
    echo
    echo "    -f -*- input file (default OUTCAR with linear response)"
    echo "    -c -*- input coresponding CONTCAR"
    echo
    echo "    -e -*- name of existing data in ./modes and ./ccar"
    echo "           e.g. NaOH_Bmmb"
    echo "           this will set -f ./modes/NaOH_Bmmb.dat"
    echo "           this will set -c ./ccar/ccar-NaOH_Bmmb"
    echo
    echo "    -p -*- name pattern e.g. NaOH_Bmmb"
    echo "           this will set -f OUTCAR-NaOH_Bmmb-dynamic"
    echo "           this will set -c CONTCAR-NaOH_Bmmb"
    echo
    echo "    -C -*- cutoff in cm-1 for imaginary modes (def $cutoff)"
    echo "    -u -*- number of formula units"
    echo
    echo "    -g --- is gas (default off)"
    echo "    -T -*- Tmax value"
    echo "    -i -*- temperature increment in degrees"
    echo
    echo "    -I --- ignore soft modes (careful!!)"
    echo "           WARN: this uses soft modes as real!"
    echo
    echo
    echo Eric Majzoub
    echo University of Missouri - St. Louis
    echo v 1.1 14 June 2013
    echo
    exit
fi

################################################################
################################################################

if [ "$existing" != "" ]; then
    if [ ! -s $CONTCAR ]; then
	echo "ERROR in vib_energy:  Can't find $CONTCAR"; exit 1;
    fi
    if [ ! -s $OUTCAR ]; then
	echo "ERROR in vib_energy:  Can't find $OUTCAR"; exit 1;
    fi
    fu=$(cat ./info/info.dat | gawk --source '($1==EX){print $5}' -v EX=$existing);
    if [ "$fu" == "" ]; then
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "FATAL ERROR: Could not find f.u. for structure $existing"
	echo
	echo "      Output of script will be incorrect!!!!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	exit 1;
    fi
    # echo "found fu= "$fu
fi

if [ -z $OUTCAR ]
 then
   echo "please enter OUTCAR using -f flag"
   exit
fi

if [ -z $fu ]
 then
   echo "please enter forumla units using -u flag"
   exit
fi


# call the free energy script
grep THz $OUTCAR | awk -v fu=$fu -v Tmax=$Tmax -v CUTOFF=$cutoff -v Tinc=$inc -v gas=$isgas -v ignoresoft=$IgnoreSoftModes -v debug=$dbg -f $PDTOP/free_energy.awk

exit 0
