# PDcalc.m

addpath("/home/ehm/src/pdcalc/");

#
# PDcalc V2, this is re-written to handle multiple gases and handle them all equally
#
# V 2.0
# E.H. Majzoub
# UM-St. Louis
# 18 October 2013
#

# v 2.1.0  27 Jul 2017. Provide info on pressure when no solution is found.
# v 2.0.1  18 May 2016. Fix some output printing issues.


# constants
global k_B = 1.38e-23; # in joules/K
global eVtoJ = 1.602e-19;
global Avogadro=6.022e23
global PI=3.14159265358979;
global AMU=1.66053892e-27;
global hbar=1.05457173e-34;
global JMK_to_EVAK=1.0364e-5;

#variables

global F_Vib_data;
global S_Vib_data;
global a;
global b;
global b_name;
global b_pre;
global b_type;
global const_var;
global const_var_value;
global debug;
global decrement_gases;
global e213count=0;
global increment;
global increment_lower_P_bound;
global isgas;
global molwt;
global mu=0;
global ngases;
global niGas;
global num_atoms;
global num_phases;
global phase;
global print_comp_map;
global printall;
global pressure_constraint;
global reactions_at_fixed_T;
global Rgas_pre=8.3144621; # J /(mol K)
global Rgas;
global start;
global static_free_energy;
global steps;
global stop;
global temp;
global tieline;
global tieline_steps;
global TR;
global valid;
global var;
global var_end;
global var_init;
global volumescale;
global wtpct=0;

# version
vers_major=2;
vers_minor=1;
vers_bugfix=0;
vers_date="27 Jul 2017";

TR=-1;
reactions_at_fixed_T= -1;
removed_gas=0;

debug_on_warning (3)

difftol=0.001;
maxfu=5;
global max_SCP_loops;
SCP_tol=1e-5; # Pascals
Pscp_diff=0;
Pscp_diff_old=0;
printmax=9;
printflag=1;
screen_counter=0;
Pr_update=0; molsum=0;

#####################################################
printf("\n");
printf("##################################################\n");
printf("# PDcalc version %d.%d.%d  %s\n",vers_major,vers_minor,vers_bugfix,vers_date);
printf("# E.H. Majzoub, UMSL\n");
printf("# Orig script: 23 Oct 2013\n");
printf("##################################################\n");


###  read data.in input file
global directory = './'
global myfile = fopen("data.in","r");
# call readinputs.m
readinputs
#printinputs
debug
num_atoms
num_phases


##########################################
#         print phases used
##########################################
printcount=0;
printf("-----------------------------------------------------------------------------------------\n");
printf("                 ---- Phases used in this calculation ----\n\n");
for j = 1:num_phases
  printf("%-30s ",phase{j}); printcount++;
  if ( printcount>2 || length(phase{j})>28 )
    printf("\n"); printcount=0;
  endif
endfor
if (printcount>0) printf("\n"); endif
printf("-----------------------------------------------------------------------------------------\n");
printf("                 ---- General Run Info. ----\n\n");

Rgas = Rgas_pre/volumescale;

if ( reactions_at_fixed_T > 0 )
   TR=reactions_at_fixed_T;
   printf("  reactions_at_fixed_T = %d K\n",TR);
endif

# count the number of gases amongst the phases and
# create last row of a for the pressure constraint
ngases=0;
for j = 1:num_phases
    if ( isgas(j)==1 )
      ngases = ngases+1;
      a(num_atoms+1,j) = Rgas * TR; # will get changed below for variable P
    else
      a(num_atoms+1,j) = 0;
    endif
endfor

printf("  number of gas species = %d\n",ngases);
printf("  max_SCP_loops= %d\n",max_SCP_loops);

# Check the volumescale variable and print warning if not 1.
printf("\n");
printf("  System Volume = %f [m^3]\n",volumescale);
printf("  Reaction temperatures are volume dependent! (0.0224 m^3 = 22.4 l)\n");

# check decrement_gases flag (0 or 1)
if ( decrement_gases )
   printf("\n  ----  decrement_gases flag is set to 1  ----\n");
   printf("  Gas atoms will be removed and atom counts lowered\n");
   printf("  following desorption of gases. This should be used\n");
   printf("  with the 'free' (F) or 'lower' (L) option for the\n");
   printf("  pressure constraint.\n\n");
endif

## Gas entropy for non-hydrogen gases
function nq = NQ(m,TT)
  global hbar;
  global PI;
  global k_B;
  global AMU;
  nq = ( (m*AMU*k_B*TT) / ( 2*PI*(hbar^2) ) )^(3/2);
endfunction

# Note on the scaling of Rgas when using volumescaling:
# In the free energy and entropy, Rgas should not be scaled
# because the value of S or F depends only on the pressure,
# and returns the S or F in terms of this, and we want the
# units correct. Recall that P is calculated from the scaled
# volume and the gas phase fractions and so the scaling
# is in that term.

function sgas = SGAS (TT,PP,nqi)
  global Rgas; global Rgas_pre;
  global JMK_to_EVAK;
  global k_B;
  global molwt;
  nq=NQ(molwt(nqi),TT);
  # mono-atomic
  #sgas = (Rgas_pre)* ( 5/2 + log( nq ) + log( k_B*TT / PP ) );
  # diatomic and higher with vibrational contribution
  sgas = (Rgas_pre)* ( 7/2 + log( nq/2 ) + log( k_B*TT / PP ) );
endfunction

function fgas = FGAS (TT,PP,nqi)
  global Rgas; global Rgas_pre;
  global JMK_to_EVAK;
  global k_B;
  global molwt;
  nq=NQ(molwt(nqi),TT);
  # mono-atomic
  # temp = - (Rgas_pre*TT) * ( log( nq ) + log( k_B*TT / PP ) + 1 ); 
  # diatomic and higher with vibrational contribution
  temp = - (Rgas_pre*TT) * ( log( nq/2 ) + log( k_B*TT / PP ) + 2 ); 
  fgas = temp * JMK_to_EVAK;
endfunction


####################################################
## Pick T or P as independent variable
####################################################
if ! strcmp(const_var, "T") && ! strcmp(const_var, "P") && ! strcmp(const_var, "C")
  printf("\nerror: please specify pressure(P) or temp(T) as constant variable\n\n");
endif

#########settings for GLPK function####################
# set bounds on atom constraints (F=free,S=equality,U=upperbound,L=lowerbound)
for i= 1:num_atoms
  ctype(i) = "S"; # equality constraint for the composition
endfor
printf("  ----- Pressure constraint ------\n");
if ( strcmp(pressure_constraint,"F") )
  printf("  Using F, free pressure constraint.\n");
  ctype(num_atoms+1) = "F"; # free
  printf("  suggest setting max_SCP_loops = 20\n");
elseif ( strcmp(pressure_constraint,"L")  )
  printf("  Using L, lower bound pressure constraint.\n");
  ctype(num_atoms+1) = "L"; # pressure is below
  printf("  suggest setting max_SCP_loops = 20\n");
elseif ( strcmp(pressure_constraint,"S")  )
  printf("  Using S, equality pressure constraint.\n");
  ctype(num_atoms+1) = "S";
  max_SCP_loops=1;
  printf("  setting max_SCP_loops = 1\n");
elseif ( strcmp(pressure_constraint,"U")  )
  printf("  Using U, upper bound pressure constraint.\n");
  ctype(num_atoms+1) = "U";
  printf("  suggest setting max_SCP_loops = 20\n");
endif


if ( increment_lower_P_bound )
  printf("\n     ---- increment_lower_P_bound flag is set to 1 ----\n");
  printf("    The lower pressure bound will be increased as gases are\n");
  printf("    desorbed. Use this with the 'lower' (L) constraint for\n");
  printf("    the system pressure.\n");
endif

# integer (I) or continuous (C) soluions
for i= 1:num_phases
  vartype(i) = "C";
  if ( isgas(i) )
    ub(i) = 200;
    lb_pre(i) = 1e-20; # lower bound of variables
  else
    ub(i) = 200;
    lb_pre(i) = 0;   # lower bound of variables
  endif

endfor
lb=lb_pre';
s = 1;   # maximization (-1) or minimzation (1)
param.msglev = 0;


#######################################################

if strcmp(const_var, "T")
  printf("\n  Temperature is %8.2f K\n",const_var_value);
elseif strcmp(const_var, "P")
  printf("\n  Pressure= %8.2f Pa\n",const_var_value);
  printf("  (Setting the 'b' constraint for pressure)\n");
  b_pre(num_atoms+1)=const_var_value;
else
  printf("\nChemical potential only\n\n");
endif

printf("-------------------------------------------------------------\n\n");

#############calculation################################
#
#   this outer loop varies the compositions from one
#   end of a tie line to the other with the endpoints
#   spelled out in the input data sheet 
#

if strcmp(tieline, "yes")
  num_tl_steps = tieline_steps;
elseif strcmp(tieline, "no")
  num_tl_steps = 0;
else
  printf("\n error,  please enter yes or no for tieline option\n");
  exit
endif
   
  
######### Tie line calculations ###############
tie_count=1;
loop_length(1)=0;
loop_length(2)=0;
loop_length(3)=0;
loop_length(4)=0;
loop_length(5)=0;
for j = 1:num_atoms
  if strcmp(b_type{j}, "tie")
    tie(j)=tie_count;
    loop_length(tie_count)=num_tl_steps;
    tie_count++;
  endif
endfor
tie_count--;

#### currently up to 5 elements
for x(1)=0:loop_length(1)
  for x(2)=0:loop_length(2)
    for x(3)=0:loop_length(3)
      for x(4)=0:loop_length(4)
        for x(5)=0:loop_length(5)
          
          for j = 1:num_atoms
            if strcmp(b_type{j}, "tie")
              b_pre(j)=start(j) + (x(tie(j))/num_tl_steps)*(stop(j)-start(j));
            elseif strcmp(b_type{j}, "const")
            else
              printf("\nplease select const, start, or end for each element\n");
              exit; 
            endif
          endfor

	  #############################################
	  # internal loop within a given composition
	  #############################################

	  e213count=0;
	  printf("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n");
	  printf("@ begin for composition: ");
	  for aa = 1 : num_atoms
	    printf("%s %2.2f  ",b_name{aa},b_pre(aa));
	  endfor
	  printf("\n");

	  ######################  MAIN LOOP ##########################################
	  rxncount=0;
	  steps = (var_end - var_init)/increment;
	  for i = 0 : steps ## main loop ##
	    printf("==================== MAIN LOOP i= %5d ======================\n",i);

	    var = var_init + i*increment;
	    
	    if ( strcmp(const_var, "T") ) # variable P

	      Tvar = const_var_value;
	      P=var;
	      b_pre(num_atoms+1) = P;  # this sets the pressure constraint
	      P_lowerbound=P;

	    elseif ( strcmp(const_var,"P") ) # variable T

	      Tvar = var;

	      if ( i>0 && increment_lower_P_bound )
		P = a(num_atoms+1,:)*lastxopt;
		b_pre(num_atoms+1) = P; # increase the lower bound
	      else
		P = const_var_value;		    
	      endif
	      P_lowerbound = P;

	      for j = 1:num_phases
		if ( isgas(j)==1 )
		  a(num_atoms+1,j) = Rgas * Tvar;
		endif
	      endfor

	      else
		  printf("Error. Choose T or P\n");

	    endif

	    ####################################################################
	    kT_eV = k_B*Tvar/eVtoJ;
	    kT_eV_fixedT = k_B*TR/eVtoJ;

            b=b_pre';

	    # must set lastxopt before the SCP loop
	    if ( i != 0 ) lastxopt=xopt; endif	    

	    ###########################################################
	    #  Pressure self consistency loop
	    ###########################################################
	    for scp = 1 : max_SCP_loops

	      if ( scp == 1 ) Pscp = P; endif
	      Pold = Pscp;

	      ############################################################
	      ##  set free energy and entropy
	      for j = 1:num_phases
		if ( valid(j)==1 && scp==1 )
		  f_vib(j) = interp1(temp(j,:),F_Vib_data(j,:),Tvar);
		  s_vib(j) = interp1(temp(j,:),S_Vib_data(j,:),Tvar);
		  
		  f_vib_fixedT(j) = interp1(temp(j,:),F_Vib_data(j,:),TR);
		  s_vib_fixedT(j) = interp1(temp(j,:),S_Vib_data(j,:),TR);
		elseif ( valid(j)==0 && scp==1 )
		  f_vib(j) = 0;
		  s_vib(j) = 0;
		  
		  f_vib_fixedT(j) = 0;
		  s_vib_fixedT(j) = 0;
		endif
		if ( isgas(j) )
	          f(j)        = static_free_energy(j) + f_vib(j) + FGAS(Tvar,Pscp,j) ;
	          f_fixedT(j) = static_free_energy(j) + f_vib(j) + FGAS(TR,Pscp,j) ;
		else
	          f(j)        = static_free_energy(j) + f_vib(j);
	          f_fixedT(j) = static_free_energy(j) + f_vib_fixedT(j);
		endif
	      endfor
	      
	      
	      ##### chem energy = element total energy + chem potential formula
	      mu = var_init + i*increment;
	      
	      c0 = Pscp/volumescale ;
	      g = (f + c0)' ;
	      
	      g = f' ;
	      lastg=g;
	      c = g;

	      #
	      # here we minimize f= sum       x_i * f_i
	      #                        phases
              # subject to the constraint a*x=b, where a is the atom number matrix
	      # The last row of a is the pressure constraint
	      #

	      [xopt, fopt, status, extra]=glpk(c,a,b,lb,ub,ctype,vartype,s,param);
	      if ( status == 213 )
		e213count += 1;
		if ( e213count == 1 )
		  printf("error 213: ");
		else
		  printf("#");
		endif
		continue;
	      endif
	      
	      Pscp = ( Pold + 9 * a(num_atoms+1,:)*xopt ) / 10.0;
	      Pscp_diff = Pscp-Pold;

	      if ( debug )
		printf(" scp_loop%3d: Pold= %.3e Pscp= %.3e diff= %.2e status= %d\n",scp,Pold,Pscp,Pscp_diff,status);
	      endif

	      if ( scp==1 && max_SCP_loops>1 ) printf("scp loop: "); screen_counter=1; endif
	      if ( scp>=1 )
		printf("%d",screen_counter);
		screen_counter++;
		if ( screen_counter==10 ) screen_counter=0; endif
	      endif
	      if ( status==10 )
		printf("\n");
		printf("!! -GLPK Error 10: no solution. Try changing atom counts or pressure.\n");
		printf("   -The atom counts should be of order 1-10. Ballpark suggestions follow.\n");
		molsum=0;
		for iii=1:num_atoms
		  molsum = molsum+b(iii);
		endfor
                # The factor of 2 below works well for hydrogen. It can be hard to find a sol'n
                # when the temp is low or the pressure is high (above 10^6 Pa).
                # I couldn't find an easy way around this. Maybe another internal loop to search
		# for a solution would work, but it would take more time.
		printf("   -(molsum= %.0f   Rgas/volumescale= %.3f   Tvar= %.1f)\n",molsum,Rgas,Tvar);
		Pr_update= (molsum * Rgas * Tvar)/2; # note Rgas is scaled here (Rgas/volumescale)
		printf("   -Can try changing pressure to ~ %.1e [Pa]\n",Pr_update);
		printf("   -Can try changing   molsum to ~ %.0f\n", 2*P/(Rgas*Tvar) );
		printf("   -Or wait for Tvar to be ~ %.0f [K]\n",2*P/(molsum*Rgas) );

		break;
	      endif

	      if ( abs(Pscp-Pold) < SCP_tol ) break; endif
	      if ( Pscp_diff*Pscp_diff_old < 0.0 ) break; endif
	      Pscp_diff_old=Pscp_diff;
			   
	    endfor # end SCP loop
	    if ( scp == max_SCP_loops )
	      printf(" exceeded max scp loops\n");
	    endif
	    
	    # recalculate the pressure after the minimization
	    P = a(num_atoms+1,:)*xopt;
	    if ( strcmp(print_comp_map,"yes") )
	       if ( e213count>0 )
		  printf("\n"); e213count=0;
	       endif
	       if ( max_SCP_loops == 1 )
		 printf("\n### T= %+5d C     P(calc)= %6.2e [bar]   LPstatus=%d\n",Tvar-273,P*1e-5,status);
	       else
		 printf("\n### T= %+5d C     P(scp)= %6.2e [bar]    LPstatus=%d\n",Tvar-273,P*1e-5,status);
	       endif
	       for pp=1:num_phases
		   if ( xopt(pp) > difftol )
		     printf("%6.3f %s  ",xopt(pp),phase{pp});
		   endif
	       endfor
	       printf("\n");
	    endif

	    x_i(i+1,:) = xopt; 
	    fopt_i(i+1) = fopt;
	    
	    ########## LP minimization finished ##########
	    
	    ##### print initial distribution ####
            if ( i == 0 )
              lastxopt = xopt;
              if strcmp(print_comp_map,"yes")
                printf("\ncomposition: ");
                for i=1:num_atoms
                  printf(" %2s %2.2f ",b_name{i},b_pre(i));
                endfor
              endif
	      
	      printf("\nInitial: ");
	      for n= 1:num_phases
                if ( abs(xopt(n)) >  difftol )
                  printf("%.3f %-12.10s",xopt(n), phase{n});
                endif
	      endfor
	      printf("\n");
            endif
            
	    ##### print final distribution ##
            if (i == steps)
	      ##  print composition
	      printf("\n---------------------------------------------------\n");
              printf("Final: ");
              for n= 1:num_phases
                if ( abs(xopt(n)) >  difftol )
                  printf("%1.2f %-10.10s",xopt(n), phase{n});
                endif
              endfor
	      printf("\n");
            endif
	    

	    ################################################################
	    ####################### Reaction Check #########################
	    ################################################################

            for n= 1:num_phases
		if ( i != 0 )
		  if ( abs(xopt(n) - lastxopt(n)) > difftol )
		    # printf("setting print flag. i=%d  abs(fopt)= %.3g\n",i,abs(fopt));
                    printflag=1;
		    break;
		  endif
		endif
            endfor
            
	    if ( abs(fopt) > 1e-20 && printflag==1 && i!=0 )            
	       
	      rxncount=rxncount+1;	
              if ( strcmp(printall,"yes") )
		printf(".........................................................\n");
		printf(" Reaction # %d\n",rxncount);
		if strcmp(const_var, "T")
		  printf(" Pressure= %10.2f [bar]   fopt= %6.2g\n",P*1e-5,fopt);
		elseif strcmp(const_var, "P")
		  printf(" Temperature= %6.1f K   P= %8.2e [bar]     fopt= %6.2g\n",Tvar,P*1e-5,fopt);
		elseif strcmp(const_var, "C")
		  printf(" Chem Potential: mu= %4.4e  fopt= %6.2g\n",mu,fopt);
		endif
		
   		## calculate and print the difference table             
		if ( i != 0 )
		  for n= 1:num_phases
		    diff(n) = xopt(n) - lastxopt(n);
		    if ( debug == 1 ) printf("%12.5f ",diff(n)); endif
		  endfor
		endif            
		
		## Print the LHS of reaction
		printf("\n");
		for n= 1:num_phases
		  if ( diff(n) < -difftol ) printf("%.3f %-4s ",-diff(n),phase{n}); endif
		endfor
		
		## Print RHS of reaction
		printf("--->");
		printf(" ");
		for n= 1:num_phases
                  if ( diff(n) > difftol ) printf("%.3f %-4s ",diff(n),phase{n}); endif
		endfor
		
		printf("\n");
		dS=0; dF=0; dG=0; dG_Tlow=0;
		dS_fixedT=0; dF_fixedT=0;
		for n=1:num_phases
	          # printf("%-10s f= %10.6f  s=%8.6f  diff(n)= %6.3f\n",phase{n},f(n),s_vib(n),diff(n));
		  dS  += diff(n)*s_vib(n);
		  dF  += diff(n)*f(n);
		  dG  += diff(n)*g(n);
		  dG_Tlow += diff(n)*lastg(n);
		  
		  dS_fixedT  += diff(n)*s_vib_fixedT(n);
		  dF_fixedT  += diff(n)*f_fixedT(n);
		  
		  if ( isgas(n) )
		    dS += diff(n)*SGAS(Tvar,P,n) * JMK_to_EVAK;
		    # printf("dSgas = %f\n",SGAS(Tvar,P,n) * JMK_to_EVAK);
		    dS_fixedT += diff(n)*SGAS(TR,P,n) * JMK_to_EVAK;
		  endif
		endfor
		
		dS_rxn = dS;
		
		# for fixed T calculations
		dS_rxn_fixedT = dS_fixedT;
		
              endif
	      
	      ######## print a bunch of stuff or just the phase fractions #########
              if ( strcmp(printall,"yes") )
		 
		if ( strcmp(const_var,"P") )
		  printf("dH= %6.1f [kJ/mol rxn]    T= %+5d C",Tvar*dS*98.6, Tvar-273);
		endif
		if ( strcmp(const_var,"T") )
		  printf("dH= %6.1f [kJ/mol rxn]    P= %+.2e",Tvar*dS*98.6,  P);
		endif
		
		if ( reactions_at_fixed_T > 0 )
                  printf("\ndHt= %5.1f [kJ/mol rxn] = %6.1f [eV] %8s at  T= %+dK  %+d C\n",
			 TR*dS_fixedT*98.6,TR*dS_fixedT," ",TR,TR-273);
		endif
		
	        printf("\n");
		Pcalc = a(num_atoms+1,:)*xopt;
		printf("Partials [bar]: ");
		for gg = 1:num_phases
		  if ( isgas(gg) )
		    Ppart = a(num_atoms+1,gg)*abs(xopt(gg));
		    if ( Ppart < 1e-5 ) Ppart=0; endif
		    printf("P_%s = %.3e   ",phase{gg},Ppart*1e-5);
		  endif
		endfor
		printf("\n");
		
		#printf("mu= %4.2f eV    T= %3d C\n",mu, Tvar-273);
		
		printf("dF = %6.1f [eV]   %6.1f [kJ/mol rxn]\n", ...
		       dF,dF*98.6);
	        printf("dH = %6.1f [eV]   %6.1f [kJ/mol rxn]\n", ...
		       Tvar*dS,Tvar*dS*98.6);
	        printf("dS =               %6.1f [J/mol K]\n", ...
		       dS/JMK_to_EVAK ) ;
                printf("dG = %6.1f [eV]   %6.1f [kJ/mol rxn]   dG(T= %d) = %10.4f\n", ...
		       dG,dG*98.6,Tvar-increment,dG_Tlow);
                if ( reactions_at_fixed_T > 0 )
	          printf("dSt=               %6.1f [J/mol K]      at T= %+dK  %+d C\n", ...
			 dS_fixedT/JMK_to_EVAK,TR,TR-273) ;
                  printf("dHt= %6.1f [eV]   %6.1f [kJ/mol rxn]   at T= %+dK  %+d C\n",
                         TR*dS_fixedT,TR*dS_fixedT*98.6,TR,TR-273);
                endif
		
              endif # end printall
	      
	    endif
	    printflag=0;

	    ########## Decrement gases ##########
	    if ( decrement_gases && ( P > P_lowerbound ) )
	       for pp = 1:num_phases
		   if ( isgas(pp) )
		      if ( abs(xopt(pp)) > 1e-9 )
			 printf("Removing gas %10s ",phase{pp});
			 removed_gas=1;
			 for aa = 1:num_atoms
			   # Decrement composition based on atom
			   # numbers in the gas phase.
			   # Remove only the gas *above* the lower
			   # bound, if there is one.
			   frc = abs(xopt(pp))*a(aa,pp);
			   frc_scale = (P - P_lowerbound)/P;
			   rmov = frc * frc_scale;
			   printf("%8.1e ",rmov); 
			   b_pre(aa) -= rmov;
			 endfor
			 xopt(pp) = xopt(pp) * ( 1 - frc_scale );     #adjust xopt
		      endif
		      if ( removed_gas==1 ) printf("\n"); removed_gas=0; endif
		   endif
	       endfor
	       if ( debug )
		 printf("Presure after removal= %.2e\n",a(num_atoms+1,:)*xopt*1e-5);
	       endif
	    endif # decrement gas #


	  endfor # end main loop #
	  
	  
	  ################ Debug printing
	  if ( debug == 1 )
	    printf("###########################################################\n\n\n");
	    if strcmp(const_var, "T")
	      printf("Pressure  ");
	    elseif strcmp(const_var, "P")
	      printf("Temperature  ");
	    elseif strcmp(const_var, "C")
	      printf("Chem  ");
	    endif
	    
	    for j = 1:num_phases
	      printf("%-15s ",phase{j});
	    endfor
	    printf("\n");
	    
	    for i = 0: steps
	      printf("%-7.2e ",var_init + i*increment);   
	      for j = 1:num_phases
		printf("%-15.4f ",x_i(i+1,j));
	      endfor
	      printf(" Fopt = %-5.4g stat= %d\n", fopt_i(i+1),status);
	    endfor 
	  endif
	  printf("\n");
	  
	endfor  
      endfor
    endfor
  endfor
endfor### end of tie line loop
printf("\n");

##############################################################  
##### report WARNING if free energy files are missing###

if strcmp(printall, "yes")
  printf("\n\n");
  for i=1:num_phases
    if valid(i)==0
      printf("WARNING Missing phonon file for %10s\n", phase{i});
    endif
  endfor
endif
##############################################################  

printf("+++ Done +++\n");

