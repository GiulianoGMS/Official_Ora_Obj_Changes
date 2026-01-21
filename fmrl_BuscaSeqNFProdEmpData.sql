create or replace function fmrl_BuscaSeqNFProdEmpData
      (
       pnSeqProduto        IN NUMBER,
       pdDataBase          IN DATE,
       pnNroEmpresa        IN NUMBER,
       psTipoNF            IN VARCHAR2
      )
return number is
  Result NUMBER;
  seq_Retorno NUMBER;
  seq_Remessa NUMBER;
  vnSeqNFUltEntrada number;
  vnSeqNFUltEntCompra number;
begin
     -- Busca ultima entrada
     select max(decode(psTipoNF,'R',a.seqnfultenttransf,a.seqnf))
     into   Result
     from   mrl_ProdEmpDtaSeqNFEntr a, mlf_notafiscal b
     where  a.seqnf           = b.seqnf and
            a.seqproduto      = pnSeqProduto and
            a.dtaentradasaida = pdDataBase and
            a.nroempresa      = pnNroEmpresa and
            case
            when psTipoNF = 'E' OR
                 ( psTipoNF = 'U' and a.indnfentrcusto = 'S') OR
                 ( psTipoNF = 'C' and a.indnfentrcompra = 'S') OR
                 ( psTipoNF = 'T' and a.indnfentrcompracusto = 'S') OR
                 ( psTipoNF = 'B' and a.indnfentrcomprareceb = 'S') OR
                 ( psTipoNF = 'D' and a.Indnfentricmsst = 'S') OR
                 ( psTipoNF in ('G','R','X') and a.indnfentrcomprageral = 'S')
            then 1
            else 0
            end = 1
            and a.seqnf not in (select seqselecao from maxx_selecrowid);
     If Result is Null Then
        select max(decode(psTipoNF,'R',a.seqnfultenttransf,a.seqnf))
        into   Result
        from   mrl_ProdEmpDtaSeqNFEntr a, mlf_notafiscal b
        where  a.seqnf           = b.seqnf and
               a.seqproduto      = pnSeqProduto and
               a.dtaentradasaida = ( select max(x.dtaentradasaida)
                                     from   mrl_ProdEmpDtaSeqNFEntr x
                                     where  x.seqproduto = a.seqproduto and
                                            x.dtaentradasaida between pdDataBase - 30 and pdDataBase and
                                            x.nroempresa = a.nroempresa and
                                            case
                                            when psTipoNF = 'E' OR
                                                 ( psTipoNF = 'U' and x.indnfentrcusto = 'S') OR
                                                 ( psTipoNF = 'C' and x.indnfentrcompra = 'S') OR
                                                 ( psTipoNF = 'T' and x.indnfentrcompracusto = 'S') OR
                                                 ( psTipoNF = 'B' and x.indnfentrcomprareceb = 'S') OR
                                                 ( psTipoNF = 'D' and x.Indnfentricmsst = 'S') OR
                                                 ( psTipoNF in ('G','R','X') and x.indnfentrcomprageral = 'S')
                                            then 1
                                            else 0
                                            end = 1 and
                                            x.seqnf not in (select seqselecao from maxx_selecrowid)
                                   ) and
               a.nroempresa      = pnNroEmpresa and
               case
               when psTipoNF = 'E' OR
                    ( psTipoNF = 'U' and a.indnfentrcusto = 'S') OR
                    ( psTipoNF = 'C' and a.indnfentrcompra = 'S') OR
                    ( psTipoNF = 'T' and a.indnfentrcompracusto = 'S')  OR
                    ( psTipoNF = 'B' and a.indnfentrcomprareceb = 'S') OR
                    ( psTipoNF = 'D' and a.Indnfentricmsst = 'S') OR
                    ( psTipoNF in ('G','R','X') and a.indnfentrcomprageral = 'S')
               then 1
               else 0
               end = 1
               and a.seqnf not in (select seqselecao from maxx_selecrowid);
        If Result is Null  Then
           select max(decode(psTipoNF,'R',a.seqnfultenttransf,a.seqnf))
           into   Result
           from   mrl_ProdEmpDtaSeqNFEntr a, mlf_notafiscal b
           where  a.seqnf           = b.seqnf and
                  a.seqproduto      = pnSeqProduto and
                  a.dtaentradasaida = ( select max(x.dtaentradasaida)
                                        from   mrl_ProdEmpDtaSeqNFEntr x
                                        where  x.seqproduto = a.seqproduto and
                                               x.dtaentradasaida <= pdDataBase and
                                               x.nroempresa = a.nroempresa and
                                               case
                                               when psTipoNF = 'E' OR
                                                    ( psTipoNF = 'U' and x.indnfentrcusto = 'S') OR
                                                    ( psTipoNF = 'C' and x.indnfentrcompra = 'S') OR
                                                    ( psTipoNF = 'T' and x.indnfentrcompracusto = 'S') OR
                                                    ( psTipoNF = 'B' and x.indnfentrcomprareceb = 'S') OR
                                                    ( psTipoNF = 'D' and x.Indnfentricmsst = 'S') OR
                                                    ( psTipoNF in ('G','R','X') and x.indnfentrcomprageral = 'S')
                                               then 1
                                               else 0
                                               end = 1 and
                                               x.seqnf not in (select seqselecao from maxx_selecrowid)
                                      ) and
                  a.nroempresa     = pnNroEmpresa and
                  case
                  when psTipoNF = 'E' OR
                       ( psTipoNF = 'U' and a.indnfentrcusto = 'S') OR
                       ( psTipoNF = 'C' and a.indnfentrcompra = 'S') OR
                       ( psTipoNF = 'T' and a.indnfentrcompracusto = 'S') OR
                       ( psTipoNF = 'B' and a.indnfentrcomprareceb = 'S') OR
                       ( psTipoNF = 'D' and a.Indnfentricmsst = 'S') OR
                       ( psTipoNF in ('G','R','X') and a.indnfentrcomprageral = 'S')
                  then 1
                  else 0
                  end = 1
                  and a.seqnf not in (select seqselecao from maxx_selecrowid);
        End If;
     End IF;
     if psTipoNF in ( 'G', 'X' ) then
        vnSeqNFUltEntCompra := Result;
        vnSeqNFUltEntrada := fmrl_BuscaSeqNFProdEmpData(pnSeqProduto,
                                                          pdDataBase,
                                                          pnNroEmpresa,
                                                          'R');
        if nvl(vnSeqNFUltEntrada,0) > nvl(vnSeqNFUltEntCompra,0) then
           select max(a.seqnf)
           into   Result
           from   mrl_ProdEmpDtaSeqNFEntr a, mlf_notafiscal b
           where  a.seqnf           = b.seqnf
           and    a.seqproduto      = pnSeqProduto
           and    a.nroempresa      = pnNroEmpresa
           and    a.seqnfultenttransf = vnSeqNFUltEntrada
           and    a.seqnf not in (select seqselecao from maxx_selecrowid);
        end if;
     end if;
     -- Busca entrada por bonificação caso não haja entrada por compra
     if Result is null and psTipoNF = 'X' then
       select max( a.seqnf )
         into Result
         from mlf_notafiscal a, max_codgeraloper b, mlf_nfitem c
        where a.codgeraloper = b.codgeraloper
          and a.numeronf = c.numeronf
          and a.seqnf = nvl(c.seqnf, a.seqnf)
          and a.serienf = c.serienf
          and a.nroempresa = c.nroempresa
          and a.seqpessoa = c.seqpessoa
          and a.tipnotafiscal = c.tipnotafiscal
          and b.tipdocfiscal in ( 'C', 'O' )
          and b.tippedidocompra in ( 'E', 'B', 'V' )
          and a.tipnotafiscal = 'E'
          and nvl( c.seqprodutobase, c.seqproduto ) = pnSeqProduto
          and a.nroempresa = pnNroEmpresa
          and c.quantidade > 0
          and a.seqnf not in (select seqselecao from maxx_selecrowid);
     end if;
     -- Adicionado para pegar nota de remessa
     -- Giuliano 18/01/2025
     IF psTipoNF IN ('D','U') THEN
        SELECT MAX(SEQNF_2)
          INTO seq_Remessa
          FROM NAGT_NF_RELAC_REMESSA_V2 NAG WHERE NAG.SEQNF_1 = Result;
     END IF;
     
     seq_Retorno := NVL(seq_Remessa, Result);
     
     return(seq_Retorno);
Exception
  When NO_DATA_FOUND Then
       Result := NULL;
       return(Result);
  When OTHERS Then
       raise_application_error(-20020, 'Erro ao buscar ultima nota de entrada.');
end fmrl_buscaseqnfprodempdata;
