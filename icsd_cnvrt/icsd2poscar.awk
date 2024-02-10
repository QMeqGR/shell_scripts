@include "icsd_lib.awk"
BEGIN{

  # E. Majzoub
  # Sept 2005

  # version 1.5.5
  # Mon Jan 28 12:07:31 CST 2013
  # add switch to over-ride the space group found in ICSD file
  # set on command line "-v SGOVERRIDE=1"

  # version 1.5.4
  # Fri Nov  5 13:47:57 CDT 2010
  # add icsd to cif converter
  
  # version 1.5.3
  # Thu Mar  6 23:15:29 CST 2008
  # -moved functions to library icsd_lib.awk
  #  no other changes.

  # version 1.5.2
  # Wed Jul 11 16:11:10 PDT 2007
  # minor addition of one line in parse section
  # to find element from H103 for example.

  # version 1.5.1
  # Tue Nov 28 13:34:41 PST 2006 
  # minor bug fix for input in icsd file of 0
  # instead of 0.0
  
  # version 1.5
  # Mon Nov 20 15:47:30 PST 2006
  # added element "D" in case H was input that way
  
  # version 1.5
  # Wed Nov  1 14:58:03 PST 2006
  # Increased output digits from 10 to 14
  #
  # version 1.4
  # Tue Apr  4 09:41:42 PDT 2006
  # ICSD has changed their file format, yet again
  # will now have to grab space group from N line
  #
  # also added find_fraction function for turning
  # 0.3333 into 0.3333333333333 and same for 0.6667
  # this fixes problems for cases where too many atoms
  # were generated because they were not overlapping
  # when they should have been.
  #

  # version 1.3
  # Mon Oct 17 14:15:19 PDT 2005
  # changed PI from 3.1415926535 to
  # 4.0*atan2(1.0,1.0) to get the lat
  # parms to be correct to 10 decimal
  # places.

  # version 1.2
  # orderd the output so that lowest Z is first
  # (this is optional and must be specified on
  # the command line)
  # cat blah | awk -f icsd2poscar.awk -v ORDER=1

  # version 1.1
  # changed the title line to Z: Z1 Z2 Z3

  # version 1.0
  # first version

  ####################################################

  CONVFMT="%.15g";
  TOLERANCE=0.0001; # tolerance for converting 0.3333 to 1/3

  MAX_ELEM=10;
  MAX_ATOM=100;

  PI = 4.0*atan2(1.0,1.0);
  D2R = PI/180.0;

  ELEM=0;       # num elements found

  # -v SGOVERRIDE=1; will over-ride the space group setting in icsd file
  # -v NEWSG="I41/a:2" example new space group

  # CIFOUT=1, will output cif file instead of poscar
  # ORDER=[0 || 1], order the output in increasing Z
  ordr[MAX_ELEM];     # holds the order in which elem[i]
                # should be placed in POSCAR file

  elem[MAX_ELEM];     # to hold the elements
  nwyk[MAX_ELEM];     # num WYKOFF positions of each element
  nats[MAX_ELEM];     # number of atoms of each element
  atom[3*MAX_ATOM];    # atom positions

  for(i=0;i<MAX_ELEM;i++) {
    nwyk[i]=0;
    nats[i]=0;
  }
  for(i=0;i<3*MAX_ATOM;i++) { atom[i]=0; }

  if ( SGOVERRIDE==1 ){
      spg=NEWSG;      
      if ( debug>0 ) printf("Overriding spacegroup found in file with %s\n",NEWSG);
  }
}

#####################################
#             Functions             #
#####################################

# functions now in icsd_lib.awk


#####################################
#       Pattern-Action Rules        #
#####################################
($1 == "N" && SGOVERRIDE==0 ){
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
  a = $2;
  b = $3;
  c = $4;
  alph = $5;
  beta = $6;
  gamm = $7;
}
( $1 == "S" && $2 == "GRUP" && SGOVERRIDE==0 ){
  spg = substr($0,7,50);
  if ( debug>0 ) printf("found space group line\n");
  if ( debug>0 ) printf("spg = %s\n",spg);

}

($1 == "A"){
  species = $2;
  parse_species(species);
  x = find_fraction($3);
  y = find_fraction($4);
  z = find_fraction($5);
  if (debug>0) printf("atom number %d, x=%.5f y=%5f z=%5f\n",at_num,x,y,z);
  nwyk[ELEM-1]=at_num; # will catch the last (highest) atom number
  if ( CIFOUT ) { print_atom_pos_cif(species,ELEM-1,x,y,z); }
  else { print_atom_pos(spg,ELEM-1,x,y,z); }
}


END{

  count_atoms();
# debug stuff
#  for(i=0; i<ELEM; i++){
#    printf("elem[%2d] = %2s, nwyk = %2d, nats= %2d\n",i,elem[i],nwyk[i],nats[i]);
#  }
  if ( !ORDER ) { for(i=0;i<MAX_ELEM;i++) { ordr[i]=i; } }
  if ( ORDER ) { order_atoms(); }
  if ( CIFOUT ) { print_cif(); }
  else { print_poscar(); }
  clean_up();
}
