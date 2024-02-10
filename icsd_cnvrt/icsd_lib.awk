BEGIN{

  # v 1.3.1 25 May 2018, igawk removed from gawk package, igawk --> gawk
  # v 1.3 Tue Feb  3 15:41:55 CST 2015
  #       add 0.1667 = 0.16666666666666 for 1/6, and same for 5/6
  #
  # v 1.2 Fri Nov  5 13:47:57 CDT 2010 
  #       add icsd to cif converter
  #
  # v 1.1 Mon Oct 27 09:04:39 CDT 2008
  #       set tolerance so 0.3333 returns
  #       0.3333333333333, and similarly
  #       for 0.6667

  # v 1.0 Tue Apr  3 09:12:47 PDT 2007
  #       fixed triple product bug

  CONVFMT="%.15g";
  TOLERANCE=0.000001;
  TTOL=0.00000001;# tolerance for converting 0.3333 to 1/3
  PI =  4.0*atan2(1.0,1.0);
  D2R = PI/180.0;
  R2D = 180.0/PI;

}


function print_comment (comment_string) {
  printf("%s\n",comment_string);
}

function get_Z( ELMT ) {
  if ( ELMT=="H" )  return   1;
  if ( ELMT=="D" )  return   1;
  if ( ELMT=="He" ) return   2;
  if ( ELMT=="Li" ) return   3;
  if ( ELMT=="Be" ) return   4;
  if ( ELMT=="B" )  return   5;
  if ( ELMT=="C" )  return   6;
  if ( ELMT=="N" )  return   7;
  if ( ELMT=="O" )  return   8;
  if ( ELMT=="F" )  return   9;
  if ( ELMT=="Ne" ) return  10;
  if ( ELMT=="Na" ) return  11;
  if ( ELMT=="Mg" ) return  12;
  if ( ELMT=="Al" ) return  13;
  if ( ELMT=="Si" ) return  14;
  if ( ELMT=="P" )  return  15;
  if ( ELMT=="S" )  return  16;
  if ( ELMT=="Cl" ) return  17;
  if ( ELMT=="Ar" ) return  18;
  if ( ELMT=="K" )  return  19;
  if ( ELMT=="Ca" ) return  20;
  if ( ELMT=="Sc" ) return  21;
  if ( ELMT=="Ti" ) return  22;
  if ( ELMT=="V" )  return  23;
  if ( ELMT=="Cr" ) return  24;
  if ( ELMT=="Mn" ) return  25;
  if ( ELMT=="Fe" ) return  26;
  if ( ELMT=="Co" ) return  27;
  if ( ELMT=="Ni" ) return  28;
  if ( ELMT=="Cu" ) return  29;
  if ( ELMT=="Zn" ) return  30;
  if ( ELMT=="Ga" ) return  31;
  if ( ELMT=="Ge" ) return  32;
  if ( ELMT=="As" ) return  33;
  if ( ELMT=="Se" ) return  34;
  if ( ELMT=="Br" ) return  35;
  if ( ELMT=="Kr" ) return  36;
  if ( ELMT=="Rb" ) return  37;
  if ( ELMT=="Sr" ) return  38;
  if ( ELMT=="Y" )  return  39;
  if ( ELMT=="Zr" ) return  40;
  if ( ELMT=="Nb" ) return  41;
  if ( ELMT=="Mo" ) return  42;
  if ( ELMT=="Tc" ) return  43;
  if ( ELMT=="Ru" ) return  44;
  if ( ELMT=="Rh" ) return  45;
  if ( ELMT=="Pd" ) return  46;
  if ( ELMT=="Ag" ) return  47;
  if ( ELMT=="Cd" ) return  48;
  if ( ELMT=="In" ) return  49;
  if ( ELMT=="Sn" ) return  50;
  if ( ELMT=="Sb" ) return  51;
  if ( ELMT=="Te" ) return  52;
  if ( ELMT=="I" )  return  53;
  if ( ELMT=="Xe" ) return  54;
  if ( ELMT=="Cs" ) return  55;
  if ( ELMT=="Ba" ) return  56;
  if ( ELMT=="La" ) return  57;
  if ( ELMT=="Ce" ) return  58;
  if ( ELMT=="Pr" ) return  59;
  if ( ELMT=="Nd" ) return  60;
  if ( ELMT=="Pm" ) return  61;
  if ( ELMT=="Sm" ) return  62;
  if ( ELMT=="Eu" ) return  63;
  if ( ELMT=="Gd" ) return  64;
  if ( ELMT=="Tb" ) return  65;
  if ( ELMT=="Dy" ) return  66;
  if ( ELMT=="Ho" ) return  67;
  if ( ELMT=="Er" ) return  68;
  if ( ELMT=="Tm" ) return  69;
  if ( ELMT=="Yb" ) return  70;
  if ( ELMT=="Lu" ) return  71;
  if ( ELMT=="Hf" ) return  72;
  if ( ELMT=="Ta" ) return  73;
  if ( ELMT=="W" )  return  74;
  if ( ELMT=="Re" ) return  75;
  if ( ELMT=="Os" ) return  76;
  if ( ELMT=="Ir" ) return  77;
  if ( ELMT=="Pt" ) return  78;
  if ( ELMT=="Au" ) return  79;
  if ( ELMT=="Hg" ) return  80;
  if ( ELMT=="Tl" ) return  81;
  if ( ELMT=="Pb" ) return  82;
  if ( ELMT=="Bi" ) return  83;
  if ( ELMT=="Po" ) return  84;
  if ( ELMT=="At" ) return  85;
  if ( ELMT=="Rn" ) return  86;
  if ( ELMT=="Fr" ) return  87;
  if ( ELMT=="Ra" ) return  88;
  if ( ELMT=="Ac" ) return  89;
  if ( ELMT=="Th" ) return  90;
  if ( ELMT=="Pa" ) return  91;
  if ( ELMT=="U" )  return  92;
  if ( ELMT=="Np" ) return  93;
  if ( ELMT=="Pu" ) return  94;
  if ( ELMT=="Am" ) return  95;
  if ( ELMT=="Cm" ) return  96;
  if ( ELMT=="Bk" ) return  97;
  if ( ELMT=="Cf" ) return  98;
  if ( ELMT=="Es" ) return  99;
  if ( ELMT=="Fm" ) return 100;
  if ( ELMT=="Md" ) return 101;
  if ( ELMT=="No" ) return 102;
  if ( ELMT=="Lr" ) return 103;
  if ( ELMT=="Rf" ) return 104;
  if ( ELMT=="Db" ) return 105;
  if ( ELMT=="Sg" ) return 106;
  if ( ELMT=="Bh" ) return 107;
  if ( ELMT=="Hs" ) return 108;
  if ( ELMT=="Mt" ) return 109;
}

function print_title () {
  printf("Z: ");
  for (i=0;i<ELEM;i++) {
    printf("%d ", get_Z(elem[ordr[i]]) );
  }
  printf("\n");
}

function tol (a,b,t) {
  if ( ( (a+t)>b ) && ( (a-t)<b ) ) return 1;
  else return 0;
}

function find_fraction ( string ) {

  frac = string;
  slash=index(frac,"/");
  if ( debug>0 ) printf("string = %s, as float = %.8f  slash present=%d\n",
			string,string,slash);

  if ( slash ){
    numerator=substr(frac,0,slash);
    denominator=substr(frac,slash+1,length(frac));
    if (debug>0) printf("numer = %d   denom = %d\n",numerator,denominator);
    frac = numerator/denominator;
  }
  if ( tol(string,0.0,TOLERANCE) ) frac = 0.0;
  # special cases for ICSD database
  if ( tol(string,0.1667,TTOL) ) {
    if ( debug>0 ) printf("! Special case ICSD 0.166700\n");
    frac = 0.166666666666667;
  }
  if ( tol(string,0.8333,TTOL) ) {
    if ( debug>0 ) printf("! Special case ICSD 0.833300\n");
    frac = 0.833333333333333;
  }
  if ( tol(string,0.3333,TTOL) ) {
    if ( debug>0 ) printf("! Special case ICSD 0.333300\n");
    frac = 0.333333333333333;
  }
  if ( tol(string,0.6667,TTOL) ) {
    if ( debug>0 ) printf("! Special case ICSD 0.666700\n");
    frac = 0.666666666666667;
  }
  
  if ( debug>0 ) printf("fractn as float = %.8f\n",frac);
  return frac;

}

function print_lats (a,b,c,alph,beta,gamm) {
  if ( debug>0 ) printf("a b c = %20.14f%20.14f%20.14f\n",a,b,c);
  if ( debug>0 ) printf("angles = %20.14f%20.14f%20.14f\n",alph,beta,gamm);
  alph *= D2R;
  beta *= D2R;
  gamm *= D2R;
  if ( debug>0 ) printf("angrad = %20.14f%20.14f%20.14f\n",alph,beta,gamm);

  ax = a;

  bx = b * cos(gamm);
  by = b * sin(gamm);

  cx = c * cos(beta);
  cy = ( 1.0 / ( b * sin(gamm) ) ) * ( c * b * cos(alph) - c * b * cos(beta) * cos(gamm) );
  cz = sqrt( c*c - cx*cx - cy*cy );

  printf("1.0 lattice constant\n");
  printf("%20.14f%20.14f%20.14f\n",a,0.0,0.0);
  printf("%20.14f%20.14f%20.14f\n",bx,by,0.0);
  printf("%20.14f%20.14f%20.14f\n",cx,cy,cz);

}

function print_atom_pos (spg,E,X,Y,Z) {
  if ( debug>0 ) printf("Calling wyckoff.sh with X= %s, Y= %s, Z= %s\n",X,Y,Z);
  system("$CVT_TOP/wyckoff.sh -s \"" spg "\" -x " X " -y " Y " -z " Z " > tmp_"E"_"at_num);
}

function print_atom_pos_cif (SPC,E,X,Y,Z) {
  if ( debug>0 ) printf("Calling wyckoff.sh with X= %s, Y= %s, Z= %s\n",X,Y,Z);
  system("echo \"" SPC "\" " X " " Y " " Z " > tmp_"E"_"at_num);
}

function elem_match (element) {
  flag=0;
  for (i=0; i<ELEM; i++) {
    if ( element == elem[i] ) { flag=1; }
  }
  return(flag);
}

function parse_species (sp) {

  if ( debug>0 ) printf("%s length = %d\n",sp,length(sp));
  
  if ( length(sp) == 2 ){
    element = substr(sp,0,1);
    if ( debug>0 ) printf("looks like element %s\n", element);
    at_num = substr(sp,2,5);
    if ( !elem_match(element) ) {
      elem[ELEM++] = element;
      if ( debug>0 ) printf("--->element no. %d : %s\n",ELEM, element);
    }
  }
  
  if ( length(sp) == 3 || length(sp) == 4 ){
    c2 = substr(sp,2,1);
    if ( debug>0 ) printf("second character = %s\n", c2);

    if ( c2 !~ /[1-9]/ ) {
      element = substr(sp,0,2);
      if ( debug>0 ) printf("looks like element %s\n", element);
      at_num=substr(sp,3,5);
      if ( !elem_match(element) ) {
	elem[ELEM++] = element;
	if ( debug>0 ) printf("--->element no. %d : %s\n",ELEM, element);
      }
    }
    if ( c2 ~ /[1-9]/ ) {
      element = substr(sp,0,1);
      if ( debug>0 ) printf("looks like element %s\n", element);
      at_num=substr(sp,2,5);
      if ( !elem_match(element) ) {
	elem[ELEM++] = element;
	if ( debug>0 ) printf("--->element no. %d : %s\n",ELEM, element);
      }
    }
  }

  if ( length(sp) == 5 ) {
    printf("Not coded for length five.\n");
  }

}

function   print_atom_nos () {
  for (i=0; i<ELEM; i++) {
    printf(" %d ",nats[ ordr[i] ]);
  }
  printf("\n");
}

function print_atoms () {
  for (i=0;i<ELEM; i++) {
    tempname="tmp_"ordr[i]"_";
    system("cat "tempname"*");
    printf("\n");
  }
}

function print_poscar () {

  if ( debug>0 ) print_comment(comment);
  print_title();
  print_lats(a,b,c,alph,beta,gamm);
  print_atom_nos();
  printf("direct\n");
  print_atoms();
}

function print_cif () {

  # get the symmetry ops from sginfo
  system("sginfo "spg" -allxyz | gawk -f $CVT_TOP/sginfo_grab.awk -v ALLXYZ=1 > tmp_sginfo_allxyz");
  # get the symmetry group number from sginfo
  system("sginfo "spg" | gawk -f $CVT_TOP/sginfo_grab.awk -v SGNUM=1 > tmp_sginfo_sgnum");

  printf("data_global\n");
  printf("#");  print_comment(comment);   printf("\n");
  printf("# auto generated from icsd_cnvrt, E. Majzoub 2010\n");
  printf("_cell_length_a %f\n",a);
  printf("_cell_length_b %f\n",b)
  printf("_cell_length_c %f\n",c);
  printf("_cell_angle_alpha %f\n",alph);
  printf("_cell_angle_beta %f\n",beta);
  printf("_cell_angle_gamma %f\n",gamm);
  printf("_symmetry_space_group_name_H-M '%s'\n",spg);
  printf("_symmetry_Int_Tables_number "); system("cat tmp_sginfo_sgnum"); printf("\n");
  printf("loop_\n");
  printf("_symmetry_equiv_pos_site_id\n");
  printf("_symmetry_equiv_pos_as_xyz\n");
  system("cat tmp_sginfo_allxyz");
  printf("loop_\n");
  printf("_atom_site_label\n");
  printf("_atom_site_fract_x\n");
  printf("_atom_site_fract_y\n");
  printf("_atom_site_fract_z\n");
  print_atoms();
}

function count_atoms () {
  
  for (i=0; i<ELEM; i++) {
    system("cat tmp_"i"_* | wc | awk '(NF==3){print $1}' > tmp_nat_"i);
    tempname = "tmp_nat_"i;
    getline tval < tempname;
    nats[i]=tval;
  }
  
}

function order_atoms() {

  # this function will order the elements from lowest
  # to highest Z.

  # ordr[0] lowest Z
  # ordr[1] next highest Z, etc...

  # call the elements as
  # elem[ ordr[i] ]
  # nats[ ordr[i] ], etc..
  #

  # find and set the lowest element Z
  lowest=10000;
  for (i=0;i<ELEM;i++) {
    if ( get_Z(elem[i]) < lowest ) { lowest=get_Z(elem[i]); ordr[0]=i; }
  }

  # successively find larger Z's and order them
  for (i=1;i<ELEM;i++) {
    lowest=10000;
    for (j=0;j<ELEM;j++) {
      if ( get_Z(elem[j]) > get_Z(elem[ordr[i-1]]) && get_Z(elem[j])<lowest ) { lowest=get_Z(elem[j]); ordr[i]=j; }
    }
  }
  
# ordered from lowest to highest Z
#  for (i=0;i<ELEM;i++) {
#    printf("%s ",elem[ordr[i]]);
#  }

}

function clean_up () {
  system("rm -f tmp*");
}
