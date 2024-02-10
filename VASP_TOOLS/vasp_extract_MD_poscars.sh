#!/bin/bash

script_name="vasp_extract_MD_poscars.sh"
script_date="03 Feb 2016"
script_version="0.2"

# version 0.2 07 Feb 2018
#   -- add extraction of energies of the poscars
# version 0.1 03 Feb 2016
#   -- first version

AWKFILES=$HOME/awkfiles/

# defaults
dbg=0;
energies=0;
help=0;
modulo=1;
nargs=$#;
ocar="OUTCAR"
pcar="POSCAR"
structN="a";
output_version=4;

declare SWITCH
while getopts "dEhm:N:O:P:V" SWITCH; do
    case $SWITCH in
	d) dbg=1 ;;
	E) energies=1 ;;
	h) help=1 ;;
	m) modulo=$OPTARG ;;
	O) ocar=$OPTARG ;;
	P) pcar=$OPTARG ;;
	N) structN=$OPTARG ;;
	V) output_version=5 ;;
    esac
done

if [ $help -eq 1 ] || [ $nargs -eq 0 ]; then
    echo
    echo "#####################################"
    echo "#  "$script_name
    echo "#  version "$script_version
    echo "#  "$script_date
    echo "#####################################"
    echo
    echo "     USE:    $script_name -O OUTCAR -P POSCAR"
    echo
    echo "     OPTIONS: (* denotes arg required)"
    echo
    echo "    -d --- debug (default off)"
    echo "    -h --- print this help message"
    echo
    echo "    -O -*- outcar name (default OUTCAR)"
    echo "    -P -*- poscar name (default POSCAR)"
    echo "    -m -*- get every m-th structure"
    echo "    -N -*- get structure number N"
    echo "           'a' will get all, energies in energies.txt"
    echo "    -E --- get energies and exit (output in energies.dat)"
    echo "    -V --- output VASP version 5 (default v4)"
    echo
    echo
    echo Eric Majzoub
    echo University of Missouri - St. Louis
    echo
    exit
fi

#################################################
#  Functions
#################################################
function clean_up () {
    rm -f $tempfiles;
}

function make_t_awkfiles () {

cat > tmp_extract_pcars.awk <<EOF

BEGIN{
# set on command line
# get_starting_poscar
# nat;
# get_struct_num; # a particular structure number

# Note the first glv is the starting structure, so extract
# numbers 2 and up...

# flags
# gsp= get starting poscar;
# glv= get lattice vectors;
# gap= get atom positions;
# gen= get energy;

gsp=0; glv=0; gap=0; gen=0;
acnt=0;
lv_cnt=0;
struct_cnt=0;

}

# get starting poscar
(get_starting_poscar==1 && /position of ions in fractional coordinates/){
start_line=NR;
if ( debug ) printf("NR=  %d\n",start_line);
gsp=1;
}
(gsp==1 && NR>start_line && NR<start_line+nat+1){
print \$0;
}

# get outcar
(gsp==0 && /direct lattice vectors/){
struct_cnt++;
glv=1; # get lattice vectors
if (  debug ) printf("glv # %d  NR= %d\n",struct_cnt,NR);
start_line=NR;
}
(glv==1 && get_struct_num==struct_cnt && NR>start_line && NR<start_line+4){
lv_cnt+=1;
if (  debug ) printf("lv %16.9f%16.9f%16.9f\n",\$1,\$2,\$3);
if ( !debug ) printf("%16.9f%16.9f%16.9f\n",\$1,\$2,\$3);
if ( lv_cnt==3 ) { lv_cnt=0; glv=0; gap=1; gen=1; }
}

(gsp==0 && gap==1 && \$1=="POSITION" && \$2=="TOTAL-FORCE"){
apos_start_line=NR;
if ( debug ) printf("atom pos start_line= %d\n",apos_start_line);
}

(gsp==0 && gap==1 && NR>apos_start_line+1 && NR<apos_start_line+1+nat+1){
acnt+=1;
if (  debug ) printf("apos %3d  %10.5f%10.5f%10.5f\n",acnt,\$1,\$2,\$3);
if ( !debug ) printf("%10.5f%10.5f%10.5f\n",\$1,\$2,\$3);
if ( acnt == nat ){acnt=0; gap=0;}
}

(gsp==0 && gen==1 && /free  energy/){
printf "%8d%20.8f\n",struct_cnt,\$5 >> "energies.txt"
gen=0;
}

END{

}

EOF
    
}

#################################################

# if -E option is used
if [ $energies -eq 1 ]; then
    cat $ocar | grep "free  energy" | gawk '{print NR+1, $5}' > energies.dat;
    exit;
fi

# get header from POSCAR
t_header=tmp.header_file.$script_name
cat $pcar | gawk --source '($1 != "Direct"){print $0}($1=="Direct"){exit;}' > $t_header;
if [ $dbg -eq 1 ]; then
    echo "header: "
    cat $t_header
    echo
fi

# get number of atoms
nat=$(cat $t_header | tail -1 | gawk '{n=0;for(i=1;i<NF+1;i++){n+=$i};print n;}');
if [ $dbg -eq 1 ]; then
    echo "nat= "$nat
fi

# make the temporary awk files
make_t_awkfiles;

# get starting poscar
t_start_pcar=tmp.starting_pcar.$script_name
cat $t_header > $t_start_pcar
cat $ocar | gawk -f ./tmp_extract_pcars.awk -v get_starting_poscar=1 -v nat=$nat -v debug=0 >> $t_start_pcar

# get other poscars
num_ocars=$(cat $ocar | grep "direct lattice vectors" | wc -l);

if [ "$structN" == "a" ]; then
    num_list=$(gawk --source 'BEGIN{for(i=2;i<N+1;i++){if (i%MOD==0) printf("%d ",i);};}' -v N=$num_ocars -v MOD=$modulo)
    echo "Found $num_ocars POSCARS. Extracting, modulo "$modulo " ..."
else
    num_list=$structN;
    echo "Found $num_ocars POSCARS. Extracting number $structN"
fi
for n in $num_list; do
    if [ $dbg -eq 1 ]; then
	echo "Getting structure number "$n
    fi
    cat $ocar | gawk -f ./tmp_extract_pcars.awk  -v nat=$nat -v get_struct_num=$n -v debug=0 > tmp.struct.$n.dat;
    nout=$(gawk --source 'BEGIN{printf("%05d",nn);}' -v nn=$n)
    head -2 $t_header               > POSCAR-n$nout.cart;
    head -3 tmp.struct.$n.dat      >> POSCAR-n$nout.cart;
    tail -1 $t_header              >> POSCAR-n$nout.cart;
    echo "Cartesian"               >> POSCAR-n$nout.cart;
    tail -$nat tmp.struct.$n.dat   >> POSCAR-n$nout.cart;

    poscar_cnvrt -f POSCAR-n$nout.cart -C > POSCAR-n$nout;
    if [ $dbg -eq 0 ]; then
	rm -f POSCAR-n$nout.cart;
    fi

    if [ $output_version -eq 5 ]; then
	cp POSCAR-n$nout tmp.in;
	cat tmp.in | igawk -f $AWKFILES/poscar_2v5.awk > POSCAR-n$nout;
	rm -f tmp.in;
    fi
    
done

# get difference files from starting poscar

# get difference files from one outcar to the next



tempfiles="$t_header tmp_extract_pcars.awk $t_start_pcar tmp.struct.*.dat";
if [ $dbg -eq 0 ]; then
    clean_up;
fi

exit
