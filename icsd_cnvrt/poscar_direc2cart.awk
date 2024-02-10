@include "/home/ehm/awkfiles/awklib.awk"
BEGIN{

  # SET ON COMMAND LINE
  # -v center_cluster=1

  # Interchanges POSCAR (CONTCAR) formats 'direct' and 'cartesian'

    VERSION=1.4

  # v 1.4 Thu 08 Jun 2017
  #  -move the direct to cart code to awklib and call a function
  #   here
  #
  # v 1.3 Wed 16 Sept 2015
  #  -bug fix for POSCARS with a scale factor
  #   If VASP input has a scale factor, and the atom positions are CART,
  #   the atom positions are in the basis vectors without the scale mult.
  #
  # v 1.2 Tue Jun 30 09:52:00 CDT 2009
  #  -set new flag for re-centering geometric center
  #   of a cluster to the box center (for clusters only!)
  #   This switch works only when input is CART and trans-
  #   forming to DIRECT and only with cubic boxes!!!
  #
  # v 1.1 Wed Apr 25 10:37:45 PDT 2007
  # v 1.0 Tue Apr 10 19:31:16 PDT 2007
  #

  # Notes:
  # - automatically changes scale to 1.0
  # - auto detects cart2direc or direc2cart


#########################################################################

  CONVFMT="%.15g";
  PI =  4.0*atan2(1.0,1.0);
  D2R = PI/180.0;
  R2D = 180.0/PI;

  C2D = 0;
  D2C = 0;
  atom_counter = 0;
  scale_chng_flag = 0;

}

(NR==1){ title=$0; }
(NR==2){ scale_line=$0; scale=$1; orig_scale=$1;}
(NR==3){ for(i=1;i<4;i++){ rb1[i]=$i; }; }
(NR==4){ for(i=1;i<4;i++){ rb2[i]=$i; }; }
(NR==5){ for(i=1;i<4;i++){ rb3[i]=$i; }; }
(NR==6){ atom_numbers=$0; for(i=1;i<NF+1;i++){nat+=$i}; }
(NR==7 && $1~"art"){ C2D=1; }
(NR==7 && $1~"ire"){ D2C=1; }
(NR>=8 && NF==3 && atom_counter<=nat){
  for(i=0;i<3;i++){ at[3*atom_counter+i]=$(i+1) };
  atom_counter++;
}


END{


  if ( debug > 0 ){
    printf("scale = %10.5f\n",scale);
    printf("lattice vec 1: %20.15f%20.15f%20.15f\n",rb1[1],rb1[2],rb1[3]);
    printf("lattice vec 2: %20.15f%20.15f%20.15f\n",rb2[1],rb2[2],rb2[3]);
    printf("lattice vec 3: %20.15f%20.15f%20.15f\n",rb3[1],rb3[2],rb3[3]);
    printf("Total number of atoms is %d\n",nat);
    if ( C2D ) printf("detected 'cartesian' input file\n");
    if ( D2C ) printf("detected 'direct' input file\n");
    for(i=0;i<nat;i++){
      printf("atom[%2d] = %20.15f%20.15f%20.15f\n",i,at[3*i+0],at[3*i+1],at[3*i+2]);
    }
    printf("+++ end of debug, POSCAR or CONTCAR follows\n");
  }

  if ( tol(scale, 1.0, 1e-10) == 0 ){
    if ( debug > 0 ) printf(" CHANGING SCALE\n");
    for(i=1;i<4;i++) rb1[i] *= scale;
    for(i=1;i<4;i++) rb2[i] *= scale;
    for(i=1;i<4;i++) rb3[i] *= scale;
    scale = 1.0;
    scale_chng_flag = 1;
  }

  printf("%s\n",title);
  if ( scale_chng_flag == 0 ) printf("%s\n",scale_line);
  if ( scale_chng_flag == 1 ) printf("1.0 newscale\n");
  printf("%20.15f%20.15f%20.15f\n",rb1[1],rb1[2],rb1[3]);
  printf("%20.15f%20.15f%20.15f\n",rb2[1],rb2[2],rb2[3]);
  printf("%20.15f%20.15f%20.15f\n",rb3[1],rb3[2],rb3[3]);
  printf("%s\n",atom_numbers);
  if ( D2C ) {
    printf("Cartesian\n");
    for(i=0;i<nat;i++){
	direct_to_cart(at,i,rb1,rb2,rb3,cart);
	printf("%20.15f%20.15f%20.15f\n",cart[0],cart[1],cart[2]);
    }
  }

  if ( C2D ) {

    printf("Direct\n");
    M[0] = rb1[1];
    M[1] = rb1[2];
    M[2] = rb1[3];

    M[3] = rb2[1];
    M[4] = rb2[2];
    M[5] = rb2[3];

    M[6] = rb3[1];
    M[7] = rb3[2];
    M[8] = rb3[3];

    # if scale != 1.0, then put the atoms in real space
    # coordinates that include the scale factor.
    # This is the v 1.3 fix from 16 Sept 2015.
    for(i=0;i<nat;i++){
	at[3*i+0] *= orig_scale; at[3*i+1] *= orig_scale; at[3*i+2] *= orig_scale;
	if ( debug ) printf("at[%d] = %15.10f%15.10f%15.10f\n",i,at[3*i+0],at[3*i+1],at[3*i+2]);
    }
    
    if ( center_cluster==1 ){
      # call iscubic from awklib
      cubval=iscubic(M);
      if ( debug==1 ) printf("cubval= %f\n",cubval);
      if ( tol(cubval,0.0,1e-5) ){
	printf("Cell is not cubic! Exiting.\n");
	exit;
      }
      # calc the geometric center of the cluster
      gc_x=0; gc_y=0; gc_z=0;
      for(i=0;i<nat;i++){
	gc_x += at[3*i+0]/nat; gc_y += at[3*i+1]/nat; gc_z += at[3*i+2]/nat;
      }
      if ( debug ) printf("gc = %10.4f%10.4f%10.4f\n",gc_x,gc_y,gc_z);
      for(i=0;i<nat;i++){
	newx=at[3*i+0]-gc_x+cubval/2;
	newy=at[3*i+1]-gc_y+cubval/2;
	newz=at[3*i+2]-gc_z+cubval/2;
	if ( newx > cubval ) newx=newx-cubval;
	if ( newx < 0.0    ) newx=newx+cubval;

	if ( newy > cubval ) newy=newy-cubval;
	if ( newy < 0.0    ) newy=newy+cubval;

	if ( newz > cubval ) newz=newz-cubval;
	if ( newz < 0.0    ) newz=newz+cubval;
	at[3*i+0]=newx;
	at[3*i+1]=newy;
	at[3*i+2]=newz;
      }
    }


    # call transvers and inverse functions from awklib.awk
    if ( debug > 0 ){
	printf("matrix M\n");
	print_matrix_3x3(M);
    }
    transpose(M,Mt);
    if ( debug > 0 ){
	printf("matrix Mt (transpose)\n");
	print_matrix_3x3(Mt);
    }
    inverse3x3(Mt,Minv);
    if ( debug > 0 ){
	printf("matrix Minv (inverse)\n");
	print_matrix_3x3(Minv);
    }
    if ( debug > 0 ) printf("Atom positions.\n");

    for(i=0;i<nat;i++){
      printf("%20.15f%20.15f%20.15f\n",
	     at[3*i+0]*Minv[0] + at[3*i+1]*Minv[1] + at[3*i+2]*Minv[2],
	     at[3*i+0]*Minv[3] + at[3*i+1]*Minv[4] + at[3*i+2]*Minv[5],
	     at[3*i+0]*Minv[6] + at[3*i+1]*Minv[7] + at[3*i+2]*Minv[8]);
    }
    
  }

}
