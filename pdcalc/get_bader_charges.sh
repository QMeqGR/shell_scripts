#!/bin/bash

# This script is to be run in a directory
# containing both the OUTCAR and CONTCAR
# for a run with the VASP_setup.sh script
# with -m 13 (bader charge)
#
# It should also work with a phonon run.
#
# This script is called by pd_prep_data.sh in the pdcalc_v2 code.
#
# E.H. Majzoub
# UM - St. Louis
# 20 August 2015
# 

# change only this line for a new cluster
BASE=/home/majzoube

if [ -d $BASE ]; then
#    echo "Using BASE= $BASE to set PDTOP"
    PDTOP=$BASE/src/pdcalc
    AWKFILES=$BASE/awkfiles
    export AWKPATH=$AWKPATH:$BASE/src/pdcalc:$BASE/awkfiles
    ORDER=$BASE/awkfiles/poscar_order.awk

    GETVER=$AWKFILES/poscar_get_version.awk
    C2V4=$AWKFILES/poscar_2v4.awk
else
#    echo "Using HOME to set PDTOP"
    PDTOP=$HOME/src/pdcalc
    AWKFILES=$HOME/awkfiles
    export AWKPATH=$AWKPATH:$HOME/src/pdcalc:$HOME/awkfiles
    ORDER=$HOME/awkfiles/poscar_order.awk

    GETVER=$AWKFILES/poscar_get_version.awk
    C2V4=$AWKFILES/poscar_2v4.awk
fi


script_name="get_bader_charges.sh"
script_date="Thu 14 Sept 2017"
script_vers="0.2"

# v 0.2  14 sept 2017

##############################################################
##############################################################
TMP_FILES="tmp.pcar tmp.bader.awk tmp.column.1 tmp.column.2 \
tmp.ave.out tmp.ave.awk tmp.bader_eff_charges.out tmp.zvals \
tmp.column.zvals tmp.elms tmp.intermediate"
rm -f $TMP_FILES

# default variables
baderdat=""
contcar="CONTCAR";
dbg=0;
help=0;
outcar="OUTCAR";


declare SWITCH
while getopts "C:dD:hO:" SWITCH; do
    case $SWITCH in
    C) contcar=$OPTARG ;;
    d) dbg=1 ;;
    D) baderdir=$OPTARG; baderdat=$baderdir/bader.dat; ;;
    h) help=1 ;;
    O) outcar=$OPTARG ;;
    esac
done

if [ $help -eq 1 ]; then
    echo
    echo "Command line options:"
    echo
    echo "-d -- debug output"
    echo "-h -- show help"
    echo
    echo "-D -*- path to bader directory"
    echo "-C -*- CONTCAR file (default CONTCAR)"
    echo "-O -*- OUTCAR file (default OUTCAR)"
    echo
    exit
fi

###################################################

function cleanup () {
    rm -rf $TMP_FILES;
}

###################################################
if [ ! -s $outcar ]; then
    echo "No OUTCAR found with size > 0. Exiting."
    exit
fi
if [ ! -s $contcar ]; then
    echo "No CONTCAR found with size > 0. Exiting."
    exit
fi

if [ $dbg -eq 1 ]; then
    echo "Using outcar= "$outcar
    echo "Using contcar= "$contcar
fi

pcar_ver=$(cat $contcar | igawk -f $GETVER)
echo "pcar_ver= "$pcar_ver

if   [ $pcar_ver -eq 4 ]; then
    cp $contcar tmp.pcar;
elif [ $pcar_ver -eq 5 ]; then
    cat $contcar | igawk -f $C2V4 > tmp.pcar;
else
    echo "Can't determine CONTCAR version. Exiting"
    cleanup;
    exit
fi

n_bader=$(cat $baderdat | grep "CHARGE" | wc -l)

if   [ $n_bader -eq 0 ] || [ ! -e $baderdat ]; then
    echo "No bader charges found or no bader.dat. Exiting."
    cleanup;
    exit
fi

###################################################
# make the temporary awk files

cat > tmp.ave.awk <<EOF

BEGIN{
debug=0;

NMAX=10; # max kinds of atoms
elm[NMAX];
n_elm[NMAX];
Zsum[NMAX];
elm_count=0;

}

(NF==2){
 e=\$1; z=\$2;
 if ( debug ) printf("reading NR: %d :: %s\n",NR,\$0);

 matchflag=0; matchi=-1;
 for(i=1;i<NMAX+1;i++){
   if ( e == elm[i] ){ matchflag=1; matchi=i; }
 }
 if ( matchflag==1 ){
   if ( debug ) printf("existing elm %s\n",e);
   Zsum[matchi] += z; n_elm[matchi]++;
 } else {
   if ( debug ) printf("adding elm %s\n",e);
   elm[++elm_count]=e; Zsum[elm_count] += z; n_elm[elm_count]++;
 }

}

END{
 if ( debug ) printf("found %d elements\n",elm_count);
 for(i=1;i<elm_count+1;i++){
  if ( debug ) printf("i elm[i] Zsum[i] n_elm[i] = %5d%5s%10.4f%5d\n",i,elm[i],Zsum[i],n_elm[i]);
  printf("Z_%-2s (ave)= %7.4f\n",elm[i],Zsum[i]/n_elm[i]);
 }
}

EOF

###################################################
# Start here
###################################################

zlist=$(cat tmp.pcar | gawk --source '(NR==1){for(i=2;i<NF+1;i++){printf("%d ",$i);}}');
echo "zlist= "$zlist;
# make this an array to reference
ZLIST=($zlist)

num_list=$(cat tmp.pcar | gawk --source '(NR==6){print $0}');
echo "num_list= "$num_list
num_num=$(echo $num_list | wc | gawk '{print $2}')
if [ $dbg -gt 0 ]; then
    echo "num_num= "$num_num
fi

# Fill the array Z_ion
declare -a Z_ion ### "declare -A Z_ion" gives an error ??
count=-1;
for num in $num_list; do
    count=$((count+1))
    loop_list=$(gawk --source 'BEGIN{for(i=1;i<N+1;i++){printf("%d ",i);}}' -v N=$num)
    if [ $dbg -gt 0 ]; then
	echo "loop_list "$count" = "$loop_list
    fi
    for loop_i in $loop_list; do
	ion_count=$((ion_count+1))
	Z_ion[$ion_count]=${ZLIST[$count]}
	# echo "Z_ion["$ion_count"]= "${ZLIST[$count]}
	elm=$(gawk -f awklib.awk --source 'BEGIN{printf("%s", ztoelm(Z) ); }' -v Z=${ZLIST[$count]} )
	if [ $dbg -eq 1 ]; then
	    gawk --source 'BEGIN{printf("Z_ion[%3d]= %s\n",ION,ELM);}' -v ION=$ion_count -v ELM=$elm;
	fi
	gawk --source 'BEGIN{printf("%s\n",ELM);}' -v ELM=$elm >> tmp.column.1
    done
done

echo "n_bader= "$n_bader
if [ $n_bader -gt 1 ]; then
    bader_nat=$(cat $baderdat | gawk --source '($1~"[1234567890]"){print $0}' | wc -l);
    cat $baderdat | gawk --source '($1~"[1234567890]"){print $5}' > tmp.column.2;
fi

cat $outcar  | grep VRHFIN | gawk -F= '{print $2}' | gawk -F: '{print $1}' > tmp.elms;
cat $outcar | gawk --source '($1=="POMASS" && $4=="ZVAL"){print $6}' > tmp.zvals;

line=0; rm -f tmp.column.zvals
for nn in $num_list; do
    line=$((line+1))
#    echo "line= "$line "  nn="$nn
    nnnn=$(gawk --source 'BEGIN{for(i=0;i<NN;i++){printf("%d ",i);};}' -v NN=$nn;)
#    echo "nnnn= "$nnnn
    for nnn in $nnnn; do
	cat tmp.zvals | gawk --source '(NR==N){print $0}' -v N=$line >> tmp.column.zvals
    done
done

paste tmp.column.1 tmp.column.2 tmp.column.zvals > tmp.intermediate
#cat tmp.intermediate
#echo
cat tmp.intermediate | gawk '{printf("%5s%10.4f\n",$1,$3-$2);}'> tmp.bader_eff_charges.out
cat tmp.bader_eff_charges.out | igawk -f ./tmp.ave.awk > tmp.ave.out
cat tmp.ave.out >> tmp.bader_eff_charges.out

cat tmp.bader_eff_charges.out

# clean up
rm -f $TMP_FILES

exit

