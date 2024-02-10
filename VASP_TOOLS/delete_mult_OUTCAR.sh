#!/bin/bash

# USE: delete_mult_OUTCAR.sh  directory

dir=$1;

if [ "$dir" == "" ]; then
    echo "USE: delete_mult_OUTCAR.sh directory"
    exit
fi

cdir=$(pwd); # will return here
dbg=0;

#echo
#echo "Don't use this code inside any other scripts!!!!"
#echo "This is taken care of automatically in the Script_ run now."
#echo


#    NOTES:
# 1. Delete multiple outcars for pack run relxations
# 2. Should be run in the vasp directory where the OUTCAR-n files are located
# 3. The last OUTCAR-n file is spared and OUTCAR is symlinked to it, i.e.,
#
#               OUTCAR  ----->  OUTCAR-nmax
#

###################################################################
function clean_up_and_exit() {
    rm -f lserr.txt;
    cd $cdir;
    exit
}

###################################################################
###################################################################
if [ $dbg -eq 1 ]; then
    echo "Directory: $dir"
fi
cd $dir

# look for OUTCAR link (in case this script has already been run)
if [ -h OUTCAR ]; then
    if [ $dbg -eq 1 ]; then
	echo "Found symlink OUTCAR. Script has already been run here. exiting."
    fi
    exit;
fi

n_outcars=$(ls 2> lserr.txt OUTCAR-* | wc -l);
none=$(cat lserr.txt | gawk '($1=="ls:" && $2=="cannot"){print 1}');

if [ "$none" == "1" ]; then
    if [ $dbg -eq 1 ]; then
	echo "none= "$none
	echo "No OUTCAR- files found."
    fi
    clean_up_and_exit;
fi

# special case if only OUTCAR-1 exists
if [ $n_outcars -eq 1 ]; then
    if [ $dbg -eq 1 ]; then
	echo "Special case, only OUTCAR-1 exits. Linking to OUTCAR."
    fi
    ln -sf OUTCAR-1 OUTCAR;
    clean_up_and_exit;
fi

last_outcar=OUTCAR-$n_outcars;
last_outcar_size=$(ls -l $last_outcar | gawk '{print $5}');

if [ $dbg -eq 1 ]; then
    echo "In directory: "$(pwd)
    echo "n_outcars= "$n_outcars;
    ls OUTCAR-*;
    echo "last_outcar= "$last_outcar  "  size= "$last_outcar_size;
fi

if [ "$last_outcar_size" == "" ]; then
    echo "Error finding last outcar size. last_outcar_size= "$last_outcar_size
    clean_up_and_exit;
fi

if [ $last_outcar_size -gt 0 ]; then
    # echo "removing all OUTCAR-n except $last_outcar";
    nlist=$(gawk --source 'BEGIN{for(i=1;i<NMAX;i++){printf("%d ",i);}}' -v NMAX=$n_outcars)
    # echo "nlist= "$nlist
    for N in $nlist; do
	if [ $dbg -eq 1 ]; then
	    echo "removing OUTCAR-"$N
	fi
	rm -f OUTCAR-$N;
    done
fi

if [ $dbg -eq 1 ]; then
    echo "Making symlink OUTCAR ---> OUTCAR-"$n_outcars;
fi
ln -sf OUTCAR-$n_outcars OUTCAR;

clean_up_and_exit ;

cd $cdir;

exit