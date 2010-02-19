{**********************************************************************
  This small program tests the use of type definitions of arrays, booleans, and
integers.  It also tests the use of forward declarations of functions, etc.
**********************************************************************}

program foo;

type
  b1 = boolean;
  index = integer;
  vector = array [1..10] of integer;

var
  i:index;
  x,y:vector;

function f2 (x,y,z:boolean; a,b:vector):integer; forward;

function f1 (w,x,y,z:b1; a,b,c:vector):integer;

var
  i:index;
  result:vector;
  sum:integer;

begin
  for i:=1 to 10 do
    if i mod 2 = 1 then
      result [i] := f2 (w,x,y,a,b)
    else
      result [i] := f2 (x,y,z,b,c);
  for i:= 1 to 10 do
    sum := sum + result[i];
  f1:=sum
end;

{ Note that I changed the parameter names from the forward declaration }
function f2 (a,b,c:boolean; x,y:vector):integer;
var
  i:index;
  result:vector;
  sum:integer;

begin
  for i:=1 to 10 do
    if a or b and c then
      result[i]:=f1(a,a,b,c,x,x,y)
    else
      result[i]:=f1(a,b,c,c,x,y,y);
  for i:=1 to 10 do
    sum := sum + result[i];
  f2:=sum
end;

begin
  for i:=1 to 10 do
    begin
      x[i]:=i;
      y[i]:=i
    end
end.
