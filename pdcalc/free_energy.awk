BEGIN {

  # VERSION 1.1
  # 14 June 2013 -- increase the translational mode cutoff to 5.0 cm-1 for non-imag modes
  #                 This was 0.05 before, probably too low and trans modes were counted.
  #                 Also, ignoring soft modes now counts the imag mode as regular instead
  #                 of skipping it.

  # Set on command line
  # Tinc, Tmax
  # fu
  # ignoresoft - ignore soft modes
  # gas - is this a gas

  MAXDAT=20000;
  hbar=6.582e-16; # in eV
  kB=8.617e-5;     # in eV
  fcount=0;
  icount=0;
  lowcut_f=CUTOFF; # non-imag mode cutoff in cm-1
  lowcut_i=CUTOFF; # imag cutoff cutoff in cm-1
  Tmin=10;

  F[MAXDAT];
  S[MAXDAT];
  Cv[MAXDAT];

  if ( ignoresoft == 1 && debug ) printf("WARN: using imag modes as real!\n");
  if ( debug ) printf("lowcut_f= %10.5f    lowcut_i= %10.5f\n",lowcut_f,lowcut_i);

}

# field $8 is cm-1
($2=="f"){ # mode is not imaginary
  if ( debug ) printf("Reading (f  ) mode # %d: %15.6f cm-1 ... ",$1,$8);
  fcount++;
  if ( $8>=lowcut_f ){
    if ( debug ) printf("keeping this mode.\n");
    w[FNR]=$6*1e12;
    skip[FNR]=0;
  } else { # this is probably a translational mode
    if ( debug ) printf("SKIPING this mode.\n");
    w[FNR]=0;
    skip[FNR]=1;
  }
}
# with "f/i=" field $7 is cm-1
($2=="f/i="){ # thie mode is imaginary
  if ( debug ) printf("Reading (f/i) mode # %d: %15.6f cm-1 ... ",$1,$8);
  if ( $7>lowcut_i ){ # we have a problem, because this is not translational
    icount++;
    w[FNR]=0;
    skip[FNR]=1;
    if ( ignoresoft==0 && gas==0 ) {
	if ( debug ) printf("SKIPING this mode.\n");
	printf("IMG %3d   -%-10.5f cm-1\n",icount,$7);
	w[FNR]=0;
	skip[FNR]=1;
    }
    if ( ignoresoft==1 && gas==0 ){
	if ( debug ) printf("keeping this mode.\n");
	if (debug) printf("using IMG %3d  %10.5f cm-1\n",icount,$7);
	w[FNR]=$5*1e12;
	skip[FNR]=0;
    }
  } else { # this may be just a translational mode
      if ( debug ) printf("SKIPING this mode.\n");
      if ( debug ) printf("trans mode %3d %10.5f cm-1. skipping this mode.\n",icount,$7);
      w[FNR]=0;
      skip[FNR]=1;
  }
}

END{

    mod=0;
    for(i=1; i<=FNR; i++){
	if ( skip[i]==0 ) mod++;
    }
    if ( debug ) printf("mode count = %d used modes\n",mod);

  for(T=Tmin; T <= Tmax; T+= Tinc){
    tot_energy=0; FreeEnergy=0; Entropy=0; SpecHeat=0;

    for(i=1; i <= FNR; i++) {

      if (skip[i]==0) {

	hbw = hbar*w[i];
	beta = 1.0/(kB*T);

	F[i]  = hbw/2 + kB*T*log( 1 - exp( -beta*hbw ) );
	S[i]  = kB*( beta*hbw*exp(-beta*hbw)/(1-exp(-beta*hbw)) -log(1-exp(-beta*hbw)) );
	Cv[i] = kB * ( hbw/(kB*T) )**2 * exp(hbw/(kB*T)) / (exp(hbw/(kB*T))-1)**2;
	
	FreeEnergy += F[i];
	Entropy += S[i];
	SpecHeat += Cv[i];
      }

    }

    printf("%15.0f%20.10f%20.10f%20.10f\n",T,FreeEnergy/fu,Entropy/fu,SpecHeat/fu);
  }
}



