#!/bin/sh



# Use: $ make_named_symlinks.sh /Users/cluster/forge/pack B*H*

# version 0.3   10 July 2017
# update so it only looks in those directories containing phon/
#

# version 0.2, 15 Nov 2016
# Try to do this intelligently and check that:
# 1. the static energies are all the same.
# 2. that the phonons may be from lower encut calcs for gases
# 3. other consistency checks...
#


BASE=$1
PATTERN=$2

ENCUT_STATIC=600;

if [ "$BASE" == "" ] || [ "$PATTERN" == "" ]; then
    echo
    echo  "Use: $ make_named_symlinks.sh BASE_DIR PATTERN"
    echo  "e.g.: $ make_named_symlinks.sh /Users/cluster/forge/pack B*H*"
    echo
    exit
fi

echo "BASE= "$BASE
echo "PATTERN= "$PATTERN

# find directories containing the OUTCAR files
file_locations=$(find $BASE -type d | grep "$PATTERN" | grep "phon")

for dir_pre1 in $file_locations; do

    echo "dir_pre1= "$dir_pre1
    dir=${dir_pre1%%/phon}
    echo "dir= "$dir;

    # name will depend on the directory structure
    # grabs directory name
    name5=$(echo $dir | gawk -F'/' --source '{print $5}');
    # takes run_2 piece and returns 2
    name6=$(echo $dir | gawk -F'/' --source '{print substr($6,4)}');
    # takes P_12 piece and returns 12
    name8=$(echo $dir | gawk -F'/' --source '{print $8}' | gawk -F'_' --source '{print $2}');
    name=$name5"_r"$name6"p"$name8

    
    echo "Looking in directory: #########  " $dir " ##########";
    outcars=$(ls $dir/OUTCAR*);
    echo "outcars= "$outcars
    if [ -L $dir/OUTCAR ]; then
	static=OUTCAR;
	echo "Using static: "$dir/$static
    else
	# old code that should not be necessary any longer
	outcar_dashes=$(ls $dir/OUTCAR-*);
	echo "outcars_dashes= "$outcar_dashes
	num_outcars=$(ls $dir/OUTCAR-* | wc -l);
	echo "num_outcars= " $num_outcars;
	static=OUTCAR-$num_outcars
	echo "Using static: "$dir/$static
    fi
    encut_static=$(cat $dir/$static | grep "ENCUT" | gawk '{print $3}')
    echo "Cutoffs:  outcar           ENCUT_STATIC"
    echo "          $encut_static            $ENCUT_STATIC"
    echo
    echo  "Using name= "$name
    echo  "Acceptable? : ('y' for yes, 'n' to enter name manually, 's' to skip)"
    read acceptable;
    if [ "$acceptable" == "y" ]; then
	echo "Name = "$name
    elif [ "$acceptable" == "n" ]; then
	echo "Enter name: "
	read name;
    elif [ "$acceptable" == "s" ]; then
	echo "skiping..."
	continue
    fi	
	
    echo "........Linking CONTCAR and static OUTCAR from "$dir
    ln -sf $dir/CONTCAR ./CONTCAR-$name;
    ln -sf $dir/$static ./OUTCAR-$name-static;
    echo
    
    echo "Finding phonon directories..."
    # find directories containing the ./phon files
    phon_dirs=$(find $dir -name "*phon*" -type d)
    echo "Phonon directories: " $phon_dirs
    for phon_dir in $phon_dirs; do
	phon_outcars=$(ls $phon_dir/OUTCAR*);
	echo "phon_outcars= "$phon_outcars
	phon_outcar=${phon_outcars##/*/}
	echo "phon_outcar= "${phon_outcars##/*/}
	if [ "$phon_outcar" == "OUTCAR" ]; then
	    echo "......Linking phonon (dynamic) outcar"
	    ln -sf $phon_dir/OUTCAR ./OUTCAR-$name-dynamic;
	    echo " ---- DONE with " $dir "  ----- ";
	    echo
	    break; # break current phon loop
	else
	    echo "!!!!!!!!!! No phon OUTCAR found !!!!!!!!!!!!"
	fi
    done

done
