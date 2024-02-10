#!/bin/bash

# Cluster directory
BASE=/home/majzoube

# check if running on cluster or desktop
if [ -d $BASE ]; then
    echo "Using BASE= "$BASE "to set PDTOP"
    PDTOP=$BASE/src/pdcalc
    export AWKPATH=$AWKPATH:$BASE/src/pdcalc:$BASE/awkfiles
    ORDER=$BASE/awkfiles/poscar_order.awk
else
    echo "Using HOME to set PDTOP"
    PDTOP=$HOME/src/pdcalc
    export AWKPATH=$AWKPATH:$HOME/src/pdcalc:$HOME/awkfiles
    ORDER=$HOME/awkfiles/poscar_order.awk
fi

#################################
script_name="pd_prep_data.sh"
script_version="2.9"
script_date="07 Nov 2017"
#################################

# version 2.9  07 Nov 2017
#  -- add symmetry of structure to info.dat file.
#
# version 2.8  14 Sep 2017
#  -- added bader charge calculations where those directories exist
#  -- only generate files for born charges where those charges were calculated
#
# version 2.7  25 Jul 2017
#  -- new version after moving old v1 stuff to archive and renaming v2
#     to pdcalc and creating all the packaging scripts.
#  -- put all the directories containing information from pd_prep_data
#     into the info/ folder and reference from there.
#
# version 2.6  22 Jul 2017
#  -- create directory for structures
# version 2.5  15 Oct 2015
#  -- create data files for E0-TSvib for easy plotting
#
# version 2.4  08 Sept 2015
#  -- collect Zeff (born effective charges) if available from OUTCAR
# version 2.3  03 Sept 2015
#  -- bug fix. Run CONTCAR through poscar_order or
#     the script fails to count the atoms properly
#     for cases like Z: 1 3 1 5
#
# version 2.2  24 Aug 2015
#  -- add switch to "rm -rf octave_work"
# 
# version 2.1  01 May 2014
#       -- add output of densities
#
#
# pdcalc V2
# 18 October 2013
#
# general phase diagram calculation with gases
# E. Majzoub
# UMSL

# defaults
dbg=0;
help=0;
isgas=0;
IgnoreSoftModes=0;
kill_octave_work=0;
MINDENSITY=0.2;
SoftModeCutoff=-1;
tmpcar="tmp.contcar.v4"
TMP_FILES="tmp.contcar.v4 tempfile.contcar.POSv4 temp"
UseModesFiles=0;

# Directory structure
WORK=octave_work;
INFO=$WORK/info;
MODS=$INFO/modes;
BADR=$INFO/bader;
CARS=$INFO/ccar;
ZEFF=$INFO/z_eff;
THRM=$INFO/e0-ts;

PD_INPUT=data.in; # main data file read by TD_TP

SYMSEARCH=`which symsearch`

################################################################
################################################################
declare SWITCH
while getopts "dhkC:IM" SWITCH; do
    case $SWITCH in
    h) help=1;;
    C) SoftModeCutoff=$OPTARG;;
    d) dbg=1;;
    I) IgnoreSoftModes=1; echo "WARN: ignoring soft modes!" ;;
    k) kill_octave_work=1 ;;
    M) UseModesFiles=1; echo "WARN: Using existing modes files" ;;	
    esac
done

if [ $help -eq 1 ]; then
    echo
    echo "Command line options:"
    echo
    echo "-d -- debug output"
    echo "-h -- show help"
    echo
    echo "-C -- change soft mode cutoff (default is 8 cm-1)"
    echo "-I -- ignore soft modes"
    echo "      WARN: soft modes are used as real"
    echo "-k -- rm -rf ./octave_work"
    echo
    echo "-M -- Use existing modes files (debugging only)"
    echo
    exit
fi

make_tmp_contcar () {
    # convert to V4 poscar style if needed
    isV5=`cat $contcar | awk '(NR==6 && $0!~"[0-9]"){print 1}(NR==6 && $0~"[0-9]"){print 0}'`;
    if [ $isV5 -eq 1 ]; then
	cat $contcar | awk '(NR!=6){print $0}' > tempfile.contcar.POSv4;
    else
	cat $contcar > tempfile.contcar.POSv4;
    fi
    
    # order the poscar
    if [ $dbg -eq 1 ]; then
	echo
	echo "----------- CONTCAR START "$contcar
	cat $contcar
    fi
    cat tempfile.contcar.POSv4 | igawk -f $ORDER > $tmpcar
    if [ $dbg -eq 1 ]; then
	echo "----------- CONTCAR ORDERED " $contcar
	cat $tmpcar
    fi
}

##################################################
##################################################

echo "==========================================="
echo "    $script_name  ver  $script_version"
echo "==========================================="

if [ -d $WORK ] && [ $kill_octave_work -eq 1 ]; then
    echo "# Removing $WORK directory..."
fi

# make octave_work directory
if [ ! -d $WORK ]; then
    echo "# Making directory $WORK"
    mkdir $WORK;
fi

# info directory must be made first
if [ -d $INFO ]; then
    echo "# Removing old $INFO directory"
    rm -rf $INFO;
fi
if [ ! -d $INFO ]; then
    echo "# Making directory $INFO"
    mkdir $INFO
    gawk --source 'BEGIN{printf("%-30s%10s%9s%7s%5s%12s%10s\n",tag,molwt,dens,gas,fu,en,sym);}' -v tag=tag -v molwt=molwtfu -v dens=density -v gas=isgas -v fu=fu -v en=epfu -v sym=sym >> $INFO/info.dat
fi

# Note that not all of the info/subdir are treated the same, so don't automate the following
# modes directory
if [ -d $MODS ] && [ $UseModesFiles -eq 0 ]; then
    echo "# Removing old $MODS directory"
    rm -rf $MODS;
fi
if [ ! -d $MODS ]; then
    echo "# --Making directory $MODS"
    mkdir $MODS
fi

# bader directory
if [ -d $BADR ]; then
    echo "# Removing old $BADR directory"
    rm -rf $BADR
fi
if [ ! -d $BADR ]; then
    echo "# --Making $BADR directory"
    mkdir $BADR
fi

# Zeff directory
if [ -d $ZEFF ]; then
    echo "# Removing old $ZEFF directory"
    rm -rf $ZEFF
fi
if [ ! -d $ZEFF ]; then
    echo "# --Making $ZEFF directory"
    mkdir $ZEFF
fi

# ccar directory
if [ -d $CARS ]; then
    echo "# Removing old $CARS directory"
    rm -rf $CARS
fi
if [ ! -d $CARS ]; then
    echo "# --Making $CARS directory"
    mkdir $CARS
fi

# E0-TS directory
if [ -d $THRM ]; then
    echo "# Removing old $THRM directory"
    rm -rf $THRM
fi
if [ ! -d $THRM ]; then
    echo "# --Making $THRM directory"
    mkdir $THRM
fi

#####################################################################
#####################################################################
echo "control_file" > $WORK/$PD_INPUT

if [ $IgnoreSoftModes -eq 1 ]; then
    vibflags="-I";
fi
if [ "$SoftModeCutoff" != "-1" ]; then
    vibflags=$vibflags" -C $SoftModeCutoff";
    echo "# using vibflags: "$vibflags;
fi
echo "# using vibflags: "$vibflags >> $WORK/$PD_INPUT;

############################################
# First loop over the structures
############################################

# first activate participating atoms
for i in OUTCAR*static; do
    tag_pre=${i##OUTCAR-}
    tag=${tag_pre%%-static}
    contcar=CONTCAR-${tag}

    if [ ! -s $contcar ]; then
	echo "# --- NOTICE 1 !!  $contcar is empty. Skipping."; continue;
    else
	make_tmp_contcar;	
    fi
    
    grep Z: $tmpcar > temp
    num_atom_types=$((`cat temp | wc -w `-1))
    atom_types=`grep Z: $tmpcar | awk ' {for (i=2;i<=NF;i++) { printf("%d ", $i) } printf("\n") } ' ` 
 
 # activate atoms
    for (( j=1; j<=$num_atom_types; j++ ))
      do
      elem=` echo $atom_types | awk -v choose=$j  ' { print $choose } ' `
      active[elem]=1
    done
done

echo " " | awk ' { printf("%-32s%-10s%-5s%-5s %-14s","phase","molwt","gas","use","static(eV/fu)") } ' >> $WORK/$PD_INPUT

for i in {1..100}; do
    if [ "${active[i]}" = "1" ];  then
	elem_name=` echo $i | awk -f $PDTOP/Get_Elem_Name.awk `
	echo $elem_name | awk  ' { printf("%5s", $1) } ' >>  $WORK/$PD_INPUT
    fi
done

echo " " | awk ' { printf(" end\n") } ' >> $WORK/$PD_INPUT


############################################
# Second loop over the structures
############################################

# now grab data from each phase and print
for i in OUTCAR*static ; do
    tag_pre=${i##OUTCAR-}
    tag=${tag_pre%%-static}
    
    static=OUTCAR-${tag}-static
    dynamic=OUTCAR-${tag}-dynamic
    contcar=CONTCAR-${tag}

    if [ ! -s $contcar ]; then
	echo "# --- NOTICE 2 !!  $contcar is empty. Skipping."; continue;
    else
	make_tmp_contcar;	
    fi

    if [ $dbg -eq 1 ]; then
	echo "##########   getting data from tag= "$tag "   ###############";
    fi

# check if this is a gas molecule
# calculate the density and check to see if this is a gas molecule in a big box
    density=`cat $tmpcar | igawk -f $PDTOP/contcar_info.awk | grep Density | awk '{print $3}'`
    if [ $dbg -eq 1 ]; then
	echo "density= "$density
    fi
    isgas=`echo $density | gawk --source '($1>MD){print 0}($1<=MD){print 1}' -v MD=$MINDENSITY`;

    # get the symmetry of the structure for info.dat
    if [ $isgas -eq 1 ]; then
	sym="gas";
    else
	sym=$($SYMSEARCH -f $tmpcar -r 0.05 | tail -1 | gawk '{print $5}')
    fi
    
# grab energies (this only works because there are
# two spaces between 'free' and 'energy' for the final static energy)
    energy=`grep "free  energy" $static | tail -1 | awk ' { print $5 } ' `
    if [ $dbg -eq 1 ]; then
	echo "static energy= "$energy;
    fi
# grab atom_types
    head -1 $tmpcar > temp
    num_atom_types=$((`cat temp | wc -w `-1))
    atom_types=`grep Z: $tmpcar | awk ' {for (i=2;i<=NF;i++) { printf("%d ", $i) } printf("\n") } ' `
    if [ $dbg -eq 1 ]; then
	echo "num_atom_types= "$num_atom_types
	echo "atom_types= "$atom_types
    fi


 #  grab atom counts
    atom_counts=` sed -n 6p $tmpcar`

    unset atom_count
 #also find minimum atom count in this loop
    atom_count_min=1000
    for ((j=1; j<=$num_atom_types; j++))
      do
      atom_type=`echo $atom_types | awk -v choose=$j ' { print $choose } ' `
      atom_count[atom_type]=`echo $atom_counts | awk -v choose=$j ' { print $choose } ' `
      if [ "$atom_count_min" -gt "${atom_count[atom_type]}" ]; then
	  atom_count_min=${atom_count[atom_type]}
      fi
    done

# determine number of formula units
    for ((j=$atom_count_min; j>0 ; j-- ))
      do
  #test if divides by other atoms
	if [ $dbg -eq 1 ]; then
	    echo "j_loop= "$j "  atom counts= "$atom_counts
	fi
      fu_found=`echo $atom_counts | awk -v fu=$j ' BEGIN{ divisor = "true"  } { for (i=1 ; i<=NF; i++)  \
                { if ($i % fu != 0)  {divisor = "false"}};  print divisor  } '`
      if [ $fu_found == "true" ];then
	  fu=$j
	  if [ $isgas -eq 1 ]; then
	      fu=1; # if molecule, we want only 1fu (e.g. B2H6 is not BH3)
	  fi
	  break
      fi
    done
    if [ $dbg -eq 1 ]; then
	echo "number of fu= "$fu
    fi

 #generate atom count_matrix
    printed_counts=""
    for j in {1..50}
      do
      if [ "${active[j]}" = "1" ]; then
	  if [ -z ${atom_count[j]} ]; then
	      printed_counts="$printed_counts 0 "
	  else
	      printed_counts="$printed_counts ${atom_count[j]} "
	  fi
      fi
    done
    if [ $dbg -eq 1 ]; then
	echo "printed_counts= "$printed_counts
    fi


# get the molecular weight of the compound
    molwt=`cat $tmpcar | igawk -f contcar_info.awk | grep amu | awk '{print $4}'`;
    molwtfu=`echo | awk --source 'BEGIN{printf("%.3f",MW/FU);}' -v MW=$molwt -v FU=$fu`
    epfu=`echo " scale=10; $energy/$fu " | bc`;
    if [ $dbg -eq 1 ]; then
	echo "Mol wt of "$contcar "= "$molwt  "no. fu= "$fu " molwt/fu= "$molwtfu;
	echo "eV/f.u. = "$epfu
    fi

# generate vibrational file with fu argument and check for imaginary modes
    echo "# calculating free energy, entropy for: "$dynamic

    if [ $UseModesFiles -eq 0 ]; then
	$PDTOP/vib_energy.sh -f $dynamic -c $contcar -T 2000 -u $fu -i 1 -g $isgas  $vibflags > tmp.vib.file;
	if [ $? -eq 1 ]; then
	    echo "!! Error !!: vib_energy.sh failed for $file! Investigate!"
	fi
	cat $dynamic | grep THz > $MODS/${tag}.mods.dat;
    fi
    if [ $UseModesFiles -eq 1 ]; then
	temp_dynamic=$MODS/${tag}.mods.dat;
	$PDTOP/vib_energy.sh -f $temp_dynamic -c $contcar -T 2000 -u $fu -i 1 -g $isgas  $vibflags  > tmp.vib.file;
	if [ $? -eq 1 ]; then
	    echo "!! Error !!: vib_energy.sh failed for $file! Investigate!"
	fi
    fi
	
    img_flag=`cat tmp.vib.file | grep IMG | wc -l`;

    if [ $img_flag -gt 0 ]; then
	echo "-------> !! File $tag has imaginary modes. Skipping this file. !!"
    else

	cat tmp.vib.file > $WORK/${tag}.dat
	cat tmp.vib.file | gawk --source '{print $1,$2+EPFU}' -v EPFU=$epfu > $THRM/${tag}.+E0.dat

	nfld=5; # need to increase the number of fields if adding new columns
	echo $tag " " $molwtfu " " $isgas " " $epfu " " $printed_counts | \
	    awk -v fu=$fu -v NFLD=$nfld --source \
            '{ printf(" %-30s %8.2f %4d  1  %14.6f   ", $1, $2, $3, $4);\
                                for(i=NFLD; i<=NF; i++) { printf("%5d", $i/fu ) };\
                                printf("\n") }' >> $WORK/$PD_INPUT
    fi


    # print information to info files
    gawk --source 'BEGIN{printf("%-30s%10.2f%9.3f%7d%5d%12.3f%10s\n",tag,molwt,dens,gas,fu,en,sym);}' -v tag=$tag -v molwt=$molwtfu -v dens=$density -v gas=$isgas -v fu=$fu -v en=$epfu -v sym=$sym >> $INFO/info.dat


    # print out the born effective charges, if there are any in the OUTCAR
    n_born=0;
    n_born=$(cat $dynamic | grep "BORN EFFECTIVE CHARGES" | wc -l)
    if [ $n_born -gt 0 ]; then
	$PDTOP/get_born_charges.sh -C $contcar -O $dynamic > $ZEFF/$tag.born_zeff;
    fi

    # print out the bader charges
    # get the directory where the bader.dat file is located
    bader_dir_pre1=$(ls -l $static | gawk '{print $NF}')
    bader_dir_try1=${bader_dir_pre1%%/OUTCAR*}
    bader_dir_try2=${bader_dir_pre1%%/phon/OUTCAR*}
    if [ $dbg -eq 1 ]; then
	echo "bader_dir_try1= "$bader_dir_try1
	echo "bader_dir_try2= "$bader_dir_try2
    fi

    bader_list="$bader_dir_try1/bader $bader_dir_try2/bader"
    for bb in $bader_list; do
	if [ -d $bb ] && [ -s $bb/bader.dat ]; then
	    BDIR=$bb;
	    BOPTS="-C $contcar -O $static -D $BDIR"
	    $PDTOP/get_bader_charges.sh $BOPTS > $BADR/$tag.bader;
	fi	
    done
    
    # save the static contcar to the ccar directory
    cat $contcar > $CARS/ccar-$tag
    
done

echo " end" >> $WORK/$PD_INPUT
echo >> $WORK/$PD_INPUT
cat CONTROL >> $WORK/$PD_INPUT

# Make tables of the charge data for bader and born directories
cdir=$(pwd)
cd octave_work/info/z_eff
make_table_ave_charg > table.dat; cd $cdir;
cd octave_work/info/bader
make_table_ave_charg > table.dat; cd $cdir;

if [ $dbg -eq 0 ]; then
    rm -f $TMP_FILES
    rm -f tmp.vib.file;
fi

echo " +++ Done +++"

exit
