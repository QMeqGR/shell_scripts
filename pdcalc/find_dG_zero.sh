#!/bin/sh

#
# The purpose of this script is to run through temperature
# and look for a stationary point for dG, indicating
# that a reaction can take place.
#
# If a stationary point is identified, then the script
# will go back and calculate the dH value at the desired
# temperature that differs from the critical temp (stationary
# point temperature).
#

script_name="find_dG_zero.sh"
script_date="August 2015"
script_vers="0.1"
version=$script_vers



# Cluster directory
BASE=/home/majzoube

# check if running on cluster or desktop
if [ -d $BASE ]; then
#    echo "Using BASE= "$BASE "to set PDTOP"
    PDTOP=$BASE/src/pdcalc
    export AWKPATH=$AWKPATH:$BASE/src/pdcalc:$BASE/awkfiles
    ORDER=$BASE/awkfiles/poscar_order.awk
else
#    echo "Using HOME to set PDTOP"
    PDTOP=$HOME/src/pdcalc
    export AWKPATH=$AWKPATH:$HOME/src/pdcalc:$HOME/awkfiles
    ORDER=$HOME/awkfiles/poscar_order.awk
fi

# point to rxn_thermo
RNT=$PDTOP/rxn_thermo.sh


# first verison 0.1 27 Aug 2015

######################################
# defaults
help=0;
dbg=0;
DT=20;
LHS="";
maxtemp=2000;
PR_Pa="101325"; # pressure in Pa
RHS="";
RHStoten=0;
T="300"; # temperature default in K
Tref=""; # temperature of stationary point for G
window=50;
in_window=0;


######################################
declare SWITCH
while getopts "dD:hL:P:r:R:T:w:" SWITCH; do
    case $SWITCH in
    d) dbg=1 ;;
    D) DT=$OPTARG ;;
    h) help=1 ;;
    L) LHS=$OPTARG ;;
    P) PR_Pa=$OPTARG ;;
    R) RHS=$OPTARG ;;
    T) T=$OPTARG ;;
    w) window=$OPTARG ;;
    esac
done



if [ $# -eq 0 ] || [ $help -eq 1 ]; then
    echo
    echo "#######################"
    echo "#  "$script_name
    echo "#######################"
    echo
    echo "Version "$version
    echo $ver_date
    echo
    echo "use: "$script_name" -L \"1 CaH2\" -R \"1 Ca 1 hydrogen\"  [dD:hL:P:R:T:w:]"
    echo "     Script is to be run in the octave_work directory"
    echo "     of a pdcalc calculation"
    echo
    echo "    -h --- show this help"
    echo "    -d --- debug (default is OFF)"
    echo
    echo "         ** EQUATION INPUT **"
    echo "            example: 1 CaH2 --> 1 Ca 1 hydrogen"
    echo "            note: no '+' sign"
    echo "            coefficients must be given, even if '1'"
    echo
    echo "    -L -*- LHS of rxn eqn"
    echo "           e.g. -L \"2 CaH2\""
    echo "    -R -*- RHS of rxn eqn"
    echo "           e.g. -R \"2 Ca 2 H2\""
    echo
    echo "    -P -*- pressure in Pa (default $PR_Pa)"
    echo "    -T -*- desired temperature in K (def "$T")"
    echo "    -D -*- temperature step for dG=0 search (default $DT)"
    echo "    -w -*- energy window (default $window)"
    echo
    echo
    echo Eric Majzoub
    echo University of Missouri - St. Louis
    echo August 2015
    echo
    exit
fi


#############################################################
#############################################################
nlist=$(gawk --source 'BEGIN{for(i=10;i<MAXTEMP;i+=dt){printf("%d ",i);}}' -v dt=$DT -v MAXTEMP=$maxtemp)

# first need to find the stationary point
echo "###############################################"
echo "Searching for stationary point (dG=0)"
echo
for n in $nlist; do
    #    echo "n= "$n
    out1=$($RNT -P $PR_Pa -L "$LHS" -R "$RHS" -T $n -r $n | tail -1)
    dE=$(echo $out1 | gawk '{print $4}');
    TdS=$(echo $out1 | gawk '{print $10}');
    printf "%5s%8d%8s%12.3e%8s%12.3e\n" "T=" $n "dE=" $dE "TdS=" $TdS
    #echo $out1
    
    err=$(echo $dE $TdS | gawk '( $2 > $1 ){print 1}')
    if [ "$err" == 1 ]; then
	echo "TdS > dE at T= "$n
	echo $out1
	break
    fi
    ans=$(echo $dE $TdS $window | gawk '( ($1-$2)^2 < $3 ){print 1}')
    if [ "$ans" == "1" ]; then
	echo $out1
	out_save=$out1
	in_window=1;
    fi
done

if [ $in_window -eq 1 ]; then
    echo "Found stationary G"
    echo $out_save
    Tref=$(echo $out_save | gawk '{print $8}')
    echo "Using Tref= "$Tref " and T(desired)= "$T
    $RNT -P $PR_Pa -L "$LHS" -R "$RHS" -T $T -r $Tref -d
else
    echo "!! Window of dE and TdS not satisfied. !!"
    echo "   Reaction may not be favorable. Or try increasing window."
    echo
    exit
fi



exit
