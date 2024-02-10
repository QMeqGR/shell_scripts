#!/bin/sh
# This script is part of VASP TOOLS

BASE=/home/ehm
VT_TOP=$BASE/src/VASP_TOOLS
PATH=$PATH:$VT_TOP/bin

# process vasp cycle runs
# E.H. Majzoub, University of Missouri, 2015
#

VERSION=1.2

# V 1.2, 12 Jun 2017
#
########################################
dbg=0;


# awkfiles
CCAR_INFO=$VT_TOP/awkfiles/contcar_info.awk
PCAR_2V4=$VT_TOP/awkfiles/poscar_2v4.awk
HIST=$VT_TOP/awkfiles/histogram.awk

if [ $dbg -eq 1 ]; then
    echo "CCAR_INFO= "$CCAR_INFO
fi

######################################################################
#   FUNCTIONS
######################################################################
function print_use(){
    echo
    echo "Use: $ process_cyc_conc_files.sh base1 base2 (example, issue in ~/pack for ~/pack/base1, etc.)"
    echo "or"
    echo "Use: $ process_cyc_conc_files.sh (issue in dir with P_n directories)"
    echo

    exit
}

######################################################################
function autodetectV5 {
    poscar=$1;
    if [ ! -s $poscar ]; then
        isV5=0;
        echo "File "$poscar " is empty. Exiting."
        exit
    else
        isV5=`cat $poscar | awk '(NR==6 && $0!~"[0-9]"){print 1}(NR==6 && $0~"[0-9]"){print 0}'`;
    fi
}

######################################################################
function get_data(){

tdir=$(pwd);

for dir in P_*; do

    if [ -e $dir/1run ]; then
	nmax=$(ls $dir/*run | wc -l | gawk '{print $1}')
    else 
	continue;
    fi

    if [ $dbg -eq 1 ]; then
	echo "In directory: "$dir
	echo "--- found   nmax= "$nmax
    fi

    if [ $nmax -ge 1 ]; then

	sym=$($BASE/bin/max_sym $dir/CONTCAR)
	energy=$(cat $dir/OUTCAR-$nmax | grep "free  energy" | tail -1 | gawk '{printf("%.3f ",$5);}')


	autodetectV5 $dir/CONTCAR;
	if [ $isV5 -eq 1 ]; then
	    cat $dir/CONTCAR | igawk -f $PCAR_2V4 > $dir/tmp.proc.cyc.conc.v4;
	else
	    cp $dir/CONTCAR $dir/tmp.proc.cyc.conc.v4;
	fi

	if [ $dbg -eq 1 ]; then echo "calculating density..."; fi
	dens=$(cat $dir/tmp.proc.cyc.conc.v4 | igawk -f $CCAR_INFO | grep Density | gawk '{printf("%.3f ",$3);}')
	orth=$(cat $dir/tmp.proc.cyc.conc.v4 | igawk -f $CCAR_INFO | grep "orth  =" | gawk '{printf("%.4f ",$3);}')
	vol=$(cat $dir/tmp.proc.cyc.conc.v4  | igawk -f $CCAR_INFO | grep Vol | grep -v orth | gawk '{printf("%.2f ",$3);}');
	echo $dir " z " $energy " " $vol " " $dens " " $orth " " $sym;

	if [ $dbg -eq 1 ]; then 
	    echo "--- found   isV5= "$isV5
	    echo "--- found    sym= "$sym;
	    echo "--- found energy= "$energy;
	    echo "--- found   orth= "$orth;
	    echo "--- found    vol= "$vol;
	    echo "--- found   dens= "$dens;
	else
	    rm $dir/tmp.proc.cyc.conc.v4;
	fi

    fi

done
}



######################################################################
# SCRIPT BEGINS HERE
######################################################################

cdir=$(pwd)

if [ "$(ls | grep P_)" != "" ]; then
    echo "Looks like you have requested the current directory. Correct? [y/n]"
    read ans
    if [ "$ans" == "y" ] || [ "$ans" == "Y" ]; then
	vasprun_dirs=$(pwd)
	echo "vasprun_dirs= "$vasprun_dirs
    else
	print_use;
    fi
elif  [ "$1" == "a" ]; then
    vasprun_dirs=$(find ./ -name vaspruns);
    echo "vasprun_dirs= "$vasprun_dirs
    echo
    echo "Find energies for all scripts? [y/n]"
    read ans
    if [ "$ans" == "y" ] || [ "$ans" == "Y" ]; then
	echo "OK, doing all vasprun directories"
    else
	print_use;
    fi
elif [ $# -gt 0 ]; then
    rm -f tmp.find.vaspdirs
    search_dirs=$@
    for ddd in $search_dirs; do
	find ./$ddd -name vaspruns >> tmp.find.vaspdirs
    done
    vasprun_dirs=$(cat tmp.find.vaspdirs)
    echo "Find energies for all these: "$vasprun_dirs
    echo "Enter [y/n]:"
    read ans
    if [ "$ans" == "y" ] || [ "$ans" == "Y" ]; then
	echo "OK, doing all those vasprun directories"
    else
	print_use;
    fi
    rm -f tmp.find.vaspdirs
else
    print_use;
fi

echo "vasprun_dirs= $vasprun_dirs";

for vdir in $vasprun_dirs; do

    cd $vdir;
    echo $vdir;

    echo "dir   Z   eV/fu vol density orth tol sg symm" | tee tmp.junk.dat
    if [ $dbg -eq 1 ]; then
	get_data  | tee tmp.junk.dat
    else
	get_data | sort -n -k 3 >> tmp.junk.dat
    fi

    cat tmp.junk.dat | column -t | tee energies.dat
    rm -f tmp.junk.dat

    cat energies.dat | igawk -f $HIST -v col=3  > energ_hist.dat;

    # return to base directory
    cd $cdir;
done


exit



