#!/bin/bash

#################################################
# Editable things
#################################################
# 

script_name="gnufit.sh";
version="2.0.1"
ver_date="12 May 2020"

default_num_steps=9;

gp="gnuplot.p"
fit_limit=1e-5
TITLEFONT="Helvetica"
FONT="Helvetica"

# 04 Jan 2015 note:
# GNUPLOT fit segfaults in v4.6.6.
# It is apparently fixed in 5.0. Use 4.2 or around there...
#

# ver 2.0.1 -- add variable init for poly switch
# ver 2.0.0 -- clean up the code a bit and add showvariables
#              for some other functions.
# ver 1.8.9 -- add simple exponential fits.
# ver 1.8.8 -- removed FIT_LAMBDA_FACTOR. It caused segfault if set at all
#              with gnuplot 4.6.x
# ver 1.8.7 -- added pseudo-voigt peak type
# ver 1.8.6 -- added asymptotic with variable exponent power
#           -- add 'input variable guess' but only implemented this
#              for the asymp2 function. Will update as necessary.
#            --add max iterations switch, and lambda factors for gnuplot.
# ver 1.8.5 -- added shifted center for arb order poly
# ver 1.8.4 -- added rdf sphere fitting
# ver 1.8.3 -- fixed Birch-Murn
# ver 1.8.2 -- add pause time to switches
# ver 1.8.1 -- use "GNUPLOT < gp" instead of "GNUPLOT gp"
# ver 1.8 -- add Birch-Murnaghan EOS and make both EOS
#            output B in GPa
# ver 1.7 -- add quiet option and output only fit data
# ver 1.6 -- added asymptotic function
# ver 1.5 -- added arbitrary order polynomial at x=0
# ver 1.4 -- added cubic fit for raman calibration spectra
# ver 1.3 -- added jpeg output support.
# version 1.0, Mon Jun 19 2006


#################################################
# No need to edit below this line
#################################################

###########################################
# find the executables and set their paths
if [ ! -e /usr/bin/which ]; then
    echo "No file /usr/bin/which found. You must set"
    echo "executable locations in shell file by hand."
    exit 1
fi
AWK=`which awk`
if [ ! -e $AWK ]; then
    echo "WARNING: Executable 'awk' not found."
    AWK=/usr/local/bin/awk
    echo "using "$AWK
fi
CAT=`which cat`
if [ ! -e $CAT ]; then
    echo "WARNING: Executable 'cat' not found."
    CAT=/usr/local/bin/cat
    echo "using "$CAT
fi
GNUPLOT=`which gnuplot`
if [ ! -e $GNUPLOT ]; then
    echo "WARNING: Executable 'gnuplot' not found."
    GNUPLOT=/usr/local/bin/gnuplot
    echo "will try using "$GNUPLOT
fi


######################################
# defaults
file="Eout"
asmp=0
bmrn=0
dbg=0
eps=0
exp=0; exp_typ=0; exp_ord=0;
help=0
lambdafactor=0; # this is the default in gnuplot (0 sets it to 10)
lambdastart=0; # this is the default in gnuplot
min="*"
max="*"
maxiter=600;
mrn=0
order=0
pausetime=-1
poly=0
polymin=1
prb=0
pseudovoigt=0;
qd=0
quiet=0
so=0
sprb=0
shiftpoly=0
setx0=-1
showvars=0
title=""
varguess=""
xlabl="xlabl"
ylabl="ylabl"

jpeg_out=0;

######################################
declare SWITCH
while getopts "a:A:BdeE:f:gjl:m:L:M:hHI:sSt:T:p:P:qQx:X:v:VY:z" SWITCH; do
    case $SWITCH in
    a) asmp=1 ; order=$OPTARG ;;
    A) asmp=2 ; order=$OPTARG ;;
    B) bmrn=1 ;;
    f) file=$OPTARG ;;
    e) eps=1 ;;
    E) exp=$OPTARG;
       exp_typ=$(echo $exp | gawk -F: '{print $1}');
       exp_ord=$(echo $exp | gawk -F: '{print $2}');  ;;
    g) pseudovoigt=1 ;;
    j) jpeg_out=1; eps=1 ;;
    d) dbg=1 ;;
    l) polymin=$OPTARG ;;
    L) lambdafactor=$OPTARG ;;
    m) min=$OPTARG ;;
    M) max=$OPTARG ;;
    h) help=1 ;;
    H) mrn=1 ;;
    I) maxiter=$OPTARG ;;
    p) poly=$OPTARG ;;
    P) shiftpoly=$OPTARG ;;
    q) quiet=1; eps=1 ;;
    z) so=1 ;;
    Q) qd=1 ;;
    s) prb=1 ;;
    S) sprb=1 ;;
    t) pausetime=$OPTARG ;;
    T) title=$OPTARG ;;
    v) varguess=$OPTARG ;;
    V) showvars=1 ;;
    x) setx0=$OPTARG ;;
    X) xlabl=$OPTARG ;;
    Y) ylabl=$OPTARG ;;
    esac
done


if [ $# -eq 0 ] || [ $help -eq 1 ]; then
    echo
    echo "#######################"
    echo "#      "$script_name
    echo "#######################"
    echo
    echo "Version "$version
    echo $ver_date
    echo
    echo "use: "$script_name" -f infile  [options]"
    echo
    echo "    -d --- debug (default is OFF)"
    echo
    echo "             ---  INPUT AND OUTPUT ---"
    echo
    echo "    -f --- infile (default Eout)"
    echo "    -e --- output to eps file fit.eps"
    echo "    -j --- make a jpeg output file in addition"
    echo "             (turns on -e switch automatically)"
    echo "    -q --- quiet : do not plot, only print out the fit variables"
    echo "    -t -*- set pause time in seconds (default *should* hold graph)"
    echo "    -T --- figure title in quotes"
    echo "    -X --- x-axis label in quotes ({/Symbol q} for theta)"
    echo "    -Y --- y-axis label in quotes"
    echo
    echo "             --- FITTING DOMAIN AND NUM ITERATIONS ---"
    echo 
    echo "    -m -*- x min"
    echo "    -M -*- x max"
    echo "    -L -*- fit_lambda_factor (default 10, lower is bigger steps)"
    echo "             !!! crashes in gnuplot 4.6.x if not set to 0 !!!"
    echo "    -I -*- maximum number of iterations (default= 1000)"
    echo
    echo "             --- INITIALIZING VARIABLES ---"
    echo 
    echo "    -V --- show variables for a particular fit and exit"
    echo "             (so you know order when using the -v switch)"
    echo "    -v -*- set guess variables (option not coded for all functions yet)"
    echo "             use: -v \"1.234:8.92:5e-7:2.33\""
    echo
    echo "             --- GENERAL FUNCTIONS ---"
    echo
    echo "    -x --- set x0 SHIFT for -Q, -P, or -S switches"
    echo
    echo "    -s --- parabola            : a +            c*x**2, centered at x=0"
    echo "    -S --- parabola SHIFTed    : a +            c*(x-x0)**2"
    echo "    -z --- quadratic poly      : a + b*x +      c*x**2, centered at x=0"
    echo "    -Q --- SHIFTed quadratic   : a + b*(x-x0) + c*(x-x0)**2"
    echo
    echo "    -p -*- arb order poly         : a0 + a1*x + ... + a_n*x**n"
    echo "    -P -*- arb order poly SHIFTed : a0 + a1*(x-x0) + ... + a_n*(x-x0)**n"
    echo "    -l -*- set polymin ( >=2 )    : a_n*x**n + ..."
    echo "             Use with -P or -p switches to get, e.g. a2*x^2 + ... + a9*x^9"
    echo
    echo "    -a -*- asymptotic function type 1: a0 + a1*x + a2*x**2 + PE*(1-exp(-EX/x))"
    echo "             the argument is the order of the poly before the exponential."
    echo "             e.g. above is -a 2"
    echo "    -E -*- exponential function type and order: use -E n:O"
    echo "             1:2 --> a0 + a1 * exp(a2 * x) + a3 * exp(a4 * x)"
    echo "             2:1 --> a0 + a1 * exp(a2 / x)"
    echo
    echo "             --- SPECIALIZED FITS ---"
    echo
    echo "    -A -*- asymptotic function type 2:"
    echo "             rising is order 1, and falling is order 2"
    echo "             order 1: fmax-(fmax-f0)*exp{-((x-x0)/tau)^alpha}"
    echo "             order 2: f0-(f0-fmin)*(1-exp{-((x-x0)/tau)^alpha})"
    echo "    -H --- Murnaghan fit (assumes B' constant)"
    echo "             Output b is in GPa!!!"
    echo "    -B --- Birch-Murnaghan fit (higher order)"
    echo "    -g --- pseudo-Voigt fit"
    echo "             variables: X0 AMPLITUDE ETA HWIDTH BASELINE"
    echo
    echo
    echo
    echo Eric Majzoub
    echo Sandia National Laboratories
    echo 19 June 2006
    echo
    echo
    exit
fi

#############################################################
#############################################################

if [ $dbg -eq 1 ]; then
    echo "--------------------------------------"
    echo "---- COMMAND LINE SWITCH SETTINGS ----"
    echo "file= "$file
    echo "eps= "$eps
    echo "dbg= "$dbg
    echo "exp= "$exp " exp_typ= "$exp_typ " exp_ord= "$exp_ord
    echo "min= "$min
    echo "max= "$max
    echo "bmrn= "$bmrn
    echo "mrn= "$mrn
    echo "so= "$so
    echo "qd= "$qd
    echo "quiet= "$quiet
    echo "prb= "$prb
    echo "cub= "$cub
    echo "sev= "$sev
    echo "poly= "$poly
    echo "shiftpoly= "$shiftpoly
    echo "polymin= "$polymin
    echo "polymax= "$polymax
    echo "pausetime= "$pausetime
    echo "pseudovoigt= "$pseudovoigt
    echo "asmp= "$asmp
    echo "sprb="$sprb
    echo "setx0="$setx0
    echo "varguess= "$varguess
    echo "--------------------------------------"
    echo "--------------------------------------"
fi

if  [ $exp_typ -eq 0 ] && [ $prb -eq 0 ] && [ $qd -eq 0 ] &&\
    [ $so -eq 0 ] && [ $sprb -eq 0 ] && [ $bmrn -eq 0 ] &&\
    [ $poly -eq 0 ] && [ $asmp -eq 0 ] && [ $mrn -eq 0 ] &&\
    [ $shiftpoly -eq 0 ] && [ $pseudovoigt -eq 0 ]; then
    echo "Must set one switch for fit!"
    exit
fi

###################################################
# Functions
###################################################
function fcn_setx0 () {
    if [ "$setx0" = "-1" ]; then
	echo "x0= "$var_x0 >> gfit.par ;
    else
	echo "x0= "$var_x0 " # FIXED" >> gfit.par ;
    fi
}

function fcn_getx0 () {
    if [ "$setx0" = "-1" ]; then
	var_x0=`cat $file | $AWK -f ~/awkfiles/xy_min.awk -v getxmin=1`;
    else
	var_x0=$setx0;
    fi
}

function set_variables () {
    numvars=$(echo "$varguess" | gawk -F ":" --source '{print NF}');
    numlist=$(gawk --source 'BEGIN{for(i=1;i<NN+1;i++){printf("%d ",i);}}' -v NN=$numvars);
    if [ $dbg -eq 1 ]; then
	echo "In function 'set_variables'"
	echo "numvars= "$numvars;
	echo "numlist= "$numlist;
    fi
    for ii in $numlist; do
	varloop=$(echo "$varguess" | gawk -F ":" --source '{print $II}' -v II=$ii);
	if [ $dbg -eq 1 ]; then
	    echo "ii= $ii  setting " ${variable_list[ii]}"= "$varloop;
	fi
	echo ${variable_list[ii]}"= "$varloop >> gfit.par;
    done
}


# create gnuplot.p file
function make_gplot_file() {

    if [ $eps -eq 1 ]; then
	echo "set terminal postscript eps enhanced color solid \"$FONT\" 14" >> $gp
	echo "set output \"fit.eps\"" >> $gp
    fi
    echo "set title \"$title\" font \"$TITLEFONT,20\"" >> $gp
    echo "set xlabel \"$xlabl\" offset 0,-0.5 font \"$FONT,14\"" >> $gp
    echo "set ylabel \"$ylabl\" offset -1 font \"$FONT,14\"" >> $gp
    echo "set autoscale xfix" >> $gp
    echo "set xtics autofreq" >> $gp
    echo "FIT_LIMIT=$fit_limit" >> $gp
    echo "FIT_MAXITER=$maxiter" >> $gp
    echo "FIT_START_LAMBDA=$lambdastart" >> $gp
    echo "FIT_LAMBDA_FACTOR=$lambdafactor" >> $gp
    echo "fit [$min:$max] f(x) '$file' via 'gfit.par'" >> $gp
    echo "plot [$min:$max] f(x), '$file'" >> $gp
    if [ $eps -eq 0 ]; then
	echo "pause $pausetime" >> $gp
    fi

}


function make_awk_file() {

cat > tmp.gnufit.extract_vars.awk <<EOF

BEGIN{
    read_flag=0;
}

(\$1=="Final"){read_flag=1;}
(NF>=3 && read_flag==1 && \$2=="="){printf("%e ",\$3);}
(\$1=="correlation" && start_flag==1){read_flag=0;}

END{
    printf("\n");
}

EOF

}



###################################################################
## START SCRIPT
###################################################################

##############################
# exponential:  a0 + a1 * exp(a2 * x) + a3 * exp(a4 * x) + ...
if [ $exp_typ -eq 1 ] || [ $exp_typ -eq 2 ]; then

    # I need 2 times the order number for adding the additional variables
    exp_var_list=`echo $exp_ord | gawk --source '{for(i=1;i<2*$1+1;i++){printf("%d ",i);}}'`
    if [ $dbg -eq 1 ]; then
	echo "list= "$exp_var_list
    fi

    if [ $showvars -eq 1 ]; then
	echo "f(x) =  a0 + a1 * exp(a2 * x) + a3 * exp(a4 * x) + ..."
	echo "Variables and order are: a0 a1 a2 a3 a4 ..."
	exit
    fi
    
    variable_list[1]="a0"
    for n in $exp_var_list; do
	# Need variable_list=([1]=a0 [2]=a1 [3]=a2);
	variable_list[$((n+1))]="a$n"
    done
    
    if [ "$varguess" != "" ]; then
	set_variables;
    else
	echo "a0= 0.1" > gfit.par ;
	for n in $exp_var_list; do
	    echo "a$n= 1" >> gfit.par ;
	done
    fi

    expfcn="f(x) = a0 "
    exp_ord_list=`echo $exp_ord | gawk --source '{for(i=0;i<$1;i++){printf("%d ",i);}}'`
    for n in $exp_ord_list; do
	# tnp1 = 2n+1    and tnp2 = 2n+2
	tnp1=$(echo $n | gawk '{printf("%d",2*$1+1);}')
	tnp2=$(echo $n | gawk '{printf("%d",2*$1+2);}')
	# this will generate a1*exp(a2*x) + a3*exp(a4*x) + a5*exp(a6*x) +...
	if [ $exp_typ -eq 1 ]; then
	    expfcn=$expfcn" + a$tnp1 * exp( a$tnp2 * x )"
	elif [ $exp_typ -eq 2 ]; then
	    expfcn=$expfcn" + a$tnp1 * exp( a$tnp2 / x )"
	fi
    done
    echo "$expfcn" > $gp;

    if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for exponential type $exp_typ fit"
	echo "$expfcn"
    fi

    make_gplot_file
    
fi

##############################
# asymptotic type 1
if [ $asmp -eq 1 ]; then

    echo "a0= 1" > gfit.par ;
    polylist=`echo $order | gawk --source '{for(i=1;i<$1+1;i++){printf("%d ",i);}}'`
    if [ $dbg -eq 1 ]; then
	echo "polylist= "$polylist
    fi
    for n in $polylist; do
	echo "a$n= 1" >> gfit.par ;
    done
    echo "PE= 1" >> gfit.par ;
    echo "EX= 1" >> gfit.par ;

        if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for asymptotic type 1 fit"
    fi

    asmp_function="f(x) = a0 "
    for n in $polylist; do
	asmp_function=$asmp_function" + a$n*x**$n"
    done
    asmp_function=$asmp_function" + PE*(1-exp(-EX/x))"
    
    echo "$asmp_function" > $gp
    make_gplot_file

fi

##############################
# asymptotic type 2
if [ $asmp -eq 2 ]; then

    variable_list=([1]="FASYMP" [2]="ALPHA" [3]="TAU");
    if [ $showvars -eq 1 ]; then
	echo "Variables and order are: FASYMP ALPHA TAU"
	exit
    fi

    if [ "$varguess" != "" ]; then
	set_variables;
    else
	fasymp=$(cat $file | tail -1 | gawk '{print $2}');
	tauguess=$(cat $file | tail -1 | gawk '{print $1}');
	echo "FASYMP= $fasymp" >> gfit.par ;    
	echo "ALPHA= 0.5" >> gfit.par ;
	echo "TAU= $tauguess" >> gfit.par ;
    fi

        if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for asymptotic type 2 fit"
    fi

    x0=$(cat $file | head -1 | gawk '{print $1}');
    f0=$(cat $file | head -1 | gawk '{print $2}');
    if [ $dbg -eq 1 ]; then
	echo "x0= "$x0;
	echo "f0= "$f0;
    fi
    if [ $order -eq 1 ]; then
	asmp_function="f(x) = FASYMP - (FASYMP-$f0)*exp( -((x-$x0)/TAU)**ALPHA )"
    fi
    if [ $order -eq 2 ]; then
	asmp_function="f(x) = $f0-($f0-FASYMP)*(1-exp( -((x-$x0)/TAU)**ALPHA ))"
    fi
    
    echo "$asmp_function" > $gp
    make_gplot_file

fi

##############################
# arb poly
if [ $poly -gt 0 ]; then

    polymax=$poly;
    polylist=`awk --source 'BEGIN{for(i=MIN;i<MAX+1;i++){printf("%d ",i);}}' -v MIN=$polymin -v MAX=$polymax`
    if [ $dbg -eq 1 ]; then
	echo "polylist= "$polylist
    fi

    poly_var_list=`echo $poly | gawk --source '{for(i=1;i<$1+1;i++){printf("%d ",i);}}'`
    if [ $dbg -gt 0 ]; then
       echo "poly_var_list= "$poly_var_list;
    fi
    variable_list[1]="a0"
    for n in $poly_var_list; do
	# Need variable_list=([1]=a0 [2]=a1 [3]=a2);
	variable_list[$((n+1))]="a$n"
    done
    
    if [ "$varguess" != "" ]; then
	set_variables;
    else
	echo "a0= 1" > gfit.par ;    
	for n in $polylist; do
	    echo "a$n= 1" >> gfit.par ;
	done
    fi

        if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for arb order poly"
    fi

    polynomial="f(x) = a0 ";
    for n in $polylist; do
	polynomial=$polynomial" + a$n*x**$n"
    done

    if [ $dbg -eq 1 ]; then
	echo "polynomial= "$polynomial
    fi

    echo "$polynomial" > $gp
    make_gplot_file
    
fi

##############################
# shifted arb poly
if [ $shiftpoly -gt 0 ]; then
    echo "a0= 1" > gfit.par ;
    fcn_getx0;
    polymax=$shiftpoly;
    echo "polymin= "$polymin
    echo "polymax= "$polymax
    polylist=`awk -v MIN=$polymin -v MAX=$polymax --source 'BEGIN{for(i=MIN;i<MAX+1;i++){printf("%d ",i);}}'`
    if [ $dbg -eq 1 ]; then
	echo "polylist= "$polylist
    fi
    fcn_setx0;
    for n in $polylist; do
	echo "a$n= 1" >> gfit.par ;
    done

        if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for shifted arb order poly"
    fi

    polynomial="f(x) = a0 ";
    for n in $polylist; do
	polynomial=$polynomial" + a$n*(x-x0)**$n"
    done

    if [ $dbg -eq 1 ]; then
	echo "polynomial= "$polynomial
    fi

    echo "$polynomial" > $gp
    make_gplot_file

fi

##############################
# simple parabola
if [ $prb -eq 1 ]; then
    var_x0=`cat $file | $AWK -f ~/awkfiles/xy_min.awk -v getxmin=1`;
    var_a=`cat $file | $AWK -f ~/awkfiles/xy_min.awk -v getymin=1`;
    echo "x0= "$var_x0
    echo "ymin= "$y_min
    var_c=1;

    echo "a= "$var_a > gfit.par ;
    echo "c= "$var_c >> gfit.par ;

    if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for simple parabola"
    fi
    
    echo "f(x) = a+c*x**2" > $gp
    make_gplot_file
    
fi

##############################
# shifted simple parabola
if [ $sprb -eq 1 ]; then
    fcn_getx0;
    var_a=`cat $file | $AWK -f ~/awkfiles/xy_min.awk -v getymin=1`;
    echo "x0= "$var_x0
    echo "var_a= "$var_a " (y_min)"
    var_c=1;

    echo "a= "$var_a > gfit.par ;
    echo "c= "$var_c >> gfit.par ;
    fcn_setx0;

    if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for shifted simple parabola"
    fi
    
    echo "f(x) = a+c*(x-x0)**2" > $gp
    make_gplot_file
    
fi

##############################
# simple second order quadratic
if [ $so -eq 1 ]; then
    x_min=`cat $file | $AWK -f ~/awkfiles/xy_min.awk -v getxmin=1`;
    y_min=`cat $file | $AWK -f ~/awkfiles/xy_min.awk -v getymin=1`;
    echo "xmin= "$x_min
    echo "ymin= "$y_min
    var_b=`echo $x_min | $AWK '(NF==1){printf("%.10f",-2.0*$1);}'`;
    var_a=`echo $x_min $y_min | $AWK '(NF==2){printf("%.10f",$1*$1+$2);}'`;
    var_c=1;

    echo "a= "$var_a > gfit.par ;
    echo "b= "$var_b >> gfit.par ;
    echo "c= "$var_c >> gfit.par ;

    if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for second order polynomial"
    fi
    
    echo "f(x) = a+b*x+c*x**2" > $gp
    make_gplot_file
    
fi

##############################
# shifted quadratic
if [ $qd -eq 1 ]; then
    fcn_getx0;
    var_a=`cat $file | $AWK -f ~/awkfiles/xy_min.awk -v getymin=1`;
    echo "x0= "$var_x0
    echo "var_a= "$var_a " (y_min)"
    var_b=1;
    var_c=1;

    echo "a= "$var_a > gfit.par ;
    echo "b= "$var_b >> gfit.par ;
    echo "c= "$var_c >> gfit.par ;
    fcn_setx0;

    if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for shifted quadratic fit"
    fi
    
    echo "f(x) = a+b*(x-x0)+c*(x-x0)**2" > $gp
    make_gplot_file
    
fi

##############################
# Murnaghan equation of state fit
if [ $mrn -eq 1 ] || [ $bmrn -eq 1 ]; then
    var_E0=`cat $file | $AWK -f ~/awkfiles/xy_min.awk -v getymin=1`;
    var_V0=`cat $file | $AWK -f ~/awkfiles/xy_min.awk -v getxmin=1`;
    var_b=10;
    var_bp=10;

    echo "E0= "$var_E0 > gfit.par ;
    echo "V0= "$var_V0 >> gfit.par ;
    echo "b= "$var_b >> gfit.par ;
    echo "bp= "$var_bp >> gfit.par ;

    if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for Murnaghan fit"
    fi

    # echo "f(x) = E0 + (b*x/bp)*((((V0/x)**bp)/(bp-1))+1) - V0*b/(bp-1)" > $gp
    # Below will give B in GPa
    eVpA3_to_GPa=160.21765;
    bn="(b/$eVpA3_to_GPa)";
    if [ $mrn -eq 1 ]; then
	echo "f(x) = E0 + ($bn*x/bp)*((((V0/x)**bp)/(bp-1))+1) - V0*$bn/(bp-1)" > $gp
    elif [ $bmrn -eq 1 ]; then
	prefact="( ( 9.0 * V0 * $bn ) / 16.0 )";
	trmV="( (V0/x)**(0.66666666666666667) )";
	trmV1="( $trmV - 1 )";
	trmV2="( 6.0 - 4.0*$trmV )";
	echo "f(x) = E0 + $prefact * ( $trmV1**3 * bp + $trmV1**2 * $trmV2 )" > $gp
    fi
    make_gplot_file
    
fi

##############################
# pseudo-voigt
if [ $pseudovoigt -eq 1 ]; then
    variable_list=([1]="X0" [2]="AMPLITUDE" [3]="ETA" [4]="HWIDTH" [5]="BASELINE");
    if [ $showvars -eq 1 ]; then
	echo "Variables and order are: X0 AMPLITUDE ETA HWIDTH BASELINE"
	exit
    fi
    if [ "$varguess" != "" ]; then
	set_variables;
    else
	x0=$(cat $file | gawk --source 'BEGIN{maxy=-1e9}($1>minx && $1<maxx){if($2>maxy){maxy=$2;cent=$1}}END{print cent}' -v minx=$min -v maxx=$max);
	amplitude=$(cat $file | gawk --source 'BEGIN{maxy=-1e9}($1>minx && $1<maxx){if($2>maxy){maxy=$2}}END{print maxy}' -v minx=$min -v maxx=$max);
	eta=0.1;
	hwidth=$(gawk --source 'BEGIN{print (A-B)/10}' -v A=$max -v B=$min);
	baseline=$(cat $file | tail -1 | gawk '{print $2}');
	echo "X0= $x0">> gfit.par;
	echo "AMPLITUDE= $amplitude" >> gfit.par;
	echo "ETA= $eta">> gfit.par;
	echo "HWIDTH= $hwidth" >> gfit.par;
	echo "BASELINE= $baseline" >> gfit.par;
    fi

    if [ $quiet -eq 0 ]; then
	echo "##########################################"
	echo " Creating gnuplot.p file for pseudovoigt fit"
    fi
    pv_func="f(x) = BASELINE + AMPLITUDE * ( ETA*( 1 / ( 1 + ( (x-X0)/HWIDTH )**2 ) ) + (1-ETA)*( exp( -log(2)*((x-X0)/HWIDTH)**2  ) ) )"
    echo "$pv_func" > $gp
    make_gplot_file
    
fi



###################################################################
###################################################################

########################################
# RUN GNUPLOT
########################################
if [ $quiet -eq 0 ]; then
    $GNUPLOT < $gp | tee tmp.gnufit.gnuplot_run.out
elif [ $quiet -eq 1 ]; then
    $GNUPLOT < $gp >& tmp.gnufit.gnuplot_run.out;
    make_awk_file;
    $CAT tmp.gnufit.gnuplot_run.out | $AWK -f tmp.gnufit.extract_vars.awk 
fi

if [ $jpeg_out -eq 1 ]; then
    echo "Generating jpeg output... "
    CONV_OPTS="-density 300 -quality 99"
    convert $CONV_OPTS fit.eps fit.jpg
fi

# clean up files if no debug
if [ $dbg -eq 0 ]; then
    rm -f gfit.par fit.log gnuplot.p tmp.gnufit.gnuplot_run.out tmp.gnufit.extract_vars.awk
    if [ $jpeg_out -eq 1 ] || [ $quiet -eq 1 ]; then
	rm -f fit.eps tmp.gnufit.gnuplot_run.out
    fi
fi

exit



