#!/bin/bash

# vcalc script
#
# Call this script in the directory ../ to where the VASP run was completed
#
# E.H. Majzoub, University of Missouri, 2015
#

VERSION=2.0
# version 2.0, 14 Sept 2017
# Incorporating bader charge analysis in the renamed vcalc script
# (used to be calc_phonons).
#

# NOTE: As of VASP TOOLS version 2.1.3 the calc_phonon.sh script has changed name
# to vcalc.sh. The calc_phonon.sh script now points to vcalc.sh.
#
# vcalc.sh now incorporates bader and born charge calculations, etc.
# 

# Old original calc_phonon versions...
# version 1.2, 15 Feb 2016
#   --changed name to calc_phonons and added RANDtag from new vasp_setup behavior
# version 1.0, 20 July 2015

script_name="vcalc.sh"
script_date="14 Sept 2017"
script_version=$VERSION

#################################################################
## Defaults
bader=0;
born=0;
cline="";
dbg=0;
dir_name="";
help=0;
kill_existing_dir=0;
mode=3;
phonon=1;
vsetup_born=12;
vsetup_bader=13;
type="phon"; # default calculation type

#################################################################

declare SWITCH
while getopts "bBdD:hkl:m:" SWITCH; do
    case $SWITCH in
	b) born=1;  type="born";  phonon=0; ;;
	B) bader=1; type="bader"; phonon=0; ;;
	d) dbg=1 ;;
	D) dir_name=$OPTARG ;;
	h) help=1 ;;
	k) kill_existing_dir=1 ;;
	l) cline=$OPTARG ;;
	m) mode=$OPTARG ;;
    esac
done

#################################################################

if [ $help -eq 1 ] || [ $# -eq 0 ]; then
    echo
    echo "########################"
    echo "#      "$script_name
    echo "########################"
    echo
    echo "version "$script_version
    echo $script_date
    echo
    echo "use: $ $script_name -D directory_name"
    echo "example: $ $script_name -D P_24 -b    will calc born eff chrg only using LCALCEPS method"
    echo
    echo "    -h --- show this help"
    echo "    -d --- debug"
    echo 
    echo "    -D -*- directory base name"
    echo "    -k --- kill any existing phon directory in the base directory"
    echo "           (default is not to rm -rf this directory)"
    echo
    echo "           ==  PHONON CALCULATIONS  =="
    echo "               (calculates Born charges automatically)"
    echo
    echo "    -m -*- phonon calc mode (default 3: linear response)"
    echo "           options: 3 linear response"
    echo "                    4 frozen phonon"
    echo
    echo
    echo "           ==  EFFECTIVE CHARGE CALCULATIONS  =="
    echo "               (turns OFF phonon spectra calculation)"
    echo
    echo "    -b --- calculate Born effective charge using LCALCEPS method"
    echo "    -B --- calculate Bader charges"
    echo
    echo "           ==  VASP OPTIONS  =="
    echo
    echo "    -l -*- VASP_setup script command line in quotes"
    echo "           (e.g. -l \"-f POSCAR -k 2 -p 16 -V 532\")"
    echo "           ** default is to use the cline contents from base dir **"
    echo "           ** You do not need to add -m 3, it is added by default **"
    echo 
    echo
    exit
fi


##################################################
# functions 
##################################################
function get_rand_tag (){
    tagpre1=$(ls Script* | gawk '{print $1}');
    tagpre2=${tagpre1%%.sh}
    tagpre3=${tagpre2##*_}
    if [ $dbg -eq 1 ]; then
        echo "finding random number tag..."
        echo "tagpre1= "$tagpre1
        echo "tagpre2= "$tagpre2
        echo "tagpre3= "$tagpre3
    fi
    RANDtag=$tagpre3
}

function call_VASP_setup () {

    if [ $born -eq 1 ]; then
	vasp_setup $cline -m $vsetup_born;
    elif [ $bader -eq 1 ]; then
	vasp_setup $cline -m $vsetup_bader;
    else
	vasp_setup $cline -m $mode; # default calc is phonon
    fi
    
}

##################################################
#  Script starts here
##################################################
cdir=$(pwd)

######################################################
echo "## calc type= "$type
echo "## dir_name= "$dir_name
echo "## kill_exisiting_dir= "$kill_existing_dir

if [ ! -d ./$dir_name ]; then
    echo "No directory ./$dir_name. Exiting."
    exit
fi

#########################################
if [ -d ./$dir_name/$type ]; then
    if [ "$kill_existing_dir" == "1" ]; then
	echo "removing existing $type directory..."
	rm -rf $dir_name/$type
	echo "making new $type directory..."
	mkdir ./$dir_name/$type
    else
	echo "$type directory "$dir_name/$type" exists... skipping"
	exit
    fi
else
    mkdir ./$dir_name/$type
fi

# Go into $type directory and start the calculation
cd ./$dir_name/$type
tmpname0=$(pwd)
if [ $born -eq 1 ]; then
    tmpname1=${tmpname0%%/born}
elif [ $bader -eq 1 ]; then
    tmpname1=${tmpname0%%/bader}
else
    tmpname1=${tmpname0%%/phon}
fi
name=${tmpname1##/*/}
echo "name= "$name
cp ../CONTCAR ./POSCAR;
if [ -s ../cline.out ] && [ "$cline" == "" ]; then
    cline=$(cat ../cline.out | grep command | gawk -F'=' --source '{print $2}')
    echo "found cline for VASP setup, using it here: "$cline
    call_VASP_setup;
elif [ "$cline" != "" ]; then
    echo "Using cline supplied on run_phonon command line"
    call_VASP_setup;
else
    cline="-f POSCAR -k 2 -p 2"
    call_VASP_setup;
fi

if [ -s ../KPOINTS ]; then
    echo "found existing KPOINTS file in VASP run directory, will use it."
    cp -f ../KPOINTS . ;
fi

rm -f script.*.out;
get_rand_tag;
mv Script_$type"_"$RANDtag.sh   Script_"$name"_$type"_"$RANDtag.sh;

echo "Submitting $type job..."
nohup ./Script_"$name"_$type"_"$RANDtag.sh >& script.$name.$type.out &

cd $cdir
exit
