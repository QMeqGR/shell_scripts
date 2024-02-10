#!/bin/bash

#################################################
script_name="make_cv_fits.sh";
script_version="1.1"
script_date="08 Sept 2017"

# v 1.1  08 Sept 2017
# updated to work with latest version of pdcalc scripts
# fixed some issues and made the dbg output more meaningful

# defaults
dbg=0;
help=0;
datafile=data.in;
STANDARDS="hydrogen N2 Li Mg B C Si S"

######################################
declare SWITCH
while getopts "dhS:" SWITCH; do
    case $SWITCH in
    d) dbg=1 ;;
    h) help=1 ;;
    S) STANDARDS=$OPTARG ;;
    esac
done


if [ $help -eq 1 ]; then
    echo
    echo "#######################"
    echo "#      "$script_name
    echo "#######################"
    echo
    echo "Version "$version
    echo $ver_date
    echo
    echo "use: $script_name -[options]"
    echo 
    echo "    -h --- show this help screen"
    echo "    -d --- debug (default is OFF)"
    echo
    echo "    -S -*- set standards (must be in data.in)"
    echo "           e.g. -S \"Si S hydrogen B\" "
    echo
    echo Eric Majzoub
    echo University of Missouri - St. Louis
    echo 2016
    echo
    echo
    exit
fi


##################################################
# standard states
##################################################
std_state=($STANDARDS);
n_states=${#std_state[@]};
if [ $dbg -eq 1 ]; then
    echo "std_state= "${std_state[@]};
    echo "n_states= "$n_states;
fi
states_loop=`awk --source 'BEGIN{for(i=0;i<M;i++){printf("%d ",i)};}' -v M=$n_states`;
if [ $dbg -eq 1 ]; then
    echo "states_loop= "$states_loop
fi

##################################################
# FUNCTIONS
##################################################
function get_static_energy (){
    found=$(cat $datafile | gawk --source '($1==TAG && NF>5){print $0}' -v TAG=$tag | wc -l);
    if [ $found -eq 1 ]; then
	if [ $dbg -eq 1 ]; then
	    cat $datafile | gawk --source '($1==TAG && NF>5){print $0}' -v TAG=$tag;
	fi
	# change the column number here (5 right now) if adding columns to data.in
	static=`cat $datafile | gawk --source \
    		    	       '($1==TAG && NF>5){printf("%f",$5);}' -v TAG=$tag`
    else
	echo "--- !!!  Cannot find standard element $tag "
	static="-1.0"
    fi
}

function isgas (){
    gas=`cat $datafile | gawk --source \
     '(NR>3 && NF==10 && $1==TAG){print $2}' -v TAG=$tag`;
}


function get_formation_energy (){
    if [ $dbg -eq 1 ]; then
	echo "Getting formation energy for "$tag
    fi
    for std in $states_loop; do
	#echo "tag= "$tag "  std_state= "${std_state[$std]};
	if [ "$tag" == "${std_state[$std]}" ]; then
	    echo "tag= "$tag " is a standard. Formation energy = 0.";
	    return;
	fi
    done

    total_en=$static;
    if [ $dbg -eq 1 ]; then
	echo "total_en (start)= "$total_en;
    fi

    # start reading at column 6. This needs updating if the
    # format for data.in changes!!!!
    atoms=(`cat $datafile | awk --source '($1=="phase" && NF>4)\
    { for(i=6;i<NF;i++){printf("%s ",$i);} }' -v TAG=$tag`);
    num_at_types=${#atoms[@]};
    num_each_atom=(`cat $datafile | awk --source '($1==TAG && NF>4)\
    { for(i=6;i<=NF;i++){printf("%d ",$i);} }' -v TAG=$tag`);
    num_at_types_loop=`awk --source 'BEGIN{for(i=0;i<M;i++){printf("%d ",i)};}'\
                       -v M=$num_at_types`;

    if [ $dbg -eq 1 ]; then
	echo "num_at_types= "$num_at_types;
	echo "atoms=         "${atoms[*]};
	echo "num_each_atom= "${num_each_atom[*]};
    fi

    for atom in $num_at_types_loop; do

	if [ ${num_each_atom[$atom]} -eq 0 ]; then
	    continue;
	fi

	at=${atoms[$atom]};
	if [ $dbg -eq 1 ]; then
	    echo "* Searching for atom $at"
	fi

	for std in $states_loop; do

	    standard=${std_state[$std]};
	    if [ "$standard" == "hydrogen" ]; then
		standard="H";
	    fi
	    match=`echo $at $standard | gawk --source\
                   '{n1=match($2,$1); n2=match($1,$2); if(n1!=0 && n2!=0){print 1;}else{print 0;}}'`;

	    if [ $match -eq 1 ]; then

		num_ats=${num_each_atom[$atom]}
		n_std=`echo $num_ats ${std_num_ats[$std]} | gawk '{printf("%f",$1/$2);}'`;
		total_en=`echo $total_en $n_std ${std_enrgy[$std]} \
                          | gawk '{printf("%f",$1-$2*$3);}'`;
		if [ $dbg -eq 1 ]; then
		    echo "* n_std= $n_std   total_en= "$total_en;
	            printf "match: atom= %2s  stdrd[%s]= %2s  num_ats= %d\n" "$at" "$std" "$standard" "$num_ats"
	    fi

		break;
	    fi
	done
	if [ $match -eq 0 ]; then
	    echo "!! --> No match found for atom $at. Formation energy will be wrong!!"
#	    total_en="-1"
	  #	    return;
	fi
    done

    #convert to kJ/mol
    total_en=`echo $total_en | gawk '{printf("%.2f",$1*96.48306883);}'`;
    return;
}



###########################################
# Script begins here
###########################################
echo "##################################################"
echo "# $script_name, v $script_version, $script_date"
echo "# E. Majzoub, University of Missouri - St. Louis"
echo "##################################################"
echo
echo "# Using standards: $STANDARDS"

std_enrgy=($states_loop);
std_num_ats=($states_loop);
for std in $states_loop; do

    tag=${std_state[$std]};
    get_static_energy;
    std_enrgy[$std]=$static;

    if [ $dbg -eq 1 ] && [ $found -eq 1 ]; then
	echo "standard state= "${std_state[$std]};
	echo "tag= "$tag;
	echo "static= "$static
    fi

    if [ "$tag" == "hydrogen" ] || [ "$tag" == "N2" ]; then
	std_num_ats[$std]=2;
    else
	std_num_ats[$std]=1;
    fi
done
if [ $dbg -eq 1 ]; then
    echo "std_enrgy= "${std_enrgy[@]};
    echo "std_num_ats= "${std_num_ats[*]};
fi



echo "############################################"
echo "# Starting main loop"
echo "############################################"
echo

##################################################
##################################################
# This should convert the eV/atom K or eV/fu K into J/mol K
for file in *.dat; do
    
    if [ "$file" == "$datafile" ]; then
	continue;
    fi

    # get the formation energy
    tag=${file%%.dat};
    echo "$tag"

    get_static_energy;

    # calculate the formatin energy
    total_en=0;
    get_formation_energy;

    echo "Atomization energy at 0K: "`echo "" | awk --source '{printf("%20.1f\n",STAT*96.48306883);}' -v STAT=$static` " kJ/mol";
    echo "Formation energy at 0K:" $total_en " kJ/mol";
    echo "Entropy at 298K: "`cat $file | gawk --source '($1>=298 && $1<299){printf("%20.1f\n",$3/1.0364e-5);}'` " J/mol K"

    cat $file | gawk --source '($1>=0 && $1<=1000){printf("%10.2f%20.10f\n", $1, $4/1.0364e-5);}' > tmp.cvfit.out;

    echo "Fitted Cv: 0-300K, T= a0 + a1*T + a2*T**2 + a3*T**3"
    gnufit -f tmp.cvfit.out -p 3 -m 0 -M 300 -q | tee tmp.gnufit.out;
    echo "Fitted Cv: 300-1500K, T= a0 + a1*T + a2*T**2 + a3*T**3"
    gnufit -f tmp.cvfit.out -p 3 -m 300 -M 1000 -q | tee tmp.gnufit.out;
    echo

rm -f tmp.cvfit.out tmp.gnufit.out;

done
