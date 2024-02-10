#!/bin/bash

script_name="prep_vasp_runs.sh"
script_version="0.2"
script_date="Fri 03 Jun 2016"


#
# v 0.2  03 June 2015, add switch to control pct of low volume structures to keep
#
# version 0.1  29 Dec 2015
# E.H. Majzoub
#

# defaults
dbg=0;
help=0;
nargs=$#;
pct=0.75;
remove_unfinished_bs=0;
BASE=/home/majzoube


declare SWITCH
while getopts "dhp:r" SWITCH; do
    case $SWITCH in
    d) dbg=1 ;;
    h) help=1 ;;
    p) pct=$OPTARG ;;
    r) remove_unfinished_bs=1 ;;
    esac
done

if [ $help -eq 1 ] || [ $nargs -eq 0 ]; then
    echo
    echo "#############################"
    echo "#  "$script_name
    echo "#############################"
    echo
    echo "version "$script_version
    echo $script_date
    echo
    echo
    echo "use: "$script_name"  -[opts]"
    echo
    echo "    -d --- debug (default off)"
    echo "    -h --- print this help message"
    echo
    echo "    -p -*- use %p lowest volume structures for VASP calculations"
    echo "           (default is $pct)"
    echo
    echo "    -r --- remove unfinished .bs files and exit (won't start any VASP runs)."
    echo "           Currently running .bs runs will not be killed, you must kill"
    echo "           them by hand."
    echo
    echo
    echo Eric Majzoub
    echo University of Missouri - St. Louis
    echo
    exit
fi


##############################################################
#  BEGIN SCRIPT HERE
##############################################################

cdir=$(pwd);
TOP=${cdir##/*/}
filelist=$(ls *.bs)
Nfiles=$(ls *.bs | wc -l | gawk '{print $1}')
echo "Nfiles= "$Nfiles
# # extract lowest pct% volume structures
pct=$(gawk --source 'BEGIN{c=0.90*b; printf("%d",int(c));}'  -v b=$Nfiles)
if [ $dbg -eq 1 ]; then
    echo "Using pct= "$pct;
fi

if [ $Nfiles -eq 0 ]; then
    echo "It looks like this is not a PEGs run directory. Exiting..."
    exit;
fi

if [ $dbg -eq 1 ]; then
    echo "cdir= " $cdir
    echo "TOP= "$TOP
    echo "filelist= "$filelist
    echo "Nfiles= "$Nfiles
fi

############################################
if [ $remove_unfinished_bs -eq 1 ]; then
    for file in *.bs; do
	finished=$(cat $file | grep involuntary | wc -l);
	if [ $finished -eq 0 ]; then
	    echo "$file is not finished ...  removing it"
	    rm -f $file;
	fi
    done
    exit
fi


# Check to see if all the PEGS runs are finished
pegs_finished=1;
for file in $filelist; do
    flag=$(cat $file | grep invol | wc -l | gawk '{print $1}');
    if [ $flag -eq 0 ]; then
	echo "Job "$file " still running...";
	tail -1 $file;
	pegs_finished=0;
    fi
done

if [ $pegs_finished -eq 0 ]; then

    echo "PEGS not finished..."
    exit

else

    echo
    # count number of runN files
    Nrunfiles=$(find ./ -name "run*" | wc -l);
    echo "Found "$Nrunfiles "runx files"
    Nplus1=$((Nrunfiles+1));
    echo "Using "$Nplus1 "for new run directory extension"
    rundir="run"$Nplus1;
    mkdir $rundir;
    mkdir $rundir/vaspruns;

    volstep=10; volmin=50;
    $BASE/src/VASP_TOOLS/process_bs_orth_dens.sh 10000 | sort -n -k 5 > sort.dat;
    cat sort.dat | grep -v Getting | head -n$pct | gawk '{print $1}' > files_to_extract.dat;
    for f in `cat files_to_extract.dat`; do
	# echo "f= "$f
	fnumpre1=${f%%.bs};
	# echo "fnumpre1= "$fnumpre1
	fnum=${fnumpre1##*_}
	# echo "fnum= "$fnum
	pcar="POSCAR-n"$fnum
	mv $pcar $rundir/vaspruns/
    done

    cp $BASE/src/VASP_TOOLS/vasp_cyc_concurrent.sh $rundir/vaspruns/v_cyc_$TOP.sh;
    rm -f POSCAR* files_to_extract.dat sort.dat;
    mv out*.bs $rundir;
    cp PACK_OPTIONS input.in $rundir;
    cd $rundir/vaspruns/;
    echo "Starting vasp runs... "
    nohup ./v_cyc_$TOP.sh >& v.cyc.$TOP.out &
    cd $cdir;
    rm $TOP*.sh* PR*;

fi



exit
