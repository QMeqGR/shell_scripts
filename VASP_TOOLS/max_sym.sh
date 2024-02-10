#!/bin/bash

infile=$1;
posname=$infile;
TOLERANCE=0.25; # max rms displacement for high tolerance

function make_awkscript(){

cat > highsym.awk <<EOF

BEGIN{
sg=1;
line="";
#tol; set tolerance on command line
savtol=0; # this is the tolerance we want to generate the poscar 
}
(NF==7 && \$2!~"error"){
if ( \$3 > sg && \$7<tol ) {sg=\$3; spg=\$5; line=\$0; savtol=\$7;}
}
END{
printf("%.3f %d %s",savtol,sg,spg);
}
EOF

}

if [ ! -x `which symsearch` ]; then
    echo "Can't find symsearch in max_sym.sh. Exiting."
    exit
fi

symsearch -f $posname -H >& tmp.symsearch.out;
make_awkscript;
hsymtol=`cat tmp.symsearch.out | igawk -f ./highsym.awk -v tol=$TOLERANCE`;
echo $hsymtol;
logicalHS=`echo $hsymtol | awk '(NF==1){hs=$1;}END{if(hs>0.0){print 1}else{print 0}}'`;

rm -f highsym.awk tmp.symsearch.out;

exit
