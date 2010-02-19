{
	This program checks type equivalence. It defines some
	equivalent named types, and then some equivalent anonymous
	records. 
	See the comments in main for which statements are correct and
	which are not.
}

program test0002;

type
   i = integer;
   j = i;
   k = j;
   h = integer;

   r = record
	   a : j;
	   b : string
   end;
   s = r;

   a = array[1..10] of s;
   b = a;

var
   r1 : record
	   a : k;
	   b : string
   end;
   r2,r3 : record
	   a : integer;
	   b : string
   end;
   r4,r5 : r;
   r6 : s;

   a1,a2 : array[1..10] of r;
   a3,a4 : a;
   a5    : b;
   a6    : array[1..10] of record a : integer; b : string end;

begin
   { these are correct }
    r1 := r2;
    r1 := r3;
    r2 := r3;

   { these are errors }
    r4 := r1;
    r4 := r2;
    r1 := r4;
    r2 := r4;
    r1 := r6;
    r6 := r1;

   { these are correct }
    r4 := r5;
    r4 := r6;
    r6 := r4;

   { these are correct }
    a1 := a2;
    a2 := a1;
    a3 := a4;
    a3 := a5;
    a5 := a3;

   { these are incorrect }
    a1 := a3;
    a3 := a1;
    a5 := a1;
    a1 := a5;
    a1 := a6;
    a6 := a2;
    a5 := a6;
    a6 := a4;

   { these are correct }
    a1[0] := r4;
    r5 := a2[0];
    a6[0] := r1;
    r3 := a6[0];    
	a3[0] := r4;
	r6 := a3[0];
	r5 := a3[0];

   { these are incorrect }
	a6[0] := r4;
    r6 := a6[0];
	r5 := a6[0]
end.

