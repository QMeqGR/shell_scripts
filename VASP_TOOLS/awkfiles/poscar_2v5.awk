@include "/home/ehm/awkfiles/awklib.awk"
BEGIN{

    # convert from v 4 to v 5
    # input must be in my common vasp format
    # with header line Z: z1 z2 ...
    #
    # v1.0  2 Oct 2015
    #

    done=0;
}

(NR==1){
    for(i=2;i<NF+1;i++){ z[i-1]=$i; nelms=NF-1; }
}
( NR!=1 || NR!=5 ){print $0}
( NR==5 && done==0 ){
    for(i=1;i<nelms+1;i++){
	printf(" %s ", ztoelm( z[i] ) );
    }
    printf("\n");
    done=1;
}


END{

}
