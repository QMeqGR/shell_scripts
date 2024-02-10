BEGIN{

  version=3.1
  
  # doscar_split.awk
  # E.H. Majzoub
  #
  # typical use:
  # cat DOSCAR | igawk -f doscar_split.awk -v prt_tot=1 -v ispin=0 -v lm_decomp=1
  #
  # version 3.1, 17 Oct 2015, small minor output changes, no fixes.
  # version 3.0, 21 Jan 2014, updated to get spin polarized lm-decomp correct
  # version 2.0, 26 Sept 2012, updated for vasp 5, not fully functional
  # version 1.0, 22 June 2009
  #

  # command line parameters:
  # ispin=0; non-spin polarized
  #      =1; spin-polarized
  # lm_decomp=1; DOSCAR has LM decomp format

  # N= atom number to extract
  # if N is not set, then the script will extract
  # all atom DOS to ./atom_dos/DOS_#

  # ispin=1 spin polarized (default non-spin polarized)

  # Note: the script will automatically shift the Fermi
  # energy to zero, and integrate the DOS for each s,p,d

  # Output:
  #
  # non-spin polarized:
  # Energy sDOS sIDOS pDOS pIDOS dDOS dIDOS
  #
  # spin polarized:
  # Energy sDOSup sIDOSup sDOSdn sIDOSdn ... p ... d ...
  #
  # LM decomp, non-spin polarized:
  # Energy s pm1 pm0 pp1 dm2 dm1 dm0 dp1 dp2
  #

  MAXDATA=1000;
  MAXATOMS=200;
  nat=0; # number of atoms
  header=6; # six lines in header VASP 4.6.x
  ndat=0;
  Elow=0;
  Ehigh=0;
  Efermi=0;
  Ebin_width=0;
  sp_pol=1;
  non_sp_pol=0;
  vasp_version=5;

  prt_tot=1; # will print the total DOS

  # counters
  count=0;
  atom_count=0; ac_flag=0;
  dat_count=0;

  # array allocation
  EN[MAXDATA];
  DOS_all[MAXDATA];
  IDOS_all[MAXDATA];

  DOS_all_up[MAXDATA];
  IDOS_all_up[MAXDATA];
  DOS_all_dn[MAXDATA];
  IDOS_all_dn[MAXDATA];

  DOS_S[MAXATOMS*MAXDATA];
  DOS_P[MAXATOMS*MAXDATA];
  DOS_D[MAXATOMS*MAXDATA];
  DOS_F[MAXATOMS*MAXDATA];

  DOS_S_up[MAXATOMS*MAXDATA];
  DOS_P_up[MAXATOMS*MAXDATA];
  DOS_D_up[MAXATOMS*MAXDATA];
  DOS_F_up[MAXATOMS*MAXDATA];
  DOS_S_dn[MAXATOMS*MAXDATA];
  DOS_P_dn[MAXATOMS*MAXDATA];
  DOS_D_dn[MAXATOMS*MAXDATA];
  DOS_F_dn[MAXATOMS*MAXDATA];

  # for LM Decomp
  DOS_Sm0[MAXATOMS*MAXDATA];
  DOS_Pm1[MAXATOMS*MAXDATA];
  DOS_Pm0[MAXATOMS*MAXDATA];
  DOS_Pp1[MAXATOMS*MAXDATA];
  DOS_Dm2[MAXATOMS*MAXDATA];
  DOS_Dm1[MAXATOMS*MAXDATA];
  DOS_Dm0[MAXATOMS*MAXDATA];
  DOS_Dp1[MAXATOMS*MAXDATA];
  DOS_Dp2[MAXATOMS*MAXDATA];

  # for sp-pol LM decomp
  DOS_Su[MAXATOMS*MAXDATA];
  DOS_Sd[MAXATOMS*MAXDATA];

  DOS_Pux[MAXATOMS*MAXDATA];
  DOS_Puy[MAXATOMS*MAXDATA];
  DOS_Puz[MAXATOMS*MAXDATA];
  DOS_Pdx[MAXATOMS*MAXDATA];
  DOS_Pdy[MAXATOMS*MAXDATA];
  DOS_Pdz[MAXATOMS*MAXDATA];

  DOS_Duxy[MAXATOMS*MAXDATA];
  DOS_Ddxy[MAXATOMS*MAXDATA];
  DOS_Duyz[MAXATOMS*MAXDATA];
  DOS_Ddyz[MAXATOMS*MAXDATA];
  DOS_Duxz[MAXATOMS*MAXDATA];
  DOS_Ddxz[MAXATOMS*MAXDATA];
  DOS_Dux2y2[MAXATOMS*MAXDATA];
  DOS_Ddx2y2[MAXATOMS*MAXDATA];
  DOS_Duz2[MAXATOMS*MAXDATA];
  DOS_Ddz2[MAXATOMS*MAXDATA];

  # integrated DOS variables
  sint=0; pint=0; dint=0; fint=0;
  sint_up=0; pint_up=0; dint_up=0; fint_up=0;
  sint_dn=0; pint_dn=0; dint_dn=0; find_dn=0;


  printf("\nINFO:\n");
  printf("ispin= %d\n",ispin);
  printf("lm_decomp= %d\n",lm_decomp);    
  printf("vasp version= %d\n",vasp_version);

  if ( dbg ) {
      printf("debug header:\n");
      printf("dbg, NR, header+(ndat+1)*(atom_count+1), atom_count, ac_flag, ::, file_line\n");
  }
  printf("---> Removing current output directory and re-calculating...");
  if ( ispin==1 ) printf(" atom_dos_pol/\n\n");
  if ( ispin==0 ) printf(" atom_dos_npol/\n\n");
  if ( ispin==1 ) system("rm -rf atom_dos_pol");
  if ( ispin==0 ) system("rm -rf atom_dos_npol");

}

##################################
##################################

(dbg==1){print "dbg",NR, header+(ndat+1)*(atom_count+1), atom_count,ac_flag,"::", $0}

(NR==1){
  nat=$1;
  if ( nat>MAXATOMS ){printf("Exceeded MAXATOMS!\n");}
}
(NR==header){
  Elow=$1;
  Ehigh=$2;
  ndat=$3;
  Efermi=$4;

  if ( dbg ) {
    printf("header = %d\n",header);
    printf("ndat   = %d\n",ndat);
    printf("Elow   = %e\n",Elow);
    printf("Ehigh  = %e\n",Ehigh);
    printf("Efermi = %e\n",Efermi);
  }

}


# which atom are we on
(NR==header+ndat+1 && ndat>0 ){ 
  if ( dbg) printf("header+ndat+1= %d  NR= %d -----> setting atom_count=1\n",header+ndat+1, NR);
  atom_count=1;
}
(NR==header+(ndat+1)*atom_count && atom_count==1){
  if ( ac_flag==0 ) ac_flag=1;
}
(NR==header+(ndat+1)*(atom_count+1) && atom_count>0){
  if ( dbg ) printf("NR=%5d atom_count= %3d ac_flag=%d\n",NR,atom_count,ac_flag);
  if ( ac_flag==1 ) {
    atom_count++;
    dat_count=0;
  }
}

# read in DOS for all atoms
(NR>header && NF==3 && ispin==non_spin_pol && atom_count==0){
    # printf("reading total data at begining\n");
  EN[count]=$1-Efermi;
  DOS_all[count]=$2;
  IDOS_all[count]=$3;
  count++;
}
# in VASP 5, there is an empty column here making NF==4
(NR>header && NF==4 && ispin==non_spin_pol && atom_count==0 && vasp_version=5){
  EN[count]=$1-Efermi;
  DOS_all[count]=$2;
  IDOS_all[count]=$3;
  count++;
}
(NR>header && NF==5 && ispin==sp_pol && atom_count==0){
  EN[count]=$1-Efermi;
  DOS_all_up[count]=$2;
  DOS_all_dn[count]=$3;
  IDOS_all_up[count]=$4;
  IDOS_all_dn[count]=$5;
  count++;
}

# read in s,p,d DOS for atom[atom_count]
(atom_count>=1 && NF==4 && ispin==non_sp_pol ){
  DOS_S[dat_count+atom_count*ndat]=$2;
  DOS_P[dat_count+atom_count*ndat]=$3;
  DOS_D[dat_count+atom_count*ndat]=$4;
  dat_count++;
}
(atom_count>=1 && NF==7 && ispin==sp_pol ){
  DOS_S_up[dat_count+atom_count*ndat]=$2;
  DOS_S_dn[dat_count+atom_count*ndat]=$3;
  DOS_P_up[dat_count+atom_count*ndat]=$4;
  DOS_P_dn[dat_count+atom_count*ndat]=$5;
  DOS_D_up[dat_count+atom_count*ndat]=$6;
  DOS_D_dn[dat_count+atom_count*ndat]=$7;
  dat_count++;
}
(atom_count>=1 && NF==10 && ispin==non_sp_pol && lm_decomp=1 ){ # LM decomp non-sp-pol
  #     2 3  4  5  6   7   8   9      10
  #     s px py pz dxy dyz dxz dx2-y2 dz2

  DOS_Sm0[dat_count+atom_count*ndat]=$2;
  DOS_Pm1[dat_count+atom_count*ndat]=$3;
  DOS_Pm0[dat_count+atom_count*ndat]=$4;
  DOS_Pp1[dat_count+atom_count*ndat]=$5;
  DOS_Dm2[dat_count+atom_count*ndat]=$6;
  DOS_Dm1[dat_count+atom_count*ndat]=$7;
  DOS_Dm0[dat_count+atom_count*ndat]=$8;
  DOS_Dp2[dat_count+atom_count*ndat]=$9;
  DOS_Dp1[dat_count+atom_count*ndat]=$10;

  DOS_S[dat_count+atom_count*ndat]=$2;
  DOS_P[dat_count+atom_count*ndat]=$3+$4+$5;
  DOS_D[dat_count+atom_count*ndat]=$6+$7+$8+$9+$10;

  dat_count++;
}

(atom_count>=1 && NF==19 && ispin==sp_pol && lm_decomp=1 ){ # LM decomp sp-pol

  #                   1  2  3  4   5   6   7   8   9   10   11   12   13   14   15   16      17      18   19
  # read info. format is s+ s- px+ px- py+ py- pz+ pz- dxy+ dxy- dyz+ dyz- dxz+ dxz- dx2-y2+ dx2-y2- dz2+ dz2-

  su=DOS_Su[dat_count+atom_count*ndat]=$2;
  sd=DOS_Sd[dat_count+atom_count*ndat]=$3;

  pux=DOS_Pux[dat_count+atom_count*ndat]=$4;
  pdx=DOS_Pdx[dat_count+atom_count*ndat]=$5;
  puy=DOS_Puy[dat_count+atom_count*ndat]=$6;
  pdy=DOS_Pdy[dat_count+atom_count*ndat]=$7;
  puz=DOS_Puz[dat_count+atom_count*ndat]=$8;
  pdz=DOS_Pdz[dat_count+atom_count*ndat]=$9;

  duxy=DOS_Dux[dat_count+atom_count*ndat]=$10;
  ddxy=DOS_Ddx[dat_count+atom_count*ndat]=$11;
  duyz=DOS_Duyz[dat_count+atom_count*ndat]=$12;
  ddyz=DOS_Ddyz[dat_count+atom_count*ndat]=$13;
  duxz=DOS_Duxz[dat_count+atom_count*ndat]=$14;
  ddxz=DOS_Ddxz[dat_count+atom_count*ndat]=$15;
  dux2y2=DOS_Dux2y2[dat_count+atom_count*ndat]=$16;
  ddx2y2=DOS_Ddx2y2[dat_count+atom_count*ndat]=$17;
  duz2=DOS_Duz2[dat_count+atom_count*ndat]=$18;
  ddz2=DOS_Ddz2[dat_count+atom_count*ndat]=$19;

  sup=DOS_S_up[dat_count+atom_count*ndat]=su;
  snd=DOS_S_dn[dat_count+atom_count*ndat]=sd;
  pup=DOS_P_up[dat_count+atom_count*ndat]=pux+puy+puz;
  pnd=DOS_P_dn[dat_count+atom_count*ndat]=pdx+pdy+pdz;
  dup=DOS_D_up[dat_count+atom_count*ndat]=duxy+duyz+duxz+dux2y2+duz2;
  ddn=DOS_D_dn[dat_count+atom_count*ndat]=ddxy+ddyz+ddxz+ddx2y2+ddz2;

  DOS_S[dat_count+atom_count*ndat]=sup+sdn;
  DOS_P[dat_count+atom_count*ndat]=pup+pdn;
  DOS_D[dat_count+atom_count*ndat]=dup+ddn;

  dat_count++;
}


END{

  # calc the bin width for integration
  Ebin_width=EN[1]-EN[0];

  if ( prt_tot==1 ){
    for(j=0;j<ndat;j++){
      if ( ispin==non_sp_pol ){
	printf "%15.4e%12.4e%12.4e\n",
	  EN[j],
	  DOS_all[j+i*ndat],
	  IDOS_all[j+i*ndat] > "DOS_tot_nonpol.dat";
      }
      if ( ispin==sp_pol ){
	printf "%15.4e%12.4e%12.4e%12.4e%12.4e\n",
	  EN[j],
	  DOS_all_up[j+i*ndat],
	  IDOS_all_up[j+i*ndat],
	  DOS_all_dn[j+i*ndat],
	  IDOS_all_dn[j+i*ndat] > "DOS_tot_pol.dat";
      }
    }
  }

#  if ( N=="" ) printf("N= %s\n",N);
  
  if ( N=="" && ispin==non_sp_pol ) system("mkdir atom_dos_npol");
  if ( N=="" && ispin==sp_pol ) system("mkdir atom_dos_pol");
  for(i=1;i<nat+1;i++){
    sint=0;pint=0;dint=0;
    sint_up=0;pint_up=0;dint_up=0;
    sint_dn=0;pint_dn=0;dint_dn=0;
    if ( dbg ) printf("Atom [%3d] EN S P D\n",i);
    for(j=0;j<ndat;j++){
      
      if ( ispin==non_sp_pol ){
	sint+=DOS_S[j+i*ndat]*Ebin_width;
	pint+=DOS_P[j+i*ndat]*Ebin_width;
	dint+=DOS_D[j+i*ndat]*Ebin_width;
	if ( i==N && N!="" )
	  printf "%15.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e\n",
	    EN[j],
	    DOS_S[j+i*ndat],sint,
	    DOS_P[j+i*ndat],pint,
	    DOS_D[j+i*ndat],dint >> "DOS_"i;
	
	if ( N=="" )
	  printf "%15.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e\n",
	    EN[j],
	    DOS_S[j+i*ndat],sint,
	    DOS_P[j+i*ndat],pint,
	    DOS_D[j+i*ndat],dint >> "atom_dos_npol/DOS_"i;
      }
      if ( ispin==sp_pol ){
	sint_up+=DOS_S_up[j+i*ndat]*Ebin_width;
	sint_dn+=DOS_S_dn[j+i*ndat]*Ebin_width;
	pint_up+=DOS_P_up[j+i*ndat]*Ebin_width;
	pint_dn+=DOS_P_dn[j+i*ndat]*Ebin_width;
	dint_up+=DOS_D_up[j+i*ndat]*Ebin_width;
	dint_dn+=DOS_D_dn[j+i*ndat]*Ebin_width;
	if ( i==N && N!="" )
	  printf "%15.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e\n",
	    EN[j],
	     DOS_S_up[j+i*ndat],sint_up,
	    -DOS_S_dn[j+i*ndat],sint_dn,
	     DOS_P_up[j+i*ndat],pint_up,
	    -DOS_P_dn[j+i*ndat],pint_dn,
	     DOS_D_up[j+i*ndat],dint_up,
	    -DOS_D_dn[j+i*ndat],dint_dn >> "DOS_"i;
	
	if ( N=="" )
	  printf "%15.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e%12.4e\n",
	    EN[j],
	     DOS_S_up[j+i*ndat],sint_up,
	    -DOS_S_dn[j+i*ndat],sint_dn,
	     DOS_P_up[j+i*ndat],pint_up,
	    -DOS_P_dn[j+i*ndat],pint_dn,
	     DOS_D_up[j+i*ndat],dint_up,
	    -DOS_D_dn[j+i*ndat],dint_dn >> "atom_dos_pol/DOS_"i;
      }
      
    }
  }
  
}
