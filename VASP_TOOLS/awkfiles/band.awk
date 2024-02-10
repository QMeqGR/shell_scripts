#  BAND.AWK
#
# Use for VASP:
#       cat EIGENVAL | gawk -f band.awk -v vasp=1 -v n=25 -v explicit=0
#
#       explicit = 1 : indicates explicit (zero weight) kpoints
#                      probably from a hybrid HF band structure
#       n = number of points from one high sym point to the next
#           (this draws a vertical line on the plot)
#       H = height of vertical lines, spaced every 'n' points
#           (default is 10)
#       Ef = E-fermi from SCF run
#            If you set this, it will shift E-fermi to zero.
#
#
# version 1.2, 09 Feb 2016
# version 1.1, 18 Oct 2015
# 
# 
# E. Majzoub
# University of Missouri - St. Louis
#
# Works with ABINIT or VASP output
# Specify -v vasp=1 or -v abinit=1
#


# Takes output of ABINIT and makes data file for band structure
# viewing with xmgrace.
BEGIN{
    version=1.2;
    
    MAX=1000;
    POINTMAX=10000;
    kpt=0;
    if ( !H ) { H=10; }
    
    # VASP variables
    skip=6; # skip first 6 header lines
    kpoint[MAX];
    nband=0; # get nband from header line 6
    band[POINTMAX];
    band_count=0;
    
    # ABINIT variables
    newkpt=0;
    lineno=0;
    nfields=0;

    if ( !vasp && !abinit ) {
	printf("need to set vasp=1 or abinit=1\n");
	exit;
    }
    printf("# band.awk v %.1f, n=%d  Ef=%f  explicit= %d\n",version,n,Ef,explicit);
}
#####################################

(vasp==1 && NR==6){ nband=$3; }
(vasp==1 && NF==4 && NR>skip){
    kpt++;
    kpoint_x[kpt]=$1;    kpoint_y[kpt]=$2;    kpoint_z[kpt]=$3;
    if ( explicit == 1 && $4 == 0.0 ) { read_bands=1; }
    if ( explicit == 0 && $4 >  0.0 ) { read_bands=1; }
}
(vasp==1 && read_bands==1 && band_count<(nband+1) && NF==3 ){
    band_count++;
    band[nband*kpt + band_count]=$2 - Ef;
    if ( debug ) {printf("reading kpt= %d band= %d  en= %f\n",kpt,band_count,$2);}
    if ( band_count == nband ){band_count=0; read_bands=0;}
}

###################################
(abinit==1 && $1 ~ /kpt/){
  if (lineno<NR) printf("\n");
  kpt++;
  printf("%d.",kpt);
}
(abinit==1 && $1 !~ /kpt/ ){
  for(i=0; i<NF; i++) printf("%f ",$i);
  lineno=NR;
}

END{

    if ( vasp == 1 ){
	if ( debug == 1 ){
	    printf("nband= %d\n",nband);
	    printf("kpt= %d\n",kpt-1);
	}
	for(j=1;j<nband+1;j++){
	    if ( j > 1 ){printf("&\n");}
	    for(i=1;i<kpt+1;i++){
		printf("%d %f\n",i,band[nband*i+j]);
	    }
	}
	# make the vertical lines
	if ( n ) {
	    nlines=kpt/n;
	    if ( debug ==1 ) printf("nlines= %d\n",nlines);
	    printf("&\n");
	    printf("%d %d\n",1,-H);
	    printf("%d %d\n",1, H);
	    for (i=1;i<nlines+1;i++){
		printf("&\n");
		printf("%d %d\n",n*i,-H);
		printf("%d %d\n",n*i, H);
	    }
	}
	if ( Ef ) {
	    printf("&\n");
	    printf("0 0\n");
	    printf("%d 0\n",n*nlines);
	}
    }
    
}
