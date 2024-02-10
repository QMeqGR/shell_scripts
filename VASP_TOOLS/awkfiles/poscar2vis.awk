BEGIN{
# E. Majzoub, SNL/CA oct 2005

# use -v XBS=1 for xbs output [ -v BONDS=1 will make bonds for all NN atoms ]
# use -v FRM=1 for xbsa frame output to mv file
# use -v DXL=1 for DrawXtl output
# use -V XMK=1 for Xmakemol output

# BP    -- percentage of bond length
# DUP   -- use duplicate cells
# use -v CONV=1 for conventional cell output in xbsa

  SCRIPT_NAME="poscar2vis.awk";
  SCRIPT_VERSION=1.4;

# Notes:
#
# version 1.4, 06 Mar 2009
# -add FRM option to print out only the atom positions for xbsa frame file
# version 1.3, 12 Feb 2009
# -changed one line to make this work with "Selective dynamics"
#  input files... NF>2 in the selection of atoms below.
#
# version 1.2, 08 May 2007
# -added cell boundary and conventional cell code for xbsa
#
# version 1.1, 13 October 2006
# -added bonds for xbsa output


  CONVFMT="%.12g";
# constants
  PI = 4.0*atan2(1.0,1.0);
  D2R = PI/180.0;
  R2D = 180.0/PI;

# xbs related stuff
  rad=0.5;
  BOND_WIDTH=0.025;


  HI = 1.001;
  LO = 0.999;
  CORNER_RAD = 0.08; # must be >= FRM_RAD
  FRM_RAD = 0.07;
  FRM_CLR = "Gray";
  n1[4];n2[4];n3[4];

  c0[4];
  c1[4];
  c2[4];
  c3[4];
  c4[4];
  c5[4];
  c6[4];
  c7[4];

# DrawXtl related stuff
  alph=0.0;
  beta=0.0;
  gamm=0.0;
  r1mg=0.0;
  r2mg=0.0;
  r3mg=0.0;

  p[3000];     # holds atom positions
  Z_at[1000];  # holds atom Z
  nat=0;
  count=0;
}

############################################
#  FUNCTIONS
############################################

function print_spe_xbs(c,R,r,g,b)
{
  
  printf("spec %c %10.4lf%10.4lf%10.4lf%10.4lf\n",c,R,r,g,b);

  return;
}

function print_bnd_xbs(ch1,ch2,m,M,R)
{

  printf("bonds %c %c %12.5lf%15.5lf%15.5lf    %s\n",ch1,ch2,m,M,R,FRM_CLR);

  return;
}


function ztorad_xbs( z ) {

  if ( z==1   ) return( 1.25 );
  if ( z==2   ) return( 0.25 );
  if ( z==3   ) return( 0.68 );
  if ( z==4   ) return( 0.80 );
  if ( z==5   ) return( 0.23 );
  if ( z==6   ) return( 0.77 );
  if ( z==7   ) return( 0.70 );
  if ( z==8   ) return( 0.66 );
  if ( z==9   ) return( 0.64 );
  if ( z==10  ) return( 1.58 );
  if ( z==11  ) return( 0.97 );
  if ( z==12  ) return( 0.65 );
  if ( z==13  ) return( 0.50 );
  if ( z==14  ) return( 0.41 );
  if ( z==15  ) return( 1.12 );
  if ( z==16  ) return( 1.84 );
  if ( z==17  ) return( 1.81 );
  if ( z==18  ) return( 1.88 );
  if ( z==19  ) return( 1.33 );
  if ( z==20  ) return( 0.99 );
  if ( z==21  ) return( 0.81 );
  if ( z==22  ) return( 0.68 );
  if ( z==23  ) return( 1.35 );
  if ( z==24  ) return( 1.28 );
  if ( z==25  ) return( 1.26 );
  if ( z==26  ) return( 1.27 );
  if ( z==27  ) return( 1.25 );
  if ( z==28  ) return( 1.25 );
  if ( z==29  ) return( 1.28 );
  if ( z==30  ) return( 1.39 );
  if ( z==31  ) return( 0.62 );
  if ( z==32  ) return( 0.53 );
  if ( z==33  ) return( 2.22 );
  if ( z==34  ) return( 1.98 );
  if ( z==35  ) return( 1.95 );
  if ( z==36  ) return( 2.00 );
  if ( z==37  ) return( 1.48 );
  if ( z==38  ) return( 1.13 );
  if ( z==39  ) return( 0.93 );
  if ( z==40  ) return( 0.80 );
  if ( z==41  ) return( 0.67 );
  if ( z==42  ) return( 1.40 );
  if ( z==43  ) return( 1.36 );
  if ( z==44  ) return( 1.34 );
  if ( z==45  ) return( 1.35 );
  if ( z==46  ) return( 1.38 );
  if ( z==47  ) return( 1.26 );
  if ( z==48  ) return( 0.97 );
  if ( z==49  ) return( 0.81 );
  if ( z==50  ) return( 0.71 );
  if ( z==51  ) return( 2.45 );
  if ( z==52  ) return( 2.21 );
  if ( z==53  ) return( 2.16 );
  if ( z==54  ) return( 2.17 );
  if ( z==55  ) return( 1.67 );
  if ( z==56  ) return( 1.35 );
  if ( z==57  ) return( 1.15 );
  if ( z==58  ) return( 1.82 );
  if ( z==59  ) return( 1.83 );
  if ( z==60  ) return( 1.82 );
  if ( z==61  ) return( 1.81 );
  if ( z==62  ) return( 1.80 );
  if ( z==63  ) return( 1.80 );
  if ( z==64  ) return( 1.80 );
  if ( z==65  ) return( 1.78 );
  if ( z==66  ) return( 1.77 );
  if ( z==67  ) return( 1.77 );
  if ( z==68  ) return( 1.76 );
  if ( z==69  ) return( 1.75 );
  if ( z==70  ) return( 1.74 );
  if ( z==71  ) return( 0.50 );
  if ( z==72  ) return( 1.58 );
  if ( z==73  ) return( 1.47 );
  if ( z==74  ) return( 1.41 );
  if ( z==75  ) return( 1.38 );
  if ( z==76  ) return( 1.35 );
  if ( z==77  ) return( 1.36 );
  if ( z==78  ) return( 1.39 );
  if ( z==79  ) return( 1.44 );
  if ( z==80  ) return( 1.57 );
  if ( z==81  ) return( 1.72 );
  if ( z==82  ) return( 1.75 );
  if ( z==83  ) return( 1.70 );
  if ( z==84  ) return( 1.76 );
  if ( z==85  ) return( 0.50 );
  if ( z==86  ) return( 0.50 );
  if ( z==87  ) return( 0.50 );
  if ( z==88  ) return( 0.50 );
  if ( z==89  ) return( 0.50 );
  if ( z==90  ) return( 0.50 );
  if ( z==91  ) return( 0.50 );
  if ( z==92  ) return( 0.50 );
  if ( z==93  ) return( 0.50 );
  if ( z==94  ) return( 0.50 );
  if ( z==95  ) return( 0.50 );
  if ( z==96  ) return( 0.50 );
  if ( z==97  ) return( 0.50 );
  if ( z==98  ) return( 0.50 );
  if ( z==99  ) return( 0.50 );
  if ( z==100 ) return( 0.50 );
  if ( z==101 ) return( 0.50 );
  if ( z==102 ) return( 0.50 );
  if ( z==103 ) return( 0.50 );

}

function ztoelm( z ) {
  if ( z==1   ) return( "H"  );
  if ( z==2   ) return( "He" );
  if ( z==3   ) return( "Li" );
  if ( z==4   ) return( "Be" );
  if ( z==5   ) return( "B"  );
  if ( z==6   ) return( "C"  );
  if ( z==7   ) return( "N"  );
  if ( z==8   ) return( "O"  );
  if ( z==9   ) return( "F"  );
  if ( z==10  ) return( "Ne" );
  if ( z==11  ) return( "Na" );
  if ( z==12  ) return( "Mg" );
  if ( z==13  ) return( "Al" );
  if ( z==14  ) return( "Si" );
  if ( z==15  ) return( "P"  );
  if ( z==16  ) return( "S"  );
  if ( z==17  ) return( "Cl" );
  if ( z==18  ) return( "Ar" );
  if ( z==19  ) return( "K"  );
  if ( z==20  ) return( "Ca" );
  if ( z==21  ) return( "Sc" );
  if ( z==22  ) return( "Ti" );
  if ( z==23  ) return( "V"  );
  if ( z==24  ) return( "Cr" );
  if ( z==25  ) return( "Mn" );
  if ( z==26  ) return( "Fe" );
  if ( z==27  ) return( "Co" );
  if ( z==28  ) return( "Ni" );
  if ( z==29  ) return( "Cu" );
  if ( z==30  ) return( "Zn" );
  if ( z==31  ) return( "Ga" );
  if ( z==32  ) return( "Ge" );
  if ( z==33  ) return( "As" );
  if ( z==34  ) return( "Se" );
  if ( z==35  ) return( "Br" );
  if ( z==36  ) return( "Kr" );
  if ( z==37  ) return( "Rb" );
  if ( z==38  ) return( "Sr" );
  if ( z==39  ) return( "Y"  );
  if ( z==40  ) return( "Zr" );
  if ( z==41  ) return( "Nb" );
  if ( z==42  ) return( "Mo" );
  if ( z==43  ) return( "Tc" );
  if ( z==44  ) return( "Ru" );
  if ( z==45  ) return( "Rh" );
  if ( z==46  ) return( "Pd" );
  if ( z==47  ) return( "Ag" );
  if ( z==48  ) return( "Cd" );
  if ( z==49  ) return( "In" );
  if ( z==50  ) return( "Sn" );
  if ( z==51  ) return( "Sb" );
  if ( z==52  ) return( "Te" );
  if ( z==53  ) return( "I"  );
  if ( z==54  ) return( "Xe" );
  if ( z==55  ) return( "Cs" );
  if ( z==56  ) return( "Ba" );
  if ( z==57  ) return( "La" );
  if ( z==58  ) return( "Ce" );
  if ( z==59  ) return( "Pr" );
  if ( z==60  ) return( "Nd" );
  if ( z==61  ) return( "Pm" );
  if ( z==62  ) return( "Sm" );
  if ( z==63  ) return( "Eu" );
  if ( z==64  ) return( "Gd" );
  if ( z==65  ) return( "Tb" );
  if ( z==66  ) return( "Dy" );
  if ( z==67  ) return( "Ho" );
  if ( z==68  ) return( "Er" );
  if ( z==69  ) return( "Tm" );
  if ( z==70  ) return( "Yb" );
  if ( z==71  ) return( "Lu" );
  if ( z==72  ) return( "Hf" );
  if ( z==73  ) return( "Ta" );
  if ( z==74  ) return( "W"  );
  if ( z==75  ) return( "Re" );
  if ( z==76  ) return( "Os" );
  if ( z==77  ) return( "Ir" );
  if ( z==78  ) return( "Pt" );
  if ( z==79  ) return( "Au" );
  if ( z==80  ) return( "Hg" );
  if ( z==81  ) return( "Tl" );
  if ( z==82  ) return( "Pb" );
  if ( z==83  ) return( "Bi" );
  if ( z==84  ) return( "Po" );
  if ( z==85  ) return( "At" );
  if ( z==86  ) return( "Rn" );
  if ( z==87  ) return( "Fr" );
  if ( z==88  ) return( "Ra" );
  if ( z==89  ) return( "Ac" );
  if ( z==90  ) return( "Th" );
  if ( z==91  ) return( "Pa" );
  if ( z==92  ) return( "U " );
  if ( z==93  ) return( "Np" );
  if ( z==94  ) return( "Pu" );
  if ( z==95  ) return( "Am" );
  if ( z==96  ) return( "Cm" );
  if ( z==97  ) return( "Bk" );
  if ( z==98  ) return( "Cf" );
  if ( z==99  ) return( "Es" );
  if ( z==100 ) return( "Fm" );
  if ( z==101 ) return( "Md" );
  if ( z==102 ) return( "No" );
  if ( z==103 ) return( "Lr" );
}

###############################################################
###############################################################
# note: this is coded to work with the output of
# icsd2poscar.awk, in which
# the first line should read: "Z: Z1 Z2 Z3 ..."
(NR==1){ for(i=2;i<NF+1;i++) { elem[i-1]=$i; ntyp=(i-1); } }

# if I change the first line of output back to
# Ca B H
# i.e., without the 'Z:' then this line works
# and looks cleaner and is easier to read
# (NR==1){ for(i=2;i<NF+1;i++) { elem[i]=$i; ntyp=i); } }

(NR==2){ scalefact=$1; }
(NR==3){ for(i=1;i<4;i++) { r1[i]=$i*scalefact; } }
(NR==4){ for(i=1;i<4;i++) { r2[i]=$i*scalefact; } }
(NR==5){ for(i=1;i<4;i++) { r3[i]=$i*scalefact; } }
(NR==6){ for(i=1;i<NF+1;i++) { numtyp[i]=$i; nat+=$i; } }
(NR>6 && NF>2) {
  p[3*count+0]=$1;
  p[3*count+1]=$2;
  p[3*count+2]=$3;
  count++;
}

END{
# these variables are null by default unless set
# and won't work as !XBS for example, unless you
# explicitly set them

  if (XBS) { DXL=0; FRM=0; }
  if (DXL) { XBS=0; FRM=0; }
  if (FRM) { DXL=0; XBS=0; }

# calculate angles
  r1mg = sqrt( r1[1]*r1[1] + r1[2]*r1[2] + r1[3]*r1[3] );
  r2mg = sqrt( r2[1]*r2[1] + r2[2]*r2[2] + r2[3]*r2[3] );
  r3mg = sqrt( r3[1]*r3[1] + r3[2]*r3[2] + r3[3]*r3[3] );
  
  r1d2 = r1[1]*r2[1] + r1[2]*r2[2] + r1[3]*r2[3];
  r1d3 = r1[1]*r3[1] + r1[2]*r3[2] + r1[3]*r3[3];
  r2d3 = r2[1]*r3[1] + r2[2]*r3[2] + r2[3]*r3[3];
  
  cost12 = r1d2 / (r1mg*r2mg);
  sint12 = sqrt( 1.0 - cost12*cost12 );
  t12 = atan2(sint12,cost12);
  
  cost13 = r1d3 / (r1mg*r3mg);
  sint13 = sqrt( 1.0 - cost13*cost13 );
  t13 = atan2(sint13,cost13);
  
  cost23 = r2d3 / (r2mg*r3mg);
  sint23 = sqrt( 1.0 - cost23*cost23 );
  t23 = atan2(sint23,cost23);
  
  alph = R2D * t23;
  beta = R2D * t13;
  gamm = R2D * t12;
  
  

# debug printing
  if ( debug>0 ){
    printf("Read %d rows\n",count);
    printf("nat= %d (total number of atoms)\n",nat);
    printf("ntyp = %d (number of types of atoms)\n",ntyp);
    printf("Number of each of the different types:\n");
    for(i=1;i<ntyp+1;i++){
      printf("numtyp[%d] = %d     elem[%d] = %d\n",i,numtyp[i],i,elem[i]);
    }
  }

# figure out the Z for each type of atom
  t_count=1;
  running_total=0;
  for(i=0;i<nat;i++){
    if ( debug>1 ) printf("i=%d  t_count=%d  numtyp[]=%d elem[]=%d\n",i,t_count,numtyp[t_count],elem[t_count]);
    if ( i < numtyp[t_count]+running_total ) Z_at[i] = elem[t_count];
    if ( i == numtyp[t_count]+running_total ) {
      if ( debug>2 ) printf("* incrementing t_count\n");
      running_total += numtyp[t_count];
      t_count++;
      Z_at[i] = elem[t_count];
    }
    if ( debug>0 ) printf("Z_at[%d] = %d\n",i,Z_at[i]);
  }


##################
#  DRAWxtl output
##################
  if (DXL){

    printf("title xbsa2drawxtl\n");
    printf("vrml2\n");
    printf("nolabels\n");
    printf("spgp P 1 1 1\n");
    printf("cell %10.4f%10.4f%10.4f%10.4f%10.4f%10.4f\n",r1mg,r2mg,r3mg,alph,beta,gamm);
    
    count=0;
    for(j=1;j<ntyp+1;j++) {
      z=elem[j];
      elm=ztoelm( z );
      for(i=0;i<numtyp[j];i++){
	at=count;
	printf("atom %5s%5d%15.10f%15.10f%15.10f\n",elm,i+1,p[3*at+0],p[3*at+1],p[3*at+2]);
	count++;
      }
    }
    for(j=1;j<ntyp+1;j++) {
      z=elem[j];
      elm=ztoelm( z );
      sprad = -1;

      if (elm == "H"){spcol="BakersChoc"; sprad=0.6;}
      if (elm == "B"){spcol="DarkSlateGrey"; sprad=0.81;}
      if (elm == "Cu"){spcol="DarkSlateGrey"; sprad=1.0;}
      if (elm == "N"){spcol="DarkSlateGrey"; sprad=0.65;}
      if (elm == "O"){spcol="DarkSlateGrey"; sprad=0.65;}
      if (elm == "Al"){spcol="DarkSlateGrey"; sprad=1.0;}
      if (elm == "Si"){spcol="DarkSlateGrey"; sprad=1.0;}
      if (elm == "Ti"){spcol="Gold"; sprad=1.0;}
      if (elm == "Au"){spcol="Gold"; sprad=1.0;}

      if (elm == "Li"){spcol="Copper"; sprad=0.9;}
      if (elm == "Na"){spcol="Copper"; sprad=0.9;}
      if (elm == "Cl"){spcol="Red"; sprad=0.9;}
      if (elm == "Mg"){spcol="Copper"; sprad=0.8;}
      if (elm == "Ca"){spcol="DustyRose"; sprad=1.12;}
      if (elm == "K"){spcol="DustyRose"; sprad=1.52;}
      if (elm == "Pd"){spcol="DustyRose"; sprad=1.52;}

      if ( sprad == -1 ) {
	printf("rem :: WARN: in script %s\n",SCRIPT_NAMEq);
	printf("rem :: DXL output: element --> %s  not found!\n",elm);
	printf("rem :: using default color (Red) and radius (0.5) \n");
	spcol="Red"; sprad=0.5;
      }
      printf("sphere %-5s%6.3f %-25s\n",elm,sprad,spcol);
    }
    

    printf("box 0.020 Black\n");
    printf("edges 0.020 Black\n");
    printf("axislines 0.00 white\n");
    printf("phong 0.60 150.0\n");
    printf("list 5\n");
    printf("end\n");    
    exit;
  }

#########################
# XMakeMol output
#########################
  if ( XMK ) {
    printf("%d\n",nat);
    printf("comment line\n");
    count=0;
    for(j=1;j<ntyp+1;j++) {
      z=elem[j];
      elm=ztoelm( z );
      for(i=0;i<numtyp[j];i++){
	at=count;
	printf("%5s%15.8f%15.8f%15.8f\n",elm,p[3*at+0],p[3*at+1],p[3*at+2]);
	count++;
      }
    }
    exit;
  }

##################
#  FRM output
##################

  if ( FRM ){

    count=0;
    printf("frame\n");
    for(j=1;j<ntyp+1;j++) {
      z=elem[j];
      elm=ztoelm( z );
      for(i=0;i<numtyp[j];i++){
	at=count;
	for (k=1; k<4; k++){
	  cart_vec[k] = p[3*at+0]*r1[k]+p[3*at+1]*r2[k]+p[3*at+2]*r3[k];
	}

	printf("%20.15f%20.15f%20.15f ",cart_vec[1],cart_vec[2],cart_vec[3]);
	count++;
      }
      printf("\n");
    }

  }

#########################
# XBSA output
#########################

  if ( XBS ) {

    printf("*\n");
    printf("* XBS output generated from %s, version %s\n",SCRIPT_NAME,SCRIPT_VERSION);
    printf("*\n");

    count=0;
    for(j=1;j<ntyp+1;j++) {
      z=elem[j];
      elm=ztoelm( z );
      for(i=0;i<numtyp[j];i++){
	at=count;
	for (k=1; k<4; k++){
	  cart_vec[k] = p[3*at+0]*r1[k]+p[3*at+1]*r2[k]+p[3*at+2]*r3[k];
	}
	if (XBS) printf("atom ");
	printf("%5s%20.15f%20.15f%20.15f\n",elm,cart_vec[1],cart_vec[2],cart_vec[3]);
	count++;
      }
    }
    
    for(j=1;j<ntyp+1;j++) {
      z=elem[j];
      elm=ztoelm( z );
      rad=ztorad_xbs( z );
      R=rand(); G=rand(); B=rand();
      printf("spec %5s %8.3f%5.2f%5.2f%5.2f\n",elm,rad,R,G,B);
    }

    if ( BONDS ){
      for(j=1;j<ntyp+1;j++) {

	z=elem[j];
	elm=ztoelm( z );

	for(j2=1;j2<j;j2++) {
	  z2=elem[j2];
	  if ( z == z2 ) continue;
	  elm2=ztoelm( z2 );

	  # find nearest neighbor distances
	  MIN_NN=1e10;
	  for(a1=0;a1<nat;a1++){
	    if ( Z_at[a1] != z ) continue;
	    for (k=1; k<4; k++){
	      cart_vec1[k] = p[3*a1+0]*r1[k]+p[3*a1+1]*r2[k]+p[3*a1+2]*r3[k];
	    }
	    X1=cart_vec1[1]; Y1=cart_vec1[2]; Z1=cart_vec1[3];
	    for(a2=0;a2<nat;a2++){
	      if ( Z_at[a2] != z2 ) continue;
	      if ( a1==a2 ) continue;
	      if ( Z_at[a1] == Z_at[a2] ) continue;
	      for (k=1; k<4; k++){
		cart_vec2[k] = p[3*a2+0]*r1[k]+p[3*a2+1]*r2[k]+p[3*a2+2]*r3[k];
	      }
	      X2=cart_vec2[1]; Y2=cart_vec2[2]; Z2=cart_vec2[3];
	      D=sqrt( (X1-X2)*(X1-X2) + (Y1-Y2)*(Y1-Y2) + (Z1-Z2)*(Z1-Z2) );
	      if ( D<MIN_NN ) MIN_NN=D;
	    }
	  }

	  # make the bond allowance 10% of the minimum distance
	  if ( ! BP ){
	    printf("Set bond length percentage for bond ranges\n");
	    printf("use -v BP=0.1 (for +/- 10% of bond length)\n");
	    exit;
	  }
	  BA=MIN_NN*BP;
	  if ( debug>0 ) {
	    printf("MIN_NN = %f\n",MIN_NN);
	    printf("BA (bond allowance) = %f\n",BA);
	  }
	  printf("bonds %6s%6s%10.5f%10.5f%8.2f Black\n",elm,elm2,MIN_NN-BA,MIN_NN+BA,BOND_WIDTH);
	}
      }

    }


    if ( DUP == 1 ){
      printf("dup %20.10lf%20.10lf%20.10lf\n",r1[1],r1[2],r1[3]);
      printf("dup %20.10lf%20.10lf%20.10lf\n",r2[1],r2[2],r2[3]);
      printf("dup %20.10lf%20.10lf%20.10lf\n",r3[1],r3[2],r3[3]);
    }

    if ( CONV == 1 ){

      # cut the cell to the conventional dimensions
      for(i=1;i<4;i++){
	n1[i] = r1[i]/r1mg;
	n2[i] = r2[i]/r2mg;
	n3[i] = r3[i]/r3mg;
      }
      printf("cut %10.5f%10.5f%10.5f%10.5f%10.5f\n",n1[1],n1[2],n1[3],0.0,r1mg);
      printf("cut %10.5f%10.5f%10.5f%10.5f%10.5f\n",n2[1],n2[2],n2[3],0.0,r2mg);
      printf("cut %10.5f%10.5f%10.5f%10.5f%10.5f\n",n3[1],n3[2],n3[3],0.0,r3mg);

      for(i=1;i<4;i++){
	c0[i] = 0.0;
	c1[i] = r1[i];
	c2[i] = r1[i]+r2[i];
	c3[i] = r2[i];
	c4[i] = r3[i];
	c5[i] = r1[i]+r3[i];
	c6[i] = r1[i]+r2[i]+r3[i];
	c7[i] = r2[i]+r3[i];
      }

      printf("* CELL PARAMETERS AND BORDER\n");
      printf("atom 0 %10.5f%10.5f%10.5f\n",c0[1],c0[2],c0[3]);
      printf("atom 1 %10.5f%10.5f%10.5f\n",c1[1],c1[2],c1[3]);
      printf("atom 2 %10.5f%10.5f%10.5f\n",c2[1],c2[2],c2[3]);
      printf("atom 3 %10.5f%10.5f%10.5f\n",c3[1],c3[2],c3[3]);
      
      printf("atom 4 %10.5f%10.5f%10.5f\n",c4[1],c4[2],c4[3]);
      printf("atom 5 %10.5f%10.5f%10.5f\n",c5[1],c5[2],c5[3]);
      printf("atom 6 %10.5f%10.5f%10.5f\n",c6[1],c6[2],c6[3]);
      printf("atom 7 %10.5f%10.5f%10.5f\n",c7[1],c7[2],c7[3]);
      
      print_spe_xbs("0",CORNER_RAD,0.0,0.0,0.0);
      print_spe_xbs("1",CORNER_RAD,0.0,0.0,0.0);
      print_spe_xbs("2",CORNER_RAD,0.0,0.0,0.0);
      print_spe_xbs("3",CORNER_RAD,0.0,0.0,0.0);
      
      print_spe_xbs("4",CORNER_RAD,0.0,0.0,0.0);
      print_spe_xbs("5",CORNER_RAD,0.0,0.0,0.0);
      print_spe_xbs("6",CORNER_RAD,0.0,0.0,0.0);
      print_spe_xbs("7",CORNER_RAD,0.0,0.0,0.0);
      
      print_bnd_xbs("0","1",r1mg*LO,r1mg*HI,FRM_RAD);
      print_bnd_xbs("3","2",r1mg*LO,r1mg*HI,FRM_RAD);
      print_bnd_xbs("4","5",r1mg*LO,r1mg*HI,FRM_RAD);
      print_bnd_xbs("6","7",r1mg*LO,r1mg*HI,FRM_RAD);
      
      print_bnd_xbs("1","2",r2mg*LO,r2mg*HI,FRM_RAD);
      print_bnd_xbs("0","3",r2mg*LO,r2mg*HI,FRM_RAD);
      print_bnd_xbs("5","6",r2mg*LO,r2mg*HI,FRM_RAD);
      print_bnd_xbs("4","7",r2mg*LO,r2mg*HI,FRM_RAD);
      
      print_bnd_xbs("0","4",r3mg*LO,r3mg*HI,FRM_RAD);
      print_bnd_xbs("1","5",r3mg*LO,r3mg*HI,FRM_RAD);
      print_bnd_xbs("2","6",r3mg*LO,r3mg*HI,FRM_RAD);
      print_bnd_xbs("3","7",r3mg*LO,r3mg*HI,FRM_RAD);
      
    }

    printf("inc 5\n");
    exit;
  }

}
