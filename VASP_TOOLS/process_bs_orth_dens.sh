#!/bin/sh

BASE=/home/majzoube

if [ "$1" = "" ]; then
    echo "Use: $ process_bs.sh volume_tolerance"
    exit
fi

tolerance=$1;

##########################
function get_poscar () {
file=$1;
number=`cat $file | awk '($2~/commandline/){print $NF}'`
#echo "getting POSCAR "$number
cat $file | awk '($1=="*P"){print $0}' | sed 's/*P //' > POSCAR-n$number

}


# get the energy data
echo "Getting data..."
for file in *.bs; do
    number=`cat $file | awk '($2~/commandline/){print $NF}'`
    orth=`cat $file | awk -f $BASE/awkfiles/pack_info.awk | grep ortho | awk '{printf("%.4f",$2);}'`;
    vol=`cat $file | awk -f $BASE/awkfiles/pack_info.awk | grep vol | awk '{printf("%10.4f",$2);}'`
    voltol=`echo $vol $tolerance | awk '($1>$2){print 0}($1<=$2){print 1}'`;
    if [ $voltol -eq 1 ]; then
	get_poscar $file 
	echo -e $file '\t' "orth= "$orth '\t' "vol= "$vol '\t' "voltol= "$voltol;
    fi
done | sort -n -k 5 | tee energies.dat;

exit

