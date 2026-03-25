create or replace function fc5ConverteNumberToChar(
                  pnValor      in Number,
                  pnInteiro    in Number default 10,
                  pnDecimal    in Number default 2)
return varchar2
is
  vsFormat  varchar2(50);
begin
  vsFormat := lpad('0', pnInteiro, '9') || 'D' || rpad('0', pnDecimal, '0');
  return (substr(trim(to_char(trunc(pnValor, pnDecimal), vsFormat, 'nls_numeric_characters=''.,''')),0,50));
end fc5ConverteNumberToChar;
