BEGIN{

  # E. Majzoub
  # 24 May 2006
  
  # version 1.0
  # Wed May 24 14:11:25 PDT 2006

  # select all structures, copy the structure data and put in one
  # big file, then run this script on it to produce separate directories
  # with POSCAR in each one.

  # VARIABLES
  
  debug=1;
}

($1 == "N"){
  count++;
  # the compound is currently bouned by "-" marks in ICSD
  n_fields = split($0,comment,"-");
  fname = "s_"comment[2]".txt";

  if (debug) {
    printf("\n\n--- creating file number %d ---\n",count);
    printf("n_fields = %d\n",n_fields);
    printf("fname = %s\n",fname);
  }

  system("mkdir s_"count);
  print $0 >> "s_"count"/"fname;
}
($1 == "C"){ print $0 >> "s_"count"/"fname; }
($1 == "A"){ print $0 >> "s_"count"/"fname; }


END{
  printf("Making POSCAR files\n");
  system("for dir in s_*; do echo ""NEW DIR $dir""  ; cd $dir; icsd_cnvrt -f *.txt -P; cd ..; done");

}
