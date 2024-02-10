# readinputs function for phase diagram calculation
# this function reads the input data file

function [] = readinputs
  

global Cv_Vib_data;
global F_Vib_data;
global Freq;
global H_temp;
global H_valid;
global N_H_ratio;
global S_Vib_data;
global a;
global b;
global b_name;
global b_pre;
global b_type;
global const_var;
global const_var_value;
global debug;
global directory;
global decrement_gases;
global electrode;
global increment;
global isgas;
global increment_lower_P_bound;
global max_SCP_loops;
global molwt;
global myfile;
global niH;
global num_atoms;
global num_phases;
global phase;
global pre;
global print_comp_map;
global print_quant;
global printall;
global pressure_constraint;
global reactions_at_fixed_T;
global real_status;
global start;
global static_free_energy;
global stop;
global temp;
global tieline;
global tieline_steps;
global valid;
global var_end;
global var_init;
global volumescale;

# read "control_file"
skip = fskipl(myfile); # skip a line
# read "vibflags"
skip = fskipl(myfile);

# can't skip the next line b/c it depends on the number of types of
# atoms

#read and skip other header shit !!! CHANGE THIS NUMBER IF ADDING COLUMNS !!!!
skip = fscanf(myfile,"%s",5);

num_atoms=-1;
num_phases=0;
end_atoms="start";
end_phases="start";
ss=1;
while !strcmp(end_atoms,"end")
  species{ss} = fscanf(myfile,"%s",1);
  end_atoms = species{ss};
#  printf("reading %s\n",end_atoms);
  ss += 1;
  num_atoms += 1;
endwhile

i=1;
while !strcmp(end_phases, "end")

  phase{i}=fscanf(myfile,"%s",1);

  if ( !strcmp(phase{i},"end") )
    molwt(i) = fscanf(myfile,"%f",1);
    isgas(i) = fscanf(myfile,"%d",1);
    use_phase = fscanf(myfile,"%d",1);
    static_free_energy(i) = fscanf(myfile,"%f",1);

   #read in atom counts
   for j=1:num_atoms
     a(j,i)=fscanf(myfile,"%f",1);
   endfor
   if ( use_phase == 1 )
    num_phases += 1;
    i += 1;
   endif
  else
   end_phases = "end";    
   if ( use_phase == 0 ) #  delete last row if use phase was zero to give matrix correct dimensions
     a(:,num_phases+1) = [];
   endif
  endif
endwhile

# read in mass convservation constants
skip = fscanf(myfile,"%s",2);
for i=1:num_atoms
        b_name{i}=fscanf(myfile,"%s",1);
        b_type{i}=fscanf(myfile,"%s",1);
        if strcmp(b_type{i},"const")
          b_pre(i)=fscanf(myfile,"%f",1);
	  #printf("These must be the same order as the top header\n");
	  #printf("b_name{%d}= %2s, b_type{%d}= %s, b_pre(%d)= %f\n",i,b_name{i},i,b_type{i},i,b_pre(i));
        else
          start(i)=fscanf(myfile,"%f",1);
          stop(i)=fscanf(myfile,"%f",1);
        endif
endfor
b_pre(num_atoms+1)=1e-5; # set just to give b_pre the right dimensions.

# read whether this is a tie line calculation and read tieline steps
skip = fscanf(myfile,"%s",1);
tieline = fscanf(myfile, "%s",1);

skip = fscanf(myfile,"%s",1);
tieline_steps = fscanf(myfile, "%d",1);

# read in whether temp or Press constant
skip = fscanf(myfile,"%s",1);
const_var =fscanf(myfile,"%s",1); # this should be "T" or "P"

# read in constant variable value
skip = fscanf(myfile,"%s",1);
const_var_value =fscanf(myfile,"%f",1);

# read in variable intial value
skip = fscanf(myfile,"%s",1);
var_init =fscanf(myfile,"%f",1);

#read in variable end value
skip = fscanf(myfile,"%s",1);
var_end =fscanf(myfile,"%f",1);

#read in variable increment 
skip = fscanf(myfile,"%s",1);
increment =fscanf(myfile,"%f",1);

#read in variable printall 
skip = fscanf(myfile,"%s",1);
printall =fscanf(myfile,"%s",1);

#read in variable print_comp_map
skip = fscanf(myfile,"%s",1);
print_comp_map =fscanf(myfile,"%s",1);

#read in variable print_quant
#skip = fscanf(myfile,"%s",1);
#print_quant = fscanf(myfile,"%s",1);

#read in variable debug
skip = fscanf(myfile,"%s",1);
debug =fscanf(myfile,"%d",1);

#read in variable reactions_at_fixed_T
skip = fscanf(myfile,"%s",1);
reactions_at_fixed_T =fscanf(myfile,"%d",1);

# read in volume scaling
skip=fscanf(myfile,"%s",1);
volumescale=fscanf(myfile,"%f",1);

# read the pressure constraint
skip=fscanf(myfile,"%s",1);
pressure_constraint=fscanf(myfile,"%s",1);

# read the decrement gases flag
skip=fscanf(myfile,"%s",1);
decrement_gases=fscanf(myfile,"%d",1);

# read the increment_lower_P_bound
skip=fscanf(myfile,"%s",1);
increment_lower_P_bound=fscanf(myfile,"%d",1);

# read in max_SCP_loops
skip=fscanf(myfile,"%s",1);
max_SCP_loops=fscanf(myfile,"%d",1);

fclose(myfile);

if strcmp(const_var, "T")
   printf("overriding the value of 'reactions_at_fixed_T' in data.in file.\n");
   reactions_at_fixed_T = const_var_value;
endif

###########################################################
#               read thermo data files 
###########################################################

# read in data if it exists or else sets file validity bit to zero
for i= 1:num_phases
  valid(i) = 1;
endfor
####################   read phase i 
for i=1:num_phases
 myfile = fopen([phase{i},".dat"],"r");
 if (myfile != -1) 
  inc = 1;
  dat = 0;
  while (dat != -1)
   dat = fgetl(myfile);
   if (dat != -1)
    # this reads in the energies in units of J/mol-c
     [ temp(i,inc) F_Vib_data(i,inc) S_Vib_data(i,inc) Cv_Vib_data(i,inc)] = sscanf(dat, "%f %f %f %f", "C");
   # printf("f_vib_j of phase %5s = %10f\n", phase{i} , Freq(i,inc));
    inc++;
   endif;
  endwhile
  fclose(myfile);
 else
 valid(i)=0;
 endif;
endfor
  
  
