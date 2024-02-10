# wyckoff.awk
#
# This program works by parsing the output
# of sginfo "spacegroup" -allxyz
#
# use: bash$ sginfo "R -3 m" -allxyz | awk -f ~/awkfiles/wyckoff.awk \
#            -v X=0.1234 -v Y=0.2345 -v Z=0.3456
#
# Program steps:
#
# 1. Parses the X,Y,Z values in the case they were put
# in as fractions like 1/3, etc... and turns them into 0.3333333333.
#
# 2. Parses the output of sginfo, so each position looks like
#    -y-1/3
#
# 3. Re-centers the input, and substitutes the X,Y,Z values in the
#    parsed sginfo output.  The recentering is done to avoid
#    substitutions that look like: --0.2345-1/3.  This would
#    instead be transformed to -0.7655-1/3.
#
# 4. Puts the output in file 'tmpout' for further work.
#    (to be done by three2one.awk)
#

# version 1.1   01 Nov 2006
#               increased output digits from 10 to 15
#
# version 1.0   06 jul 2005
# e. majzoub
#

BEGIN{
  CONVFMT="%.15g";
  linecnt=0;
  count=0;
  flag=0;
  vmflag=0;
  wflag=0;
  modlines=0;
  linenum =1000000;
  vmline  =1000000;

# if X,Y,Z is input as fraction, then unravel the
# text and put it in floating point.

  if ( X ~ /\// ) {
    match(X,/\//);
    before = substr(X,0,RSTART-1);
    after = substr(X,RSTART+1);
    X = before/after;
  }
  if ( Y ~ /\// ) {
    match(Y,/\//);
    before = substr(Y,0,RSTART-1);
    after = substr(Y,RSTART+1);
    Y = before/after;
  }
  if ( Z ~ /\// ) {
    match(Z,/\//);
    before = substr(Z,0,RSTART-1);
    after = substr(Z,RSTART+1);
    Z = before/after;
  }
}

# find the Vector Modulus output line in the file,
# this is almost the last thing that is output before the
# xyz positions.
($0 ~ /Vector/ && $0 ~ /Modulus/){
  vmline=NR;
  vmflag=1;
#  print "vmline="vmline;
}

# keep setting a new value for modlines if we are
# still going through those values
(NF==4 && vmflg==1){
  modlines=NR;
}

# when we hit the first blank line after vec mod lines
# set the warn flag
($0=="" && NR>modlines && vmflag){
  wflag=1;
}


# if we hit a hash mark line, then we can set the flag flag
# and begin reading in the stuff we're interested in.
# the hash marks set aside the position markers for each
# translational set of the minimum equivalent positions.
($1~/#/ && $0 !~ /sginfo/) {

 count++;
 flag=1;
 linenum=NR;
 
 for (i=0; i<3; i++) a[i]=$(i+2);
 
# get rid of left (
 match(a[0],/\(/);
 a[0] = substr(a[0],RSTART+1);
 
 
# get rid of right )
 match(a[2],/\)/);
 a[2] = substr(a[2],0,RSTART-1);
 
# print "line="linenum,"position: ",a[0],a[1],a[2];
}

# READ IN THE GOOD STUFF
# if we hit hashed lines then flag flag will be set
# if we hit no hashed lines then flag wflag will be set
($1 !~ /#/ && NR>modlines && (flag || wflag) && $0!="") {
 n=split($0,b,",");
 # this puts things in b[1],b[2],b[3]

 if ( X < 0.0 ) { X += 1.0; }
 if ( X > 1.0 ) { X -= 1.0; }
 if ( Y < 0.0 ) { Y += 1.0; }
 if ( Y > 1.0 ) { Y -= 1.0; }
 if ( Z < 0.0 ) { Z += 1.0; }
 if ( Z > 1.0 ) { Z -= 1.0; }

 sub(/x/,X,b[1]);
 sub(/y/,Y,b[1]);
 sub(/z/,Z,b[1]);
 sub(/x/,X,b[2]);
 sub(/y/,Y,b[2]);
 sub(/z/,Z,b[2]);
 sub(/x/,X,b[3]);
 sub(/y/,Y,b[3]);
 sub(/z/,Z,b[3]);

# print b[1], b[2], b[3];

 system("echo "b[1]" | bc -l >> tmpout");
 system("echo "b[2]" | bc -l >> tmpout");
 system("echo "b[3]" | bc -l >> tmpout");

}

END{

}
