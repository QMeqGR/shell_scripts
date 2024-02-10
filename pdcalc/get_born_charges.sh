#!/bin/bash

# This script is to be run in a directory
# containing both the OUTCAR and CONTCAR
# for a run with the VASP_setup.sh script
# with the "-m 12" (born) switch set.
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


script_name="get_born_charges.sh"
script_date="Thu Aug 20 10:40:47 CDT 2015"
script_vers="0.2"

# v1 Thu Aug 20 10:40:47 CDT 2015

##############################################################
##############################################################
TMP_FILES="tmp.pcar tmp.born.awk tmp.column.1 tmp.column.2 \
tmp.ave.out tmp.ave.awk tmp.born_eff_charges.out"
rm -f $TMP_FILES

# default variables
contcar="CONTCAR";
dbg=0;
help=0;
outcar="OUTCAR";


declare SWITCH
while getopts "C:dhO:" SWITCH; do
    case $SWITCH in
    C) contcar=$OPTARG ;;
    d) dbg=1 ;;
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

n_born=$(cat $outcar | grep "BORN EFFECTIVE CHARGES" | wc -l)

if   [ $n_born -eq 0 ]; then
    echo "No born effective charges found in OUTCAR. Exiting."
    cleanup;
    exit
elif [ $n_born -eq 1 ]; then
    echo "Looks like a phonon run."
elif [ $n_born -eq 2 ]; then
    echo "Looks like a LCALCEPS run."
else
    echo "n_born is not 0, 1, or 2. What the hell? Exiting."
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

cat > tmp.born.awk <<EOF

BEGIN{
debug=0;
born_set=0;
read=0;
read_ion=0;
# set on command line
#  nbornset

}

(\$10=="NIONS"){nions=\$12;}
(\$0 ~ "BORN EFFECTIVE CHARGES"){
born_set++;
line_start=NR;
#printf("born_set= %d   nbornset= %d\n",born_set,nbornset);
if ( born_set == nbornset ){
read=1;
#printf("reading born set %d\n",born_set);
} else {
read=0;
}
}
(read==1 && \$1=="ion"){
read_ion=\$2;
n=\$2;
}
(read==1 && read_ion>0 && \$1==1){
xx[n]=\$2; xy[n]=\$3; xz[n]=\$4;
}
(read==1 && read_ion>0 && \$1==2){
yx[n]=\$2; yy[n]=\$3; yz[n]=\$4;
}
(read==1 && read_ion>0 && \$1==3){
zx[n]=\$2; zy[n]=\$3; zz[n]=\$4;
read_ion=0;
if ( n == nions ){read==0;}
}

END{

for(i=1;i<nions+1;i++){
if ( debug == 1 ){
 printf("ion %d\n",i);
 printf("%10.4f%10.4f%10.4f\n",xx[i],xy[i],xz[i]);
 printf("%10.4f%10.4f%10.4f\n",yx[i],yy[i],yz[i]);
 printf("%10.4f%10.4f%10.4f\n",zx[i],zy[i],zz[i]);
}
trace=xx[i]+yy[i]+zz[i];
printf("ion %4d  ave_trace= %8.4f\n",i,trace/3);
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

if [ $n_born -eq 1 ]; then
    cat $outcar | igawk -f ./tmp.born.awk -v nbornset=1 | gawk '(NF>0){print $NF}' > tmp.column.2;
else
#    echo "excluding local field effects"
#    cat OUTCAR | igawk -f ./tmp.born.awk -v nbornset=1;
    if [ $dbg -eq 1 ]; then
	echo "including local field effects"
	cat $outcar | igawk -f ./tmp.born.awk -v nbornset=2;
    fi
    cat $outcar | igawk -f ./tmp.born.awk -v nbornset=2 | gawk '(NF>0){print $NF}' > tmp.column.2;
fi

paste tmp.column.1 tmp.column.2 > tmp.born_eff_charges.out
cat tmp.born_eff_charges.out | igawk -f ./tmp.ave.awk > tmp.ave.out
cat tmp.ave.out >> tmp.born_eff_charges.out

cat tmp.born_eff_charges.out

# clean up
rm -f $TMP_FILES

exit

