function [] = printinputs
  
global k_B = 1.38e-23; # in joules/K
global eVtoJ = 1.602e-19;
global JtoHart=2.293710449e+17;
global Avogadro=6.022e23
global M_Proton_kg = 1.6737e-27;
global M_H2_kg =  2*M_Proton_kg;
global M_Li_kg =  6.941*1e-3/Avogadro
global H_bar_eVs = 6.58211899e-16;   # eV*s 
global H_bar_Js = 1.054571e-34;   # eV*s
# ideal gas constant hydrogen
global R_H2 = 4124; #(J/kg K)
###hydrogen zero point  eV
global H_zero = 0.81874;
#variables
global num_phases;
global num_atoms;
global constrain_chem_element;
global tieline;
global tieline_steps;
global H2_static_energy;
global phase;
global isgas;
global static_free_energy;
global niH;
global a;
global b_pre;
global start;
global stop;
global b_type;
global molwt;
global b;
global electrode;
global var;
global const_var;
global const_var_value;
global var_init;
global var_end;
global steps;
global increment;
global printall;
global print_comp_map;
global print_quant;
global debug;
global real_status;
global Freq;
global H_temp;
global H2_Vib_data;
global H2_S_data;
global H_valid;
global temp;
global F_Vib_data;
global volume;
global valid;

#### print num_phases
printf("Number of phases=%d\n",num_phases);
#### print num_atoms
printf("Number of atoms=%d\n",num_atoms);

### print H2_static_free_energy
printf("H2 static free energy=%f\n",H2_static_energy);

# print different phases
printf("\nStatic free energies\n");
for i = 1:num_phases
  SFE_KJ_mol = static_free_energy*Avogadro/(JtoHart * 1000);
  printf("%-15s  %-15.8f  %-10.8f \n",phase{i}, static_free_energy(i),SFE_KJ_mol(i) );
endfor
printf("\n");




#####   look over  #####
########################
########################
#del_H = (SFE_KJ_mol(2)-SFE_KJ_mol(1)-2*H2_KJ_mol)/2;
#######################
#printf("\ndel  for MGH2 is %-10.4f \n", del_H);
printf("\n\n");


#print li-valid
printf("H_valid = %d ", H_valid);
#print validity for dynamic phases
printf("valid = ");
for i=1:num_phases
printf("%d ",valid(i));
endfor
printf("\n");

# print atomic matrix
printf("atomic matrix \n");
for i= 1:num_atoms
  for j = 1:num_phases
  printf("%1d ",a(i,j));
endfor
printf("\n");
endfor

#print nih
printf("H count = ");
for i = 1:num_phases
  printf(" %1d ",niH(i));
endfor
printf("\n");



# print constant variable
printf("constant variable is %s\n",const_var);  
printf("constant variable value is %d\n",const_var_value);  
printf("var_init is %d\n",var_init);
printf("steps is %d\n",steps);
printf("increment by %d\n\n",increment);
