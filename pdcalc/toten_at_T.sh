#!/bin/sh

script_name="toten_at_T.sh"
script_date="17 Oct 2015"
script_vers="2.0"

# version 2.0
# -- added reference energy for making tables of structures with rel energy

PDTOP=$HOME/src/pdcalc
export AWKPATH=$AWKPATH:$HOME/src/pdcalc

#defaults
dbg=0;
help=0;
infile="data.in"
T=10;
en_ref="";
kjout=0;
eV_to_kJperMol=96.48306883;

declare SWITCH
while getopts "dhE:kT:" SWITCH; do
    case $SWITCH in
    h) help=1;;
    d) dbg=1;;
    E) en_ref=$OPTARG ;;
    k) kjout=1 ;;
    T) T=$OPTARG ;;
    esac
done
if [ $help -eq 1 ]; then
    echo
    echo "Command line options:"
    echo
    echo "-d --- debug output"
    echo "-h --- show help"
    echo
    echo "-T -*- calculate at temp T (default $T)"
    echo "-E -*- use structure X as energy reference"
    echo "       (name in the left hand column)"
    echo "       This will ref both static and Tref energies."
    echo "     -k -- (suboption for -E) show output in kJ/mol"
    echo
    echo
    echo "Eric Majzoub"
    echo "University of Missouri - St. Louis"
    echo
    exit
fi

#################################################
#################################################

function get_energy () {
    static=`cat $infile | gawk --source '($1==PHS){print $5}' -v PHS="$phase"`;
    dynamic=`cat $phase.dat | gawk --source '($1==TEMP){print $2}' -v TEMP=$T`;
    toten=`echo $static $dynamic | gawk '{print $1+$2}'`;
}

#################################################

phaselist=`cat $infile | gawk --source '($1~"phase"){read=1;}(read==1 && $1!~"end" && $1!~"phase"){print $1}($1~"end"){read=0;}'`
if [ $dbg -eq 1 ]; then
    echo $phaselist;
fi

if [ "$en_ref" != "" ]; then
    found=0;
    for phase in $phaselist; do
	if [ "$phase" == "$en_ref" ]; then
	    echo "Will use "$en_ref " as energy reference."
	    get_energy;
	    ref_stat=$static;
	    ref_totl=$toten;
	    found=1;
	fi
    done
    if [ $found -eq 0 ]; then
	echo "Can't find structure "$en_ref " in table of structures."
	exit
    fi
fi


echo "------------------------------------------------------------------------------------"
gawk --source 'BEGIN{printf("%-30s%15s%10s%5d%15s\n","phase","static","T=",TEMP,"diff");}' -v TEMP=$T
echo "------------------------------------------------------------------------------------"
for phase in $phaselist; do
    get_energy;
    #echo "phase= "$phase " static= "$static " dynamic= "$dynamic " toten= "$toten;
    if [ "$en_ref" == "" ]; then
	echo $phase $static $toten         | gawk '{printf("%-30s%15.5f%15.5f%15.5f\n",$1,$2,$3,$3-$2);}';
    else
	if [ $kjout -eq 1 ]; then
	    echo $phase $static $toten $ref_stat $ref_totl | gawk 'BEGIN{c=96.4831}{printf("%-30s%15.5f%15.5f%15s\n",$1,c*($2-$4),c*($3-$5),"--");}';
	else
	    echo $phase $static $toten $ref_stat $ref_totl | gawk '{printf("%-30s%15.5f%15.5f%15s\n",$1,$2-$4,$3-$5,"--");}';
	fi
    fi
done

exit


