#!/bin/sh

script_version=1.0.0
script_name="icsd_reduce.sh"
script_date="Thu Jan 10 2008"


#############################################
# defaults
help=0;
dbg=0;
file=allstructs.txt;
get_icsd=0;
get_xrd=0;
get_pos=0;

stf1=temp_file_1.${script_name%%.sh}

declare SWITCH
while getopts "df:hPx" SWITCH; do
    case $SWITCH in
    d) dbg=1 ;;
    f) file=$OPTARG ;;
    h) help=1 ;;
    i) get_icsd=1 ;;
    P) get_pos=1 ;;
    x) get_xrd=1 ;;
    esac
done

if [ ! -e "allstructs.txt" ]; then
    echo "No allstructs.txt file found. Set on command line."
    echo
    exit
fi
    

if [ $help -eq 1 ]; then
    echo
    echo "#######################"
    echo "#    icsd_cnvrt.sh    #"
    echo "#######################"
    echo
    echo "version: "$script_version
    echo "last update: "$script_date
    echo
    echo "use: icsd_cnvrt.sh -f infile  [-df:hPx]"
    echo 
    echo
    echo "    -h --- show this help"
    echo "    -d --- debug"
    echo
    echo "    -f --- file with icsd stuctures (def: allstructs.txt)"
    echo "    -i --- get icsd files and quit (named struct_n)"
    echo "    -P --- produce .poscar files"
    echo "    -x --- produce tth.dat powder patterns"
    echo
    echo Eric Majzoub
    echo Sandia National Laboratories
    echo original script date: 10 Jan 2008
    echo
    echo
    exit
fi


#########################
# Functions
#########################
function make_awk_file() {

cat > $stf1.awk <<EOF

BEGIN{
 N_count=0;
 pnt_flag=0;
 # set N_num via -v option;
}

(\$1=="N" && pnt_flag==1){pnt_flag=0;}
(\$1=="N" && pnt_flag==0){
    if ( N_num == N_count++ ){
	pnt_flag=1;
	print \$0;
    }
}
(\$1=="C" && pnt_flag==1){print \$0;}
(\$1=="A" && pnt_flag==1){print \$0;}


EOF

}

function clean_up_temp_files() {

    rm -f $stf1 $stf1.awk;
    if [ $get_icsd -eq 0 ]; then
	rm -f struct_*
    fi

}

#########################
# Script starts here
#########################

echo
echo "Using file "$file

echo "Removing old struct_* files... hope you didn't need them."
rm -f struct_*;

make_awk_file;
cat $file | awk '($1!="S"&&$1!="T"){print $0}' > $stf1

n_files=`cat $stf1 | awk '($1=="N"){print $0}' | wc | awk '{print $1}'`
echo "number of structures = "$n_files;

file_list=`echo $n_files | awk '{for(i=0;i<$1;i++){printf("%d ",i);}}'`
echo "file_list= "$file_list;

for outfilen in $file_list; do
    cat $stf1 | awk -f $stf1.awk -v N_num=$outfilen > struct_$outfilen;
done

if [ $get_xrd -eq 1 ]; then
    for xrd_file in `ls struct_*`; do
	echo "Generating tth.dat file for "$xrd_file
	icsd_cnvrt -f $xrd_file -x;
	mv $xrd_file.tth.dat xrd_$xrd_file.tth.dat
    done
fi
if [ $get_pos -eq 1 ]; then
    for pos_file in `ls struct_*`; do
	echo "Generating poscar file for "$pos_file
	icsd_cnvrt -f $pos_file -P;
	mv POSCAR POSCAR_$pos_file
    done
fi


if [ $dbg -eq 0 ]; then
    echo "Cleaning up temp files..."
    clean_up_temp_files;
fi

echo
exit
