#!/bin/bash

cdir=$(pwd);
dirname=$1;

if [ -d $dirname ]; then
    echo "Calculating ENCUT=300 for dir= "$dirname;
else
    echo "Can't find dir= "$dirname;
    exit;
fi

cd $dirname;
echo "Creating directories..."
mkdir encut_300;
cd encut_300;
cp ../CONTCAR ./POSCAR

echo "Running VASP_setup ..."
~/src/VASP_setup.sh -f POSCAR -k -1 -i 2 -p 8 -E 300;

echo "Submitting script ..."
nohup ./Script*.sh  >& script.*.out &

cd $cdir;

exit
