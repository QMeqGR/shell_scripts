# three2one.awk
# This awk file takes the output of
# wyckoff.awk, which is given in a single
# column file 'tmpout', with the format
# x1
# y1
# z1
# x2
# y2
# z2, etc...
#
# This awk program folds three rows into one
# line.  First it modulo's the elements
# back into the range (-1,1), and then
# re-centers them to be in [0,1)
#


# version 1.2    01 nov 2006
#                increased output precision from 10 to 14 digits
#
# version 1.1    15 Sep 2005
#                added the modulo code to
#                fix output like -1.234
#
# version 1.0
# June or Aug 2005
#

BEGIN{
  CONVFMT="%.15g";
  TOL=1e-9;
  count=0;
  debug=0;
}

function tolerance (A,B,T) {
  C = A-B;
  if ( C < 0.0 ) C *= -1.0;
  if ( C < T ) { return 1; }
  else { return 0; }
}

(NF==1){
  count++;
  if ( count==1 ) { a=$1; }
  if ( count==2 ) { b=$1; }
  if ( count == 3 ) {
    c=$1;

    if ( debug ) { printf("a_in= %f\n",a); }

    # bring them back into the first zone
    a = a%1.0;
    b = b%1.0;
    c = c%1.0;
    
    if ( a > 1.0 ) { a -= 1.0; }
    if ( a < 0.0 ) { a += 1.0; }
    if ( b > 1.0 ) { b -= 1.0; }
    if ( b < 0.0 ) { b += 1.0; }
    if ( c > 1.0 ) { c -= 1.0; }
    if ( c < 0.0 ) { c += 1.0; }

    if ( debug ) { printf("a_p1= %f\n",a); }

    # in case we have some output like
    # 0.5 1.0 0.0
    # 0.5 0.0 1.0
    if ( tolerance(a,1.0,TOL) ) { a -= 1.0; }
    if ( tolerance(b,1.0,TOL) ) { b -= 1.0; }
    if ( tolerance(c,1.0,TOL) ) { c -= 1.0; }

    if ( debug ) { printf("a_p2= %f\n",a); }

    printf("%20.14f%20.14f%20.14f\n",a,b,c);
    count=0;
  }
}

END{

}
