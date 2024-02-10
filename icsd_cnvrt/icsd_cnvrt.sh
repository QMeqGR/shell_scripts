#!/bin/bash

script_version=1.4.22
script_date="25 May 2018"
#script_date="26 Jan 2014"
#script_date="09 Dec 2013"
#script_date="05 Nov 2010"

# version 1.4.22
# 25 May 2018
# - igawk was removed from gawk package. change igawk to gawk.
#
# version 1.4.20
# Thu Aug 17 12:44:35 CDT 2017
# -add switch to input different Xray sources
#  for xray diffraction output.
# -fix: reading of cif files improvements.
# -add switch to output the icsd file (from cif convert).
#  This is mostly for debugging purposes.
#
# version 1.4.19
# Mon Jan 27 12:28:55 CST 2014
# -fix: updated the sort of the input icsd file. It failed
#       on some sorts before, now it uses tr -s " " and -k 2.1,2.1
#       so it should sort on the first character of the element
# -fix: removing carriage returns should have\r$ in the sed line.
#       it failed previously with \r only.
# -add: warning for fractional occupancies on POSCAR output
#
# version 1.4.18
# Mon Dec  9 09:33:23 CST 2013
# -fix: make all AWK calls GAWK
#
# version 1.4.17
# Mon Jan 28 12:07:31 CST 2013
# -make switch S over-ride the space group in .icsd file
# -fix bug that produce incorrect cif files
#
# version 1.4.16
# Fri Nov  5 14:15:23 CDT 2010
# -add icsd to cif converter.
#
# version 1.4.15
# Wed Jul  7 13:41:16 CDT 2010
# -fixed file trunk naming issues for cif files.
#
# version 1.4.14
# Tue Feb 23 13:33:12 CST 2010
# -run through sed to remove carraige returns in case
#  the cif file was a dos file
#
# version 1.4.13
# Fri Aug 28 12:05:28 CDT 2009
# -ICSD eliminated their file format and only
#  distribute structures in CIF format.
#  Added cif2icsd converter awkfile and
#  auto-detect when converting CIF files.
#
# version 1.4.12
# Mon Oct 27 09:10:49 CDT 2008
# -fixed again the ICSD 0.3333 0.6667 cases.
#  modified icsd_lib.awk find_fraction
#
# version 1.4.11
# Wed Jul  9 16:00:21 CDT 2008
# -updated findsym2icsd.awk and trim_uniq.awk
#  to correct for low prec output of findsym
# 
# version 1.4.10
# Thu Mar  6 23:06:41 CST 2008
# -update to use icsd_lib.awk
# -new function to produce primitive cell
#
# version 1.4.9
# Thu Jan 10 17:42:36 CST 2008
# -fix simple file name error
#
# version 1.4.8
# Mon Dec 17 13:26:42 CST 2007
# -add generation of total pair dist file.
#
# version 1.4.7
# Wed Jul 11 16:11:10 PDT 2007
# -change one line in icsd2poscar.awk (see that file for changes)
# -sort the input file to order the elements... see new fcn below.
#
# version 1.4.6
# Wed Jun  6 09:36:20 PDT 2007
# -add option to get cell volume
#
# version 1.4.5
# Tue May  8 16:33:40 PDT 2007
# -make code corrections to poscar2vis.awk
#
# version 1.4.4
# Sat May  5 13:48:58 PDT 2007
# -make xbs output print the cell frame
#
# version 1.4.3
# Thu Apr 26 13:35:37 PDT 2007
# -add option to output powder diffraction .tth.dat
#
# version 1.4.2
# Thu Apr 12 17:37:06 PDT 2007
# -added option to output poscar in direct or cart
#
# version 1.4.1
# Mon Nov 20 15:47:30 PST 2006
# -updated poscar2vis with more options, updated this file
#
# version 1.4
# Tue Apr  4 09:45:18 PDT 2006
# -add debug switch
#
# 16 jan 2005
# version 1.3, make easier to distribute the code
#
# 28 oct 2005
# version 1.2 added support for xbsa and drawxtl output
#
# 14 oct 2005
# version 1.1 added support for xmakemol output

#################################################
# Editable things
#################################################
# 
export CVT_TOP=/home/ehm/src/icsd_cnvrt
export AWKPATH=$CVT_TOP:/home/ehm/awkfiles

#############################################
# defaults
cif_input=-1;
cifout=0;
file=input.in
get_vol=-1
help=0
icsd_out=0;
lambda=1.5405;
original_file_name="not_set_yet"
poscar=-1
poscar_cart=-1
powder=-1
powderdiff=-1
primcell=0
SG=""
SETSTR=""
sgoverride=0
source="Cu";
rdf=-1
xmkmol=-1
xbs=-1
xbs_frame=-1
dxl=-1
dbg=-1

declare SWITCH
while getopts "bBcCdDf:hIl:LpPRS:VxX" SWITCH; do
    case $SWITCH in
    b) xbs=1 ;;
    B) xbs_frame=1 ;;
    c) cifout=1 ;;
    C) poscar_cart=1 ;;
    d) dbg=1 ;;
    D) powder=1 ;;
    f) file=$OPTARG; original_file_name=$OPTARG ;;
    h) help=1 ;;
    I) icsd_out=1 ;;
    l) source=$OPTARG;;
    L) dxl=1 ;;
    p) primcell=1 ;;
    P) poscar=1 ;;
    R) rdf=1 ;;
    S) SETSTR=$OPTARG; sgoverride=1 ;;
    V) get_vol=1 ;;
    x) powderdiff=1 ;;	
    X) xmkmol=1 ;;
    esac
done


#################################################
# No need to edit below this line
#################################################



if [ $help -eq 1 ] || [ $# -eq 0 ]; then
    echo
    echo "#######################"
    echo "#    icsd_cnvrt.sh    #"
    echo "#######################"
    echo
    echo "version: "$script_version
    echo "last update: "$script_date
    echo
    echo "use: icsd_cnvrt.sh -f infile  [-bBcCdDhLpPRSVxX]"
    echo 
    echo
    echo "    -h --- show this help"
    echo "    -d --- debug"
    echo
    echo "       === Input Options === "
    echo
    echo "    -f --- file with icsd stucture format"
    echo "    -S --- manually set the Hermann-Mauguin string: 'R-3m:H',etc."
    echo "           this over-rides the setting in the .icsd file!"
    echo
    echo "       === CIF and ICSD OUTPUT ==="
    echo
    echo "    -c --- produce cif file"
    echo "    -I --- produce icsd file (needs cif input)"
    echo
    echo "       === POSCAR and XYZ OUTPUT ==="
    echo
    echo "    -p --- produce POSCAR (primcell) 'direct' file"
    echo "    -P --- produce POSCAR file in 'direct' format"
    echo "    -C --- produce POSCAR file in 'cartesian' format"
    echo "    -X --- produce xmakemol.xyz output file"
    echo
    echo "       === XRD and INFO OUTPUT ==="
    echo
    echo "    -V --- print cell volume and exit"
    echo "    -R --- produce out.rdf total pair file"
    echo "    -D --- produce powder.in input file"
    echo "    -x --- produce powder diffraction .tth.dat file"
    echo "    -l -*- X-ray source for XRD pattern output (default Cu)"
    echo "            Options: Cr Fe Co Cu Mo Ag"
    echo
    echo "       === VISUALIZATION ==="
    echo
    echo "    -b --- produce xbs (8 cells) file in.bs"
    echo "    -B --- produce xbs conventional cell with cell frame"
    echo "    -L --- produce drawxtl.str output file"
    echo
    echo
    echo Eric Majzoub
    echo Sandia National Laboratories
    echo original script date: 15 sept 2005
    echo
    echo
    exit
fi

###########################################
# find the executables and set their paths
if [ ! -e /usr/bin/which ]; then
    echo "No file /usr/bin/which found."
    exit 1
fi
AWK=$(which awk 2> /dev/null)
if [ -z "$AWK" ]; then
    echo "WARNING: Executable 'awk' not found."
    AWK=/usr/local/bin/awk
    echo "using "$AWK
fi
GAWK=$(which gawk 2> /dev/null)
if [ -z "$GAWK" ]; then
    echo "WARNING: Executable 'gawk' not found."
    AWK=/usr/local/bin/gawk
    echo "using "$GAWK
fi
CAT=$(which cat 2> /dev/null)
if [ -z "$CAT" ]; then
    echo "WARNING: Executable 'cat' not found."
    CAT=/usr/local/bin/cat
    echo "using "$CAT
fi
SORT=$(which sort 2> /dev/null)
if [ -z "$SORT" ]; then
    echo "WARNING: Executable 'sort' not found."
    CAT=/usr/local/bin/sort
    echo "using "$SORT
fi
SGINFO=$(which sginfo 2> /dev/null)
if [ -z "$SGINFO" ]; then
    echo "WARNING: Executable 'sginfo' not found."
    SGINFO=/usr/local/bin/sginfo
    echo "using "$SGINFO
fi
SPACEGROUP=$(which spacegroup 2> /dev/null)
if [ -z "$SPACEGROUP" ]; then
    echo "WARNING: Executable 'spacegroup' not found."
    SPACEGROUP=/home/packages/source/exciting/src/spacegroup/spacegroup
    echo "will try using "$SPACEGROUP
fi
POWDER=$(which powder 2> /dev/null)
if [ -z "$POWDER" ]; then
    echo "WARNING: Executable 'powder' not found."
    POWDER=$HOME/bin/powder
    echo "will try using "$POWDER
fi
CONTCAR_PDF=$(which contcar_pdf 2> /dev/null)
if [ -z "$CONTCAR_PDF" ]; then
    echo "WARNING: Executable 'contcar_pdf' not found."
    CONTCAR_PDF=$HOME/bin/contcar_pdf
    echo "will try using "$CONTCAR_PDF
fi
D2U=$(which dos2unix 2> /dev/null)
if [ -z "$D2U" ]; then
    D2U="";
    echo "WARNING: Executable 'dos2unix' not found."
    echo "       : File conversion may fail if there are carriage returns."
fi

CIF2ICSD=$CVT_TOP/cif2icsd.awk
ICSD2POSCAR=$CVT_TOP/icsd2poscar.awk
ICSD2EXCITING=$CVT_TOP/icsd2exciting.awk
ICSD_GET_SG=$CVT_TOP/icsd_get_sg.awk
POSCAR2POWD=$CVT_TOP/poscar2powder.awk
POSCAR2VIS=$CVT_TOP/poscar2vis.awk
POSCAR_CART=$CVT_TOP/poscar_direc2cart.awk
POSCAR_VOL=$CVT_TOP/poscar_volume.awk
XSF2POSCAR=$CVT_TOP/xsf2poscar.awk

################################
#  Functions
################################

function get_equiv {
   $SGINFO "$spgp" -allxyz | $AWK -v X=$x -v Y=$y -v Z=$z -v debug=$dbg -f $CVT_TOP/wyckoff.awk ;
    $CAT tmpout | $AWK -f $CVT_TOP/three2one.awk -v debug=$dbg | $SORT -n |  $UNIQ;
    $RM -f tmpout
}


# this function is necessary if the order
# of the elements in the icsd file is not
# sequential.  i.e. it needs to be Na1 Al1 Al2 H1 H2 H3
# and not                          Al1 Na1 Al2 H1 H2 H3
function sort_input_icsd {

    $CAT $file | gawk --source '($1~"N"){ print $0; }' > temp_icsd_cnvrt_sort_fcn_N_line;
    $CAT $file | gawk --source '($1~"C"){ print $0; }' > temp_icsd_cnvrt_sort_fcn_C_line;
    $CAT $file | gawk --source '($1~"A"){ print $0; }' > temp_icsd_cnvrt_sort_fcn_A_line_unsrt;
    $CAT temp_icsd_cnvrt_sort_fcn_A_line_unsrt | tr -s " " | $SORT -k 2.1,2.1 > temp_icsd_cnvrt_sort_fcn_A_line;
    
    $CAT temp_icsd_cnvrt_sort_fcn_N_line >> temp_icsd_cnvrt_sort_fcn_new_icsd_file;
    $CAT temp_icsd_cnvrt_sort_fcn_C_line >> temp_icsd_cnvrt_sort_fcn_new_icsd_file;
    $CAT temp_icsd_cnvrt_sort_fcn_A_line >> temp_icsd_cnvrt_sort_fcn_new_icsd_file;

    cat temp_icsd_cnvrt_sort_fcn_new_icsd_file | column -t > tmp.junk;
    mv tmp.junk temp_icsd_cnvrt_sort_fcn_new_icsd_file;
    
    file=temp_icsd_cnvrt_sort_fcn_new_icsd_file;

}

function clean_up_temp_files {

    rm -f temp_icsd_cnvrt_sort_fcn_N_line;
    rm -f temp_icsd_cnvrt_sort_fcn_C_line;
    rm -f temp_icsd_cnvrt_sort_fcn_A_line_unsrt;
    rm -f temp_icsd_cnvrt_sort_fcn_A_line;
    rm -f temp_icsd_cnvrt_sort_fcn_new_icsd_file;
    rm -f temp_icsd_cif2icsd_file;

}

function set_xrd_lambda {

    echo "Using $source as XRD source."
    
    if [ "$source" == "Cr" ] || [ "$source" == "cr" ] || [ "source" == "24" ]; then
	lambda="2.29351";
    fi
    if [ "$source" == "Fe" ] || [ "$source" == "fe" ] || [ "source" == "26" ]; then
	lambda="1.93991";
    fi
    if [ "$source" == "Co" ] || [ "$source" == "co" ] || [ "source" == "27" ]; then
	lambda="1.79278";
    fi
    if [ "$source" == "Cu" ] || [ "$source" == "cu" ] || [ "source" == "29" ]; then
	lambda="1.5405";
    fi
    if [ "$source" == "Mo" ] || [ "$source" == "mo" ] || [ "source" == "42" ]; then
	lambda="0.713543";
    fi
    if [ "$source" == "Ag" ] || [ "$source" == "ag" ] || [ "source" == "47" ]; then
	lambda="0.563775";
    fi

}

function check_for_frac_occup {
    ## Note: ICSD format is (I think as of 18 Aug 2017)
    ## 7 column example
    ## A Fe1 x y z Usio occup
    isfrac=0;
    isfrac=$(cat $file | gawk 'BEGIN{flag=0}($1=="A" && NF>6){if(($7>1.001||$7<0.999)&&$7!=0){flag=1}}END{print flag}');
    if [ $isfrac -eq 1 ]; then
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "!!!  WARN: Fractional occupancies found in ICSD file   !!!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    fi
}

################################
# script begins here
################################

# Check to see if the input file is CIF format, and convert
# to the ICSD (no longer distributed by ICSD) format that
# all my scripts were written to work with.
file_tail="${file##*.}";
cif_indicator=`cat $file | grep "_atom_site_label"`;
if [ ! -z "$cif_indicator" ]; then
    cif_input=1;
fi
if [ "$file_tail" == "cif" ] || [ $cif_input -eq 1 ]; then

    echo "################"
    echo "Detected CIF file! Converting to ICSD format.";
    echo "################"

    if [ "$D2U" != "" ]; then
	$CAT $file | $D2U | sed 's/\r$//g' | $GAWK -f $CIF2ICSD > temp_icsd_cif2icsd_file;	
    else
	# remove carriage returns from DOS files
	$CAT $file | sed 's/\r$//g' | $GAWK -f $CIF2ICSD > temp_icsd_cif2icsd_file;
    fi
    file="temp_icsd_cif2icsd_file";

    original_file_trunk=${original_file_name%%.cif};
else
    original_file_trunk=${original_file_name%%.icsd};    
fi

# sort the input file so the elements are in blocks:
sort_input_icsd;
check_for_frac_occup;

# -I switch (icsd output)
if [ $cif_input -eq 1 ] && [ $icsd_out -eq 1 ]; then
    mv $file $original_file_trunk.icsd;
    clean_up_temp_files;
    exit
fi


# set the xrd wavelength to choose
if [ "$source" != "Cu" ]; then
    set_xrd_lambda;
fi

if [ $sgoverride -eq 1 ]; then
    #SG=`$CAT $file | $AWK -f $ICSD_GET_SG`;
    #SETSTR=`$SGINFO $SG | awk '($1~/Space/){printf("%s",\$5);}'`
    if [ $dbg -eq 1 ]; then
	echo "over-riding the spg setting with "$SETSTR;
    fi
fi

if [ $cifout -eq 1 ]; then
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v CIFOUT=1  -v debug=$dbg > temp_tmp;
    cat temp_tmp | sed '/^$/d' > ${original_file_name%%.icsd}.cif;
    rm -f temp_tmp;
fi

if [ $poscar -eq 1 ]; then
    if [ $sgoverride -eq 1 ]; then
	echo "Overriding space group with "$SETSTR
    fi
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v SGOVERRIDE=$sgoverride -v NEWSG=$SETSTR -v debug=$dbg > POSCAR
fi

if [ $primcell -eq 1 ]; then
    if [ -z $SETSTR ]; then
	SG=`$CAT $file | $AWK -f $ICSD_GET_SG`;
	SETSTR=`$SGINFO $SG | awk '($1~/Space/){printf("%s",\$5);}'`
    fi
    $CAT $file | $GAWK -f $ICSD2EXCITING -v ORDER=1 -v spg="$SETSTR" > spacegroup.in;
    $SPACEGROUP >& spacegroup.log &&
    $CAT crystal.xsf | $GAWK -f $XSF2POSCAR | $GAWK -f $POSCAR_CART > POSCAR_primcell;
    if [ $dbg -eq -1 ]; then
	rm -f crystal.xsf crystal.ascii GEOMETRY.OUT spacegroup.in spacegroup.log
    fi
fi

if [ $poscar_cart -eq 1 ]; then
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v debug=$dbg | $GAWK -f $POSCAR_CART > POSCAR
fi

if [ $get_vol -eq 1 ]; then
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v debug=$dbg | $GAWK \
	-f $POSCAR_VOL;
fi

if [ $powder -eq 1 ]; then
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v debug=$dbg | $GAWK -f $POSCAR2POWD -v debug=$dbg  > powder.in
fi

if [ $powderdiff -eq 1 ]; then
    POWDER_OPTS="-X -t $lambda -P -C"
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v debug=$dbg | $GAWK -f $POSCAR2POWD -v debug=$dbg  > powder.in;
    $POWDER -f powder.in $POWDER_OPTS > $original_file_trunk.tth.dat;
    rm -f powder.in;
fi

if [ $rdf -eq 1 ]; then
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v debug=$dbg > POSCAR_TEMPFILE;
    $CONTCAR_PDF -f POSCAR_TEMPFILE > out.rdf
    rm POSCAR_TEMPFILE;
fi

if [ $xmkmol -eq 1 ]; then
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v debug=$dbg | $GAWK -f $POSCAR2VIS -v XMK=1 -v debug=$dbg  > xmakemol.xyz
fi

if [ $xbs -eq 1 ]; then
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v debug=$dbg | $GAWK -f $POSCAR2VIS -v XBS=1 -v BONDS=1 -v BP=0.1 -v DUP=1 -v debug=$dbg > in.bs
fi

if [ $xbs_frame -eq 1 ]; then
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v debug=$dbg | $GAWK -f $POSCAR2VIS -v XBS=1 -v BONDS=1 -v BP=0.1 -v CONV=1 -v DUP=1 -v debug=$dbg > in.bs
fi

if [ $dxl -eq 1 ]; then
    $CAT $file | $GAWK -f $ICSD2POSCAR -v ORDER=1 -v debug=$dbg | $GAWK -f $POSCAR2VIS -v DXL=1 -v debug=$dbg  > drawxtl.str
fi

clean_up_temp_files;

exit
