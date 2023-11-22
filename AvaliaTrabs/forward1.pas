Program Maximum_Minimum_Number(output);

var 
    res: integer;

function max(num1, num2: integer): integer; forward;

function min(bnum1, bnum2: integer): integer;
var
   bresult: integer;

begin
   if bnum1 > bnum2 then
      bresult := bnum2
   else
      bresult := bnum1;
   min := bresult
end;


function max(num1, num2: integer): integer;
var
   result: integer;

begin
   if num1 > num2 then
      result := num1
   else
      result := num2;
   max := result
end;

begin
  res := max(5,10);
  writeln(res);
  res := min(1, 2);
  writeln(res)
end.
