BEGIN{

}

(NR==3){a1=$1; a2=$2; a3=$3;}
(NR==4){b1=$1; b2=$2; b3=$3;}
(NR==5){c1=$1; c2=$2; c3=$3;}

END{

  triple = c1*(a2*b3-a3*b2) + c2*(a3*b1-a1*b3) + c3*(a1*b2-a2*b1);

  printf("cell vol= %20.10f  [ang^3]\n",triple);

}
