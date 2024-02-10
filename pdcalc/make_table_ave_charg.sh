#!/bin/bash

# get the elements from ../../data.in
elms=$(cat ../../data.in | grep phase | gawk '{for(i=6;i<NF;i++){printf("%s ",$i);}}');
Qlist=$(for E in $elms; do printf "Q_%s " $E; done)
Zlist=$(for E in $elms; do printf "Z_%s " $E; done)

function get_data () {

    echo "#_file "$Qlist

    for file in *; do
	if [ "$file" == "table.dat" ]; then continue; fi
	   
	empty=0;
	
	empty=$(cat $file | grep Exiting | wc -l)
	if [ $empty -eq 1 ]; then
	    continue;
	fi

	printf "%10s " $file

	for Z in $Zlist; do
	    z=0;
	    z=$(cat $file | gawk --source '($1==ZZ){print $NF}' -v ZZ=$Z );
	    if [ "$z" == "" ]; then
		printf "%8s " "-----"
	    else
		printf "%+-8.2f " $z
	    fi
	done
	printf "\n"
        
done
    
}

get_data | column -t

exit
