#!/bin/sh
# This script is part of VASP TOOLS

BASE=/home/majzoube
VT_TOP=$BASE/src/VASP_TOOLS

# v 1.1 add formula unit support
# v 1.0 first version

if [ $# -lt 3 ]; then
        echo "use: process_vasp_cycle.sh 1 0.2 FU_Z V5 printdensity"
        echo "for C1-POSCAR...  rms=0.2  etot/NUM_FU_Z and vasp5 POSCAR style"
        exit
fi

debug=0;
n=$1;
tol=$2;
fu_z=$3;
isV5=$4;
printdensity=$5;

if [ -z $printdensity ]; then
    printdensity=0;
fi

echo "script parms: "$n" "$tol" "$fu_z
echo "printdensity= "$printdensity

filelist=`ls C$n-*POSCAR*-n*`;
echo "filelist= "$filelist;

if [ $printdensity -eq 1 ]; then
    echo "CONTCAR,Z,eV/fu,density,tol,sg,symm" > energies-$n.dat;
else
    echo "CONTCAR,Z,eV/fu,tol,sg,symm" > energies-$n.dat;
fi

for file in $filelist; do

    if [ $debug -eq 1 ]; then
        echo "file="$file;
	echo "removing v5 element lines..."
    fi

    if [ "$isV5" == "V5" ]; then
	cat $file | awk '(NR!=6){print $0}' > script.tmp.file;
    else
	cat $file > script.tmp.file;
    fi
    filet=script.tmp.file;

    npos_fu=`head $filet | awk -v FUZ=$fu_z '(NR==1){for(i=1;i<NF+1;i++){if($i==FUZ){printf("%d",i-1)}}}'`;
    nnfu=`head $filet | awk -v POSFU=$npos_fu '(NR==6){print $POSFU}'`;

    if [ $debug -eq 1 ]; then
        echo "npos_fu="$npos_fu "  nnfu="$nnfu;
    fi

#    echo $file `cat O${file:1} | awk -f $BASE/$VT_TOP/awkfiles/outcar_info.awk | grep eV` \
#        `symsearch -f $filet -r $tol | grep Space` $nnfu | awk -v nfu=$nnfu\
#        '(NF==11){printf("%-25s%8s%11.4f SpGr%5d%10s%10s%10s%8.4f  Z=%d\n",$1,$2,$3/(nfu),$6,$7,$8,$9,$10,$11);}';

    eV=`cat O${file:1} | awk -f $BASE/$VT_TOP/awkfiles/outcar_info.awk | grep eV | awk '{print $2}'`;
    sym=`$BASE/bin/max_sym $filet | awk --source '(NF==2){printf("0.0 1 P1");}(NF>2){print $0}'`;
    density=`cat $filet | igawk -f $BASE/$VT_TOP/awkfiles/contcar_info.awk | awk --source '($1~"Density"){print $3}'`;
    if [ $printdensity -eq 1 ]; then
	echo $file $nnfu $eV $density $sym | awk --source '{printf("%s,%d,%.4f,%.3f,%s,%s,%s\n",$1,$2,$3/$2,$4,$5,$6,$7);}';
    else
	echo $file $nnfu $eV $sym | awk --source '{printf("%s,%d,%.4f,%s,%s,%s\n",$1,$2,$3/$2,$4,$5,$6);}';
    fi


done  | sort -n -k 3 -t "," >> energies-$n.dat &

exit
