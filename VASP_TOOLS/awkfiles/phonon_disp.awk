BEGIN{
  # phonon_disp
  # extract phonon displacements from phonons.out
  # output file from gobaby code from Ozolins
  #
  # v 1.0 Mon Mar  1 13:04:48 CST 2010
  #

  # dbg;
  # mode; # the mode displacements requested

  headerlength=2;
  freq_cols=6;
  disp_cols=7;
  MAX=50000;

  modecount=0;
  negmodcnt=0;
  readmode=0;
  count=0;
  dx[MAX];
  dy[MAX];
  dz[MAX];
  
}


(NR==1){ nat=$1; }
(NR==2){ qx=$1; qy=$2; qz=$3; }
(NR>headerlength && NF==freq_cols){
  for(i=0;i<NF;i++){
    freq[modecount]=$(i+1);
    if ( freq[modecount] < 0.0 ) negmodcnt++;
    modecount++;
  }
}
(NR>headerlength && NF==disp_cols){
  if ( dbg && $1==1 ) {
    printf("### Reading mode %d  count = %d ###\n",readmode++,count);

  }
  if ( dbg ) printf("Reading disp %15.6f%15.6f%15.6f  count = %d\n",$2,$3,$4,count);
  dx[count]=$2;
  dy[count]=$3;
  dz[count]=$4;
  count++;
}


END{
  
  if (dbg) printf("Found %d mode frequencies\n",modecount);
  if (dbg) printf("Found %d negtive frequencies\n",negmodcnt);

  if (dbg) {
    printf("Found modes:\n");
    for(i=0;i<modecount;i++){
      printf("%10.2f ",freq[i]);
      if ( (i+1)%6==0 ) printf("\n");
    }
    printf("\n");
  }

  for(i=0;i<modecount;i++){
    if ( (mode-1)==i ){
      for(j=0;j<nat;j++){
	printf("%15.6f%15.6f%15.6f\n",
	       dx[i*nat+j],
	       dy[i*nat+j],
	       dz[i*nat+j]);
      }
    }
  }

}
