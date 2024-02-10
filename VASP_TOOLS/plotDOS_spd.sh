#!/bin/bash

script_name="plotDOS"
script_version=1.6
script_date="27 June 2018"

BASE=/home/ehm

# v 1.6 - change the -n option to give a list
# v 1.5 - add code to run the DOSCAR through doscar_split.awk
#         with all the options necessary there.
#       - update switch details to be more clear
# v 1.4 - merge with plotDOS_spd_updown.sh so there is no
#         duplication of code functions. (added spinpol tag)
# v 1.3 - get element name from CONTCAR chemistry.txt file
# v 1.2 - add option for ticks

#############################################
# awkfiles
VT_TOP=$BASE/src/VASP_TOOLS
DOSCAR_SPLIT=$VT_TOP/awkfiles/doscar_split.awk
Z_TO_ELM=$VT_TOP/awkfiles/z_to_elm.awk

# defaults
dbg=0;
doscar=DOSCAR;
dos_file="";
dos_dir="atom_dos_npol"; # will be changed if spinpol=1
file_list="";
help=0;
jpegout=0;
lmdecomp=0;
startgv=1;
tick=10:2
title="";
pdfout=0;
print_total_dos=1;
range="AUTO";
spinpol=0;
title_manual=0;

# plot defaults
atom_label_size=1.2;
axisfont_size=1.5;
xticklabel_size=1.25;
yticklabel_size=1;


declare SWITCH
while getopts "dhLjn:pR:sT:x:" SWITCH; do
    case $SWITCH in
    d) dbg=1 ;;
    h) help=1 ;;
    j) jpegout=1; startgv=0 ;;
    L) lmdecomp=0 ;;
    n) file_list=$OPTARG ;;
    p) pdfout=1;  startgv=0 ;;
    R) range=$OPTARG ;;
    s) spinpol=1; range="-9:3"; dos_dir="atom_dos_pol" ;;
    T) title=$OPTARG ; title_manual=1 ;;
    x) tick=$OPTARG ;;
    esac
done

if [ $help -eq 1 ] || [ $# -eq 0 ]; then
    echo
    echo "#######################"
    echo "#    "$script_name
    echo "#######################"
    echo
    echo "version: "$script_version
    echo "last update: "$script_date
    echo
    echo "use: plotDOS.sh -n atom_number [opts]"
    echo
    echo "     Run this script in the vasp directory where"
    echo "     the DOSCAR is located."
    echo 
    echo
    echo "    -h --- show this help"
    echo "    -d --- debug"
    echo
    echo "    -n -*- integer of atom number for DOS plot output, e.g. -n 21"
    echo "           (goes with the atom number in the POSCAR file)."
    echo "           For multiple files use quotes \"21 23\", etc."
    echo "           Using -n ALL will make plots for all atoms. It helps"
    echo "           to use -j or -p here, otherwise gv will start."
    echo
    echo "    -L --- do NOT print lm decomp (default is to decompose)"
    echo "    -s --- spin polarized calculation (old plotDOS_spd_updown.sh script)"
    echo "        spin pol calc works with 13 column file:"
    echo "        1  2   3         4   5         6   7            13"
    echo "        en sup sup-integ sdn sdn-integ pup pup-integ... ddn-integ"
    echo
    echo "    -j --- jpeg output (default is viewing in gv)"
    echo "    -p --- pdf output  (default is viewing in gv)"
    echo
    echo "    -R -*- x-range (use colon and quotes) e.g. -R \"-20:50\""
    echo "    -x -*- x-ticks major:minor (use colon and quotes) e.g. -t \"10:2\" (default)"
    echo "    -T -*- title (use quotes if there are spaces)"
    echo
    echo
    echo Eric Majzoub
    echo University of Missouri - St. Louis
    echo original script date: 6 June 2013
    echo
    echo
    exit
fi

if [ "$file_list" == "" ]; then
    echo "Try -h for help."; exit;
fi
if [ $dbg -eq 1 ]; then
    echo "plotting "$dos_file
    echo "DOSCAR_SPLIT= "$DOSCAR_SPLIT
fi
##################################################
##################################################
# Run the file through doscar_split.awk

cat DOSCAR | gawk -f $DOSCAR_SPLIT -v prt_tot=$print_total_dos \
		   -v ispin=$spinpol -v lm_decomp=$lmdecomp

if [ -d atom_dos_npol ] || [ -d atom_pos_pol ]; then
    if [ -s atom_dos*/DOS_1 ]; then
	echo "Extracted data succesfully."
    else
	echo "Error extracting data."; exit;
    fi
else
    echo "Error extracting data."; exit;
fi

##################################################
##################################################
# Range parms
xlo=$(echo $range | gawk -F ":" --source '{print $1}')
xhi=$(echo $range | gawk -F ":" --source '{print $2}')
if [ $dbg -eq 1 ]; then
    echo "xlo= "$xlo
    echo "xhi= "$xhi
fi

if [ "$range" == "AUTO" ]; then
    RANGE=AUTOSCALE;
else
    RANGE="WORLD XMIN $xlo; WORLD XMAX $xhi;"
fi

# tick parms
tickmajor=$(echo $tick | gawk -F ":" --source '{print $1}')
tickminor=$(echo $tick | gawk -F ":" --source '{print $2}')
TICKMAJOR="xaxis tick major $tickmajor"
TICKMINOR="xaxis tick minor $tickminor"
if [ $dbg -eq 1 ]; then
    echo "tickmajor= "$tickmajor
    echo "tickminor= "$tickminor
    echo "TICKMAJOR= "$TICKMAJOR
    echo "TICKMINOR= "$TICKMINOR
fi

function get_elm_from_chem_file () {
    # get the element name if the chemistry.txt file exists
    # (this only works if the plotBANDS command was used, and "poscar_cnvrt -f CONTCAR -l" was issued)
    if [ -e chemistry.txt ]; then
	echo "Found chemistry.txt file. Will try to get element name."
	echo $dos_file;
	atom_number=$(echo $dos_dir/$dos_file | gawk -F "_" '{print $NF}');
	echo "atom_number= "$atom_number
	zatom=$(cat chemistry.txt | gawk --source '($1 !~ "#" && AN >= $3 && AN <= $NF){print $1}' -v AN=$atom_number)
	echo "found zatom= "$zatom
	element=$( gawk -f $Z_TO_ELM -v ZZ=$zatom )
	echo "found element= "$element
	if [ "$title" == "" ] || [ $title_manual -eq 0 ]; then
	    echo "setting title... "
	    title="$element \#$atom_number"
	fi
    fi
}


function make_grace_batch (){

##################################################
#   non spin polarized
##################################################
cat > batch.agr<<EOF

READ BLOCK "$dos_dir/$dos_file"

arrange (6,1,0.1,.1,.0)

######################## S-DOS
focus g0
view 0.15, 0.1, 1.15, 0.36
BLOCK xy "1:2"
s0 line color 1
$RANGE
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
yaxis label "s-DOS"
yaxis tick place normal
xaxis label "Energy [eV]"
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size

focus g1
view 0.15, 0.1, 1.15, 0.36
BLOCK xy "1:3"
$RANGE
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
yaxis label place opposite
yaxis label place spec
yaxis label place 0.0, 0.08
yaxis tick place opposite
yaxis ticklabel place opposite
s0 line color 2
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size

######################## P-DOS
focus g2
view 0.15, 0.40, 1.15, 0.66
BLOCK xy "1:4"
$RANGE
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
s0 line color 1
xaxis ticklabel off
yaxis tick place normal
yaxis label "p-DOS"
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size


focus g3
view 0.15, 0.40, 1.15, 0.66
s0 line color 2
BLOCK xy "1:5"
$RANGE
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
yaxis label place opposite
yaxis label place spec
yaxis label place 0.0, 0.08
yaxis label "Integrated DOS"
yaxis tick place opposite
yaxis ticklabel place opposite
xaxis ticklabel off
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size



######################## D-DOS
focus g4
view 0.15, 0.70, 1.15, 0.96
with string
    string on
    string loctype view
    string 0.18, 0.9
    string color 1
    string rot 0
    string font 0
    string just 0
    string char size 1.75
    string def "$title"
BLOCK xy "1:6"
s0 line color 1
$RANGE
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
yaxis tick place normal
xaxis ticklabel off
yaxis label "d-DOS"
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size

focus g5
view 0.15, 0.70, 1.15, 0.96
BLOCK xy "1:7"
s0 line color 2
$RANGE
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
xaxis ticklabel off
yaxis label place opposite
yaxis label place spec
yaxis label place 0.0, 0.08
yaxis tick place opposite
yaxis ticklabel place opposite
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size

###################################
PRINT TO "$dos_dir/$dos_file.plot.eps"
DEVICE "EPS" OP "level2"
PRINT

EOF

##################################################
#   spin polarized
##################################################
cat > batch.spinpol.agr<<EOF

READ BLOCK "$dos_dir/$dos_file"

arrange (6,1,0.1,.1,.0)

######################## S-DOS
focus g0
view 0.15, 0.1, 1.15, 0.38
BLOCK xy "1:2"
s0 line color 4
BLOCK xy "1:4"
s1 line color 2
WORLD XMIN $xmin
WORLD XMAX $xmax
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
yaxis label "s-DOS"
yaxis tick place normal
xaxis label "Energy [eV]"
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size


focus g1
view 0.15, 0.1, 1.15, 0.38
BLOCK xy "1:3"
s0 line color 4
s0 linestyle 2
BLOCK xy "1:5"
s1 line color 2
s1 linestyle 2
WORLD XMIN $xmin
WORLD XMAX $xmax
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
yaxis label place opposite
yaxis tick place opposite
yaxis ticklabel place opposite
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size



######################## P-DOS
focus g2
view 0.15, 0.38, 1.15, 0.66
BLOCK xy "1:6"
s0 line color 4
BLOCK xy "1:8"
s1 line color 2
WORLD XMIN $xmin
WORLD XMAX $xmax
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
xaxis ticklabel off
yaxis tick place normal
yaxis label "p-DOS"
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size


focus g3
view 0.15, 0.38, 1.15, 0.66
BLOCK xy "1:7"
s0 line color 4
s0 linestyle 2
BLOCK xy "1:9"
s1 line color 2
s1 linestyle 2
WORLD XMIN $xmin
WORLD XMAX $xmax
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
yaxis label place opposite
yaxis label "i-dos"
yaxis tick place opposite
yaxis ticklabel place opposite
xaxis ticklabel off
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size



######################## D-DOS
focus g4
view 0.15, 0.66, 1.15, 0.94
with string
    string on
    string loctype view
    string 0.18, 0.9
    string color 1
    string rot 0
    string font 0
    string just 0
    string char size 1.75
    string def "$title"
BLOCK xy "1:10"
s0 line color 4
BLOCK xy "1:12"
s1 line color 2
WORLD XMIN $xmin
WORLD XMAX $xmax
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
yaxis tick place normal
xaxis ticklabel off
yaxis label "d-DOS"
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size


focus g5
view 0.15, 0.66, 1.15, 0.94
BLOCK xy "1:11"
s0 line color 4
s0 linestyle 2
BLOCK xy "1:13"
s1 line color 2
s1 linestyle 2
WORLD XMIN $xmin
WORLD XMAX $xmax
AUTOSCALE YAXES
$TICKMAJOR
$TICKMINOR
xaxis ticklabel off
yaxis label place opposite
yaxis tick place opposite
yaxis ticklabel place opposite
xaxis label char size $axisfont_size
yaxis label char size $axisfont_size
xaxis ticklabel char size $xticklabel_size
yaxis ticklabel char size $yticklabel_size



###################################
PRINT TO "$dos_dir/$dos_file.plot.eps"
DEVICE "EPS" OP "level2"
PRINT

EOF

}


function make_plot (){

######
if [ $spinpol -eq 0 ]; then
    gracebat -batch batch.agr -nosafe -hardcopy;
fi
if [ $spinpol -eq 1 ]; then
    gracebat -batch batch.spinpol.agr -nosafe -hardcopy;
fi

######
if [ $dbg -eq 0 ]; then
    rm -f batch.agr batch.spinpol.agr;
fi

######
if [ $jpegout -eq 1 ]; then
    convert $dos_dir/$dos_file.plot.eps -rotate 90  $dos_dir/$dos_file.plot.jpg;
fi
if [ $pdfout -eq 1 ]; then
    convert $dos_dir/$dos_file.plot.eps -rotate 90  $dos_dir/$dos_file.plot.pdf;
fi

######
if [ $startgv -eq 1 ]; then
    gv $dos_dir/$dos_file.plot.eps;
fi

rm -f $dos_dir/*.plot.eps;
    
}

############################################################
#  Script starts here
############################################################
if   [ "$file_list" == "ALL" ]; then
    dos_file_list=$(ls $dos_dir/* | grep DOS_ --exclude "*.*")
elif [ "$file_list" != "ALL" ]; then
    for ff in $file_list; do
	dos_file_list="$dos_file_list $dos_dir/DOS_$ff";
    done
else
    echo "error setting -n option. exiting." exit;
fi

if [ $dbg -eq 1 ]; then
    echo "dos_file_list= "$dos_file_list;
fi

for dos_file_pre1 in $dos_file_list; do
    dos_file=${dos_file_pre1##*/};
    echo "Plotting dos_file= " $dos_file
    get_elm_from_chem_file ;
    make_grace_batch ;
    make_plot ;
done

echo "Done."

exit
