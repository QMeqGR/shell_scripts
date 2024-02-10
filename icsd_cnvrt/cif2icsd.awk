BEGIN{

# version 2.1  Thu Aug 17 20:08:06 CDT 2017
#     -- fix: ignore loop tags for things other than atom positions
# version 2.0  05 Jan 2010  complete re-write to handle
#              CIF files properly with loop_ construct

# version 1.0  ???

#  debug=1;

  nat=0;
  atom_flag=0;
  dataset_count=0;
  MAX_LOOP=50;
  loop[MAX_LOOP];
  loop_tag_on=0;
  loop_nr=0;
  loop_read_on=0;
  loop_read_nr=0;
  loop_count=0;

  noquote=0;

}

( "data_" == substr($1,1,5) ){ dataset_count++ }
($1 == "data_1"){
    if (debug) printf("---- Reading data set 1.\n");
}
($1 == "data_2"){
    if (debug) printf("---- At data set 2. Exiting.\n");
    exit;
}
($1 == "loop_"){
  # clear loop array
  if ( debug ) printf("*** Turning loop tag on\n");
  for(i=0;i<MAX_LOOP;i++){loop[i]=""};
  loop_tag_on=1;
  loop_count=0;
  loop_nr=NR;
  loop_read_on=0;
}
(loop_tag_on==1 && NR==(loop_nr+1) && $1 != "_atom_site_label"){
    tagvar=$1;
    if ( debug ){
	printf("tagvar= %s\n",tagvar);
	printf("Turning loop tag off\n");
    }
    loop_tag_on=0; loop_nr=0;
}
(loop_tag_on && NR>loop_nr){
  if ( substr($1,1,1)=="_" ){
    loop[loop_count++]=$1;
    if ( debug ) printf("-----> %s\n",$1);
    if ( $1=="_atom_site_label" )  {
      atom_site_label_num =(loop_count);
      if ( debug ) printf("%7s atom_site_label_num= %d\n",
			  "",atom_site_label_num);
    }
    if ( $1=="_atom_site_fract_x" ) {
      atom_site_fract_x_num=(loop_count);
      if ( debug ) printf("%7s atom_site_fract_x_num= %d\n",
			  "",atom_site_fract_x_num);
    }
    if ( $1=="_atom_site_fract_y" ) {
      atom_site_fract_y_num=(loop_count);
      if ( debug ) printf("%7s atom_site_fract_y_num= %d\n",
			  "",atom_site_fract_y_num);
    }
    if ( $1=="_atom_site_fract_z" ) {
      atom_site_fract_z_num=(loop_count);
      if ( debug ) printf("%7s atom_site_fract_z_num= %d\n",
			  "",atom_site_fract_z_num);
    }
    if ( $1=="_atom_site_U_iso_or_equiv" ) {
	atom_site_U_iso_or_equiv_num=(loop_count);
	if ( debug ) printf("%7s atom_site_U_iso_or_equiv_num= %d\n",
			  "",atom_site_U_iso_or_equiv_num);
    }
    if ( $1=="_atom_site_occupancy" ) {
      atom_site_occupancy_num=(loop_count);
      if ( debug ) printf("%7s atom_site_occupancy_num= %d\n",
			  "",atom_site_occupancy_num);
    }
    if ( $1=="_atom_site_adp_type" ) {
	atom_site_adp_type_num=(loop_count);
	if ( debug ) printf("%7s atom_site_adp_type_num= %d\n",
			    "",atom_site_adp_type_num);
    }
    if ( $1=="_atom_site_type_symbol" ) {
	atom_site_type_symbol_num=(loop_count);
	if ( debug ) printf("%7s atom_site_type_symbol_num= %d\n",
			    "",atom_site_type_symbol_num);
    }
  }
}
(loop_tag_on && NR>loop_nr){
  if ( substr($1,1,1)!="_" ){
    if ( debug ) printf("*** Turning loop tag off: count=%d\n",loop_count);
    # turn loop-tag off and loop-read on
    loop_tag_on=0;
    loop_read_on=1;
    loop_read_nr=NR;
  }
}
(loop_read_on && NR>=loop_read_nr && NF==loop_count && $1 !~ "#"){
  if ( debug ) { printf("## reading ## %s\n",$0); }
  if ( loop[atom_site_label_num-1] == "_atom_site_label" ){
    at_name[nat]=$atom_site_label_num;
    x[nat]=$atom_site_fract_x_num;
    y[nat]=$atom_site_fract_y_num;
    z[nat]=$atom_site_fract_z_num;
    U[nat]=$atom_site_U_iso_or_equiv_num;
    occ[nat]=$atom_site_occupancy_num;
    adp[nat]=$atom_site_adp_type_num;
    typsym[nat]=$atom_site_type_symbol_num;
    nat++;
  }
}
($1 ~ "_cell_length_a"){ a = $2; }
($1 ~ "_cell_length_b"){ b = $2; }
($1 ~ "_cell_length_c"){ c = $2; }
($1 ~ "_cell_angle_alpha"){ alph = $2; }
($1 ~ "_cell_angle_beta"){  beta = $2; }
($1 ~ "_cell_angle_gamma"){ gamm = $2; }

($1 ~ "_symmetry_space_group_name_H-M") {
  if ( index($0,"\r") != 0 ){
    if ( debug ){
      printf("!!! Found a fucking carraige return! ");
      printf(" Is this a goddamn DOS file?\n");
      printf("!!! I will remove the carraige returns. (You're welcome)\n");
    }
    sgpline=gsub("\r","",$0);
  }
  sgpline=$0;
  # check to see if the spacegroup is enclosed in single ' quotes
  if ( index($0,"'") == 0 ){
    noquote=1;
    if ( debug == 1 ){
      printf("cif2icsd dbg: no ' in spacegroup name\n");
    }
  }
}
($1 ~ "_symmetry_Int_Tables_number"){ sgn=$2; }

#($1 ~ "_atom"){ atom_flag=1; }
#(NF>=7 && atom_flag==1){
#  at_name[nat]=$1;
#  x[nat]=$5;
#  y[nat]=$6;
#  z[nat]=$7;
#  nat++;
#}


END{

  if ( debug ) {
      printf("Found %d data sets.\n",dataset_count);
  }
  if ( noquote==1 ){
    if ( debug ) printf("sg line = %s\n",sgpline);
    spacegroup=substr(sgpline,length("_symmetry_space_group_name_H-M")+1);
    if ( debug==1 ){
      printf("cif2icsd dbg: found spacegroup = %s\n",spacegroup);
    }
  } else {
    if ( debug ) printf("sg line = %s\n",sgpline);
    if ( debug ) printf("%s\n",substr(sgpline,match(sgpline,"'")+1));
    right=substr(sgpline,match(sgpline,"'")+1);
    if ( debug ) printf("%s\n",substr(right,0,length(right)-1));
    withspaces=substr(right,0,length(right)-1);
    nspaces=gsub(" ","",withspaces);
    if ( debug ) printf("n=%d\n",nspaces);
    spacegroup=withspaces;
    if ( debug ) printf("string=%s\n",spacegroup);
  }

  printf("N * [%s]\n",spacegroup);
  printf("C %8.4f%10.4f%10.4f%9.3f%8.3f%8.3f\n",
	 a,b,c,alph,beta,gamm);

  for(i=0;i<nat;i++){
    printf("A %5s %10.4f%10.4f%10.4f%10.4f%12.2f\n",
	   at_name[i],
	   x[i],y[i],z[i],U[i],occ[i]);
  }

}
