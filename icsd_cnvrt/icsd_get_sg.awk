BEGIN{
  spg="";
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

END{
  printf("%s",spg);
}
