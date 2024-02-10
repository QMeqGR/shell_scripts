@include "/home/ehm/awkfiles/awklib.awk"
BEGIN{
  # apos2poscar
  # output will be in CART format
  #
  # v 1.0 Sun Feb 28 22:36:46 CST 2010
  #       - this is a very minimal first version
  #         with no error checking
  #

  # dbg=0;
  numat=0;
  atcount=0;

}


(NR==1){latvec1=$0;}
(NR==2){latvec2=$0;}
(NR==3){latvec3=$0;}
(NR==4){supercell=$0;}
(NR==5){nspec=$1;}
(NR==6){
  for(i=1;i<NF+1;i++){
    wt[i]=$i;
  }
}
(NR==7){
  numline=$0;
  for(i=1;i<NF+1;i++){
    num_z[i]=$i;
    numat+=$i;
  }
}
(NR>=8 && NR<(8+numat)){
  at[atcount]=$0;
  atcount++;
}


END{

  if (dbg) {
    printf("latvec1= %s\n",latvec1);
    printf("latvec2= %s\n",latvec2);
    printf("latvec3= %s\n",latvec3);
    printf("nspec= %d\n",nspec);
  }

  printf("Z: ");
  for(i=1;i<nspec+1;i++){
    printf("%d ",wttoz( wt[i] ) );
  }
  printf("\n");
  printf("1.0\n");
  printf("%s\n",latvec1);
  printf("%s\n",latvec2);
  printf("%s\n",latvec3);
  printf("%s\n",numline);
  printf("Cartesian\n");
  for(i=0;i<=numat;i++){
    printf("%s\n",at[i]);
  }

}
