@include "icsd_lib.awk"
BEGIN{

  # set on command line
  #
  # spg = "R-3m:H", etc...  (cell setting string)
  #

  MAXATOMS=400;

  a2b=1.0/0.5291772108;
  count=0;
  spec[MAXATOMS];
  apos[3*MAXATOMS];
  
  ELEM=0;
  elem[MAXATOMS];
  numtype[10]; # number of each type of element

}

($1 == "N" && spg == "" ){
  comment=$0;
  if ( debug > 0 ) print("getting spacegroup from N line");

  part1 = substr($0,index($0,"[")+1);
  part2 = substr(part1,0,index(part1,"]")-1);

  if ( debug > 0 ) {
    printf("part1 = %s\n",part1);
    printf("part2 = %s\n",part2);
  }
  spg = part2;
}

($1 == "C"){
  a = $2*a2b;  b = $3*a2b;  c = $4*a2b;
  alph=$5; beta=$6; gamm=$7;
}
($1 == "A"){

  parse_species($2);
  spec[count]=get_Z( elem[ELEM-1] );

  x = find_fraction($3);
  y = find_fraction($4);
  z = find_fraction($5);

  apos[3*count+0]=x;
  apos[3*count+1]=y;
  apos[3*count+2]=z;

  if (debug>0) printf("atom number %d, x=%.5f y=%5f z=%5f spec=%d\n",
		      at_num,x,y,z,spec[count]);

  count++;
}


END{
  if ( debug>0) printf("Total wyckoff positions found: %d\n",count);

  else printf("'%s'\n",spg);

  printf("%15.8f%15.8f%15.8f\n",a,b,c);
  printf("%15.8f%15.8f%15.8f\n",gamm,beta,alph);
  printf("1 1 1\n");
  printf(".true.\n");
  printf("%d\n",ELEM);

  for(i=0;i<ELEM;i++){
    for(j=0;j<count;j++){
      if ( spec[j] == get_Z( elem[i] ) ) numtyp[i]++;
    }
  }
 
  for(i=0;i<ELEM;i++){
    printf("'%s' '%s.in'\n",elem[i],elem[i]);
    printf("%d\n",numtyp[i]);
    for(j=0;j<count;j++){
      if ( spec[j] == get_Z( elem[i] ) )
      printf("%15.8f%15.8f%15.8f\n",apos[3*j+0],apos[3*j+1],apos[3*j+2]);
    }
  }

}
