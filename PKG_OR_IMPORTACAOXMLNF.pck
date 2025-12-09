create or replace package body PKG_OR_IMPORTACAOXMLNF is
vsUsuario VARCHAR2(20);
vsUFEmpresa VARCHAR2(2);
vsUFFornecedor VARCHAR2(2);
vnSeqFornecedor NUMBER;
/*                                 *
 *   INICIA PROCESSO DE IMPORTAÇÃO *
 *                                 */
PROCEDURE ORP_INICIAIMPORTACAO(pnNroEmpresa IN NUMBER, psUsuario IN VARCHAR2)
IS
  vnInconsistenciaNF NUMBER;
  vnInconsistenciaItem NUMBER;
  vnNroMatriz NUMBER;
  vnNroEmpresaOrc NUMBER;
  vnSeqNota NUMBER;
  vsExigeItensNF VARCHAR2(1);
  vsNotaTransf VARCHAR2(1);
  vnCount NUMBER;
BEGIN
 begin
     vsUsuario:= psUsuario;
     --Obtém a matriz da empresa
     SELECT  E.MATRIZ
     INTO    vnNroMatriz
     FROM    GE_EMPRESA E
     WHERE   E.NROEMPRESA = pnNroEmpresa;
     --Obtém a empresa orçamentária
     SELECT P.NROEMPRESAORC
     INTO   vnNroEmpresaOrc
     FROM   OR_PARAMETRO P
     WHERE  P.NROEMPRESA = pnNroEmpresa;
     --Obtém a UF da empresa
     SELECT  E.ESTADO
     INTO    vsUFEmpresa
     FROM    GE_EMPRESA E
     WHERE   E.NROEMPRESA = pnNroEmpresa;
     --Obtém a relação de NFs a serem importadas de acordo com os filtros da aplicação
     FOR cur_nota in (SELECT A.IDNF, B.NATDESP, A.CNPJDESTINATARIO, NVL(A.TIPOIMP,'X') TIPOIMP,
                             A.SEQFORNECEDOR, A.CNPJEMITENTE
                      FROM   ORV_IMPORTACAO_NF_XML A,
                             ORX_NFSELIMPORTACAO B
                      WHERE  A.IDNF = B.IDNF
                        AND  NVL(A.TIPOIMP,'X') = NVL(B.TIPOIMP,'X')
                     )
     LOOP
        --Obtendo seqpessoa (fornecedor)
        vnSeqFornecedor := ORF_OBTEMFORNECEDOR(cur_nota.SEQFORNECEDOR, cur_nota.CNPJEMITENTE);
        --Verifica Nat Desp com Itens da NF
        select nvl(p.exigeitensnota, 'N')
          into vsExigeItensNF
          from rfv_paramnatnfdesp p
         where p.codhistorico = cur_nota.natdesp
           and p.nroempresa = vnNroMatriz;
        --Verifica se é nota de transferência/Venda coligada
        SELECT COUNT(1)
        INTO vnCount
        FROM ORV_IMPORTACAO_NF_XML A, MAX_EMPRESA B
        WHERE A.SEQFORNECEDOR = B.SEQPESSOAEMP
        AND A.TIPOIMP = 'X'
        AND A.IDNF = cur_nota.idnf;
        IF vnCount > 0 THEN
           vsNotaTransf:= 'S';
        ELSE
           vsNotaTransf:= 'N';
        END IF;
        --Contador de inconsistência da NF / Itens
        vnInconsistenciaItem:= 0;
        --Exclui as inconsistências da NF (e dos itens)
        delete from OR_INCONSIST_IMPORT_XML
               where IDNF = cur_nota.Idnf
                 and NVL(TIPOIMP,'X') = cur_nota.tipoimp;
        commit;
        -- deletando os produtos da tabela temporária identifcados por CFOP
        DELETE FROM ORX_IMPNFEPRODUTOITEM;
        --Verifica as inconsistências da NF (e insere na tabela se houver)
        vnInconsistenciaNF:= ORF_INCONSISTENCIANF(cur_nota.idnf, cur_nota.natdesp, pnNroEmpresa, vnNroMatriz, cur_nota.tipoimp);
        --Verifica as inconsistências dos Itens
        If vsExigeItensNF = 'S' Then
           vnInconsistenciaItem:= ORF_INCONSISTENCIAITEM(cur_nota.idnf, cur_nota.natdesp, pnNroEmpresa, vnNroMatriz, cur_nota.tipoimp,vnNroEmpresaOrc, vsNotaTransf);
        End If;
        --Se a NF e os itens estiverem OK, insere
        If vnInconsistenciaNF = 0 And vnInconsistenciaItem = 0 Then
           ORP_IMPORTANF(cur_nota.idnf, cur_nota.natdesp, pnNroEmpresa, vnNroMatriz, vnNroEmpresaOrc, vnSeqNota, cur_nota.tipoimp, vsNotaTransf);
           If vsExigeItensNF = 'S' Then
              ORP_IMPORTAITEM(cur_nota.idnf, cur_nota.natdesp, pnNroEmpresa, vnNroEmpresaOrc, vnSeqNota, vnNroMatriz, cur_nota.tipoimp);
           End If;
        End If;
        --Há um parâmatro que indica se a NF será deletada da TMP.
        --Neste caso, foi feito um tratamento no painel de importação que verifica a existência da NF na tabela do orçamento e na
        -- tabela TMP (importação) por meio da chave de acesso, se existir, a NF não é exibida no painel.
     end loop;
 exception
    when  others then
          raise_application_error (-20200, sqlerrm );
 End;
END ORP_INICIAIMPORTACAO;
--  FIM DO PROCESSO DE IMPORTAÇÃO --
-- INSERE INCONSISTÊNCIA --
PROCEDURE ORP_INSERE_INCONSISTENCIA(pnIDNFe        IN NUMBER,
                                    pnNatDesp      IN OR_NFDESPESA.CODHISTORICO%TYPE,
                                    pnIDItem       IN TMP_M014_ITEM.M014_ID_ITEM%TYPE,
                                    psMotivo       IN OR_INCONSIST_IMPORT_XML.MOTIVO%TYPE,
                                    psTipoImp      IN VARCHAR2)
IS
  vnSeqIncons number;
BEGIN
     select S_OR_INCONSIST_IMPORT_XML.NEXTVAL
     into   vnSeqIncons
     from dual;
     insert into OR_INCONSIST_IMPORT_XML(SEQINCONSISTENCIA, IDNF, IDITEM, NATDESP, MOTIVO, TIPOIMP)
     values (vnSeqIncons, pnIDNFe, pnIDItem, pnNatDesp, psMotivo, psTipoImp);
     commit;
END ORP_INSERE_INCONSISTENCIA;
-- INCONSISTENCIA NF --
FUNCTION ORF_INCONSISTENCIANF(pnIDNFe        IN NUMBER,
                              pnNatDesp      IN OR_NFDESPESA.CODHISTORICO%TYPE,
                              pnNroEmpresa   IN NUMBER,
                              pnNroMatriz    IN NUMBER,
                              psTipoImp      IN VARCHAR2)
RETURN NUMBER
IS
  vnContInconsistencia    NUMBER;
  vnCont                  NUMBER;
  vsMensagemRetorno       VARCHAR2(300);
  vsVerificaNFServ        VARCHAR2(1);
  --Nat Desp
  vsExigeItensNF          VARCHAR2(1);
  vnSeqPessoa             GE_PESSOA.SEQPESSOA%TYPE;
  vsMSGNFE                VARCHAR2(50);
  vnExisteNota            NUMBER;
  vnSeqTransportador      GE_PESSOA.SEQPESSOA%TYPE;
BEGIN
  vnContInconsistencia:= 0;
  vnCont:= 0;
  --Verifica se fornecedor(emitente) está cadastrado
  select count(1)
  into   vnCont
  from   ge_pessoa p, orv_importacao_nf_xml n
  where  p.nrocgccpf = to_number(substr(n.CNPJEMITENTE, 1, 12))
  and    p.digcgccpf = to_number(substr(n.CNPJEMITENTE, 13, 2))
  and    n.IDNF = pnIDNFe
  and    NVL(n.TIPOIMP,'X') = psTipoImp;
  If vnCont = 0 Then
    ORP_INSERE_INCONSISTENCIA(pnIDNFe, pnNatDesp, null, 'O Fornecedor desta Nota Fiscal não está cadastrado!', psTipoImp);
  End if;
  --Verifica o controle do orçamento
  If Not orf_verifica_controle_orc(pnIDNFe, pnNroEmpresa, vsMensagemRetorno, psTipoImp) Then
     ORP_INSERE_INCONSISTENCIA(pnIDNFe, pnNatDesp, null, vsMensagemRetorno, psTipoImp);
  End if;
  --Verifica Nat Desp com Itens da NF
  select nvl(p.exigeitensnota, 'N')
  into   vsExigeItensNF
  from   rfv_paramnatnfdesp p
  where  p.codhistorico = pnNatDesp
  and    p.nroempresa = pnNroMatriz;
  select count(1)
  into   vnCont
  from   orv_importacao_item_xml i
  where  i.IDNF = pnIDNFe
    AND  NVL(i.TIPOIMP,'X') = psTipoImp;
    --Verifica se é uma NFSe
    select nvl(j.INDIMPORTANFSE, 'N'), j.SEQTRANSPORTADOR
    into   vsVerificaNFServ, vnSeqTransportador
    from   orv_importacao_nf_xml j
    where  j.IDNF = pnIDNFe;
  If vsExigeItensNF = 'S' and vnCont = 0 and vsVerificaNFServ = 'N' Then
     ORP_INSERE_INCONSISTENCIA(pnIDNFe, pnNatDesp, null, 'A Natureza de despesa exige itens, porém não há itens para esta NF.', psTipoImp);
  End if;
  --Verifica se a NF já está cadastrada
  select count(1)
  into   vnCont
  from   ge_pessoa p,
         orv_importacao_nf_xml n,
         or_nfdespesa d
  where  d.seqpessoa = p.seqpessoa
  and    p.nrocgccpf = to_number(substr(n.CNPJEMITENTE, 1, 12))
  and    p.digcgccpf = to_number(substr(n.CNPJEMITENTE, 13, 2))
  and    d.nronota = n.NUMERONF
  and    d.serie   = n.SERIE
  and    n.IDNF = pnIDNFe
  and    NVL(n.TIPOIMP,'X') = psTipoImp
  and    d.nroempresa = pnNroEmpresa
  and    d.codmodelo = n.modelo;
  If vnCont > 0 Then
    ORP_INSERE_INCONSISTENCIA(pnIDNFe, pnNatDesp, null, 'Esta NF já foi importda/digitada.', psTipoImp);
  End if;
  -- RC 191554 Verifica se a nota já foi lançada no recebimenro
  vnSeqPessoa := 0;
  SELECT NVL(MAX(P.SEQPESSOA),0)
  INTO   vnSeqPessoa
  FROM   GE_PESSOA P,
         ORV_IMPORTACAO_NF_XML N
 WHERE   P.NROCGCCPF = TO_NUMBER(SUBSTR(N.CNPJEMITENTE, 1, 12))
   AND   P.DIGCGCCPF = TO_NUMBER(SUBSTR(N.CNPJEMITENTE, 13, 2))
   AND   N.IDNF = pnIDNFe
   AND   NVL(N.TIPOIMP,'X') = psTipoImp;
  IF vnSeqPessoa != 0 THEN
     BEGIN
          SELECT NVL(FMLF_EXISTENOTA( pnNroEmpresa,A.NUMERONF, A.SERIE, vnSeqPessoa, TRUNC(A.DTAEMISSAO), A.CHAVEACESSO ),0),
                 'número: ' || A.NUMERONF || ', série: ' || A.SERIE
          INTO   vnExisteNota,
                 vsMSGNFE
          FROM   ORV_IMPORTACAO_NF_XML A
          WHERE  A.IDNF = pnIDNFe;
     EXCEPTION
          WHEN NO_DATA_FOUND THEN
               vnExisteNota := 0;
     END;
     IF vnExisteNota > 0 THEN
        ORP_INSERE_INCONSISTENCIA(
               pnIDNFe,
               pnNatDesp,
               NULL,
               'A nota fiscal ' || vsMSGNFE || ' já foi lançada pelo módulo de Recebimento de Notas.',
               psTipoImp);
     END IF;
  END IF;
  IF vnSeqTransportador IS NOT NULL THEN
    SELECT COUNT(1)
      INTO vnCont
	    FROM GE_PESSOA A, MAD_TRANSPORTADOR B
	   WHERE A.SEQPESSOA = vnSeqTransportador
	     AND A.SEQPESSOA = B.SEQTRANSPORTADOR;
     IF vnCont = 0 THEN
        ORP_INSERE_INCONSISTENCIA(
               pnIDNFe,
               pnNatDesp,
               NULL,
               'O Transportador:' || to_char(vnSeqTransportador) ||' não está cadastrado',
               psTipoImp);
     END IF;
  END IF;
-- Verifica o nº de inconsistências existentes
  select count(1)
  into   vnContInconsistencia
  from   or_inconsist_import_xml n
  where  n.idnf = pnIDNFe
    and  NVL(n.tipoimp,'X') = psTipoImp;
  return vnContInconsistencia;
END ORF_INCONSISTENCIANF;
-- IMPORTA NF --
PROCEDURE ORP_IMPORTANF(pnIDNFe         IN  NUMBER,
                        pnNatDesp       IN  OR_NFDESPESA.CODHISTORICO%TYPE,
                        pnNroEmpresa    IN  NUMBER,
                        pnNroMatriz     IN  NUMBER,
                        pnNroEmpresaOrc IN  NUMBER,
                        pnSeqNota       OUT NUMBER,
                        psTipoImp       IN VARCHAR2,
                        psNotaTransf     IN VARCHAR2)
IS
 vnCGO                  NUMBER;
 vnVersaoPessoa         NUMBER;
 vdDtaVencDuplicata     DATE;
 vsCodSitDoc            GE_PARAMDINAMICO.VALOR%TYPE;
 vnCodSitDoc            OR_NFDESPESA.CODSITDOC%TYPE;
 vsTipoTributacao       OR_NFDESPESA.TIPOTRIBUTACAO%TYPE;
 vsTributIcms           OR_NFDESPESA.TRIBUTICMS%TYPE;
 vsTributPis            OR_NFDESPESA.TRIBUTPIS%TYPE;
 vsTributCofins         OR_NFDESPESA.TRIBUTCOFINS%TYPE;
 vsExigeItensNota       OR_NFDESPESA.EXIGEITENSNOTA%TYPE;
 vsTipoTributacaoIpi    OR_NFDESPESA.TIPOTRIBUTACAOIPI%TYPE;
 vsRetencaoPisNFDesp    OR_NFDESPESA.RETENCAOPISNFDESP%TYPE;
 vsRetencaoCofinsNFDesp OR_NFDESPESA.RETENCAOCOFINSNFDESP%TYPE;
 vsModeloNF             RF_PARAMNATNFDESP.MODELONF%TYPE;
 vsTipoModeloNF         RF_PARAMNATNFDESP.TIPOMODELONF%TYPE;
 vsRequisicoes          GEX_DADOSTEMPORARIOS2.STRING2%TYPE;
 vnCount                NUMBER(15);
 vnAliqIssQn            OR_NFDESPESA.ALIQISS%TYPE;
 vnAliqIssSt            OR_NFDESPESA.ALIQISSST%TYPE;
 vsEspecieNF            OR_NFDESPESA.ESPECIENF%TYPE;
 vnSeqContrato          OR_NFDESPESA.MCSSEQCONTRATO%TYPE;
 vsCodProduto           OR_NFDESPESA.CODPRODUTO%TYPE;
BEGIN
-- PD
 vsCodSitDoc := '';
 GEP_PARAMDINAMICO_N(0, 'ORNFDESPESA', 'ORCAMENTO' ,
               'SITUACAO_DOC_PADRAO', 'N', vsCodSitDoc,
               'Sugere a situação de documento. Opções: 0 - Regular / 1 - Regular Extemporâneo / 6 - Complementar / 7 - Complementar Extemporâneo / 8 - Emitido Base Regime Especial/Norma Específica', TRUNC(Sysdate), 'CONSINCO',
               '1', 0 );
 If vsCodSitDoc is not null and vsCodSitDoc >= 0 And vsCodSitDoc <= 8 then
    vnCodSitDoc := vsCodSitDoc;
 Else
    vnCodSitDoc := 0;
 End If;
 --Obtendo o seqNota
 IF psTipoImp = 'A' THEN
   SELECT COALESCE(X.SEQIMPNF, S_ORNFDESPESA.NEXTVAL)
   INTO pnSeqNota
   FROM OR_NFDESPESAIMPDET X
   WHERE X.CHAVE_UNICA = pnIDNFe;
 ELSE
   pnSeqNota := S_ORNFDESPESA.NEXTVAL;
 END IF;
 --Obtendo os campos referentes a natureza de despesa
 SELECT P.CGO,
        P.TIPTRIBUTACAO,
        P.TRIBUTICMS,
        P.TRIBUTPIS,
        P.TRIBUTCOFINS,
        P.EXIGEITENSNOTA,
        P.TIPOTRIBUTACAOIPI,
        P.RETENCAOPISNFDESP,
        P.RETENCAOCOFINSNFDESP,
        P.MODELONF,
        P.TIPOMODELONF,
        NVL(P.ALIQISSQN, 0),
        NVL(P.ALIQISSST, 0),
		    P.ESPECIENF,
        P.CODPRODUTO
 INTO   vnCGO,
        vsTipoTributacao,
        vsTributIcms,
        vsTributPis,
        vsTributCofins,
        vsExigeItensNota,
        vsTipoTributacaoIpi,
        vsRetencaoPisNFDesp,
        vsRetencaoCofinsNFDesp,
        vsModeloNF,
        vsTipoModeloNF,
        vnAliqIssQn,
        vnAliqIssSt,
        vsEspecieNF,
        vsCodProduto
 FROM   RFV_PARAMNATNFDESP P
 WHERE  P.NROEMPRESA = pnNroMatriz
 AND    P.CODHISTORICO = pnNatDesp;
  --Obtendo a versão e UF do fornecedor
  select    p.versao,
            p.uf
  into      vnVersaoPessoa,
            vsUFFornecedor
  from      ge_pessoa p
  where     p.seqpessoa = vnSeqFornecedor;
 --Obtendo a data da 1ª duplicata para o calculo do prazo de pagamento
 SELECT MIN(A.DTAVENC_DUPLICATA)
 INTO  vdDtaVencDuplicata
 FROM  ORV_FATURA_DUPLICATA_NFXML A
 WHERE A.IDNF = pnIDNFe
   AND NVL(A.TIPOIMP,'X') = psTipoImp;
 --Verifica contrato vinculado a nota
 vnSeqContrato := null;
 vnCount := 0;
 SELECT COUNT(1)
   INTO vnCount
   FROM MCSV_CONTRATOATIVOFORN A
  WHERE A.SEQFORNECEDOR = vnSeqFornecedor
    AND A.NROEMPRESA = pnNroEmpresa
    AND A.NATDESPESA = pnNatDesp;
 IF vnCount = 1 Then
  SELECT A.SEQCONTRATO
    INTO vnSeqContrato
    FROM MCSV_CONTRATOATIVOFORN A
   WHERE A.SEQFORNECEDOR = vnSeqFornecedor
     AND A.NROEMPRESA = pnNroEmpresa
     AND A.NATDESPESA = pnNatDesp;
 end if;
 --Será inserido os valores oriundos do xml, o restante dos dados/tratamentos será feito na aplicação quando o usuário buscar a NF
 INSERT INTO OR_NFDESPESA(SEQNOTA,
                          NRONOTA,
                          SERIE,
                          SEQPESSOA,
                          NROEMPRESA,
                          NROEMPRESANATDESP,
                          NROEMPRESAORC,
                          CGO,
                          DTAEMISSAO,
                          DTAENTRADA,
                          VALOR,
                          PRAZOPAGTO,
                          VLRIR,
                          OBSERVACAO,
                          VLRDESCONTOS,
                          VERSAOPESSOA,
                          CODMODELO,
                          CODHISTORICO,
                          VLRLIQNOTA,
                          VLRISS,
                          ALIQISS,
                          VLRISENTO,
                          VLROUTRAS,
                          VLRICMS,
                          VLRBASEISS,
                          VLRBASEICMS,
                          VLRBASEIR,
                          ALIQIR,
                          ESPECIENF,
                          VLRFINANCEIRO,
                          NFE,
                          NFECHAVEACESSO,
                          TIPOPGTO,
                          USUINCLUSAO,
                          DTAINCLUSAO,
                          CODSITDOC,
                          INDNFIMPORTADA,
                          INDNFIMPORTCONSISTIDA,
                          REQUISICOES,
                          TIPOTRIBUTACAO,
                          TRIBUTICMS,
                          TRIBUTPIS,
                          TRIBUTCOFINS,
                          EXIGEITENSNOTA,
                          TIPOTRIBUTACAOIPI,
                          RETENCAOPISNFDESP,
                          RETENCAOCOFINSNFDESP,
                          NFECHAVEACESSOSERVICO,
                          VLRPIS,
                          VLRBASEPIS,
                          ALIQPIS,
                          VLRCOFINS,
                          VLRBASECOFINS,
                          ALIQCOFINS,
                          VLRCSSLL,
                          VLRBASECSSLL,
                          ALIQCSSLL,
                          INFOFISCO,
                          INDNOTATRANSF,
                          VLRISSST,
                          ALIQISSST,
                          VLRBASEISSST,
                          MCSSEQCONTRATO,
                          CIFFOB,
                          TIPOCTE,
                          CODMUNORIG,
                          CODMUNDEST,
                          SEQTRANSPORTADOR,
                          CODPRODUTO
                          )
 SELECT pnSeqNota,
        n.NUMERONF,
        n.SERIE,
        vnSeqFornecedor,
        pnNroEmpresa,
        (Select Nvl(A.NroEmpresaHist, pnNroEmpresaOrc) From ORV_NROEMPRESAPLANO A Where A.Nroempresa = pnNroMatriz),
        pnNroEmpresaOrc,
        vnCGO,
        TRUNC(n.DTAEMISSAO),
        (CASE WHEN NVL(n.TIPOIMP,'X') = 'A' THEN NVL(n.DTAENTRADASAIDA,trunc(sysdate))
              ELSE trunc(sysdate)
         END) DTAENTRADA,
        n.VLRNF + nvl(n.VLRDESCONTOS, 0), --vlr bruto da nf
        (SELECT SUBSTR(C5_COMPLEXIN.C5INSTRING(CAST(COLLECT(TO_CHAR(A.DTAVENC_DUPLICATA - TRUNC(n.DTAEMISSAO))) AS C5INSTRTABLE), '/'), 0, 2000)
         FROM    ORV_FATURA_DUPLICATA_NFXML A
         WHERE A.IDNF = pnIDNFe
           AND NVL(A.TIPOIMP,'X') = psTipoImp) PRAZOPAGTO,
        (CASE WHEN N.VLRBASEIR IS NULL OR N.VLRBASEIR = 0 THEN
                   NULL
              ELSE
                  NVL(N.VLRIR, 0)
        END),
        SUBSTR(N.INFOCONTRIB, 0, 249),
        N.VLRDESCONTOS,
        vnVersaoPessoa,
        (CASE WHEN NVL(n.TIPOIMP,'X') = 'A' THEN NVL(n.MODELO,NVL(vsModeloNF,'55'))
              ELSE NVL(vsModeloNF,'55')
         END) MODELO,
        pnNatDesp,
        N.VLRNF VLRLIQNF, --já inclui os descontos e soma ST e IPI (se houver)
        (CASE WHEN N.VLRBASEISS IS NULL OR N.VLRBASEISS = 0 THEN
                   NULL
              WHEN vnAliqIssQn = 0 THEN
                   NULL
              ELSE
                  NVL(N.VLRISS, 0)
        END),
        (CASE WHEN N.VLRBASEISS IS NULL OR N.VLRBASEISS = 0 THEN
                   NULL
              WHEN vnAliqIssQn = 0 THEN
                   NULL
              ELSE
                   (NVL(N.VLRISS, 0) / N.VLRBASEISS) * 100
        END) ALIQISS,
        (CASE WHEN N.VLRBASEICMS IS NULL OR N.VLRBASEICMS = 0 THEN
                   NULL
              ELSE
                   N.VLRISENTO
        END) VLRISENTO,
        (CASE WHEN N.VLROUTROS IS NULL OR N.VLROUTROS = 0 THEN
                   NULL
              ELSE
                   N.VLROUTROS
        END) VLROUTRAS, -- VLR OUTRAS ICMS
        (CASE WHEN N.VLRBASEICMS IS NULL OR N.VLRBASEICMS = 0 THEN
                   NULL
              ELSE
                   NVL(N.VLRICMS, 0)
        END),
        (CASE WHEN N.VLRBASEISS IS NULL OR N.VLRBASEISS = 0 THEN
                   NULL
              WHEN vnAliqIssQn = 0 THEN
                   NULL
              ELSE
                   N.VLRBASEISS
        END),
        (CASE WHEN N.VLRBASEICMS IS NULL OR N.VLRBASEICMS = 0 THEN
                      NULL
              ELSE
                      N.VLRBASEICMS
        END),
        (CASE WHEN N.VLRBASEIR IS NULL OR N.VLRBASEIR = 0 THEN
                      NULL
              ELSE
                   N.VLRBASEIR
        END),
        (CASE WHEN N.VLRBASEIR IS NULL OR N.VLRBASEIR = 0 THEN
                   NULL
              ELSE
                   (NVL(N.VLRIR, 0) / N.VLRBASEIR) * 100
        END) ALIQIR,
        NVL(vsEspecieNF,'NFe'),
        N.VLRNF + NVL(N.VLRDESCONTOS, 0), --vlr financeiro
        (CASE WHEN NVL(n.TIPOIMP,'X') = 'A' THEN n.NFE
              WHEN n.MODELO = '57' THEN 'X'
              ELSE 'S'
         END) nfe,
        N.CHAVEACESSO,
        'P',
        vsUsuario,
        trunc(sysdate),
        vnCodSitDoc,
        'S', --NF importada
        'N', --NF consistida
        G.STRING2, -- Requisições
	      vsTipoTributacao,
        vsTributIcms,
        vsTributPis,
        vsTributCofins,
        vsExigeItensNota,
        vsTipoTributacaoIpi,
        vsRetencaoPisNFDesp,
        vsRetencaoCofinsNFDesp,
        N.NFECHAVEACESSOSERVICO,
        (CASE WHEN N.VLRBASEPIS IS NULL OR N.VLRBASEPIS = 0 THEN
                   NULL
              ELSE
                   N.VLRRETIDOPIS
        END) VLRRETIDOPIS,
        (CASE WHEN N.VLRBASEPIS IS NULL OR N.VLRBASEPIS = 0 THEN
                   NULL
              ELSE
                   N.VLRBASEPIS
        END) VLRBASEPIS,
        (CASE WHEN N.VLRBASEPIS IS NULL OR N.VLRBASEPIS = 0 THEN
                   NULL
              ELSE
                    ( N.VLRRETIDOPIS / N.VLRBASEPIS ) * 100
        END) ALIQPIS,
        (CASE WHEN N.VLRBASECOFINS IS NULL OR N.VLRBASECOFINS = 0 THEN
              NULL
        ELSE
              N.VLRRETIDOCOFINS
        END) VLRRETIDOCOFINS,
        (CASE WHEN N.VLRBASECOFINS IS NULL OR N.VLRBASECOFINS = 0 THEN
              NULL
        ELSE
              N.VLRBASECOFINS
        END) VLRBASECOFINS,
        (CASE WHEN N.VLRBASECOFINS IS NULL OR N.VLRBASECOFINS = 0 THEN
                   NULL
              ELSE
                   ( N.VLRRETIDOCOFINS / N.VLRBASECOFINS ) * 100
        END) ALIQCOFINS,
        (CASE WHEN N.VLRBASECSSLL IS NULL OR N.VLRBASECSSLL = 0 THEN
              NULL
        ELSE
              N.VLRRETIDOCSLL
        END) VLRRETIDOCSLL,
        (CASE WHEN N.VLRBASECSSLL IS NULL OR N.VLRBASECSSLL = 0 THEN
              NULL
        ELSE
              N.VLRBASECSSLL
        END) VLRBASECSSLL,
        (CASE WHEN N.VLRBASECSSLL IS NULL OR N.VLRBASECSSLL = 0 THEN
                   NULL
              ELSE
                   ( N.VLRRETIDOCSLL / N.VLRBASECSSLL ) * 100
        END) ALIQCSSLL,
        N.INFOFISCO,
        psNotaTransf,
        (CASE WHEN N.VLRBASEISS IS NULL OR N.VLRBASEISS = 0 THEN
                   NULL
              WHEN vnAliqIssSt = 0 THEN
                   NULL
              ELSE
                   NVL(N.VLRISS, 0)
        END),
        (CASE WHEN N.VLRBASEISS IS NULL OR N.VLRBASEISS = 0 THEN
                   NULL
              WHEN vnAliqIssSt = 0 THEN
                   NULL
              ELSE
                   (NVL(N.VLRISS, 0) / N.VLRBASEISS) * 100
        END) ALIQISSST,
        (CASE WHEN N.VLRBASEISS IS NULL OR N.VLRBASEISS = 0 THEN
                   NULL
              WHEN vnAliqIssSt = 0 THEN
                   NULL
              ELSE
                   N.VLRBASEISS
        END),
        vnSeqContrato,
        N.CIFFOB,
        N.TIPOCTE,
        N.CODMUNORIG,
        N.CODMUNDEST,
        N.SEQTRANSPORTADOR,
        vsCodProduto
 FROM   ORV_IMPORTACAO_NF_XML N,
        GEX_DADOSTEMPORARIOS G
 WHERE  N.IDNF = pnIDNFe
 AND    NVL(N.TIPOIMP,'X') = psTipoImp
 AND    N.IDNF = G.NUMBER1 (+)
 AND    NVL(N.TIPOIMP,'X') = G.STRING4 (+)
 AND    N.NUMERONF = G.NUMBER2 (+);
 -- RC 195316 Alimentando tabela OR_NFDESPESAREQ que armazena as requisiões da nota
 SELECT G.STRING2
 INTO   vsRequisicoes
 FROM   ORV_IMPORTACAO_NF_XML N,
        GEX_DADOSTEMPORARIOS G
 WHERE  N.IDNF = pnIDNFe
 AND    NVL(N.TIPOIMP,'X') = psTipoImp
 AND    N.IDNF = G.NUMBER1 (+)
 AND    NVL(N.TIPOIMP,'X') = G.STRING4 (+)
 AND    N.NUMERONF = G.NUMBER2 (+);
 IF vsRequisicoes IS NOT NULL THEN
    FOR vtDados IN (
        SELECT COLUMN_VALUE SEQREQUISICAONOTA
        FROM   TABLE(CAST(C5_COMPLEXIN.C5INTABLE( vsRequisicoes ) AS C5INSTRTABLE)))
    LOOP
        vnCount := 0;
        SELECT COUNT(1)
        INTO   vnCount
        FROM   OR_NFDESPESAREQ A
        WHERE  A.SEQNOTA = pnSeqNota
        AND    A.SEQREQUISICAO = vtDados.SEQREQUISICAONOTA;
        IF vnCount = 0 THEN
           INSERT	INTO OR_NFDESPESAREQ(
                  SEQNOTA,
                  SEQREQUISICAO)
           VALUES	(pnSeqNota,
                  vtDados.SEQREQUISICAONOTA);
        END IF;
    END LOOP;
 END IF;
 /*Registra o SeqNota na tabela de importação via arquivo*/
 IF psTipoImp = 'A' THEN
   UPDATE OR_NFDESPESAIMPDET D
      SET D.SEQIMPNF =  pnSeqNota
    WHERE D.CHAVE_UNICA = pnIDNFe;
 END IF;
 COMMIT;
END ORP_IMPORTANF;
-- EXCLUI NF DO ORÇAMENTO --
PROCEDURE ORP_EXCLUINF(pnSeqNota  IN NUMBER)
IS
BEGIN
  DELETE FROM OR_NFDESPESA N WHERE N.SEQNOTA = pnSeqNota;
  commit;
END ORP_EXCLUINF;
-- INCONSISTÊNCIA ITEM --
FUNCTION ORF_INCONSISTENCIAITEM(pnIDNFe         IN NUMBER,
                                pnNatDesp       IN OR_NFDESPESA.CODHISTORICO%TYPE,
                                pnNroEmpresa    IN NUMBER,
                                pnNroMatriz     IN NUMBER,
                                psTipoImp       IN VARCHAR2,
                                pnNroEmpresaOrc IN OR_PARAMETRO.NROEMPRESAORC%TYPE,
                                psNotaTransf    IN VARCHAR2)
RETURN NUMBER
IS
  vsMsgInconsist OR_INCONSIST_IMPORT_XML.MOTIVO%TYPE;
  vnInconsistenciaItem NUMBER;
  vbOk   BOOLEAN;
BEGIN
  --Contador de inconsistência do Item
   vnInconsistenciaItem:= 0;
  --Obtém a relação de itens da NF
  for cur_item in (SELECT A.IDITEM,
                          A.CODPRODUTO,
                          A.QUANTIDADE,
                          A.CFOP,
                          A.IDNF,
                          A.SEQPRODUTO,
                          A.TIPOIMP
                   FROM   ORV_IMPORTACAO_ITEM_XML A
                   WHERE  A.IDNF = pnIDNFe
                   AND    NVL(A.TIPOIMP,'X') = psTipoImp )
  loop
       --Exclui as inconsistências do Item
       delete from OR_INCONSIST_IMPORT_XML
        where IDNF = pnIDNFe
          and IDITEM = cur_item.iditem
          and NVL(TIPOIMP,'X') = psTipoImp;
       commit;
       --Verifica se o produto está cadastrado / relacionado ao fornecedor
       vbOk := ORF_OBTEMCODPRODUTO(
                                   cur_item.codproduto,
                                   pnNroEmpresa,
                                   cur_item.IDNF,
                                   cur_item.IDITEM,
                                   cur_item.TIPOIMP,
                                   cur_item.CFOP,
                                   pnNatDesp,
                                   pnNroEmpresaOrc,
                                   pnNroMatriz,
                                   psNotaTransf,
                                   cur_item.seqproduto,
                                   vsMsgInconsist);
       If NOT vbOk THEN
          -- se não retornar o produto, verificar o de para
          ORP_INSERE_INCONSISTENCIA(pnIDNFe, pnNatDesp, cur_item.iditem, vsMsgInconsist, psTipoImp);
       End If;
       --Verifica se a quantidade está zerada
       If cur_item.quantidade = 0 Then
          ORP_INSERE_INCONSISTENCIA(pnIDNFe, pnNatDesp, cur_item.iditem, 'O produto ' || cur_item.codproduto || ' está com a quantidade zerada.', psTipoImp);
       End If;
  end loop;
  --Verifica o nº de inconsistências
  select count(1)
  into   vnInconsistenciaItem
  from   or_inconsist_import_xml i
  where  i.idnf = pnIDNFe
  and    NVL(i.tipoimp,'X') = psTipoImp
  and    i.iditem is not null;
  RETURN vnInconsistenciaItem;
END ORF_INCONSISTENCIAITEM;
-- IMPORTA ITEM --
PROCEDURE ORP_IMPORTAITEM(pnIDNFe         IN NUMBER,
                          pnNatDesp       IN OR_NFDESPESA.CODHISTORICO%TYPE,
                          pnNroEmpresa    IN NUMBER,
                          pnNroEmpresaOrc IN NUMBER,
                          pnSeqNota       IN NUMBER,
                          pnNroMatriz     IN NUMBER,
                          psTipoImp       IN VARCHAR2)
IS
 vnCFOPEstado           NUMBER;
 vnCFOPForaEstado       NUMBER;
 vnCFOPExterior         NUMBER;
 vsTipoTributacao       OR_NFDESPESA.TIPOTRIBUTACAO%TYPE;
 vsTributIcms           OR_NFDESPESA.TRIBUTICMS%TYPE;
 vsTributPis            OR_NFDESPESA.TRIBUTPIS%TYPE;
 vsTributCofins         OR_NFDESPESA.TRIBUTCOFINS%TYPE;
 vsTipoTributacaoIpi    OR_NFDESPESA.TIPOTRIBUTACAOIPI%TYPE;
 vsRetencaoPisNFDesp    OR_NFDESPESA.RETENCAOPISNFDESP%TYPE;
 vsRetencaoCofinsNFDesp OR_NFDESPESA.RETENCAOCOFINSNFDESP%TYPE;
 vnAliqIssQn            OR_NFDESPESA.ALIQISS%TYPE;
 vnAliqIssSt            OR_NFDESPESA.ALIQISSST%TYPE;
 vsIntegraDomini        RF_PARAMNATNFDESP.INTEGRADOMINI%TYPE;
 vsGeraCiap             RF_PARAMNATNFDESP.GERACIAP%TYPE;
BEGIN
  --Obtém os CFOPs e campos da Nat Desp
  SELECT P.CFOPESTADO,
         P.CFOPFORAESTADO,
         P.CFOPEXTERIOR,
         P.TIPTRIBUTACAO,
         P.TRIBUTICMS,
         P.TRIBUTPIS,
         P.TRIBUTCOFINS,
         P.TIPOTRIBUTACAOIPI,
         P.RETENCAOPISNFDESP,
         P.RETENCAOCOFINSNFDESP,
         NVL(P.ALIQISSQN, 0),
         NVL(P.ALIQISSST, 0),
         P.INTEGRADOMINI,
         P.GERACIAP
  INTO   vnCFOPEstado,
         vnCFOPForaEstado,
         vnCFOPExterior,
         vsTipoTributacao,
         vsTributIcms,
         vsTributPis,
         vsTributCofins,
         vsTipoTributacaoIpi,
         vsRetencaoPisNFDesp,
         vsRetencaoCofinsNFDesp,
         vnAliqIssQn,
         vnAliqIssSt,
         vsIntegraDomini,
         vsGeraCiap
  FROM   RFV_PARAMNATNFDESP P
  WHERE  P.CODHISTORICO = pnNatDesp
  AND    P.NROEMPRESA = pnNroMatriz;
  INSERT INTO OR_NFITENSDESPESA(SEQNOTA,
                                NROITEM,
                                NROEMPRESA,
                                NROEMPRESAORC,
                                CODPRODUTO,
                                VERSAOPROD,
                                DESCRICAO,
                                CFOP,
                                UNIDADEPADRAO,
                                UNIDADE,
                                QUANTIDADE,
                                VLRTOTAL,
                                VLRDESCONTO,
                                VLRISENTO,
                                VLROUTRAS,
                                VLRBASEICMSPROP,
                                VLRICMS,
                                ALIQICMS,
                                VLRBASEPIS,
                                ALIQPIS,
                                VLRPIS,
                                VLRBASECOFINS,
                                ALIQCOFINS,
                                VLRCOFINS,
                                VLRBASEISS,
                                ALIQISS,
                                VLRISS,
                                PERCREDBASEICMS,
                                VLRBASICMSSTPRO,
                                CODNCM,
                                VLRITEM,
                                INDFINANCEIRO,
                                ALIQIPI,
                                VLRBASEIPI,
                                VLRIPI,
                                VLROUTROSIPI,
                                VLRISENTOIPI,
                                VLRICMSDIF,
                                VLRBASEICMSDIF,
                                TIPOTRIBUTACAO,
                                TRIBUTAICMSNFDESP,
                                TRIBUTAPISNFDESP,
                                TRIBUTACOFINSNFDESP,
                                TIPOTRIBUTACAOIPI,
                                RETENCAOPISNFDESP,
                                RETENCAOCOFINSNFDESP,
                                VLRBASEISSST,
                                ALIQISSST,
                                VLRISSST,
                                INDGERADOMINI,
                                INDGERACIAP
                               )
  SELECT pnSeqNota,
         ROWNUM, --nroitem
         pnNroEmpresa,
         pnNroEmpresaOrc,
         X.CODPRODUTO, --codProdutoFiscal (item xml X fornecedor)
         X.VERSAO, --versao do produto já com o depara
         X.DESCRICAO,
         CASE WHEN X.CFOPDESTINO IS NULL THEN
             (CASE WHEN vsUFFornecedor = vsUFEmpresa THEN
                         vnCFOPEstado
                  WHEN vsUFFornecedor = 'EX' THEN
                         vnCFOPExterior
                  ELSE
                         vnCFOPForaEstado
              END)
         ELSE X.CFOPDESTINO END, --CFOP
         SUBSTR(I.UNIDADEPADRAO, 1, 3),
         SUBSTR(I.UNIDADE, 1, 3),
         I.QUANTIDADE,
         I.VLRTOTAL,
         I.VLRDESCONTO,
         (CASE WHEN (I.ALIQICMS IS NULL AND I.VLRBASEICMS IS NULL) OR (I.ALIQICMS = 0 AND I.VLRBASEICMS = 0) THEN
                   NULL
              ELSE
                   0
         END), --VLR ISENTO ICMS
                  --///////////////// Tratativas TipTributacao Giuliano 31/03/2025
         CASE WHEN NVL(vsTipoTributacao,'X') = 'O' THEN NVL(I.VLRTOTAL, 0) ELSE 
         (CASE WHEN (I.ALIQICMS IS NULL AND I.VLRBASEICMS IS NULL) OR (I.ALIQICMS = 0 AND I.VLRBASEICMS = 0) THEN
                   NULL
              ELSE
                   0
         END)
         END, --VLR OUTRAS ICMS
         
         CASE WHEN NVL(vsTipoTributacao,'X') = 'O' THEN NULL ELSE 
         (CASE WHEN I.VLRBASEICMS IS NULL OR I.VLRBASEICMS = 0 THEN
                     NULL
               ELSE
                    I.VLRBASEICMS
         END)
         END,
         
         CASE WHEN NVL(vsTipoTributacao,'X') = 'O' THEN NULL ELSE 
         (CASE WHEN (I.ALIQICMS IS NULL AND I.VLRBASEICMS IS NULL) OR (I.ALIQICMS = 0 AND I.VLRBASEICMS = 0) THEN
                   NULL
              ELSE
                   NVL(I.VLRICMS, 0)
         END)
         END,
         
         CASE WHEN NVL(vsTipoTributacao,'X') = 'O' THEN 0 ELSE 
         (CASE WHEN I.ALIQICMS IS NULL OR I.ALIQICMS = 0 THEN
                    NULL
               ELSE
                  I.ALIQICMS
          END)
         END,
          
         --///////////////////////////////////////////////////////// Termina ICMS
         (CASE WHEN I.ALIQPIS IS NULL OR I.ALIQPIS = 0 THEN
                    NULL
               ELSE
                    NVL(I.VLRBASEPIS, 0)
         END),
         (CASE WHEN I.ALIQPIS IS NULL OR I.ALIQPIS = 0 THEN
                      NULL
               ELSE
                      I.ALIQPIS
          END),
         (CASE WHEN I.ALIQPIS IS NULL OR I.ALIQPIS = 0 THEN
                    NULL
               ELSE
                   NVL(I.VLRPIS, 0)
         END),
         (CASE WHEN I.ALIQCOFINS IS NULL OR I.ALIQCOFINS = 0 THEN
                    NULL
               ELSE
                    NVL(I.VLRBASECOFINS, 0)
         END),
         (CASE WHEN I.ALIQCOFINS IS NULL OR I.ALIQCOFINS = 0 THEN
                      NULL
               ELSE
                      I.ALIQCOFINS
          END),
         (CASE WHEN I.ALIQCOFINS IS NULL OR I.ALIQCOFINS = 0 THEN
                    NULL
               ELSE
                    NVL(I.VLRCOFINS, 0)
         END),
         (CASE WHEN I.ALIQISSQN IS NULL OR I.ALIQISSQN = 0 THEN
                    NULL
               WHEN vnAliqIssQn = 0 THEN
                    NULL
               ELSE
                    NVL(I.VLRBASEISSQN, 0)
         END),
         (CASE WHEN I.ALIQISSQN IS NULL OR I.ALIQISSQN = 0 THEN
                    NULL
               WHEN vnAliqIssQn = 0 THEN
                    NULL
               ELSE
                      I.ALIQISSQN
         END),
         (CASE WHEN I.ALIQISSQN IS NULL OR I.ALIQISSQN = 0 THEN
                    NULL
               WHEN vnAliqIssQn = 0 THEN
                    NULL
               ELSE
                   NVL(I.VLRISSQN, 0)
         END),
         I.PERCREDBASEICMS,
         I.VLRBASEICMSST,
         I.CODNCM,
         I.QUANTIDADE * I.VLRITEM, --Na aplicação precisa informar o vlr total do item
         'S', --INDFINANCEIRO
         (CASE WHEN I.ALIQIPI IS NULL OR I.ALIQIPI = 0 THEN
                       NULL
               ELSE
                   I.ALIQIPI
         END),
         (CASE WHEN I.VLRBASEIPI IS NULL OR I.VLRBASEIPI = 0 THEN
                      NULL
               ELSE
                      I.VLRBASEIPI
         END),
         (CASE WHEN (I.ALIQIPI IS NULL AND I.VLRBASEIPI IS NULL) OR (I.ALIQIPI = 0 AND I.VLRBASEIPI = 0) THEN
                    NULL
               ELSE
                    NVL(I.VLRIPI, 0)
          END),
         (CASE WHEN (I.ALIQIPI IS NULL AND I.VLRBASEIPI IS NULL) OR (I.ALIQIPI = 0 AND I.VLRBASEIPI = 0) THEN
                   NULL
              ELSE
                  0
         END), --VLROUTROSIPI
         (CASE WHEN (I.ALIQIPI IS NULL AND I.VLRBASEIPI IS NULL) OR (I.ALIQIPI = 0 AND I.VLRBASEIPI = 0) THEN
                   NULL
              ELSE
                  0
         END), --VLRISENTOIPI
         I.VLRICMSDIF,
         (CASE WHEN I.VLRICMSDIF = 0 OR I.VLRICMSDIF IS NULL THEN
                     NULL
               ELSE
                    I.VLRBASEICMS
         END), ---VLRBASEICMSDIF
         vsTipoTributacao,
         vsTributIcms,
         vsTributPis,
         vsTributCofins,
         vsTipoTributacaoIpi,
         vsRetencaoPisNFDesp,
         vsRetencaoCofinsNFDesp,
         (CASE WHEN I.ALIQISSQN IS NULL OR I.ALIQISSQN = 0 THEN
                    NULL
               WHEN vnAliqIssSt = 0 THEN
                    NULL
               ELSE
                    NVL(I.VLRBASEISSQN, 0)
         END),
         (CASE WHEN I.ALIQISSQN IS NULL OR I.ALIQISSQN = 0 THEN
                    NULL
               WHEN vnAliqIssSt = 0 THEN
                    NULL
               ELSE
                    I.ALIQISSQN
         END),
         (CASE WHEN I.ALIQISSQN IS NULL OR I.ALIQISSQN = 0 THEN
                    NULL
               WHEN vnAliqIssSt = 0 THEN
                    NULL
               ELSE
                   NVL(I.VLRISSQN, 0)
         END),
         vsIntegraDomini,
         vsGeraCiap
  FROM   ORV_IMPORTACAO_ITEM_XML I,
         ORX_IMPNFEPRODUTOITEM X
  WHERE  I.IDNF = X.IDNF
    AND  I.IDITEM = X.IDITEMNF
    AND  I.TIPOIMP = X.TIPOIMPORTACAO
    AND  I.IDNF = pnIDNFe
    AND  NVL(I.TIPOIMP,'X') = psTipoImp;
  -- Ponto de entrada preencher ICMS, PIS/COFINS e ICMSST de acordo com a natureza de despesa
  ORP_IMPITEMORCCUST(TP_OR_IMPITEMORC(pnSeqNota, pnNatDesp, pnNroEmpresa));
  commit;
END ORP_IMPORTAITEM;
-- EXCLUI ITEM ORÇAMENTO --
PROCEDURE ORP_EXCLUIITEM(pnSeqNota IN NUMBER)
IS
BEGIN
 DELETE FROM OR_NFITENSDESPESA I WHERE I.SEQNOTA = pnSeqNota;
 commit;
END ORP_EXCLUIITEM;
--Obtém o codigoProdutoFiscal (codigoItem xml X fornecedor)
FUNCTION ORF_OBTEMCODPRODUTO(
         psCodProduto     IN TMP_M014_ITEM.M014_Cd_Produto%TYPE,
         pnNroEmpresa     IN NUMBER,
         pnIDNFe          IN ORV_IMPORTACAO_ITEM_XML.IDNF%TYPE,
         pnIDItemNFe      IN ORV_IMPORTACAO_ITEM_XML.IDITEM%TYPE,
         psTipoImportacao IN ORV_IMPORTACAO_ITEM_XML.TIPOIMP%TYPE,
         pnCFOP           IN ORV_IMPORTACAO_ITEM_XML.CFOP%TYPE,
         pnNatDesp        IN OR_NFDESPESA.CODHISTORICO%TYPE,
         pnNroEmpresaOrc  IN OR_PARAMETRO.NROEMPRESAORC%TYPE,
         pnNroEmpMatriz   IN GE_EMPRESA.MATRIZ%TYPE,
         psNotaTransf     IN VARCHAR2,
         pnSeqProduto     IN MAP_PRODUTO.SEQPRODUTO%TYPE,
         psMsgInconsist   OUT OR_INCONSIST_IMPORT_XML.MOTIVO%TYPE)
RETURN BOOLEAN
IS
  vsCodProdFiscal   MAP_PRODUTO.CODPRODFISCAL%TYPE;
  vsIndImpItensCFOP RF_PARAMNATNFDESP.INDIMPNFITENSCFOP%TYPE;
  vsCodProdGenerico OR_PARAMNFITENSCFOP.CODPRODUTO%TYPE;
  vnCFOPDestino     OR_PARAMNFITENSCFOP.CFOPENTRADA%TYPE;
  vsDescricao       MAP_PRODUTO.DESCCOMPLETA%TYPE;
  vnVersao          MRL_PRODUTOEMPRESA.VERSAO%TYPE;
BEGIN
     IF pnSeqProduto IS NOT NULL THEN
       SELECT MAX(B.DESCRICAO), MAX(B.VERSAOPROD), MAX(B.CODPRODUTO)
       INTO   vsDescricao, vnVersao, vsCodProdFiscal
       FROM   ORV_PRODUTOTRIB B
       WHERE  B.SEQPRODUTO = pnSeqProduto
       AND    B.NROEMPRESA = pnNroEmpresa
       AND    B.SEQFORNECEDOR = vnSeqFornecedor;
       IF vsCodProdFiscal IS NULL THEN
         psMsgInconsist := 'O produto com o Seq ' || psCodProduto || ' não está cadastrado ou relacionado para este fornecedor.';
         RETURN FALSE;
       END IF;
        INSERT INTO ORX_IMPNFEPRODUTOITEM(
               IDNF,
               IDITEMNF,
               TIPOIMPORTACAO,
               CODPRODUTO,
               CFOPDESTINO,
               DESCRICAO,
               VERSAO)
        VALUES (pnIDNFe,
               pnIDItemNFe,
               psTipoImportacao,
               vsCodProdFiscal,
               vnCFOPDestino,
               vsDescricao,
               vnVersao);
        RETURN TRUE;
     END IF;
     --Busca o código do produto utilizado no fiscal através da relação código_produto X fornecedor (comercial)
     SELECT MAX(B.CODPRODUTO) --caso retorne mais que 1 reg(erro de cadastro)
     INTO   vsCodProdFiscal
     FROM   MAP_PRODCODIGO A,
            ORV_PRODUTOTRIB B
     WHERE  A.SEQPRODUTO = B.SEQPRODUTO
        AND UPPER(A.CODACESSO) =  UPPER(psCodProduto) --oriundo do XML (desconsiderar zeros à esquerda pois o SM assim o faz)
        AND B.NROEMPRESA = pnNroEmpresa
        AND B.SEQFORNECEDOR = vnSeqFornecedor; --já obtido ao importar o cabeçalho da nfe
    --Caso seja nota de transferência, virá o CODPRODUTO informado na view ORV_IMPORTACAO_ITEM_XML
    IF psNotaTransf = 'S' THEN
        BEGIN
             SELECT A.CODPRODUTO, A.DESCRICAO, A.VERSAOPROD
             INTO   vsCodProdFiscal, vsDescricao, vnVersao
             FROM   RFV_PRODUTO A
             WHERE  A.CODPRODUTO = psCodProduto
             AND    A.NROEMPRESA = pnNroEmpresa;
        EXCEPTION WHEN OTHERS THEN
             vsCodProdFiscal := NULL;
        END;
    ELSE
        --Busca o código do produto utilizado no fiscal através da relação código_produto X fornecedor (comercial)
        BEGIN
             SELECT MAX(B.CODPRODUTO)
             INTO   vsCodProdFiscal
             FROM   MAP_PRODCODIGO A,
                    ORV_PRODUTOTRIB B
             WHERE  A.SEQPRODUTO = B.SEQPRODUTO
             AND    UPPER(A.CODACESSO) =  UPPER(psCodProduto) --oriundo do XML (desconsiderar zeros à esquerda pois o SM assim o faz)
             AND    B.NROEMPRESA = pnNroEmpresa
             AND    B.SEQFORNECEDOR = vnSeqFornecedor --já obtido ao importar o cabeçalho da nfe
             AND    A.CGCFORNEC = B.CGCFORNEC;
        EXCEPTION WHEN OTHERS THEN
             vsCodProdFiscal := NULL;
        END;
    END IF;
    IF vsCodProdFiscal IS NOT NULL THEN
        IF psNotaTransf != 'S' THEN
           SELECT MAX(B.DESCRICAO), MAX(B.VERSAOPROD)
           INTO   vsDescricao, vnVersao
           FROM   ORV_PRODUTOTRIB B
           WHERE  B.CODPRODUTO = vsCodProdFiscal
           AND    B.NROEMPRESA = pnNroEmpresa
           AND    B.SEQFORNECEDOR = vnSeqFornecedor;
        END IF;
        INSERT INTO ORX_IMPNFEPRODUTOITEM(
               IDNF,
               IDITEMNF,
               TIPOIMPORTACAO,
               CODPRODUTO,
               CFOPDESTINO,
               DESCRICAO,
               VERSAO)
        VALUES (pnIDNFe,
               pnIDItemNFe,
               psTipoImportacao,
               vsCodProdFiscal,
               NULL,
               vsDescricao,
               vnVersao);
        RETURN TRUE;
    END IF;
    SELECT NVL(P.INDIMPNFITENSCFOP,'N')
    INTO   vsIndImpItensCFOP
    FROM   RFV_PARAMNATNFDESP P
    WHERE  P.CODHISTORICO = pnNatDesp
    AND    P.NROEMPRESA = pnNroEmpMatriz;
    IF vsCodProdFiscal IS NULL AND vsIndImpItensCFOP = 'S' THEN
       BEGIN
            SELECT A.CODPRODUTO,
                   A.CFOPENTRADA
            INTO   vsCodProdGenerico,
                   vnCFOPDestino
            FROM   OR_PARAMNFITENSCFOP A
            WHERE  A.NROEMPRESAORC = pnNroEmpresaOrc
            AND    A.CFOPSAIDA = pnCFOP;
       EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 psMsgInconsist := 'Não foi encontrada parametrização de-para do produto ' || psCodProduto || ', CFOP ' || pnCFOP;
                 RETURN FALSE;
    END;
       --Refaz a consistência se o produto genérico está relacionado para aquele fornecedor
       BEGIN
          SELECT MAX(B.CODPRODUTO)
          INTO   vsCodProdFiscal
          FROM   MAP_PRODCODIGO A,
                 ORV_PRODUTOTRIB B
          WHERE  A.SEQPRODUTO = B.SEQPRODUTO
          AND    B.CODPRODUTO =  vsCodProdGenerico
          AND    B.NROEMPRESA = pnNroEmpresa
          AND    B.SEQFORNECEDOR = vnSeqFornecedor;
       EXCEPTION WHEN OTHERS THEN
          vsCodProdFiscal:= NULL;
       END;
       IF vsCodProdFiscal IS NOT NULL THEN
          SELECT MAX(B.DESCRICAO), MAX(B.VERSAOPROD)
          INTO   vsDescricao, vnVersao
          FROM   ORV_PRODUTOTRIB B
          WHERE  B.CODPRODUTO = vsCodProdFiscal
          AND    B.NROEMPRESA = pnNroEmpresa
          AND    B.SEQFORNECEDOR = vnSeqFornecedor;
          INSERT INTO ORX_IMPNFEPRODUTOITEM(
                 IDNF,
                 IDITEMNF,
                 TIPOIMPORTACAO,
                 CODPRODUTO,
                 CFOPDESTINO,
                 DESCRICAO,
                 VERSAO)
          VALUES (pnIDNFe,
                 pnIDItemNFe,
                 psTipoImportacao,
                 vsCodProdFiscal,
                 vnCFOPDestino,
                 vsDescricao,
                 vnVersao);
          RETURN TRUE;
       ELSE
          psMsgInconsist := 'O produto genérico ' || vsCodProdGenerico || ', configurado no de-para CFOP de Saída: '|| pnCFOP || ', CFOP de Entrada: '|| vnCFOPDestino ||' não está cadastrado ou relacionado para este fornecedor.';
          RETURN FALSE;
       END IF;
    ELSE
       IF psNotaTransf = 'S' THEN
          psMsgInconsist := 'O produto com o código ' || psCodProduto || ' não foi encontrado.';
       ELSE
          psMsgInconsist := 'O produto com o código de acesso ' || psCodProduto || ' não está cadastrado ou relacionado para este fornecedor.';
       END IF;
       RETURN FALSE;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
         psMsgInconsist := 'Erro ao identificar o produto ' || psCodProduto || ': ' || SQLERRM;
         RETURN FALSE;
END ORF_OBTEMCODPRODUTO;
--Obtém a versão do produto
FUNCTION  ORF_OBTEMVERCAOPROD(psCodProduto      IN TMP_M014_ITEM.M014_Cd_Produto%TYPE,
                              pnNroEmpresa      IN NUMBER)
RETURN NUMBER
IS
  vnVersaoProduto MRL_PRODUTOEMPRESA.Versao%TYPE;
BEGIN
    --Busca a versão do produto utilizado no fiscal através da relação código_produto X fornecedor (comercial)
    SELECT MAX(B.VERSAOPROD) --caso retorne mais que 1 reg(erro de cadastro)
    INTO   vnVersaoProduto
    FROM   MAP_PRODCODIGO A,
           ORV_PRODUTO B
    WHERE  A.SEQPRODUTO = B.SEQPRODUTO
       AND UPPER(A.CODACESSO) =  UPPER(psCodProduto) --oriundo do XML (desconsiderar zeros à esquerda pois o SM assim o faz)
       AND B.NROEMPRESA = pnNroEmpresa
       AND B.SEQFORNECEDOR = vnSeqFornecedor; --já obtido ao importar o cabeçalho da nfe
    RETURN  vnVersaoProduto;
EXCEPTION
    WHEN OTHERS THEN
         RETURN NULL;
END ORF_OBTEMVERCAOPROD;
-- Obtendo fornecedor (seqpessoa)
FUNCTION  ORF_OBTEMFORNECEDOR(pnSeqFornecedor   IN NUMBER,
                              psCNPJ            IN TMP_M001_EMITENTE.M001_NR_CNPJ%TYPE)
RETURN NUMBER
IS
  vnSeqFornecedorAux         NUMBER;
BEGIN
  vnSeqFornecedorAux := NULL;
  --Carrega fornecedor informado na origem
  IF NVL(pnSeqFornecedor,0) != 0 THEN
    SELECT MAX(P.SEQPESSOA)
      INTO vnSeqFornecedorAux
      FROM GE_PESSOA P
     WHERE P.SEQPESSOA = pnSeqFornecedor;
  END IF;
  -- Caso não informar ou não existir o fornecedor da origem
  IF vnSeqFornecedorAux IS NULL THEN
    -- Carrega fornecedor com status ativo
    SELECT MAX(P.SEQPESSOA)
      INTO vnSeqFornecedorAux
      FROM GE_PESSOA P
     WHERE P.NROCGCCPF = TO_NUMBER(SUBSTR(psCNPJ, 1, 12))
       AND P.DIGCGCCPF = TO_NUMBER(SUBSTR(psCNPJ, 13, 2))
       AND NVL(P.STATUS,'A') = 'A';
    -- Caso não encontrar o fornecedor, carrega sem filtro de status
    IF vnSeqFornecedorAux IS NULL THEN
      SELECT MAX(P.SEQPESSOA)
        INTO vnSeqFornecedorAux
        FROM GE_PESSOA P
       WHERE P.NROCGCCPF = TO_NUMBER(SUBSTR(psCNPJ, 1, 12))
         AND P.DIGCGCCPF = TO_NUMBER(SUBSTR(psCNPJ, 13, 2));
    END IF;
  END IF;
  RETURN  vnSeqFornecedorAux;
EXCEPTION
    WHEN OTHERS THEN
         RETURN NULL;
END ORF_OBTEMFORNECEDOR;
--Gera inconsistência de cancelamento de nfse
PROCEDURE ORP_CONSISTECANCELAMENTONFS(pnNroEmpresa IN GE_EMPRESA.NROEMPRESA%TYPE)
IS
vnBemDomini NUMBER(1);
vnCount NUMBER(10);
BEGIN
     --Exclui as inconsistências da NFSe para cancelamento
     DELETE FROM OR_INCONSIST_IMPORT_XML I
           WHERE EXISTS( SELECT 1
                           FROM ORX_NFCANCELAMENTO T
                          WHERE T.IDNF = I.IDNF)
             AND NVL(TIPOIMP,'X') = 'X';
     COMMIT;
     --Obtém a relação de NFs a serem importadas de acordo com os filtros da aplicação
     FOR Nota in (SELECT A.SEQNOTA, A.IDNF, B.CODHISTORICO, B.AUTORIZADO, B.AUTORIZADONIVEL2, B.SITUACAO
                    FROM ORX_NFCANCELAMENTO A,
                         OR_NFDESPESA B
                  WHERE  B.SeqNota = A.Seqnota)
     LOOP
         IF Nota.AUTORIZADO = 'S' AND NOTA.AUTORIZADONIVEL2 = 'S' THEN
            ORP_INSERE_INCONSISTENCIA(Nota.IDNF, Nota.CODHISTORICO, null, 'Não é possível excluir uma nota fiscal autorizada. Para manutenção, é necessário realizar o processo manualmente na aplicação de Nota Fiscal de Despesa.', 'X');
         END IF;
         IF Nota.AUTORIZADO = 'S' AND NOTA.AUTORIZADONIVEL2 IS NULL THEN
            ORP_INSERE_INCONSISTENCIA(Nota.IDNF, Nota.CODHISTORICO, null, 'Não é possível excluir uma nota fiscal parcialmente autorizada. Para manutenção, é necessário realizar o processo manualmente na aplicação de Nota Fiscal de Despesa.', 'X');
         END IF;
         IF Nota.SITUACAO = 'I' THEN
            ORP_INSERE_INCONSISTENCIA(Nota.IDNF, Nota.CODHISTORICO, null, 'Não é possível excluir uma Nota fiscal integrada. Para manutenção, é necessário realizar o processo manualmente na aplicação de Nota Fiscal de Despesa.', 'X');
         END IF;
         vnCount := 0;
         SELECT COUNT(1)
           INTO vnCount
  		     FROM FI_LANCTOCOMISSAONOTA A
 		      WHERE A.SEQNOTA = Nota.SEQNOTA;
         IF vnCount > 0 THEN
            ORP_INSERE_INCONSISTENCIA(Nota.IDNF, Nota.CODHISTORICO, null, 'A nota já está vinculada ao pagamento de comissão. Para manutenção, é necessário realizar a desvinculação ao pagamento de comissão.', 'X');
         END IF;
         vnBemDomini := FCDOM_EXISTENOTAORDOMINI(pnNroEmpresa, Nota.SEQNOTA);
	       IF vnBemDomini > 0 THEN
            ORP_INSERE_INCONSISTENCIA(Nota.IDNF, Nota.CODHISTORICO, null, 'Existe(m) Ben(s) vinculado(s) a nota fiscal. Para manutenção, é necessário excluir a(s) movimentações no módulo Patrimonial.', 'X');
         END IF;
     END LOOP;
END ORP_CONSISTECANCELAMENTONFS;
--Gera log de exclusão de cancelamento de nfse
PROCEDURE OR_LOGCANCELAMENTONF(   pnSeqNota   IN OR_NFDESPESA.SEQNOTA%TYPE,
                                  pnIdNF      IN ORV_IMPORTACAO_ITEM_XML.IDNF%TYPE,
                                  pnNroNota   IN OR_NFDESPESA.NRONOTA%TYPE,
                                  psSerie     IN OR_NFDESPESA.SERIE%TYPE,
                                  psChave     IN OR_NFDESPESA.NFECHAVEACESSOSERVICO%TYPE,
                                  pnSeqPessoa IN OR_NFDESPESA.SEQPESSOA%TYPE,
                                  psDescricao  IN VARCHAR2 )
IS
vsCodUsuario VARCHAR2(200);
BEGIN
 --BUSCA USUÁRIO LOGADO NO SISTEMA
 SELECT MAX(A.C5_USERAPP)
   INTO vsCodUsuario
   FROM GEX_C5CLIENT A;
 -- SE O USUÁRIO FOR NULO A ALTERAÇÃO FOI VIA BANCO
 IF vsCodUsuario IS NULL THEN
    vsCodUsuario := Sys_Context('USERENV', 'SESSIONID');
 END IF;
 INSERT INTO OR_CANCELAMENTONFLOG
             ( SEQCANCELAMENTONFLOG,
               IDNF,
               SEQNOTA,
               NRONOTA,
               SERIE,
               CHAVESERVICO,
               SEQPESSOA,
               USUARIO,
               DTACANCELAMENTO,
               DTAHORACANCELAMENTO,
               DESCRICAO )
      VALUES ( S_OR_CANCELAMENTONFLOG.Nextval,
               pnIdNF,
               pnSeqNota,
               pnNroNota,
               psSerie,
               psChave,
               pnSeqPessoa,
               vsCodUsuario,
               TRUNC(SYSDATE),
               SYSDATE,
               psDescricao );
END OR_LOGCANCELAMENTONF;
--Rotina para exclusão de NFSe
PROCEDURE ORP_CANCELANFIMPORTADA( pnSeqNota IN OR_NFDESPESA.SEQNOTA%TYPE,
                                  pnIdNF    IN ORV_IMPORTACAO_ITEM_XML.IDNF%TYPE,
                                  pnOk      IN OUT NUMBER)
IS
BEGIN
pnOk := 0;
  DELETE FROM OR_NFITENSDESPESA
        WHERE OR_NFITENSDESPESA.SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFDESPIMPOSTOS
        WHERE OR_NFDESPIMPOSTOS.SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFVENCIMENTODIREITO
        WHERE OR_NFVENCIMENTODIREITO.SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFVENCIMENTO
        WHERE OR_NFVENCIMENTO.SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFCONTARATEIO
        WHERE OR_NFCONTARATEIO.SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFVENCTOOUTRASOPER
        WHERE OR_NFVENCTOOUTRASOPER.SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFOUTRASOPER
        WHERE OR_NFOUTRASOPER.SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFDESPESACONTRATOS
        WHERE OR_NFDESPESACONTRATOS.SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFPLANILHALANCTO
        WHERE OR_NFPLANILHALANCTO.SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFPESSOARETENCAO A
        WHERE A.SEQNOTA = pnSeqNota
          AND A.IMPOSTO = 'ISSQN';
  DELETE FROM OR_NFDESPESAPROJETO
        WHERE SEQNOTA = pnSeqNota;
  DELETE FROM OR_NFDESPESA
        WHERE OR_NFDESPESA.SEQNOTA= pnSeqNota;
  pnOk := 1;
  COMMIT;
  EXCEPTION
       WHEN OTHERS THEN
       ROLLBACK;
       pnOk := 0;
       ORP_INSERE_INCONSISTENCIA(pnIdNF, NULL, NULL,' Ocorreu erro ao excluir os dados na nota fiscal na Procedure: ORP_CANCELANFIMPORTADA. Erro: ' || SQLERRM, 'X');
END ORP_CANCELANFIMPORTADA;
-- Retorna sequencia para ser usada na coluna OR_NFDESPESAIMPDET.CHAVE_UNICA
FUNCTION ORF_SEQORNFDESPESAIMPDET
RETURN OR_NFDESPESAIMPDET.CHAVE_UNICA%TYPE
IS
  vnSequence     OR_NFDESPESAIMPDET.CHAVE_UNICA%TYPE;
  vnCount        NUMBER;
BEGIN
  LOOP
    -- Gerar a nova sequência
    SELECT S_ORNFDESPESA.NEXTVAL
    INTO   vnSequence
    FROM   DUAL;
    -- checar se a sequência já existe
    SELECT COUNT(1)
    INTO   vnCount
    FROM   OR_NFDESPESAIMPDET
    WHERE  CHAVE_UNICA = vnSequence;
    -- se não existir retornar a sequência
    EXIT WHEN vnCount = 0;
  END LOOP;
  RETURN vnSequence;
EXCEPTION
     WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20001, 'Erro ao gerar sequence: ' || SQLERRM);
END ORF_SEQORNFDESPESAIMPDET;
end PKG_OR_IMPORTACAOXMLNF;
