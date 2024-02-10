#!/bin/sh
# restart VASP calcs

if [ $1 == "cluster" ]; then
    BASE=/home/majzoube
    SYMS="$BASE/bin/symsearch"
    OUTCAR_INFO=$BASE/awkfiles/outcar_info.awk
elif [ $1 == "desktop" ]; then
    SYMS=$HOME/bin/symsearch
    OUTCAR_INFO=$HOME/awkfiles/outcar_info.awk
fi

cdir=$(pwd);
echo "In restart.sh: dir=  "$cdir;

for number in `ls *run`; do
  n=${number%%run};
  echo $n
done

# echo $((n+1))
m=$((n+1))
echo "getting outcar info..."
if [ ! -s OUTCAR ]; then
    echo "In restart.sh. No OUTCAR file."
fi
cat OUTCAR | igawk -f $OUTCAR_INFO > $m"run"
echo "copying CONTCAR to POSCAR (restart.sh)"
if [ -s ./CONTCAR ]; then
    cp CONTCAR POSCAR
else
    echo "CONTCAR empty!!"
fi

if [ -s XDATCAR ]; then
    cat XDATCAR >> save_XDATCAR;
fi

cat *run

echo "running symsearch with r=0.01"
$SYMS -f CONTCAR -r 0.01 | grep Space;
echo "running symsearch with r=0.1"
$SYMS -f CONTCAR -r 0.1 | grep Space;
echo "running symsearch with r=0.4"
$SYMS -f CONTCAR -r 0.4 | grep Space;

exit
