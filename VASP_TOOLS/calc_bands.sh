#!/bin/bash

#  calc_bands script
#
#  Call this script in the directory ../ to where the VASP run was completed
#
#  E.H. Majzoub, University of Missouri, 2015
#

VERSION=1.0

script_name="calc_bands.sh"
script_date="16 Sept 2015"
script_version=$VERSION

# version 1.0, 16 Sept. 2015

AWKFILES=/home/majzoube/awkfiles;
GEN_KPTS=$AWKFILES/gen_band_points.awk;

# Defaults
band_files_dir="/home/majzoube/band_files"
cline="";
concat_cline="";
dbg=0;
dir_name="";
explicit_kpt_gen=0;
help=0;
kill_existing_dir=0;
kpts_band_file="";
kpts_band_file_name="";
skip_charg_step=0;
type=band;


###########################
declare SWITCH
while getopts "c:dD:ehkK:l:s" SWITCH; do
    case $SWITCH in
	c) concat_cline=$OPTARG ;;
	d) dbg=1 ;;
	D) dir_name=$OPTARG ;;
	e) explicit_kpt_gen=1 ;;
	h) help=1 ;;
	k) kill_existing_dir=1 ;;
	K) kpts_band_file_name=$OPTARG ;;
	l) cline=$OPTARG ;;
	s) skip_charg_step=1 ;;
	*) eval echo "Unrecognized arg \$$[OPTIND-1]. Exiting."; exit ;;
    esac
done

if [ $help -eq 1 ] || [ $# -eq 0 ]; then
    echo
    echo "########################"
    echo "#      "$script_name
    echo "########################"
    echo
    echo "version "$script_version
    echo $script_date
    echo
    echo "    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "    !!!!!! NOTE: REDIRECT the output of this script. !!!!!!!!!!!!"
    echo "    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo
    echo " This script assumes your POSCAR is structurally relaxed already."
    echo " This script will use k-point density from the relaxed run."
    echo
    echo " use: $ calc_bands -D directory_name -K kpoints_file  >& redirect_script_output.txt &"
    echo " example: $ calc_bands -D P_24   -K sg119  >& ./P_24/p24.band.out &"
    echo
    echo " The band files directory is set to: "$band_files_dir
    echo " Current band files to choose from:"
    ls $band_files_dir
    echo
    echo
    echo "     OPTIONS:"
    echo
    echo "    -h --- show this help"
    echo "    -d --- debug"
    echo 
    echo "    -D -*- directory base name"
    echo 
    echo "    -k --- kill any existing band directory in the base directory"
    echo "           (default is not to rm -rf this directory)"
    echo
    echo "    -l -*- VASP_setup script command line in quotes"
    echo "           (e.g. -l \"-f POSCAR -k 2 -p 16 -V 532\")"
    echo "           ** default is to use the cline contents from base dir **"
    echo "    -c -*- use cline from base dir, but add to it with additional options"
    echo "           (e.g. -c \"-X 1\")"
    echo
    echo
    echo "    -K -*- k-points band file"
    echo "    -e --- explicit kpoints generation"
    echo "           Use this option when doing HF or hybrid band structures."
    echo "           You still have to specify the kpoints band fiile."
    echo
    echo "    -s --- skip charge density step (worked, but trouble with band structure step)"
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


##################################################
# START 
##################################################
echo "============== calc_bands script ================="
echo "               version "$VERSION
echo "=================================================="
cdir=$(pwd)

kpts_band_file=$band_files_dir/$kpts_band_file_name
echo "Using band_files_dir= "$band_files_dir
echo "Using kpoints band file name= "$kpts_band_file_name
if [ "$kpts_band_file_name" == "" ]; then
    echo "No kpoints file name given. Exiting."; exit;
fi
echo "Using kpoints band file= "$kpts_band_file
if [ ! -s $kpts_band_file ]; then
    echo "No kpoints band file. Exiting."; exit;
fi

######################################################
if [ ! -d ./$dir_name ]; then
    echo "No directory ./$dir_name. Exiting."
    exit
fi

echo "## calc type= "$type
echo "## dir_name= "$dir_name
echo "## kill_exisiting_dir= "$kill_existing_dir
echo

######################################################
# Check for existing directories
######################################################
if [ -d ./$dir_name/$type ]; then
    if [ "$kill_existing_dir" == "1" ]; then
	echo "removing existing $type directory : "$dir_name/$type
	rm -rf $dir_name/$type
	echo "making new $type directory..."
	mkdir ./$dir_name/$type
    elif [ $skip_charg_step -eq 1 ]; then
	echo "Found $type directory, but instructed to skip charge density step..."
    else
	echo "$type directory "$dir_name/$type" exists... skipping"
	exit
    fi
else
    echo "Did not find $type directory... making one"
    mkdir ./$dir_name/$type
fi


#########################################

cd ./$dir_name/$type

tmpname0=$(pwd)
tmpname1=${tmpname0%%/band}
echo "Now in directory: "$tmpname0

name=${tmpname1##/*/}
echo "(for script name) name= "$name

if [ -s ../CONTCAR ] && [ $skip_charg_step -eq 0 ]; then
    cp ../CONTCAR ./POSCAR;
elif [ -s ../CONTCAR ] && [ $skip_charg_step -eq 1 ]; then
    echo "Found ../CONTCAR but skipping copy since charge density has been calculated..."
else
    echo "No CONTCAR in $dir_name. exiting"
    exit
fi

if [ -s ../cline.out ] && [ "$cline" == "" ]; then
    cline=$(cat ../cline.out | grep command | gawk --source '{for(i=4;i<NF+1;i++){printf("%s ",$i)}}')
    echo "found cline for VASP setup: "$cline
    echo "Check that this is consistent with current use."
elif [ "$cline" != "" ]; then
    echo "Using cline supplied on calc_bands.sh command line"
    echo "cline: "$cline
fi

if [ "$concat_cline" != "" ]; then
    echo "Adding to cline the following options: "$concat_cline
    cline="$cline $concat_cline"
    echo "New cline= "$cline
fi


if [ $skip_charg_step -eq 0 ]; then
    echo "------------------ Calculating pre1 charge density -----------------------"
    ~/src/VASP_setup.sh $cline -i 2 -n -C  ;
    rm -f script.*.out;
    get_rand_tag;
    mv Script_$type"_"$RANDtag.sh Script_"$name"_$type"_"$RANDtag.sh;
    ./Script_"$name"_$type"_"$RANDtag.sh | tee script.pre1.out;
    mv OUTCAR OUTCAR-pre1
    mv OSZICAR OSZICAR-pre1
    rm -f Script_"$name"_$type"_"$RANDtag.sh;
else
    if [ -s OUTCAR-pre1 ] && [ -s CHGCAR ] && [ -s CHG ]; then
	echo
	echo "---- Skipping charge density step ----"
	echo "Removing RUN_LOOP_LOCK if it exists."; rm -f RUN_LOOP_LOCK;
	echo "Removing existing Script*, script*, job-*, etc. files..."
	rm -f Script* script* job-* PCDAT REPORT vasp.out vasprun.xml;
    else
	echo "Can't find exisiting charge density files. Exiting."
	exit
    fi
fi

echo
echo

echo "------------------ Calculating band structure ----------------------------"
~/src/VASP_setup.sh $cline -n -C -i 2 -m 11 ;
rm -f script.*.out;
get_rand_tag;
if [ $explicit_kpt_gen -eq 1 ]; then
    echo "Calculating kpoints explicity and giving them zero weight..."
    cat $kpts_band_file | gawk -f $GEN_KPTS > tmp.new.kpts;
    num_new_points=$(cat tmp.new.kpts | wc -l);
    echo "number of new kpoints is: "$num_new_points
    cat IBZKPT tmp.new.kpts > tmp.kpts;
    rm -f tmp.new.kpts;
    cat tmp.kpts | gawk --source '(NR==2){print $1+N}(NR!=2){print $0}' -v N=$num_new_points > KPOINTS;
    rm -f tmp.kpts;
else
    cp -f $kpts_band_file ./KPOINTS;
fi
mv Script_$type"_"$RANDtag.sh Script_"$name"_$type"_"$RANDtag.sh;
./Script_"$name"_$type"_"$RANDtag.sh | tee script.bands.out;
mv OUTCAR OUTCAR-band

rm -f tmp.* tempfile*;
echo "+++ bands done +++"
cd $cdir;

exit