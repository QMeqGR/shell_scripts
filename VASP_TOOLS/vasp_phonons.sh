#!/bin/sh

script_name="vasp_phonons.sh"
script_version="1.2"
script_date="07 Apr 2014"

# Changes:
#
# v 1.2 -- change name of the script (formerly phonon_xbsa)
#          and add features
# v 1.1 -- add vasp options
# v 1.0 -- first version
#

AWKFILES=$HOME/awkfiles
PHON_AWK=outcar_phonons_vasp5.awk
V4V5=poscar_2v4.awk
P2vis=poscar2vis.awk

# default values
apos_infile="apos.dat";
catTHz=0;
dbg=0;
help=0;
gobabyphonons=0;
outcar_infile="OUTCAR";
modnum=-1;
modfollow=0;
nargs=$#;
poscar_infile="CONTCAR";
infile="phonons.out";
vaspphonons=0;
viewxbsa=0;
catdisps=0;

#############################################
declare SWITCH
while getopts "a:cC:o:p:df:hM:X:" SWITCH; do
    case $SWITCH in
    a) apos_infile=$OPTARG; vaspphonons=0; gobabyphonons=1 ;;
    c) catTHz=1; vaspphonons=1; ;;
    C) catdisps=1; modnum=$OPTARG; vaspphonons=1; ;;
    d) dbg=1 ;;
    f) infile=$OPTARG; gobabyphonons=1; ;;
    h) help=1 ;;
    o) outcar_infile=$OPTARG; vaspphonons=1; ;;
    p) poscar_infile=$OPTARG; vaspphonons=1; ;;
    X) modnum=$OPTARG; vaspphonons=1; viewxbsa=1; ;;
    M) modfollow=1; vaspphonons=1; modnum=$OPTARG; ;;
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
    echo "use: "$script_name"  -[a:C:df:ho:p:M:X:]"
    echo "                       : denotes option requires an argument"
    echo
    echo "    -h --- show this help list"
    echo "    -d --- debug (default off)"
    echo
    echo "     ######## Gobaby phonon options #########"
    echo "    -f --- gobaby phonons file name (default phonons.out)"
    echo "    -a --- apos.dat input file name (default apos.dat)"
    echo
    echo
    echo "     #######  VASP phonon options  #########"
    echo "    -c --- cat THz modes from OUTCAR and exit"
    echo "    -o -*- outcar file (default OUTCAR)"
    echo "    -p -*- poscar input file (default CONTCAR)"
    echo "           (makes apos.dat if not working with vasp output)"
    echo
    echo "     The mode number can be input with any of the"
    echo "     following options:"
    echo "    -X -*- create XBSA in.bs and in.mv for mode m"
    echo "    -M -*- follow mode number m and produce POSCAR"
    echo "    -C -*- cat displacements for mode number m"
    echo 
    echo
    echo "    Note: The xbsa input file must be named in.bs "
    echo
    echo Eric Majzoub
    echo 31 Jan 2009
    echo
    exit
fi


##########################################
##########################################

function clean_up () {
    rm -f tmp.modfollow.dat;
    rm -f tempfile.poscar_cnvrt.POSv4;
    rm -f tmp.* oct.in;
}
function clean_bs () {
    rm -f in.bs in.mv;
}

function make_awkfile () {

cat > tmp.phonon.awk <<EOF

BEGIN{
  print_flag=0;
  cnt=0;
  j=0;
}

(NF==3){ at[3*cnt+0]=\$1; at[3*cnt+1]=\$2; at[3*cnt+2]=\$3; cnt++; }
(NF==7){

    if ( \$1==1 ) { printf("\nframe\n"); }

    x=at[3*j+0]+\$2;
    y=at[3*j+1]+\$3;
    z=at[3*j+2]+\$4;
  
    printf("%.16f %.16f %.16f ",x,y,z);
    j++;
    if ( j==cnt ) j=0;
    
}


END{

#  printf("Read %d atoms\n",cnt);

}

	
EOF

}

##########################################
##########################################


if [ ! -s $poscar_infile ]; then
    echo $poscar_infile " is empty. Exiting"
    exit
fi

if [ $gobabyphonons -eq 1 ] || [ $viewxbsa -eq 1 ]; then
    cat $apos_infile | awk '(NR>7 && NF==3){print $0;}' > tmp.phonon.dat ;
    nat=`cat tmp.phonon.dat | wc | awk '{print $1}'`;
    echo "Found number of atoms: "$nat
    cat $infile | awk '(NF==7){print $0;}' >> tmp.phonon.dat ;
    make_awkfile ;
    cat tmp.phonon.dat | awk -f tmp.phonon.awk > tmp.frames.dat ;
    mv -f tmp.frames.dat in.mv;
    rm -f tmp.phonon.*;
fi

if [ $vaspphonons -eq 1 ] && [ $catTHz -eq 1 ]; then
    cat $outcar_infile | grep THz;
    clean_up; clean_bs;
    exit;
fi


if [ $vaspphonons -eq 1 ] && [ $catdisps -eq 0 ]; then
    echo "Getting phonon mode="$modnum " from "$outcar_infile
    cat $outcar_infile | igawk -f $AWKFILES/$PHON_AWK -v mode=$modnum;
fi


if [ "$poscar_infile" != "" ] && [ $catdisps -eq 0 ]; then
    echo "Creating in.bs file..."
    cat $poscar_infile | igawk -f $AWKFILES/$V4V5 | igawk -f $AWKFILES/$P2vis -v XBS=1 > in.bs ;
    if [ ! -e "apos.dat" ] && [ $gobabyphonons -eq 1 ]; then
	echo "Creating apos.dat file..."
	poscar_cnvrt -f $poscar_infile -a
    fi
fi

if [ $modfollow -eq 1 ]; then
    if [ $modnum -eq -1 ]; then
	echo "Specify a mode. Exiting."
	clean_up; clean_bs;
	exit;
    fi
    poscar_cnvrt -f $poscar_infile -C | head -7 > tmp.modfollow.dat;
    cat in.mv | gawk --source '(NR>1){print $0}' >> tmp.modfollow.dat;
    poscar_cnvrt -f tmp.modfollow.dat -C > "$poscar_infile"-modfollow_$modnum;
    clean_up; clean_bs;
fi

if [ $catdisps -eq 1 ]; then
    rm -f tmp.disps;
    cat $outcar_infile | igawk -f $AWKFILES/$PHON_AWK -v mode=$modnum -v printdisps=1;
    cat tmp.disps;
    clean_up; clean_bs;
fi

if [ $dbg -ne 1 ]; then
   clean_up;
fi


echo
echo "             +++ ${script_name%%.sh} done +++"
echo


