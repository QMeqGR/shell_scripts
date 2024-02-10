#!/bin/sh

script_name="VASP_setup.sh"
script_version="2.1.5 quartz + rolla forge + desktop"
script_date="26 Jun 2018"

################################################################################

# BASE is hard coded on the cluster so that students may
# run the code without having to mirror all my scripts

#CLUSTER="forge"
#cluster_home=/home/majzoube

CLUSTER="quartz"
cluster_home=/g/g14/majzoub1


######################################################
# QUEUES FOR ACCOUNTING
QUEUE_OPTIONS="doe_umsl doe_ameslab"

# This sets LOCATION by checking for a Desktop directory.
if [ -d $cluster_home ]; then
    LOCATION="cluster";
    BASE=$cluster_home
else
    LOCATION="desktop";
    BASE=/home/ehm
fi

echo "* LOCATION= "$LOCATION

# set PATHS and some cluster specifics
if   [ $LOCATION == "cluster" ]; then

    echo "* CLUSTER= "$CLUSTER
    
    AWKFILES=$BASE/awkfiles

    # Eric runs on grethor. Students may run on free and requeue.
    IAM=$(whoami)
    if [ $IAM == "majzoube" ]; then
	run_only_on_grethor=1;
    else
	run_only_on_grethor=0;
    fi
    
    # Very cluster specific variables and issues
    if [ $CLUSTER == "forge" ]; then

	VASP_PATH=$BASE/Dvasp5.4.1p/vasp.5.4.1/bin;
	
	#  pseudopotentials
	# common directories for psps
	pawpot_GGA_dir="$BASE/Dvasp/pawpot_GGA/";
	pawpot_PBE_dir="$BASE/Dvasp5.3.2/pawpot_PBE/";
	pawpot_LDA_dir="$BASE/Dvasp/pawpot/";
	pot_LDA_dir="$BASE/Dvasp/pot/";

	NPROC_CLUSTER=8;
	HRS_CLUSTER=100;
	load_wait=400;
	load_wait_grethor=400; load_wait_free=1200; load_wait_requeue=800;
	wait_time="30m";
	if [ $run_only_on_grethor -eq 1 ]; then
	    partitions="grethor"; # list the node groups you want to run on here
	    #EXCLUSIVE="#SBATCH --exclusive";
	    NNODES="#SBATCH --nodes=1";
	else
	    partitions="free,requeue"; # list the node groups you want to run on here
	    EXCLUSIVE="";
	    #    TEMPACCT="#SBATCH --account=majzoubet";
	fi
	
	####### Load the module that should setup paths for the intel compiler used
	#  to compile this version of VASP
	module load mvapich2/intel/15/ib

    elif [ $CLUSTER == "quartz" ]; then

	SCRATCH=/p/lscratchh/majzoub1
	NFSTMP=/nfs/tmp2/majzoub1
	
	VASP_PATH=$BASE/Dvasp5.4.4_apr2017/vasp.5.4.4/bin;
		
	#  pseudopotentials
	# common directories for psps
	pawpot_GGA_dir="$BASE/Dvasp/pawpot_GGA/";
	pawpot_PBE_dir="$BASE/Dvasp5.3.2/pawpot_PBE/";
	pawpot_LDA_dir="$BASE/Dvasp/pawpot/";
	pot_LDA_dir="$BASE/Dvasp/pot/";

	NPROC_CLUSTER=2;
	HRS_CLUSTER=24;
	load_wait=400;
	load_wait_grethor=400; load_wait_free=1200; load_wait_requeue=800;
	wait_time="30m";
	if [ $run_only_on_grethor -eq 1 ]; then
	    partitions="grethor"; # list the node groups you want to run on here
	    #EXCLUSIVE="#SBATCH --exclusive";
	    NNODES="#SBATCH --nodes=1";
	else
	    partitions="free,requeue"; # list the node groups you want to run on here
	    EXCLUSIVE="";
	    #    TEMPACCT="#SBATCH --account=majzoubet";
	fi
	
	####### Load the module that should setup paths for the intel compiler used
	#  to compile this version of VASP
	module load mkl/2018.0
	
    fi

    VASP_VERSIONS="0 5 15"
    vasp_path=$VASP_PATH
    ver_list="$VASP_VERSIONS"

elif [ $LOCATION == "desktop" ]; then

    AWKFILES=$HOME/awkfiles
    VASP_PATH=/home/ehm/lab/VASP/vasp.5.4.4_Apr_2017/vasp.5.4.4/bin;
    VASP_VERSIONS="0 5 15"


    NPROC_CLUSTER=8;
    HRS_CLUSTER=100;
    run_only_on_grethor=0;

    vasp_path=$VASP_PATH
    ver_list="$VASP_VERSIONS"

    pawpot_GGA_dir="$HOME/lab/VASP/pawpot_GGA/";
    pawpot_PBE_dir="$HOME/lab/VASP/pawpot_PBE/";
    pawpot_LDA_dir="$HOME/lab/VASP/pawpot/";
    pot_LDA_dir="$HOME/lab/VASP/pot/";

else
    echo "No LOCATION found. Should be 'cluster' or 'desktop'.  Exiting."
    exit
fi



##########################################################################
#  ALL EDITABLE OPTIONS ARE ABOVE
#
#  DO NOT MODIFY BELOW THIS LINE
##########################################################################

#
#        VERSION HISTORY
#
# v 2.1.5 update proper bader analysis
# v 2.1.3 forge 14 Sept 2017
#   -- many small updates to functionality and bug fixes
# v 2.1.0 rolla 12 June 2016
#   -- Lots of small fixes and changes. Work began in 2.0.2 so most of the
#      changes are there as well.
#   -- Merging changes to desktop version.
#   -- Try to fix the "bad termination" problem on forge with better
#      load determination
#
# v 2.0.2 rolla 12 Feb 2016
#   -- add 'fast' switch for relaxations -- to use gamma on first relaxation and then k2
# v 2.0.1 rolla 01 Feb 2016
#   -- add major mode for MD run
#   -- add major mode for hybrid functional B3LYP
#
# v 2.0.0 rolla 06 Nov 2015
#   -- clean up the code
#
# v 1.9.7 rolla 16 Sept 2015
#   -- add switch for queue name.
#   -- change switch -g to NOT set NPAR
#   -- change convergence switches to use Accurare instead of High, (High will change
#      the cutoff).
#   -- add memory per cpu directive to submit script
#   -- add major mode for BAND structure calculations
#   -- add major mode for spin polarized calculations
#
# v 1.9.6 rolla 16 July 2015
#   -- added switch to calculate effective charges only with no phonons (LEPSILON)
# v 1.9.5 rolla 20 april 2015
# v 1.9.5g Modified for grethor by ehm on 19 Sept 2013, added EDIFF switch
# v 1.9.4g Modified for grethor by ehm on 08 June 2013, added metals switch
#
# Modified for primo. ehm 29 Apr 2010
# added code for mpdboot etc.

# Modified for primo. ehm 21oct09

##################################################################################
##################################################################################
# User definable settings for vasp executable locations and -V switch (vasp_version)
ver_0="standard";
USR_VASP_EXE_V_0=$vasp_path/vasp_std;

ver_5="noncolinear"
USR_VASP_EXE_V_5=$vasp_path/vasp_ncl;

ver_15="gamma only"
USR_VASP_EXE_V_15=$vasp_path/vasp_gam;
VASPgamma=$USR_VASP_EXE_V_15;

# MPD related
#NODEFILE="/home/majzoube/mpd.hosts"


###############################################################################
# Really, DO NOT MODIFY BELOW THIS LINE
###############################################################################
GAWK=`which gawk`
cline=$@; # save command line details
cdir=$(pwd)
RANDtag=$RANDOM # for unique script names
top=${cdir##*/}_$RANDtag # name for Script_top_RANDtag.sh
jobname=${cdir##$HOME/}


# default values
algo="Very_Fast";
addgrid=".FALSE.";
aexx="";
aggac="";
aggax="";
aldac="";
bader=0;
BADER_COMMAND1=""; BADER_COMMAND2=""; BADER_COMMAND3="";
BAD_TERM_COUNT=0;
BAD_TERM_MAX=10;
born=-1;
berry=-1;
dbg=0;
clean=0;
converg=0;
dont_move_outcar=0;
ediff="1E-06";
ediffg="-0.005";
element_list="";
enmax=600.00;
enaug=$enmax;
exchange_mode=0;
fast=0;
gamma_centered_kpoints=0 ;
gga="";
help=0;
hrs=$HRS_CLUSTER;
ibrion=2; # 2=CG, 0=MD
icharg="";
isif=3;
ispin="";
isym=2;
ismear="-1";
istart="";
ivdw="0";
kpts="";
kpt_min=2;
laechg=""; # LAECGH
lhfcalc="";
lchrg=".FALSE."; # LCHARG
lorbit="";
lvtot=".FALSE."
lwave=".FALSE.";
magmom="";
major_mode=0; # see options in help below
metal=0; # default is insulator or semicon
memory_per_cpu_MB=3000; # from sinfo with %m field (4000 and up crash)
nblock="";
nelmin="";
nelm="";
nfree=2;
nsw=250; # set low for phonon calcs
numproc=$NPROC_CLUSTER;
n_iter="1 2 3 4 5 6 7 8 9 10";
paw_gga=0;
pot_gga=0;
paw_pbe=0;
partitions="";
potcar_dir=$pawpot_GGA_dir;
potcar_type="pawpot_GGA";
potdir_list="";
potim=0.1; # set to 1 for phonon calc
poscar="POSCAR";
prec="Normal";
queue="";
sigma="0.05";
smass="-10"; # previously defaulted to -2
tebeg="";
teend="";
tmp_base="VASP_setup";
unset_npar=0;
vasp_version=0;
write_flags="000";
write_incar=1;

declare SWITCH
while getopts "a:B:cCdD:e:E:f:F:gG:hi:I:k:KL:Mm:nN:O:P:p:q:s:t:v:V:wW:X:" SWITCH; do
    case $SWITCH in
    a) converg=$OPTARG ;;
    B) berry=$OPTARG ;;
    c) clean=1 ;;
    C) lchrg=".TRUE." ;;
    d) dbg=1 ;;
    D) potcar_type=$OPTARG ;;
    e) element_list=$OPTARG ;;
    E) enmax=$OPTARG ;;
    f) poscar=$OPTARG ;;
    F) fast=$OPTARG ;;
    g) unset_npar=1 ;;
    G) ediffg=$OPTARG ;;
    h) help=1 ;;
    i) isif=$OPTARG ;;
    I) isym=$OPTARG ;;
    k) kpt_min=$OPTARG ;;
    K) gamma_centered_kpoints=1 ;;
    L) ediff=$OPTARG ;;
    M) metal=1 ;;
    m) major_mode=$OPTARG ;;
    n) n_iter="1" ; dont_move_outcar=1 ;;
    N) nsw=$OPTARG ;;
    O) magmom=$OPTARG ;;
    p) numproc=$OPTARG ;;
    P) partitions=$OPTARG ;;
    q) queue=$OPTARG ;;
    s) special_codes=$OPTARG ;;
    t) hrs=$OPTARG ;;
    v) ivdw=$OPTARG ;;
    V) vasp_version=$OPTARG ;;
    w) write_incar=0 ;;
    W) write_flags=$OPTARG ;;
    X) exchange_mode=$OPTARG ;;
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
    echo "     OPTIONS:"
    echo
    echo "    -f -*- input file (default POSCAR)"
    echo "    -d --- debug (default off)"
    echo "    -h --- print this help message"
    echo
    echo "    -t -*- time in hours for job script (default $hrs)"
    echo "    -p -*- number of processors (no. cores actually, default=$numproc)"
    echo "    -P -*- partition override, (default= $partitions)"
    echo "    -q -*- queue name for job submission (default is $queue)"
    echo "           Currently supported queue names are $QUEUE_OPTIONS"
    echo
    echo "    -k -*- kpoint min (-1 = use Gamma only; also sets ediff=1e-5) (default=2)"
    echo "    -K --- use Gamma-centered KPOINTS (for hexagonal lattices)"
    echo "    -M --- set ismear and sigma for metal"
    echo "    -F -*- 'fast' -- number of relaxations with gamma only, then back to -k switch value"
    echo
    echo "    -a -*- convergence issues:"
    echo "           1: use algo=fast, ediff=1e-07, prec=high (def Very_Fast,-06,normal)"
    echo "           2: use algo=normal, ediff=1e-07, prec=high"
    echo "           3: use algo=fast, ediff=1e-07, prec=high, enaug=1000"
    echo "           4: use algo=All (all bands with conjugate gradient)"
    echo
    echo "    -m -*- major mode: (default is for standard vasp run)"
    echo "           1: phonon calc INCAR (for frozen phonon calc)"
    echo "           2: phonon optic mode hand calc INCAR"
    echo "           3: linear response phonon calc INCAR for VASP 5"
    echo "           4: frozen phonon calc INCAR for VASP 5"
    echo "           5: frozen phonon with Ozolins Gobaby code"
    echo "          10: electronic DOS"
    echo "          11: BAND structure calculation"
    echo "          12: BORN effective charge calculation"
    echo "          13: BADER charge calculation (requires external bader code)"
    echo "              Note! must add the no. of elec's not in psp to the"
    echo "              'charge'. e.g. standard N has zval 5, so add 2 to get"
    echo "              the total number of electrons on the atom."
    echo "          20: SPIN polaorized calculation (use -O to set MAGMOM)"
    echo "          40: MD: standard molecular dynamics run"
    echo
    echo "    -X -*- exchange/correlation and hybrid functionals:"
    echo "          1: .................... B3LYP - use paw_GGA psps"
    echo "          2: .................... PBE0 - must use paw_PBE psps with -D switch"
    echo
    echo "    -W -*- write output files flag (default 000)"
    echo "           'abc' where a,b,c are 1 or 0. Example -W 101"
    echo "           a=LWAVE    b=LCHARG    c=LVTOT"
    echo
    echo "    -s -*- special codes"
    echo "           use: -s \"ICHARG=11 LORBIT=11\" "
    echo
    echo "    -v -*- set IVDW in INCAR (default $ivdw)"
    echo "           1  or 10 = DFT-D2 Grimme (note: use -v 1 with -V 532 for paw_GGA pots)"
    echo "           11 or 12 = DFT-D3 Grimme"
    echo
    echo "    -V -*- vasp version (default $vasp_version)"
    echo
    for vv in $ver_list; do
	echo "           "$vv" = "$(eval echo \$ver_$vv)
    done
    echo
    echo "    -B -*- berry phase mode"
    echo "           1: X"
    echo "           2: Y"
    echo "           3: Z"
    echo
    echo "           INCAR PARAMETERS and POTCAR CHOICES"
    echo
    echo "    -C --- set LCHARG variable to TRUE"
    echo "    -g --- do NOT set NPAR (default is off)"
    echo "    -O -*- set MAGMOM, use quotes, eg: 40*0 1 -1 1 -1 for 44 atom cell"
    echo "    -L -*- EDIFF (default=$ediff) electronic stopping eV"
    echo "    -G -*- EDIFFG (default=$ediffg) geometry stopping eV/ang"
    echo "    -E -*- ENMAX (default $enmax)"
    echo "    -i -*- ISIF (default $isif)"
    echo "    -I -*- ISYM (default $isym)"
    echo "    -N -*- NSW (default $nsw)"
    echo "    -n --- set max number of relaxation iterations to 1 (default 9)"
    echo
    echo "    -D -*- directory to search for POTCAR files (def pawpot_GGA)"
    echo "           'pawpot_GGA'   'pawpot_LDA'   'pawpot_PBE'"
    echo "    -e -*- element list (default automatically read from POSCAR)"
    echo
    echo "    -w --- do NOT write INCAR file"
    echo "    -c --- clean output files and exit"
    echo
    echo
    echo Eric Majzoub
    echo Sandia National Laboratories
    echo v 1.0 26 Feb 2007
    echo "current version: "$script_version
    echo
    exit
fi

#########################################################
# save command line in case needed for later reference
#########################################################
if [ $clean -ne 1 ]; then
    echo "* script         = "$script_name | tee cline.out
    echo "* script version = "$script_version | tee -a cline.out
    echo "* script date    = "$script_date | tee -a cline.out
    echo "* command line   = "$cline | tee -a cline.out
fi


#########################################################
# functions
#########################################################
function check_for_wavecar (){
    if [ -s ../WAVECAR ]; then
	echo "symlinking with WAVECAR from ../"
	ln -sf ../WAVECAR .
    else
	echo "No WAVECAR found to start from. Exiting."
	exit
    fi
}

function HF_set_algo_flag (){
    # This function is for hybrid exchange functionals only
    if [ $metal -eq 1 ]; then
	algo="Damp";
    else
	algo="All";
    fi
}

function print_parms () {
    if [ $dbg -eq 1 ]; then
	echo "######### parms ##########";
	echo "algo= "$algo;
	echo "potcar_dir= "$potcar_dir;
	echo "poscar= "$poscar;
	echo "element_list= "$element_list;
	echo "kpts= "$kpts;
	echo "isif= "$isif;
	echo "isym= "$isym;
	echo "numproc= "$nproc;
	echo "major_mode= "$major_mode
    fi
}

function remove_files () {

    # if write_incar is 0, we are running elcons or something...
    if [ $write_incar -eq 1 ]; then
	rm -f INCAR;
    fi
    # do not put cline here, it will be erased!!
    rm -f POTCAR KPOINTS Script* script* OSZICAR vasp.* IBZ* CHG*;
    rm -f RUN* VASP* WAVE* job* XDAT* REPORT DOSCAR EIG* PC*;
    rm -f submit* OUTCAR* vasp* sbatch.out Vlocal *run;
    rm -f AEC* BCF.dat ACF.dat AVF.dat ELFCAR PROCAR;
    rm -f slurm*;
}

function get_elements_from_poscar () {

    echo "* Using potcar_dir= "$potcar_dir;

    cat > $tmp_base.01.awk <<EOF
    (NR==1){ for(i=2;i<NF+1;i++){printf("%d ",\$i);} }
EOF

    element_list=`head -1 $poscar | awk -f $tmp_base.01.awk`

}

function make_incar_file () {

    rm -f INCAR;

    echo "SYSTEM  =   Auto generated by VASP_setup, v "$script_version  >> INCAR;
    echo
    if [ "$istart" != "" ]; then
    echo "ISTART  =   "$istart >> INCAR;        
    fi
    echo "LWAVE   =   "$lwave >> INCAR;
    echo "LCHARG  =   "$lchrg >> INCAR;
    echo "LVTOT   =   "$lvtot >> INCAR;
    if [ "$lorbit" != "" ]; then
	echo "LORBIT  =   "$lorbit >> INCAR;
    fi
    if [ "$lelf" != "" ]; then
	echo "LELF    =   "$lelf >> INCAR;
    fi
    if [ "$laechg" != "" ]; then
	echo "LAECHG  =   "$laechg >> INCAR;
    fi
    if [ $ivdw -gt 0 ]; then
	echo "IVDW    =   "$ivdw >> INCAR;
    fi
    if [ "$icharg" != "" ]; then
	echo "ICHARG  =   "$icharg >> INCAR;
    fi
    echo " " >> INCAR;
 
    echo "NSIM    =   4  > 1 use blocked RMM-DIIS = 3D BLAS = faster" >> INCAR;
    echo " " >> INCAR;
    echo "# Electronic Relaxation 1" >> INCAR;
    if [ "$enmax" != "" ]; then
	echo "ENMAX   =   "$enmax >> INCAR;
    fi
    echo "#ENAUG   =   "$enaug >> INCAR;
    echo "ADDGRID =  "$addgrid >> INCAR;
    echo "PREC    =   "$prec " Normal  Medium=default, Normal has better forces" >> INCAR;
    echo "EDIFF   =   "$ediff " energy stopping-criterion for elec iterations" >> INCAR;
    if [ "$ediffg" != "" ]; then
	echo "EDIFFG  =   "$ediffg " force stopping-criterion for geometry steps" >> INCAR;
    fi
    echo " " >> INCAR;
    echo "# Ionic Relaxation" >> INCAR;
    echo "IBRION  =   "$ibrion >> INCAR;
    if [ $smass -ne -10 ]; then
	echo "SMASS   =   "$smass >> INCAR;
    fi

    if [ "$tebeg" != "" ]; then
	echo "TEBEG   =   "$tebeg >> INCAR;
    fi
    if [ "$teend" != "" ]; then
	echo "TEEND   =   "$teend >> INCAR;
    fi
    if [ "$nelmin" != "" ]; then
	echo "NELMIN  =   "$nelmin >> INCAR;
    fi
    if [ "$nelm" != "" ]; then
	echo "NELM    =   "$nelm >> INCAR;
    fi
    if [ "$nblock" != "" ]; then
	echo "NBLOCK  =   "$nblock >> INCAR;
    fi

    echo "# settings for parallel version (ignored in serial run)" >> INCAR;
    echo "LPLANE  =   .TRUE.   reduces communication in FFT" >> INCAR;
    if [ $unset_npar -eq 0 ]; then
	echo "$NPAR" >> INCAR;
    fi

    if [ $major_mode -ne 3 ]; then
	echo "NSW     =   "$nsw >> INCAR;
	echo "POTIM   =   "$potim >> INCAR;
	echo "ISIF    =   "$isif >> INCAR;
    fi
    if [ $major_mode -eq 4 ]; then
	echo "NFREE   =  "$nfree >> INCAR;
    fi
    echo "ISYM    =   "$isym >> INCAR;
    echo " " >> INCAR;
    if [ $major_mode -eq 3 ]; then
	echo "# Linear response settings" >> INCAR;
	echo "LEPSILON = "$lepsilon >> INCAR;
	echo "LRPA = "$lrpa >> INCAR;
	echo " " >> INCAR;
    fi
    if [ $born -gt -1 ]; then
	echo "# calc Born effective charges" >> INCAR;
	echo "LCALCEPS =   .TRUE." >> INCAR;
	echo "LRPA     =   .TRUE." >> INCAR;
    fi

    # major mode 6x
    if [ $exchange_mode -gt 0 ]; then
	echo "# Hybrid functional options" >> INCAR;
    fi
    if [ "$lhfcalc" != "" ]; then
	echo "LHFCALC =   "$lhfcalc >> INCAR;
    fi
    if [ "$gga" != "" ]; then
	echo "GGA     =   "$gga >> INCAR;
    fi
    if [ "$aexx" != "" ]; then
	echo "AEXX    =   "$aexx >> INCAR;
    fi
    if [ "$aggax" != "" ]; then
	echo "AGGAX   =   "$aggax >> INCAR;
    fi
    if [ "$aggac" != "" ]; then
	echo "AGGAC   =   "$aggac >> INCAR;
    fi
    if [ "$aldac" != "" ]; then
	echo "ALDAC   =   "$aldac >> INCAR;
    fi


    if [ $berry -gt -1 ]; then
	echo "# Berry phase settings" >> INCAR;
    fi
    echo -e $b_set >> INCAR;
    echo " " >> INCAR;
    echo "# DOS related values" >> INCAR;
    echo "ISMEAR  =  "$ismear  >> INCAR;
    echo "SIGMA   =  "$sigma   >> INCAR;
    echo " " >> INCAR;
    echo "# Electronic Relaxation" >> INCAR;
    echo "ALGO    =   "$algo >> INCAR;
    echo "LREAL   =   .FALSE." >> INCAR;
    echo >> INCAR;
    if [ "$ispin" != "" ]; then
	echo "ISPIN   =   "$ispin >> INCAR;
    fi
    if [ "$magmom" != "" ]; then
	echo "MAGMOM   =  "$magmom >> INCAR;
    fi
    echo "$special_codes" | gawk --source '{for(i=1;i<NF+1;i++){printf("%s\n",$i);}}' >> INCAR;
    
}

############ Make POTCAR file #################
function make_potcar_file () {

    paw_pbe=`echo "$potcar_dir" | awk '($1 ~ "pawpot_PBE"){printf("%d\n",1);}'`
    paw_gga=`echo "$potcar_dir" | awk '($1 ~ "pawpot_GGA"){printf("%d\n",1);}'`
    pot_gga=`echo "$potcar_dir" | awk '($1 ~    "pot_GGA"){printf("%d\n",1);}'`
    
    for elem_num in $element_list; do

	if [ $dbg -eq 1 ]; then
	    echo "searching for POTCAR for element "$elem_num;
	fi

	elem_label=`echo $elem_num | $GAWK -f $AWKFILES/awklib.awk --source '{printf("%s",ztoelm($1));}'`
	
	# These are special cases
	if [ $elem_num -eq  1 ] && [ "$pot_gga" == 1 ]; then
	    elem_label="H_200eV"
	fi
	if [ $elem_num -eq  1 ] && [ "$paw_gga" == 1 ]; then
	    elem_label="H"
	fi
	if [ $elem_num -eq 19 ] && [ "$pot_gga" == 1 ]; then
	    elem_label="K"
	fi
	if [ $elem_num -eq 19 ] && [ "$paw_gga" == 1 ]; then
	    elem_label="K_sv"
	fi
	if [ $elem_num -eq 19 ] && [ "$paw_pbe" == 1 ]; then
	    elem_label="K_sv"
	fi
	if [ $elem_num -eq 20 ] && [ "$paw_gga" == 1 ]; then
	    elem_label="Ca"
	fi
	if [ $elem_num -eq 20 ] && [ "$pot_gga" == 1 ]; then
	    elem_label="Ca"
	fi
	if [ $elem_num -eq 20 ] && [ "$paw_pbe" == 1 ]; then
	    elem_label="Ca_pv"
	fi
	if [ $elem_num -eq 21 ] && [ "$paw_pbe" == 1 ]; then
	    elem_label="Sc_sv"
	fi
	if [ $elem_num -eq 21 ] && [ "$paw_pbe" != 1 ]; then
	    elem_label="Sc"
	fi
	if [ $elem_num -eq 37 ] && [ "$paw_pbe" != 1 ]; then
	    elem_label="Rb_sv"
	fi
	if [ $elem_num -eq 38 ] && [ "$paw_pbe" != 1 ]; then
	    elem_label="Sr_sv"
	fi
	if [ $elem_num -eq 55 ] && [ "$paw_pbe" != 1 ]; then
	    elem_label="Cs_sv"
	fi
	if [ $elem_num -eq 56 ] && [ "$paw_pbe" != 1 ]; then
	    elem_label="Ba_sv"
	fi

	if [ $dbg -eq 1 ]; then
	    echo "elem_label= "$elem_label;
	fi

	potdir_list=`ls $potcar_dir`;
	if [ $dbg -eq 1 ]; then
	    echo "potdir_list= "$potdir_list
	fi

	potcar_found=0;
	for dirname in $potdir_list; do
	    if [ "$dirname" == "$elem_label" ]; then
		cat $potcar_dir/$elem_label/POTCAR >> POTCAR;
		potcar_found=1;
		elem_label="";
	    fi
	done


	if [ $potcar_found -eq 0 ]; then
	    echo "!! Trouble finding POTCAR for "$elem_label;
	    echo "!! Searching for Z= "$elem_num;
	    echo "exiting"
	    exit;
	fi


	
    done
    
}

function make_kpoints_file () {

    cat $poscar | awk '(NR==3 || NR==4 || NR==5){print $0}' > $tmp_base.03.latvecs
    
    cat > $tmp_base.02.awk <<EOF
    (NR==1){ r11=\$1; r12=\$2; r13=\$3; }
    (NR==2){ r21=\$1; r22=\$2; r23=\$3; }
    (NR==3){ r31=\$1; r32=\$2; r33=\$3; }
    END{
	a=sqrt(r11*r11 + r12*r12 + r13*r13);
	b=sqrt(r21*r21 + r22*r22 + r23*r23);
	c=sqrt(r31*r31 + r32*r32 + r33*r33);
	cell_vol=r31*(r12*r23-r13*r22) + r32*(r11*r23-r13*r21) + r33*(r11*r22-r12*r21);
	if ( cell_vol < 0 ) { cell_vol= -cell_vol;}
	cv3=exp( (1/3)*log( cell_vol ) );
	kx=int(cv3/a*$kpt_min);
	ky=int(cv3/b*$kpt_min);
	kz=int(cv3/c*$kpt_min);
	if ( kx%2 != 0 ) kx-=1;
	if ( ky%2 != 0 ) ky-=1;
	if ( kz%2 != 0 ) kz-=1;
	if ( kx == 0 ) kx=2;
	if ( ky == 0 ) ky=2;
	if ( kz == 0 ) kz=2;
	printf("%.0f %.0f %.0f\n",kx,ky,kz);
    }
EOF

##############################
if [ $kpt_min -eq -1 ]; then
    echo "!!! kpt_min is set to -1 !!!"
    echo "* Using GAMMA POINT version of VASP"
    vasp_version=15;
fi

##############################
# assemble the KPOINTS file
##############################

if [ $vasp_version -eq 15 ] || [ $kpt_min -eq -1 ]; then
    gamma_centered_kpoints=1; kpts="1 1 1"; ediff="1E-05";
else
    kpts=$(cat $tmp_base.03.latvecs | awk -f $tmp_base.02.awk);
fi
echo "* kpts = "$kpts

echo "Auto" >> KPOINTS;
echo "0" >> KPOINTS;
if [ $gamma_centered_kpoints -eq 1 ]; then
    echo "Gonkhorst" >> KPOINTS;
else
    echo "Monkhorst" >> KPOINTS;
fi
if [ $vasp_version -eq 15 ]; then
    echo "1 1 1" >> KPOINTS;
else
    echo $kpts >> KPOINTS;
fi
echo "0. 0. 0." >> KPOINTS;

#############################
# Calculate kpoint density
NKPTS=$(echo $kpts | gawk --source '(NF==3){ printf("%.3f",$1*$2*$3); }' );
if [ $dbg -eq 1 ]; then
    echo "NKPTS= "$NKPT
fi
cat $poscar | $GAWK -f $AWKFILES/contcar_info.awk -v KPTS=$NKPTS | grep "K-point density"

} # end  make_kpoints_file


function make_script_run_file () {

    VASP_EXE=$(eval echo \$USR_VASP_EXE_V_$vasp_version);

cat > Script_$top.sh <<EOF
#!/bin/sh

    # Autogenerated from VASP_setup.sh version: $script_version
    # defaults from vasp_setup script
    bad_term_count=$BAD_TERM_COUNT;
    bad_term_max=$BAD_TERM_MAX;

    # functions
    function check_load_and_sleep () {

    	part=\$1 # the partition should be passed to this function

        if [ "$LOCATION" == "desktop" ]; then
           return;
        fi

	if [ "\$part" == "NOT_SET_YET" ]; then
	   echo "    fcn check_load_and_sleep: partition not set yet."; echo
	   return;
	fi

	load_wait=$load_wait; # default to preset
	if [ "\$part" == "grethor" ]; then load_wait=$load_wait_grethor; fi
	if [ "\$part" == "free" ];    then load_wait=$load_wait_free;    fi
	if [ "\$part" == "requeue" ]; then load_wait=$load_wait_requeue; fi

        echo "   Checking cluster load on CLUSTER= $CLUSTER, partition= \$part ... "
        cluster_load=\$($BASE/bin/load \$part);
        echo "     Load = \$cluster_load     load_max= \$load_wait";

        while [ \$cluster_load -gt \$load_wait ]; do
           echo "     sleeping $wait_time "; sleep $wait_time;
           cluster_load=\$($BASE/bin/load \$part);
        done
    }

    cdir=\`pwd\`
    $MODULE_LINE_IN_SCRIPT_FILE
    rm -f DONE_FLAG

    echo "cdir="\$cdir
    echo "Starting Script.sh... in directory= "\$cdir
    
    unset noclobber
    if [ -e STOPCAR ]; then
	rm -f STOPCAR
    fi

    # create the executable in current directory
    echo "$VASP_EXE" > VASP_EXE_POINTER;

    nproc=$numproc;
    NUM=2;

    # must have the nproc *= statement AFTER the k_machines call
    #nproc=\`echo \$nproc \$NUM | awk '{print \$1*\$2}'\`;
    # set mach=\`cat machines\`

    # echo \$mach >| vasp.out 
    echo Script_"$top".sh PID = \$\$ >| vasp.out

    for iter in $n_iter; do

	echo
	echo "    +++++  Starting iteration number "\$iter
	echo

        check_load_and_sleep NOT_SET_YET;

        ## FAST switch code
        if [ $fast -gt 0 ] && [ \$iter -eq 1 ]; then
           echo "*** Fast switch set and iter == 1. Creating gamma KPOINTS file, and setting pointer to gamma vasp."
           cp KPOINTS save_KPOINTS;
           echo "Auto" > KPOINTS; echo "0" >> KPOINTS; echo "G" >> KPOINTS; echo "1 1 1" >> KPOINTS; echo "0.0 0.0 0.0" >> KPOINTS;
           echo "$VASPgamma" > VASP_EXE_POINTER;
        fi
        if  [ $fast -gt 0 ] && [ \$iter -gt $fast ]; then
           echo "*** Fast switch set and iter == 3. Restoring original KPOINTS and vasp_exe pointer."
           mv -f save_KPOINTS KPOINTS;
           echo "$VASP_EXE" > VASP_EXE_POINTER;
        fi

       echo "(A) --- Creating RUN_LOOP_LOCK ---"
       #  used in case of bad termination runs...
       #   if 'bad' the script will restart the itertation and NOT increment the iter num
       touch RUN_LOOP_LOCK; 
       # check to see if the job fails for some reason (bad nodes), etc. And re-run the iteration if it fails.
       bad_run_check="-1";

       while [ -e RUN_LOOP_LOCK ]; do

          echo;
          echo "(B) --- Submitting job to queue ---"
          $LINK_LINE_IN_DESKTOP_VERSION
          $SUBMIT_LINE_IN_SCRIPT_FILE 

          #files=\$(ls);
          #echo "files= "\$files;

          if [ -e sbatch.out ]; then
             echo "Found sbatch.out file."
          elif [ ! -e sbatch.out ] && [ ! $LOCATION == "desktop" ]; then
             echo "  !ERROR: No sbatch.out file! Exiting. (see Script.sh file)."; exit;
          fi
          err_trap=\$(cat sbatch.out | head -1 | grep error | wc -l);
          if [ \$err_trap -ge 1 ]; then
             rm -f Vlocal RUN_LOOP_LOCK;
             echo; echo "!!! Error submitting job. See sbatch.out file. Exiting. !!!"; echo; exit;
          fi

          # get the job number from the system
          jobnum=\`head -1 sbatch.out | awk '{ print \$4 }'\`;
          # jobfile=\${cdir##/*/}_out.\$jobnum;
          jobfile=job-\$jobnum;
	  # get the partition the job was submitted to
	  part=\$(myruns | gawk --source '(\$1==JOBNUM){print \$2}' -v JOBNUM=\$jobnum;)
          echo;
          echo "(C) --- JOB ID NUMBERS: jobnumber= "\$jobnum  " jobfile= "\$jobfile  "   partition= "\$part;

          while [ -e ./sbatch.out ]; do
             sleep 5;
          done

          if [ ! -e \$jobfile ]; then
             echo "In Script_ file. No jobfile found with name= "\$jobfile;
          elif [ ! -s \$jobfile ]; then
             echo "In Script_ file. Jobfile with name= "\$jobfile " is empty."             
          fi
          bad_run_check=\$(cat \$jobfile | grep "BAD TERMINATION OF ONE OF YOUR APPLICATION PROCESSES" | wc -l);
          if [ \$bad_run_check -eq 1 ]; then

             bad_term_count=\$((bad_term_count+1))
             echo; echo "!!!!!!!!!!!!!!!   BAD TERMINATION error count \$bad_term_count  !!!!!!!";
             echo "   --- trying to kill the job file if it still exists. job= "\$jobnum;
	     $QDEL_LINE_IN_SCRIPT_FILE

             echo "Will check load and sleep if necessary before resubmitting this iter..."
             check_load_and_sleep \$part;

             echo "Resubmitting this job..."; echo

             if [ \$bad_term_count -gt \$bad_term_max ]; then
                  echo "Reached bad termination max count. Investigate errors. Exiting."; exit;
             fi

          else

             echo "Successful iteration... removing RUN_LOOP_LOCK file..."
             rm -f RUN_LOOP_LOCK;

          fi
       done
       # end bad run check

        echo "Variable dont_move_outcar= "$dont_move_outcar;
        if  [ $dont_move_outcar -eq 0 ]; then    
            echo "copying CONTCAR to POSCAR (inside Script.sh)"
            if [ -s ./CONTCAR ]; then
               cp -f CONTCAR POSCAR
            else
               echo "CONTCAR empty!!"
            fi
            echo "Calling restart.sh..."
	    $RESTART_LINE_IN_SCRIPT_FILE $LOCATION
        fi

        echo;
        echo "(D) --- Deleting job number "\$jobnum;
        $QDEL_LINE_IN_SCRIPT_FILE

        if  [ $dont_move_outcar -eq 0 ]; then
            mv OUTCAR OUTCAR-\$iter;
	    # remove the last OUTCAR-
            p=\$((iter-1));
	    if [ -e OUTCAR-\$p ]; then
	       rm -f OUTCAR-\$p;
	    fi
        fi

	nit=\`grep "F\=" OSZICAR | wc -l\`
        echo "(E) --- checking number of iterations... nit= "\$nit
	if [ \$nit -eq 1 ]; then
            if [ $fast -eq 0 ]; then
	       echo "nit=1, (ISIF==3, no volume or ion moves; ISIF==2, no ion moves) stopping."
	       break
            fi
            if [ $fast -gt 0 ] && [ \$iter -gt $fast ]; then
               echo "nit=1, and fast switch is set, and iter > fast ==> ran at least one non-gamma kpoints run."
               break
            fi 
	fi

    done

    echo "Volume change iterations= "\$iter
    if  [ $dont_move_outcar -eq 0 ]; then        
    	echo "Symlinking last OUTCAR..."
    	ln -sf OUTCAR-\$iter OUTCAR
    fi

    echo; echo "   +++ Successful Script.sh run. +++"; echo
    # remove executable after running
    rm -f ./sbatch.out ./STDIN.* vasprun.xml ./Vlocal VASP_EXE_POINTER 

exit

EOF

chmod +x Script_$top.sh;

}

function make_submitvasp_forge () {
    
cdir=`pwd`

cat > submitvasp.job <<EOF
#!/bin/bash -l
#SBATCH --time=$hrs:00:00
#SBATCH --ntasks=$numproc
#SBATCH --partition=$partitions
#SBATCH --mem-per-cpu=$memory_per_cpu_MB
#SBATCH --job-name=$jobname
##SBATCH --mail-type=fail
#SBATCH --export=all
#SBATCH --workdir=$cdir
#SBATCH --out=job-%j
$QUEUE
$EXCLUSIVE
$NNODES

cd $cdir
if [ ! -e ./VASP_EXE_POINTER ]; then
   echo "No VASP_EXE_POINTER file. Exiting."; exit
fi
VASP_LOC_EXE=\$(cat ./VASP_EXE_POINTER)
cp \$VASP_LOC_EXE ./Vlocal

module load mvapich2/intel/15/ib
time mpirun -np $numproc ./Vlocal < /dev/null 2>&1 | tee vasp.out ;

$BADER_COMMAND1
$BADER_COMMAND2
$BADER_COMMAND3

if [ $fast -gt 0 ]; then
   rm -f ./sbatch.out ./STDIN.* ./nslots 
fi
if [ $fast -eq 0 ]; then
   rm -f ./sbatch.out ./STDIN.* ./nslots ./Vlocal
fi

EOF

}

function make_submitvasp_quartz () {
    
cdir=`pwd`

cat > submitvasp.job <<EOF
#!/bin/bash -l
#MSUB -N $jobname
#MSUB -l procs=$numproc
#MSUB -A hstore
#MSUB -q pbatch
#MSUB -l walltime=$hrs:00:00
#MSUB -l gres=lscratchh

$QUEUE
$EXCLUSIVE
$NNODES

cd $cdir
if [ ! -e ./VASP_EXE_POINTER ]; then
   echo "No VASP_EXE_POINTER file. Exiting."; exit
fi
VASP_LOC_EXE=\$(cat ./VASP_EXE_POINTER)
cp \$VASP_LOC_EXE ./Vlocal

module load mkl/2018.0
#time mpirun -np $numproc ./Vlocal < /dev/null 2>&1 | tee vasp.out ;
time srun -n $numproc ./Vlocal < /dev/null 2>&1 | tee vasp.out ;

$BADER_COMMAND1
$BADER_COMMAND2
$BADER_COMMAND3

if [ $fast -gt 0 ]; then
   rm -f ./sbatch.out ./STDIN.* ./nslots 
fi
if [ $fast -eq 0 ]; then
   rm -f ./sbatch.out ./STDIN.* ./nslots ./Vlocal
fi

EOF

}


function get_nit_from_outcar () {
    outcar_nit=$(cat OUTCAR | grep Iteration | tail -1 | gawk '{print $3}' | gawk -F '(' '{print $1}');
}

#################### END FUNCTIONS ######################



###############################################################
#   INCAR FILE SETTINGS
###############################################################

# NPAR setting
if [ $numproc -le 2 ]; then
    NPAR="NPAR    =   $numproc";
elif [ $numproc -eq 2 ] || [ $numproc -eq 4 ] || [ $numproc -eq 8 ]; then
    NPAR="NPAR    =   2";
elif [ $numproc -eq 16 ] || [ $numproc -eq 32 ]; then
    NPAR="NPAR    =   4";
fi
if [ $born -eq 1 ]; then
    NPAR="NPAR    =   $numproc";
fi


################################################################
# Convergence issues settings:
if [ $converg -eq 1 ]; then
    algo="Fast"; ediff="1E-07"; prec="Accurate";
fi
if [ $converg -eq 2 ]; then
    algo="Normal"; ediff="1E-07"; prec="Accurate";
fi
if [ $converg -eq 3 ]; then
    algo="Fast"; ediff="1E-07"; prec="Accurate"; enaug="1000.00"; addgrid=".TRUE.";
fi
if [ $converg -eq 4 ]; then
    algo="All"; ediff="1E-06";
fi

###############################################################
# Metal settings
if [ $metal -eq 1 ]; then
    ismear=1; sigma=0.2;
fi

################################################################
# POTCAR directory
echo "* Using POTCAR type: "$potcar_type
if   [ "$potcar_type" == "pawpot_GGA" ]; then
    potcar_dir=$pawpot_GGA_dir;
elif [ "$potcar_type" == "pawpot_PBE" ]; then
    potcar_dir=$pawpot_PBE_dir;
elif [ "$potcar_type" == "pawpot_LDA" ]; then
    potcar_dir=$pawpot_LDA_dir;
elif [ "$potcar_type" == "pot_LDA" ]; then
    potcar_dir=$pot_LDA_dir;
else
    echo "Can't find directory for POTCARs... check -D switch. Exiting."; exit;
fi

################################################################
# Write flags:  'abc'
# a=LWAVE    b=LCHARG    c=LVTOT
if   [ "$write_flags" == "000" ]; then
    echo "* Using standard write flags (no wave, charg, or vtot...)"
elif [ "$write_flags" == "100" ]; then
    lwave=".TRUE.";  lchrg=".FALSE."; lvtot=".FALSE.";
elif [ "$write_flags" == "010" ]; then
    lwave=".FALSE."; lchrg=".TRUE.";  lvtot=".FALSE.";
elif [ "$write_flags" == "001" ]; then
    lwave=".FALSE."; lchrg=".FALSE."; lvtot=".TRUE.";
elif [ "$write_flags" == "110" ]; then
    lwave=".TRUE.";  lchrg=".TRUE.";  lvtot=".FALSE.";
elif [ "$write_flags" == "101" ]; then
    lwave=".TRUE.";  lchrg=".FALSE."; lvtot=".TRUE.";
elif [ "$write_flags" == "011" ]; then
    lwave=".FALSE."; lchrg=".TRUE.";  lvtot=".TRUE.";
elif [ "$write_flags" == "111" ]; then
    lwave=".TRUE.";  lchrg=".TRUE.";  lvtot=".TRUE.";
else
    echo "Bad form for -W switch. Exiting."
    exit
fi

################################################################
# Major Mode settings:
################################################################
echo "**********************************************************"
if [ $major_mode -eq 1 ]; then
    echo "* MAJOR MODE  1: phonon calc INCAR (for frozen phonon calc)"
    ibrion=0; isif=0; potim="1.0"; smass="-2"; nsw="5";
fi
if [ $major_mode -eq 2 ]; then
    echo "* MAJOR MODE  2: phonon optic mode hand calc INCAR"
    ibrion=0; isif=0; potim="0.1"; smass="-2"; nsw="8";
fi
if [ $major_mode -eq 3 ]; then
    echo "* MAJOR MODE 03: linear response phonon calc INCAR for VASP 5"
    ibrion=8; isif=0; smass="-3"; nsw="0"; lepsilon=".TRUE."; lrpa=".FALSE.";
    n_iter="1"; dont_move_outcar=1;
    NPAR="NPAR    =   $numproc"; # necessary for phonon calcs
fi
if [ $major_mode -eq 4 ]; then
    echo "* MAJOR MODE 04: frozen phonon calc INCAR for VASP 5"
    ibrion=6; isif=0; potim="0.015"; nfree="2"; nsw="1";
    n_iter="1"; dont_move_outcar=1;
    NPAR="NPAR    =   $numproc"; # necessary for phonon calcs
fi
if [ $major_mode -eq 5 ]; then
    echo "* MAJOR MODE 05: frozen phonon calc using Ozolins Gobaby code"
    ibrion=0; isif=0; potim="1.0"; nsw="5"; smass="-2";
    icharg="2"; n_iter="1"; dont_move_outcar=1;
    NPAR="NPAR    =   $numproc"; # necessary for phonon calcs
fi
if [ $major_mode -eq 10 ]; then
    echo "* MAJOR MODE 10: electronic DOS"
    echo "* (Note: can run bader on CHGCAR, but core charges are absent)"
    ibrion="-1"; nsw=0; smass="-2"; potim="0.1"; isif=0;
    lorbit=11; lchrg=".TRUE."; lelf=".TRUE.";
    NPAR="NPAR    =   1"; # necessary for phonon calcs
    n_iter=1; dont_move_outcar=1;
fi
if [ $major_mode -eq 11 ]; then
    echo "* MAJOR MODE 11: BAND structure calculation"
    ibrion="-1"; icharg=11; lorbit=11; nsw=0;
    n_iter=1; dont_move_outcar=1;
fi
if [ $major_mode -eq 12 ]; then
    echo "* MAJOR MODE 11: BORN effective charge calculation"
    born=1; n_iter=1; dont_move_outcar=1;
fi
if [ $major_mode -eq 13 ]; then
    which_bader=$(which bader);
    have_bader=$(which bader | gawk '($1~"no bader"){print 0; exit;}END{print 1}')
    if [ $have_bader -eq 0 ]; then
	echo; echo "!! No 'bader' executable. Cannot calculate bader charges !! Exiting."; exit;
    else
	echo "* Using bader exe: $which_bader"
    fi
    bader=1;

    ## old code, may be wrong
    #BADER_COMMAND1="# Bader code, core charges only!!"
    #BADER_COMMAND2="bader CHGCAR; mv ACF.dat bader.dat"
    #BADER_COMMAND3="rm -f CHG* BCF.dat AVF.dat ELFCAR"
    # Note I'm only use the CHGCAR since the AECCAR files don't seem to
    # give the core charges correctly, or have different units, or whatever.
    # Using the code from Henkleman's page, but only the valence charge
    # makes sense runing "bader CHGCAR" (i.e. no summing of AECCAR files and no ref)
    ## end old code

    # these commands are from the henkelman web page
    # http://theory.cm.utexas.edu/henkelman/code/bader/
    BADER_COMMAND1="# Bader code"
    BADER_COMMAND2="chgsum.pl AECCAR0 AECCAR2; bader CHGCAR -ref CHGCAR_sum"
    BADER_COMMAND3="mv ACF.dat bader.dat; rm -f BCF.dat AVF.dat"

    echo "* MAJOR MODE 13: BADER charge calculation using valence charge only!!"
    echo "* Note: AECCARn files don't work with the bader code properly (9/2017)"
    echo "* Post DFT calc, script will run the bader code on CHGCAR:"
    echo "* $ bader CHGCAR"
    echo "* Afterward it will remove the large CHG files"
    ibrion="-1"; nsw=0; smass="-2"; potim="0.1"; isif=0; prec="high"
    lorbit=11; lchrg=".TRUE."; lelf=".TRUE."; laechg=".TRUE."; addgrid=".TRUE."
    NPAR="NPAR    =   1"; # necessary for phonon calcs
    n_iter=1; dont_move_outcar=1;
fi
if [ $major_mode -eq 20 ]; then
    if [ "$magmom" == "" ]; then
	echo "must set -O switch for MAGMOM"
	exit
    fi
    echo "* MAJOR MODE 20: SPIN polarized calculation"
    ispin="2"; smass="-2"; potim="0.1"; isif=0; isym=2;
    npar=1; lchrg=".TRUE."; lelf=".TRUE.";
    ibrion="-1"; lorbit=11; nsw=0;
    n_iter=1; dont_move_outcar=1;
fi
if [ $major_mode -eq 40 ]; then
    echo "* MAJOR MODE 40: MD calculation"
    smass="-1"; potim="3.0"; isif=0; isym=0;
    npar=2; lchrg=".FALSE.";
    ibrion="0"; nsw=2000; tebeg="673"; teend="200";
    n_iter=1; dont_move_outcar=1;
    nelmin=6; nelm=100; prec="Low";
    nblock=1; ediff="1e-4"; ediffg=""; enmax="";
fi
echo "**********************************************************"

###############################################################
#  EXCHANGE/CORRELATION AND HYBRID FUNCTIONALS
###############################################################
if [ $exchange_mode -eq 1 ]; then
    echo "EXCHANGE MODE 1: HYBRID FCNL ... B3LYP"
    lhfcalc=".TRUE."; gga="B3"; aexx="0.2";
    aggax="0.72"; aggac="0.81"; aldac="0.19";
    istart=1;
    isym=3; # must use this for HF calcs
    HF_set_algo_flag;
    check_for_wavecar;
fi
if [ $exchange_mode -eq 2 ]; then
    echo "EXCHANGE MODE 2: HYBRID FCNL ... PBE0 ... also use -D /path/to/paw_PBE"
    lhfcalc=".TRUE."; gga="PE"; aexx="0.25";
    aggax="0.75"; aggac="1.0"; aldac="1.0";
    istart=1;
    isym=3; # must use this for HF calcs
    HF_set_algo_flag;
    check_for_wavecar;
fi


################################################################
# Berry's Phase setting:
# -1=no setting
#  1=x, 2=y, 3=z
if [ $berry -eq 1 ]; then
    lchrg=".FALSE."; nsw="1"; isif=2;
    b_set="LBERRY = .TRUE. \nIGPAR = 1 \nNPPSTR = 6 \nDIPOL = 0.5 0.5 0.5";
fi
if [ $berry -eq 2 ]; then
    lchrg=".FALSE."; nsw="1"; isif=2;
    b_set="LBERRY = .TRUE. \nIGPAR = 2 \nNPPSTR = 6 \nDIPOL = 0.5 0.5 0.5";
fi
if [ $berry -eq 3 ]; then
    lchrg=".FALSE."; nsw="1"; isif=2;
    b_set="LBERRY = .TRUE. \nIGPAR = 3 \nNPPSTR = 6 \nDIPOL = 0.5 0.5 0.5";
fi


###############################################################
#   BATCH FILE SETTINGS
###############################################################
if [ "$queue" != "" ]; then
    echo "* Setting queue to " $queue
    QUEUE="#SBATCH --account="$queue
fi

# SET CALL FOR MPIRUN OR QUEUE SYSTEM
if [ "$LOCATION" == "cluster" ]; then

    if [ $CLUSTER == "forge" ]; then
	LINK_LINE_IN_DESKTOP_VERSION=""
	SUBMIT_LINE_IN_SCRIPT_FILE="sbatch  submitvasp.job >& sbatch.out;"
	QDEL_LINE_IN_SCRIPT_FILE="qdel \$jobnum;";
	MODULE_LINE_IN_SCRIPT_FILE="module load mvapich2/intel/15/ib;"
	RESTART_LINE_IN_SCRIPT_FILE="$BASE/src/VASP_TOOLS/restart.sh "
    elif [ $CLUSTER == "quartz" ]; then
	LINK_LINE_IN_DESKTOP_VERSION=""
	SUBMIT_LINE_IN_SCRIPT_FILE="sbatch  submitvasp.job >& sbatch.out;"
	QDEL_LINE_IN_SCRIPT_FILE="qdel \$jobnum;";
	MODULE_LINE_IN_SCRIPT_FILE="module load mkl/2018.0"
	RESTART_LINE_IN_SCRIPT_FILE="$BASE/src/VASP_TOOLS/restart.sh "
    fi

elif [ "$LOCATION" == "desktop" ]; then

    VASP_EXE=$(eval echo \$USR_VASP_EXE_V_$vasp_version);
    echo "* Using VASP_EXE= "$VASP_EXE
    LINK_LINE_IN_DESKTOP_VERSION="ln -sf $(eval echo \$VASP_EXE) ./Vlocal;"
    SUBMIT_LINE_IN_SCRIPT_FILE="time mpirun -np $numproc ./Vlocal < /dev/null 2>&1 | tee vasp.out ;"
    QDEL_LINE_IN_SCRIPT_FILE=""
    MODULE_LINE_IN_SCRIPT_FILE=""
    RESTART_LINE_IN_SCRIPT_FILE="$HOME/src/VASP_TOOLS/restart.sh "

else
    exit
fi



################################################
#    SCRIPT STARTS HERE
################################################

if [ $dbg -eq 1 ]; then
    print_parms;
fi

if [ $clean -eq 1 ]; then
    remove_files;
    exit;
fi

if [ -z "$potcar_dir" ]; then
    echo "Can't find directory: "$potcar_dir
    echo "You must specify the directory to find POTCARS. Exiting."; exit;
fi

remove_files;
get_elements_from_poscar;
if [ $write_incar -eq 1 ]; then
    make_incar_file;
fi
make_potcar_file;
make_kpoints_file;
make_script_run_file;
if [ $CLUSTER == "forge" ]; then
    make_submitvasp_forge;
elif [ $CLUSTER == "quartz" ]; then
    make_submitvasp_quartz;
fi
touch script.$top.out ;

if [ $dbg -eq 0 ]; then
    rm -f $tmp_base.01.awk
    rm -f $tmp_base.02.awk
    rm -f $tmp_base.03.latvecs
fi
