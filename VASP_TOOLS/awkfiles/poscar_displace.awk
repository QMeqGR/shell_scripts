BEGIN{

  # poscar_displace
  # reads a POSCAR (cart format only!) with
  # concat displacements following the atom
  # positions

  # v 1.0 Sun Feb 28 22:36:46 CST 2010
  #

  numat=0;
  atcount=1;
  # dreduce=0.5; reduce the displacement by factor

}

(NR==1){zline=$0; print $0; }
(NR==2){scaleline=$0; print $0; }
(NR==3){latvec1=$0; print $0; }
(NR==4){latvec2=$0; print $0; }
(NR==5){latvec3=$0; print $0; }
(NR==6){
  numline=$0; print $0;
  for(i=1;i<NF+1;i++){
    num_z[i]=$i;
    numat+=$i;
  }
}
(NR==7){
  if ( $1!~"art" ) {
    printf("Only Cartesian format allowed!!!\n");
    exit;
  } else {
    print $0;
  }
}
(NR>=8 && NR<(8+2*numat)){
  if ( atcount<=numat ){
    atx[atcount]=$1;
    aty[atcount]=$2;
    atz[atcount]=$3;
  } else {
    dispx[atcount-numat]=$2;
    dispy[atcount-numat]=$3;
    dispz[atcount-numat]=$4;
  }
    atcount++;
}

END{

  for(i=1;i<=numat;i++){
    printf("%20.15f%20.15f%20.15f\n",
	   atx[i]+dispx[i]*dreduce,
	   aty[i]+dispy[i]*dreduce,
	   atz[i]+dispz[i]*dreduce);
  }

}
