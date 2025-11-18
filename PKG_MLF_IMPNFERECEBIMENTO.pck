create or replace package PKG_MLF_IMPNFERECEBIMENTO is

  -- Author  : BIDIO
  -- Created : 03/06/2010 11:16:37
  -- Purpose : Importação das tabelas de integração de Nota Fiscal Eletrônica para as 
  --           tabelas auxilares do recebimento de mercadorias
  
  vbIndImportouNFXMLParaRecebto BOOLEAN := FALSE;
  
   -- ##### Importa as notas das tabelas de Integração #########
  PROCEDURE SP_IMPORTA_TMP(
              pnIDNFe              IN        TMP_M000_NF.M000_ID_NF%TYPE,
              pnCodGeralOper       IN        MAX_CODGERALOPER.CODGERALOPER%TYPE,
              pnNroEmpresa         IN        MAX_EMPRESA.NROEMPRESA%TYPE,
              pdDtaHorLancto       IN        MLF_AUXNOTAFISCAL.DTAHORLANCTO%TYPE,
              psUsuLancto          IN        MLF_AUXNOTAFISCAL.USULANCTO%TYPE,
              pnExcluiOphos        IN        INTEGER,
              pnImpOK              IN OUT    INTEGER,
              pnChaveNFe           IN        TMP_M000_NF.M000_NR_CHAVE_ACESSO%TYPE);
              
  PROCEDURE SP_CONSISTEIMPNFE(
              pnIDNFE              IN        MRL_NFEINCONSISTENCIA.SEQNOTAFISCAL%TYPE,
              pnNroEmpresa         IN        MAX_EMPRESA.NROEMPRESA%TYPE,
              pnVerifCancSefazLib  IN        INTEGER);              


  PROCEDURE SP_GRAVAINCONSISTENCIANFE(
              pnSeqNotafiscal          MRL_NFEINCONSISTENCIA.SEQNOTAFISCAL%TYPE,
              pnSeqItem               MRL_NFEINCONSISTENCIA.SEQNFITEM%TYPE,
              psTipoInconsist         MRL_NFEINCONSISTENCIA.TIPOINCONSIST%TYPE,
              pnCodInconsist          MRL_NFEINCONSISTENCIA.CODINCONSIST%TYPE,
              psBloqueioLiberacao     MRL_NFEINCONSISTENCIA.BLOQUEIOLIBERACAO%TYPE,
              psDescricao             MRL_NFEINCONSISTENCIA.DESCRICAO%TYPE);
              
   -- ##### Exclui as notas das tabelas de Integração #########
  PROCEDURE SP_EXCLUI_TMP(
              pnIDNFe              IN        TMP_M000_NF.M000_ID_NF%TYPE); 
              

  PROCEDURE SP_TMPEXCLUSAO(
              pnNroEmpresa         IN        MAX_EMPRESA.NROEMPRESA%TYPE);
              
    -- Verificação do pedido de compras informado para o item
  Function  fc_VerificaPedidoItemNFe(
             pnSeqNotaFiscal       IN        TMP_M000_NF.M000_ID_NF%TYPE,
             pnSeqItemNF           IN        TMP_M014_ITEM.M014_NR_ITEM%TYPE,
             pnSeqProduto          IN        MAP_PRODUTO.SEQPRODUTO%TYPE)
   return   number;                                                

   -- Calcula Proporção da quantidade recebida no pedido pela quantidade no xml
  Function  fc_CalcPropQtde(
             pnSeqNotaFiscal       IN        TMP_M000_NF.M000_ID_NF%TYPE,             
             pnSeqProduto          IN        MAP_PRODUTO.SEQPRODUTO%TYPE,
             pnQtdPed              IN        MRL_NFEITEMPEDIDO.QUANTIDADE%TYPE,
             pnQtdXml              IN        TMP_M014_ITEM.M014_VL_QTDE_COM%TYPE,
             pnQtdEmbPed           IN        MRL_NFEITEMPEDIDO.QTDEMBALAGEM%TYPE DEFAULT 1,
             pnQtdEmbXml           IN        MAP_PRODCODIGO.QTDEMBALAGEM%TYPE DEFAULT 1,
             psPDConvEmbPedXml     IN        MAX_PARAMETRO.VALOR%TYPE DEFAULT 'N',
             psIndUtilPedSecund    IN        MRL_NFEITEMPEDIDO.INDUTILPEDSECUNDARIO%TYPE DEFAULT 'N')
   return   number; 
  
  PROCEDURE SP_EXPURGOINTEGRACAONDD( pdDtaInicial     in date,
                                     pdDtaFinal       in date,
                                     psOwner          in varchar2 default 'integracao'
                                   );
                                   
  PROCEDURE SP_CalcVlrOriginalTitulo( 
             pnSeqAuxNotaFiscal    IN        MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL%TYPE,
             psRecebVencVlrLiq     IN        MAF_FORNECEDOR.INDRECEBVENCVLRLIQ%TYPE);                                 
                                      
  --verifica se existem fornecedores relacionados (por CNPJ ou rede)          
  function fc_FornecRelac(pnSeqFornecedor in maf_fornecedor.seqfornecedor%Type,
                          psPD_PmtVisualPedFornRel in max_parametro.valor%type)
    return varchar2;
    
  PROCEDURE SP_AJUSTEARREDITENS(
             pnSeqAuxNotaFiscal    IN        MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL%TYPE,
             pnSeqNotaFiscal       IN        TMP_M000_NF.M000_ID_NF%TYPE,
             pnNroEmpresa          IN        MAX_EMPRESA.NROEMPRESA%TYPE);  
end PKG_MLF_IMPNFERECEBIMENTO;
/
create or replace package body PKG_MLF_IMPNFERECEBIMENTO is

  -- ##### Importa as notas das tabelas de Integração #########
  PROCEDURE SP_IMPORTA_TMP(
              pnIDNFe              IN        TMP_M000_NF.M000_ID_NF%TYPE,
              pnCodGeralOper       IN        MAX_CODGERALOPER.CODGERALOPER%TYPE,
              pnNroEmpresa         IN        MAX_EMPRESA.NROEMPRESA%TYPE,
              pdDtaHorLancto       IN        MLF_AUXNOTAFISCAL.DTAHORLANCTO%TYPE,
              psUsuLancto          IN        MLF_AUXNOTAFISCAL.USULANCTO%TYPE,
              pnExcluiOphos        IN        INTEGER,
              pnImpOK              IN OUT    INTEGER,
              pnChaveNFe           IN        TMP_M000_NF.M000_NR_CHAVE_ACESSO%TYPE)
  IS
    
      vsAux                             VARCHAR2(10);
      vnPD_IndModCalcICMSST             VARCHAR2(1);
      vnPD_IndModCalcDesconto           VARCHAR2(1);
      vnPD_IndModCalcIPI                VARCHAR2(1);
      vsPD_IndTipCalcTotProd            VARCHAR2(1);
      vsPD_IndModLanctoDespesaPedido    VARCHAR2(1);
      vsPD_vsPDConvEmbPedXml            VARCHAR2(1);
      vsPD_IndPrazoTit                  VARCHAR2(1);
      vsPD_ImpInfoTitXmlEdi             VARCHAR2(1);
      vnLinhasProc                      INTEGER;
      vbExclui                          BOOLEAN;
      vnSeqAuxNF                        MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL%TYPE;
      vsUFOrigem                        GE_PESSOA.UF%TYPE;
      vnSeqFornec                       GE_PESSOA.SEQPESSOA%TYPE;
      vnVersaoPessoa                    GE_PESSOA.VERSAO%TYPE;
      vnPerFinanc                       MLF_AUXNFITEM.PERCDESCFINANC%TYPE;
      vdDtaLimDescFinanc                MLF_AUXNFVENCIMENTO.DTALIMDESCFINANC%TYPE;
      vsPzoPagamento                    MAF_FORNECDIVISAO.PZOPAGAMENTO%TYPE;
      vsArrayPrazoPagto                 str_array;
      vnQtde                            NUMBER := 0;
      vdDtaBaseVencto                   MLF_AUXNFVENCIMENTO.DTALIMDESCFINANC%TYPE;
      vsIndPrazoPagto                   MAF_FORNECDIVISAO.INDPZOPAGAMENTO%TYPE;
      vnDiasPzo                         MLF_AUXNFVENCIMENTO.DIASPRAZO%TYPE;
      vsSoftNFe                         MRL_EMPSOFTPDV.SOFTPDV%TYPE;
      vnSeqM000_ID_NF                   TMP_M000_NF.M000_ID_NF%TYPE;
      vnQtdeEmb                         MLF_AUXNFITEM.QTDEMBALAGEM%TYPE;
      vsCgoEntradaEmissao               VARCHAR2(1);
      vsRecebVencVlrLiq                 MAF_FORNECEDOR.INDRECEBVENCVLRLIQ%TYPE;
      vnVlrFunRural                     MLF_AUXNFITEM.VLRFUNRURALITEM%TYPE;
      vsModeloNF                        MLF_AUXNOTAFISCAL.MODELONF%TYPE;
      vsPDConvEmbXML                    MAX_PARAMETRO.VALOR%TYPE;
      vnVlrOperDesc                     MLF_AUXNFITEM.VLROPCONTRATODESC%TYPE;
      vnVlrOperRet                      MLF_AUXNFITEM.VLROPCONTRATORET%TYPE;
      vnVlrDescContrato                 MLF_AUXNFITEM.VLRDESCCONTRATO%TYPE;
      vnVlrOperDescParc                 MLF_AUXNFITEM.VLROPCONTRATODESC%TYPE;
      vnVlrOperRetParc                  MLF_AUXNFITEM.VLROPCONTRATORET%TYPE;
      vnVlrDescContratoParc             MLF_AUXNFITEM.VLRDESCCONTRATO%TYPE;
      vnContParc                        number;
      vnVlrOperDescRest                 MLF_AUXNFITEM.VLROPCONTRATODESC%TYPE;
      vnVlrOperRetRest                  MLF_AUXNFITEM.VLROPCONTRATORET%TYPE;
      vnVlrDescContratoRest             MLF_AUXNFITEM.VLRDESCCONTRATO%TYPE;
      vsIndUsaLoteEstoque               VARCHAR2(1);
      vsPDUtilCondPagtoContrFidel       MAX_PARAMETRO.VALOR%TYPE;
      vnVlrTotalItem                    MLF_AUXNOTAFISCAL.VLRTOTALNF%TYPE;
      vnVlrParcela                      MLF_AUXNFVENCIMENTO.VLRTOTAL%TYPE;
      vdDtaVencimento                   MLF_AUXNFVENCIMENTO.DTAVENCIMENTO%TYPE;
      vnSeqAuxNotaFiscal                MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL%TYPE;
      vnVlrDescFinanc                   MLF_AUXNFITEM.VLRDESCITEM%TYPE;
      vsArrayPrazoPagtoPedido           str_array;
      vsArrayPrazoPagtoAux              str_array;
      vnExistePedido                    number;
      vnExistePedidoPzo                    number;
      vsPD_PermImpXmlCnpj               MAX_PARAMETRO.VALOR%TYPE;
      vsIndImpTituloXmlEdi              MAF_FORNECDIVISAO.INDIMPTITULOXMLEDI%TYPE;
      vsPDIndConsNfeImpProc             MAX_PARAMETRO.VALOR%TYPE;
      vnSeqAuxNFVencto                  MLF_AUXNFVENCIMENTO.SEQAUXNFVENCTO%TYPE;
      vnSeqAuxNFVenctoXML               MLF_AUXNFVENCIMENTOXML.SEQAUXNFVENCTO%TYPE;
      vsIndAssumeEmbQtdEmbXml           maf_fornecdivisao.indassumeembqtdembxml%type;
      vsTipoDespesaNF                   MAF_FORNECDIVISAO.TIPODESPESANF%type;
      vsPD_ConsideraVlrPedBonif         MAX_PARAMETRO.VALOR%TYPE;
      vnPercDescContrato                MLF_AUXNFVENCIMENTO.PERCDESCCONTRATO%TYPE;
      vsPD_IndConsisteFornAtivoEdi      MAX_PARAMETRO.VALOR%TYPE;
      vsTipoDtaDescFinanc               VARCHAR2(1);
      vnQtdeDiasAntDescFinanc           NUMBER;
      vnSeqPessoa                       MLF_AUXNOTAFISCAL.SEQPESSOA%TYPE;
      -- RP 149708
      vsPD_GeraInconsProdCompl          MAX_PARAMETRO.VALOR%TYPE; 
      vsIndComplVlrImposto              MAX_CODGERALOPER.INDCOMPLVLRIMP%TYPE;            
      vnSeqProdutoComplImposto          MAX_EMPRESA.SEQPRODUTOCOMPLIMPOSTO%TYPE;
      vnVlrTotalNFe                     MRLV_NFEIMPORTACAO.VLRTOTNF%TYPE;
      vnVlrTotIcmsDesonNFe              MRLV_NFEIMPORTACAO.VLRTOTICMSDESONERADO%TYPE;
      vnVlrTotalItensNF                 MLF_AUXNFITEM.VLRTOTALITEM%TYPE;
      vsIndSubICMSDesTotNF              MLF_AuxNfItem.IndSubIcmsDesTotNf%Type;
      vsPD_DefaultLancaVlrSt            MAX_PARAMETRO.VALOR%TYPE;         
      vsIndImpDifAliqNFe                MAX_CODGERALOPER.INDIMPDIFALIQNFE%TYPE;      
      vsPD_ComprorFornecRecebto         MAX_PARAMETRO.VALOR%TYPE;
      vdDtaVencFixa                     MSU_PEDIDOSUPRIM.DTAVENCTOFIXA%TYPE;
      vsPD_ConsidDtaVencPed             MAX_PARAMETRO.VALOR%TYPE;
      --RC184906
      vnCount                           NUMBER;
      vnVlrTotalXML                     MLF_AUXNFVENCIMENTO.VLRTOTAL%TYPE;
      vnVlrTotalConsis                  MLF_AUXNOTAFISCAL.VLRTOTALNF%TYPE;
      --
      vsIndUtilCustoPrecifComer         MAX_PARAMGERAL.INDUTILCUSTOPRECIFCOMER%TYPE;
      vsObservacao                      MAX_CODGERALOPER.OBSPADRAONF%TYPE;


      vsTipDocFiscal                    MAX_CODGERALOPER.TIPDOCFISCAL%TYPE;

      vsIndTipoCodOrigemImpReceb        MAX_PARAMETRO.VALOR%TYPE;       --RC 201203

      --RP 207482
      --

      --
      vsPD_RateiaFreteNFItens           MAX_PARAMETRO.VALOR%TYPE;
      vnVlrFreteNaNotaItem              MLF_AUXNFITEM.VLRFRETENANF%TYPE;
      vnTotFreteNaNotaSoma              MLF_AUXNOTAFISCAL.VLRFRETENANF%TYPE;
      vnTotVlrFreteNaNF                 MLF_AUXNOTAFISCAL.VLRFRETENANF%TYPE;
      vnUltimoSeq                       MLF_AUXNFITEM.SEQAUXNFITEM%TYPE;
      vsIndRecalcFreteNaNF              MLF_AUXNOTAFISCAL.INDRECALCFRETENANF%TYPE;
      vnPerc                            DECIMAL(20,15);
      vnPercPeso                        DECIMAL(20,15);
      vsProdutos                        VARCHAR(1000);
      vnDiasPzoAux                      MLF_AUXNFVENCIMENTO.DIASPRAZO%TYPE;
      vsIndNFRefProdRural               MAX_CODGERALOPER.INDNFREFPRODRURAL%TYPE;
      vnVlrTotalNFItem                  MLF_AUXNOTAFISCAL.VLRTOTALNF%TYPE;          
      vnVlrTotalNota                    MLF_AUXNOTAFISCAL.VLRTOTALNF%TYPE;  
      vnVlrIcmsEstorno                  MLF_AUXNFITEM.VLRICMSESTORNO%TYPE;       
      vsCalculoICMS                     MAF_FORNECDIVISAO.CALCULOICMS%TYPE;      
      vnVlrFunSenar                     MLF_AUXNFITEM.VLRFUNSENAR%TYPE;
      vnVlrFunRat                       MLF_AUXNFITEM.VLRFUNRAT%TYPE;
      vnVlrFunPrevSocial                MLF_AUXNFITEM.VLRFUNPREVSOCIAL%TYPE; 
      vsPDUtilizaValorSimplesXML        MAX_PARAMETRO.VALOR%TYPE;
      vsPD_LiberaNFAutoSemDiverg        MAX_PARAMETRO.VALOR%TYPE;
      tObjImportaTmp                    TP_MLF_Importa_TMP;         
      vnQtdItemPedido                   MRL_NFEITEMPEDIDO.QUANTIDADE%TYPE;     
      vnPercBiodiesel                   MLF_AUXNFITEM.PERCBIODIESEL%TYPE;        
      vsDiasPrazoNF                     MLF_AUXNOTAFISCAL.DIASPRAZO%TYPE;
      vsDiasPrazoVencNF                 MLF_AUXNOTAFISCAL.DIASPRAZOVENC%TYPE;
      vsTipPedidoCompra                 MLF_AUXNOTAFISCAL.TIPPEDIDOCOMPRA%TYPE;
      vsPDIndDeduzIcmsDeson             MAX_PARAMETRO.VALOR%TYPE;
      vnFatorConvEmbXML                 MAP_FAMFORNEC.FATORCONVEMBXML%TYPE;
      vsPesavel                         MAP_FAMILIA.PESAVEL%TYPE;
  BEGIN
      vbIndImportouNFXMLParaRecebto := TRUE;
      
      pnImpOK  := 1;
      vbExclui := True; 
      -- Parametros para entrada dos ítens
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', pnNroEmpresa, 'IND_MODO_CALCULO_ICMSST', 'S', 'C',
            'INDICA O MODO DE CÁLCULO PADRÃO DO ICMSST (C - CALCULADO, R - RATEADO, P - CONF. PEDIDO)', vsAux );
      vnPD_IndModCalcICMSST := SubStr(vsAux,0,1);
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', pnNroEmpresa, 'IND_MODO_CALCULO_DESCONTO', 'S', 'R',
            'INDICA O MODO DE CÁLCULO PADRÃO DO DESCONTO (R - RATEADO, P - PERCENTUAL DO ITEM, V - VALOR)', vsAux );
      vnPD_IndModCalcDesconto := SubStr(vsAux,0,1);
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', pnNroEmpresa, 'IND_MODO_CALCULO_IPI', 'S', 'B',
            'INDICA O MODO DE CÁLCULO PADRÃO DO IPI (B - SOBRE VALOR BRUTO, L - SOBRE VALOR LIQUIDO, P - CONF. PEDIDO)', vsAux );
      vnPD_IndModCalcIPI := SubStr(vsAux,0,1);
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', pnNroEmpresa, 'IND_TIPO_CALCULO_TOTALPRODUTOS', 'S', 'B',
            'INDICA O MODO DE CÁLCULO PADRÃO DO TOTAL DOS PRODUTS (B - VALOR BRUTO, L - VALOR LIQUIDO)', vsAux );
      vsPD_IndTipCalcTotProd := SubStr(vsAux,0,1);
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', pnNroEmpresa, 'IND_LANCTO_DESPESA_PEDIDO', 'S', 'N',
            'INDICA SE LANÇA DESPESAS CONFORME PEDIDO (S/N)', vsAux );
      vsPD_IndModLanctoDespesaPedido := SubStr(vsAux,0,1);    
       PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NFE', 0, 'CONV_EMB_PED_XML', 'S', 'N',
            'CONVERTE A QUANTIDADE RECEBIDA AO VINCULAR UM PEDIDO DE COMPRA À NOTA DE ACORDO COM A EMBALAGEM DA FAMILIA/FORNECEDOR QUANDO A EMBALAGEM DO XML FOR DIFERENTE DO PEDIDO?'|| chr(13) || chr(10) ||
            'VALORES:(S-SIM/N-NÃO(VALOR PADRÃO))', vsAux );
      vsPD_vsPDConvEmbPedXml := SubStr(vsAux,0,1);  
      
       PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'CADASTRO_FAMILIA', 0, 'CONV_EMB_XML', 'S', 'N',
             'EXIBE CAMPO DE CONVERSÃO DE EMBALAGEM PARA RECEBIMENTO DE NOTA FISCAL IMPORTADA DO XML? VALORES: (S-SIM / N-NÃO (VALOR PADRÃO))', vsAux );
      vsPDConvEmbXML := SubStr(vsAux,0,1);        

       PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'CONTRATO_FIDELIDADE', 0, 'UTIL_COND_PAGTO_CONTR_FIDEL', 'S', 'N',
             'UTILIZA CONDIÇÃO DE PAGAMENTO EM VEZ DE PRAZO PAGAMENTO NO CONTRATO FIDELIDADE? VALORES:(S-SIM/N-NÃO(VALOR PADRÃO))', vsAux );
      vsPDUtilCondPagtoContrFidel := SubStr(vsAux,0,1);             

      -- RP 146314
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', pnNroEmpresa, 'IND_CONSID_VLR_PED_BONIF', 'S', 'N',
            'INDICA SE O VALOR DO PEDIDO DE BONIFICAÇÃO É CONSIDERADO NA GERAÇÃO DO TÍTULO (S/N).', vsAux );
      vsPD_ConsideraVlrPedBonif := SubStr(vsAux,0,1); 
            
      --RC 124876
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', pnNroEmpresa, 'IND_PRAZO_TIT', 'S', 'X',
             'INDIQUE QUAL PRAZO SERÁ CONSIDERADO NA GERAÇÃO DO TÍTULO DE OBRIGAÇÃO DA NF:'|| chr(13) || chr(10) ||
              'X-CONFORME XML(PADRÃO)'|| chr(13) || chr(10) ||
              'F-PZO DO FORNECEDOR'|| chr(13) || chr(10) ||
              'P-CONFORME PEDIDO, CASO NÃO HAJA PEDIDO SERÁ CONSIDERADO PZO DO FORNECEDOR'|| chr(13) || chr(10) ||
              'S-CONFORME XML E CONSISTE COM O PZO DO PED/FORNEC', vsAux);
      vsPD_IndPrazoTit := SubStr(vsAux,0,1);
      
      --RC 182470
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', 0, 'CONSID_DTA_VENC_FIXA_PED', 'S', 'N',
             'CONSIDERA A DATA DE VENCIMENTO FIXA DO PEDIDO. VALORES: S/N(PADRÃO = N). ' || chr(13) || chr(10) || 
                        'OBS.: CASO NÃO HOUVER A DATA INFORMADA NO PEDIDO CONTINUA PELO TRATAMENTO DO PD IND_PRAZO_TIT', vsPD_ConsidDtaVencPed);
      
      --RP 126084
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', 0, 'PERM_IMP_XML_CNPJ', 'S', 'N',
             'PERMITE IMPORTAR XML DE UMA NF-E DO FORNECEDOR QUANDO DUAS OU MAIS EMPRESAS DO SISTEMA POSSUIR O MESMO CNPJ ? VALORES:(S-SIM/N-NÃO(VALOR PADRÃO))', vsPD_PermImpXmlCnpj);
      
      --RC 126114
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NF', 0, 'IMP_INFO_TIT_XMLEDI', 'S', 'S',
             'INDICA SE IMPORTA AS INFORMAÇÕES DE TÍTULO AO IMPORTAR XML/EDI 
             VALORES: 
             N-NÃO 
             S-SIM(PADRÃO) 
             F-CONFORME FORNECEDOR/DIVISÃO', vsAux);
      vsPD_ImpInfoTitXmlEdi := SubStr(vsAux,0,1);
      
      --RP 127241
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NF', pnNroEmpresa, 'IND_CONS_NFE_IMP_PROC', 'S', 'N',
             'INDIQUE SE AS NOTAS FISCAIS ELETRÔNICAS IMPORTADAS PARA O RECEBIMENTO SERÃO CONSIDERADAS COM STATUS "AGUARDANDO". VALORES(S-SIM/N-NÃO(PADRÃO))', vsPDIndConsNfeImpProc);            
      
      --RP 146882
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', pnNroEmpresa, 'CONSISTE_FORNEC_ATIVO_EDI', 'S', 'S',
	           'INDICA SE CONSISTE SE O FORNECEDOR ESTÁ ATIVO EM PROCESSO DE EDI.' || CHR(13) || CHR(10) ||
	           'VALORES:' || CHR(13) || CHR(10) ||
	           'N-NÃO' || CHR(13) || CHR(10) ||
             'S-SIM(PADRÃO)', vsPD_IndConsisteFornAtivoEdi);            

      -- RP 149708
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', pnNroEmpresa, 'CONSISTE_ITEM_NFE_COMPLIMPOSTO', 'S', 'S', 
             'INDICA SE GERA INCONSISTÊNCIA DE PRODUTO NÃO ENCONTRADO OU QUANTIDADE NÃO INFORMADA PARA ITEM DE NFE DE COMPLEMENTO DE IMPOSTO.' || CHR(13) || CHR(10) || 
             'VALORES:' || CHR(13) || CHR(10) || 
             'N-NÃO' || CHR(13) || CHR(10) || 
             'S-SIM(PADRÃO)',vsPD_GeraInconsProdCompl);                        
      
      
      --RC 164048
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NF', 0, 'DEFAULT_LANCA_VLR_ST', 'S', 'N',
             'INFORME A OPÇÃO DEFAULT DO CAMPO "PERMITE LANÇAR VALOR NA BASE ICMS ST COM VALOR ZERADO NO CAMPO VALOR ICMS ST" NOS PARÂMETROS PARA CÁLCULO DO RECEBIMENTO DE MERCADORIA. VALORES:(S-SIM/N-
NÃO(VALOR PADRÃO))', vsAux);
      vsPD_DefaultLancaVlrSt := SubStr(vsAux,0,1);
      
      
      --RC 178581
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NF', 0, 'COMPROR_FORNEC_PED_RECEBTO', 'S', 'N',
             'UTILIZA NEGOCIAÇÃO DE COMPROR COM O FORNECEDOR NO ACRÉSCIMO DO CUSTO E GERAÇÃO DO VALOR NO FINANCEIRO? (S - SIM/N - NÃO(VALOR PADRÃO))', vsAux);
      vsPD_ComprorFornecRecebto := SubStr(vsAux,0,1);
     
      --RC 201203
      SP_BUSCAPARAMDINAMICO('RECEBTO_NFE', 0, 'IND_TIPO_COD_ORIGEM_IMP_RECEB', 'S', 'F',
          'INDICA QUAL O CÓDIGO DE ORIGEM DA MERCADORIA SERÁ CONSIDERADO NA IMPORTAÇÃO DA NOTA PARA O RECEBIMENTO. 
           VALORES:X-XML/F-FAMÍLIA(PADRÃO)', vsIndTipoCodOrigemImpReceb);
      ---
      
      -- RP 203454
       PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', 0, 'RATEIA_FRETE_NF_ITENS', 'S', 'N',
             'INFORMA SE IRÁ FAZER O RATEIO AUTOMÁTICO DO FRETE NA NF PARA OS ITENS NA GERAÇÃO PARA O RECEBIMENTO.' || chr(13) || chr(10) ||
             'VALORES:'|| chr(13) || chr(10) || 
             'S-SIM' || chr(13) || chr(10) || 
             'N-NÃO(PADRÃO)', vsPD_RateiaFreteNFItens);
             
      SP_BUSCAPARAMDINAMICO('RECEBTO_NF', 0,'UTILIZA_VALOR_SIMPLES_XML','S','N',
                            'UTILIZAR OS VALORES DO SIMPLES NACIONAL DO XML NO TOPO DA NOTA.' || CHR(13) || CHR(10) ||
     'S - CARREGA OS VALORES DO XML' || CHR(13) || CHR(10) ||
     'N - DESCARTA OS VALORES DO XML E ATUALIZA BASEADO NO CADASTRO DO FORNECEDOR (PADRÃO)',
                            vsPDUtilizaValorSimplesXML    
                           );
                           
      SP_BUSCAPARAMDINAMICO('RECEBTO_NFE', pnNroEmpresa, 'LIBERA_NF_AUTO_SEM_DIVERG', 'S', 'N',
             'LIBERAR NF AUT. PARA CONF. QUANDO NÃO HOUVER INCONSISTENCIAS (AUT/MANUAL)'|| CHR(13) || CHR(10) ||
             'N-NAO(PADRÃO)' || CHR(13) || CHR(10) ||
             'S-SIM,TODAS AS NF'|| CHR(13) || CHR(10) ||
             'C-SIM,SÓ OS CGOS QUE GERAM CARGA AUT'|| CHR(13) || CHR(10) ||
             'LISTA-INF LISTA DE CGO SÓ POR VIRGULA'|| CHR(13) || CHR(10) ||
             'OBS:É IGNORADO SE O PARAM IND_CONS_NFE_IMP_PROC ESTIVER ATIVO', vsPD_LiberaNFAutoSemDiverg);

      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', 0, 'IND_DEDUZ_ICMS_DESON', 'S', 'S',
             'INFORMA QUAL SERÁ O VALOR PADRÃO DO INDICADOR SE SUBTRAI O VALOR DO ICMS DESONERADO NO ITEM' || chr(13) || chr(10) ||
             'OBS.: PARÂMETRO SERÁ CONSIDERADO APENAS SE O INDICADOR E O VALOR DO ICMS DESONERADO NÃO FOR RETORNADO NAS TAGS DO XML' || chr(13) || chr(10) ||
             'VALORES: S - SIM (PADRÃO) N - NÃO', vsPDIndDeduzIcmsDeson);
             
      -- Verifica se a mesma chave está sendo processada
      INSERT INTO MRL_NFEIMPPROCESS VALUES(pnChaveNFe);
      
      --RC 119472
      SELECT MAX(DECODE(A.TIPCGO || A.TIPUSO, 'EE', 'S', 'N')), MAX(DECODE(A.TIPCGO || A.TIPUSO, 'EE',A.MODELONF,A.MODELONFE)),
             MAX(NVL(A.INDCOMPLVLRIMP, 'N')),
             MAX(A.INDIMPDIFALIQNFE),
             CASE WHEN MAX(A.TIPUSO) = 'E' THEN
               MAX(FC5_CGOOBSERVACAOPADRAONF(pnCodGeralOper, pnNroEmpresa))
             ELSE
               NULL
             END,
             MAX(A.TIPDOCFISCAL),
             MAX(A.INDNFREFPRODRURAL),
             MAX(A.TIPPEDIDOCOMPRA)
        INTO vsCgoEntradaEmissao, vsModeloNF, vsIndComplVlrImposto,
             vsIndImpDifAliqNFe,
             vsObservacao,
             vsTipDocFiscal,
             vsIndNFRefProdRural,
             vsTipPedidoCompra
        FROM MAX_CODGERALOPER A
       WHERE A.CODGERALOPER = pnCodGeralOper;
      
      -- RC 108917
      SELECT 	max(A.SOFTPDV)
    	INTO   	vsSoftNFe
    	FROM   	MRL_EMPSOFTPDV A
    	WHERE   A.NROEMPRESA = pnNroEmpresa
      AND 	  A.TIPOSOFT = 'N' 
      AND	    A.STATUS = 'A';
      
      -- RC 194638
      SELECT NVL(MAX(P.INDUTILCUSTOPRECIFCOMER), 'N')
      INTO   vsIndUtilCustoPrecifComer            
      FROM   MAX_PARAMGERAL P;      
      
      -- Pega o seqnotafiscal unico tanto para nota de entrada quanto para notas de emissão. rc 110958    
      SELECT S_SEQNOTAFISCAL.NEXTVAL INTO vnSeqM000_ID_NF FROM DUAL;   
      
      -- ############### Consistência das notas ###############
  
      -- Consiste as notas já importadas      
      INSERT INTO MRL_NFELOGIMPORT(
    	          SEQLOG, DTAIMPORTACAO,
    	          USUIMPORTACAO, TIPLOG, SEQAUXNOTAFISCAL,
                SEQNOTAFISCAL, NROEMPRESA, SEQPESSOA,
                HISTORICO)
        
      SELECT S_SEQNFELOGIMPORT.NEXTVAL, SYSDATE,
             psUsuLancto, 'E', A.SEQAUXNOTAFISCAL,
             pnIDNFe, pnNroEmpresa, A.SEQPESSOA,
             'Nota ' || A.NUMERONF ||
                ' Série ' || A.SERIENF ||
                ' Forn. ' || A.SEQPESSOA ||
                ' Empr. ' || A.NROEMPRESA ||
                ' já importada no sistema'
      
      FROM   ( 
               SELECT X.SEQNOTAFISCAL, X.SEQAUXNOTAFISCAL,
                      X.NROEMPRESA, X.SEQPESSOA, X.NUMERONF,
                      X.SERIENF, DECODE(vsCgoEntradaEmissao, 'S', X.NFEREFERENCIACHAVE, NVL(X.NFECHAVEACESSO, X.NFECHAVEACESSOCOPIA)) NFECHAVEACESSO
               FROM MLF_AUXNOTAFISCAL X
               WHERE  DECODE(vsCgoEntradaEmissao, 'S', X.NFEREFERENCIACHAVE, NVL(X.NFECHAVEACESSO, X.NFECHAVEACESSOCOPIA)) = pnChaveNFE
               AND    X.TIPNOTAFISCAL = 'E'
               AND    ((X.NROEMPRESA = pnNroEmpresa AND vsPD_PermImpXmlCnpj = 'S') OR vsPD_PermImpXmlCnpj != 'S')
               
               UNION
               
               SELECT XX.SEQNOTAFISCAL, XX.SEQAUXNOTAFISCAL,
                      XX.NROEMPRESA, XX.SEQPESSOA, TO_NUMBER(W.NUMERONF) NUMERONF,
                      W.SERIENF, W.CHAVEACESSO NFECHAVEACESSO
               FROM MLF_AUXNOTAFISCAL XX, MAX_CODGERALOPER PP, MRLV_NFEIMPORTACAO W
               WHERE PP.CODGERALOPER = XX.CODGERALOPER
               AND   PP.TIPUSO = 'E'
               AND   PP.INDNFREFPRODRURAL = 'S'       
               AND   W.CHAVEACESSO = pnChaveNFE
               AND   XX.NFREFERENCIANRO = W.NUMERONF
               AND   XX.NFREFERENCIASERIE = W.SERIENF
               AND   XX.SEQPESSOA = W.SEQPESSOA
               AND   XX.NROEMPRESA = W.NROEMPRESA
               AND   XX.TIPNOTAFISCAL = 'E'  
               AND   ((XX.NROEMPRESA = pnNroEmpresa AND vsPD_PermImpXmlCnpj = 'S') OR vsPD_PermImpXmlCnpj != 'S')              
               AND   XX.STATUSNF != 'C'
                                  
               
               UNION
               
               SELECT Y.SEQNOTAFISCAL, Y.SEQAUXNOTAFISCAL,
                      Y.NROEMPRESA, Y.SEQPESSOA, Y.NUMERONF,
                      Y.SERIENF, Y.NFECHAVEACESSO
               FROM MLF_NOTAFISCAL Y
               WHERE  Y.NFECHAVEACESSO = pnChaveNFE 
               AND    Y.TIPNOTAFISCAL = 'E'              
               AND    ((Y.NROEMPRESA = pnNroEmpresa AND vsPD_PermImpXmlCnpj = 'S') OR vsPD_PermImpXmlCnpj != 'S')
               
               UNION
               
               SELECT YY.SEQNOTAFISCAL, YY.SEQAUXNOTAFISCAL,
                      YY.NROEMPRESA, YY.SEQPESSOA, TO_NUMBER(W.NUMERONF) NUMERONF,
                      W.SERIENF, W.CHAVEACESSO NFECHAVEACESSO
               FROM MLF_NOTAFISCAL YY, MAX_CODGERALOPER PP, MRLV_NFEIMPORTACAO W
               WHERE PP.CODGERALOPER = YY.CODGERALOPER
               AND   PP.TIPUSO = 'E'
               AND   PP.INDNFREFPRODRURAL = 'S'       
               AND   W.CHAVEACESSO = pnChaveNFE
               AND   YY.NFREFERENCIANRO = W.NUMERONF
               AND   YY.NFREFERENCIASERIE = W.SERIENF
               AND   YY.SEQPESSOA = W.SEQPESSOA
               AND   YY.NROEMPRESA = W.NROEMPRESA
               AND   to_char(YY.NFREFERENCIADTAEMISSAO, 'dd/mm/yyyy') = W.DTAEMISSAO
               AND   NVL(YY.NFEREFERENCIACHAVE, 0) = W.CHAVEACESSO
               AND   YY.TIPNOTAFISCAL = 'E' 
               AND   ((YY.NROEMPRESA = pnNroEmpresa AND vsPD_PermImpXmlCnpj = 'S') OR vsPD_PermImpXmlCnpj != 'S')            
               AND   YY.STATUSNF != 'C'
      
             ) A

      WHERE  A.NFECHAVEACESSO = pnChaveNFE;
      
      vnLinhasProc := SQL%ROWCOUNT;
      If vnLinhasProc > 0 Then
         pnImpOK   := 0;
         vbExclui  := False;       
      End If;   
      
      -- Consiste as notas que estão aguardando importação porém já existem no sistema Consinco
      INSERT INTO MRL_NFELOGIMPORT(
    	          SEQLOG, DTAIMPORTACAO,
    	          USUIMPORTACAO, TIPLOG, SEQAUXNOTAFISCAL,
                SEQNOTAFISCAL, NROEMPRESA, SEQPESSOA,
                HISTORICO)
                
      SELECT S_SEQNFELOGIMPORT.NEXTVAL, SYSDATE,
             psUsuLancto, 'E', A.SEQAUXNOTAFISCAL,
             pnIDNFe, A.NROEMPRESA, A.SEQPESSOA,
             'Nota ' || A.NUMERONF ||
                ' Série ' || A.SERIENF ||
                ' Forn. ' || A.SEQPESSOA ||
                ' Empr. ' || A.NROEMPRESA ||
                ' está aguardando importação porém já existe no sistema Consinco'
      
      FROM   ( 
               SELECT W.SEQNOTAFISCAL, X.SEQAUXNOTAFISCAL,
                      X.NROEMPRESA, X.SEQPESSOA, X.NUMERONF,
                      X.SERIENF
               FROM MLF_AUXNOTAFISCAL X, MRLV_NFEIMPORTACAO W
               WHERE X.NUMERONF = W.NUMERONF
               AND   X.NROEMPRESA = W.NROEMPRESA
               AND   X.SEQPESSOA = W.SEQPESSOA
               AND   X.SERIENF = TO_CHAR(W.SERIENF)
               AND   X.TIPNOTAFISCAL = 'E'
               AND   (vsModeloNF is null or X.MODELONF = vsModeloNF )
               AND   ((X.NROEMPRESA = pnNroEmpresa AND vsPD_PermImpXmlCnpj = 'S') OR vsPD_PermImpXmlCnpj != 'S')
               --AND   NVL(X.SEQNOTAFISCAL,0) != W.SEQNOTAFISCAL
               AND     NVL(X.NFECHAVEACESSO,NVL(X.NFECHAVEACESSOCOPIA,0)) != W.CHAVEACESSO
               AND     NOT EXISTS (
                                  SELECT 1 FROM MAX_CODGERALOPER R
                                  WHERE  R.CODGERALOPER = X.CODGERALOPER
                                  AND    R.INDNFREFPRODRURAL = 'S'
                                  AND    X.NFREFERENCIANRO IS NOT NULL
                                  AND    X.NFREFERENCIASERIE IS NOT NULL  
                                  AND    vsCgoEntradaEmissao = 'S'     
                                  )
               AND     NOT EXISTS (
                                  SELECT 1 FROM MAX_CODGERALOPER R
                                  WHERE  R.CODGERALOPER = X.CODGERALOPER
                                  AND    DECODE(R.TIPCGO || R.TIPUSO, 'EE', 'S', 'N') = 'S'
                                  AND    X.NFREFERENCIANRO IS NOT NULL
                                  AND    X.NFREFERENCIASERIE IS NOT NULL  
                                  AND    vsCgoEntradaEmissao = 'N'     
                                  )
               
               UNION
               
               SELECT Z.SEQNOTAFISCAL, Y.SEQAUXNOTAFISCAL,
                      Y.NROEMPRESA, Y.SEQPESSOA, Y.NUMERONF,
                      Y.SERIENF
               FROM MLF_NOTAFISCAL Y, MRLV_NFEIMPORTACAO Z
               WHERE Y.NUMERONF = Z.NUMERONF
               AND   Y.NROEMPRESA = Z.NROEMPRESA
               AND   Y.SEQPESSOA = Z.SEQPESSOA
               AND   Y.SERIENF = TO_CHAR(Z.SERIENF)
               AND   Y.TIPNOTAFISCAL = 'E'
               AND   (vsModeloNF is null or Y.MODELONF = vsModeloNF)
               AND   ((Y.NROEMPRESA = pnNroEmpresa AND vsPD_PermImpXmlCnpj = 'S') OR vsPD_PermImpXmlCnpj != 'S')              
               --AND   NVL(Y.SEQNOTAFISCAL,0) != Z.SEQNOTAFISCAL
               AND   NVL(Y.NFECHAVEACESSO,0) != Z.CHAVEACESSO
               AND     NOT EXISTS (
                                  SELECT 1 FROM MAX_CODGERALOPER R
                                  WHERE  R.CODGERALOPER = Y.CODGERALOPER
                                  AND    R.INDNFREFPRODRURAL = 'S'
                                  AND    Y.NFREFERENCIANRO IS NOT NULL
                                  AND    Y.NFREFERENCIASERIE IS NOT NULL    
                                  AND    vsCgoEntradaEmissao = 'S'       
                                  )
               AND     NOT EXISTS (
                                  SELECT 1 FROM MAX_CODGERALOPER R
                                  WHERE  R.CODGERALOPER = Y.CODGERALOPER
                                  AND    DECODE(R.TIPCGO || R.TIPUSO, 'EE', 'S', 'N') = 'S'
                                  AND    Y.NFREFERENCIANRO IS NOT NULL
                                  AND    Y.NFREFERENCIASERIE IS NOT NULL    
                                  AND    vsCgoEntradaEmissao = 'N'       
                                  )
             ) A

      WHERE  A.SEQNOTAFISCAL = pnIDNFe;  
      
      vnLinhasProc := SQL%ROWCOUNT;
      If vnLinhasProc > 0 Then
         pnImpOK := 0;         
      End If;   


      SELECT  MAX(N.SEQFORNECEDOR),MAX(G.VERSAO),MAX(G.UF)
      INTO    vnSeqFornec,vnVersaoPessoa,vsUFOrigem
      FROM    MRL_NFEIMPORTACAO N, GE_PESSOA G
      WHERE   N.SEQNOTAFISCAL = pnIDNFE
      AND     N.SEQFORNECEDOR = G.SEQPESSOA;

     
      -- Consiste se fornecedor está ativo em processo de EDI    
      
      -- RP 146882 - Não fazer a consistência casa o PD esteja = 'N'
      If vsPD_IndConsisteFornAtivoEdi != 'N' Then   
          INSERT INTO MRL_NFELOGIMPORT(
        	          SEQLOG, DTAIMPORTACAO,
        	          USUIMPORTACAO, TIPLOG, SEQAUXNOTAFISCAL,
                    SEQNOTAFISCAL, NROEMPRESA, SEQPESSOA,
                    HISTORICO)
            
           SELECT S_SEQNFELOGIMPORT.NEXTVAL, SYSDATE,
                       psUsuLancto, 'E', null,
                       pnIDNFe, pnNroEmpresa, A.SEQPESSOA,
                       'Fornecedor ativo em processo de EDI para nota ' || A.NUMERONF ||
                          ' Série ' || A.SERIENF ||
                          ' Forn. ' || A.SEQPESSOA ||
                          ' Empr. ' || pnNroEmpresa
                
           FROM   MRLV_NFEIMPORTACAO A, MAF_FORNECEDI B, MAX_EDI C
           WHERE  A.SEQNOTAFISCAL = pnIDNFe
           AND    B.SEQFORNECEDOR = A.SEQPESSOA
           AND    B.NROEMPRESA = pnNroEmpresa
           AND    C.NOMEEDI = B.NOMEEDI
           AND    C.LAYOUT = B.LAYOUT
           and    B.STATUS = 'A'
           AND    C.INDIMPNFE = 'N' /*RA 69095*/;
             
          
          vnLinhasProc := SQL%ROWCOUNT;
          If vnLinhasProc > 0 Then
             pnImpOK := 0;         
          End If;    
      End If;
      
      If pnImpOK = 1 Then
          -- Se existe nos itens da nota um item no qual M014_DM_Deduz_Deson é null, faz o tratamento:
          Select Count(1)
          Into vnCount
          From TMP_M014_Item A
          Where A.M000_Id_Nf = pnIDNFe
          And A.M014_DM_Deduz_Deson Is Null;
          
          vsIndSubIcmsDesTotNF := 'S';
          if vnCount > 0 then
             -- Pega os valores da NFe importada para comparação
             SELECT MAX(NVL(A.VLRTOTNF,0)), MAX(NVL(A.VLRTOTICMSDESONERADO,0))
             INTO   vnVlrTotalNFe, vnVlrTotIcmsDesonNFe
             FROM   MRLV_NFEIMPORTACAO A     
             WHERE  A.SEQNOTAFISCAL   =  pnIDNFe;
             
             if vnVlrTotIcmsDesonNFe > 0 then
                 -- Verifica a soma dos itens para comparar com o da NFe importada                                 
                 SELECT NVL(
                          SUM(
                            (NVL(A.VLRPRODUTO,0) * fc_CalcPropQtde(A.SEQNOTAFISCAL,A.SEQPRODUTO,A.QUANTIDADE,A.QUANTIDADE)) +
                            (NVL(A.VLRDESPESA,0) * fc_CalcPropQtde(A.SEQNOTAFISCAL,A.SEQPRODUTO,A.QUANTIDADE,A.QUANTIDADE)) +
                            (NVL(A.VLRICMSST,0) * fc_CalcPropQtde(A.SEQNOTAFISCAL,A.SEQPRODUTO,A.QUANTIDADE,A.QUANTIDADE)) +
                            (NVL(A.VLRFCPST,0) * fc_CalcPropQtde(A.SEQNOTAFISCAL,A.SEQPRODUTO,A.QUANTIDADE,A.QUANTIDADE)) +
                            0 + (NVL(A.VLRIPI,0) * fc_CalcPropQtde(A.SEQNOTAFISCAL,A.SEQPRODUTO,A.QUANTIDADE,A.QUANTIDADE)) -
                            ABS(NVL(A.VLRDESCONTO,0))
                            - NVL(A.VLRICMSDESONERADO,0)
                           ),0)
                 INTO   vnVlrTotalItensNF
                 FROM   MRLV_NFEIMPORTACAOITEM A
                 WHERE  A.SEQNOTAFISCAL  = pnIDNFe;
                 
                 if((vnVlrTotalNFe > 0 and vnVlrTotalItensNF >= 0) and (abs(vnVlrTotalNFe - vnVlrTotalItensNF) > 0 and abs(vnVlrTotalNFe - vnVlrTotalItensNF) = vnVlrTotIcmsDesonNFe)) then
                   vsIndSubICMSDesTotNF := 'N';           
                 end if;
             end if;
          end if;
          --
          
          SELECT  S_SEQAUXNOTAFISCAL.NEXTVAL into vnSeqAuxNF from dual;       
          -- ############### Importa as notas ###############
          --Insere o cabeçalho da nota fiscal
          INSERT INTO MLF_AUXNOTAFISCAL(
                 SEQAUXNOTAFISCAL, STATUSNF, NUMERONF,
                 SEQPESSOA, SERIENF, TIPNOTAFISCAL,
          	     NROEMPRESA, VERSAOPESSOA, CODGERALOPER,
          	     DTAEMISSAO, UFORIGEMDESTINO, VLRRECEBDINHEIRO,
                 NROCGCCPFFORNEC, DIGCGCCPFFORNEC, INDPROCESSAMENTO,
                 TIPCALCDESC, TIPCALCICMSST, TIPCALCIPI,
                 LANCDESPCONFPEDIDO,DTARECEBIMENTO, 
                 DTASAIDA,
                 DTAENTRADA, 
                 DTAHORENTRADA,
                 TIPFRETETRANSP, DTAHORLANCTO,
                 USULANCTO, TIPCALCTOTPROD, VLRTOTALNF,
                 BASECALCICMSST, VLRICMSST, VLRFRETENANF,
                 BASECALCICMS, VLRICMS, VLRIPI,
                 VLRDESPTRIBUTADA, VLRDESPNTRIBUTADA,
                 NFECHAVEACESSO, SEQNOTAFISCAL, 
                 INDNFE, BASEICMSANTECIPADO, VLRICMSANTECIPADO, INDIMPXML,
                 NFREFERENCIANRO, NFREFERENCIASERIE, NFEREFERENCIACHAVE,
                 TPOCALCDESCFINANC,MODELONF, 
                 NFREFERENCIADTAEMISSAO, NFREFERENCIAMODELO,INFCOMPLEMENTARESNFE,
                 VLRTOTICMSDESONERADO,                    -- RP 138389
                 PERALIQICMSSIMPLESNAC,                   -- RP 141213
                 INDCONSUMIDORFINAL, INDSUBICMSDESTOTNF,
                 VLRTAXASERVADMSUFRAMA, VLRTAXASERVADMSUFRAMACALC, INDVLRICMSSTZERO,
		             NROPROCESSOBPM, VLRTOTFCPICMS, VLRTOTFCPST, VLRTOTFCPDISTRIB, 
                 OBSERVACAO, OBSERVACAONFE,
                 VERSAOXML,
                 INDSOMAFECPCUSTOPROD,
                 INDSOMAFECPCUSTOFIS,
                 INDSOMAFECPCUSTOGER,
                 INFOFISCO,
                 
                 VLRSEGURO, STATUSRETMANIFESTDEST,
                 BASICMSMONO, VLRICMSMONO, BASICMSMONORETEN, VLRICMSMONORETEN,
                 BASICMSMONORETANTERIOR, VLRICMSMONORETANTERIOR, TIPPEDIDOCOMPRA,
                 INDCRT
                 )
          SELECT DISTINCT vnSeqAuxNF, 'V', decode(vsCgoEntradaEmissao,'S',0,A.NUMERONF),
                 NVL(vnSeqFornec,A.SEQPESSOA), A.SERIENF, 'E',
                 pnNroEmpresa,NVL(vnVersaoPessoa,A.VERSAOPESSOA), pnCodGeralOper,
                 decode(vsCgoEntradaEmissao,'S',null,TO_DATE(A.DTAEMISSAO,'dd/MM/yyyy')), NVL(vsUFOrigem, A.UFORIGEM), 0,
                 A.NROCGCCPF, A.DIGCGCCPF, decode(vsPDIndConsNfeImpProc,'S','A','I'),
                 vnPD_IndModCalcDesconto, vnPD_IndModCalcICMSST, vnPD_IndModCalcIPI,
                 vsPD_IndModLanctoDespesaPedido,  trunc(sysdate), 
                 /*decode(vsCgoEntradaEmissao,'S',trunc(sysdate), nvl(TO_DATE(A.DTAENTRADASAIDA,'dd/MM/yyyy'), trunc(sysdate))) DtaSaida,
                 decode(vsCgoEntradaEmissao,'S',trunc(sysdate), nvl(TO_DATE(A.DTAENTRADASAIDA,'dd/MM/yyyy'), trunc(sysdate))) DtaEntrada, */ /*RC 112021*/
                 decode(vsCgoEntradaEmissao,'S',trunc(sysdate), nvl(TO_DATE(A.DTAENTRADASAIDA,'dd/MM/yyyy'), TO_DATE(A.DTAEMISSAO,'dd/MM/yyyy'))) DtaSaida,
                 trunc(sysdate) DtaEntrada, 
                 sysdate DTAHORENTRADA,
                 decode(vsCgoEntradaEmissao,'S','C',A.TIPFRETE), pdDtaHorLancto,
                 psUsuLancto, vsPD_IndTipCalcTotProd, A.VLRTOTNF,
                 A.BASCALCICMSST, A.VLRTOTICMSST, A.VLRTOTFRETE,
                 A.BASCALCICMS, A.VLRTOTICMS, A.VLRTOTIPI,
                 DECODE(NVL(C.TIPODESPESANF, 'T'), 'T', A.VLRTOTDESPESA + NVL(A.VLRTOTSEGURO, 0), 0), DECODE(NVL(C.TIPODESPESANF, 'T'), 'T', 0, A.VLRTOTDESPESA + NVL(A.VLRTOTSEGURO, 0)),
                 Decode(vsCgoEntradaEmissao,'S',null,A.CHAVEACESSO) CHAVEACESSO, vnSeqM000_ID_NF SeqNotaFiscal, 
                 Decode(vsCgoEntradaEmissao,'S',null,'S') IndNFE,0 BaseICMSAntecipado, 0 VlrICMSAntecipado, 'S' IndImpXML,
                 Decode(vsCgoEntradaEmissao,'S',A.NUMERONF,null) NFReferencia, Decode(vsCgoEntradaEmissao,'S',A.SERIENF,null) SerieReferencia, Decode(vsCgoEntradaEmissao,'S',A.CHAVEACESSO,null) ChaveAcessoReferencia,
                 nvl(C.TPOCALCDESCFINANC,'T'), vsModeloNF,
                 Decode(vsCgoEntradaEmissao,'S',TO_DATE(A.DTAEMISSAO,'dd/MM/yyyy'),null) NFReferenciaDtaEmissao,
                 Decode(vsCgoEntradaEmissao,'S',A.MODELONF,null) NFReferenciaModelo,
                 INFCOMPLEMENTARES,
                 A.VLRTOTICMSDESONERADO,                     -- RP 138389
                 C.PERALIQICMSSIMPLESNAC,                    -- RP 141213
                 A.INDCONSUMIDORFINAL, vsIndSubICMSDesTotNF,
                 0, 0, vsPD_DefaultLancaVlrSt, A.NROPROCESSOBPM, A.VLRTOTFCPICMS, A.VLRTOTFCPST, A.VLRTOTFCPDISTRIB,
                 vsObservacao, decode(vsTipDocFiscal, 'T', A.INFCOMPLEMENTARES, null),
                 A.VERSAOXML,
                 'S', --indsomafecpcustoprod
                 'S',     --indsomafecpcustofis
                 'S',      --indsomafecpcustoger
                 A.INFOFISCO,
                 
                 A.VLRTOTSEGURO,
                 A.STATUSRETMANIFESTDEST,
                 A.BASICMSMONO, A.VLRICMSMONO, A.BASICMSMONORETEN, A.VLRICMSMONORETEN,
                 A.BASICMSMONORETANTERIOR, A.VLRICMSMONORETANTERIOR, vsTipPedidoCompra,
                 A.INDCRT
          FROM   MRLV_NFEIMPORTACAO A,
                 MAX_EMPRESA B,
                 MAF_FORNECDIVISAO C
                 
          WHERE  B.NROEMPRESA = A.NROEMPRESA
          AND    C.SEQFORNECEDOR = A.SEQPESSOA
          AND    C.NRODIVISAO = B.NRODIVISAO
          AND    ((A.NROEMPRESA = pnNroEmpresa AND vsPD_PermImpXmlCnpj = 'S') OR vsPD_PermImpXmlCnpj != 'S')
          AND    A.SEQPESSOA = NVL(vnSeqFornec, A.SEQPESSOA)
          AND    A.SEQNOTAFISCAL     =     pnIDNFe;
    
          -- Verifica se foi processado alguma linha
          vnLinhasProc := SQL%ROWCOUNT;
          If vnLinhasProc = 0 Then
             pnImpOK := 0;  
             
             -- Grava o log de ERRO da importação do cabeçalho
             INSERT INTO MRL_NFELOGIMPORT(
    	          SEQLOG, DTAIMPORTACAO,
    	          USUIMPORTACAO, TIPLOG, SEQAUXNOTAFISCAL,
                SEQNOTAFISCAL, NROEMPRESA, SEQPESSOA,
                HISTORICO)
        
             SELECT S_SEQNFELOGIMPORT.NEXTVAL, SYSDATE,
                   psUsuLancto, 'E', null,
                   pnIDNFe, pnNroEmpresa, A.SEQPESSOA,
                   'Ocorreu algum erro na importação do cabeçalho da nota ' || A.NUMERONF ||
                      ' Série ' || A.SERIENF ||
                      ' Forn. ' || A.SEQPESSOA ||
                      ' Empr. ' || pnNroEmpresa
            
             FROM   MRLV_NFEIMPORTACAO A
             WHERE  A.SEQNOTAFISCAL = pnIDNFe;
                    
          End If;           
      
      End If;

      If pnImpOK = 1 Then
      -- RC 127471
      BEGIN
        SELECT NVL(B.INDASSUMEEMBQTDEMBXML, 'N'), NVL(B.TIPODESPESANF, 'T'),
                NVL((SELECT E.INDCALCULOICMS
                      FROM MAF_FORNECEMP E 
                      WHERE E.SEQFORNECEDOR = B.SEQFORNECEDOR
                      AND E.NROEMPRESA = C.NROEMPRESA
                     ), NVL(B.CALCULOICMS, 'N')
                   )
          INTO vsIndAssumeEmbQtdEmbXml, vsTipoDespesaNF,
                vsCalculoICMS
          FROM MAF_FORNECEDOR A, 
               MAF_FORNECDIVISAO B, 
               MAX_EMPRESA C
         WHERE A.SEQFORNECEDOR = B.SEQFORNECEDOR
           AND B.NRODIVISAO = C.NRODIVISAO
           AND C.NROEMPRESA = pnNroEmpresa
           AND A.SEQFORNECEDOR = (SELECT D.SEQPESSOA 
                                    FROM MLF_AUXNOTAFISCAL D 
                                   WHERE D.SEQAUXNOTAFISCAL = vnSeqAuxNF);
      EXCEPTION 
          WHEN NO_DATA_FOUND THEN
            vsIndAssumeEmbQtdEmbXml := 'N';
            vsTipoDespesaNF         := 'T';
            vsCalculoICMS           := 'N';  
      END;         

        -- Insere os ítens das notas
          -- Insere tmp para otimizar insercao dos itens (insert select view)    
      INSERT INTO MRLX_NFEIMPORTACAOITEM
        (SEQNOTAFISCAL, SEQNFITEM, IDITEM, NROEMPRESA, SEQPESSOA, PEDIDO, SEQPRODUTO, DESCPRODUTO,
         CODACESSO, SEQFAMILIA, QTDEMBALAGEM, QUANTIDADE, VLRPRODUTO, VLRDESCONTO, BASEICMS, ALIQICMS,
         VLRICMS, BASEIPI, ALIQIPI, VLRIPI, BASEICMSST, ALIQICMSST, VLRICMSST, CFOP, CGCFORNEC, DADOSXML,
         CHAVEACESSO, VLRDESPESA, CODNCMXML, VLRPISXML, VLRCOFINSXML, SITUACAONFPISXML, SITUACAONFCOFINSXML,
         VLRTOTICMSDESONERADO, MOTIVODESONERACAOICMS, CODCESTXML, 
         PERALIQINTPARTILHAICMS, 
         PERPARTILHAICMS,
         VLRICMSCALCDESTINO, VLRICMSCALCORIGEM, 
         BASCALCICMSPARTILHA, PERALIQUOTAFECPPARTILHA, 
         VLRFECPPARTILHA, BASICMSSTDISTRIB, VLRICMSSTDISTRIB, PERALIQICMSSTDISTRIB,
         NROFCI,
         BASEFCPST, PERALIQFCPST, VLRFCPST,
         BASEFCPICMS, PERALIQFCPICMS, VLRFCPICMS,
         BASEFCPDISTRIB, PERALIQFCPDISTRIB,VLRFCPDISTRIB, CODORIGEMTRIB,
         PERREDBCICMSEFET, VLRBASEICMSEFET, PERALIQICMSEFET, VLRICMSEFET, CODAJUSTEEFD, 
         INDESCALARELEVANTE, CNPJFABRICANTE, DIGCNPJFABRICANTE, VLRICMSDISTRIB,
         VLRFRETE,
         VLRICMSDIFERIDOXML, VLRICMSDESONXML, MOTDESICMSXML, CBENEFXML, PERDIFERIDOXML,
         UNIDADEXML, SEQITEMNFXML, QUANTIDADEMBXML, QUANTIDADEXML, VLRSEGURO, CODSITUACAONFXML,
         
         VLRICMSSIMPLES,
         BASICMSMONO, PERALIQICMSMONO, VLRICMSMONO, 
         BASICMSMONORETEN, PERALIQICMSMONORETEN, VLRICMSMONORETEN,
         BASICMSMONODIF, PERALIQICMSMONODIF, VLRICMSMONODIF,
         BASICMSMONORETANTERIOR, PERALIQICMSMONORETANTERIOR, VLRICMSMONORETANTERIOR,
         SeqItemOrigXml,
         IndSubIcmsDesTotNf)
      SELECT SEQNOTAFISCAL, SEQNFITEM, IDITEM, NROEMPRESA, SEQPESSOA, PEDIDO, SEQPRODUTO, DESCPRODUTO,
             CODACESSO, SEQFAMILIA, (CASE WHEN (vsIndAssumeEmbQtdEmbXml = 'S' AND QTDUN > 0 AND 1 = (SELECT count(1)
                                                                                                     FROM   MAP_PRODUTO P,MAP_FAMILIA F, MAP_FAMEMBALAGEM E
                                                                                                     WHERE  F.SEQFAMILIA = P.SEQFAMILIA
                                                                                                     AND    E.SEQFAMILIA = F.SEQFAMILIA
                                                                                                     AND    E.QTDEMBALAGEM = QTDUN
                                                                                                     AND    P.SEQPRODUTO = A.SEQPRODUTO)) THEN
                                      QTDUN
                                    else
                                      QTDEMBALAGEM
                                    end), 
                                    QUANTIDADE, VLRPRODUTO, VLRDESCONTO, BASEICMS, ALIQICMS,
             VLRICMS, BASEIPI, ALIQIPI, VLRIPI, BASEICMSST, ALIQICMSST, VLRICMSST, CFOP, CGCFORNEC, DADOSXML,
             CHAVEACESSO, VLRDESPESA, CODNCMXML, VLRPISXML, VLRCOFINSXML, SITUACAONFPISXML, SITUACAONFCOFINSXML,
             VLRICMSDESONERADO, MOTIVODESONERACAOICMS, CODCEST, 
             decode(vsIndImpDifAliqNFe,'N',null,PERALIQINTPARTILHAICMS), 
             decode(vsIndImpDifAliqNFe,'N',null,PERPARTILHAICMS),
             decode(vsIndImpDifAliqNFe,'N',null,VLRICMSCALCDESTINO), decode(vsIndImpDifAliqNFe,'N',null,VLRICMSCALCORIGEM), 
             decode(vsIndImpDifAliqNFe,'N',null,BASCALCICMSPARTILHA), decode(vsIndImpDifAliqNFe,'N',null,PERALIQUOTAFECPPARTILHA), 
             decode(vsIndImpDifAliqNFe,'N',null,VLRFECPPARTILHA), A.BASICMSSTDISTRIB, A.VLRICMSSTDISTRIB, CASE WHEN A.PERALIQICMSSTDISTRIB < 100 THEN
                                                                                                            A.PERALIQICMSSTDISTRIB
                                                                                                          ELSE
                                                                                                            NULL
                                                                                                          END,
             A.NROFCI,
             A.BASEFCPST, A.PERALIQFCPST, A.VLRFCPST,
             A.BASEFCPICMS, A.PERALIQFCPICMS, A.VLRFCPICMS,
             A.BASEFCPDISTRIB, A.PERALIQFCPDISTRIB, A.VLRFCPDISTRIB, A.DMORIGICMS, 
             A.PERREDBCICMSEFET, A.VLRBASEICMSEFET, A.PERALIQICMSEFET, A.VLRICMSEFET, A.CODAJUSTEEFD || ',' || A.CodAjusteEfdPresumidoXml || ',' || A.CodAjusteEfdDiferidoXml, 
             A.INDESCALARELEVANTE, A.CNPJFABRICANTE, A.DIGCNPJFABRICANTE,
             A.VLRICMSSUBSTITUTO,
             A.VLRFRETE,
             A.VLRICMSDIFERIDOXML, A.VLRICMSDESONXML, A.MOTIVODESONICMSXML,
             A.CODBENEFICIOXML, A.PERDIFERIDOXML, A.UNIDADEXML, A.SEQNFITEM,
             A.QUANTIDADEMBXML, A.QUANTIDADE, A.VLRSEGURO, A.CODSITUACAONFXML,
             
             A.VLRICMSSIMPLES,
             A.BASICMSMONO, A.PERALIQICMSMONO, A.VLRICMSMONO, 
             A.BASICMSMONORETEN, A.PERALIQICMSMONORETEN, A.VLRICMSMONORETEN,
             A.BASICMSMONODIF, A.PERALIQICMSMONODIF, A.VLRICMSMONODIF,
             A.BASICMSMONORETANTERIOR, A.PERALIQICMSMONORETANTERIOR, A.VLRICMSMONORETANTERIOR,
             A.SeqItemOrigXml,
             A.IndSubIcmsDesTotNf
        FROM MRLV_NFEIMPORTACAOITEM A
       WHERE A.SEQNOTAFISCAL = pnIDNFe
         AND ((A.NROEMPRESA = pnNroEmpresa AND vsPD_PermImpXmlCnpj = 'S') OR vsPD_PermImpXmlCnpj != 'S');
       
       
        -- Insere os ítens das notas
        INSERT INTO MLF_AUXNFITEM(
  	            SEQAUXNOTAFISCAL, SEQAUXNFITEM, QTDEMBALAGEM,
  	            SEQPRODUTO, TIPITEM, SEQITEMNF,
               CODTRIBUTACAO, QUANTIDADE, VLRITEM,
               VLRDESCITEM, VLRFUNRURALITEM, VLRDESPTRIBUTITEM,
               VLRDESPNTRIBUTITEM, VLRDESPFORANF, VLRTOTISENTO,
               VLRTOTOUTRA, BASCALCICMS, PERALIQUOTAICMS,
               VLRICMS, BASCALCIPI, PERALIQUOTAIPI,
               VLRIPI, BASCALCICMSST, PERALIQUOTAICMSST,
               VLRICMSST, VLRDESCFINANCEIRO, VLRDESCTRANSF,
               INDADMPRECO, VLRTOTALITEM, INDMANUTENCAO,
               NROPEDIDOSUPRIM, CFOP,
               VLRABATIMENTO, VLRDESCFINCALC, VLRPAUTAICMS,
               CODACESSO, CENTRALLOJA,
               CODNCMXML, -- RP 125015
               -- RP 125061
               VLRPISXML,
               VLRCOFINSXML,
               -- RC 131506
               SITUACAONFPISXML,
               SITUACAONFCOFINSXML,
               -- RP 138389
               VLRTOTICMSDESONERADO,
               MOTIVODESONERACAOICMS,
               -- RP 144496
               CODCESTXML,
               -- RP 144958
               PERALIQINTPARTILHAICMS, 
               PERPARTILHAICMS,
               VLRICMSCALCDESTINO, 
               VLRICMSCALCORIGEM,
	           BASCALCICMSPARTILHA,
               PERALIQUOTAFECPPARTILHA, 
               VLRFECPPARTILHA,

               CFOPORIGEM, CODORIGEMTRIB,
               VLRICMSXML,
               VLRICMSSTXML,
               VLRIPIXML,
               BASICMSSTDISTRIB, VLRICMSSTDISTRIB, PERALIQUOTAICMSSTDISTRIB,
               NROFCI,
               BASEFCPST, PERALIQFCPST, VLRFCPST,
               BASEFCPICMS, PERALIQFCPICMS, VLRFCPICMS,
               BASEFCPDISTRIB, PERALIQFCPDISTRIB,VLRFCPDISTRIB,
               PERREDBCICMSEFET, VLRBASEICMSEFET,PERALIQICMSEFET, VLRICMSEFET, CODAJUSTEEFDXML, 
               INDESCALARELEVANTE, CNPJFABRICANTE, DIGCNPJFABRICANTE, TIPFORITEM, VLRICMSDISTRIB,
               VLRFRETENANF,
               VLRICMSDIFERIDOXML, VLRICMSDESONXML, MOTDESICMSXML, CBENEFXML, PERDIFERIDOXML,
               UNIDADEXML, SEQITEMNFXML, QUANTIDADEMBXML, QUANTIDADEXML, VLRSEGURO, CODSITUACAONFXML,
               CODORIGEMTRIBXML, BASCALCICMSXML, BASCALCICMSSTXML,
               
               VLRFCPICMSXML, VLRFCPSTXML, VLRICMSSIMPLESXML, DESCRICAOPRODXML,
               BASICMSMONO, PERALIQICMSMONO, VLRICMSMONO, 
               BASICMSMONORETEN, PERALIQICMSMONORETEN, VLRICMSMONORETEN,
               BASICMSMONODIF, PERALIQICMSMONODIF, VLRICMSMONODIF,
               BASICMSMONORETANTERIOR, PERALIQICMSMONORETANTERIOR, VLRICMSMONORETANTERIOR,
               SEQITEMORIGXML,
               IndSubIcmsDesTotNf)
        SELECT DISTINCT B.SEQAUXNOTAFISCAL,NVL(i.NROITEM,A.SEQNFITEM), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM),              
               -- RP 149708
               CASE WHEN (vsPD_GeraInconsProdCompl = 'N' AND vsIndComplVlrImposto = 'S') AND (NVL(I.SEQPRODUTO, A.SEQPRODUTO) <= 0)  THEN
                   M.SEQPRODUTOCOMPLIMPOSTO 
               ELSE
                   NVL(I.SEQPRODUTO, A.SEQPRODUTO) 
               END,               
               'R', 
               NVL(i.NROITEM,A.SEQNFITEM),
               0,
               -- RP 149708
               CASE WHEN (vsPD_GeraInconsProdCompl = 'N' AND vsIndComplVlrImposto = 'S') AND NVL(I.QUANTIDADE,A.QUANTIDADE) <= 0 THEN
                   1
               ELSE
                   CASE WHEN vsPDConvEmbXML = 'S' AND NVL(F.FATORCONVEMBXML,0) > 0 THEN
                       CASE WHEN NVL(C.PESAVEL, 'N') = 'S' THEN
                            round((NVL(I.QUANTIDADE,A.QUANTIDADE) /  F.FATORCONVEMBXML), 3) * NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM)
                       ELSE
                            round((NVL(I.QUANTIDADE,A.QUANTIDADE) /  F.FATORCONVEMBXML) * NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM))
                       END
                   ELSE
                       NVL(I.QUANTIDADE,A.QUANTIDADE) * NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM)
                   END 
               END QUANTIDADE,
               
               NVL(A.VLRPRODUTO,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.VLRDESCONTO,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO), 0,
               DECODE(vsTipoDespesaNF, 'T', (NVL(A.VLRDESPESA,0) + NVL(A.VLRSEGURO, 0)) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO), 0),
               DECODE(vsTipoDespesaNF, 'T', 0, (NVL(A.VLRDESPESA,0) + NVL(A.VLRSEGURO, 0)) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO)),
               0, 0,
               0, NVL(A.BASEICMS,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.ALIQICMS,0),
               NVL(A.VLRICMS,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.BASEIPI,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               CASE 
                 WHEN NVL(A.ALIQIPI,0) > 99.99 THEN
                     ROUND((NVL(A.VLRIPI,0) / NVL(A.BASEIPI,0)) * 100,2)
                 ELSE NVL(A.ALIQIPI,0) 
               END ALIQIPI,
               NVL(A.VLRIPI,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.BASEICMSST,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.ALIQICMSST,0),
               NVL(A.VLRICMSST,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO), 0, 0,
               'N', 0, 'E',
               NVL(I.NROPEDIDOSUPRIM,0), A.CFOP,
               '0', 0, 0,
               A.CODACESSO,
               CASE /* RP 78189*/
                 WHEN NVL(I.NROPEDIDOSUPRIM,0) = 0 THEN
                    M.INDCENTRALLOJA
                 ELSE
                    ( SELECT MAX(E.CENTRALLOJA)
                        FROM MSU_PEDIDOSUPRIM E
                       WHERE E.NROPEDIDOSUPRIM = I.NROPEDIDOSUPRIM
                         AND E.NROEMPRESA = M.NROEMPRESA)
               END,
               A.CODNCMXML, -- RP 125015
               -- RP 125061
               A.VLRPISXML * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               A.VLRCOFINSXML * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               (SELECT MAX(M.SITUACAONFPISENT) 
                FROM   MAXV_SITUACAONFPISDEV M
                WHERE  M.NROEMPRESA       = PNNROEMPRESA 
                AND    M.SITUACAONFPISSAI = LPAD(TRIM(A.SITUACAONFPISXML),2,'0')),
               (SELECT MAX(M.SITUACAONFCOFINSENT) 
                FROM   MAXV_SITUACAONFCOFINSDEV M 
                WHERE  M.NROEMPRESA       = PNNROEMPRESA 
                AND    M.SITUACAONFCOFINSSAI = LPAD(TRIM(A.SITUACAONFCOFINSXML),2,'0')),
                -- RP 138389
                NVL(A.VLRTOTICMSDESONERADO,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                A.MOTIVODESONERACAOICMS,
                A.CODCESTXML,
                -- RP 144958
                A.PERALIQINTPARTILHAICMS, 
                A.PERPARTILHAICMS,
                A.VLRICMSCALCDESTINO, 
                A.VLRICMSCALCORIGEM,
		            A.BASCALCICMSPARTILHA,
                A.PERALIQUOTAFECPPARTILHA, 
                A.VLRFECPPARTILHA,

                A.CFOP, 
                CAST(Fmlf_Retorncodorigemmercadoria(Pnorigem      => A.CODORIGEMTRIB,
                                                    PnNroEmpresa  => pnNroEmpresa,
                                                    PnSeqProduto  => CASE WHEN (vsPD_GeraInconsProdCompl = 'N' AND vsIndComplVlrImposto = 'S') AND (NVL(I.SEQPRODUTO, A.SEQPRODUTO) <= 0)  THEN
                                                                         M.SEQPRODUTOCOMPLIMPOSTO 
                                                                     ELSE
                                                                         NVL(I.SEQPRODUTO, A.SEQPRODUTO) 
                                                                     END,
                                                    Pstiporetorno => vsIndTipoCodOrigemImpReceb) AS VARCHAR2(1)),
                NVL(A.VLRICMS,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.VLRICMSST,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.VLRIPI,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),


                A.BASICMSSTDISTRIB * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) BASICMSSTDISTRIB,
                A.VLRICMSSTDISTRIB * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) VLRICMSSTDISTRIB,
                A.PERALIQICMSSTDISTRIB PERALIQICMSSTDISTRIB,

                A.NROFCI,
                NVL(A.BASEFCPST, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) BASEFCPST,
                A.PERALIQFCPST,
                NVL(A.VLRFCPST, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) VLRFCPST,
                NVL(A.BASEFCPICMS, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) BASEFCPICMS,
                A.PERALIQFCPICMS, 
                NVL(A.VLRFCPICMS, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) VLRFCPICMS,
                NVL(A.BASEFCPDISTRIB, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) BASEFCPDISTRIB,
                A.PERALIQFCPDISTRIB PERALIQFCPDISTRIB,
                NVL(A.VLRFCPDISTRIB, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) VLRFCPDISTRIB,
                --RP194723
                A.PERREDBCICMSEFET, A.VLRBASEICMSEFET, A.PERALIQICMSEFET, A.VLRICMSEFET, A.CODAJUSTEEFD,
                A.INDESCALARELEVANTE, A.CNPJFABRICANTE, A.DIGCNPJFABRICANTE,
                DECODE(F.INDCONSIDTIPFORNCGO, 'S', fc5_cfoptipfornecedorxml(A.CFOP, A.CODORIGEMTRIB, A.CODSITUACAONFXML), NULL), A.VLRICMSDISTRIB,
                A.VLRFRETE,
                A.VLRICMSDIFERIDOXML * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                A.VLRICMSDESONXML, A.MOTDESICMSXML, A.CBENEFXML, A.PERDIFERIDOXML,
                A.UNIDADEXML, A.SEQITEMNFXML, A.QUANTIDADEMBXML, A.QUANTIDADEXML,
                A.VLRSEGURO * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                A.CODSITUACAONFXML, A.CODORIGEMTRIB,
                NVL(A.BASEICMS, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.BASEICMSST, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.VLRFCPICMS, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.VLRFCPST, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                CASE WHEN (vsPDUtilizaValorSimplesXML = 'S') AND (NVL(A.BASEICMSST, 0) > 0)  THEN
                   0
                ELSE
                   NVL(A.VLRICMSSIMPLES, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO)
                END,
                
                A.DESCPRODUTO,
                A.BASICMSMONO, A.PERALIQICMSMONO, A.VLRICMSMONO, 
                A.BASICMSMONORETEN, A.PERALIQICMSMONORETEN, A.VLRICMSMONORETEN,
                A.BASICMSMONODIF, A.PERALIQICMSMONODIF, A.VLRICMSMONODIF,
                A.BASICMSMONORETANTERIOR, A.PERALIQICMSMONORETANTERIOR, A.VLRICMSMONORETANTERIOR,
                A.SeqItemOrigXml,
                DECODE(A.IndSubIcmsDesTotNf, 1, 'S', 0, 'N', CASE WHEN A.IndSubIcmsDesTotNf IS NULL THEN
                  CASE WHEN A.Vlricmsdesonxml IS NOT NULL THEN vsIndSubICMSDesTotNF 
                    ELSE vsPDIndDeduzIcmsDeson END ELSE vsIndSubICMSDesTotNF END)                      
        FROM MRLX_NFEIMPORTACAOITEM A, MLF_AUXNOTAFISCAL B, MRL_NFEITEMPEDIDO I, MAP_PRODUTO P,
             MAP_FAMDIVISAO D, MAX_EMPRESA M, MAP_FAMFORNEC F, MAP_FAMILIA C
        WHERE A.SEQNOTAFISCAL = pnIDNFe
        --AND   B.SEQNOTAFISCAL = A.SEQNOTAFISCAL
        AND   (vsModeloNF is null or B.MODELONF = vsModeloNF)
        AND   decode(vsCgoEntradaEmissao,'S',B.NFEREFERENCIACHAVE, NVL(B.NFECHAVEACESSO,B.NFECHAVEACESSOCOPIA)) = A.CHAVEACESSO
        AND   A.SEQPESSOA     = B.SEQPESSOA
        AND   A.NROEMPRESA    = B.NROEMPRESA
        AND   A.SEQNOTAFISCAL = I.SEQNOTAFISCAL(+)
        AND   A.SEQNFITEM     = I.SEQNFITEM(+)
        AND   P.SEQPRODUTO    = NVL(I.SEQPRODUTO,A.SEQPRODUTO)
        AND   P.SEQFAMILIA    = D.SEQFAMILIA
        AND   D.NRODIVISAO    = M.NRODIVISAO
        AND   M.NROEMPRESA    = pnNroEmpresa
        AND   B.NROEMPRESA    = M.NROEMPRESA
        AND   A.SEQFAMILIA    = F.SEQFAMILIA    (+)
        AND   A.SEQPESSOA     = F.SEQFORNECEDOR (+)
        AND   P.SEQFAMILIA    = C.SEQFAMILIA
        AND   NVL(I.SEQPRODUTO,A.SEQPRODUTO)    > 0
        UNION
        SELECT DISTINCT B.SEQAUXNOTAFISCAL, NVL(I.NROITEM,a.SEQNFITEM), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM),
               -- RP 149708
               CASE WHEN (vsPD_GeraInconsProdCompl = 'N' AND vsIndComplVlrImposto = 'S') AND (NVL(I.SEQPRODUTO, A.SEQPRODUTO) <= 0)  THEN
                   M.SEQPRODUTOCOMPLIMPOSTO
               ELSE
                   NVL(I.SEQPRODUTO, A.SEQPRODUTO) 
               END,              
               
               'R', 
               NVL(I.NROITEM,a.SEQNFITEM),
               0, 
               -- RP 149708
               CASE WHEN (vsPD_GeraInconsProdCompl = 'N' AND vsIndComplVlrImposto = 'S') AND NVL(I.QUANTIDADE,A.QUANTIDADE) <= 0 THEN
                   1
               ELSE
                   CASE WHEN vsPDConvEmbXML = 'S' AND NVL(F.FATORCONVEMBXML,0) > 0 THEN
                       CASE WHEN NVL(C.PESAVEL, 'N') = 'S' THEN
                            round((NVL(I.QUANTIDADE,A.QUANTIDADE) /  F.FATORCONVEMBXML), 3) * NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM)
                       ELSE
                            round((NVL(I.QUANTIDADE,A.QUANTIDADE) /  F.FATORCONVEMBXML) * NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM))
                       END
                   ELSE
                       NVL(I.QUANTIDADE,A.QUANTIDADE) * NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM)
                   END 
               END QUANTIDADE,
                  
               NVL(A.VLRPRODUTO,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.VLRDESCONTO,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO), 0,
               DECODE(vsTipoDespesaNF, 'T', (NVL(A.VLRDESPESA,0) + NVL(A.VLRSEGURO, 0)) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO), 0),
               DECODE(vsTipoDespesaNF, 'T', 0, (NVL(A.VLRDESPESA,0) + NVL(A.VLRSEGURO, 0)) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO)),
               0, 0,
               0, NVL(A.BASEICMS,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.ALIQICMS,0),
               NVL(A.VLRICMS,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.BASEIPI,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.ALIQIPI,0),
               NVL(A.VLRIPI,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.BASEICMSST,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               NVL(A.ALIQICMSST,0),
               NVL(A.VLRICMSST,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO), 0, 0,
               'N', 0, 'E',
               NVL(I.NROPEDIDOSUPRIM,0), A.CFOP,
               '0', 0, 0,
               A.CODACESSO, M.INDCENTRALLOJA,
               A.CODNCMXML, -- RP 125015
               -- RP 125061
               A.VLRPISXML * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               A.VLRCOFINSXML * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
               (SELECT MAX(M.SITUACAONFPISENT) 
                FROM   MAXV_SITUACAONFPISDEV M
                WHERE  M.NROEMPRESA       = PNNROEMPRESA 
                AND    M.SITUACAONFPISSAI = LPAD(TRIM(A.SITUACAONFPISXML),2,'0')),
               (SELECT MAX(M.SITUACAONFCOFINSENT) 
                FROM   MAXV_SITUACAONFCOFINSDEV M 
                WHERE  M.NROEMPRESA       = PNNROEMPRESA 
                AND    M.SITUACAONFCOFINSSAI = LPAD(TRIM(A.SITUACAONFCOFINSXML),2,'0')),
                
                NVL(A.VLRTOTICMSDESONERADO,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                A.MOTIVODESONERACAOICMS,
                A.CODCESTXML,
                -- RP 144958
                A.PERALIQINTPARTILHAICMS, 
                A.PERPARTILHAICMS,
                A.VLRICMSCALCDESTINO, 
                A.VLRICMSCALCORIGEM,
		            A.BASCALCICMSPARTILHA,
                A.PERALIQUOTAFECPPARTILHA,
                A.VLRFECPPARTILHA,

                A.CFOP, 
                CAST(Fmlf_Retorncodorigemmercadoria(Pnorigem      => A.CODORIGEMTRIB,
                                                    PnNroEmpresa  => pnNroEmpresa,
                                                    PnSeqProduto  => CASE WHEN (vsPD_GeraInconsProdCompl = 'N' AND vsIndComplVlrImposto = 'S') AND (NVL(I.SEQPRODUTO, A.SEQPRODUTO) <= 0)  THEN
                                                                         M.SEQPRODUTOCOMPLIMPOSTO 
                                                                     ELSE
                                                                         NVL(I.SEQPRODUTO, A.SEQPRODUTO) 
                                                                     END,
                                                    Pstiporetorno => vsIndTipoCodOrigemImpReceb) AS VARCHAR2(1)),
                NVL(A.VLRICMS,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.VLRICMSST,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.VLRIPI,0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),


                A.BASICMSSTDISTRIB * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) BASICMSSTDISTRIB,
                A.VLRICMSSTDISTRIB * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) VLRICMSSTDISTRIB,
                A.PERALIQICMSSTDISTRIB PERALIQICMSSTDISTRIB,

                A.NROFCI,
                NVL(A.BASEFCPST, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                A.PERALIQFCPST, 
                NVL(A.VLRFCPST, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.BASEFCPICMS, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                A.PERALIQFCPICMS, 
                NVL(A.VLRFCPICMS, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.BASEFCPDISTRIB, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) BASEFCPDISTRIB,
                A.PERALIQFCPDISTRIB PERALIQFCPDISTRIB,
                NVL(A.VLRFCPDISTRIB, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO) VLRFCPDISTRIB,
                --RP194723
                A.PERREDBCICMSEFET, A.VLRBASEICMSEFET, A.PERALIQICMSEFET, A.VLRICMSEFET, A.CODAJUSTEEFD,
                A.INDESCALARELEVANTE, A.CNPJFABRICANTE, A.DIGCNPJFABRICANTE,
                DECODE(F.INDCONSIDTIPFORNCGO, 'S', fc5_cfoptipfornecedorxml(A.CFOP, A.CODORIGEMTRIB, A.CODSITUACAONFXML), NULL), A.VLRICMSDISTRIB,
                A.VLRFRETE,
                A.VLRICMSDIFERIDOXML * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                A.VLRICMSDESONXML, A.MOTDESICMSXML, A.CBENEFXML, A.PERDIFERIDOXML,
                A.UNIDADEXML, A.SEQITEMNFXML, A.QUANTIDADEMBXML, A.QUANTIDADEXML,
                A.VLRSEGURO * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                A.CODSITUACAONFXML, A.CODORIGEMTRIB,
                NVL(A.BASEICMS, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.BASEICMSST, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.VLRFCPICMS, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.VLRFCPST, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                NVL(A.VLRICMSSIMPLES, 0) * fc_CalcPropQtde(I.SEQNOTAFISCAL, A.SEQPRODUTO, NVL(I.QUANTIDADE, A.QUANTIDADE), NVL(I.QUANTIDADENF, A.QUANTIDADE), NVL(I.QTDEMBALAGEM, A.QTDEMBALAGEM), COALESCE(I.QTDEMBALAGEM, F.EMBPADRAOIMPXML, A.QTDEMBALAGEM), vsPD_vsPDConvEmbPedXml, I.INDUTILPEDSECUNDARIO),
                
                A.DESCPRODUTO,
                A.BASICMSMONO, A.PERALIQICMSMONO, A.VLRICMSMONO, 
                A.BASICMSMONORETEN, A.PERALIQICMSMONORETEN, A.VLRICMSMONORETEN,
                A.BASICMSMONODIF, A.PERALIQICMSMONODIF, A.VLRICMSMONODIF,
                A.BASICMSMONORETANTERIOR, A.PERALIQICMSMONORETANTERIOR, A.VLRICMSMONORETANTERIOR,
                A.SeqItemOrigXml,
                DECODE(A.IndSubIcmsDesTotNf, 1, 'S', 0, 'N', CASE WHEN A.IndSubIcmsDesTotNf IS NULL THEN
                  CASE WHEN A.Vlricmsdesonxml IS NOT NULL THEN vsIndSubICMSDesTotNF 
                    ELSE vsPDIndDeduzIcmsDeson END ELSE vsIndSubICMSDesTotNF END)
        FROM MRLX_NFEIMPORTACAOITEM A, MLF_AUXNOTAFISCAL B, MRL_NFEITEMPEDIDO I, MAX_EMPRESA M, MAP_FAMFORNEC F,
             MAP_FAMDIVISAO D, MAP_FAMILIA C
        WHERE A.SEQNOTAFISCAL = pnIDNFe
        --AND   B.SEQNOTAFISCAL = A.SEQNOTAFISCAL
        AND   (vsModeloNF is null or B.MODELONF = vsModeloNF)
        AND   decode(vsCgoEntradaEmissao,'S',B.NFEREFERENCIACHAVE,NVL(B.NFECHAVEACESSO,B.NFECHAVEACESSOCOPIA) ) = A.CHAVEACESSO
        AND   A.SEQPESSOA     = B.SEQPESSOA
        AND   A.NROEMPRESA    = B.NROEMPRESA
        AND   A.SEQNOTAFISCAL = I.SEQNOTAFISCAL(+)
        AND   A.SEQNFITEM     = I.SEQNFITEM(+)
        AND   B.NROEMPRESA    = M.NROEMPRESA
        AND   A.SEQFAMILIA    = F.SEQFAMILIA    (+)
        AND   A.SEQPESSOA     = F.SEQFORNECEDOR (+)        
        AND   A.SEQFAMILIA    = D.SEQFAMILIA
        AND   D.NRODIVISAO    = M.NRODIVISAO
        AND   D.SEQFAMILIA    = C.SEQFAMILIA
        AND   M.NROEMPRESA    = pnNroEmpresa
        AND   NVL(I.SEQPRODUTO, A.SEQPRODUTO)    = 0
        ORDER BY 1,4;
        
        BEGIN
         vsProdutos := '';
         FOR produto IN (SELECT B.SEQPRODUTO
                         FROM   MLF_AUXNOTAFISCAL A, MLF_AUXNFITEM B
                         WHERE  A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                         AND    A.SEQNOTAFISCAL = vnSeqM000_ID_NF
                         AND    B.QUANTIDADE = 0
                         ) 
         LOOP
          IF vsProdutos IS NOT NULL THEN
           vsProdutos := vsProdutos || ', ';
          END IF;
          IF length(vsProdutos) + length(produto.Seqproduto) > 1000 THEN
           EXIT;
          END IF;
          vsProdutos := vsProdutos || produto.Seqproduto;
         END LOOP;
         IF vsProdutos IS NOT NULL THEN
          RAISE_APPLICATION_ERROR(-20500, '#Os seguintes produtos possuem erro de configuração no fator de conversão:
' || vsProdutos || '#');
         END IF;
        END;
        
        -- Ajuste arredondamento após cálculo pela proporção de pedido secundário
        SP_AJUSTEARREDITENS( vnSeqAuxNF, pnIDNFe, pnNroEmpresa );
       -- Aplica o valor de desconto financeiro
       PKG_MLF_RECEBIMENTO.SP_RATEIADESCFINANC( vnSeqAuxNF, 0 );
        
       -- Verifica se foi processado alguma linha
        vnLinhasProc := SQL%ROWCOUNT;
        If vnLinhasProc = 0 Then
          pnImpOK := 0; 
    
          
          -- Grava o log de ERRO da importação dos itens
             INSERT INTO MRL_NFELOGIMPORT(
    	          SEQLOG, DTAIMPORTACAO,
    	          USUIMPORTACAO, TIPLOG, SEQAUXNOTAFISCAL,
                SEQNOTAFISCAL, NROEMPRESA, SEQPESSOA,
                HISTORICO)
        
             SELECT S_SEQNFELOGIMPORT.NEXTVAL, SYSDATE,
                   psUsuLancto, 'E', A.SEQAUXNOTAFISCAL,
                   pnIDNFe, A.NROEMPRESA, A.SEQPESSOA,
                   'Não foi importado nenhum ítem para nota ' || A.NUMERONF ||
                      ' Série ' || A.SERIENF ||
                      ' Forn. ' || A.SEQPESSOA ||
                      ' Empr. ' || A.NROEMPRESA
            
             FROM   MLF_AUXNOTAFISCAL A
             WHERE  A.SEQNOTAFISCAL = vnSeqM000_ID_NF;
        Else
          if vsIndUtilCustoPrecifComer = 'S' then
            for vtCCDiv in ( SELECT A.SEQAUXNOTAFISCAL SEQAUXNOTAFISCAL,
                                    B.SEQAUXNFITEM SEQAUXNFITEM,
                                    NVL(B.NROPEDIDOSUPRIM, 0) NROPEDIDOSUPRIM,
                                    A.VLRFRETENANF VLRFRETENANF,
                                    NVL(A.TIPRATFRETE, 'V') TIPRATFRETE,
                                    NVL(A.INDRECALCFRETENANF,'N') INDRECALCFRETENANF,
                                    E.TIPDOCFISCAL TIPDOCFISCAL,
                                    B.VLRITEM VLRITEM,
                                    SUM(B.VLRITEM) OVER() TOTALVLRITEM,
                                    D.PESOBRUTO * (B.QUANTIDADE / B.QTDEMBALAGEM) PESOITEM,
                                    SUM(D.PESOBRUTO * (B.QUANTIDADE / B.QTDEMBALAGEM)) OVER() TOTALPESOITEM
                             FROM MLF_AUXNOTAFISCAL  A,
                                  MLF_AUXNFITEM      B,
                                  MAP_PRODUTO        C,
                                  MAP_FAMEMBALAGEM   D,
                                  MAX_CODGERALOPER   E
                             WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                             AND   B.SEQPRODUTO       = C.SEQPRODUTO
                             AND   C.SEQFAMILIA       = D.SEQFAMILIA
                             AND   A.CODGERALOPER     = E.CODGERALOPER
                             AND   B.QTDEMBALAGEM     = D.QTDEMBALAGEM
                             AND   A.SEQNOTAFISCAL    = vnSeqM000_ID_NF
                             AND B.SEQAUXNFITEM <= 990
                             ORDER BY B.SEQAUXNFITEM )
            loop                 
              if vtCCDiv.Nropedidosuprim > 0 then  
                pkg_mlf_recebimento.sp_geraimpostospedido(vtCCDiv.Seqauxnotafiscal, vtCCDiv.seqauxnfitem);
              end if;
              IF vsPD_RateiaFreteNFItens = 'S' THEN
                  IF vtCCDiv.Totalvlritem > 0 THEN
                     vnPerc := vtCCDiv.Vlritem / vtCCDiv.Totalvlritem;
                  END IF;
                  IF vtCCDiv.Totalpesoitem > 0 THEN
                     vnPercPeso := vtCCDiv.Pesoitem / vtCCDiv.Totalpesoitem;
                  END IF;
                  PKG_MLF_RECEBIMENTO.SP_RATEIAFRETENANF( vtCCDiv.Seqauxnotafiscal,
                                                          vtCCDiv.Seqauxnfitem,
                                                          vtCCDiv.Vlrfretenanf,
                                                          vtCCDiv.Tipratfrete,
                                                          vnPercPeso,
                                                          vnPerc,
                                                          vnVlrFreteNaNotaItem,
                                                          vnTotFreteNaNotaSoma
                                                         );
                                                         
                   UPDATE MLF_AUXNFITEM
                   SET VLRFRETENANF = CASE WHEN vnTotFreteNaNotaSoma IS NULL OR
                                                (vtCCDiv.INDRECALCFRETENANF = 'N' AND
                                                 vtCCDiv.TIPDOCFISCAL = 'D')
                                           THEN
                                             VLRFRETENANF
                                           ELSE
                                             vnVlrFreteNaNotaItem
                                      END
                    WHERE SEQAUXNOTAFISCAL = vtCCDiv.Seqauxnotafiscal
                    AND SEQAUXNFITEM = vtCCDiv.Seqauxnfitem;

                    vnTotVlrFreteNaNF    := vtCCDiv.Vlrfretenanf;
                    vsIndRecalcFreteNaNF := vtCCDiv.Indrecalcfretenanf;
                    vsTipDocFiscal       := vtCCDiv.Tipdocfiscal;
                    vnSeqAuxNotaFiscal   := vtCCDiv.Seqauxnotafiscal;
                    vnUltimoSeq          := vtCCDiv.Seqauxnfitem;

              END IF;
            end loop;
            IF vsPD_RateiaFreteNFItens = 'S' THEN
                If vnTotFreteNaNotaSoma != 0 Then
                   vnTotFreteNaNotaSoma := vnTotVlrFreteNaNF - vnTotFreteNaNotaSoma;
                End If;
                UPDATE MLF_AUXNFITEM
                   SET VLRFRETENANF = CASE WHEN vnTotFreteNaNotaSoma = 0 OR
                                                (vsIndRecalcFreteNaNF = 'N' AND
                                                 vsTipDocFiscal = 'D')
                                           THEN
                                             VLRFRETENANF
                                           ELSE
                                             VLRFRETENANF + vnTotFreteNaNotaSoma
                                      END
                    WHERE SEQAUXNOTAFISCAL = vnSeqAuxNotaFiscal
                    AND SEQAUXNFITEM = vnUltimoSeq;
            END IF;
          end if;
        
        End If;
      END If;  
      
        
      
      --RP 109871-----------------------------------------------------------------------------------------
      --Verifica parâmetro vsPD_vsPDConvEmbPedXml = 'S' 
        If vsPD_vsPDConvEmbPedXml = 'S' Then
        --  Busca itens da nota que tem pedido e se a familia do produto está configurado embalagem de importacao de xml 
        FOR T IN ( SELECT A.SEQAUXNOTAFISCAL,A.SEQAUXNFITEM, A.NROPEDIDOSUPRIM,A.SEQPRODUTO,
                          A.QTDEMBALAGEM, A.QUANTIDADE, A.CENTRALLOJA, B.NROEMPRESA, D.EMBPADRAOIMPXML
                    FROM MLF_AUXNFITEM A,
                         MLF_AUXNOTAFISCAL B,
                         MAP_PRODUTO C,
                         MAP_FAMFORNEC D
                    WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL  
                    AND   A.SEQPRODUTO = C.SEQPRODUTO
                    AND   B.SEQPESSOA = D.SEQFORNECEDOR
                    AND   C.SEQFAMILIA = D.SEQFAMILIA
                    AND   DECODE(vsCgoEntradaEmissao,'S',B.NFEREFERENCIACHAVE, NVL(B.NFECHAVEACESSO,B.NFECHAVEACESSOCOPIA)) = pnChaveNFE
                    AND   B.SEQNOTAFISCAL =  vnSeqM000_ID_NF
                    AND   A.NROPEDIDOSUPRIM IS NOT NULL
                    AND   D.EMBPADRAOIMPXML IS NOT NULL
                    ORDER BY A.SEQAUXNFITEM)
          LOOP 
             
               /*Pega quantidade de embalagem dos itens do pedido para atualizar nos itens da nota*/
                vnQtdeEmb := null;
                SELECT MAX(R.QTDEMBALAGEM)
                INTO   vnQtdeEmb
                FROM   MSU_PSITEMRECEBER  R
                WHERE  R.NROPEDIDOSUPRIM  = T.NROPEDIDOSUPRIM
                AND    R.SEQPRODUTO       = T.SEQPRODUTO 
                AND    R.CENTRALLOJA      = T.CENTRALLOJA
                AND    R.NROEMPRESA       = T.NROEMPRESA; 
               
                /*Atualiza item da nota conforme item do pedido*/
                -- RP 154044 - Inserido para atualizar a coluna de Quantidade
                IF vnQtdeEmb IS NOT NULL AND T.QTDEMBALAGEM != vnQtdeEmb
                THEN
                  UPDATE MLF_AUXNFITEM I 
                  SET    I.QTDEMBALAGEM = vnQtdeEmb
                         --I.QUANTIDADE = ( T.QUANTIDADE * T.EMBPADRAOIMPXML / vnQtdeEmb )
                  WHERE  I.SEQAUXNOTAFISCAL = T.SEQAUXNOTAFISCAL
                  AND    I.SEQAUXNFITEM = T.SEQAUXNFITEM;  
                END IF;                                                          
             
            
          END LOOP;  
        End If;
      --Fim RP 109871-----------------------------------------------------------------------------------------
      
      If pnImpOK = 1 THEN
      
        pkg_mlf_recebimento.SP_CONSISTEAUXNOTAFISCAL(vnSeqAuxNF); --RC 184906
      --REQ.78745  
         --RC 112883 
         SELECT NVL(MAX(INDRECEBVENCVLRLIQ), 'N')
           INTO vsRecebVencVlrLiq
           FROM MAF_FORNECEDOR A
          WHERE A.SEQFORNECEDOR = vnSeqFornec;
          --RP 226941 RC 221239
          SELECT COUNT(*)
          INTO vnCount
          FROM MAX_EMPRESA G
          WHERE G.SEQPESSOAEMP = vnSeqFornec;        
         if vsRecebVencVlrLiq = 'N' and vnCount = 0 then
         
           --BUSCA PERCENTUAL
           begin
            SELECT   CASE WHEN F.TPOCALCDESCFINANC = 'P'
                         THEN DECODE(NVL(SUM(I.VLRITEM), 0), 0, 0, (SUM(I.VLRDESCFINCALC) / SUM(I.VLRITEM)) * 100)
                     ELSE
                         DECODE(NVL(SUM(I.VLRTOTALITEM), 0), 0, 0, (SUM(I.VLRDESCFINCALC) / SUM(I.VLRTOTALITEM)) * 100)   
                     END 
            INTO    vnPerFinanc
            FROM    MLF_AUXNFITEM I ,
                    MLF_AUXNOTAFISCAL F
                          
            WHERE   I.SEQAUXNOTAFISCAL = F.SEQAUXNOTAFISCAL
            AND     F.SEQNOTAFISCAL = vnSeqM000_ID_NF
            
            GROUP BY F.TPOCALCDESCFINANC;
           exception
             when others then
                vnPerFinanc := 0;
             end;    
         else 
           vnPerFinanc:= 0;
         end if;
        
        
          --BUSCA OS PRAZOS DE PAGAMENTO EX 0/30/60 - EM LINHAS
         SELECT  fc5_strtokenize(NVL(DECODE(vsPDUtilCondPagtoContrFidel, 'S', NVL(CP.CONDPRAZOPAGTO,  F.PZOPAGAMENTO),  F.PZOPAGAMENTO), '0'), '/' ), F.INDIMPTITULOXMLEDI
         INTO    vsArrayPrazoPagto, vsIndImpTituloXmlEdi
         FROM    MAF_FORNECDIVISAO F,
                 MAX_EMPRESA E,
                 MLF_AUXNOTAFISCAL A,
                 MRL_CONDPRAZOPAGTO CP
         WHERE  F.NRODIVISAO = E.NRODIVISAO
         AND    F.SEQFORNECEDOR = A.SEQPESSOA
         AND    E.NROEMPRESA = A.NROEMPRESA
         AND    F.SEQCONDCONDPRAZOPAGTO  = CP.SEQCONDCONDPRAZOPAGTO (+)
         AND    A.NROEMPRESA = pnNroEmpresa
         AND    A.SEQNOTAFISCAL = vnSeqM000_ID_NF;

         -- BUSCA OS PRAZOS DE PAGAMENTO DO PEDIDO
         SELECT fc5_strtokenize(NVL(MAX((SELECT SUBSTR(C5_COMPLEXIN.C5INSTRING(CAST(COLLECT(TO_CHAR(COLUMN_VALUE + FBUSCADIASPRORROGCONTRATOFIDEL(P.SEQFORNECEDOR, 
                                                                                                                                                  P.NROEMPRESA, 
                                                                                                                                                  N.SEQPRODUTO, 
                                                                                                                                                  P.DTAEMISSAO))) AS C5INSTRTABLE), '/' ), 1, 40)
                                     FROM TABLE(C5_COMPLEXIN.C5INTABLE(P.PZOPAGAMENTO, '/')))), '0'), '/' ),
                MAX(decode(vsPD_ConsidDtaVencPed,'S',P.DTAVENCTOFIXA,null))
           INTO vsArrayPrazoPagtoPedido,
                vdDtaVencFixa
           FROM MSU_PEDIDOSUPRIM P,
                MRL_NFEITEMPEDIDO N
          WHERE P.NROPEDIDOSUPRIM = N.NROPEDIDOSUPRIM
            AND P.NROEMPRESA = pnNroEmpresa
            AND N.SEQNOTAFISCAL = pnIDNFe;
         
         SELECT count(1)
           INTO vnExistePedido
           FROM MSU_PEDIDOSUPRIM P,
                MRL_NFEITEMPEDIDO N
          WHERE P.NROPEDIDOSUPRIM = N.NROPEDIDOSUPRIM
            AND P.NROEMPRESA = pnNroEmpresa
            AND N.SEQNOTAFISCAL = pnIDNFe;
         
         if vnExistePedido > 0 and vsPD_IndPrazoTit = 'S' then
           
           SELECT count(1)
             INTO vnExistePedidoPzo
             FROM MSU_PEDIDOSUPRIM P,
                  MRL_NFEITEMPEDIDO N
            WHERE P.NROPEDIDOSUPRIM = N.NROPEDIDOSUPRIM
              AND P.NROEMPRESA = pnNroEmpresa
              AND N.SEQNOTAFISCAL = pnIDNFe
              AND P.PZOPAGAMENTO IS NOT NULL;
              
         end if;

         vsPzoPagamento :='0'; 
        
         --- BUSCA A DTA BASE DE VENCIMENTO E O INDICE DE PRAZO DE PAGAMENTO 
         
         SELECT DTABASEVECTO , INDPZOPAGAMENTO
           INTO vdDtaBaseVencto, vsIndPrazoPagto 
                                  
             
         FROM (
               SELECT      NVL(F.INDPZOPAGAMENTO, 'F') INDPZOPAGAMENTO,
                           F.PERCDESCFINACORDO,
                           F.TIPODTABASEVENCTO,
                           F.TIPODTADESCFINANC,
                           NVL(F.QTDDIASANTDESCFIN, 0),
                           
                           NVL(
                                CASE WHEN F.TIPODTABASEVENCTO = 'R' THEN 
                                     A.DTAENTRADA
                                WHEN F.TIPODTABASEVENCTO = 'S' THEN
                                     A.DTASAIDA      
                                ELSE 
                                     A.DTAEMISSAO
                                END, TRUNC(SYSDATE)) AS DTABASEVECTO 
                                     
                           
                    FROM   MAF_FORNECDIVISAO F,
                           MAX_EMPRESA E,
                           MLF_AUXNOTAFISCAL A
                    WHERE  F.NRODIVISAO = E.NRODIVISAO
                    AND    F.SEQFORNECEDOR = A.SEQPESSOA
                    AND    E.NROEMPRESA = A.NROEMPRESA
                    AND    A.NROEMPRESA = pnNroEmpresa
                    AND    A.SEQNOTAFISCAL = vnSeqM000_ID_NF
          );     
          
        --
        SELECT SUM(B.VLROPCONTRATODESC),
               SUM(B.VLROPCONTRATORET),
               SUM(B.VLRDESCCONTRATO)
          INTO vnVlrOperDesc,      
               vnVlrOperRet,       
               vnVlrDescContrato
          FROM MLF_AUXNFITEM B
         WHERE B.SEQAUXNOTAFISCAL = vnSeqAuxNF;  
       
        -- RC 126114
        if vsPD_ImpInfoTitXmlEdi = 'S' OR (vsPD_ImpInfoTitXmlEdi = 'F' AND vsIndImpTituloXmlEdi = 'S') then 
        -- RC 124876
        if vsPD_IndPrazoTit in('X','S') Or vdDtaVencFixa is not null then                    
          
          -- Fornecedor
           vsArrayPrazoPagtoAux := vsArrayPrazoPagto;
          
           if vsPD_IndPrazoTit = 'S' and vnExistePedidoPzo != 0 then 
              -- Pedido
               vsArrayPrazoPagtoAux := vsArrayPrazoPagtoPedido;
           end if;    
           
           
            --* Recebimento conforme vencimentos do xml
           
           
            vnQtde         := 1;  
            ---
            SELECT COUNT(1)
              INTO vnContParc 
              FROM TMP_M004_DUPLICATA A, MLF_AUXNOTAFISCAL B, TMP_M000_NF C
             WHERE A.M000_ID_NF = pnIDNFe
               AND decode(vsCgoEntradaEmissao,'S',B.NFEREFERENCIACHAVE, NVL(B.NFECHAVEACESSO,B.NFECHAVEACESSOCOPIA)) = C.M000_NR_CHAVE_ACESSO
               AND C.M000_ID_NF = A.M000_ID_NF;
           
            --
            if vnContParc > 0 then
              vnVlrOperDescParc := ROUND((vnVlrOperDesc / vnContParc), 5);
              vnVlrOperRetParc := ROUND((vnVlrOperRet / vnContParc), 5);
              vnVlrDescContratoParc := ROUND((vnVlrDescContrato / vnContParc), 5);
            end if;
            --Insere os dados do pagamento
            FOR T IN ( SELECT B.SEQAUXNOTAFISCAL SEQAUXNOTAFISCAL,
                              B.SEQPESSOA SEQPESSOA,
                              A.M004_DT_VENCIMENTO DTAVENCIMENTO, 
                              NVL(A.M004_VL_DUPLICATA,0) VLRDUPLICATA
                        FROM  TMP_M004_DUPLICATA A, MLF_AUXNOTAFISCAL B, TMP_M000_NF C
                        WHERE A.M000_ID_NF = pnIDNFe
                        --AND   B.SEQNOTAFISCAL = A.M000_ID_NF
                        AND   decode(vsCgoEntradaEmissao,'S',B.NFEREFERENCIACHAVE, NVL(B.NFECHAVEACESSO,B.NFECHAVEACESSOCOPIA)) = C.M000_NR_CHAVE_ACESSO
                        AND   C.M000_ID_NF = A.M000_ID_NF
                        AND   B.NROEMPRESA = pnNroEmpresa
                        ORDER BY A.M000_ID_NF, B.SEQAUXNOTAFISCAL, A.M004_ID_DUPLICATA )
            LOOP
                      -- RC 182470
                      if vdDtaVencFixa is not null then
                         vdDtaVencimento := vdDtaVencFixa;
                      else
                         vdDtaVencimento := T.DTAVENCIMENTO;
                      end if;  
              
                      vnVlrFunRural            := 0;
                      vnVlrOperDescRest        := 0;
                      vnVlrOperRetRest         := 0; 
                      vnVlrDescContratoRest    := 0;
                      vnVlrFunSenar            := 0;
                      vnVlrFunRat              := 0;
                      vnVlrFunPrevSocial       := 0;
                        -----------Busca prazo do pedido
                        if vnQtde > vsArrayPrazoPagtoAux.Count then                     
                           vdDtaLimDescFinanc := null;
                           vnDiasPzo := null;
                           
                        else
                        
                            IF vsIndPrazoPagto = 'F' THEN
                                vdDtaLimDescFinanc := vdDtaBaseVencto +  to_number(trim(vsArrayPrazoPagtoAux(vnQtde)));
                            ELSE
                                vdDtaLimDescFinanc := FMAD_CALCDTAVENCTO(vdDtaBaseVencto, vsIndPrazoPagto, to_number(vsArrayPrazoPagtoAux(vnQtde)), NULL);
                            END IF;
                            
                            vnDiasPzo := TO_NUMBER(vsArrayPrazoPagtoAux(vnQtde));
                            
                        end if;
                        
                        
                        -----------Busca prazo fornecedor
                        
                        if vnQtde > vsArrayPrazoPagtoAux.Count then                     
                           vdDtaLimDescFinanc := null;
                           vnDiasPzo := null;
                           
                        else
                        
                            IF vsIndPrazoPagto = 'F' THEN
                                vdDtaLimDescFinanc := vdDtaBaseVencto +  to_number(trim(vsArrayPrazoPagtoAux(vnQtde)));
                            ELSE
                                vdDtaLimDescFinanc := FMAD_CALCDTAVENCTO(vdDtaBaseVencto, vsIndPrazoPagto, to_number(vsArrayPrazoPagtoAux(vnQtde)), NULL);
                            END IF;
                            
                            
                            -- RP 148994
                            -- Busca dados para checagem
                            SELECT F.TIPODTADESCFINANC, NVL(F.QTDDIASANTDESCFIN,0)
                              INTO vsTipoDtaDescFinanc, vnQtdeDiasAntDescFinanc
                              FROM MAF_FORNECDIVISAO F, MAX_EMPRESA E  
                             WHERE F.NRODIVISAO = E.NRODIVISAO
                               AND E.NROEMPRESA = pnNroEmpresa
                               AND F.SEQFORNECEDOR = T.SEQPESSOA;
                            
                            If nvl(vsTipoDtaDescFinanc,'V')  = 'N' THEN
                               -- fixo
                               SELECT TO_DATE('31-DEC-2050')
                                 INTO vdDtaLimDescFinanc
                                FROM DUAL; 
                            ElsIf nvl(vsTipoDtaDescFinanc,'V')  = 'A' then
                                vdDtaLimDescFinanc := vdDtaLimDescFinanc	- vnQtdeDiasAntDescFinanc;
                            End if;
                            --- 
                            
                            
                            vnDiasPzo := TO_NUMBER(vsArrayPrazoPagtoAux(vnQtde));
                            
                        end if;
                          if vnQtde = 1 then
                            -- RC 117291
                            SELECT NVL(MAX(N.VLRFUNRURAL), SUM(B.VLRFUNRURALITEM)),
                                   MAX(CASE 
                                     WHEN (NVL(B.TIPPEDCOMPRAITEM, 'C') = 'B' OR NVL(B.TIPPEDCOMPRAITEM, 'C') = 'E') AND N.TIPPEDIDOCOMPRA = 'C' THEN 
                                          DECODE(vsPD_ConsideraVlrPedBonif, 'S', B.PERCDESCCONTRATO, NULL)
		                                  ELSE 
                                          B.PERCDESCCONTRATO
                                     	END),
                                   NVL(MAX(N.VLRFUNSENAR), SUM(B.VLRFUNSENAR)),
                                   NVL(MAX(N.VLRFUNRAT), SUM(B.VLRFUNRAT)),
                                   NVL(MAX(N.VLRFUNPREVSOCIAL), SUM(B.VLRFUNPREVSOCIAL))
                              INTO vnVlrFunRural, 
                                   vnPercDescContrato,
                                   vnVlrFunSenar,
                                   vnVlrFunRat,
                                   vnVlrFunPrevSocial 
                              FROM MLF_AUXNFITEM B, MLF_AUXNOTAFISCAL N
                             WHERE N.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                               AND B.SEQAUXNOTAFISCAL = T.SEQAUXNOTAFISCAL;
                             --
                             if vnContParc > 0 then
                               vnVlrOperDescRest        := vnVlrOperDesc - (vnVlrOperDescParc * vnContParc);
                               vnVlrOperRetRest         := vnVlrOperRet - (vnVlrOperRetParc * vnContParc);
                               vnVlrDescContratoRest    := vnVlrDescContrato - (vnVlrDescContratoParc * vnContParc);
                             end if;                                              
                          end if;
              		  
			  
			                  SELECT S_SEQAUXNFVENCTO.NEXTVAL
                        INTO   vnSeqAuxNFVencto
                        FROM   DUAL;
                        
                        SELECT S_SEQAUXNFVENCTO.NEXTVAL
                        INTO   vnSeqAuxNFVenctoXML
                        FROM   DUAL;
			
                          INSERT INTO MLF_AUXNFVENCIMENTO(
                    	                                    SEQAUXNOTAFISCAL, 
                                                          SEQAUXNFVENCTO,
                                                          DTAVENCIMENTO, 
                                                          VLRTOTAL, 
                                                          INDPRAZOPAGTO,
                                                          PERCDESCFINANC, 
                                                          VLRDESCFINANC, 
                                                          DIASPRAZO, 
                                                          DTALIMDESCFINANC,
                                                          VLRDESCFUNRURAL,
                                                          VLROPCONTRATODESC,
                                                          VLROPCONTRATORET,
                                                          VLRDESCCONTRATO,
                                                          PERCDESCCONTRATO, 
                                                          PERCOMPROR, 
                                                          PRAZOPAGTOCOMPROR,
                                                          SEQAUXNFVENCTOXML,
                                                          VLRDESCFUNSENAR,
                                                          VLRDESCFUNRAT,
                                                          VLRDESCFUNPREVSOCIAL)
                          VALUES (T.SEQAUXNOTAFISCAL,
                                  vnSeqAuxNFVencto,
                                  vdDtaVencimento, 
                                  T.VLRDUPLICATA, 
                                  'F', 
                                  vnPerFinanc, 
                                  (T.VLRDUPLICATA * vnPerFinanc)/100, 
                                  vnDiasPzo,
                                  vdDtaLimDescFinanc,
                                  vnVlrFunRural,
                                  vnVlrOperDescParc + vnVlrOperDescRest,      
                                  vnVlrOperRetParc + vnVlrOperRetRest,       
                                  vnVlrDescContratoParc + vnVlrDescContratoRest,
                                  vnPercDescContrato,
                                  decode(vsPD_ComprorFornecRecebto,'S',fmrl_dadoscompror(T.SEQAUXNOTAFISCAL,'C',0),NULL),
                                  decode(vsPD_ComprorFornecRecebto,'S',fmrl_dadoscompror(T.SEQAUXNOTAFISCAL,'P',0),NULL),
                                  vnSeqAuxNFVenctoXML,
                                  vnVlrFunSenar,
                                  vnVlrFunRat,
                                  vnVlrFunPrevSocial 
                                 );
                                                   
                          -- RC 126114
                          INSERT INTO MLF_AUXNFVENCIMENTOXML(
                    	                                    SEQAUXNOTAFISCAL, 
                                                          SEQAUXNFVENCTO,
                                                          DTAVENCIMENTO, 
                                                          VLRTOTAL, 
                                                          INDPRAZOPAGTO,
                                                          PERCDESCFINANC, 
                                                          VLRDESCFINANC, 
                                                          DIASPRAZO, 
                                                          DTALIMDESCFINANC,
                                                          VLRDESCFUNRURAL,
                                                          VLROPCONTRATODESC,
                                                          VLROPCONTRATORET,
                                                          VLRDESCCONTRATO,
                                                          PERCDESCCONTRATO,
                                                          VLRDESCFUNSENAR,
                                                          VLRDESCFUNRAT,
                                                          VLRDESCFUNPREVSOCIAL)
                          VALUES (T.SEQAUXNOTAFISCAL, 
                                  vnSeqAuxNFVenctoXML,
                                  vdDtaVencimento, 
                                  T.VLRDUPLICATA, 
                                  'F', 
                                  vnPerFinanc, 
                                  (T.VLRDUPLICATA * vnPerFinanc)/100, 
                                  vnDiasPzo,
                                  vdDtaLimDescFinanc,
                                  vnVlrFunRural,
                                  vnVlrOperDescParc + vnVlrOperDescRest,      
                                  vnVlrOperRetParc + vnVlrOperRetRest,       
                                  vnVlrDescContratoParc + vnVlrDescContratoRest,
                                  vnPercDescContrato,
                                  vnVlrFunSenar,
                                  vnVlrFunRat,
                                  vnVlrFunPrevSocial);
                                                                   
                     -- RC 196969
                     vnDiasPzoAux := null;
                     if (vdDtaVencimento - vdDtaBaseVencto) <= 9999 then
                       vnDiasPzoAux := NVL(vdDtaVencimento - vdDtaBaseVencto, vnDiasPzo);
                     end if;
                               
			               UPDATE MLF_AUXNFVENCIMENTO
                          SET    DIASPRAZO = NVL(vnDiasPzoAux, vnDiasPzo),
                                 DIASPZOPED = case when vsPD_IndPrazoTit != 'S' then
                                                   NVL(vnDiasPzoAux, vnDiasPzo)
                                              when vnDiasPzo is not null then
                                                   NVL(FMAD_CALCDTAVENCTO(vdDtaBaseVencto, vsIndPrazoPagto, vnDiasPzo, NULL) - vdDtaBaseVencto, vnDiasPzo)
                                              else
                                                   DIASPZOPED
                                              end
                          WHERE  SEQAUXNOTAFISCAL = T.SEQAUXNOTAFISCAL
                          AND    SEQAUXNFVENCTO = vnSeqAuxNFVencto;
                     
                     UPDATE MLF_AUXNFVENCIMENTOXML
                          SET    DIASPRAZO = NVL(vnDiasPzoAux, vnDiasPzo),
                                 DIASPZOPED = case when vsPD_IndPrazoTit != 'S' then
                                                   NVL(vnDiasPzoAux, vnDiasPzo)
                                              when vnDiasPzo is not null then
                                                   NVL(FMAD_CALCDTAVENCTO(vdDtaBaseVencto, vsIndPrazoPagto, vnDiasPzo, NULL) - vdDtaBaseVencto, vnDiasPzo)
                                              else
                                                   DIASPZOPED
                                              end
                          WHERE  SEQAUXNOTAFISCAL = T.SEQAUXNOTAFISCAL
                          AND    SEQAUXNFVENCTO = vnSeqAuxNFVenctoXML;
                          

			                  vnQtde := vnQtde + 1; 
              END LOOP;                
          elsif vsPD_IndPrazoTit = 'F' or vsPD_IndPrazoTit = 'P'  then
          --** Recebimento conforme prazos do fornecedor ou pedido
          
              if vsPD_IndPrazoTit = 'F' or vnExistePedido = 0 then 
                  -- Fornecedor
                  vsArrayPrazoPagtoAux := vsArrayPrazoPagto;
              else 
                  -- Pedido
                  vsArrayPrazoPagtoAux := vsArrayPrazoPagtoPedido;
              end if;
              
              
              
              
              vnContParc := vsArrayPrazoPagtoAux.Count;
       
              vnVlrFunRural   := 0;
              vnVlrTotalItem  := 0;
              vnVlrDescFinanc := 0;
              vnPercDescContrato := 0;
              vnVlrFunSenar            := 0;
              vnVlrFunRat              := 0;
              vnVlrFunPrevSocial       := 0;
              
              vnQtde          := 1;
              FOR T IN ( SELECT B.SEQAUXNOTAFISCAL SEQAUXNOTAFISCAL,
                                B.SEQPESSOA SEQPESSOA,
                                NVL(A.M004_VL_DUPLICATA,0) VLRDUPLICATA
                          FROM TMP_M004_DUPLICATA A, MLF_AUXNOTAFISCAL B, TMP_M000_NF C
                          WHERE A.M000_ID_NF = pnIDNFe
                          --AND   B.SEQNOTAFISCAL = A.M000_ID_NF
                          AND   decode(vsCgoEntradaEmissao,'S',B.NFEREFERENCIACHAVE, NVL(B.NFECHAVEACESSO,B.NFECHAVEACESSOCOPIA)) = C.M000_NR_CHAVE_ACESSO
                          AND     C.M000_ID_NF     = A.M000_ID_NF
                          ORDER BY A.M000_ID_NF, B.SEQAUXNOTAFISCAL, A.M004_ID_DUPLICATA )
              LOOP
                  vnVlrTotalItem  := vnVlrTotalItem + T.VLRDUPLICATA;
                  vnVlrDescFinanc := vnVlrDescFinanc + ((T.VLRDUPLICATA * vnPerFinanc)/100);
                  
                  if vnQtde = 1 then
                    SELECT NVL(MAX(N.VLRFUNRURAL), SUM(B.VLRFUNRURALITEM)),
                           MAX(CASE 
                             WHEN (NVL(B.TIPPEDCOMPRAITEM, 'C') = 'B' OR NVL(B.TIPPEDCOMPRAITEM, 'C') = 'E') AND N.TIPPEDIDOCOMPRA = 'C' THEN 
                                  DECODE(vsPD_ConsideraVlrPedBonif, 'S', B.PERCDESCCONTRATO, NULL)
                            ELSE 
                                  B.PERCDESCCONTRATO
                             	END),
                           NVL(MAX(N.VLRFUNSENAR), SUM(B.VLRFUNSENAR)),
                           NVL(MAX(N.VLRFUNRAT), SUM(B.VLRFUNRAT)),
                           NVL(MAX(N.VLRFUNPREVSOCIAL), SUM(B.VLRFUNPREVSOCIAL))
                      INTO vnVlrFunRural, 
                           vnPercDescContrato,
                           vnVlrFunSenar,
                           vnVlrFunRat,
                           vnVlrFunPrevSocial
                      FROM MLF_AUXNFITEM B, MLF_AUXNOTAFISCAL N
                     WHERE N.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                        AND B.SEQAUXNOTAFISCAL = T.SEQAUXNOTAFISCAL;
                  end if;
                  
                  vnSeqAuxNotaFiscal := T.SEQAUXNOTAFISCAL;
                  vnSeqPessoa        := T.SEQPESSOA;
              END LOOP;
              
              if vnVlrTotalItem > 0 then
              
                  if vnContParc > 0 then
                     vnVlrParcela          := TRUNC(vnVlrTotalItem / vnContParc, 2);
                     vnVlrOperDescParc     := TRUNC((vnVlrOperDesc / vnContParc), 5);
                     vnVlrOperRetParc      := TRUNC((vnVlrOperRet / vnContParc), 5);
                     vnVlrDescContratoParc := TRUNC((vnVlrDescContrato / vnContParc), 5);
                  end if;
                  
                  FOR i in vsArrayPrazoPagtoAux.First .. vsArrayPrazoPagtoAux.Last
                  LOOP
                      vnDiasPzo := to_number(vsArrayPrazoPagtoAux(i));
      
                      IF vsIndPrazoPagto = 'F' THEN
                          vdDtaVencimento := vdDtaBaseVencto +  vnDiasPzo;
                      ELSE
                          vdDtaVencimento := FMAD_CALCDTAVENCTO(vdDtaBaseVencto, vsIndPrazoPagto, vnDiasPzo, NULL);
                      END IF;
                      
                      -- RP 148994
                      -- Busca dados para checagem
                      SELECT F.TIPODTADESCFINANC, NVL(F.QTDDIASANTDESCFIN,0)
                        INTO vsTipoDtaDescFinanc, vnQtdeDiasAntDescFinanc
                        FROM MAF_FORNECDIVISAO F, MAX_EMPRESA E  
                       WHERE F.NRODIVISAO = E.NRODIVISAO
                         AND E.NROEMPRESA = pnNroEmpresa
                         AND F.SEQFORNECEDOR = vnSeqPessoa;
                      
                      If nvl(vsTipoDtaDescFinanc,'V') = 'N' THEN
                         -- fixo
                         SELECT TO_DATE('31-DEC-2050')
                           INTO vdDtaLimDescFinanc
                          FROM DUAL; 
                      ElsIf nvl(vsTipoDtaDescFinanc,'V') = 'A' then
                          vdDtaLimDescFinanc := vdDtaLimDescFinanc	- vnQtdeDiasAntDescFinanc;
                      Else
                          vdDtaLimDescFinanc := vdDtaVencimento;
                      End if;
                      --- 
                      
		      SELECT S_SEQAUXNFVENCTO.NEXTVAL
                      INTO   vnSeqAuxNFVencto
                      FROM   DUAL;
                      
                      SELECT S_SEQAUXNFVENCTO.NEXTVAL
                      INTO   vnSeqAuxNFVenctoXML
                      FROM   DUAL;
                      
                      INSERT INTO MLF_AUXNFVENCIMENTO(
                	                                    SEQAUXNOTAFISCAL, 
                                                      SEQAUXNFVENCTO,
                                                      DTAVENCIMENTO, 
                                                      VLRTOTAL, 
                                                      INDPRAZOPAGTO,
                                                      PERCDESCFINANC, 
                                                      VLRDESCFINANC, 
                                                      DIASPRAZO, 
                                                      DTALIMDESCFINANC,
                                                      VLRDESCFUNRURAL,
                                                      VLROPCONTRATODESC,
                                                      VLROPCONTRATORET,
                                                      VLRDESCCONTRATO,
                                                      PERCDESCCONTRATO,
                                                      PERCOMPROR, 
                                                      PRAZOPAGTOCOMPROR,
                                                      SEQAUXNFVENCTOXML,
                                                      VLRDESCFUNSENAR,
                                                      VLRDESCFUNRAT,
                                                      VLRDESCFUNPREVSOCIAL)
                      VALUES (vnSeqAuxNotaFiscal,
                              vnSeqAuxNFVencto,
                              vdDtaVencimento, 
                              vnVlrParcela, 
                              vsIndPrazoPagto, -- RP 195055
                              vnPerFinanc, 
                              (vnVlrParcela * vnPerFinanc)/100, 
                              vnDiasPzo,
                              vdDtaLimDescFinanc,
                              vnVlrFunRural,
                              vnVlrOperDescParc,
                              vnVlrOperRetParc,
                              vnVlrDescContratoParc,
                              vnPercDescContrato,
                              decode(vsPD_ComprorFornecRecebto,'S',fmrl_dadoscompror(vnSeqAuxNotaFiscal,'C',0),NULL),
                              decode(vsPD_ComprorFornecRecebto,'S',fmrl_dadoscompror(vnSeqAuxNotaFiscal,'P',0),NULL),
                              vnSeqAuxNFVenctoXML,
                              vnVlrFunSenar,
                              vnVlrFunRat,
                              vnVlrFunPrevSocial
                             );
		            UPDATE MLF_AUXNFVENCIMENTO
                      SET    DIASPRAZO = NVL(vdDtaVencimento - vdDtaBaseVencto, vnDiasPzo),
                             DIASPZOPED = NVL(vdDtaVencimento - vdDtaBaseVencto, vnDiasPzo)
                      WHERE  SEQAUXNOTAFISCAL = vnSeqAuxNotaFiscal
                      AND    SEQAUXNFVENCTO = vnSeqAuxNFVencto;
                      
                      -- RC 126114        
                      INSERT INTO MLF_AUXNFVENCIMENTOXML(
                	                                    SEQAUXNOTAFISCAL, 
                                                      SEQAUXNFVENCTO,
                                                      DTAVENCIMENTO, 
                                                      VLRTOTAL, 
                                                      INDPRAZOPAGTO,
                                                      PERCDESCFINANC, 
                                                      VLRDESCFINANC, 
                                                      DIASPRAZO, 
                                                      DTALIMDESCFINANC,
                                                      VLRDESCFUNRURAL,
                                                      VLROPCONTRATODESC,
                                                      VLROPCONTRATORET,
                                                      VLRDESCCONTRATO,
                                                      PERCDESCCONTRATO,
                                                      VLRDESCFUNSENAR,
                                                      VLRDESCFUNRAT,
                                                      VLRDESCFUNPREVSOCIAL)
                      VALUES (vnSeqAuxNotaFiscal, 
                              vnSeqAuxNFVenctoXML,
                              vdDtaVencimento, 
                              vnVlrParcela, 
                              vsIndPrazoPagto, -- RP 195055
                              vnPerFinanc, 
                              (vnVlrParcela * vnPerFinanc)/100, 
                              vnDiasPzo,
                              vdDtaLimDescFinanc,
                              vnVlrFunRural,
                              vnVlrOperDescParc,
                              vnVlrOperRetParc,
                              vnVlrDescContratoParc,
                              vnPercDescContrato,
                              vnVlrFunSenar,
                              vnVlrFunRat,
                              vnVlrFunPrevSocial);                              
                      
                      UPDATE MLF_AUXNFVENCIMENTOXML
                      SET    DIASPRAZO = NVL(vdDtaVencimento - vdDtaBaseVencto, vnDiasPzo),
                             DIASPZOPED = NVL(vdDtaVencimento - vdDtaBaseVencto, vnDiasPzo)
                      WHERE  SEQAUXNOTAFISCAL = vnSeqAuxNotaFiscal
                      AND    SEQAUXNFVENCTO = vnSeqAuxNFVenctoXML;
      
                      vnVlrTotalItem    := vnVlrTotalItem - vnVlrParcela;
                      vnVlrDescFinanc   := vnVlrDescFinanc - ((vnVlrParcela * vnPerFinanc)/100);
                      vnVlrFunRural     := vnVlrFunRural - vnVlrFunRural;
                      vnVlrOperDesc     := vnVlrOperDesc - vnVlrOperDescParc;
                      vnVlrOperRet      := vnVlrOperRet - vnVlrOperRetParc;
                      vnVlrDescContrato := vnVlrDescContrato - vnVlrDescContratoParc;
                      vnVlrFunSenar     := vnVlrFunSenar - vnVlrFunSenar;
                      vnVlrFunRat       := vnVlrFunRat - vnVlrFunRat;
                      vnVlrFunPrevSocial := vnVlrFunPrevSocial - vnVlrFunPrevSocial;
                  END LOOP;
                  
                  if vnVlrTotalItem != 0 Or vnVlrDescFinanc != 0 Or vnVlrFunRural != 0 Or vnVlrOperDesc != 0 Or vnVlrOperRet != 0 Or vnVlrDescContrato != 0 then
                     UPDATE MLF_AUXNFVENCIMENTO 
                        SET VLRTOTAL = VLRTOTAL + vnVlrTotalItem,
                            VLRDESCFINANC = VLRDESCFINANC + vnVlrDescFinanc,
                            VLRDESCFUNRURAL = VLRDESCFUNRURAL + vnVlrFunRural,
                            VLROPCONTRATODESC = VLROPCONTRATODESC + vnVlrOperDesc,
                            VLROPCONTRATORET = VLROPCONTRATORET + vnVlrOperRet,
                            VLRDESCCONTRATO = VLRDESCCONTRATO + vnVlrDescContrato,
                            VLRDESCFUNSENAR = VLRDESCFUNSENAR + vnVlrFunSenar,
                            VLRDESCFUNRAT = VLRDESCFUNRAT + vnVlrFunRat,
                            VLRDESCFUNPREVSOCIAL = VLRDESCFUNPREVSOCIAL + vnVlrFunPrevSocial
                      WHERE SEQAUXNOTAFISCAL = vnSeqAuxNotaFiscal
                        AND DTAVENCIMENTO = vdDtaVencimento;
                  end if;
                                   
                  -- RC 126114  
                  if vnVlrTotalItem != 0 Or vnVlrDescFinanc != 0 Or vnVlrFunRural != 0 Or vnVlrOperDesc != 0 Or vnVlrOperRet != 0 Or vnVlrDescContrato != 0 then
                     UPDATE MLF_AUXNFVENCIMENTOXML 
                        SET VLRTOTAL = VLRTOTAL + vnVlrTotalItem,
                            VLRDESCFINANC = VLRDESCFINANC + vnVlrDescFinanc,
                            VLRDESCFUNRURAL = VLRDESCFUNRURAL + vnVlrFunRural,
                            VLROPCONTRATODESC = VLROPCONTRATODESC + vnVlrOperDesc,
                            VLROPCONTRATORET = VLROPCONTRATORET + vnVlrOperRet,
                            VLRDESCCONTRATO = VLRDESCCONTRATO + vnVlrDescContrato,
                            VLRDESCFUNSENAR = VLRDESCFUNSENAR + vnVlrFunSenar,
                            VLRDESCFUNRAT = VLRDESCFUNRAT + vnVlrFunRat,
                            VLRDESCFUNPREVSOCIAL = VLRDESCFUNPREVSOCIAL + vnVlrFunPrevSocial
                      WHERE SEQAUXNOTAFISCAL = vnSeqAuxNotaFiscal
                        AND DTAVENCIMENTO = vdDtaVencimento;
                  end if;                  
              end if;
          end if; -- vsPD_IndPrazoTit
          -- RP 225709
          SP_CalcVlrOriginalTitulo(vnSeqAuxNF, vsRecebVencVlrLiq);
          
          SP_AlteraVencimento(vnSeqAuxNF);
          
          SP_MLF_AUXNFVENCITEM(vnSeqAuxNF);
          
          SP_CALCULA_DESCCONTRATO_VENC(vnSeqAuxNF);
          
          FOR I IN (SELECT A.VLROPCONTRATODESC,
                           A.SEQAUXNOTAFISCAL,
                           A.SEQAUXNFVENCTOXML
                    FROM MLF_AUXNFVENCIMENTO A
                    WHERE A.SEQAUXNOTAFISCAL = vnSeqAuxNF)
          LOOP
            UPDATE MLF_AUXNFVENCIMENTOXML A
            SET A.Vlropcontratodesc = I.VLROPCONTRATODESC
            WHERE A.SEQAUXNOTAFISCAL = I.SEQAUXNOTAFISCAL
            AND A.SEQAUXNFVENCTO = I.SEQAUXNFVENCTOXML;
          END LOOP;
          
          SELECT NVL(AVG(A.PRAZOPAGTOCOMPROR), AVG(A.DIASPRAZO)),
                 AVG(A.DIASPRAZO)
          INTO   vsDiasPrazoNF,
                 vsDiasPrazoVencNF
          FROM   MLF_AUXNFVENCIMENTO A
          WHERE  A.SEQAUXNOTAFISCAL = vnSeqAuxNF;
          
          IF vsDiasPrazoVencNF IS NOT NULL THEN
            UPDATE MLF_AUXNOTAFISCAL A
            SET    A.DIASPRAZO = vsDiasPrazoNF,
                   A.DIASPRAZOVENC = vsDiasPrazoVencNF
            WHERE  A.SEQAUXNOTAFISCAL = vnSeqAuxNF;
          END IF;
          
        end if;  
        
      End If;

      SELECT NVL(MAX(E.INDUSALOTEESTOQUE),'N')
      INTO vsIndUsaLoteEstoque
      FROM  MAX_EMPRESA E
      WHERE E.NROEMPRESA = pnNroEmpresa;
      
      If vsIndUsaLoteEstoque = 'S' Then
        If pnImpOK = 1 Then
          --Insere os dados do lote
          
          FOR T IN (
                           
                  Select B.Seqauxnotafiscal, D.Seqauxnfitem, C.M017_Nr_Lote Nrlote, C.M017_Dt_Fabr Dtafabricacao,
                       C.M017_Dt_Validade Dtavalidade, C.M017_Vl_Qtd_Lote Qtde, B.Numeronf, B.Seqpessoa, B.Serienf,
                       B.Tipnotafiscal, B.Nroempresa, Nvl(D.Seqproduto, 0) Seqproduto, D.Tipitem, D.Seqitemnf, c.Codagregacao, 
                       decode(C.NROREGMINSAUDE,'ISENTO','ISENTO',LPAD(C.NROREGMINSAUDE, 13, '0')) CODPRODANVISA, C.MOTIVOISENCAOMINSAUDE,
                       D.LOCATUESTQ, D.QTDEMBALAGEM, b.seqnotafiscal
                  From Mlf_Auxnotafiscal b,  Mlf_Auxnfitem d, Tmp_M017_Med c
                 Where B.Seqnotafiscal = vnSeqM000_ID_NF
                   And D.Seqauxnotafiscal = B.Seqauxnotafiscal
                   And exists ( select 1
                                  from TMP_M000_NF n, TMP_M014_ITEM i
                                 where C.M014_Id_Item = i.M014_Id_Item
                                   And i.M000_Id_Nf = n.M000_Id_Nf 
                                   And i.m014_nr_item = d.seqitemnf
                                   And n.M000_Nr_Chave_Acesso =  Decode(vsCgoEntradaEmissao, 'S', B.Nfereferenciachave, Nvl(B.Nfechaveacesso, B.Nfechaveacessocopia))
                                    )
                 Group By B.Seqauxnotafiscal, D.Seqauxnfitem, C.M017_Nr_Lote, C.M017_Dt_Fabr, C.M017_Dt_Validade,
                          C.M017_Vl_Qtd_Lote, B.Numeronf, B.Seqpessoa, B.Serienf, B.Tipnotafiscal, B.Nroempresa,
                          Nvl(D.Seqproduto, 0), D.Tipitem, D.Seqitemnf, C.Codagregacao, C.NROREGMINSAUDE, C.MOTIVOISENCAOMINSAUDE,
                          D.LOCATUESTQ, D.QTDEMBALAGEM, b.seqnotafiscal
                 Order By B.Seqauxnotafiscal, D.Seqauxnfitem, C.M017_Nr_Lote, C.M017_Dt_Fabr, C.M017_Dt_Validade,
                          C.M017_Vl_Qtd_Lote, B.Numeronf, B.Seqpessoa, B.Serienf, B.Tipnotafiscal, B.Nroempresa,
                          Nvl(D.Seqproduto, 0), D.Tipitem, D.Seqitemnf, C.NROREGMINSAUDE, C.MOTIVOISENCAOMINSAUDE,
                          D.LOCATUESTQ, D.QTDEMBALAGEM
                                       )
           LOOP 
             
                    SELECT MAX(A.QUANTIDADE)
                    INTO vnQtdItemPedido
                    FROM MRL_NFEITEMPEDIDO A
                    WHERE A.SEQNOTAFISCAL = pnIDNFe
                    AND   A.NROITEM = t.SEQITEMNF ;  
                                   
                    -- Verifica se família do item controla lote de estoque
                    SELECT COUNT(*)
                    INTO vnLinhasProc
                    FROM MLF_AUXNFITEM A, MAP_PRODUTO B, MAP_FAMILIA C
                    WHERE C.SEQFAMILIA = B.SEQFAMILIA
                    AND B.SEQPRODUTO = A.SEQPRODUTO
                    AND A.SEQAUXNOTAFISCAL = T.SEQAUXNOTAFISCAL
                    AND A.SEQAUXNFITEM = T.SEQAUXNFITEM 
                    AND ( NVL(C.INDUSALOTEESTOQUE,'N') = 'S' OR NVL(C.INDMEDICAMENTO,'N') = 'S');
                    
                    If vnLinhasProc > 0 Then
                        select max(f.fatorconvembxml), max(h.pesavel)
                          into vnFatorConvEmbXML, vsPesavel
                          from map_famfornec f,
                               map_familia h,
                               map_produto g
                         where g.seqfamilia = f.seqfamilia
                           and f.seqfornecedor = t.seqpessoa
                           and g.seqproduto = t.seqproduto
                           and g.seqfamilia = h.seqfamilia;
                    
                        INSERT INTO MLF_NFITEMLOTE(SEQNFITEMLOTE, SEQAUXNOTAFISCAL, SEQAUXNFITEM, 
                                 NROLOTEESTOQUE, DTAFABRICACAO, DTAVALIDADE, QUANTIDADE, 
                                 NUMERONF, SEQPESSOA, SERIENF, TIPNOTAFISCAL, NROEMPRESA, 
                                 SEQPRODUTO, TIPITEM, SEQITEMNF, CODAGREGACAO, CODPRODANVISA, MOTIVOISENCAOMINSAUDE,
                                 SEQLOCAL)
                        
                        VALUES(S_SEQNFITEMLOTE.NEXTVAL, T.SEQAUXNOTAFISCAL, T.SEQAUXNFITEM,
                               T.NRLOTE, T.DTAFABRICACAO, T.DTAVALIDADE,
                               CASE WHEN vsPDConvEmbXML = 'S' AND NVL(vnFatorConvEmbXML,0) > 0 THEN
                                 CASE WHEN NVL(vsPesavel,'N') = 'S' THEN
                                      round(NVL(vnQtdItemPedido,T.QTDE) / vnFatorConvEmbXML, 3) * T.QTDEMBALAGEM
                                 ELSE
                                      round(NVL(vnQtdItemPedido,T.QTDE) / vnFatorConvEmbXML) * T.QTDEMBALAGEM
                                 END
                               ELSE
                                 NVL(vnQtdItemPedido,T.QTDE) * T.QTDEMBALAGEM
                               END,
                               T.NUMERONF, T.SEQPESSOA, T.SERIENF, T.TIPNOTAFISCAL, T.NROEMPRESA,
                               T.SEQPRODUTO, T.TIPITEM, T.SEQITEMNF, T.CODAGREGACAO, T.CODPRODANVISA, T.MOTIVOISENCAOMINSAUDE,
                               T.LOCATUESTQ);
                    End If;           
           
           END LOOP;         
          
        End If;
      End If;
      
      --- Insere os dados de Origem dos Combustíveis
      If pnImpOK = 1 Then
         
         for t in ( 
               Select B.Seqauxnotafiscal, D.Seqauxnfitem, D.SEQITEMNFXML, D.SEQPRODUTO, n.m000_id_nf, i.m014_id_item
                From Mlf_Auxnotafiscal b,  Mlf_Auxnfitem d, TMP_M014_ITEM i, TMP_M000_NF n
               Where B.Seqnotafiscal = vnSeqM000_ID_NF       
                 And i.M000_Id_Nf = n.M000_Id_Nf
                 And n.M000_Nr_Chave_Acesso =  Decode(vsCgoEntradaEmissao, 'S', B.Nfereferenciachave, Nvl(B.Nfechaveacesso, B.Nfechaveacessocopia))
                 And i.m014_nr_item = d.seqitemnf               
                 And D.Seqauxnotafiscal = B.Seqauxnotafiscal
               Order By B.Seqauxnotafiscal, D.Seqauxnfitem
                  )
                  
         loop
             
             select max(C.M018_VL_PERC_BIODIESEL)
             into vnPercBiodiesel
             from  TMP_M018_COMB c
             where C.M014_Id_Item = t.M014_Id_Item            
             and   c.m000_id_nf = t.m000_id_nf;
         
             update mlf_auxnfitem a
             set a.percbiodiesel = vnPercBiodiesel
             where a.seqauxnotafiscal = t.seqauxnotafiscal
             and   a.seqauxnfitem = t.seqauxnfitem;  
             
             insert into mlf_nfitemorigcomb(seqnfitemorigcomb,
                                            seqauxnotafiscal,
                                            seqitemnfxml,
                                            seqproduto,
                                            indimportorigcomb,
                                            coduforigcomb,
                                            percorigcomb)
              select s_seqnfitemorigcomb.nextval,
                    t.seqauxnotafiscal,
                    t.seqitemnfxml,
                    t.seqproduto,
                    c.m018_orig_comb_ind_import,
                    c.m018_orig_comb_cod_uf_orig,
                    c.m018_orig_comb_vl_perc_orig                                  
             from TMP_M018_ORIG_COMB c
             where  C.M014_Id_Item = t.M014_Id_Item
             and c.m000_id_nf = t.m000_id_nf;                                                              
                           
         end loop;                       
      End If;
      
      If pnImpOK = 1 Then
        
        -- Atualiza os valores do cabeçalho da nota da nota com a somatória dos ítens
        UPDATE MLF_AUXNOTAFISCAL
        SET    (VLRDESCONTO, VLRDESCSUFRAMA,
                VLRPRODUTOS, VLRDESPNTRIBUTADA, VLRDESPTRIBUTADA,
                BASEICMSSTCALC, 
                VLRICMSSTCALC,
                VLRDESPFORANF, VLRABATIMENTO,
                VLRFRETEFORANF, 
                VLRDESCINCOND, VLRCOMPROR, 
                VLRBASEICMSRETIDO, VLRICMSRETIDO,
                VLRTOTICMSDESONERADO, VLRTOTFCPDISTRIB, 
                BASEICMSANTECIPADO, VLRICMSANTECIPADO,
                VLRTOTICMSSN, VLRFRETE) =
        (SELECT SUM(MLF_AUXNFITEM.VLRDESCITEM), SUM(NVL(MLF_AUXNFITEM.VLRDESCSUFRAMA,0)),
                SUM(MLF_AUXNFITEM.VLRITEM), SUM(MLF_AUXNFITEM.VLRDESPNTRIBUTITEM), SUM(MLF_AUXNFITEM.VLRDESPTRIBUTITEM),
                SUM(DECODE(MLF_AUXNFITEM.LANCAMENTOST,'O',MLF_AUXNFITEM.BASCALCICMSST,'S',MLF_AUXNFITEM.BASCALCICMSST,0)),
                SUM(DECODE(MLF_AUXNFITEM.LANCAMENTOST,'O',MLF_AUXNFITEM.VLRICMSST,'S',MLF_AUXNFITEM.VLRICMSST,0)),
                SUM(MLF_AUXNFITEM.VLRDESPFORANF), SUM(NVL(MLF_AUXNFITEM.VLRABATIMENTO,0)),
                0,
                SUM(NVL(MLF_AUXNFITEM.VLRDESCINCOND,0)), SUM(NVL(MLF_AUXNFITEM.VLRCOMPROR,0)),
                SUM(NVL(MLF_AUXNFITEM.VLRBASEICMSRETIDO,0)), SUM(NVL(MLF_AUXNFITEM.VLRICMSRETIDO,0)),
                SUM(NVL(MLF_AUXNFITEM.VLRTOTICMSDESONERADO,0)), SUM(NVL(MLF_AUXNFITEM.VLRFCPDISTRIB,0)),
                SUM(NVL(MLF_AUXNFITEM.BASEICMSANTECIPADO,0)), SUM(NVL(MLF_AUXNFITEM.VLRICMSANTECIPADO,0)),
                SUM(CASE WHEN vsPDUtilizaValorSimplesXML = 'S' AND NVL(MLF_AUXNFITEM.BASCALCICMSST, 0) > 0  THEN
                           0
                         WHEN vsPDUtilizaValorSimplesXML = 'S' THEN
                           NVL(MLF_AUXNFITEM.VLRICMSSIMPLESXML, 0)
                         ELSE
                           NVL(MLF_AUXNFITEM.VLRICMSSIMPLES, 0)
                    END),
                SUM(NVL(MLF_AUXNFITEM.VLRFRETENANF,0))
        FROM    MLF_AUXNFITEM
        WHERE   MLF_AUXNFITEM.SEQAUXNOTAFISCAL = MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL)
        WHERE   MLF_AUXNOTAFISCAL.SEQNOTAFISCAL = vnSeqM000_ID_NF;
        
        -- Atualiza a somatória do FCP ST dos itens no cabeçalho da nota quando FCP sem Destaque e 
        -- Fornecedor não tiver informado nenhum valor no campo correspondente
        -- Caso fornecedor informe o mesmo será respeitado, independente do Destaque do FCP
        UPDATE MLF_AUXNOTAFISCAL
        SET    (VLRTOTFCPST) = Nvl(VLRTOTFCPST, 0) + 
        (SELECT SUM(DECODE(MLF_AUXNFITEM.LANCAMENTOST,'O',MLF_AUXNFITEM.VLRFCPST,'S',MLF_AUXNFITEM.VLRFCPST,0))
                FROM    MLF_AUXNFITEM
                WHERE   MLF_AUXNFITEM.SEQAUXNOTAFISCAL = MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL
        )
        WHERE   MLF_AUXNOTAFISCAL.SEQNOTAFISCAL = vnSeqM000_ID_NF;        
        -- Atualiza valor total da nota quando utilizado cálculo do icms por Dentro 
        -- Caso a diferença entre o total do Item e total da Nota for o estorno do icms (por Dentro)
        if vsCalculoICMS = 'D' then
            SELECT sum(case
                         when (b.finalidadefamilia in ('B', 'U', 'A') and
                              nvl(d.inddescbrinde, 'N') = 'S') OR
                              (nvl(I.INDCOMPTOTNFREMESSA, 'S') = 'N') then
                          0
                         else
                          NVL(I.VLRTOTALITEM, 0) + NVL(I.VLRFRETENANF, 0)
                       end),
                   max(D.VLRTOTALNF), sum(NVL(I.VLRICMSESTORNO,0))
                       
              INTO vnVlrTotalNFItem,
                   vnVlrTotalNota, vnVlrIcmsEstorno
              FROM MLF_AUXNFITEM     I,
                   map_produto       a,
                   map_famdivisao    b,
                   max_empresa       c,
                   mlf_auxnotafiscal d
             WHERE i.seqproduto = a.seqproduto
               and a.seqfamilia = b.seqfamilia
               and i.seqauxnotafiscal = d.seqauxnotafiscal
               and d.nroempresa = c.nroempresa
               and c.nrodivisao = b.nrodivisao
               and d.seqnotafiscal = vnSeqM000_ID_NF;
            
            if nvlzero(abs((vnVlrTotalNFItem - vnVlrTotalNota) - vnVlrIcmsEstorno),0.01) = 0.01 then
            
                  update MLF_AUXNOTAFISCAL
                  set MLF_AUXNOTAFISCAL.VLRTOTALNF = vnVlrTotalNFItem      
                  where MLF_AUXNOTAFISCAL.SEQNOTAFISCAL = vnSeqM000_ID_NF;                
            
            end if;
        end if;
        
        -- Atualiza topo contranota produtor rural
        IF vsCgoEntradaEmissao = 'S' AND NVL(vsIndNFRefProdRural, 'N') = 'S' THEN
          update MLF_AUXNOTAFISCAL
          set    ( BASECALCICMS,
                   VLRICMS, 
                   BASECALCICMSST, 
                   VLRICMSST,
                   VLRIPI
                  ) =
                 (select SUM(MLF_AUXNFITEM.BASCALCICMS),
                         SUM(MLF_AUXNFITEM.VLRICMS), 
                         SUM(DECODE(MLF_AUXNFITEM.LANCAMENTOST,'O',0,'S',0,MLF_AUXNFITEM.BASCALCICMSST)), 
                         SUM(DECODE(MLF_AUXNFITEM.LANCAMENTOST,'O',0,'S',0,MLF_AUXNFITEM.VLRICMSST)),
                         SUM(MLF_AUXNFITEM.VLRIPI)
                 from    MLF_AUXNFITEM
                 where   MLF_AUXNFITEM.SEQAUXNOTAFISCAL = MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL
                 )
          where   MLF_AUXNOTAFISCAL.SEQNOTAFISCAL = vnSeqM000_ID_NF;
        END IF;
        
        -- Gera Log de Importação
        INSERT INTO MRL_NFELOGIMPORT(
    	          SEQLOG, DTAIMPORTACAO,
    	          USUIMPORTACAO, TIPLOG, SEQAUXNOTAFISCAL,
                SEQNOTAFISCAL, NROEMPRESA, SEQPESSOA,
                HISTORICO)
        
        SELECT S_SEQNFELOGIMPORT.NEXTVAL, SYSDATE,
               psUsuLancto, 'I', A.SEQAUXNOTAFISCAL,
               pnIDNFe, A.NROEMPRESA, A.SEQPESSOA,
               'Nota ' || A.NUMERONF ||
                  ' Série ' || A.SERIENF ||
                  ' Forn. ' || A.SEQPESSOA ||
                  ' Empr. ' || A.NROEMPRESA ||
                  ' importada com sucesso'
        
        FROM   MLF_AUXNOTAFISCAL A
        WHERE  A.SEQNOTAFISCAL = vnSeqM000_ID_NF;
        
        If pnExcluiOphos = 1 Then
        
           PKG_MLF_IMPNFERECEBIMENTO.SP_EXCLUI_TMP(pnIDNFe);
        
        End If;

       -- Efetua o vínculo das NFe's ao CTe
       SP_VINCULARNFEAOCTEAUTOMATICO(NULL, pnChaveNFe);  

       pkg_mlf_recebimento.SP_CONSISTEAUXNOTAFISCAL(vnSeqAuxNF);
       
      If ( vsPD_LiberaNFAutoSemDiverg != 'N') and vsPDIndConsNfeImpProc != 'S' Then
        select count(1)
        into vnCount
        from mlf_auxnfinconsistencia a
        where a.seqauxnotafiscal = vnSeqAuxNF;
        if vnCount = 0 then
          if vsPD_LiberaNFAutoSemDiverg = 'S' then
            Update mlf_auxnotafiscal Set
            indprocessamento  = 'L',
            INDRECALCST = NULL,
            USULANCTO = psUsuLancto,
            DTAHORLANCTO = pdDtaHorLancto,
            CONSIDLOCALCARGAANT = NULL            
            Where seqauxnotafiscal = vnSeqAuxNF;
          End If; 
          if vsPD_LiberaNFAutoSemDiverg = 'C' then
            select count(1)
            into vnCount
            from mlf_auxnotafiscal n, max_codgeraloper c, max_cgoempresa e
            where n.seqauxnotafiscal = vnSeqAuxNF
            and n.codgeraloper = c.codgeraloper
            and e.codgeraloper(+) = n.codgeraloper
            and e.nroempresa(+)   = n.nroempresa
            and e.status(+) = 'A'
            and nvl(e.geracargaauto,c.geracargaauto) = 'S';
            if vnCount = 0 then
              Update mlf_auxnotafiscal Set
              indprocessamento  = 'L',
              INDRECALCST = NULL,
              USULANCTO = psUsuLancto,
              DTAHORLANCTO = pdDtaHorLancto,
              CONSIDLOCALCARGAANT = NULL            
              Where seqauxnotafiscal = vnSeqAuxNF;
            End If;
          else
            begin
              select count(1)
              into vnCount
              from mlf_auxnotafiscal n
              where n.seqauxnotafiscal = vnSeqAuxNF
              and codgeraloper in (select column_value from table(cast(c5_complexin.c5intable( vsPD_LiberaNFAutoSemDiverg ) as c5instrtable)));
              if vnCount = 1 then
                Update mlf_auxnotafiscal Set
                indprocessamento  = 'L',
                INDRECALCST = NULL,
                USULANCTO = psUsuLancto,
                DTAHORLANCTO = pdDtaHorLancto,
                CONSIDLOCALCARGAANT = NULL            
                Where seqauxnotafiscal = vnSeqAuxNF
                and codgeraloper in (select column_value from table(cast(c5_complexin.c5intable( vsPD_LiberaNFAutoSemDiverg ) as c5instrtable)));
              End If;
            exception
              WHEN others THEN
                vsPD_LiberaNFAutoSemDiverg := 'N';
            END;
          End If;
        End If;
      End If;      
      
      tObjImportaTmp := TP_MLF_Importa_TMP(vnSeqAuxNF);      
      SP_MLF_Importa_TMP_Cust(tObjImportaTmp);
      
      ELSE
            -- Exclui as informações das tabelas auxiliares em casos de erro de importação
        if vbExclui then
          -- Vencimento
          DELETE FROM MLF_AUXNFVENCIMENTO B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                       AND A.SEQNOTAFISCAL = vnSeqM000_ID_NF);
          -- RC 126114
          DELETE FROM MLF_AUXNFVENCIMENTOXML B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                       AND A.SEQNOTAFISCAL = vnSeqM000_ID_NF);                       
          -- Consistencia de Vencimento
          DELETE FROM MLF_AUXNFVENCIMENTOCONSIST B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                       AND A.SEQNOTAFISCAL = vnSeqM000_ID_NF);
          -- Lote medicamento
          DELETE FROM MLF_NFITEMLOTE B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                                  
                       AND A.SEQNOTAFISCAL = vnSeqM000_ID_NF);  
                       
          -- Origem Combustível
          DELETE FROM MLF_NFITEMORIGCOMB B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                       AND A.SEQNOTAFISCAL = vnSeqM000_ID_NF); 
                                  
          -- Ítens da nota
          DELETE FROM MLF_AUXNFITEM B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                       AND A.SEQNOTAFISCAL = vnSeqM000_ID_NF);
          -- Nota Fiscal
          DELETE FROM MLF_AUXNOTAFISCAL
          WHERE SEQNOTAFISCAL = vnSeqM000_ID_NF;
        End If;
      End If; 
      
      DELETE MRL_NFEIMPPROCESS WHERE CHAVE_ACESSO = pnChaveNFe;
      
      vbIndImportouNFXMLParaRecebto := FALSE;
      
      BEGIN
        NAGP_ARRED_ITEM_AUXNF_AUTO( vnSeqAuxNF );
        END;
        
  EXCEPTION
        WHEN OTHERS THEN
        IF abs(sqlcode) = 20500 THEN 
           RAISE_APPLICATION_ERROR (-20500 , SQLERRM );
        ELSE
        RAISE_APPLICATION_ERROR (-20200 , SQLERRM );
        END IF;
  END SP_IMPORTA_TMP;
  

  /*Consiste a NFE*/
  PROCEDURE SP_CONSISTEIMPNFE(
         pnIDNFE              IN        MRL_NFEINCONSISTENCIA.SEQNOTAFISCAL%TYPE,
         pnNroEmpresa         IN        MAX_EMPRESA.NROEMPRESA%TYPE,
         pnVerifCancSefazLib  IN        INTEGER)
  IS
    vnCount                    NUMBER;
    vsPedido                   TMP_M000_NF.M000_DS_PEDIDO%TYPE;
    vsPsicotropico             MAP_FAMILIA.INDCONTROLEVDA%TYPE;
    vsContrLote                MAP_FAMILIA.INDUSALOTEESTOQUE%TYPE;
    vsPDGeraIncLoteMed         MAX_PARAMETRO.VALOR%TYPE;
    vnProdLote                 NUMBER;
    vnCountProd                NUMBER;
    vsPesavel                  MAP_FAMILIA.PESAVEL%TYPE;
    vsDecimal                  MAP_FAMILIA.PMTDECIMAL%TYPE;
    vnSeqFornec                MAF_FORNECEDOR.SEQFORNECEDOR%TYPE;
    vnQtdTmpM004               INTEGER;
    vnQtdPzoPagto              INTEGER;
    vnExisteContrato           INTEGER;
    vnNroEmpresa               MAX_EMPRESA.NROEMPRESA%TYPE;
    vsPDEmbPesavel             varchar2(1);/*RP 79000*/
    vsPDEmbDecimal             varchar2(1);
    vsPDConsistePrzoContrato   MAX_PARAMETRO.VALOR%TYPE;
    vnItensPedido              number;
    vsPDConvEmbXML             MAX_PARAMETRO.VALOR%TYPE;
    vsAux                      VARCHAR2(10);
    vnFatorConvEmbXML          MAP_FAMFORNEC.FATORCONVEMBXML%TYPE; 
    vnQuantidadeConv           NUMBER;
    vnQtdSaldoPed              NUMBER;       
    vnQtdUtilPedido            NUMBER;            
    vsConsPedidoNumerico       varchar2(1);
    vsBloqNFSomaQtdSupPed      MAX_PARAMETRO.VALOR%TYPE;
    vsPDUtilCondPagtoContrFidel MAX_PARAMETRO.VALOR%TYPE;
    vnChaveNFe                  TMP_M000_NF.M000_NR_CHAVE_ACESSO%TYPE;
    vsPD_PermImpXmlCnpj         MAX_PARAMETRO.VALOR%TYPE;
    vsPD_ConsExigPedCgoNfe      MAX_PARAMETRO.VALOR%TYPE;
    vsMensagemConsis            MRL_NFEINCONSISTENCIA.DESCRICAO%type;
    vsExgPedidoCompra           MAX_CODGERALOPER.EXGPEDIDOCOMPRA%TYPE;
    vnQtdPedidos                NUMBER;
    vsIndAssumeEmbQtdEmbXml     maf_fornecdivisao.indassumeembqtdembxml%type;
    vnQtdEmbalagemXml           map_famembalagem.qtdembalagem%type;
    vsPDTipoInconQtdEmbXml      max_parametro.valor%type;
    vnStatusNFESefaz            NUMBER;                                          -- RC 131510
    vsPD_VerifNFECancSefaz      MAX_PARAMETRO.VALOR%TYPE;                        -- RC 131510
    vsPD_GeraInconsProdCompl    MAX_PARAMETRO.VALOR%TYPE;                        -- RP 149708
    vsIndComplVlrImposto        MAX_CODGERALOPER.INDCOMPLVLRIMP%TYPE;            -- RP 149708
    vnSeqProdComplemImposto     MAX_EMPRESA.SEQPRODUTOCOMPLIMPOSTO%TYPE;         -- RP 149708
    vsPD_PmtVerifCancSefazLibRec MAX_PARAMETRO.VALOR%TYPE;                        -- RC 168362
    vsPD_PmtVisualPedFornRel    max_parametro.valor%type;                         -- RC 238433
    vsPD_BloqRecebEstornoForn   Max_Parametro.Valor%Type;

    vbNFCanceladaSefaz          BOOLEAN := FALSE;
    
    -- RP 202257
    vnNroNota                   MLF_NOTAFISCAL.NUMERONF%TYPE; 
    vsSerieNota                 MLF_NOTAFISCAL.SERIENF%TYPE;
    vnSeqPessoa                 MLF_NOTAFISCAL.SEQPESSOA%TYPE;
    vdDtaEmissao                MLF_NOTAFISCAL.DTAEMISSAO%TYPE;
    vsChaveAcesso               MLF_NOTAFISCAL.NFECHAVEACESSO%TYPE;
    vsPD_PerLimQtdeAcimPedPes   MAX_PARAMETRO.VALOR%TYPE; 
    vsPD_PerLimQtdeAcimPedCom   MAX_PARAMETRO.VALOR%TYPE; 
    vsPD_AceRecebQtdeAcimPedCom MAX_PARAMETRO.VALOR%TYPE; 
    vnPD_PerLimQtdeAcimPedCom    NUMBER;
    vnPD_PerLimQtdeAcimPedPes    NUMBER;
    vnPercLimMsg                 NUMBER;
    vnQtdSaldoPedMsg             NUMBER;
    vnQuantidadeDivPeloFator     NUMBER;
    vnQtdePedidosNFe             NUMBER;
    vnTipoPedCompNFe             NUMBER;
    vsTipoPedCompCGO             MAX_CODGERALOPER.TIPPEDIDOCOMPRA%TYPE;
    vsPD_RecebBonifNFCompra      MAX_PARAMETRO.VALOR%TYPE;
  BEGIN

    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NFE', 0, 'GERA_INCONSIT_LOTE_MEDIC', 'S', 'N',
          'GERA INCONSISTÊNCIA PARA ITENS QUE TEM LOTE DE MEDICAMENTO INDICADO NO XML MAS QUE EM SUA FAMÍLIA NÃO ESTÁ ASSINALADO QUE "EXIGE CONTROLE DE ESTOQUE POR LOTE"? 
VALORES: S-SIM, GERA PARA TODOS/N-NÃO(VALOR PADRÃO)/P-APENAS MEDICAMENTO PSICOTRÓPICO)', vsPDGeraIncLoteMed );
    vsPDGeraIncLoteMed := SubStr(vsPDGeraIncLoteMed,0,1);
    
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NFE', 0, 'CONSISTE_PRZO_CONTRATO', 'S', 'S',
          'CONSISTE O PRAZO DE PAGAMENTO COM O CONTRATO DO FORNECEDOR', vsPDConsistePrzoContrato );
    vsPDConsistePrzoContrato := SubStr(vsPDConsistePrzoContrato,0,1);    
    
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NFE', 0, 'CONS_PEDIDO_NUMERICO', 'S', 'S',
          'CONSISTE SE O PEDIDO INFORMADO NO XML É NUMÉRICO ?  (S-SIM (VALOR PADRÃO)/ N-NÃO)', vsConsPedidoNumerico );
    vsConsPedidoNumerico := SubStr(vsConsPedidoNumerico,0,1);       

    vsPDEmbPesavel :=  SubStr(fc5MaxParametro('CADASTRO_FAMILIA', 0, 'IND_PRODUTO_PESAVEL'),0,1);
    vsPDEmbDecimal :=  SubStr(fc5MaxParametro('CADASTRO_FAMILIA', 0, 'IND_EMBALAGEM_DECIMAL'),0,1);  

    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'CADASTRO_FAMILIA', 0, 'CONV_EMB_XML', 'S', 'N',
             'EXIBE CAMPO DE CONVERSÃO DE EMBALAGEM PARA RECEBIMENTO DE NOTA FISCAL IMPORTADA DO XML? VALORES: (S-SIM / N-NÃO (VALOR PADRÃO))', vsAux );
      vsPDConvEmbXML := SubStr(vsAux,0,1); 

       PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'CONTRATO_FIDELIDADE', 0, 'UTIL_COND_PAGTO_CONTR_FIDEL', 'S', 'N',
             'UTILIZA CONDIÇÃO DE PAGAMENTO EM VEZ DE PRAZO PAGAMENTO NO CONTRATO FIDELIDADE? VALORES:(S-SIM/N-NÃO(VALOR PADRÃO))', vsAux );
      vsPDUtilCondPagtoContrFidel := SubStr(vsAux,0,1);   
      
    --RP 126085
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', 0, 'PERM_IMP_XML_CNPJ', 'S', 'N',
           'PERMITE IMPORTAR XML DE UMA NF-E DO FORNECEDOR QUANDO DUAS OU MAIS EMPRESAS DO SISTEMA POSSUIR O MESMO CNPJ ? VALORES:(S-SIM/N-NÃO(VALOR PADRÃO))', vsPD_PermImpXmlCnpj);
      
    -- RC 130016      
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', 0, 'CONS_EXIG_PED_CGO_NFE', 'S', 'N',
           'CONSISTE SE NA IMPORTAÇÃO DO RECEBIMENTO DE NOTA FISCAL ELETRÔNICA OBRIGARÁ INFORMAR O PEDIDO CASO O CGO ESTEJA CONFIGURADO COMO "EXIGE PEDIDO DE COMPRA". VALORES: (S-SIM/N-NÃO(VALOR PADRÃO))', vsPD_ConsExigPedCgoNfe);
           
    -- RC 146285      
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', 0, 'TIPO_INCON_QTDEMBXML', 'S', 'L',
           'INDICA O TIPO DE INCONSISTÊNCIA PARA QUANDO A QTDE DA EMBALAGEM DO XML NÃO ESTIVER CADASTRADA NA FAMÍLIA.' || chr(13) || chr(10) ||
           'VALORES:' || chr(13) || chr(10) ||
           'B-BLOQUEIO' || chr(13) || chr(10) ||
           'L-LIBERAÇÃO(PADRÃO)', vsPDTipoInconQtdEmbXml);  

    -- RP 149708
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', pnNroEmpresa, 'CONSISTE_ITEM_NFE_COMPLIMPOSTO', 'S', 'S', 
           'INDICA SE GERA INCONSISTÊNCIA DE PRODUTO NÃO ENCONTRADO OU QUANTIDADE NÃO INFORMADA PARA ITEM DE NFE DE COMPLEMENTO DE IMPOSTO.' || CHR(13) || CHR(10) || 
           'VALORES:' || CHR(13) || CHR(10) || 
           'N-NÃO' || CHR(13) || CHR(10) || 
           'S-SIM(PADRÃO)',vsPD_GeraInconsProdCompl);
           
    -- RC 168362
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NFE', pnNroEmpresa, 'PMT_VERIF_CANC_SEFAZ_LIB_RECEB', 'S', 'N', 
           'PERMITE VERIFICAR O CANCELAMENTO JUNTO À SEFAZ APENAS NA GERAÇÃO DA NFE P/ RECEBTO(PD VERIFICA_NFE_CANC_SEFAZ=''R'',''S'') OU NA LIB. DA NF NO RECEBTO(PD VERIFICA_NFE_CANC_SEFAZ=''R'',''S'') E CONF.CARGA(PD VERIFICA_NFE_CANC_SEFAZ=''S'').VALORES (S/N(PADRÃO: N))',vsPD_PmtVerifCancSefazLibRec);       

    -- RC 238433       
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', 0, 'PMT_VISUAL_PED_FORN_REL', 'S', 'N',
      'PERMITE VISUALIZAR APENAS PEDIDOS DE OUTROS FORNECEDORES CASO ESTES ESTEJAM RELACIONADOS? VALORES:S - SIM; N- NÃO - (TAMBÉM SERÁ CONSIDERADO O CNPJ BASE PARA FAZER O RELACIONAMENTO(PADRÃO))', vsPD_PmtVisualPedFornRel);

    -- Issue DSUPREC-9791
    Pkg_Mlf_Recebimento.Sp_BuscaParametroDinamico('RECEBTO_NFE', pnNroEmpresa, 'BLOQUEIA_RECEBTO_ESTORNO_FORN', 'S', 'N',
           'BLOQUEIA RECEBIMENTO DE NF QUANDO EXISTE UMA NOTA DE ESTORNO DE COMPRA DO FORNECEDOR' || Chr(13) || Chr(10) ||
           'N - NÃO BLOQUEIA (PADRÃO)' || Chr(13) || Chr(10) ||
           'L - EXIBE INCONSISTÊNCIA DE LIBERAÇÃO' || Chr(13) || Chr(10) ||
           'B - EXIBE INCONSISTÊNCIA DE BLOQUEIO', vsPD_BloqRecebEstornoForn);
    
    -- DSUPREC-14263
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NF', pnNroEmpresa, 'IND_RECEB_BONIF_NFCOMPRA', 'S', 'N',
           'INDICA SE A EMPRESA ACEITA RECEBER ITENS DE BONIFICAÇÃO EM UMA MESMA NOTA DE COMPRAS (S/N)', vsPD_RecebBonifNFCompra);
    
    -- Exclui as inconsistências
    DELETE FROM  MRL_NFEINCONSISTENCIA
    WHERE  SEQNOTAFISCAL = pnIDNFE AND
           AUTORIZADA = 'N';
    --RC 119665
    SELECT COUNT(1)
      INTO vnItensPedido
      FROM MRLV_NFEIMPORTACAOITEM A
     WHERE A.SEQNOTAFISCAL = pnIDNFE
       AND A.SEQNFITEM NOT IN
           (SELECT B.SEQNFITEM
              FROM MRL_NFEITEMPEDIDO B
             WHERE B.SEQNOTAFISCAL = pnIDNFE
               AND NVL(B.NROPEDIDOSUPRIM, 0) != 0);
    --
    SELECT  COUNT(DISTINCT N.SEQPESSOA), N.PEDIDO
    INTO    vnCount,vsPedido
    FROM    MRLV_NFEIMPORTACAO N               
    WHERE   N.SEQNOTAFISCAL = pnIDNFE
    GROUP BY N.PEDIDO;   
    
    /*1 - Consiste se há mais de um fornecedor cadastrado com o mesmo CNPJ*/
   if vnCount > 1 then
      SELECT  MAX(SEQFORNECEDOR)
      INTO    vnSeqFornec
      FROM    MRL_NFEIMPORTACAO
      WHERE   SEQNOTAFISCAL = pnIDNFE;
      
      if vnSeqFornec is null then
        SP_GRAVAINCONSISTENCIANFE(pnIDNFE, 0, 'N', 1, 'B', 'Há mais de um fornecedor para a NFe, verifique e escolha apenas um.');
      end if;
    end if;
    
    /* RP 126085 Consiste se a NF já foi importada para outra empresa com o mesmo CNPJ */
    If vsPD_PermImpXmlCnpj = 'S' Then
    
        SELECT MAX(N.CHAVEACESSO)
          INTO vnChaveNFe
          FROM MRLV_NFEIMPORTACAO N
         WHERE N.SEQNOTAFISCAL = pnIDNFE
           AND N.NROEMPRESA = pnNroEmpresa;
         
        SELECT MIN('Nota ' || A.NUMERONF ||
                   ' - Série ' || A.SERIENF ||
                   ' - Fornecedor ' || A.SEQPESSOA ||
                   ', já foi importada pela empresa ' || A.NROEMPRESA || '.')
          INTO vsMensagemConsis
          FROM ( 
                 SELECT X.SEQNOTAFISCAL, X.SEQAUXNOTAFISCAL,
                        X.NROEMPRESA, X.SEQPESSOA, X.NUMERONF,
                        X.SERIENF, X.NFECHAVEACESSO
                 FROM MLF_AUXNOTAFISCAL X
                 WHERE  NVL(X.NFECHAVEACESSO,X.NFECHAVEACESSOCOPIA) = vnChaveNFe
                 AND    X.TIPNOTAFISCAL = 'E'
                 AND    X.NROEMPRESA != pnNroEmpresa

                 UNION

                 SELECT Y.SEQNOTAFISCAL, Y.SEQAUXNOTAFISCAL,
                        Y.NROEMPRESA, Y.SEQPESSOA, Y.NUMERONF,
                        Y.SERIENF, Y.NFECHAVEACESSO
                 FROM MLF_NOTAFISCAL Y
                 WHERE  Y.NFECHAVEACESSO = vnChaveNFe
                 AND    Y.TIPNOTAFISCAL = 'E'              
                 AND    Y.NROEMPRESA != pnNroEmpresa

               ) A
          WHERE  A.NFECHAVEACESSO = vnChaveNFe;
          
          If vsMensagemConsis is not null Then
               SP_GRAVAINCONSISTENCIANFE(pnIDNFE, 0, 'N', 11, 'L', vsMensagemConsis);
          End if;
    End if;
    
    SELECT NVL(MAX(C.EXGPEDIDOCOMPRA), 'N')
    INTO   vsExgPedidoCompra
    FROM   MAX_CODGERALOPER C, MRL_NFEIMPORTACAO N                 
    WHERE  N.SEQNOTAFISCAL = pnIDNFE
    AND    N.CODGERALOPER = C.CODGERALOPER;
    
    /*2 - Consiste se o Pedido informado é um numero válido */
    if vsPD_ConsExigPedCgoNfe = 'S' AND vsExgPedidoCompra = 'S' AND  vsConsPedidoNumerico = 'S' AND LTRIM(vsPedido,'0123456789/') IS NOT NULL AND vnItensPedido > 0 then
      SP_GRAVAINCONSISTENCIANFE(pnIDNFE, 0, 'N', 2, 'L', 'Pedido de Suprimento não identificado.');
    end if;
    /*3,4,5,6 - Consiste os itens da NFE*/
    
    FOR vit IN(
                SELECT  DISTINCT I.SEQNFITEM, NVL(P.SEQPRODUTO,I.SEQPRODUTO) SEQPRODUTO, NVL(P.QUANTIDADE,I.QUANTIDADE) QUANTIDADE, I.CODACESSO,
                        I.IDITEM,I.DESCPRODUTO, I.PEDIDO, NVL(P.QTDEMBALAGEM, I.QTDEMBALAGEM) QTDEMBALAGEM, I.SEQPESSOA, 
                        DECODE(P.SEQPRODUTO, NULL, I.SEQFAMILIA, (SELECT SEQFAMILIA FROM MAP_PRODUTO WHERE SEQPRODUTO = P.SEQPRODUTO)) SEQFAMILIA,
                        P.NROPEDIDOSUPRIM, I.NROEMPRESA, NVL(P.NROITEM,I.SEQNFITEM) NROITEM, I.QTDUN, NVL(P.QTDEMBALAGEM,0) QTDEMBALAGEMPED,
                        I.PERALIQICMSSTDISTRIB
                FROM    MRLV_NFEIMPORTACAOITEM I, MRL_NFEITEMPEDIDO P
                WHERE   I.SEQNOTAFISCAL = pnIDNFE
                AND     I.NROEMPRESA    = pnNroEmpresa
                AND     I.SEQNOTAFISCAL = P.SEQNOTAFISCAL(+)
                AND     I.SEQNFITEM     = P.SEQNFITEM(+)
                ORDER BY I.SEQNFITEM
              )
    LOOP
      
      -- RC 127471, Início
      BEGIN
        SELECT NVL(B.INDASSUMEEMBQTDEMBXML, 'N')
          INTO vsIndAssumeEmbQtdEmbXml
          FROM MAF_FORNECEDOR A, 
               MAF_FORNECDIVISAO B, 
               MAX_EMPRESA C
         WHERE A.SEQFORNECEDOR = B.SEQFORNECEDOR
           AND B.NRODIVISAO = C.NRODIVISAO
           AND C.NROEMPRESA = pnNroEmpresa
           AND A.SEQFORNECEDOR = vit.seqpessoa;
      EXCEPTION 
          WHEN NO_DATA_FOUND THEN
            vsIndAssumeEmbQtdEmbXml := 'N';      
      END;         
         
      if vsIndAssumeEmbQtdEmbXml = 'S' and (vit.qtdun > 0) and (vit.qtdembalagemped) = 0 then
        vit.qtdembalagem := vit.qtdun;
      end if;
      -- RC 127471, Final   
             
      -- Verifica se pedidos selecionados possuem quantidade suficiente de saldo
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', vit.nroempresa, 'BLOQ_NF_SOMA_QTD_SUP_PED', 'S', 'S',
             'BLOQUEIA O RECEBIMENTO DE NOTAS FISCAIS CUJA A SOMATÓRIA DAS QUANTIDADES DOS ITENS SEJA SUPERIOR A QUANTIDADE DO PRODUTO NO PEDIDO DE COMPRAS? VALORES:(S-SIM(VALOR PADRÃO)/N-NÃO)', vsAux );
      vsBloqNFSomaQtdSupPed := SubStr(vsAux,0,1);
      
      
      -- Limite da Quantidade acima do pedido pesáveis
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', vit.nroempresa, 'PER_RECE_QTDE_ACI_PED_PESAV', 'N', '0',
              'PERCENTUAL LIMITE ACEITA RECEBER DA QUANTIDADE ACIMA DO PEDIDO PESAVEIS (EM PERCENTUAL %)', vsPD_PerLimQtdeAcimPedPes );
      vsPD_PerLimQtdeAcimPedPes := REPLACE(vsPD_PerLimQtdeAcimPedPes,',', '.');
      vnPD_PerLimQtdeAcimPedPes := TO_NUMBER(vsPD_PerLimQtdeAcimPedPes);
      -- Quantidade acima do pedido
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', vit.nroempresa, 'IND_ACE_RECE_QTDE_ACIMA_PEDIDO', 'S', 'N',
              'INDICADOR SE ACEITA RECEBIMENTO COM QUANTIDADE ACIMA DO PEDIDO (S/N)', vsPD_AceRecebQtdeAcimPedCom );
      vsPD_AceRecebQtdeAcimPedCom := SUBSTR(vsPD_AceRecebQtdeAcimPedCom,1,1);
      -- Limite da Quantidade acima do pedido
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', vit.nroempresa, 'PER_RECE_QTDE_ACI_PED', 'N', '0',
              'PERCENTUAL LIMITE ACEITA RECEBER DA QUANTIDADE ACIMA DO PEDIDO (EM PERCENTUAL %)', vsPD_PerLimQtdeAcimPedCom );
      vsPD_PerLimQtdeAcimPedCom := REPLACE(vsPD_PerLimQtdeAcimPedCom,',', '.');
      vnPD_PerLimQtdeAcimPedCom := TO_NUMBER(vsPD_PerLimQtdeAcimPedCom);
      if vit.SEQPRODUTO > 0 then
        
        SELECT MAX(NVL(F.INDCONTROLEVDA,'N')), MAX(NVL(F.INDUSALOTEESTOQUE,'N')), 
               MAX(decode(F.PESAVEL, 'S', 'S', 
                                               case 
                                                 when vsPDEmbPesavel = 'S' then
                                                    nvl(E.EMBPESAVEL, F.PESAVEL)
                                                 else 
                                                    F.PESAVEL
                                               end ) ),
               MAX(decode(F.PMTDECIMAL, 'S', 'S', 
                                               case 
                                                 when vsPDEmbDecimal = 'S' then
                                                    nvl(E.EMBDECIMAL, F.PMTDECIMAL)
                                                 else 
                                                    F.PMTDECIMAL
                                               end ) )                      
        INTO   vsPsicotropico, vsContrLote,vsPesavel, vsDecimal
        FROM   MAP_PRODUTO P,MAP_FAMILIA F, MAP_FAMEMBALAGEM E
        WHERE  F.SEQFAMILIA = P.SEQFAMILIA
        AND    E.SEQFAMILIA = F.SEQFAMILIA
        AND    E.QTDEMBALAGEM = vit.QTDEMBALAGEM 
        AND    P.SEQPRODUTO = vit.SEQPRODUTO;        
      
        SELECT  NVL(MAX(F.FATORCONVEMBXML ),0) FATORCONVEMBXML,
                NVL(MAX(
                        CASE WHEN vsPDConvEmbXML = 'S' AND NVL(F.FATORCONVEMBXML,0) > 0 THEN
                                   (vit.QUANTIDADE /  F.FATORCONVEMBXML)
                             ELSE
                                  0
                        END * vit.QTDEMBALAGEM
                        ),0) QUANTIDADECONV,
                NVL(MAX(
                        CASE WHEN vsPDConvEmbXML = 'S' AND NVL(F.FATORCONVEMBXML,0) > 0 THEN
                                   (vit.QUANTIDADE /  F.FATORCONVEMBXML)
                             ELSE
                                  0
                        END
                        ),0) QUANTIDADEDIVPELOFATOR
        INTO    vnFatorConvEmbXML, vnQuantidadeConv, vnQuantidadeDivPeloFator
        FROM    MAP_FAMFORNEC F
        WHERE   F.SEQFAMILIA    = vit.seqfamilia
        AND     F.SEQFORNECEDOR = vit.seqpessoa;        
      end if;
          
      IF vsBloqNFSomaQtdSupPed = 'S' THEN    
        IF LTRIM(vit.NROPEDIDOSUPRIM,'0123456789') IS NULL THEN
      
            SELECT SUM(NVL(A.QUANTIDADE * NVL(A.QTDEMBALAGEM, 1), 0)), 
                   NVL(MAX(B.QTDSALDO - B.QTDTOTTRANSITO), 0)
            INTO   vnQtdUtilPedido, 
                   vnQtdSaldoPed
            FROM   MRL_NFEITEMPEDIDO  A,
                   MSUV_PSITEMRECEBER B,
                   MRLV_NFEIMPORTACAO  C --RC 123588
            WHERE  B.NROPEDIDOSUPRIM = A.NROPEDIDOSUPRIM
            AND    C.SEQNOTAFISCAL   = A.SEQNOTAFISCAL
            AND    C.SEQPESSOA       in (SELECT DISTINCT Column_Value
                                               FROM TABLE(CAST(C5_Complexin.C5intable(fc_FornecRelac(b.seqfornecedor, vsPD_PmtVisualPedFornRel)) AS C5instrtable)))
            AND    C.NROEMPRESA      = B.NROEMPRESA
            AND    A.SEQPRODUTO      = B.SEQPRODUTO
            AND    C.SEQPESSOA       = vit.SEQPESSOA
            AND    C.NROEMPRESA      = vit.NROEMPRESA
            AND    A.SEQPRODUTO      = vit.SEQPRODUTO
            AND    A.NROPEDIDOSUPRIM = vit.NROPEDIDOSUPRIM
            AND    A.SEQNOTAFISCAL   = pnIDNFE
            AND NOT EXISTS ( 	SELECT X.SEQNOTAFISCAL -- RC 123588
                  					  FROM MLF_AUXNOTAFISCAL X
                 					    WHERE X.NUMERONF   =  C.NUMERONF
          					          AND X.SEQPESSOA  =  C.SEQPESSOA
           					          AND  LPAD(TRIM(X.SERIENF),3,'0') = LPAD(C.SERIENF,3,'0')
           					          AND X.NROEMPRESA =  C.NROEMPRESA
					                    AND X.TIPNOTAFISCAL = 'E'
					                    AND to_char(X.DTAEMISSAO, 'dd/mm/yyyy') = C.DTAEMISSAO
					                    AND NVL(X.NFECHAVEACESSO, NVL(X.NFECHAVEACESSOCOPIA, 0)) = c.CHAVEACESSO)
     			  AND NOT EXISTS( 	SELECT Y.SEQNOTAFISCAL
                  			   		FROM MLF_NOTAFISCAL Y
                  			  		WHERE Y.NUMERONF   =  C.NUMERONF
           				    	      AND Y.SEQPESSOA  =  C.SEQPESSOA
           				    	      AND LPAD(TRIM(Y.SERIENF),3,'0') = LPAD(C.SERIENF,3,'0')
           				    	      AND Y.NROEMPRESA =  C.NROEMPRESA
   					                  AND Y.TIPNOTAFISCAL = 'E'
					                    AND to_char(Y.DTAEMISSAO, 'dd/mm/yyyy') = C.DTAEMISSAO
					                    AND NVL(Y.NFECHAVEACESSO, 0) = C.CHAVEACESSO);
                 
            if vnFatorConvEmbXML > 0 then
                if vsPesavel != 'S' and vsDecimal != 'S' then
                  vnQtdUtilPedido := trunc(vnQtdUtilPedido / vnFatorConvEmbXML);
                else
                  vnQtdUtilPedido := vnQtdUtilPedido / vnFatorConvEmbXML;
                end if;
            end if;
            
            -- Se aceitar pedido acima, verifica a margem
            vnPercLimMsg := 0;
            vnQtdSaldoPedMsg := vnQtdSaldoPed;
            IF vsPD_AceRecebQtdeAcimPedCom = 'S' THEN
               
               -- Verifica se é uma família pesável para calcular a tolerância
               IF vsPesavel = 'S' THEN
                  vnQtdSaldoPed := (vnQtdSaldoPed * (1 + (vnPD_PerLimQtdeAcimPedPes / 100)));
                  vnPercLimMsg := vnPD_PerLimQtdeAcimPedPes;
               ELSE
                  vnQtdSaldoPed := (vnQtdSaldoPed * (1 + (vnPD_PerLimQtdeAcimPedCom / 100)));
                  vnPercLimMsg := vnPD_PerLimQtdeAcimPedCom;
               END IF;   
            
            End IF;
            
            IF vnQtdSaldoPed < vnQtdUtilPedido THEN
               
               SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 20, 'B', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO ||
                                                                               ' - Desc.: ' || TRIM(SUBSTR(vit.DESCPRODUTO, 0, 100)) ||
                                                                               ' - Qtde do item (' || TO_CHAR(vnQtdUtilPedido, '999G999D999', 'nls_numeric_characters = ,.') ||
                                                                               ') maior do que o saldo disponível do pedido ' || vit.NROPEDIDOSUPRIM ||
                                                                               ' (' || TO_CHAR(vnQtdSaldoPedMsg, '999G999D999', 'nls_numeric_characters = ,.') || ')' ||
                                                                               CASE WHEN vnPercLimMsg > 0 THEN
                                                                                    ' + ' || TO_CHAR(vnPercLimMsg, '999G999D999', 'nls_numeric_characters = ,.') ||
                                                                                    '% de Diferença Permitido.'
                                                                               ELSE
                                                                                    '.'
                                                                               END);
            
            END IF;
            
        END IF;
      END IF;
      
      -- RP 149708
      SELECT NVL(max(C.INDCOMPLVLRIMP), 'N'),
             max(E.SEQPRODUTOCOMPLIMPOSTO)
      
      INTO   vsIndComplVlrImposto, 
             vnSeqProdComplemImposto
             
      FROM   MRL_NFEIMPORTACAO N,
             MAX_CODGERALOPER C,               
             MAX_EMPRESA E
      
      WHERE  C.CODGERALOPER = N.CODGERALOPER    
      AND    E.NROEMPRESA   = N.NROEMPRESA
      
      AND    N.SEQNOTAFISCAL = pnIDNFE;      

      -- Não gera a inconsistência caso o PD CONSISTE_ITEM_NFE_COMPLIMPOSTO = 'N' e a coluna INDCOMPLVLRIMP = 'S'
      If vsPD_GeraInconsProdCompl != 'N' OR vsIndComplVlrImposto != 'S' Then
        /* PRODUTO NÃO ENCONTRADO*/
        if vit.SEQPRODUTO =  0 then
          SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 3, 'L', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Produto não encontrado.');
        end if;
        
        /* PRODUTO SEM QUANTIDADE INFORMADA*/
        if vit.QUANTIDADE = 0 then
          SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 4, 'B', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Produto sem quantidade informada.');
        end if; 
      Else
        /* PRODUTO PADRÃO DE COMPLEMENTO DE IMPOSTO NÃO CONFIGURADO NOS PARÂMETROS DA EMPRESA */
        if vit.SEQPRODUTO = 0 And vnSeqProdComplemImposto is null then
          SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 15, 'B', 'Produto Padrão de Complemento de Imposto não configurado nos Parâmetros da Empresa.');
        end if;  
      End If;
      --
      if vit.SEQPRODUTO > 0 then
        
        SELECT NVL(MAX(E.QTDEMBALAGEM),0)
        INTO   vnQtdEmbalagemXml
        FROM   MAP_PRODUTO P,MAP_FAMILIA F, MAP_FAMEMBALAGEM E
        WHERE  F.SEQFAMILIA = P.SEQFAMILIA
        AND    E.SEQFAMILIA = F.SEQFAMILIA
        AND    E.QTDEMBALAGEM = vit.qtdun
        AND    P.SEQPRODUTO = vit.SEQPRODUTO;
        
        /* PRODUTO QUE NÃO SEJA PESADO E ESTEJA COM QUANTIDADE FRACIONADA*/
        if round(vit.QUANTIDADE) != vit.QUANTIDADE  AND NOT (vsPesavel = 'S' or vsDecimal = 'S' or ( vsPDConvEmbXML = 'S' and vnFatorConvEmbXML > 0))  then
          SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 17, 'B', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Produto informado não permite quantidade fracionada. Pedido: ' || vit.NROPEDIDOSUPRIM || '.');
        end if; 

        SELECT  COUNT(1)
        INTO    vnProdLote
        FROM    TMP_M017_MED M 
        WHERE   M.M014_ID_ITEM = vit.IDITEM;
        
        /*PRODUTO COM LOTE SEM A INDICAÇÃO DE CONTROLE DE LOTE NA FAMILIA*/
        if ( ((vsPDGeraIncLoteMed = 'P' and  vsPsicotropico = 'S') or vsPDGeraIncLoteMed = 'S' ) 
              and vnProdLote > 0 and vsContrLote = 'N') then
          if vsPsicotropico = 'N' then
            SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 5, 'L', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - O Produto tem lote na NFe mas na Família não está marcado que controla lote.');
          Else 
            SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 5, 'B', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || TRIM(SUBSTR(vit.DESCPRODUTO, 0, 110)) || ' - O Produto tem lote na NFe mas na Família não está marcado que controla lote e está marcado que é Psicotrópico.');
          end if;
        end if;
        
        /*6 - Consiste se o Pedido informado é um numero válido */
        if vsPD_ConsExigPedCgoNfe = 'S' AND vsExgPedidoCompra = 'S' AND vsConsPedidoNumerico = 'S' AND LTRIM(vit.PEDIDO,'0123456789/') IS NOT NULL and NVL(vit.NROPEDIDOSUPRIM,0) = 0 then
          SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 6, 'L', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Nro.Pedido: ' || vit.PEDIDO || '. Pedido de Suprimento não identificado.');
        end if;
        
        -- RC 131188 - Consiste se a embalagem definida no xml pertence a família do produto        
        if vsContrLote is null and vsIndAssumeEmbQtdEmbXml = 'N' then
          SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 10, 'B', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Embalagem do produto no XML (' || vit.QTDEMBALAGEM || ') não existe no cadastro da família.');
        end if;
        
        -- RC 146285, Início
        if vsIndAssumeEmbQtdEmbXml = 'S' and vnQtdEmbalagemXml = 0 and vit.qtdun > 0 then
          SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 12, vsPDTipoInconQtdEmbXml, vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || SUBSTR(vit.DESCPRODUTO, 0, 110) || ' - Embalagem do produto no XML (' || vit.QTDUN || ') não existe no cadastro da família. Por este motivo ela não foi utilizada.');
        end if;        
        
        if vsIndAssumeEmbQtdEmbXml = 'S' and vnQtdEmbalagemXml > 0 and vit.qtdembalagem != vit.qtdun then
          SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 13, 'L', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Embalagem do produto (' || vit.QTDEMBALAGEM || ') diferente da embalagem do produto no XML (' || vit.QTDUN || ').');
        end if;
        -- RC 146285, Final                
        
        SELECT COUNT(1)
        INTO   vnCount
        FROM   MRL_PRODUTOEMPRESA
        WHERE  SEQPRODUTO = vit.SEQPRODUTO
        AND    NROEMPRESA = pnNroEmpresa;
        If vnCount = 0 Then
          SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 21, 'B', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Produto não cadastrado para a empresa da nota.');
        End If;
      end if;
      
      /* ITEM CONVERTIDO POR FATOR XML E COM QTD DECIMAL OU NEGATIVA */
      IF vsPDConvEmbXML = 'S' AND vnFatorConvEmbXML > 0 THEN
         IF vnQuantidadeConv < 0 THEN
            SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 9, 'B', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Produto com quantidade convertida negativa. Fator Conv.XML: ' || TO_CHAR(vnFatorConvEmbXML, '999G999D999', 'nls_numeric_characters = ,.') || '.');
         END IF;
         
         IF (MOD(round (vnQuantidadeConv,2), 1) > 0.01 OR MOD(Round(vnQuantidadeDivPeloFator, 2), 1) > 0.01) AND NOT (vsPesavel = 'S' or vsDecimal = 'S')  THEN
            SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 9, 'B', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Produto com quantidade convertida fracionada. Fator Conv.XML: ' || TO_CHAR(vnFatorConvEmbXML, '999G999D999', 'nls_numeric_characters = ,.') || '.');
         END IF;
      END IF;
      
      /*16 - Consiste se a alíquota de ICMS ST Retido é maior que 99,99*/
      IF NVL(vit.PERALIQICMSSTDISTRIB, 0) >= 100 THEN
        SP_GRAVAINCONSISTENCIANFE(pnIDNFE, vit.SEQNFITEM, 'N', 16, 'L', vit.NROITEM || ' - Cod. ' || vit.SEQPRODUTO || ' - Desc.: ' || vit.DESCPRODUTO || ' - Produto com alíquota de ICMS ST Retido maior que 99,99. Valor: ' || TO_CHAR(vit.PERALIQICMSSTDISTRIB, '999D99', 'nls_numeric_characters = ,.') || '. A alíquota não será importada.');
      END IF;

    END LOOP;
    
    -- Consiste se o tipo do pedido de compra associado na nota é diferente do tipo de pedido de compra exigido configurado no CGO
    IF vsPD_RecebBonifNFCompra = 'S' THEN
      SELECT MAX(D.TIPPEDIDOCOMPRA)
      INTO vsTipoPedCompCGO
      FROM MRL_NFEIMPORTACAO C,
           MAX_CODGERALOPER D
      WHERE C.SEQNOTAFISCAL = pnIDNFE
      AND C.CODGERALOPER = D.CODGERALOPER;
        
      IF vsTipoPedCompCGO = 'C' THEN
        SELECT COUNT(1)
        INTO vnQtdePedidosNFe
        FROM MRL_NFEITEMPEDIDO A
        WHERE A.SEQNOTAFISCAL = pnIDNFE
        AND A.NROPEDIDOSUPRIM > 0;
        
        IF vnQtdePedidosNFe > 0 THEN
          -- Se o PD IND_RECEB_BONIF_NFCOMPRA for S e o tipo do pedido no CGO for C, ao menos um dos itens da nota precisa ter um pedido do tipo C associado
          SELECT COUNT(1)
          INTO vnTipoPedCompNFe
          FROM MRL_NFEITEMPEDIDO A,
               MSU_PEDIDOSUPRIM B
          WHERE A.SEQNOTAFISCAL = pnIDNFE
          AND A.NROPEDIDOSUPRIM = B.NROPEDIDOSUPRIM
          AND B.TIPPEDIDOSUPRIM = 'C';
          
          IF vnTipoPedCompNFe = 0 THEN
            SP_GRAVAINCONSISTENCIANFE(pnSeqNotafiscal     => pnIDNFE,
                                      pnSeqItem           => 0,
                                      psTipoInconsist     => 'N',
                                      pnCodInconsist      => 23,
                                      psBloqueioLiberacao => 'L',
                                      psDescricao         => 'Não foi associado nenhum pedido do tipo Compra.');
          END IF;
        END IF;
      END IF;
    END IF;
    ----

    -- Consiste se foi cancelada ou rejeitada
    for t in ( SELECT 'A Nota ' || A.NUMERONF ||
                      ', Série ' || A.SERIENF ||
                      ', Forn. ' || A.SEQPESSOA ||
                      ', Empr. ' || a.NROEMPRESA ||
                      ', Chave ' || a.CHAVEACESSO ||
                      case when b.indCancelRejeicao = 'C' then
                           ', está CANCELADA na SEFAZ. Verifique!'
                      else
                           ', está REJEITADA na SEFAZ. Verifique!'
                      end historico
               FROM   MRLV_NFEIMPORTACAO A, MRL_NFEIMPORT_CANCREJ B
               WHERE  A.SEQNOTAFISCAL = pnIDNFe
               AND    A.CHAVEACESSO   = b.nfechaveacesso) /*RA 70214*/
     loop   
         SP_GRAVAINCONSISTENCIANFE(pnIDNFE, 0, 'N', 7, 'B', t.historico);
         vbNFCanceladaSefaz := TRUE;
     end loop;

     -- Consiste se há uma nota de estorno referenciando-a
     If vsPD_BloqRecebEstornoForn In ('L', 'B') Then

       Select Max(A.ChaveAcesso)
       Into vnChaveNFe
       From Mrlv_NfeImportacao A
       Where A.SeqNotaFiscal = pnIdNFe
       And A.NroEmpresa = pnNroEmpresa;

       For i In (Select 'A NF ' || A.NumeroNf ||
                        ', Série ' || A.SerieNf ||
                        ', Forn. ' || A.SeqPessoa ||
                        ', Empr. ' || A.NroEmpresa ||
                        ', Chave ' || A.ChaveAcesso ||
                        ', possui NF ' || C.M000_Nr_Documento ||
                        '/' || C.M000_Nr_Serie ||
                        ' de estorno pelo Fornecedor. Verifique-a!' Mensagem
                 From Mrlv_NfeImportacao A,
                      Tmp_M013_Chave_Ref B,
                      Tmp_M000_Nf C
                 Where A.ChaveAcesso = B.M013_Nr_Chave_Acesso_Ref
                 And B.M013_Nr_Chave_Acesso_Ref = vnChaveNFe
                 And B.M000_Id_Nf = C.M000_Id_Nf
                 And C.M000_Dm_Entrada_Saida = 0
                 And A.NroEmpresa = pnNroEmpresa)
       Loop

         SP_GRAVAINCONSISTENCIANFE(pnSeqNotafiscal     => pnIdNFe,
                                   pnSeqItem           => 0,
                                   psTipoInconsist     => 'N',
                                   pnCodInconsist      => 22,
                                   psBloqueioLiberacao => vsPD_BloqRecebEstornoForn,
                                   psDescricao         => i.Mensagem);

       End Loop;

     End If;

     --REQ.78745
    --Consiste o numero de parcelas de acordo com o cadastro do fornecedor
    If vsPDConsistePrzoContrato = 'S' Then
      -- Verifica primeiro se tem contrato ativo senão tiver, não faz a inconsistencia
      
       SELECT  MAX(SEQFORNECEDOR), MAX(NROEMPRESA)
        INTO    vnSeqFornec, vnNroEmpresa
        FROM    MRL_NFEIMPORTACAO
        WHERE   SEQNOTAFISCAL = pnIDNFE;
     
     
       SELECT COUNT(1)
       into vnExisteContrato
       FROM MGC_CONTRATO C
       WHERE (C.SEQPESSOACAF = vnSeqFornec OR EXISTS
             (SELECT 1
                FROM GE_REDEPESSOA X
               WHERE X.SEQREDE = C.SEQREDE
                 AND X.STATUS = 'A'
                 AND X.SEQPESSOA = vnSeqFornec))
        AND C.DTAFIMVALIDADE >= TRUNC(SYSDATE)
        AND C.STATUS = 'A'; 
     
      ----
      IF vnExisteContrato > 0 THEN 
      
            SELECT COUNT(1) 
            INTO vnQtdTmpM004
            FROM TMP_M004_DUPLICATA D
            WHERE D.M000_ID_NF = pnIDNFE;
            --rc 192730
            If vnQtdTmpM004 > 0  then
            
                SELECT count(COLUMN_VALUE)
                  into vnQtdPzoPagto
                  FROM TABLE(cast(c5_ComplexIn.c5InTable((SELECT DECODE(vsPDUtilCondPagtoContrFidel, 'S', NVL(CP.CONDPRAZOPAGTO,  F.PZOPAGAMENTO),  F.PZOPAGAMENTO)
                                                           FROM MAF_FORNECDIVISAO F,
                                                                MAX_EMPRESA       E,
                                                                MRL_CONDPRAZOPAGTO CP
                                                          WHERE F.NRODIVISAO = E.NRODIVISAO
                                                            AND F.SEQCONDCONDPRAZOPAGTO  = CP.SEQCONDCONDPRAZOPAGTO (+)
                                                            AND F.SEQFORNECEDOR = vnSeqFornec
                                                            AND E.NROEMPRESA = vnNroEmpresa),
                                                         '/') as c5InStrTable));
                IF vnQtdTmpM004 != vnQtdPzoPagto THEN
                
                   SP_GRAVAINCONSISTENCIANFE(pnIDNFE, 0, 'N', 8, 'L', 'Quantidade de parcelas da NF é diferente da quantidade de parcelas do prazo de pagamento do fornecedor.');
                   
                END IF;
                
            END IF;
            
      END IF;
    End If;
        
    SELECT COUNT(1)
    INTO   vnQtdPedidos
    FROM   MRL_NFEITEMPEDIDO N
    WHERE  N.SEQNOTAFISCAL = pnIDNFE
    AND NOT EXISTS (SELECT 1
                   FROM MSU_PSITEMRECEBER I
                   WHERE I.NROPEDIDOSUPRIM = N.NROPEDIDOSUPRIM
                   AND I.SEQPRODUTO = N.SEQPRODUTO);
    
    -- RP 155228 - Inserido a variável vnItensPedido no IF abaixo
    IF vsPD_ConsExigPedCgoNfe = 'S' AND vsExgPedidoCompra = 'S' AND ( vnQtdPedidos > 0 OR vnItensPedido > 0 ) THEN        
       SP_GRAVAINCONSISTENCIANFE(pnIDNFE, 0, 'N', 19, 'L', 'Para o CGO informado é necessário informar um pedido de compras.');
    END IF;
    
    -- RC 168362
    if (vsPD_PmtVerifCancSefazLibRec = 'N' Or pnVerifCancSefazLib = 1) And Not vbNFCanceladaSefaz then
    
        -- RC 131510
        /* 12 - Consiste se a NF foi cancelada pela SEFAZ*/
        select  MAX(N.CHAVEACESSO)
        into    vnChaveNFe
        from    MRLV_NFEIMPORTACAO N
        where   N.SEQNOTAFISCAL = pnIDNFE
        and     N.NROEMPRESA = pnNroEmpresa;
        
        SP_VERIFNFESEFAZ( vnChaveNFe, 
                          pnNroEmpresa, 
                          'T', 
                          null, 
                          vnStatusNFESefaz, 
                          vsMensagemConsis );
        
        if vnStatusNFESefaz = 1 and vnStatusNFESefaz is not null then
            SP_GRAVAINCONSISTENCIANFE(pnIDNFE, 0, 'N', 14, 'B', vsMensagemConsis);
        end if;
    
    end if;
    
    -- RP 202257    
    SELECT COUNT(1),
           MAX(A.NUMERONF),
           MAX(A.SERIENF),
           MAX(A.SEQPESSOA),
           MAX(TO_DATE(A.DTAEMISSAO,'dd/MM/yyyy')),
           MAX(A.CHAVEACESSO)
    INTO   vnCount,
           vnNroNota,
           vsSerieNota,
           vnSeqPessoa,
           vdDtaEmissao,
           vsChaveAcesso         
    FROM   MRLV_NFEIMPORTACAO A
    WHERE  A.SEQNOTAFISCAL = pnIDNFE
    AND    A.NROEMPRESA = pnNroEmpresa;
    
    If vnCount > 1 then
      SELECT  MAX(SEQFORNECEDOR)
      INTO    vnSeqFornec
      FROM    MRL_NFEIMPORTACAO
      WHERE   SEQNOTAFISCAL = pnIDNFE;
      
      If vnSeqFornec is not null then
        SELECT MAX(A.NUMERONF),
               MAX(A.SERIENF),
               MAX(A.SEQPESSOA),
               MAX(TO_DATE(A.DTAEMISSAO,'dd/MM/yyyy')),
               MAX(A.CHAVEACESSO)
        INTO   vnNroNota,
               vsSerieNota,
               vnSeqPessoa,
               vdDtaEmissao,
               vsChaveAcesso         
        FROM   MRLV_NFEIMPORTACAO A
        WHERE  A.SEQNOTAFISCAL = pnIDNFE
        AND    A.NROEMPRESA = pnNroEmpresa
        AND    A.SEQPESSOA = vnSeqFornec;
      End If;
    End If;
    
    IF ORF_EXISTENOTA(pnNroEmpresa, 
                      vnNroNota, 
                      vsSerieNota, 
                      vnSeqPessoa, 
                      vdDtaEmissao, 
                      vsChaveAcesso) = 1 THEN
      SP_GRAVAINCONSISTENCIANFE(pnIDNFE, 0, 'N', 18, 'B', 'A nota informada já existe no módulo Orçamento.');
    END IF;
    ----
    
  EXCEPTION
      WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20200 , SQLERRM );
  
  END SP_CONSISTEIMPNFE;
  

  /*Grava as inconsistências*/
  PROCEDURE SP_GRAVAINCONSISTENCIANFE(
              pnSeqNotafiscal          MRL_NFEINCONSISTENCIA.SEQNOTAFISCAL%TYPE,
              pnSeqItem               MRL_NFEINCONSISTENCIA.SEQNFITEM%TYPE,
              psTipoInconsist         MRL_NFEINCONSISTENCIA.TIPOINCONSIST%TYPE,
              pnCodInconsist          MRL_NFEINCONSISTENCIA.CODINCONSIST%TYPE,
              psBloqueioLiberacao     MRL_NFEINCONSISTENCIA.BLOQUEIOLIBERACAO%TYPE,
              psDescricao             MRL_NFEINCONSISTENCIA.DESCRICAO%TYPE)
  IS
    vnCount   NUMBER;
  BEGIN
    -- Verifica se já existe a inconsistência gravada e autorizada
    SELECT COUNT(*)
    INTO   vnCount
    FROM   MRL_NFEINCONSISTENCIA
    WHERE  SEQNOTAFISCAL = pnSeqNotaFiscal AND
           SEQNFITEM     = pnSeqItem AND
           TIPOINCONSIST = psTipoInconsist AND
           CODINCONSIST = pnCodInconsist AND
           AUTORIZADA = 'S';

    IF vnCount = 0 THEN
      -- Insere na tabela de inconsistências
      INSERT INTO MRL_NFEINCONSISTENCIA(
                   SEQINCONSISTENCIA, SEQNOTAFISCAL, SEQNFITEM,
                   TIPOINCONSIST, CODINCONSIST, DESCRICAO,
                   AUTORIZADA, BLOQUEIOLIBERACAO)
          VALUES   (S_SEQNFEINCONSIST.NEXTVAL, pnSeqNotaFiscal, NVL(pnSeqItem,0),
                   psTipoInconsist, pnCodInconsist, psDescricao,
                   'N', psBloqueioLiberacao);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20200 , SQLERRM );
  END SP_GRAVAINCONSISTENCIANFE;              



  -- ##### Exclui as notas das tabelas de Integração #########
  PROCEDURE SP_EXCLUI_TMP(
              pnIDNFe              IN        TMP_M000_NF.M000_ID_NF%TYPE)
              
  IS
     
      
  BEGIN
  
     delete from TMP_M017_MED a
     where exists (select 1 from tmp_m014_item b
                  where b.m014_id_item = a.m014_id_item
                  and b.m000_id_nf = pnIDNFe);                              
     
     delete from TMP_M018_COMB a
     where exists (select 1 from tmp_m014_item b
                  where b.m014_id_item = a.m014_id_item
                  and b.m000_id_nf = pnIDNFe);                 
     
     delete from TMP_M018_ORIG_COMB a where  a.m000_id_nf = pnIDNFe;                              
     delete from TMP_M001_EMITENTE a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M002_DESTINATARIO a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M003_FATURA a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M020_ADICAO a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M019_DI a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M015_VEICULO a where a.m000_id_nf = pnIDNFe;
     delete from TMP_M014_ITEM a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M004_DUPLICATA a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M013_CHAVE_REF a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M007_REBOQUE a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M005_LOCAL a where  a.m000_id_nf = pnIDNFe;
     Delete From TMP_M011_INFO a Where a.M000_Id_Nf = pnIDNFe;
     Delete From TMP_M009_LACRE a Where Exists (Select 1 From TMP_M008_VOLUME b
                                                Where b.M008_Id_Volume = a.M008_Id_Volume
                                                And b.M000_Id_Nf = pnIDNFe);    
     delete from TMP_M008_VOLUME a where  a.m000_id_nf = pnIDNFe; 
     delete from TMP_M006_TRANSPORTE a where  a.m000_id_nf = pnIDNFe;
     delete from TMP_M012_FISCO a where a.m000_id_nf = pnIDNFe;
     delete from TMP_M000_NF a where  a.m000_id_nf = pnIDNFe;                                
     delete from MRL_NFEIMPORTACAO a where a.seqnotafiscal = pnIDNFe;               
  
  
  EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR (-20200 , SQLERRM );
  END SP_EXCLUI_TMP;  


  PROCEDURE SP_TMPEXCLUSAO(
              pnNroEmpresa              IN        MAX_EMPRESA.NROEMPRESA%TYPE)
              
  IS
  BEGIN                            
    
    
    FOR vNF IN(                                  
                SELECT  C.M000_ID_NF SEQNOTAFISCAL
                FROM    MLF_NOTAFISCAL A, MRL_INTDOCTOFISCAL D, TMP_M000_NF C
                WHERE   D.NUMERODF         =          A.NUMERONF
                AND     D.SERIEDF          =          A.SERIENF
                AND     D.SEQPESSOA        =          A.SEQPESSOA
                AND     D.NROEMPRESA       =          A.NROEMPRESA
                AND     D.INDENTRADASAIDA  =          A.TIPNOTAFISCAL
                AND     A.SEQNOTAFISCAL IS NOT NULL
                AND     A.NROEMPRESA = pnNroEmpresa
                AND     C.M000_NR_CHAVE_ACESSO = A.NFECHAVEACESSO
                AND     EXISTS( SELECT  1
                                FROM    RF_NOTAMESTRE R
                                WHERE   R.SEQNOTA = D.SEQEXPORTACAO)
                )
    LOOP
      PKG_MLF_IMPNFERECEBIMENTO.SP_EXCLUI_TMP(vNF.SEQNOTAFISCAL);
    END LOOP;

  EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR (-20200 , SQLERRM );
  END SP_TMPEXCLUSAO;  


  -- Verificação do pedido de compras informado para o item
  Function  fc_VerificaPedidoItemNFe(
             pnSeqNotaFiscal       IN        TMP_M000_NF.M000_ID_NF%TYPE,
             pnSeqItemNF           IN        TMP_M014_ITEM.M014_NR_ITEM%TYPE,
             pnSeqProduto          IN        MAP_PRODUTO.SEQPRODUTO%TYPE)
   return   number
   is
            vnNroPedido            number;
   begin
        
        begin
        
             SELECT A.NROPEDIDOSUPRIM
             INTO vnNroPedido
             FROM MRL_NFEITEMPEDIDO A
             WHERE A.SEQNOTAFISCAL = pnSeqNotaFiscal
             AND   A.SEQNFITEM = pnSeqItemNF
             AND   A.SEQPRODUTO = pnSeqProduto;
        
        exception 
            when no_data_found then
                 
            vnNroPedido := 0;      
        end;
        
        return vnNroPedido; 
        
   exception
     when  others then
           raise_application_error (-20200, sqlerrm );
   End        fc_VerificaPedidoItemNFe;
   
  -- Calcula Proporção da quantidade recebida no pedido pela quantidade no xml
  Function  fc_CalcPropQtde(
             pnSeqNotaFiscal       IN        TMP_M000_NF.M000_ID_NF%TYPE,             
             pnSeqProduto          IN        MAP_PRODUTO.SEQPRODUTO%TYPE,
             pnQtdPed              IN        MRL_NFEITEMPEDIDO.QUANTIDADE%TYPE,
             pnQtdXml              IN        TMP_M014_ITEM.M014_VL_QTDE_COM%TYPE,
             pnQtdEmbPed           IN        MRL_NFEITEMPEDIDO.QTDEMBALAGEM%TYPE DEFAULT 1,
             pnQtdEmbXml           IN        MAP_PRODCODIGO.QTDEMBALAGEM%TYPE DEFAULT 1,
             psPDConvEmbPedXml     IN        MAX_PARAMETRO.VALOR%TYPE DEFAULT 'N',
             psIndUtilPedSecund    IN        MRL_NFEITEMPEDIDO.INDUTILPEDSECUNDARIO%TYPE DEFAULT 'N'
             )
   return   number
   is
            vnQtdCalc            number;
            vnCount              integer;
            vnQtdTotal           number;
            vsIndUtilPedSecund     MRL_NFEITEMPEDIDO.INDUTILPEDSECUNDARIO%TYPE;
   begin
        vsIndUtilPedSecund := nvl(psIndUtilPedSecund, 'N');
                
        SELECT COUNT(1)
        INTO vnCount
        FROM MRL_NFEITEMPEDIDO A
        WHERE A.SEQNOTAFISCAL = pnSeqNotaFiscal
        AND   A.SEQPRODUTO = pnSeqProduto
        AND   A.INDUTILPEDSECUNDARIO = 'S'
        AND   vsIndUtilPedSecund = 'S';
        
        if vnCount > 1 then                      
           if psPDConvEmbPedXml = 'N' THEN
             vnQtdCalc := pnQtdPed / pnQtdXml;
           else
             vnQtdCalc := (pnQtdPed * pnQtdEmbPed) / (pnQtdXml * pnQtdEmbXml);
           end if;
        else
           vnQtdCalc := 1;
        end if;
        
        return vnQtdCalc;

   exception
     when  others then
           raise_application_error (-20200, sqlerrm );
   End        fc_CalcPropQtde; 
   
   PROCEDURE SP_EXPURGOINTEGRACAONDD( pdDtaInicial     in date,
                                      pdDtaFinal       in date,
                                      psOwner          in varchar2 default 'integracao'
                                    )               
   IS
     vdDataAux            date;
     vdDtaInicialAux      date;
     vdDtaFinalAux        date;     
   BEGIN     
     -- tratamento para não afetar os ultimos 90 dias.
     select case when pdDtaInicial between trunc(sysdate)-90 and trunc(sysdate) then 
                 trunc(sysdate)-91
            else 
                 pdDtaInicial
            end dtaInicialAux,                   
            case when ((pdDtaFinal between trunc(sysdate)-90 and trunc(sysdate)) or pdDtaFinal >= trunc(sysdate)) then                 
                 trunc(sysdate)-91
            else 
                 pdDtaFinal
            end dtaFinallAux
     into   vdDtaInicialAux, 
            vdDtaFinalAux
     from   dual ;
     --                               
     vdDataAux := vdDtaInicialAux;
     
     while vdDataAux <= vdDtaFinalAux
     Loop
      
       execute immediate 'delete '||psOwner||'.entryintegration a where a.dtainclusao = ''' || vdDataAux || '''';
       execute immediate 'delete '||psOwner||'.connectorintegration a where a.dtainclusao = ''' || vdDataAux || '''';
       execute immediate 'delete '||psOwner||'.tbdatabaseinput a where a.dtainclusao = ''' || vdDataAux || '''';
       execute immediate 'delete '||psOwner||'.tbdatabaseinputentry a where a.dtainclusao = ''' || vdDataAux || '''';
       execute immediate 'delete '||psOwner||'.tbdatabaseintegration a where a.dtainclusao = ''' || vdDataAux || '''';
       execute immediate 'delete '||psOwner||'.tbdatabaseintegrationentry a where a.dtainclusao = ''' || vdDataAux || '''';
       execute immediate 'delete '||psOwner||'.tbinputdocuments a where a.dtainclusao = ''' || vdDataAux || '''';
       execute immediate 'delete '||psOwner||'.tbintegration a where a.dtainclusao = ''' || vdDataAux || '''';
       
       vdDataAux := vdDataAux + 1;              
     end loop;              

   EXCEPTION
         WHEN OTHERS THEN
         RAISE_APPLICATION_ERROR (-20200 , SQLERRM );
   END SP_EXPURGOINTEGRACAONDD;
   
   PROCEDURE SP_CalcVlrOriginalTitulo(
              pnSeqAuxNotaFiscal      IN          MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL%TYPE,
              psRecebVencVlrLiq       IN          MAF_FORNECEDOR.INDRECEBVENCVLRLIQ%TYPE)

   IS
      vsPD_CalcVlrTituloXML             VARCHAR2(1);
      vsPD_LancDescContrato             VARCHAR2(1);
      vsSql                             VARCHAR2(4000);
      vsWhere                           VARCHAR2(1000);
      vnVlrDifTotalNFVenc               DECIMAL(28,15);
      vnPercRateio                      DECIMAL(28,15);
      vnVlrRateioVenc                   DECIMAL(28,15);
      vnVlrRateioItem                   DECIMAL(28,15);
      TYPE ItensCur                     IS REF CURSOR;
      vtItens                           ItensCur;
      vtMlfAuxNfItem                    MLF_AUXNFITEM%ROWTYPE;
      vnTotDescFinanc                   MLF_AUXNFITEM.VLRDESCFINCALC%TYPE;
      vnVlrTotalNF                      MLF_AUXNOTAFISCAL.VLRTOTALNF%TYPE;
      vnVlrTotalVenc                    MLF_AUXNFVENCIMENTO.VLRTOTAL%TYPE;
      vnTotVlrItem                      MLF_AUXNFITEM.VLRITEM%TYPE;
      vnUltimoSeq                       MLF_AUXNFITEM.SEQAUXNFITEM%TYPE;
      vnUltimoSeqVenc                   MLF_AUXNFVENCIMENTO.SEQAUXNFVENCTO%TYPE;
      vnTotDescSomaVenc                 MLF_AUXNFVENCIMENTO.VLRDESCFINANC%TYPE;
      vnTotDescSomaItem                 MLF_AUXNFITEM.VLRDESCFINCALC%TYPE;
      vnTotItensNF                      MLF_AUXNOTAFISCAL.VLRTOTALNF%TYPE;
   BEGIN
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NF', 0, 'CALC_VLR_TITULOXML', 'S', 'S', 
             'INDICA SE CALCULA O VALOR ORIGINAL QUANDO O FORNECEDOR ENVIAR A DUPLICATA COM VALOR LÍQUIDO.' || chr(13) || chr(10) ||
             'VALORES:' || chr(13) || chr(10) ||
             'S-SIM (PADRÃO)' || chr(13) || chr(10) ||
             'N-NÃO', vsPD_CalcVlrTituloXML);
             
      PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', 0, 'LANC_DESC_CONTRATO', 'S', 'F',
             'O VALOR DO DESCONTO DO CONTRATO SERÁ LANÇADO EM: ' ||
             'F - DESCONTO FINANCEIRO(VALOR PADRÃO)' ||
             '/C - DESCONTO DO CONTRATO/' ||
             'V - VERBA BONIFICAÇÃO(NESTA OPÇÃO TAMBÉM SERÁ LANÇADO OS VALORES REFERENTES A RETORNO DE CONTRATO E AS VERBAS DA TABELA DE CUSTO))', 
             vsPD_LancDescContrato);
      
      -- Atualiza Total NF para não dar divergência na comparação caso total vindo do xml diferente para o realmente calculado nos itens
      SELECT  sum(case when ( b.finalidadefamilia in ('B','U','A') and nvl(d.inddescbrinde, 'N') = 'S' ) OR ( nvl(I.INDCOMPTOTNFREMESSA,'S') = 'N' ) then
                   0
                  else NVL(I.VLRTOTALITEM, 0) + NVL(I.VLRFRETENANF, 0)
                  end)          
      INTO   vnVlrTotalNF
      FROM   MLF_AUXNFITEM     I,
             map_produto       a,
             map_famdivisao    b,
             max_empresa       c,
             mlf_auxnotafiscal d
      WHERE  i.seqproduto = a.seqproduto
      and    a.seqfamilia = b.seqfamilia
      and    i.seqauxnotafiscal = d.seqauxnotafiscal
      and    d.nroempresa = c.nroempresa
      and    c.nrodivisao = b.nrodivisao
      and    I.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal;
            
      IF vsPD_CalcVlrTituloXML = 'S' and psRecebVencVlrLiq = 'S' THEN
         SELECT SUM(A.VLRTOTAL)
         INTO   vnVlrTotalVenc
         FROM   MLF_AUXNFVENCIMENTO A 
         WHERE  A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal;
         
         -- Soma o desconto de contrato ao valor da parcela caso o total do vencimento seja menor que o valor total da NF
         IF vnVlrTotalVenc < vnVlrTotalNF THEN
            UPDATE MLF_AUXNFVENCIMENTO A
            SET    A.VLRTOTAL                  = A.VLRTOTAL + A.VLRDESCCONTRATOGC,
                   A.INDVLRORIGINALCALCSISTEMA = 'S',
                   A.VLRDESCFINANC             = nvl(A.VLRDESCFINANC, 0) +
                                                 CASE WHEN vsPD_LancDescContrato = 'F' THEN
                                                           A.VLRDESCCONTRATOGC
                                                      ELSE
                                                           0
                                                 END
           WHERE   A.SEQAUXNOTAFISCAL          = pnSeqAuxNotaFiscal
            AND    NVL(A.VLRDESCCONTRATOGC, 0) > 0;
         
            SELECT SUM(A.VLRTOTAL)
            INTO   vnVlrTotalVenc
            FROM   MLF_AUXNFVENCIMENTO A 
            WHERE  A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal;
            
            -- Se após a soma, o vencimento for menor que o total da NF, a diferença é rateada como desconto financeiro nos vencimentos
            IF vnVlrTotalVenc < vnVlrTotalNF THEN
               vnVlrDifTotalNFVenc := vnVlrTotalNF - vnVlrTotalVenc;
               vnTotDescSomaVenc   := 0;
               vnTotDescSomaItem   := 0;
               
               FOR vtVenc IN (
                   SELECT A.VLRTOTAL, A.SEQAUXNFVENCTO
                   FROM   MLF_AUXNFVENCIMENTO A
                  WHERE   A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal
                   ORDER BY A.SEQAUXNFVENCTO)
               LOOP
               
                   vnPercRateio     := vtVenc.VlrTotal / vnVlrTotalVenc;
                   vnVlrRateioVenc  := vnPercRateio * vnVlrDifTotalNFVenc;
                   IF (vnVlrRateioVenc + vnTotDescSomaVenc) > vnVlrDifTotalNFVenc then
                      vnVlrRateioVenc := vnVlrDifTotalNFVenc - vnTotDescSomaVenc;
                   END IF;

                   vnTotDescSomaVenc := vnTotDescSomaVenc + vnVlrRateioVenc;
               
                   UPDATE MLF_AUXNFVENCIMENTO A
                   SET    A.VLRTOTAL                   = A.VLRTOTAL + vnVlrRateioVenc,
                          A.VLRDESCFINANC              = A.VLRDESCFINANC + vnVlrRateioVenc,
                          A.VLRDESCFINANCAJUSTESISTEMA = NVL(A.VLRDESCFINANCAJUSTESISTEMA, 0) + vnVlrRateioVenc,
                          A.INDVLRORIGINALCALCSISTEMA  = 'S'
                  WHERE   A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal
                   AND    A.SEQAUXNFVENCTO   = vtVenc.SeqAuxNfVencto;
               
                   -- Guarda a última linha do vencimento
                   vnUltimoSeqVenc := vtVenc.SeqAuxNfVencto; 
               
               END LOOP;
               
               -- Verifica se existe algum item com desconto financeiro
               SELECT SUM(NVL(A.VLRDESCFINCALC, 0)), SUM(NVL(A.VLRITEM, 0))
               INTO   vnTotDescFinanc, vnTotVlrItem
               FROM   MLF_AUXNFITEM A
              WHERE   A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal;
              
               vsWhere := 'WHERE A.SEQAUXNOTAFISCAL = ' || pnSeqAuxNotaFiscal;
               
               -- Caso algum item possua desconto financeiro, o rateio do desconto será realizado somente nos itens que possuem desconto.
               -- Se não houver itens com desconto, o rateio será realizado entre todos os itens.
               IF vnTotDescFinanc > 0 THEN
                  SELECT SUM(NVL(A.VLRITEM, 0))
                  INTO   vnTotVlrItem
                  FROM   MLF_AUXNFITEM A
                 WHERE   A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal
                  AND    A.VLRDESCFINCALC   > 0;
                  
                  vsWhere := vsWhere || 'AND A.VLRDESCFINCALC > 0';
               END IF;

               vsSql := 'SELECT A.VLRITEM, A.SEQAUXNFITEM
                         FROM   MLF_AUXNFITEM A
                         ' ||       vsWhere     ||
                         'ORDER BY A.SEQAUXNFITEM';
                         
               OPEN vtItens
               FOR  vsSql;
               LOOP
               FETCH vtItens INTO
                     vtMlfAuxNfItem.Vlritem, 
                     vtMlfAuxNfItem.SeqAuxNfItem;
               EXIT WHEN vtItens%NOTFOUND; 
                                
                    vnPercRateio     := vtMlfAuxNfItem.VlrItem / vnTotVlrItem;
                    vnVlrRateioItem  := vnPercRateio * vnVlrDifTotalNFVenc;
                    IF (vnVlrRateioItem + vnTotDescSomaItem) > vnVlrDifTotalNFVenc then
                       vnVlrRateioItem := vnVlrDifTotalNFVenc - vnTotDescSomaItem;
                    END IF;
                    
                    vnTotDescSomaItem := vnTotDescSomaItem + vnVlrRateioItem;
                   
                    UPDATE MLF_AUXNFITEM A
                    SET    A.VLRDESCFINCALC   = CASE WHEN A.VLRDESCFINCALC = vnVlrRateioItem THEN
                                                  A.VLRDESCFINCALC
                                                ELSE
                                                  A.VLRDESCFINCALC + vnVlrRateioItem
                                                END
                   WHERE   A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal
                    AND    A.SEQAUXNFITEM     = vtMlfAuxNfItem.SeqAuxNfItem;
                    
                    -- Guarda o último item
                    vnUltimoSeq := vtMlfAuxNfItem.SeqAuxNfItem;
                   
                 END LOOP;
               CLOSE vtItens;
               -- Verifica se ficou algum resto do rateio e soma no ultimo vencimento.
               IF vnTotDescSomaVenc != 0 THEN
                  vnTotDescSomaVenc := vnVlrDifTotalNFVenc - vnTotDescSomaVenc;
               END IF;                  
               -- Verifica se ficou algum resto do rateio e soma no ultimo ítem.
               IF vnTotDescSomaItem != 0 THEN
                  vnTotDescSomaItem := vnVlrDifTotalNFVenc - vnTotDescSomaItem;        
               END IF;
               
               -- Soma no último vencimento se ficou a diferença
               IF vnTotDescSomaVenc > 0 THEN           
                  UPDATE MLF_AUXNFVENCIMENTO A
                  SET    A.VLRDESCFINANC              = NVL(A.VLRDESCFINANC, 0) + vnTotDescSomaVenc,
                         A.VLRDESCFINANCAJUSTESISTEMA = NVL(A.VLRDESCFINANCAJUSTESISTEMA, 0) + vnTotDescSomaVenc
                 WHERE   A.SEQAUXNOTAFISCAL           = pnSeqAuxNotaFiscal
                  AND    A.SEQAUXNFVENCTO             = vnUltimoSeqVenc;
               END IF;
               -- Soma no último item se ficou a diferença
               IF vnTotDescSomaItem > 0 THEN
                  UPDATE MLF_AUXNFITEM A
                  SET    A.VLRDESCFINCALC   = NVL(A.VLRDESCFINCALC, 0) + vnTotDescSomaItem
                 WHERE   A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal
                  AND    A.SEQAUXNFITEM     = vnUltimoSeq;
               END IF;
            END IF;
            -- Se após a soma, o vencimento for maior que o total da NF, a diferença é subtraída do último vencimento
            IF vnVlrTotalVenc > vnVlrTotalNF THEN
               vnVlrDifTotalNFVenc := vnVlrTotalVenc - vnVlrTotalNF;
               
               SELECT MAX(A.SEQAUXNFVENCTO)
               INTO   vnUltimoSeqVenc
               FROM   MLF_AUXNFVENCIMENTO A
               WHERE  A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal;
               
               UPDATE MLF_AUXNFVENCIMENTO A
               SET    A.VLRTOTAL = A.VLRTOTAL - vnVlrDifTotalNFVenc
               WHERE  A.SEQAUXNOTAFISCAL = pnSeqAuxNotaFiscal
               AND    A.SEQAUXNFVENCTO   = vnUltimoSeqVenc;
            END IF;
         END IF;
      END IF;
  EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR (-20200 , SQLERRM );                                
  END SP_CalcVlrOriginalTitulo;     
                
  --verifica se existem fornecedores relacionados (por CNPJ ou rede)          
   FUNCTION fc_FornecRelac(pnSeqFornecedor in maf_fornecedor.seqfornecedor%Type,
                           psPD_PmtVisualPedFornRel in max_parametro.valor%type)
    return varchar2
   is      
      vsCodFornecedores                varchar2(2000);
      vnNroCgcCpf                      ge_pessoa.nrocgccpf%type;  
   BEGIN          
      
      select a.nrocgccpf
      into   vnNroCgcCpf
      from   ge_pessoa a
      where  a.seqpessoa = pnSeqFornecedor;
      
      if vnNroCgcCpf is null then
        vsCodFornecedores := pnSeqFornecedor;
      else
          select Substr(C5_Complexin.C5instring(cast(collect(To_Char(a.seqfornecedor)) as
                                                      C5instrtable)), 0, 2000)
            into vsCodFornecedores
            from (select forn.Seqfornecedor
                  from ge_pessoa pes, Maf_Fornecedor forn
                  where pes.seqpessoa = forn.seqfornecedor
                  and ((  pes.fisicajuridica = 'J'
                          and pes.nrocgccpf between case when psPD_PmtVisualPedFornRel = 'N' then
                                                       TO_NUMBER(substr(vnNroCgcCpf, 1, length(vnNroCgcCpf) - 4) || '0000')
                                                    else
                                                       vnNroCgcCpf
                                                    end
                                            and     case when psPD_PmtVisualPedFornRel = 'N' then
                                                       TO_NUMBER(substr(vnNroCgcCpf, 1, length(vnNroCgcCpf) - 4) || '9999')
                                                    else
                                                       vnNroCgcCpf
                                                    end
                      )
                  OR
                  forn.seqfornecedor = pnSeqFornecedor)
                  UNION
                  select pes.Seqpessoa Seqfornecedor
                  from   Maf_Fornecedor forn, Ge_Pessoarelacao pes
                  where  pes.Seqprincipal = forn.Seqfornecedor
                  and    forn.Seqfornecedor = pnSeqFornecedor
                  UNION
                  select pes.Seqprincipal Seqfornecedor
                  from   Maf_Fornecedor forn, Ge_Pessoarelacao pes
                  where  pes.Seqpessoa = forn.Seqfornecedor
                  and    forn.Seqfornecedor = pnSeqFornecedor
                  UNION
                  select pes.Seqpessoa Seqfornecedor
                  from   Ge_Redepessoa pes, Maf_Fornecedor forn
                  where  pes.Seqpessoa = forn.Seqfornecedor
                  and    pes.Seqrede in
                         (select distinct Ge_Redepessoa.Seqrede
                          from   Ge_Redepessoa
                          where  Ge_Redepessoa.Seqpessoa = pnSeqFornecedor)
                  ) a;  
              
     end if;          
     return vsCodFornecedores;           
  END fc_FornecRelac;   
  
  PROCEDURE SP_AJUSTEARREDITENS(
              pnSeqAuxNotaFiscal    IN        MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL%TYPE,
              pnSeqNotaFiscal       IN        TMP_M000_NF.M000_ID_NF%TYPE,
              pnNroEmpresa          IN        MAX_EMPRESA.NROEMPRESA%TYPE)
   IS                 
       VnVlrDescItemNF              number;
       vnSeqUltimoItem              integer;          
  BEGIN
     
     -- Ajusta divergências de arredondamento após inserção do item da nota em comparação com xml --         
     For t in (
         SELECT *         
         FROM MRLX_NFEIMPORTACAOITEM A
            WHERE A.SEQNOTAFISCAL = pnSeqNotaFiscal
            AND   A.NROEMPRESA    = pnNroEmpresa
            AND   EXISTS (SELECT 1 FROM MRL_NFEITEMPEDIDO I
                          WHERE A.SEQNOTAFISCAL = I.SEQNOTAFISCAL
                          AND   A.SEQNFITEM     = I.SEQNFITEM
                          AND   I.SEQPRODUTO    > 0 
                          AND   I.INDUTILPEDSECUNDARIO = 'S'
                         ) 
               )
     Loop
       
         -- Busca o item correspondente na nota  --  
         Select sum(b.vlrdescitem), max(b.seqitemnf)
         into   VnVlrDescItemNF, vnSeqUltimoItem
         From Mlf_Auxnfitem b
         Where b.seqauxnotafiscal = pnSeqAuxNotaFiscal   
         And   b.seqproduto       = t.seqproduto
         And   b.seqitemnfxml     = t.seqitemnfxml;
         
         -- atualiza o valor do desconto no último ítem caso divergência no arredondamento --
         if abs(VnVlrDescItemNF - t.vlrdesconto) = 0.01 then
           
            update mlf_auxnfitem b
            set b.vlrdescitem = b.vlrdescitem - (VnVlrDescItemNF - t.vlrdesconto)
            where b.seqauxnotafiscal = pnSeqAuxNotaFiscal
            and   b.seqitemnf = vnSeqUltimoItem;
         
         end if;
     
     End Loop;
    
  EXCEPTION
        WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR (-20200 , SQLERRM );
  END SP_AJUSTEARREDITENS;
  
end PKG_MLF_IMPNFERECEBIMENTO;
/
