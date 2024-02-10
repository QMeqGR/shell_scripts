@include awklib.awk
BEGIN{
  TINY=1e-6;
  CONVFMT="%.15f";
  totatoms=0;
  # Things to set on command line if desired:
  # APFU=0; # can set atoms per formula unit if you like
  # KPTS=0; # set number of k-points to calc kpoint density
            # in recip space
  a[3];
  b[3];
  c[3];
  k1[3]; # recip space basis vectors
  k2[3];
  k3[3];
  v1[3];     # temp storage
  v2[3];     # temp storage
  vc[3];     # temp storage
}

(NR==1){ for(i=1;i<NF+1;i++){ Z[i-1]=$i; }; nat=NF-1; }
(NR==2){scale=$1;}
(NR==3){a[0] = $1; a[1]=$2; a[2]=$3;}
(NR==4){b[0] = $1; b[1]=$2; b[2]=$3;}
(NR==5){c[0] = $1; c[1]=$2; c[2]=$3;}
(NR==6){ for(i=1;i<NF+1;i++){ N[i]=$i; }; }

END{

  if ( scale > 1+TINY || scale < 1-TINY ){
    printf("\n\n");
    printf("       !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    printf("       !!   WARNING : scale is not 1.0  !!\n");
    printf("       !!            rescaling          !!\n");
    printf("       !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    printf("\n\n");

    if ( debug > 0 ) printf(" CHANGING SCALE\n");
    for(i=0;i<3;i++) a[i] *= scale;
    for(i=0;i<3;i++) b[i] *= scale;
    for(i=0;i<3;i++) c[i] *= scale;
    scale = 1.0;

  }

  printf("\n");
  printf("+++++++++++ CONTCAR info ++++++++++++++\n\n");
  printf("Number of types of atoms in POSCAR file: %d\n",nat);
  for(i=1;i<nat+1;i++){totatoms += N[i];}
  printf("Total number of atoms in POSCAR file: %d\n",totatoms);
  if ( APFU>0 ){
    printf("FU/cell = %d\n",totatoms/APFU);
    volume=cellvolume(a,b,c);
    printf("Cell volume per formula unit: %f [ang^3]\n",APFU*volume/totatoms);
    printf("\n");
  }
  printf("Lattice vectors\n");
  latvec2abc(a,b,c);
  printf("\n");
  printf("Recip lattice vectors\n");
  volume=cellvolume(a,b,c);
  k1[0] = (b[1]*c[2]-b[2]*c[1])/volume;
  k1[1] = (b[2]*c[0]-b[0]*c[2])/volume;
  k1[2] = (b[0]*c[1]-b[1]*c[0])/volume;

  k2[0] = (c[1]*a[2]-c[2]*a[1])/volume;
  k2[1] = (c[2]*a[0]-c[0]*a[2])/volume;
  k2[2] = (c[0]*a[1]-c[1]*a[0])/volume;

  k3[0] = (a[1]*b[2]-a[2]*b[1])/volume;
  k3[1] = (a[2]*b[0]-a[0]*b[2])/volume;
  k3[2] = (a[0]*b[1]-a[1]*b[0])/volume;

  printf("k1 = %15.10f%15.10f%15.10f\n",k1[0],k1[1],k1[2]);
  printf("k2 = %15.10f%15.10f%15.10f\n",k2[0],k2[1],k2[2]);
  printf("k3 = %15.10f%15.10f%15.10f\n",k3[0],k3[1],k3[2]);

  printf("Recip cell volume: %15.10f [ang^-3]\n",cellvolume(k1,k2,k3));
  if ( debug>0 ){
    printf("a.k1 a.k2 a.k3 = %10.5f%10.5f%10.5f\n",
	   vdotprod(a,k1),
	   vdotprod(a,k2),
	   vdotprod(a,k3));
    printf("b.k1 b.k2 b.k3 = %10.5f%10.5f%10.5f\n",
	   vdotprod(b,k1),
	   vdotprod(b,k2),
	   vdotprod(b,k3));
    printf("c.k1 c.k2 c.k3 = %10.5f%10.5f%10.5f\n",
	   vdotprod(c,k1),
	   vdotprod(c,k2),
	   vdotprod(c,k3));
  }
  if ( KPTS > 0 ) {
    printf("K-point density in recip space: %15.10f\n",
	   KPTS/cellvolume(k1,k2,k3));
  }
  printf("\n");
  
  for(i=1;i<nat+1;i++){
    if ( debug>0 ) printf("Z wt num = %5d %6.2f %5d\n",Z[i],ztowt(Z[i]),N[i]);
    tot_wt += ztowt(Z[i]) * N[i];
  }
  printf("Total weight [amu]: %.2f\n",tot_wt);
  density_gcc = tot_wt * 1.66044 / cellvolume(a,b,c);
  printf("Density = %f [g/cc]\n",density_gcc);
  printf("\n");
  printf("+++++++++++ Done ++++++++++++++\n");

}
