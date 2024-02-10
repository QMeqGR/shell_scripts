#!/bin/bash

# merge data.in files
# use: merge.sh data1.in data2.in ... dataN.in : H  B  Al Si Cl
# example:
# ~/src/pdcalc_v2/merge_data_files.sh data_al-h.in data_h-b-si.in : H B Li Al Si Cl 
# note the use of the colon ':' to separate the elements
#

dbg=0;

if [ $# -eq 0 ]; then
    echo
    echo "use: merge.sh data1.in data2.in ... dataN.in : H  B  Al Si Cl"
    echo
    echo "Note: this script does not merge the lower half of the data files"
    echo "      containing the CONTROL data. It must be added in by hand."
    echo "Note: this script does not merge the info/info.dat data or"
    echo "      anything in the info directory."
    exit
fi

# get the number of arguments
all_args="$@"
Ndat=$(echo $all_args | gawk -F':' '{print $1}' | gawk '{print NF}')
datfiles=$(echo $all_args | gawk -F':' '{print $1}')
elms=$(echo $all_args | gawk -F':' '{print $2}')

if [ $dbg -eq 1 ]; then
    echo "all_args= "$all_args
    echo "Ndat= "$Ndat
    echo "datfiles= "$datfiles
    echo "elms= "$elms
fi

####################################################
####################################################
cat > tmp.awk <<EOF
BEGIN{
phase_line=0;
}
(\$1=="phase"){phase_line=NR;}
(phase_line>0 && \$1!="end" && NR>phase_line){
  print \$0;
}
(phase_line>0 && \$1=="end" && NR>phase_line){exit;}

EOF


function print_line_pre_num () {
    dat=$1;
    line=$2;
    cat $dat | gawk -f tmp.awk | gawk --source '(NR==LINE){printf("%s %s %s %s %s ",$1,$2,$3,$4,$5);}' -v LINE=$line;
}

function print_line_col () {
    dat=$1; line=$2; col=$3;
    cat $dat | gawk -f tmp.awk | gawk --source '(NR==LINE){printf("%s ",$COL);}' -v LINE=$line -v COL=$col;
}

####################################################


function get_elm_nums () {
for dat in $datfiles; do

    ncompounds=$(cat $dat | gawk -f tmp.awk | wc -l);
    data_elms=$(cat $dat | grep phase | gawk '{for(i=6;i<NF;i++){printf("%s ",$i);}}');
    
    if [ $dbg -eq 1 ]; then
	echo "reading dat= "$dat;
	echo "ncompounds= "$ncompounds;
    fi

    if [ $dbg -eq 1 ]; then
	echo -n "elements in file: "$data_elms
	echo
    fi

    line=0;
    list=$(gawk --source 'BEGIN{for(i=0;i<N;i++){printf("%d ",i+1);}}' -v N=$ncompounds);

    for line in $list; do
	print_line_pre_num $dat $line

	# inner loop
	for elm in $elms; do
	    col=0; found=0;
	    for element in $data_elms; do
		col=$((col+1));
		if [ "$elm" == "$element" ]; then
		    # offset is 5 before the atom number start
		    print_line_col $dat $line $((col+5))
		    found=1; continue;
		fi
	    done
	    if [ $found -eq 0 ]; then
		echo -n "0 "
	    fi
	done #end inner loop
	gawk 'BEGIN{printf("\n");}'

    done
    
done
}

####################################################
####################################################
####################################################
echo "phase molwt gas  use  static(eV/fu) $elms end" > tmp.merge.in;
get_elm_nums | sort | uniq >> tmp.merge.in

cat tmp.merge.in | column -t

rm -f tmp.awk tmp.merge.in

exit
