#!/bin/bash

script_name="pd_calc.sh"
script_version=1.0
script_date="11 Jan 2014"

# Cluster directory
BASE=/home/majzoube

# check if running on cluster or desktop
if [ -d $BASE ]; then
    echo "Using BASE= "$BASE "to set PDTOP"
    PDTOP=$BASE/src/pdcalc
    export AWKPATH=$AWKPATH:$BASE/src/pdcalc:$BASE/awkfiles
    ORDER=$BASE/awkfiles/poscar_order.awk
else
    echo "Using HOME to set PDTOP"
    PDTOP=$HOME/src/pdcalc
    export AWKPATH=$AWKPATH:$HOME/src/pdcalc:$HOME/awkfiles
    ORDER=$HOME/awkfiles/poscar_order.awk
fi


OCT=`which octave`;

#############################################
# defaults
help=0;
outfile="";

PD_INPUT=data.in;

#############################################
declare SWITCH
while getopts "ho:" SWITCH; do
    case $SWITCH in
    h) help=1 ;;
    o) outfile=$OPTARG ;;
    esac
done

if [ $help -eq 1 ]; then
    echo
    echo "#######################"
    echo "#    "$script_name
    echo "#######################"
    echo
    echo "version: "$script_version
    echo "last update: "$script_date
    echo
    echo "use: $script_name [options]"
    echo
    echo "    -h --- show this help screen"
    echo "    -o -*- output file name"
    echo "           (default is to name them out_001.txt, _002.txt...)"
    echo 
    exit
fi

if [ "$outfile" == "" ]; then
    nout=$(ls out_*.txt 2> /dev/null | wc -l);
    n=$((nout+1));
    nn=$(gawk --source 'BEGIN{printf("%03d",N);}' -v N=$n);
    outfile=out_$nn.txt;
    echo "Using outfile= "$outfile
fi
echo "Calling pd_calc.m ..."
echo "Saving $PD_INPUT to header of output file..."
echo "#########################################" > $outfile;
echo "#  pd_calc wrapper script, $script_version" >> $outfile;
echo "#  E. Majzoub Feb 2014                   " >> $outfile;
echo "#########################################" >> $outfile;
echo "*II ( use:  | awk '(\$1==\"*I\"){print \$0}' | sed 's/*I //' > $PD_INPUT )" >>$outfile;
cat $PD_INPUT | igawk '{print "*I ",$0}' >> $outfile;
echo "*II END VERBATIM $PD_INPUT -----------" >> $outfile;

echo "Checking for all .dat thermo files..."
thrm_list=$(cat $PD_INPUT | gawk --source '($1=="phase"){read=1;line=NR;}($1=="end"){read=0;}(read==1 && NR>line){print $1}');
#echo "thrm_list= "$thrm_list
for file in $thrm_list; do
    if [ ! -s $file.dat ]; then
	echo "No file! >>> $file.dat ----> using MODS and CARS files with -I -i 1 -T 2000."
	$PDTOP/vib_energy.sh -e $file -I -i 1 -T 2000 > $file.dat;
	if [ $? -eq 1 ]; then
	    echo "!! Error !!: vib_energy.sh failed for $file! Investigate!"
	fi
    fi
done
echo "####################################################"
echo "Note: Files needed for recreating .dat are:"
echo "(1) modes (2) ccar (3) entry in info.dat (for num f.u.)"
echo "####################################################"

###################
# Start the Octave script
$OCT -qf $PDTOP/pd_calc.m | tee -a $outfile

exit
