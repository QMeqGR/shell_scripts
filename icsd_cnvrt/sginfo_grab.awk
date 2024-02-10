BEGIN{
  # grabs allxyz output from sginfo
  # E. Majzoub

  # v 1.0
  # Fri Nov  5 14:15:23 CDT 2010
  
  
  # command line
  # 
  # SG - space group symbol from icsd file
  # SGNUM = 1 || 0  : get table number and exit
  # ALLXYZ = 1 || 0 : get allxyz output

  count=0;
}

#( $0 ~ "Inversion-Flag" && ALLXYZ==1 ){pr=1;}
( ( $0~"Inversion-Flag" || $1=="x," ) && ALLXYZ==1){pr=1;}
(pr==1 && ( $1~"x" || $1~"y" || $1~"z" || $1~"-") && ALLXYZ==1){
  count++;
  printf("%d '%s'\n",count,$0);
}
(SGNUM==1 && $1=="Space" && $2=="Group"){
  print $3;
}

END{


  

}
