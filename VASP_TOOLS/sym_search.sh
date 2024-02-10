#!/bin/bash
# This script is part of VASP TOOLS

script_name="sym_search.sh"
script_date="11 Jan 2011"
script_version="1.5.9"

BASE=/home/ehm

# vasp tools top directory
VT_TOP=$BASE/src/VASP_TOOLS

# v 1.5.9  18 Aug 2017
# -fix: on error or trap, clean up temp files.
#
# v 1.5.8  26 Jan 2011
# fix output file name
#
# v 1.5.7  11 Jan 2011
# add auto-detect of POSCAR v5 and convert to v4
#
# v 1.5.6  02 Nov 2010
# add switch to do lots of fine searching with findsym
# add ability to use old symsearch binary if it is on system
#
# v 1.5.5  01 March 2010
# add code to look at phonon apos.dat files by scanning through
# negative mode frequencies for new symmetries
#
# v 1.5.4
# add more options to control fsym.in file
#
# v 1.5.3
# fix location issues. isotropy directory is assumed
# to sit in ~/bin/isotropy
#
# v 1.5.2
# add option to print out only derived icsd file
#
# v 1.5.1
# small bug fixes
#
# v 1.4
# Tue Apr  3 15:13:13 PDT 2007
# add support for outputting visual stuff, xbs, etc
#
# v 1.1
# Thu Oct 19 11:15:33 PDT 2006
# symsearch is no longer supported by the
# ISOTROPY guys.  Use only findsym now.
#


# default values
axisc_v=-1
mono_v=-1
axesr_v=-1
clean=1
dbg=0
DRED=1;
help=-1
highsym=-1
highsymN=20 # default search 20 values
isV5=0;
gen_icsd=-1
opts=""
outn=tmp
origin_fsym=2;
phon_mode=0;
phon_file="phonons.out";
gen_poscar_out=-1
name=CONTCAR
rmsv=0.00
stv=4
shift_origin=0;
xbs=0
Xsymsearch=0;

declare SWITCH
while getopts "aAdD:f:hHIm:M:n:o:Op:Pr:s:SCxX" SWITCH; do
    case $SWITCH in
    a) axisc_v=1 ;;
    A) axesr_v=1 ;;
    d) dbg=1 ;;
    D) DRED=$OPTARG ;;
    f) name=$OPTARG ;;
    h) help=1 ;;
    H) highsym=1 ;;
    I) gen_icsd=1 ;;
    m) mono_v=$OPTARG ;;
    M) phon_mode=$OPTARG ;;
    n) highsymN=$OPTARG ;;
    o) outn=$OPTARG ;;
    O) origin_fsym=1 ;;
    p) phon_file=$OPTARG ;;
    P) gen_poscar_out=1 ;;
    r) rmsv=$OPTARG ;;
    C) clean=-1 ;;
    s) stv=$OPTARG ;;
    S) shift_origin=1 ;;
    x) xbs=1 ;;
    X) Xsymsearch=1 ;;
    esac
done

if [ $# -eq 0 ] || [ $help -eq 1 ]; then
    echo
    echo "########################"
    echo "#    "$script_name
    echo "########################"
    echo
    echo "version "$script_version " : "$script_date
    echo
    echo "use: sym_search.sh  [-f file.inp] -[aAdD:f:hHIm:M:n:o:Op:Pr:s:SCxX]"
    echo
    echo "    -h --- show this help"
    echo "    -d --- debug"
    echo
    echo "    -f --- input file name (default CONTCAR)"
    echo "    -p --- phonons.out filename (default phonons.out)"
    echo "    -o --- output base name"
    echo "    -C --- do NOT clean directory (delete all but the CONTCAR file)"
    echo
    echo "    -r --- rms deviations for strain (symsearch) and tolerance (findsym)"
    echo "    -s --- search type {1,2,3,4} (symsearch only)"
    echo "    -D --- dreduce (phonon displacement factor for apos.dat"
    echo "           and phonons.out file, try 0...1"
    echo
    echo "    -a --- sets unique monoclinic axis to c (default b)"
    echo "    -m --- sets monoclinic cell choice {2,3} (default 1)"
    echo "    -A --- sets rhombo axes for R-centered sp groups (default hex)"
    echo "    -O --- use origin choice 1 (default by fsym is 2)"
    echo
    echo "    -x --- xbs output"
    echo "    -H --- loop tolerance for mulitple symmetries"
    echo "           -n -*- number for -H switch (default 20)"
    echo "    -I --- produce ICSD output from findsym symmetry"
    echo "    -P --- produce POSCAR output file from findsym symmetry"
    echo "           (generates icsd file then calls icsd_cnvrt)"
    echo "           -S --- shift icsd output to origin (default off)"
    echo
    echo "    -X --- use old symsearch binary instead of findsym"
    echo
    echo " examples: "
    echo
    echo "$ sym_search -f CONTCAR -o cabh_23 -s 4 -r 0.0001"
    echo "$ sym_search -o cabh_23 -C"
    echo
    echo
    echo Eric Majzoub
    echo Sandia National Laboratories
    echo 24 august 2005
    echo
    exit
fi


# Check if we are on Mac OS X or Linux
onDarwin=`echo \`uname -a\` | grep "Darwin"`
onLinux=`echo \`uname -a\` | grep "Linux"`

trunk=${name##/*/}
base=${name%/*}
extension=${name##*.}
bs=$outn.bs
symin=$outn.sym.in
symout=$outn.sym.out
symlog=$outn.sym.log
fsymin=$outn.fsym.in
fsymout=$outn.fsym.out
fsymlog=$outn.fsym.log
xrin=$outn.xr.in
xrout=$outn.xr.dat
xbsout=$outn.bs

hostn=`hostname`
hostbase=${hostn%%.*}

# echo trunk = $trunk
# echo base = $base
# echo extension = $extension
# echo bs = $bs
# echo symin = $symin
# echo symout = $symout
# echo xrin = $xrin
# echo xrout = $xrout

# echo $runs
# echo $trun
# echo $epsi
# echo $othr

#
# [test] expects integer expressions, for those not integer, quote them
# and use the string comparisons (!= is for strings, -ne is for integers).
#

#################################
#   Set Environment Variables   #
#################################

iso=$BASE/bin/isotropy
export ISODATA=$iso/
findsym=$iso/findsym
if [ $Xsymsearch -eq 1 ]; then
    syms=/home/packages/binaries/isotropy_2006_jan/symsearch
    export ISODATA=/home/packages/binaries/isotropy_2006_jan/
fi

POSCARCNVRT=`which poscar_cnvrt`;

FINDSYM2ICSD=$VT_TOP/awkfiles/findsym2icsd.awk
poscar2findsym=$VT_TOP/awkfiles/poscar2findsym.awk
POSCAR2VIS=$VT_TOP/awkfiles/poscar2vis.awk
APOS2POSCAR=$VT_TOP/awkfiles/apos2poscar.awk
PHONDISP=$VT_TOP/awkfiles/phonon_disp.awk
POSCARDISP=$VT_TOP/awkfiles/poscar_displace.awk

if [ $dbg -eq 1 ]; then
    echo "BASE= "$BASE
    echo "iso= "$iso
    echo "findsym= "$findsym
fi

###################################
#                                 #
#         Functions               #
#                                 #
###################################
function autodetect {
    isV5=`cat $name | awk '(NR==6 && $0!~"[0-9]"){print 1}(NR==6 && $0~"[0-9]"){print 0}'`;
}

function postprocess {

    if [ $dbg -eq 1 ]; then
	echo "Parsing CONTCAR file: "$name ;
    fi

    cat $name | awk -f $poscar2findsym -v findsym=1 -v rms=$rmsv \
	-v origin=$origin_fsym  -v axisc=$axisc_v -v mono=$mono_v \
	-v axesr=$axesr_v > $fsymin ;


    if [ -n "$onLinux" ]; then

	if [ $Xsymsearch -eq 1 ]; then
	    cat $name | awk -f $poscar2findsym -v symsearch=1 -v rms=$rmsv \
		-v search_type=$stv > $symin ;
	    $syms < $symin > $symout ;
	elif [ $Xsymsearch -eq 0 ]; then
	    if [ $dbg -eq 1 ]; then
		echo "Running findsym..."
	    fi
	    $findsym < $fsymin > $fsymout ;
	fi
    fi

    if [ -n "$onDarwin" ]; then
	echo "Symsearch not available for OS X"
	exit
    fi
    
    if [ -f symsearch.log ]; then
	mv -f symsearch.log $symlog
    fi
    
    if [ -f findsym.log ]; then
	mv -f findsym.log $fsymlog
    fi
    
}

function run_findsym {

    if [ $Xsymsearch -eq 1 ]; then
	
	cat $symout

    elif [ $Xsymsearch -eq 0 ]; then
	
	if [ $dbg -eq 1 ]; then
	    echo
	    echo "Findsym found the following spacegroup"
	fi
	
	ERR=`cat $fsymout | grep bombed`;
	if [ ! -z "$ERR" ]; then
	    echo "FATAL ERROR. FINDSYM: encountered... "$ERR
	    if [ $dbg -eq 0 ]; then
		clean_up;
	    fi
	    exit
	fi
	
	echo  `cat $fsymout | grep Space` "rms_tol= $rmsv" | \
	    awk '(NF==7){printf("%s %s%6d%10s%10s %s%8.4f\n",$1,$2,$3,$4,$5,$6,$7);}'
	
    fi
}

function generate_icsd {
    echo "Generating POSCAR file for symmetry found by FINDSYM."
    if [ -s $fsymout ]; then
	cat $fsymout | igawk -f $FINDSYM2ICSD  \
	    -v shft_orgn=$shift_origin > findsym.icsd;
    else
	echo "No findsym file found!!"
	exit;
    fi
}

function clean_up {
    rm -f $symin $symout $symlog $fsymin $fsymout $fsymlog $xrin $xrout findsym.icsd;
    rm -f tmp_apos_CONTCAR tmp_phon_displacements tmp_symsearch_phon;
    rm -f tmp_phon_CONTCAR_cart tmp_phon_CONTCAR_direct;
    rm -f tempfile.symsearch.POSv4;
    rm -f tmp.fsym.*;
}

##############################
#       BEGIN HERE           #
##############################

# check file to see if it is VASP5 version (includes species in line 6)
autodetect ;
if [ $isV5 -eq 1 ]; then
    cat $name | awk '(NR!=6){print $0}' > tempfile.symsearch.POSv4;
    echo "autodetected POSCAR version 5, converting to V4.";
    name_orig=$name;
    name=tempfile.symsearch.POSv4;
fi


# first check to see if the file given was an apos.dat file
if [ "$name" == "apos.dat" ]; then
    if [ $phon_mode -eq 0 ]; then
	echo "Which phonon mode displacement do you want (start from 1)?"
	echo "Use the -M switch to this script"
	exit;
    fi
    if [ $dbg -eq 1 ]; then
	echo "Found apos.dat file, running through APOS2POSCAR and renaming 'name'"
    fi
    # make CONTCAR file from apos.dat (cart format)
    cat $name | igawk -f $APOS2POSCAR | sed '/^$/d' > tmp_apos_CONTCAR;
    # get displacements from mode M from phonons.out
    cat $phon_file | igawk -f $PHONDISP -v mode=$phon_mode > tmp_phon_displacements;
    # combine the apos CONTCAR with the displacements and make CONTCAR direct format
    cat tmp_apos_CONTCAR tmp_phon_displacements > tmp_symsearch_phon;
    cat tmp_symsearch_phon | igawk -f $POSCARDISP -v dreduce=$DRED > tmp_phon_CONTCAR_cart;
    $POSCARCNVRT -f tmp_phon_CONTCAR_cart -C > tmp_phon_CONTCAR_direct;
    name="tmp_phon_CONTCAR_direct";
fi

if [ $xbs -eq 1 ]; then
    cat $name | awk -f $POSCAR2VIS \
	-v XBS=1 -v BONDS=1 -v BP=0.1 -v DUP=1 > $xbsout
fi

if [ $highsym -eq 1 ]; then
    tolerancelist=`echo "0.0 "``gawk --source 'BEGIN{for(i=0;i<N;i++){printf("%.4f ",0.5*exp(-(N-i)/10));}}' -v N=$highsymN`
    if [ $dbg -eq 1 ]; then
	echo "tol list="$tolerancelist
    fi
    for toll in $tolerancelist; do
	rmsv=$toll;
	postprocess ;
	run_findsym ;
    done
else
    postprocess ;
    run_findsym ;
fi


if [ $gen_icsd -eq 1 ]; then
    generate_icsd;
    if [ $isV5 -eq 1 ]; then
	mv findsym.icsd $name_orig.fsym.icsd;
    else
	mv findsym.icsd $name.fsym.icsd;
    fi
fi

if [ $gen_poscar_out -eq 1 ]; then
    generate_icsd ;
    echo "Running icsd_cnvrt..."
    icsd_cnvrt -f findsym.icsd -P;
    mv POSCAR POSCAR-findsym;
fi

if [ $clean -eq 1 ]; then
    clean_up;
fi

exit
