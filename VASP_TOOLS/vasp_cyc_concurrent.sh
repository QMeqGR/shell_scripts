#!/bin/sh

# Run VASP optimizations on POSCAR_n files concurrently

# version 1.1    22 June 2017


# default settings
dbg=0;
Fdef=3;
kpt=2;
hrs=12; # This would be for each vasp isif=3 relaxation
workingdir=$(pwd);


# Check for who is running and set QUEUE
IAM=$(whoami);
if [ "$IAM" == "majzoube" ]; then
    QUEUE="-q doe_ameslab";
    nproc=12;
else
    QUEUE="-q doe_ameslab";
    nproc=6;
fi

##################################################
##################################################
# functions
##################################################
function get_rand_tag (){
    tagpre1=$(ls Script* | gawk '{print $1}');
    tagpre2=${tagpre1%%.sh}
    tagpre3=${tagpre2##*_}
    if [ $dbg -eq 1 ]; then
        echo "finding random number tag..."
        echo "tagpre1= "$tagpre1
        echo "tagpre2= "$tagpre2
        echo "tagpre3= "$tagpre3
    fi
    RANDtag=$tagpre3
}


################################################
################################################
for file in POSCAR-n*; do 

    num=${file##POSCAR-n}
    echo "Submitting job for file "$file " structure number... "$num

    dirname=P_$num; skip=0;
    if [ -e $dirname ]; then
	echo "Directory "$dirname " exists. Skipping!"
	skip=1;
    else
	mkdir $dirname
    fi
    
    if [ $skip -eq 0 ]; then
	cd $dirname;
	cdir=$(pwd);
	top=${cdir##*/}; # name for Script_$top.sh	
	cp -f ../$file ./POSCAR;
	## vasp_setup -f POSCAR -k $kpt -p $nproc -F $Fdef $QUEUE;
	vasp_setup -f POSCAR -k $kpt -p $nproc -t $hrs $QUEUE;
	get_rand_tag;
	nohup ./Script_P_$num"_"$RANDtag.sh >& script.P_$num"_"$RANDtag".out" &
	cd $workingdir;
    else
	echo "Skipping... "$num
    fi

    if [ $skip -eq 1 ]; then
	sleep 0;
    else 
	sleep 20; # give job time to show up on qhost
    fi

done

echo " +++ vasp_cyc_conc Done +++"

exit
