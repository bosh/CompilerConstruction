{ 
	This program is used to check function return types to
	make sure they are not composite types.
	Functions foo() and foo2() both return composite types
	and should be flagged as an error. foo3() just returns
	a renaming of string and is correct. foo4() returns an
	anonymous composite type and should get flagged with
	an error during parsing.
}

program test0001;
type
	r = record
		a,b : integer;
		c   : string
	end;
	y = array[1..10] of integer;
	s = string;
var
	z : s;

function foo(a : integer) : r; { error here on return type }
begin
   a := 0
end;

function foo2(a : integer) : y; { error here on return type }
begin
	a := 0
end;

function foo3(a : integer) : s;
begin
	a := 0
end

begin
	z := foo3(3)
end.
