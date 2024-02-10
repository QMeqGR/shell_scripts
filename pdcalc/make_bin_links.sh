#!/bin/bash

PDCALC=$HOME/src/pdcalc
BIN=$HOME/bin

namelist="pd_prep_data pd_calc find_dG_zero get_bader_charges get_born_charges make_cv_fits make_named_symlinks make_table_ave_charg rxn_thermo toten_at_T vib_energy"

for name in $namelist; do
    ln -sf $PDCALC/$name.sh $BIN/$name
done
