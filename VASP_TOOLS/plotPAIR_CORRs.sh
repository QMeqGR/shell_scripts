#!/bin/bash

$script_name="plotPAIR_CORRs.sh"
$script_date="11 Feb 2016"
$script_vers="0.1"

if [ $# -lt 1 ]; then
    echo "Use: $script_name CONTCAR [d-spacing]";
    echo "If you add the d-spacing it will print the elements correlated."
    exit;
fi

contcar=$1;
d=$2;
h=0.01;
elms=$(cat $contcar | head -1 | gawk --source '($1=="Z:"){for(i=2;i<NF+1;i++){printf("%d ", $i);}}');
echo "elements= "$elms

echo "Removing old pair files..."
rm -f pcf.*;

for e1 in $elms; do
    for e2 in $elms; do
	if [ $e2 -gt $e1 ]; then
	    break;
	fi
	pairfile=pcf.$e1.$e2.dat;
	contcar_pdf -f $contcar -z $e1 -Z $e2 -H 10 > $pairfile;
	cutplot -f $pairfile -x 1 -y 3 -O ${pairfile%%.dat} -S "-i 2 -w 0.1 -R 4 -P -N -T $pairfile";
	if [ "$d" == "" ]; then
	   rm $pairfile;
	fi
    done
done

echo "####################################################"
echo "Finding correlations..."
if [ "$d" != "" ]; then
    for e1 in $elms; do
	for e2 in $elms; do
	    if [ $e2 -gt $e1 ]; then
		break;
	    fi
	    prt="";
	    prt=$(cat pcf.$e1.$e2.dat | gawk --source '($1 !~"#" && $1<(d+h) && $1>(d-h)){print $0}' -v d=$d -v h=$h)
	    if [ "$prt" != "" ]; then
		echo "$prt $e1 $e2"
	    fi
	done
    done
fi

rm -f pcf.*.dat;
