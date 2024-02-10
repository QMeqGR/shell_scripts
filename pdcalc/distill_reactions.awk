BEGIN{

    printf("dH, ,dH2, wtpct, T[C],rxn\n");
}

(NF>0 && $1!="dH="){
saveline=$0;lnum=NR;
}
(NR==(lnum+1) && $1=="dH=" && $2>0.0 && $6>0.0){
    dh=$2; typ1=$3; typ12=$4; dh2=$6; wtpct=$8; temp=$12;
    printf("%.1f,%s %s,%.1f,%.1f,%4d,%s\n",dh,typ1,typ12,dh2,wtpct,temp,saveline);
#printf("%s %s\n",$0,saveline);
}

END{

}
