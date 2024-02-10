#!/bin/sh

script_name="nn_dist.sh"
script_date="09 Aug 2017"
script_version="1.3.1"

BASE=/home/ehm
VT_TOP=$BASE/src/VASP_TOOLS
AWKPATH=$AWKPATH:$BASE/$VT_TOP

# version 1.3.1 : 09 Aug 2017. Add switches to pick z,Z. 
# version 1.3.0 : add switch to look at xmin..xmax range for
#                 all pairs of atom types
# version 1.2.1 : add "def_rer =" tag
# version 1.2   : autodetect V5 CONTCAR format
# version 1.1   : check Z: line for extra space after Z1 Z2...

# defaults
dbg=0;
element_names=0;
file="CONTCAR";
help=0;
isV5=0;
OPTS="" # Additional options to contcar_pdf
pegsout=0;
pegsstring="def_rer = ";
range="";
setZ="-1";

declare SWITCH
while getopts "dEf:hpR:Z:" SWITCH; do
    case $SWITCH in
    d) dbg=1 ;;
    E) element_names=1 ;;
    f) file=$OPTARG ;;
    h) help=1 ;;
    p) pegsout=1 ;;
    R) range=$OPTARG ;;
    Z) setZ=$OPTARG ;;
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
    echo "use: "$script_name"  -[options]"
    echo "                     -*- denotes option requires an argument"
    echo
    echo "    -h --- show this help list"
    echo "    -d --- debug (default off)"
    echo
    echo "    -f -*- input file (default "$file")"
    echo "    -E --- use element names in output (default off)"
    echo "    -p --- add \"def_rer =\" tag format for PEGS"
    echo "    -Z -*- specify Zs as Z1:Z2. e.g. -Z 13:16"
    echo
    echo "        -- RANGE OPTIONS --"
    echo
    echo "    -R -*- select range to search over (e.g. \"2.1:3.4\")"
    echo "             If -Z is set, this option will give the"
    echo "             coordination number of Z1 with the number of Z2s."
    echo
    echo
    echo Eric Majzoub
    echo University of Missouri, St. Louis
    echo 11 Jan 2008
    echo
    exit
fi

#####################
# functions
#####################
function make_script_awk() {

cat > get_elm_tmp.awk <<EOF
@include "awklib.awk"

{printf("%s",ztoelm(\$1));}

EOF
}

function autodetectV5 {
    isV5=`cat $file | awk '(NR==6 && $0!~"[0-9]"){print 1}(NR==6 && $0~"[0-9]"){print 0}'`;
}

function get_num_for_Z () {
    select_Z=$1;

    countZ=0;
    for Z in $z_vals; do
	countZ=$((countZ+1));
	if [ $select_Z -eq $Z ]; then
	    select_NZ=$countZ;
	else
	    continue;
	fi
    done

    found=0; countNZ=0;
    for NZ in $num_each_Z; do
	countNZ=$((countNZ+1));
	if [ $select_NZ -eq $countNZ ]; then

	    found=1;
	    return $NZ;
	fi
    done

    if [ $dbg -gt 0 ]; then
	echo "select_Z= $select_Z"
	echo "select_Z count= $countZ"
	echo "NZ= $NZ"
    fi
    
    if [ $found -eq 0 ]; then
	echo "Can't find Z= $selectZ in list $z_vals  !!"
    fi
}

#####################
# Script start
#####################

if [ ! -s $file ]; then
    echo "No file found. Check -f switch."; exit
fi

# check file to see if it is VASP5 version (includes species in line 6)
autodetectV5 ;
if [ $isV5 -eq 1 ]; then
    cat $file | awk '(NR!=6){print $0}' > tempfile.POSv4;
    if [ $dbg -eq 1 ]; then
	echo "autodetected POSCAR version 5, converting to V4.";
    fi
    poscar_orig_name=$file;
    file=tempfile.POSv4;
    temptrunk=tempfile.POSv4;
fi

zline=$(cat $file | awk '(NR==1){print $0}')
z_vals=$(echo $zline | awk '{for(i=2;i<NF+1;i++){if($i>0) printf("%d ",$i);}}')
n_z_vals=$(echo $z_vals | wc | awk '{print $2}')
num_each_Z=$(cat $file | awk '(NR==6){print $0}');


if [ $dbg -eq 1 ]; then
    echo "Using file "$file
    echo "zline: "$zline
    echo "z_vals: "$z_vals
    echo "n_z_vals: "$n_z_vals
    echo "num_each_Z: "$num_each_Z
fi

if [ "$range" == "" ]; then
    echo "Z1 Z2 nn_dist" | awk '{printf("#%5s%5s%10s\n",$1,$2,$3);}'
else
    rlo=$(echo $range | gawk -F':' --source '{print $1}')
    rhi=$(echo $range | gawk -F':' --source '{print $2}')
    echo "Z1 Z2 distance" | gawk --source \
       '{printf("#%5s%5s%10s %0.1f - %0.1f\n",$1,$2,$3,rlo,rhi);}' -v rlo=$rlo -v rhi=$rhi
fi

if [ "$setZ" != "-1" ]; then
    z_vals1=$(echo $setZ | gawk -F: '{print $1}');
    z_vals2=$(echo $setZ | gawk -F: '{print $2}');
else
    z_vals1=$z_vals;
    z_vals2=$z_vals;
fi

if [ $dbg -gt 0 ]; then
    echo "z_vals1= "$z_vals1;
    echo "z_vals2= "$z_vals2;
fi

make_script_awk;

# Double loop over the Z values
for zv1 in $z_vals1; do
    for zv2 in $z_vals2; do

	if [ $dbg -gt 0 ]; then
	    echo "============= Main loop: zv1= $zv1  zv2= $zv2"
	fi
	# get element names
	elm1=`echo $zv1 | gawk -f ./get_elm_tmp.awk`
	elm2=`echo $zv2 | gawk -f ./get_elm_tmp.awk`
	
	if [ "$zv2" -gt "$zv1" ] && [ "$setZ" == "-1" ]; then
	    continue
	fi
	if [ "$range" == "" ]; then

	    nn_out=$(contcar_pdf -f $file -z $zv1 -Z $zv2 -H 10 $OPTS | \
			 awk '($1!~/#/){print $0}' | head -1 | gawk '{print $1}');
	    
	    if [ $element_names -eq 1 ]; then
		if [ $pegsout -eq 1 ]; then
		    echo $elm1" "$elm2" "$nn_out | awk '{printf("%s%6s%5s%10.4f\n","def_rer = ",$1,$2,$3);}'
		else
		    echo $elm1" "$elm2" "$nn_out | awk '{printf("%6s%5s%10.4f\n",$1,$2,$3);}'
		fi
		
	    else
		if [ $pegsout -eq 1 ]; then
		    echo $zv1" "$zv2" "$nn_out | awk '{printf("%s%6d%5d%10.4f\n","def_rer = ",$1,$2,$3);}'
		else
		    echo $zv1" "$zv2" "$nn_out | awk '{printf("%6d%5d%10.4f\n",$1,$2,$3);}'
		fi
		
	    fi
	    
	else
	    echo "#----------------------------------"
	    echo $elm1" "$elm2" "$nn_out | awk '{printf("* %2s-%2s%10s%15s\n",$1,$2,"dist","pairs");}'
	    contcar_pdf -f $file -z $zv1 -Z $zv2 -L $rlo -H $rhi $OPTS | \
		awk '(NF>0 && $1!~/#/){printf("  %15.4f%15d\n",$1,$3);}' | tee tmp.junk.tmp;
	    npairs=$(cat tmp.junk.tmp | gawk 'BEGIN{n=0;}(NF==2){n=n+$2}END{print n}')
	    echo $npairs | awk '{printf("* total_pairs %18d\n",$1);}'
	    if [ "$setZ" != "-1" ]; then
		if [ $dbg -gt 0 ]; then
		    echo "calculating coordination number for Z= $z_vals1"
		fi
		get_num_for_Z $z_vals1
		echo $z_vals1 $npairs $NZ | awk '{printf("* coord of (NZ=%d) Z= %d        %.0f\n",$3,$1,$2/$3);}'
	    fi
	    rm -rf tmp.junk.tmp;
	fi
    done
done

if [ $dbg -eq 0 ]; then
    rm -f get_elm_tmp.awk $temptrunk 
fi

exit
