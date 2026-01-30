CREATE OR REPLACE Function fNFeFormaPagto (
                                             pnFinalidadeNFe        number,
                                             pnNFEntradaSaida       number, -- 0: Entrada || 1: Saída
                                             pnNroFormaPagto        number
                                                         )
Return varchar2
Is
vsInfPagto        varchar2(2);
vsConverteEspecie varchar(1);
Begin
              if pnNFEntradaSaida = 0 then -- Entrada
                 if pnFinalidadeNFe in ( 3, 4 ) then
                    vsInfPagto := '90'; -- Sem Pagamento
                 elsif pnFinalidadeNFe in ( 1, 2 ) then
                    vsInfPagto := '99'; -- Outros
                 end if;
           elsif pnNFEntradaSaida = 1 then -- Saída
                 if pnFinalidadeNFe in ( 1, 2 ) then
                     select max(a.especieformapagto)
                     into   vsConverteEspecie
                     from   mrl_formapagto a
                     where  a.nroformapagto = pnNroFormaPagto;
                     select case when vsConverteEspecie = 'D' then -- Dinheiro
                                      '01'
                                 when vsConverteEspecie = 'C' then -- Cheque
                                      '02'
                                 when vsConverteEspecie = 'R' then -- Cartão de Crédito
                                      '03'
                                 when vsConverteEspecie = 'E' then -- Cartão de Débito
                                      '04'
                                 when vsConverteEspecie = 'P' then -- Cartão Próprio (loja)
                                      '05'
                                 when vsConverteEspecie = 'T' then -- Ticket Alimentação (vale alimentação)
                                      '10'
                                 when vsConverteEspecie = 'Y' then -- Cartão Presente
                                      '12'
                                 when vsConverteEspecie = 'B' then -- Boleto
                                      '15'
                                 when vsConverteEspecie = 'H' then -- Depósito Bancário
                                      '16'
                                 when vsConverteEspecie = 'J' then -- Pagamento Instantâneo (PIX)
                                      '17'
                                 when vsConverteEspecie = 'K' then -- Transferência bancária, Carteira Digital
                                      '18'
                                 when vsConverteEspecie = 'L' then -- Programa de fidelidade, Cashback, Crédito Virtual
                                      '19'
                                 when vsConverteEspecie = 'M' then -- Sem Pagamento
                                      '90'
                                 when vsConverteEspecie is null then -- Sem Pagamento
                                      '90'
                                 else
                                      '99'                           -- Outros
                             end
                     into vsInfPagto
                     from dual;
                 
                 elsif pnFinalidadeNFe in ( 3, 4 ) then
                       vsInfPagto := '90'; -- Sem Pagamento
                 end if;
             else
                  vsInfPagto := '99'; -- Outros
             end if;
             
                 -- Alt Giuliano 30/01/2026 --
                 -- Cart Credito
                 IF pnNroFormaPagto IN (51,50,56,53) THEN
                   vsInfPagto := '03';
                 -- PIX
                 ELSIF pnNroFormaPagto IN (36) THEN
                   vsInfPagto := '17';
                 END IF;
                 ---------------------------
                 
Return (vsInfPagto);
End fNFeFormaPagto;
