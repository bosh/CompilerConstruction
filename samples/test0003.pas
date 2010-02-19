{
	This program checks to make sure that assignments are made only
	to instance variables & not type names. Every statement in
	main should produce an error, as well as the declaration of
	function foo.
}
	
program test0007;

type
  int = integer;

var
  i : integer;
  b : boolean;

function foo(x : integer) : i; forward;

procedure bar(x : int); forward;

begin
  int := 0;
  i := int;
  i := integer;
  integer := 0;
  false := b;
  true := b and false;
  bar(int);
  bar(integer)
end.

