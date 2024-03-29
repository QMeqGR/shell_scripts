@include "/home/ehm/awkfiles/awklib.awk"
BEGIN{

  # v 1.2 Wed Jul  9 15:40:16 CDT 2008
  # - correct output low precision: make 0.66667 print as 0.666666666667
  # - correct shft_orgn code
  # 
  # v 1.1 Tue Feb 26 17:01:18 CST 2008
  # - add option to shift atoms to origin
  #
  # v 1.0 Wed Jun 20 17:14:31 PDT 2007


  # Set on command line
  # shft_orgn=1

  CONVFMT="%.15g";
  PI =  4.0*atan2(1.0,1.0);
  D2R = PI/180.0;
  R2D = 180.0/PI;
  SMALL = 1e-5;
  MAX = 200; # number big enough to cover the entire periodic table


  frac_fix=0;
  nat=0;
  count=0;
  wyc_count=0;
  at_type_flag_NR=0;
  at_posi_flag_NR=0;
  at_number_flag_NR=0;
  vec_flag_NR=0;
  cell_parm_flag_NR=0;
  wyckoff_flag_NR=0;

  mul[MAX];
  order[MAX];
  num_each_type[MAX];

}

($1 ~ /Number/  && $6 ~ /cell/){
  at_number_flag_NR=NR;
  if ( debug ) printf("Setting at_number_flag_NR = %d\n",at_number_flag_NR);
}
(at_number_flag_NR+1==NR && NR>2){
  numatoms=$1;
  if ( debug ) printf("Number of atoms should be %d\n",numatoms);
}
($1 ~ /Type/  && $4 ~ /atom/){
  at_type_flag_NR=NR;
  if ( debug ) printf("Setting at_type_flag_NR = %d\n",at_type_flag_NR);
}
(at_type_flag_NR>0 &&
 NR>at_type_flag_NR &&
 at_posi_flag_NR==0 &&
 nat<numatoms) {
  for(i=0;i<NF;i++){ at_Z[nat+i] = $(i+1); }
  nat += NF;
  if ( debug ) printf("Reading %d atom types at line: %d. nat= %d\n",NF,NR,nat);
}
($1 ~ /Position/){
  at_posi_flag_NR=NR;
  if ( debug ) printf("Setting at_posi_flag_NR = %d\n",at_posi_flag_NR);
}
( at_posi_flag_NR>0 && (at_posi_flag_NR+1<=NR) ) {
  at_no[count]=$1; at_x[count]=$2; at_y[count]=$3; at_z[count]=$4;
  num_each_type[ at_Z[count] ]++;
  count++;
}
($1 ~ /Vectors/ && $2=="a,b,c:" ){
  vec_flag_NR=NR;
  if ( debug ) printf("Setting vec_flag_NR = %d\n",vec_flag_NR);  
}
( vec_flag_NR>0 && (NR==(vec_flag_NR+1)) ) {
  rb1[1]=$1; rb1[2]=$2; rb1[3]=$3;
}
( vec_flag_NR>0 && (NR==(vec_flag_NR+2)) ) {
  rb2[1]=$1; rb2[2]=$2; rb2[3]=$3;
}
( vec_flag_NR>0 && (NR==(vec_flag_NR+3)) ) {
  rb3[1]=$1; rb3[2]=$2; rb3[3]=$3;
}

($1 ~ /Origin/ && $2 ~ /at/ && shft_orgn==1) {
  orx=$3; ory=$4; orz=$5;
  if ( debug ) printf("Origin at %f %f %f\n",orx,ory,orz);
}

($1 ~ /Space/ && $2 ~ /Group/) { SPG=$5; }

($1 ~/Values/ && $3 == "a,b,c,alpha,beta,gamma:" ) {
  cell_parm_flag_NR=NR;
  if ( debug ) printf("Setting cell_parm_flag_NR = %d\n",cell_parm_flag_NR);
}
( cell_parm_flag_NR>0 && NR==cell_parm_flag_NR+1 ){
  cell_parms = $0;
}

($1 ~ /Wyckoff/ && $2 ~ /position/ ) {
  wyckoff_flag_NR = NR;
  if ( debug ) printf("Found wyckoff position at NR = %d\n",NR);
  wyc[wyc_count] = $3;
  wyc_count++;
}
( NR == wyckoff_flag_NR+1 && wyc_count>0  ){
  # get type from the first atom number in this position
  wyc_type[wyc_count-1]=$1;
  if ( debug ) printf("Wyckoff position %d, at.no. %d\n",wyc_count-1,$1);

  x = $2;  y = $3;  z = $4;
  if ( debug ) printf("--> %15.10f%15.10f%15.10f\n",x,y,z);

  # fix fractions that cause problems for icsd_cnvrt
  # example: findsym returns x=0.66667 y=0.33333
  # When some site is (2*y, x, z) and another is
  #                   (x, 2*y, z) they will be considered independent.
  #
  if ( tol(x,0.66667,1e-7) ) { x = 0.666666666666667; frac_fix=1; }
  if ( tol(y,0.66667,1e-7) ) { y = 0.666666666666667; frac_fix=1; }
  if ( tol(z,0.66667,1e-7) ) { z = 0.666666666666667; frac_fix=1; }

  if ( tol(x,0.33333,1e-7) ) { x = 0.333333333333333; frac_fix=1; }
  if ( tol(y,0.33333,1e-7) ) { y = 0.333333333333333; frac_fix=1; }
  if ( tol(z,0.33333,1e-7) ) { z = 0.333333333333333; frac_fix=1; }

  # more fraction fixes here

  if ( shft_orgn ){
    shftx = x - orx;
    shfty = y - ory;
    shftz = z - orz;
    if ( shftx < 0.0 ) shftx += 1.0;
    if ( shftx > 1.0 ) shftx -= 1.0;
    if ( shfty < 0.0 ) shfty += 1.0;
    if ( shfty > 1.0 ) shfty -= 1.0;
    if ( shftz < 0.0 ) shftz += 1.0;
    if ( shftz > 1.0 ) shftz -= 1.0;
    wyc_pos_x[wyc_count-1] = shftx;
    wyc_pos_y[wyc_count-1] = shfty;
    wyc_pos_z[wyc_count-1] = shftz;
  } else {
    wyc_pos_x[wyc_count-1] = x;
    wyc_pos_y[wyc_count-1] = y;
    wyc_pos_z[wyc_count-1] = z;
  }
  
}


END{

  if ( debug >0 ) {
    printf("Number of atoms found = %d\n",nat);
    for (i=0;i<nat;i++){
      printf("%5d%5s%15.5f%15.5f%15.5f\n",
	     at_no[i],ztoelm(at_Z[i]),at_x[i],at_y[i],at_z[i]);
    }
    printf("Space group: %s\n",SPG);
    printf("cell parms: %s\n",cell_parms);
    for(i=0;i<MAX;i++){
      if ( num_each_type[i] > 0 )
	printf("num of atoms with Z= %2d is %d\n",i,num_each_type[i]);
    }
    
  }

  printf("N * -");
  for(i=0;i<wyc_count;i++) {
    printf("%s",ztoelm(at_Z[ wyc_type[i]-1 ]));
  }
  printf("-");
  printf("[%s] Generated by findsym2icsd.awk\n",SPG);
  if ( frac_fix==1 ){
    printf("Fcomment: frac_fix=1\n");
  }
  printf("C %s\n",cell_parms);

  # need to print out the atoms so that like elements are
  # printed together. if they alternate it causes problems
  # for icsd_cnvrt script (can fix this later).
  for(j=1;j<MAX;j++){
    for(i=0;i<wyc_count;i++){
      if ( j==at_Z[ wyc_type[i]-1 ] )
	printf("A %2s%d %20.15f%20.15f%20.15f\n",
	       ztoelm(at_Z[ wyc_type[i]-1 ]),
	       1+mul[ at_Z[ wyc_type[i]-1 ] ]++,
	       wyc_pos_x[i],
	       wyc_pos_y[i],
	       wyc_pos_z[i]);
    }
  }
  
}
