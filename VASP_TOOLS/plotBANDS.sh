#!/bin/bash

script_name="plotBANDS"
script_version=0.1
script_date="05 Feb 2016"

BASE=/home/ehm

###################################################
###################################################
VT_TOP=$BASE/src/VASP_TOOLS

# awkfiles
BAND=$VT_TOP/awkfiles/band.awk
DOSCAR_SPLIT=$VT_TOP/awkfiles/doscar_split.awk

# defaults
band_dir="";
dbg=0;
explicit=0;
Efermi="";
files="CONTCAR  DOSCAR  EIGENVAL  KPOINTS  OUTCAR-band";
help=0;
jpegout=0;
lm_decomp=1;
npoints="-1";
skip_symlinks=1;
startgv=1;
title="";
pdfout=0;
range="AUTO";

declare SWITCH
while getopts "dD:eE:hjl:n:pR:T:" SWITCH; do
    case $SWITCH in
	d) dbg=1 ;;
	D) band_dir=$OPTARG; skip_symlinks=0 ;;
	e) explicit=1 ;;
	E) Efermi= $OPTARG ;;
	h) help=1 ;;
	j) jpegout=1; startgv=0 ;;
	l) lm_decomp=$OPTARG ;;
	n) npoints=$OPTARG ;;
	p) pdfout=1;  startgv=0 ;;
	R) range=$OPTARG ;;
	T) title=$OPTARG ;;
    esac
done

if [ $help -eq 1 ] || [ $# -eq 0 ]; then
    echo
    echo "#######################"
    echo "#    "$script_name
    echo "#######################"
    echo
    echo "version: "$script_version
    echo "last update: "$script_date
    echo
    echo "    Script will make symlinks to current dir based on"
    echo "    -D switch. Then it will generate the band structure"
    echo "     plot."
    echo
    echo "    Options:"
    echo
    echo "    -h --- show this help"
    echo "    -d --- debug"
    echo
    echo "    -e --- explicit set of kpoints (zero weight)"
    echo "           (sets -v explicit=1 for call to band.awk)"
    echo "    -n -*- set npoints by hand (explicit choice of kpts)"
    echo "    -l -*- LM decomp flag for DOSCAR file."
    echo "           (default is lm_decomp = $lm_decomp )"
    echo
    echo "    -D -*- directory where band structure calc was performed"
    echo "           (if not set will assume DOSCAR, CONTCAR, OUTCAR-band,"
    echo "            EIGENVAL KPOINTS are all in directory or already"
    echo "            linked.)"
    echo "    -j --- jpeg output (default is viewing in gv)"
    echo "    -p --- pdf output  (default is viewing in gv)"
    echo
    echo "    -R -*- x-range (use colon and quotes) e.g. -R \"-20:50\""
    echo "    -T -*- title (use quotes if there are spaces)"
    echo
    echo
    echo Eric Majzoub
    echo University of Missouri - St. Louis
    echo
    echo
    exit
fi

##################################################
#  make the symlinks
##################################################
if [ $skip_symlinks -eq 0 ]; then
    if [ -d $band_dir ]; then
	echo "Getting data from band_dir= "$band_dir    
    else
	echo "No directory band_dir= "$band_dir
	exit
    fi
    
    # make symlinks
    echo "Making symlinks..."
    for f in $files; do
	
	fl="$band_dir/$f"
	echo "Making link for file: "$fl
	
	if [ -s $fl ]; then
	    ln -sf $fl .
	else
	    echo "File $fl does not exist!"
	    exit
	fi
    done
fi

##################################################
#   Xmgrace options
##################################################
if [ "$title" == "" ]; then
    title="Band Structure"
fi
xlo=$(echo $range | gawk -F ":" --source '{print $1}')
xhi=$(echo $range | gawk -F ":" --source '{print $2}')
if [ $dbg -eq 1 ]; then
    echo "xlo= "$xlo
    echo "xhi= "$xhi
fi

if [ "$range" == "AUTO" ]; then
    RANGE=AUTOSCALE;
else
    RANGE="WORLD XMIN $xlo; WORLD XMAX $xhi;"
fi
   

##################################################

Efermi=$(cat OUTCAR-band | grep "E-fermi" | tail -1 | gawk '{print $3}')
if [ $npoints -eq -1 ]; then
    npoints=$(cat KPOINTS | gawk '(NR==2){print $1}')
    echo "Found npoints= "$npoints " in file KPOINTS (line number 2)"
else
    echo "Using npoints from command line, npoints= "$npoints;
fi
echo "Found Efermi= "$Efermi




echo "Getting band data..."
cat EIGENVAL | gawk -f $BAND -v vasp=1 -v Ef="$Efermi" -v n="$npoints" -v explicit=$explicit > band.dat;

echo "Getting DOS data..."
cat DOSCAR | gawk -f $DOSCAR_SPLIT -v prt_tot=1 -v lm_decomp=$lm_decomp;

echo "Getting chemistry data from CONTCAR file..."
poscar_cnvrt -f CONTCAR -l > chemistry.txt


##################################################

cat > batch.agr << EOF

READ NXY "band.dat"

BLOCK xy "1:2"
line color 1
$RANGE
yaxis label "Energy (eV)"
yaxis tick place normal
xaxis label ""


###################################
PRINT TO "band.plot.eps"
DEVICE "EPS" OP "level2"
PRINT

EOF


gracebat -batch batch.agr -nosafe -hardcopy;
if [ $dbg -eq 0 ]; then
    rm -f batch.agr;
fi

if [ $jpegout -eq 1 ]; then
    convert band.plot.eps -rotate 90  band.plot.jpg;
fi
if [ $pdfout -eq 1 ]; then
    convert band.plot.eps -rotate 90  band.plot.pdf;   
fi


if [ $startgv -eq 1 ]; then
    gv band.plot.eps;
fi

rm -f *.plot.eps;

echo " +++  Done  +++"

exit
