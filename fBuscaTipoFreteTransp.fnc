CREATE OR REPLACE Function fBuscaTipoFreteTransp(pnSeqNotafiscal     in  mfl_doctofiscal.seqnotafiscal%type,
                                                 pnNroCarga          in  mrl_cargaexped.nrocarga%type,
                                                 pnNroEmpresa        in  mrl_cargaexped.nroempresa%type,
                                                 psTipoFrete         in  mfl_doctofiscal.tipofrete%type,
                                                 pnSeqTransportador  in  mad_transportador.seqtransportador%type
                                                )
Return Varchar2
Is
  vsEMITE_TRANSPOR_CIF            max_parametro.valor%type;
  vsGeraFreteTipoEntrega          max_parametro.valor%type;
  vsRet                           mlf_notafiscal.tipfretetransp%type;
  vsTipEntrega                    mrl_cargaexped.tipentrega%type;
  vsIndTipoTransportador          mad_transportador.indtipotransportador%type;
  vsAppOrigem                     MFL_DOCTOFISCAL.APPORIGEM%TYPE;
  vsIndTranspPDV                  max_parametro.valor%type;
Begin
  -- busca PDs
  select fc5maxparametro('EXPORT_NFE', pnNroEmpresa, 'EMITE_TRANSPORTADOR_CIF'),
         fc5maxparametro('EXPORT_NFE', pnNroEmpresa, 'GERA_FRETE_TIPO_ENTREGA_PED'),
         fc5maxparametro('NAGUMO', 0, 'PDV_INDTRANSPORTE')
  into   vsEMITE_TRANSPOR_CIF,
         vsGeraFreteTipoEntrega,
         vsIndTranspPDV
  from   dual;
  -- busca informações da carga
  select nvl(MAX(A.TIPENTREGA),'E'), MAX(B.APPORIGEM)
  into   vsTipEntrega, vsAppOrigem
  from   MRL_CARGAEXPED A,
         MFL_DOCTOFISCAL  B
  where  A.NROCARGA = B.NROCARGA
  and    B.SEQNOTAFISCAL = pnSeqNotaFiscal;
  -- busca informações do transportador se houver
  SELECT MAX(A.INDTIPOTRANSPORTADOR)
  into   vsIndTipoTransportador
  FROM   MAD_TRANSPORTADOR A
  WHERE  A.SEQTRANSPORTADOR = pnSeqTransportador ;
  -- Regras para retorno do tipo de frete
  if vsGeraFreteTipoEntrega = 'S' and pnNroCarga > 0 and vsTipEntrega = 'E' then
     vsRet := 0 ;
  elsif vsGeraFreteTipoEntrega = 'S' and pnNroCarga > 0 and vsTipEntrega = 'R' then
     vsRet := 1 ;
  elsif psTipoFrete = 'C' and vsEMITE_TRANSPOR_CIF = 'S' AND pnSeqTransportador IS NOT NULL  then
     vsRet := 0 ;
  else
/*
0 = C(Padrão) - Contratação do Frete por conta do Remetente (CIF)
1 = F - Contratação do Frete por conta do Destinatário (FOB)
2 = T - Contratação do Frete por conta de Terceiros
3 = R - Transporte Próprio por conta do Remetente
4 = D - Transporte Próprio por conta do Destinatário
*/
    if psTipoFrete = 'C' then
        vsRet := 0;
    elsif psTipoFrete = 'F' then
        vsRet := 1;
    elsif psTipoFrete = 'T' then
        vsRet := 2;
    elsif psTipoFrete = 'R' then
        vsRet := 3;
    elsif psTipoFrete = 'D' then
        vsRet := 4;
    else
      -- Giuliano 22/06
        IF vsAppOrigem = 7 THEN
             vsRet := vsIndTranspPDV;
        ELSE vsRet := 9;
        END IF;
        
    end if;
  end if;
  Return vsRet;
Exception
  When Others Then
    Raise_Application_Error(-20000, Sqlerrm);
End fBuscaTipoFreteTransp;
