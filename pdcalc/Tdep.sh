#!/bin/sh

if [ $# -lt 2 ]; then
    echo
    echo "Use: T_dep.sh \"1 LiH\" \"1 Li 0.5 hydrogen\""
    echo "This script should be called in top level pdcalc"
    echo "directory that contains the octave_work directory."
    echo
    exit
fi

if [ ! -d octave_work ]; then
    echo
    echo "Must be in directory that contains octave_work. Exiting."
    echo
    exit
fi

LHS=$1
RHS=$2



RN=$HOME/src/pdcalc/rxn_thermo.sh

T_list=$(gawk --source 'BEGIN{for(i=10;i<2000;i+=50){printf("%d ",i);};}')

cd octave_work;
rm -f ../rxn.dat;

echo "#_T     dE    dS    dH" | tee -a ../rxn.dat;
for T in $T_list; do 
   $RN -L "$LHS" -R "$RHS" -T $T -r $T | tail -1 | gawk '{print $8,$4,$6,$2}' | tee -a ../rxn.dat;
done

cd ..
cat rxn.dat | column -t > tmp.rxn.dat;
mv tmp.rxn.dat rxn.dat;
