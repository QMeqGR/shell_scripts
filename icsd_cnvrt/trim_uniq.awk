# version 1.1 ehm 03 feb 2015, found this case and added dij code between
#                              the frac coords to cover it
#[ehm mnb2h8]$ wyckoff -s P_31_1_2 -x 0.1329 -y 0.8671 -z 0.33333333 
#    0.13290000000000    0.86710000000000    0.33333333000000
#    0.13290000000000    0.26580000000000    0.66666666333333
#    0.73420000000000    0.86710000000000    0.99999999666667
#    0.73420000000000    0.86710000000000    0.00000000333333
#
# lowered tolerance again to 1.001e-4
# 
# version 1.0...........
# ehm 12 jul 2008, lower tolerance to 1e-4 (FINDSYM output precision)
# ehm 01 nov 2006, increased output precision from 10 to 14 digits
# ehm 16 jan 2006
BEGIN{
  CONVFMT="%.15g";
  TOLER=1.001e-4;
  count=0;
  flags=0;
}

# functions
function fabs (a) {
    if ( a < 0.0 ) return ( -a );
    if ( a > 0.0 ) return (  a );
}
function tol (a,b,t) {
  rval=0;
  if ( ((a+t) > b) && ((a-t) < b) ) {rval=1;}
#  printf("a=%f b=%f t=%f a-b=%f b-a=%f rval=%d\n",a,b,t,a-b,b-a,rval);
  return rval;
}


(NF==3){
  x[count]=$1;
  y[count]=$2;
  z[count]=$3;
  flag[count]=0;
  count++;
}

END{
    # find repeats and flag them
    for(i=0;i<count;i++){
	for(j=0;j<i;j++){
#  printf("--- x= %f %f %f    y= %f %f %f\n",x[i],y[i],z[i],x[j],y[j],z[j]);
	    if ( tol(x[i],x[j],TOLER) &&
		 tol(y[i],y[j],TOLER) &&
		 tol(z[i],z[j],TOLER) ) {
		flag[i]=-1;
	    }
	    if ( tol(fabs(x[i]-x[j]), 1.0, TOLER) ) flag[i]=-1;
	    if ( tol(fabs(y[i]-y[j]), 1.0, TOLER) ) flag[i]=-1;
	    if ( tol(fabs(z[i]-z[j]), 1.0, TOLER) ) flag[i]=-1;
	}
    }
    
    for(i=0;i<count;i++){
	if ( flag[i] == -1 ) continue;
	printf("%20.14f%20.14f%20.14f\n",x[i],y[i],z[i]);
    }
    
}
