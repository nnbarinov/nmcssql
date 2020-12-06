create or replace function rubles (x in pls_integer)
return varchar2
as
a  pls_integer;
b  pls_integer;
begin
  a := mod(floor(x/10),10);
  b := mod(x,10);
  if a = 1 then
    return 'рублей';
  else
    if b = 1 then return 'рубль'; end if;
    if b > 1 and b < 5 then return 'рубля'; end if;
    return 'рублей';
  end if;
end;