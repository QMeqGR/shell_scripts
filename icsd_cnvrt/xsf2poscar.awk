@include "/home/ehm/awkfiles/awklib.awk"
BEGIN{

# awk program to convert XSF file format to POSCAR
# The lat vecs in XSF are in Angstrom

  r1[3];
  r2[3];
  r3[3];
  species[50];
  p[3000];
  nat=0;
  count=0;
  numtyp[50];
  typ[50];
}

(NR==5){ for(i=1;i<4;i++) { r1[i]=$i; } }
(NR==6){ for(i=1;i<4;i++) { r2[i]=$i; } }
(NR==7){ for(i=1;i<4;i++) { r3[i]=$i; } }
(NR==10){ nat=$1; }
(NR>10 && NF==4){

# atom coordinates (CART)
  species[count]=$1;
  p[3*count+0]=$2;
  p[3*count+1]=$3;
  p[3*count+2]=$4;
  count++;
}

END{

  ntyp=0;
  for(i=0;i<count;i++){
    species[i] = get_Z(species[i]);
#    printf("%d -- %d\n",i,species[i]);
    
    # first element
    if (ntyp==0 && numtyp[1]==0) {
      numtyp[1]++;
      ntyp=1;
      typ[ntyp]=species[0];
#      printf("typ[%d] = %d\n",typ[ntyp],species[0]);
      continue;
    }
    if ( species[i] == typ[ntyp] ) numtyp[ntyp]++;
    if ( species[i] != typ[ntyp] ) {
      ntyp++;
      typ[ntyp]=species[i];
      numtyp[ntyp]++;
#      printf("typ[%d] = %d\n",ntyp,typ[ntyp]);
    }

  }

#  printf("ntyp=%d\n",ntyp);
#  for(i=1;i<ntyp+1;i++){
#    printf("num of type %d : %d\n",i,numtyp[i]);
#  }

  printf("Z: ");
  for(i=1;i<ntyp+1;i++){
    printf("%d ",typ[i]);
  }
  printf("\n");
  printf("1.0 lattice constant\n");
  printf("%15.8f%15.8f%15.8f\n",r1[1],r1[2],r1[3]);
  printf("%15.8f%15.8f%15.8f\n",r2[1],r2[2],r2[3]);
  printf("%15.8f%15.8f%15.8f\n",r3[1],r3[2],r3[3]);
  for(i=1;i<ntyp+1;i++){
    printf(" %d ",numtyp[i]);
  }
  printf("\n");
  printf("Cartesian\n");

  count=0;
  for(j=1;j<ntyp+1;j++) {
    elm=elem[j];
    for(i=0;i<numtyp[j];i++){
      at=count;
      printf("%15.8f%15.8f%15.8f\n",p[3*at+0],p[3*at+1],p[3*at+2]);
      count++;
    }
  }

}
