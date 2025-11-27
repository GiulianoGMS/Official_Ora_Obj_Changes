create or replace package PKG_MAD_DI is
  -- Author  : BIDIO
  -- Created : 01/10/2011 13:49:27
  -- Purpose : Objetos utilizados para o processo de geração de notas através de Declaração de Importação
  -- Variaveis Globais
  tpImposto                     pkg_carregaimposto.tImposto;
  tpSaidaImposto                pkg_carregaimposto.tSaidaImposto;
  -- Faz o tratamento para cálculo das tributações referentes a Declaração de Importação
   PROCEDURE SP_CALCTRIBADICAOITEM(
                       pnSeqProduto    in map_produto.seqproduto%type,
                       pnNroEmpresa    in max_empresa.nroempresa%type,
                       pnVucv          in mad_adicaoitem.vlrvucv%type,
                       pnQtde          in mad_adicaoitem.quantidade%type,
                       pnSeqFornecedor in maf_fornecedor.seqfornecedor%type,
                       pnVlrPautaIPI   in mad_adicaoitem.vlripipauta%type,
                       pnVlrAFRMM      in mad_adicaoitem.vlrafrmm%type,
                       pnVlrFrete      in mad_adicaoitem.vlrfrete%type,
                       pnVlrCapatazia  in mad_adicaoitem.vlrcapatazia%type,
                       pnVlrSeguro     in mad_adicaoitem.vlrseguro%type,
                       pnVlrDespAD     in mad_adicaoitem.vlrdespad%type,
                       psNumeroDI      in mad_adicaoitem.numerodi%type,
                       pnNroAdicao     in mad_adicaoitem.nroadicao%type,
                       psIndUtilFreteBaseCalc in mad_di.indutilfretebasecalc%type,
                       psIndUtilSeguroBaseCalc in mad_di.indutilsegurobasecalc%type,
                       psIndUtilCapataziaBaseCalc in mad_di.indutilcapataziabasecalc%type,
                       psUFPortoDestino in ge_cidade.uf%type,
                       psIndRatPauta    in String,
                       psIncideBaseTribIImpFrete     in mad_di.incidebasetribiimpfrete%type := 'S',
                       psIncideBaseTribIpiFrete      in mad_di.incidebasetribipifrete%type := 'S',
                       psIncideBaseTribPisFrete      in mad_di.incidebasetribpisfrete%type := 'S',
                       psIncideBaseTribCofinsFrete   in mad_di.incidebasetribcofinsfrete%type := 'S',
                       psIncideBaseTribIcmsFrete     in mad_di.incidebasetribicmsfrete%type := 'S',
                       psIncideBaseTribIImpSeg       in mad_di.incidebasetribiimpseg%type := 'S',
                       psIncideBaseTribIpiSeg        in mad_di.incidebasetribipiseg%type := 'S',
                       psIncideBaseTribPisSeg        in mad_di.incidebasetribpisseg%type := 'S',
                       psIncideBaseTribCofinsSeg     in mad_di.incidebasetribcofinsseg%type := 'S',
                       psIncideBaseTribIcmsSeg       in mad_di.incidebasetribicmsseg%type := 'S',
                       psIncideBaseTribIImpCtz       in mad_di.incidebasetribiimpctz%type := 'S',
                       psIncideBaseTribIpiCtz        in mad_di.incidebasetribipictz%type := 'S',
                       psIncideBaseTribPisCtz        in mad_di.incidebasetribpisctz%type := 'S',
                       psIncideBaseTribCofinsCtz     in mad_di.incidebasetribcofinsctz%type := 'S',
                       psIncideBaseTribIcmsCtz       in mad_di.incidebasetribicmsctz%type := 'S'
                       );
   -- ##### Geração da Nota Fiscal Entrada Importação ('nota mãe') #########
  PROCEDURE SP_GERA_NFMAE(
              pnNumeroDI           IN        MAD_DI.NUMERODI%TYPE,
              pnCodGeralOper       IN        MAX_CODGERALOPER.CODGERALOPER%TYPE,
              pnNroEmpresa         IN        MAX_EMPRESA.NROEMPRESA%TYPE,
              pdDtaHorLancto       IN        MLF_AUXNOTAFISCAL.DTAHORLANCTO%TYPE,
              psUsuLancto          IN        MLF_AUXNOTAFISCAL.USULANCTO%TYPE,
              pnImpOK              IN OUT    INTEGER);
  -- Geração das Inconsistências da DI
  PROCEDURE SP_CONSISTENFIMPORT(
              pnNumeroDI           IN        MRL_NFINCONSISTENCIAIMPORT.NUMERODI%TYPE);
  -- Grava as inconsistências
  PROCEDURE SP_GRAVAINCONSISTIMPORT(
              pnNumeroDI           IN        MRL_NFINCONSISTENCIAIMPORT.NUMERODI%TYPE,
              pnNroAdicao          IN        MRL_NFINCONSISTENCIAIMPORT.NROADICAO%TYPE,
              pnSeqProduto         IN        MRL_NFINCONSISTENCIAIMPORT.SEQPRODUTO%TYPE,
              psTipoInconsist      IN        MRL_NFINCONSISTENCIAIMPORT.TIPOINCONSIST%TYPE,
              pnCodInconsist       IN        MRL_NFINCONSISTENCIAIMPORT.CODINCONSIST%TYPE,
              psBloqueioLiberacao  IN        MRL_NFINCONSISTENCIAIMPORT.BLOQUEIOLIBERACAO%TYPE,
              psDescricao          IN        MRL_NFINCONSISTENCIAIMPORT.DESCRICAO%TYPE);
  -- Calculo de Rateio dos Valores de Frete, Seguro, Despesa e Siscomex nos itens
  PROCEDURE  SP_RATEIOADICAOITEM(
               pnNumeroDI        IN          MAD_DI.NUMERODI%TYPE);
  -- Faz o tratamento para cálculo das tributações referentes a adição da DI
  PROCEDURE SP_CALCTRIBADICAO(
                     pnVmcv       in mad_adicao.vlrvmcv%type,
                     pnVlrPautaIPI   in mad_adicao.vlripipauta%type,
                     pnVlrAFRMM      in mad_adicao.vlrafrmm%TYPE,
                     pnVlrFrete      in mad_adicao.vlrfrete%type,
                     pnVlrSeguro     in mad_adicao.vlrseguro%type,
                     pnVlrDespAD     in mad_adicao.vlrdespad%type,
                     pnAliqII        in mad_adicao.aliqii%type,
                     pnPerRedII      in mad_adicao.perredbaseii%type,
                     pnAliqPis       in mad_adicao.aliqpis%type,
                     pnPerRedPis     in mad_adicao.perredpis%type,
                     pnAliqCofins    in mad_adicao.aliqcofins%type,
                     pnPerRedCofins  in mad_adicao.perredcofins%type,
                     pnAliqIpi       in mad_adicao.aliqipi%type,
                     pnPerRedIpi     in mad_adicao.perredipi%type,
                     pnAliqIcms      in mad_adicao.aliqicms%type,
                     pnPerRedIcms    in mad_adicao.perredicms%type,
                     pnAliqIcmsST    in mad_adicao.aliqicmsst%type,
                     pnPerRedIcmsST  in mad_adicao.perredicmsst%type,
                     pnPerAcrST      in mad_adicao.peracrescst%type,
                     pnPerRedCargaTr in mad_adicao.perredcargatribdi%type,
                     pnAliqFCPST     in mad_adicao.peraliqfcpst%type,
                     pnVlrII         in out mad_adicao.vlrii%type,
                     pnVlrPis        in out mad_adicao.vlrpis%type,
                     pnVlrCofins     in out mad_adicao.vlrcofins%type,
                     pnVlrIpi        in out mad_adicao.vlripi%type,
                     pnVlrIcms       in out mad_adicao.vlricmsst%type,
                     pnVlrIcmsST     in out mad_adicao.vlricmsst%TYPE,
                     pnVlrFCPST      in out mad_adicao.vlrfcpst%type,
                     psNumeroDI      in mad_adicaoitem.numerodi%type,
                     pnNroAdicao     in mad_adicaoitem.nroadicao%type,
                     pnNroProcImport in mad_di.nroprocimportacao%type default null
              );
  -- Processos de Importação - Empilhamento
  type t_seqpedimport is table of mad_pipedidoimport.seqpedidoimport%type
        index by binary_integer;
  vtid_IndSeqImp  t_seqpedimport;
  vn_ind_pedimp   binary_integer := 0;
  -- Processo de rateio automático dos lançamentos
  Procedure SP_RATEIOAUTOMADICAO(
            pnNumeroDI               in mad_di.numerodi%type,
            pnNroEmpresa             in mad_di.nroempresa%type,
            pnNroProcImport          in mad_piprocimportacao.nroprocimportacao%type
            );
  FUNCTION Fcalculadespcompdi(Psnumerodi IN Mad_Di.Numerodi%TYPE,
                              Pnnroadicao IN Mad_Adicao.Nroadicao%TYPE DEFAULT NULL,
                              Pnseqproduto IN Mad_Adicaoitem.Seqproduto%TYPE DEFAULT NULL,
                              Pnincdespnf IN Mad_Despesacompldi.Incdespnota%TYPE DEFAULT 'T'
                              -- D - Desp. Tributada -- F - Frete -- T - Todas
                              ) RETURN NUMBER;
  --
  PROCEDURE SP_GRAVAPREVADICAO(
            pnNroProcImportacao IN MAD_PIPEDIDOIMPORT.NROPROCIMPORTACAO%TYPE
            );
  PROCEDURE SP_GRAVAPREVADICAOITEM(
          pnNroProcImportacao IN MAD_PIPEDIDOIMPORT.NROPROCIMPORTACAO%TYPE
          );
  PROCEDURE SP_INSEREADICAO(
            tSP_MAD_PREVADICAO IN MAD_PREVADICAO%ROWTYPE
            );
  PROCEDURE SP_INSEREPREVADICAOITEM(
            tSP_MAD_PREVADICAOITEM IN MAD_PREVADICAOITEM%ROWTYPE
            );
  PROCEDURE SP_PROCEXCLUIADICAO(
            tSP_MAD_PREVADICAO IN MAD_PREVADICAO%ROWTYPE
            );
  PROCEDURE SP_EXCLUIADICAOITEM(
            tSP_MAD_PREVADICAOITEM IN MAD_PREVADICAOITEM%ROWTYPE
            );
  PROCEDURE SP_EXCLUIADICAO(
            tSP_MAD_PREVADICAO IN MAD_PREVADICAO%ROWTYPE
            );
  PROCEDURE SP_DESCARTARPREV(
            pnNroProcImportacao MAD_PREVADICAO.NROPROCIMPORTACAO%TYPE
            );
  vnNroProcImportacao mad_pilanctopagtodesp.nroprocimportacao%type;
  vnSeqLanctoPagto    mad_pilanctopagtodesp.seqlanctopagto%type;
  vsOperacao          varchar2(1);
end PKG_MAD_DI;
/
create or replace package body PKG_MAD_DI is
-- Faz o tratamento para cálculo das tributações referentes a Declaração de Importação
PROCEDURE SP_CALCTRIBADICAOITEM(
                   pnSeqProduto                  in map_produto.seqproduto%type,
                   pnNroEmpresa                  in max_empresa.nroempresa%type,
                   pnVucv                        in mad_adicaoitem.vlrvucv%type,
                   pnQtde                        in mad_adicaoitem.quantidade%type,
                   pnSeqFornecedor               in maf_fornecedor.seqfornecedor%type,
                   pnVlrPautaIPI                 in mad_adicaoitem.vlripipauta%type,
                   pnVlrAFRMM                    in mad_adicaoitem.vlrafrmm%type,
                   pnVlrFrete                    in mad_adicaoitem.vlrfrete%type,
                   pnVlrCapatazia                in mad_adicaoitem.vlrcapatazia%type,
                   pnVlrSeguro                   in mad_adicaoitem.vlrseguro%type,
                   pnVlrDespAD                   in mad_adicaoitem.vlrdespad%type,
                   psNumeroDI                    in mad_adicaoitem.numerodi%type,
                   pnNroAdicao                   in mad_adicaoitem.nroadicao%type,
                   psIndUtilFreteBaseCalc        in mad_di.indutilfretebasecalc%type,
                   psIndUtilSeguroBaseCalc       in mad_di.indutilsegurobasecalc%type,
                   psIndUtilCapataziaBaseCalc    in mad_di.indutilcapataziabasecalc%type,
                   psUFPortoDestino              in ge_cidade.uf%type,
                   psIndRatPauta                 in String,
                   psIncideBaseTribIImpFrete     in mad_di.incidebasetribiimpfrete%type default 'S',
                   psIncideBaseTribIpiFrete      in mad_di.incidebasetribipifrete%type default 'S',
                   psIncideBaseTribPisFrete      in mad_di.incidebasetribpisfrete%type default 'S',
                   psIncideBaseTribCofinsFrete   in mad_di.incidebasetribcofinsfrete%type default 'S',
                   psIncideBaseTribIcmsFrete     in mad_di.incidebasetribicmsfrete%type default 'S',
                   psIncideBaseTribIImpSeg       in mad_di.incidebasetribiimpseg%type default 'S',
                   psIncideBaseTribIpiSeg        in mad_di.incidebasetribipiseg%type default 'S',
                   psIncideBaseTribPisSeg        in mad_di.incidebasetribpisseg%type default 'S',
                   psIncideBaseTribCofinsSeg     in mad_di.incidebasetribcofinsseg%type default 'S',
                   psIncideBaseTribIcmsSeg       in mad_di.incidebasetribicmsseg%type default 'S',
                   psIncideBaseTribIImpCtz       in mad_di.incidebasetribiimpctz%type default 'S',
                   psIncideBaseTribIpiCtz        in mad_di.incidebasetribipictz%type default 'S',
                   psIncideBaseTribPisCtz        in mad_di.incidebasetribpisctz%type default 'S',
                   psIncideBaseTribCofinsCtz     in mad_di.incidebasetribcofinsctz%type default 'S',
                   psIncideBaseTribIcmsCtz       in mad_di.incidebasetribicmsctz%type default 'S'
                   )
is
  vnSeqFamiliaItem                            number;
  vnNroRegTribFornec                          number;
  vnNroTributacao                             number;
  vnNroDivisaoEmp                             Max_Empresa.Nrodivisao%type;
  vnSeqFornecItem                             number;
  vnPerAliquotaStCargaLiq                     number;
  vnPerAliqIcms                               number;
  vnPerAliqST                                 number;
  vnPerPis                                    number;
  vnPerCofins                                 number;
  vnPerAcrescST                               number;
  vnSeqPautaDivisao                           number;
  vnPerTributado                              number;
  vnPerIsento                                 number;
  vnPerOutro                                  number;
  vnPerTributadoST                            number;
  vnPerAliqIcmsCalc                           number;
  vnIndceFormBaseIPI                          number;
  vsUfEmpresa                                 varchar2(2);
  vsUfFornec                                  varchar2(2);
  vsTipTributacao                             varchar2(2);
  vsTipForItem                                varchar2(1);
  vsMicroEmpresa                              varchar2(1);
  vsTipCalcSelo                               varchar2(2);
  vsTipCalcSeloFornDiv                        varchar2(2);
  vsIndSomaIPIBaseICMS                        varchar2(2);
  vsIndPautaICMS                              varchar2(2);
  vsIndApliRedTribCalcST                      varchar2(2);
  vsIndApliRedTribCalcStSemDesp               varchar2(2);
  vsTipRedcICMSCalcST                         varchar2(2);
  vsIndIsentoPIS                              varchar2(2);
  vsTipoCalculoIPI                            varchar2(2);
  vsTipUsoCGO                                 varchar2(2);
  vsTipDocFiscal                              varchar2(2);
  vsTipCalcICMS                               varchar2(2);
  vsAceitaPautaST                             varchar2(2);
  vsItemIndPautaST                            varchar2(2);
  vsLixo                                      varchar2(20);
  vnLixo                                      number;
  vnQuantidadeEstq                            number;
  vnCustoNF                                   number;
  vnIcmsST                                    number;
  vnCredIcms                                  number;
  vnBaseIcms                                  number;
  vnBaseST                                    number;
  vnDescItem                                  number;
  vnAbatimento                                number;
  vnDespTribItem                              number;
  vnDespNTribItem                             number;
  vnBasCalcIpi                                number;
  vnOutrIpi                                   number;
  vnIsentoIpi                                 number;
  vnVlrIsento                                 number;
  vnVlrOutro                                  number;
  vnVlrDescSuf                                number;
  vsAplRedPisCofBasIcm                        varchar2(2);
  vnPerRedPisCofBasIcm                        number;
  vsIndConcDescBasIcm                         varchar2(2);
  vnAliqIpiTabForn                            number;
  vnPerAliqVPE                                number;
  vnPerCredVPE                                number;
  vsUtilRegVPEST                              varchar2(2);
  vnVlrVPE                                    number;
  vnVlrIcmsVPE                                number;
  vsSomaDespFreteBIST                         varchar2(2);
  vsIndCondDescBaseST                         varchar2(2);
  vsTipCalcIpi                                varchar2(2);
  vsIndPautaIpi                               varchar2(2);
  vsIndDescTribut                             varchar2(2);
  vsIndPautaST                                varchar2(2);
  vsIndApropriaST                             varchar2(2);
  vdDtaEmissao                                date;
  vnPerIsentoST                               number;
  vnPerOutroST                                number;
  vsCompoemCestaBasica                        varchar2(2);
  vnPerIcmsAntecipado                         number;
  vnPerBaseFecp                               number;
  vnPerAliqFecp                               number;
  vsTipoCalcFecp                              varchar2(2);
  vnPerAliqICMSDif                            number;
  vnSeqPautaICMS                              number;
  vsIndSomaIPIBaseSTTrib                      varchar2(2);
  vsIndSuframadoRec                           varchar2(2);
  vsCalcSTDescSuframaTrib                     varchar2(2);
  vnVlrDescSuframaIcmsRec                     number;
  vnVlrDescSuframaPisRec                      number;
  vnVlrDescSuframaCofinsRec                   number;
  vsSituacaoNFPisRec                          varchar2(2);
  vsSituacaoNFCofinsRec                       varchar2(2);
  vsCalcIcmsDescSuframaRec                    varchar2(2);
  vnPerPmcTrib                                number;
  vnPrMaxConsumidor                           number;
  vnTipoCalcIcmsFisciRet                      number;
  vsIndCalcIcmsVPE                            varchar2(2);
  vsSituacaoNFIpiTrib                         varchar2(2);
  vnSeqFamilia                                number;
  vnVlrIPI                                    number;
  vnCount                                     number;
  vsIndCalcDescSuframaPed                     varchar2(2);
  vsCalcDescSuframaPisCofins                  varchar2(2);
  vnLixoCalc                                  number;
  vnPerAcresICMSRet                           number;
  vnPerAliqICMSRet                            number;
  vnVlrICMSRet                                number;
  vnBaseICMSRet                               number;
  vnBaseIcmsCalc                              number;
  vnVlrTotIsentoCalc                          number;
  vnVlrTotOutraCalc                           number;
  vnVlrTotIsentoSt                            number;
  vnVlrTotOutroSt                             number;
  vnAliqIcmsSimples                           number;
  vnBasCalcFecp                               number;
  vnVlrFecp                                   number;
  vnAliqIpi                                   number;
  vnPerRedIpi                                 number;
  vnAliqII                                    number;
  vnPerRedII                                  number;
  vnVlrII                                     number;
  vnPerRedBasePis                             number;
  vnPerRedBaseCofins                          number;
  vnVlrAduaneiro                              number;
  vnVlrAduaneiroIImp                          number;
  vnVlrAduaneiroIpi                           number;
  vnVlrAduaneiroPis                           number;
  vnVlrAduaneiroCofins                        number;
  vnVlrAduaneiroIcms                          number;
  vnBaseCalculoII                             number;
  vnBaseCalculoPis                            number;
  vnBaseCalculoCofins                         number;
  vnVlrPis                                    number;
  vnVlrCofins                                 number;
  vnPerRedBasePisCofEmp                       number;
  vnPerAliqIcmsAdicao                         number;
  vnPerAliqSTAdicao                           number;
  vnPerAliqFCPSTAdicao                        number;
  vnNroRegTribCGO                             number;
  vnCgoImp                                    number;
  vnSeqFornecedor                             maf_fornecdivisao.seqfornecedor%type;
  vsIndICMSDifFam                             map_famdivisao.indcalcdifaliq%type;
  vsIndICMSDifCGO                             max_codgeraloper.indcalcdifaliq%type;
  vnPercAliqIcmsDifer                         map_tributacaouf.peraliqicmsdifer%type;
  vnBaseIcmsDifer                             mrlx_calctribitem.basicmsdif%type;
  vnVlrIcmsDifer                              mrlx_calctribitem.vlricmsdif%type;
  vnPercAliqIcmsAtac                          map_tributacaouf.percregimeatac%type;
  vnBaseIcmsAtac                              mrlx_calctribitem.basicmsatac%type;
  vnVlrIcmsAtac                               mrlx_calctribitem.vlricmsatac%type;
  vsSituacaoNFIpiTribFam                      map_familia.situacaonfipi%type;--RC 77547
  vsIndSomaIPIBaseICMSDifer                   map_tributacaouf.indsomaipibaseicmsdifer%type; -- RC 115542
  vnPerMajCofinsImport                        number;
  vnPerMajPisImport                           number;
  vsPD_BaseCalcPisCofins                      max_parametro.valor%type;
  vsPD_CalcBaseIcmsAfrmm                      max_parametro.valor%type;
  vsIndUtilRedCargaTribDI                     max_paramgeral.indutilredcargatribdi%type;
  vnPerRedCargaTr                             map_tributacaouf.perredcargatribdi%type;
  vsIndICMSSTAprovtoCredICMS                  MAF_FORNECDIVISAO.INDICMSSTAPROVTOCREDICMS%TYPE;   -- RP 147681
  vnVlrIcmsSTInt                              number;
  vsIndUtilIcmsCalcRedFcpSt                   MAP_TRIBUTACAOUF.INDUTILICMSCALCREDFCPST%TYPE;
  vnDespComplII                               number; --RC201470
  vnDespComplIPI                              number; --RC201470
  vnDespComplPIS                              number; --RC201470
  vnDespComplCOF                              number; --RC201470
  vnDespComplICMS                             number; --RC201470
  vnBaseFcpSt                                 NUMBER(15,2);
  vnPerAliqFcpSt                              NUMBER(4,2);
  vnVlrFcpSt                                  NUMBER(15,2);
  vnBaseFcpIcms                               NUMBER(15,2);
  vnPerAliqFcpIcms                            NUMBER(4,2);
  vnVlrFcpIcms                                NUMBER(15,2);
  vnVlrMercadoriaLocalDesemb                  number;
  vnPerPisMajSoma                             number;
  vnPerCofinsMajSoma                          number;
begin
  SP_BUSCAPARAMDINAMICO( 'DECLARACAO_IMPORT', 0, 'BASE_CALC_PIS_COFINS', 'S', 'A', 'INFORME COMO SERÁ A BASE DE CÁLCULO DOS IMPOSTOS PIS E COFINS? VALORES:(A-VALOR ADUANEIRO(PADRÃO)/B-INCLUI NA BASE DE CÁLCULO AS ALÍQUOTAS DO ICMS, DO IMPOSTO DE IMPORTAÇÃO, DO IPI E AS ALÍQUOTAS DAS PRÓPRIAS CONTRIBUIÇÕES)', vsPD_BaseCalcPisCofins);
  SP_BUSCAPARAMDINAMICO( 'DECLARACAO_IMPORT', 0, 'CALC_BASE_ICMS_AFRMM', 'S', 'N',
         'CONSIDERA O VALOR AFRMM NA BASE DE CÁLCULO DO ICMS QUANDO A VIA DE TRANSPORTE INTERNACIONAL FOR "MARÍTIMA"? VALORES:(S-SIM/N-NÃO(PADRÃO))',
         vsPD_CalcBaseIcmsAfrmm );
  Select nvl(indutilredcargatribdi,'N')
  into   vsIndUtilRedCargaTribDI
  From   Max_Paramgeral;
  select max(seqfamilia)
  into   vnSeqFamilia
  from   map_produto
  where  seqproduto = pnSeqProduto;
  -- Busca Tributação do Item
  begin
      Select nvl(c.nroregtributacao, nvl(d.nroregtributacao,0)),
             d.uf ufempresa, e.uf uffornecedor,
             decode (i.tipfornecedorfam, 'I', 'EI', 'D', 'ED', 'S', 'ED', null,
             (decode(f.microempresa,'S','EM',Decode(f.tipfornecedor,'I','EI','ED')))) tiptributacao,
             g.nrotributacao, a.seqfamilia, d.nrodivisao, e.seqpessoa,
             decode (i.tipfornecedorfam, 'I', 'I', 'D', 'D', 'S', 'M', null,
             (decode(f.microempresa,'S','M',Decode(f.tipfornecedor,'I','I','D')))) tipfornecedor,
             nvl(g.Seqpauta,0), f.microempresa, c.tipcalcicmsselo, g.seqpautaicms, c.indcalcdescsuframa,
             NVL(A.CALCDESCSUFRAMAPISCOFINS,'S'), nvl(h.aliquotaipi,0), nvl(h.perredbaseipient,0), nvl(h.perimpostoimport,0), nvl(h.perredimpostoimport,0),
             d.perpis, d.percofins, h.perbasepis, h.perbasecofins, nvl(d.perredbasepiscofins,0), d.cgopadraoimportacao,
             c.seqfornecedor, nvl(g.indcalcdifaliq,'N'),
             h.situacaonfipi,
             NVL(C.INDICMSSTAPROVTOCREDICMS, 'N') /* RP 147681 */
      Into	 vnNroRegTribFornec,
             vsUfEmpresa, vsUfFornec,
      	     vsTipTributacao,
             vnNroTributacao,vnSeqFamiliaItem, vnNroDivisaoEmp, vnSeqFornecItem,
             vsTipForItem,
      	     vnSeqPautaDivisao, vsMicroEmpresa, vsTipCalcSeloFornDiv, vnSeqPautaICMS, vsIndCalcDescSuframaPed,
             vsCalcDescSuframaPisCofins, vnAliqIpi, vnPerRedIpi, vnAliqII, vnPerRedII,
             vnPerPis, vnPerCofins, vnPerRedBasePis, vnPerRedBaseCofins, vnPerRedBasePisCofEmp, vnCgoImp,
             vnSeqFornecedor, vsIndICMSDifFam,
             vsSituacaoNFIpiTribFam,
             vsIndICMSSTAprovtoCredICMS
      From   Map_Famfornec a, Map_Produto b, Maf_Fornecdivisao c, Max_Empresa d,
             Ge_Pessoa e, Maf_Fornecedor f, Map_Famdivisao g, Map_Familia h,
             Map_Famfornec i
      Where  a.Seqfamilia                = b.Seqfamilia
      And    Decode(pnSeqFornecedor,null,a.principal,a.Seqfornecedor) = Decode(pnSeqFornecedor,null,'S',pnSeqFornecedor)
      And    b.seqproduto                = pnSeqProduto
      And    c.seqfornecedor             = a.seqfornecedor
      And    c.nrodivisao                = d.nrodivisao
      And    d.nroempresa                = pnnroempresa
      And    e.seqpessoa                 = c.seqfornecedor
      And    f.seqfornecedor             = e.seqpessoa
      And    g.seqfamilia                = b.seqfamilia
      And    g.nrodivisao                = d.nrodivisao
      And    h.seqfamilia                = b.seqfamilia
      And    i.seqfamilia                = g.seqfamilia
      And    i.seqfamilia                = h.seqfamilia
      And    i.seqfornecedor             = c.seqfornecedor ;
  exception
    when others then
      vnNroRegTribFornec          := null;
      vsUfEmpresa                 := null;
      vsUfFornec                  := null;
      vsTipTributacao             := null;
      vnNroTributacao             := null;
      vnSeqFamiliaItem            := null;
      vnNroDivisaoEmp             := null;
      vnSeqFornecItem             := null;
      vsTipForItem                := null;
      vnSeqPautaDivisao           := null;
      vsMicroEmpresa              := null;
      vsTipCalcSeloFornDiv        := null;
      vnSeqPautaICMS              := null;
      vsIndCalcDescSuframaPed     := null;
      vsCalcDescSuframaPisCofins  := null;
      vnAliqIpi                   := null;
      vnPerRedIpi                 := null;
      vnAliqII                    := null;
      vnPerRedII                  := null;
      vnPerPis                    := null;
      vnPerCofins                 := null;
      vnPerRedBasePis             := null;
      vnPerRedBaseCofins          := null;
      vnPerRedBasePisCofEmp       := null;
      vnCgoImp                    := null;
      vsSituacaoNFIpiTribFam      := null;
      vsIndICMSSTAprovtoCredICMS  := NULL;
  end;
  -- RC 74407
  select Max( nvl( (select cgoe.nroregtributacao
                            from max_cgoempresa cgoe
                            where cgoe.codgeraloper = c.codgeraloper
                            and   cgoe.nroempresa   = pnnroempresa
                            and   cgoe.status       = 'A'
                           ) ,c.nroregtributacao) )
  into   vnNroRegTribCGO
  from   Max_Codgeraloper c, map_famdivisao d
  where  c.codgeraloper = vnCgoImp
  and    d.seqfamilia   = vnSeqFamilia
  and    d.nrodivisao   = vnNroDivisaoEmp
  and    nvl(d.indusadadosregcgo,'N') = 'S'
  and    exists (select 1
                 from TABLE(PKG_CARREGAIMPOSTO.fc_BuscaTributacao(pnSeqProduto       => pnSeqProduto,
                                                                  psEntradaSaida     => 'E',
                                                                  pnNroTributacao    => vnNroTributacao,
                                                                  psTipTributacao    => vsTipTributacao,
                                                                  pnNroRegTributacao => c.nroregtributacao,
                                                                  psUfEmpresa        => vsUFEmpresa,
                                                                  psUfClienteForn    => vsUfFornec,
                                                                  pnNroEmpresa       => pnNroEmpresa,
                                                                  pnOrigem           => 7,
                                                                  pdDataBase         => sysdate,
                                                                  pnCGO              => vnCgoImp,
                                                                  pnSeqPessoa        => pnSeqFornecedor,
                                                                  psListaImposto     => null,
                                                                  psSomenteTrib      => 'S')) f);
  --
  if vnNroRegTribCGO is not null then
     vnNroRegTribFornec := vnNroRegTribCGO;
  end if;
  --
  IF (nvl(psUFPortoDestino,'xx') != 'xx') THEN
    select count(1) into vnCount
    FROM TABLE(PKG_CARREGAIMPOSTO.fc_BuscaTributacao(pnSeqProduto       => pnSeqProduto,
                                                     psEntradaSaida     => 'E',
                                                     pnNroTributacao    => vnNroTributacao,
                                                     psTipTributacao    => vsTipTributacao,
                                                     pnNroRegTributacao => vnNroRegTribFornec,
                                                     psUfEmpresa        => vsUFEmpresa,
                                                     psUfClienteForn    => nvl(psUFPortoDestino,'xx'),
                                                     pnNroEmpresa       => pnNroEmpresa,
                                                     pnOrigem           => 7,
                                                     pdDataBase         => sysdate,
                                                     pnCGO              => vnCgoImp,
                                                     pnSeqPessoa        => pnSeqFornecedor,
                                                     psListaImposto     => null,
                                                     psSomenteTrib      => 'S'));
    if ( vnCount > 0 ) then
       vsUfFornec := psUFPortoDestino;
    end if;
  END IF;
  ----- CGO
  SELECT max(NVL(C.INDCALCDIFALIQ,'N'))
  INTO   vsIndICMSDifCGO
  FROM   MAX_CODGERALOPER C
  WHERE  C.CODGERALOPER = vnCgoImp;
  --
  Select Max(a.aliqicms), Max(a.aliqicmsst), Max(a.peraliqfcpst)
  Into   vnPerAliqIcmsAdicao, vnPerAliqSTAdicao, vnPerAliqFCPSTAdicao
  From   Mad_Adicao a
  Where  a.numerodi = psNumeroDI
  And    a.nroadicao = pnNroAdicao
  And    nvl(a.indutilaliqaditens,'N') = 'S';
  If vnPerAliqIcmsAdicao is not null then
     vnPerAliqIcms := vnPerAliqIcmsAdicao;
  End If;
  If vnPerAliqSTAdicao is not null then
     vnPerAliqST := vnPerAliqSTAdicao;
  End If;
  If vnPerAliqFCPSTAdicao is not null then
     vnPerAliqFCPST := vnPerAliqFCPSTAdicao;
  End If;
  --
  vnCustoNF := pnVucv;
  vnQuantidadeEstq := pnQtde;
  vnVlrAduaneiro := (pnVucv * pnQtde);
  -- Despesas
  vnDespComplII := 0;
  vnDespComplIPI := 0;
  vnDespComplPIS := 0;
  vnDespComplCOF := 0;
  vnDespComplICMS := 0;
  SELECT Nvl(SUM(case when a.Indconsiddespcompii   = 'S' then b.Vlrtotdespcom else 0 end), 0),
         Nvl(SUM(case when a.Indconsiddespcompipi  = 'S' then b.Vlrtotdespcom else 0 end), 0),
         Nvl(SUM(case when a.Indconsiddespcomppis  = 'S' then b.Vlrtotdespcom else 0 end), 0),
         Nvl(SUM(case when a.Indconsiddespcompcof  = 'S' then b.Vlrtotdespcom else 0 end), 0),
         Nvl(SUM(case when a.Indconsiddespcompicms = 'S' then b.Vlrtotdespcom else 0 end), 0)
    INTO vnDespComplII,
         vnDespComplIPI,
         vnDespComplPIS,
         vnDespComplCOF,
         vnDespComplICMS
    FROM Mad_Adicaodespesa e, Mad_Despesacompldi a, Mad_Didespesa d,
         Mad_Adicaoitemdesp b
   WHERE a.Seqdespacompl = d.Seqdespacompl
     AND d.Seqdidespesa = e.Seqdidespesa
     AND d.Numerodi = e.Numerodi
     AND b.Seqadicdespesa = e.Seqadicdespesa
     AND b.Nroadicao = e.Nroadicao
     AND b.Numerodi = e.Numerodi
     AND b.Seqproduto = pnSeqProduto
     AND b.Nroadicao = pnNroAdicao
     AND b.Numerodi = psNumeroDI;
  -- Imposto Importação
  vnVlrAduaneiroIImp := vnVlrAduaneiro;
  if psIndUtilFreteBaseCalc = 'S' and nvl(psIncideBaseTribIImpFrete,'S') = 'S' then
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribIImpCtz,'S') = 'S' then
        vnVlrAduaneiroIImp := vnVlrAduaneiroIImp + pnVlrFrete + pnVlrCapatazia;
     else
        vnVlrAduaneiroIImp := vnVlrAduaneiroIImp + (pnVlrFrete - pnVlrCapatazia);
     end if;
  else
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribIImpCtz,'S') = 'S' then
        vnVlrAduaneiroIImp := vnVlrAduaneiroIImp + pnVlrCapatazia;
     end if;
  end if;
  if psIndUtilSeguroBaseCalc = 'S' and nvl(psIncideBaseTribIImpSeg,'S') = 'S' then
     vnVlrAduaneiroIImp := vnVlrAduaneiroIImp + pnVlrSeguro;
  end if;
  -- IPI
  vnVlrAduaneiroIpi := vnVlrAduaneiro;
  if psIndUtilFreteBaseCalc = 'S' and nvl(psIncideBaseTribIpiFrete,'S') = 'S' then
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribIpiCtz,'S') = 'S' then
        vnVlrAduaneiroIpi := vnVlrAduaneiroIpi + pnVlrFrete + pnVlrCapatazia;
     else
        vnVlrAduaneiroIpi := vnVlrAduaneiroIpi + (pnVlrFrete - pnVlrCapatazia);
     end if;
  else
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribIpiCtz,'S') = 'S' then
        vnVlrAduaneiroIpi := vnVlrAduaneiroIpi + pnVlrCapatazia;
     end if;
  end if;
  if psIndUtilSeguroBaseCalc = 'S' and nvl(psIncideBaseTribIpiSeg,'S') = 'S' then
     vnVlrAduaneiroIpi := vnVlrAduaneiroIpi + pnVlrSeguro;
  end if;
  -- PIS
  vnVlrAduaneiroPis := vnVlrAduaneiro;
  if psIndUtilFreteBaseCalc = 'S' and nvl(psIncideBaseTribPisFrete,'S') = 'S' then
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribPisCtz,'S') = 'S' then
        vnVlrAduaneiroPis := vnVlrAduaneiroPis + pnVlrFrete + pnVlrCapatazia;
     else
        vnVlrAduaneiroPis := vnVlrAduaneiroPis + (pnVlrFrete - pnVlrCapatazia);
     end if;
  else
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribPisCtz,'S') = 'S' then
        vnVlrAduaneiroPis := vnVlrAduaneiroPis + pnVlrCapatazia;
     end if;
  end if;
  if psIndUtilSeguroBaseCalc = 'S' and nvl(psIncideBaseTribPisSeg,'S') = 'S' then
     vnVlrAduaneiroPis := vnVlrAduaneiroPis + pnVlrSeguro;
  end if;
  -- COFINS
  vnVlrAduaneiroCofins := vnVlrAduaneiro;
  if psIndUtilFreteBaseCalc = 'S' and nvl(psIncideBaseTribCofinsFrete,'S') = 'S' then
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribCofinsCtz,'S') = 'S' then
        vnVlrAduaneiroCofins := vnVlrAduaneiroCofins + pnVlrFrete + pnVlrCapatazia;
     else
        vnVlrAduaneiroCofins := vnVlrAduaneiroCofins + (pnVlrFrete - pnVlrCapatazia);
     end if;
  else
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribCofinsCtz,'S') = 'S' then
        vnVlrAduaneiroCofins := vnVlrAduaneiroCofins + pnVlrCapatazia;
     end if;
  end if;
  if psIndUtilSeguroBaseCalc = 'S' and nvl(psIncideBaseTribCofinsSeg,'S') = 'S' then
     vnVlrAduaneiroCofins := vnVlrAduaneiroCofins + pnVlrSeguro;
  end if;
  -- ICMS
  vnVlrAduaneiroIcms := vnVlrAduaneiro;
  if psIndUtilFreteBaseCalc = 'S' and nvl(psIncideBaseTribIcmsFrete,'S') = 'S' then
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribIcmsCtz,'S') = 'S' then
        vnVlrAduaneiroIcms := vnVlrAduaneiroIcms + pnVlrFrete + pnVlrCapatazia;
     else
        vnVlrAduaneiroIcms := vnVlrAduaneiroIcms + (pnVlrFrete - pnVlrCapatazia);
     end if;
  else
     if psIndUtilCapataziaBaseCalc = 'S'and nvl(psIncideBaseTribIcmsCtz,'S') = 'S' then
        vnVlrAduaneiroIcms := vnVlrAduaneiroIcms + pnVlrCapatazia;
     end if;
  end if;
  if psIndUtilSeguroBaseCalc = 'S' and nvl(psIncideBaseTribIcmsSeg,'S') = 'S' then
     vnVlrAduaneiroIcms := vnVlrAduaneiroIcms + pnVlrSeguro;
  end if;
  -- *********************************
  tpImposto := null;
  -- ******* CHAVE TRIBUTAÇÃO *******
  tpImposto.tpChaveTributacao.pnCGO                := vnCgoImp;
  tpImposto.tpChaveTributacao.psUFEmpresa          := vsUFEmpresa;
  tpImposto.tpChaveTributacao.psUFCliFornec        := vsUfFornec;
  tpImposto.tpChaveTributacao.pnNroTributacaoUF    := Vnnrotributacao;
  tpImposto.tpChaveTributacao.psTipTributacaoUF    := vsTipTributacao;
  tpImposto.tpChaveTributacao.pnNroRegTributacaoUF := vnNroRegTribFornec;
  tpImposto.tpChaveTributacao.psEntradaSaida       := 'E';
  tpImposto.tpChaveTributacao.pnNroEmpresa         := pnNroEmpresa;
  tpImposto.tpChaveTributacao.pnSeqProduto         := pnSeqProduto;
  tpImposto.tpChaveTributacao.pnOrigem             := 7;
  tpImposto.tpChaveTributacao.pdDataBase           := trunc(sysdate);
  tpImposto.tpChaveTributacao.pnSeqPessoa          := pnSeqFornecedor;
  -- ******* Entrada *******
  tpImposto.tpParamEntrada.pnQuantidade          := pnQtde;
  tpImposto.tpParamEntrada.pnVlrItem             := pnVucv;
  tpImposto.tpParamEntrada.pnVlrAbatimento       := nvl(vnAbatimento,0);
  tpimposto.tpParamEntrada.pnVlrDescItem         := vnDescItem;
  tpImposto.tpParamEntrada.pnVlrDespTribItem     := nvl(vnDespTribItem,0);
  tpImposto.tpParamEntrada.pnVlrDespNTribItem    := nvl(vnDespNTribItem,0);
  tpImposto.tpParamEntrada.psIndImportExport     := 'S';
  tpImposto.tpParamEntrada.pnNroAdicao           := pnNroAdicao;
  tpImposto.tpParamEntrada.psNumeroDI            := psNumeroDI;
  tpImposto.tpParamEntrada.psTipCalcICMSST       := 'C';
  tpImposto.tpParamEntrada.pnVlrCapatazia        := pnVlrCapatazia;
  tpImposto.tpParamEntrada.pnVlrFrete            := pnVlrFrete;
  tpImposto.tpParamEntrada.pnVlrSeguro           := pnVlrSeguro;
  tpImposto.tpParamEntrada.pnVlrDespAD           := pnVlrDespAD;
  tpImposto.tpParamEntrada.pnVlrAduaneiroIImp    := vnVlrAduaneiroIImp;
  tpImposto.tpParamEntrada.pnVlrDespcomplII      := vnDespComplII;
  tpImposto.tpParamEntrada.pnVlrAduaneiroIpi     := vnVlrAduaneiroIpi;
  tpImposto.tpParamEntrada.pnVlrDespComplIPI     := vnDespComplIPI;
  tpImposto.tpParamEntrada.pnVlrAduaneiroPis     := vnVlrAduaneiroPis;
  tpImposto.tpParamEntrada.pnVlrDespComplPIS     := vnDespComplPIS;
  tpImposto.tpParamEntrada.pnVlrAduaneiroCofins  := vnVlrAduaneiroCofins;
  tpImposto.tpParamEntrada.pnVlrDespComplCofins  := vnDespComplCOF;
  tpImposto.tpParamEntrada.pnVlrAduaneiroIcms    := vnVlrAduaneiroIcms;
  tpImposto.tpParamEntrada.pnVlrDespComplIcms    := vnDespComplICMS;
  tpImposto.tpParamEntrada.psIndSomaIPIBaseICMS  := vsIndSomaIPIBaseICMS;
  tpImposto.tpParamEntrada.psTipCalcIPI          := vsTipCalcIpi;
  tpImposto.tpParamEntrada.psAplRedPisCofBasICMS := vsAplRedPisCofBasIcm;
  tpImposto.tpParamEntrada.pnPerRedPisCofBasICMS := vnPerRedPisCofBasIcm;
  tpImposto.tpParamEntrada.psTipUsoCGO           := vsTipUsoCGO;
  tpImposto.tpParamEntrada.psRecalcIPI           := 'S';
  tpImposto.tpParamEntrada.psIndPautaIcms        := vsIndPautaICMS;
  tpImposto.tpParamEntrada.psIndPautaST          := vsIndPautaST;
  tpImposto.tpParamEntrada.psTipCalcSelo         := vsTipCalcSelo;
  tpImposto.tpParamEntrada.psTipFornecedor       := vsTipForItem;
  tpImposto.tpParamEntrada.psMicroEmpresa        := vsMicroEmpresa;
  tpImposto.tpParamEntrada.pdDtaEmissao          := sysdate;
  tpImposto.tpParamEntrada.pdDtaRecebimento      := sysdate;
  tpImposto.tpParamEntrada.pnVlrAFRMM            := pnVlrAFRMM;
  pkg_carregaimposto.SP_BuscaImposto(pImposto      => tpImposto,
                                     pnOrigem      => 7,
                                     pSaidaImposto => tpSaidaImposto);
  vnPerAliqIcms                 := tpSaidaImposto.tpTributacao.peraliquotaicms;
  vnPerAliqST                   := tpSaidaImposto.tpTributacao.perAliquotaIcmsSt;
  vnPerAcrescST                 := tpSaidaImposto.tpTributacao.PerAcrescST;
  vnPerTributado                := tpSaidaImposto.tpTributacao.PerTributado;
  vnPerIsento                   := tpSaidaImposto.tpTributacao.PerIsento;
  vnPerOutro                    := tpSaidaImposto.tpTributacao.PerOutro;
  vsIndSomaIPIBaseICMS          := tpSaidaImposto.tpTributacao.IndSomaIPIBaseIcms;
  vsIndPautaICMS                := tpSaidaImposto.tpTributacao.IndPautaICMS;
  vsIndApliRedTribCalcST        := tpSaidaImposto.tpTributacao.IndReduzBaseSt;
  vnPerTributadoST              := tpSaidaImposto.tpTributacao.pertributst;
  vsTipCalcSelo                 := tpSaidaImposto.tpTributacao.TipCalcIcmsSelo;
  vnPerAliqIcmsCalc             := tpSaidaImposto.tpTributacao.peraliqicmscalcpreco;
  vsTipRedcICMSCalcST           := tpSaidaImposto.tpTributacao.TipReducIcmsCalcSt;
  vsIndApropriaST               := tpSaidaImposto.tpTributacao.PerIsentoSt;
  vnPerIsentoST                 := tpSaidaImposto.tpTributacao.PerIsentoST;
  vnPerOutroST                  := tpSaidaImposto.tpTributacao.PerOutroST;
  vnPerIcmsAntecipado           := tpSaidaImposto.tpTributacao.AliqIcmsAntecipado;
  vnPerBaseFecp                 := tpSaidaImposto.tpTributacao.PerBaseFecp;
  vnPerAliqFecp                 := tpSaidaImposto.tpTributacao.PerAliqFecp;
  vsTipoCalcFecp                := tpSaidaImposto.tpTributacao.TipCalcFecp;
  vnPerAliquotaStCargaLiq       := tpSaidaImposto.tpTributacao.PerAliquotaStCargagLiq;
  vnPerAliqICMSDif              := tpSaidaImposto.tpTributacao.PerAliqIcmsDif;
  vsSituacaoNFPisRec            := tpSaidaImposto.tpTributacao.SituacaoNfPis;
  vsSituacaoNFCofinsRec         := tpSaidaImposto.tpTributacao.SituacaoNfCofins;
  vsIndSomaIPIBaseSTTrib        := tpSaidaImposto.tpTributacao.indsomaipibasest;
  vsCalcIcmsDescSuframaRec      := tpSaidaImposto.tpTributacao.calcicmsdescsuframa;
  vsCalcSTDescSuframaTrib       := tpSaidaImposto.tpTributacao.calcicmsstdescsuframa;
  vsIndApliRedTribCalcStSemDesp := tpSaidaImposto.tpTributacao.indredbaseicmsstsemdesp;
  vnPerPmcTrib                  := tpSaidaImposto.tpTributacao.perpmc;
  vnTipoCalcIcmsFisciRet        := nvl(tpSaidaImposto.tpTributacao.tipocalcicmsfisci,0);
  vsIndCalcIcmsVPE              := nvl(tpSaidaImposto.tpTributacao.indcalcicmsvpe,'N');
  vsSituacaoNFIpiTrib           := nvl(tpSaidaImposto.tpTributacao.situacaonfipi,vsSituacaoNFIpiTribFam);
  vnPerRedBasePis               := nvl(tpSaidaImposto.tpTributacao.perbasepis,nvl(vnperredbasepis,vnperredbasepiscofemp));
  vnPerRedBaseCofins            := nvl(tpSaidaImposto.tpTributacao.perbasecofins,nvl(vnperredbasecofins,vnperredbasepiscofemp));
  vnPercAliqIcmsDifer           := case nvl(tpSaidaImposto.tpTributacao.Indcalcdifaliq,'N') || vsIndICMSDifCGO || vsIndICMSDifFam
                                        when 'SSS' then NVL(tpSaidaImposto.tpTributacao.PERALIQICMSDIFER,0)
                                        else 0 end;
  vsIndSomaIPIBaseICMSDifer     := nvl(tpSaidaImposto.tpTributacao.indsomaipibaseicmsdifer,'N');
  vnPerMajCofinsImport          := nvl(tpSaidaImposto.tpTributacao.permajoracaocofinsimport,0);
  vnPerMajPisImport             := nvl(tpSaidaImposto.tpTributacao.permajoracaopisimport,0);
  vnPercAliqIcmsAtac            := case when nvl(tpSaidaImposto.tpTributacao.utilregimeatac,'N') = 'S'
                                        then nvl(tpSaidaImposto.tpTributacao.percregimeatac,0)
                                        else 0 end;
  vnPerRedCargaTr               := tpSaidaImposto.tpTributacao.perredcargatribdi;
  vsIndUtilIcmsCalcRedFcpSt     := nvl(tpSaidaImposto.tpTributacao.indutilicmscalcredfcpst,'N');
  vnPerPis                      := tpSaidaImposto.tpTributacao.tributacaopiscalc;
  vnPerPisMajSoma               := nvl(vnPerPis, 0) + nvl(vnPerMajPisImport, 0);
  vnPerCofins                   := tpSaidaImposto.tpTributacao.tributacaocofinscalc;
  vnPerCofinsMajSoma            := nvl(vnPerCofins, 0) + nvl(vnPerMajCofinsImport, 0);
  vnPerAliqICMSRet              := tpSaidaImposto.tpTributacao.peraliqicmsret;
  vnPerAliqVPE                  := tpSaidaImposto.tpTributacao.peraliquotavpe;
  vnPerCredVPE                  := tpSaidaImposto.tpTributacao.percredcalcvpe;
  vnPerAliqFcpSt                := tpSaidaImposto.tpTributacao.peraliqfcpst;
  vnPerAliqFcpIcms              := tpSaidaImposto.tpTributacao.peraliqfcpicms;
  -- ICMS
  vnBaseIcms                := tpSaidaImposto.tpTributacaoCalc.bascalcicms;
  vnCredIcms                := tpSaidaImposto.tpTributacaoCalc.vlricms;
  vnVlrOutro                := tpSaidaImposto.tpTributacaoCalc.vlrtotoutra;
  vnVlrIsento               := tpSaidaImposto.tpTributacaoCalc.vlrtotisento;
  -- ICMS ST
  vnBaseST                  := tpSaidaImposto.tpTributacaoCalc.basecalcicmsst;
  vnVlrTotIsentoSt          := tpSaidaImposto.tpTributacaoCalc.vlrtotisentost;
  vnVlrTotOutroSt           := tpSaidaImposto.tpTributacaoCalc.vlrtotoutrost;
  vnIcmsST                  := tpSaidaImposto.tpTributacaoCalc.vlricmsst;
  -- IPI
  vnBasCalcIpi              := tpSaidaImposto.tpTributacaoCalc.basecalcipi;
  vnIsentoIpi               := tpSaidaImposto.tpTributacaoCalc.vlrtotisentoipi;
  vnOutrIpi                 := tpSaidaImposto.tpTributacaoCalc.vlrtotoutraipi;
  vnVlrIPI                  := tpSaidaImposto.tpTributacaoCalc.vlripi;
  -- PIS
  vnBaseCalculoPis          := tpSaidaImposto.tpTributacaoCalc.bascalcpis;
  vnVlrPis                  := tpSaidaImposto.tpTributacaoCalc.vlrpis;
  -- COFINS
  vnBaseCalculoCofins       := tpSaidaImposto.tpTributacaoCalc.bascalcofins;
  vnVlrCofins               := tpSaidaImposto.tpTributacaoCalc.vlrcofins;
  -- II
  vnBaseCalculoII           := (vnVlrAduaneiroIImp + vnDespComplII) * (1-(vnPerRedII / 100));
  vnVlrII                   := tpSaidaImposto.tpTributacaoCalc.vlrii;
  -- FCP
  vnBaseFcpSt               := tpSaidaImposto.tpTributacaoCalc.basefcpst;
  vnVlrFcpSt                := tpSaidaImposto.tpTributacaoCalc.vlrfcpst;
  vnBaseFcpIcms             := tpSaidaImposto.tpTributacaoCalc.basefcpicms;
  vnVlrFcpIcms              := tpSaidaImposto.tpTributacaoCalc.vlrfcpicms;
  -- ICMS RET
  vnBaseICMSRet             := tpSaidaImposto.tpTributacaoCalc.bascalcicmsret;
  vnVlrICMSRet              := tpSaidaImposto.tpTributacaoCalc.vlricmsret;
  -- ICMS DIFER
  vnBaseIcmsDifer           := case when tpSaidaImposto.tpTributacaoCalc.vlricmsdif > 0
                                    then tpSaidaImposto.tpTributacaoCalc.bascalcicms else 0 end;
  vnVlrIcmsDifer            := tpSaidaImposto.tpTributacaoCalc.vlricmsdif;
  -- ICMS CALC
  vnBaseIcmsCalc            := tpSaidaImposto.tpTributacaoCalc.baseicmscalc;
  -- ICMS ATAC
  vnBaseIcmsAtac            := tpSaidaImposto.tpTributacaoCalc.basicmsatac;
  vnVlrIcmsAtac             := tpSaidaImposto.tpTributacaoCalc.vlricmsatac;
  -- VPE
  vnVlrVPE                  := tpSaidaImposto.tpTributacaoCalc.vlrvpe;
  vnVlrIcmsVPE              := tpSaidaImposto.tpTributacaoCalc.vlricmsvpe;
  -- SUFRAMA
  vnVlrDescSuf              := tpSaidaImposto.tpTributacaoCalc.vlrdescsuframa;
  vnVlrDescSuframaIcmsRec   := tpSaidaImposto.tpTributacaoCalc.vlrdescsuframaicms;
  vnVlrDescSuframaPisRec    := tpSaidaImposto.tpTributacaoCalc.vlrdescsuframapis;
  vnVlrDescSuframaCofinsRec := tpSaidaImposto.tpTributacaoCalc.vlrdescsuframacofins;
  --VMLD
  vnVlrMercadoriaLocalDesemb := ((pnVucv * pnQtde) + (pnVlrFrete + pnVlrSeguro));
   delete mrlx_calctribitem;
   insert into mrlx_calctribitem
     (seqproduto,
      qtdembalagem,
      quantidade,
      vlrprodbruto,
      nroempresa,
      seqpessoa,
      vlrdescitem,
      vlricmsst,
      vlripi,
      baseicms,
      baseipi,
      peraliquotaipi,
      peraliquotaicms,
      vlrpautaipi,
      lancamentost,
      peraliquotaicmsst,
      vlricms,
      vlroutra,
      vlrisento,
      tipocalcicmsfisci,
      vlricmsantecipado,
      baseicmsst,
      vlrdescsf,
      vlrdescfincalc,
      codrea,
      vlrbaseicmsretido,
      aliqicmsretido,
      vlricmsretido,
      vlricmscalc,
      baseicmscalc,
      peraliqicmscalc,
      indpautaicms,
      vlrvpe,
      peraliquotavpe,
      vlricmsvpe,
      percredcalcvpe,
      vlrtotisentost,
      vlrtotoutrost,
      perisentost,
      peroutrost,
      baseicmsstdistrib,
      vlricmsstdistrib,
      aliqicmsantecipado,
      baseicmsantecipado,
      bascalcfecp,
      vlrfecp,
      peraliquotafecp,
      vlrfreteitemrateio,
      peraliqicmsdif,
      peraliqicmsorig,
      peraliquotastcargaliq,
      vlrdescbasepis,
      vlrdescbasecofins,
      indpautast,
      indcreddebicmsopst,
      vlrisentoipi,
      vlroutraipi,
      vlrdescsuframa,
      vlrdescsuframaicms,
      vlrdescsuframapis,
      vlrdescsuframacofins,
      indsuframado,
      vlrdescicms,
      vlrdesptributitem,
      vlrdespntributitem,
      codtare,
      peraliquotatare,
      vlricmstare,
      vlrfretetransp,
      situacaonf,
      versao,
      situacaonfpis,
      situacaonfcofins,
      vlrpiscalc,
      peraliquotapis,
      vlrpis,
      vlrcofinscalc,
      aliqpiscalc,
      aliqcofinscalc,
      peraliquotacofins,
      vlrcofins,
      bascalcpis,
      bascalcofins,
      vlrembpmc,
      situacaonfipi,
      pertributado,
      peracrescst,
      pertributst,
      baseicmspresumido,
      pericmspresumido,
      vlricmspresumido,
      vlrabatimento,
      tipdocfiscal,
      vlrimpostoimport,
      vlrafrmm,
      basicmsdif,
      vlrIcmsDif,
      basicmsatac,
      vlrIcmsatac,
      --
      basefcpst,
      peraliqfcpst,
      vlrfcpst,
      basefcpicms,
      peraliqfcpicms,
      vlrfcpicms,
      vlraduaneiro,
      vlrmercadorialocaldesembarque
     )
   values(pnSeqProduto,
          fpadraoembcompra(vnSeqFamilia,vnNroDivisaoEmp),
          vnQuantidadeEstq * fpadraoembcompra(vnSeqFamilia,vnNroDivisaoEmp),
          pnVucv,
          pnNroEmpresa,
          pnSeqFornecedor,
          vnDescItem,
          vnIcmsST,
          vnVlrIPI,
          vnBaseIcms,
          vnBasCalcIpi,
          vnAliqIpi,
          vnPerAliqIcms,
          pnVlrPautaIPI,
          vsIndApropriaST,
          vnPerAliqST,
          vnCredIcms,
          vnVlrOutro,
          vnVlrIsento,
          vnTipoCalcIcmsFisciRet,
          null,
          vnBaseST,
          null,
          null,
          null,
          vnBaseICMSRet,
          vnPerAliqICMSRet,
          vnVlrICMSRet,
          null,
          vnBaseIcmsCalc,
          vnPerAliqIcmsCalc,
          null,
          vnVlrVPE,
          vnPerAliqVPE,
          vnVlrIcmsVPE,
          vnPerCredVPE,
          vnVlrTotIsentoSt,
          vnVlrTotOutroSt,
          vnPerIsentoST,
          vnPerOutroST,
          null,
          null,
          null,
          null,
          vnBasCalcFecp,
          vnVlrFecp,
          vnPerAliqFecp,
          null,
          null, --vnPerAliqICMSDif,
          null,
          vnPerAliquotaStCargaLiq,
          null,
          null,
          vsItemIndPautaST,
          null,
          vnIsentoIpi,
          vnOutrIpi,
          vnVlrDescSuf,
          vnVlrDescSuframaIcmsRec,
          vnVlrDescSuframaPisRec,
          vnVlrDescSuframaCofinsRec,
          vsIndSuframadoRec,
          null,
          vnDespTribItem,
          vnDespNTribItem,
          null,
          null,
          null,
          null,
          null,
          null,
          vsSituacaoNFPisRec,
          vsSituacaoNFCofinsRec,
          vnVlrPis,
          vnPerPisMajSoma,
          vnVlrPis,
          vnVlrCofins,
          vnPerPisMajSoma,
          vnPerCofinsMajSoma,
          vnPerCofinsMajSoma,
          vnVlrCofins,
          vnBaseCalculoPis,
          vnBaseCalculoCofins,
          null,
          vsSituacaoNFIpiTrib,
          vnPerTributado,
          vnPerAcrescST,
          vnPerTributadoST,
          null,
          null,
          null,
          vnAbatimento,
          vsTipDocFiscal,
          vnVlrII,
          pnVlrAFRMM,
          vnBaseIcmsDifer,
          vnVlrIcmsDifer,
          vnBaseIcmsAtac,
          vnVlrIcmsAtac,
          vnBaseFcpSt,
          vnPerAliqFcpSt,
          vnVlrFcpSt,
          vnBaseFcpIcms,
          vnPerAliqFcpIcms,
          vnVlrFcpIcms,
          vnVlrAduaneiro,
          vnVlrMercadoriaLocalDesemb
         );
end SP_CALCTRIBADICAOITEM;
--
-- ##### Geração da Nota Fiscal Entrada Importação ('nota mãe') #########
PROCEDURE SP_GERA_NFMAE(
          pnNumeroDI           IN        MAD_DI.NUMERODI%TYPE,
          pnCodGeralOper       IN        MAX_CODGERALOPER.CODGERALOPER%TYPE,
          pnNroEmpresa         IN        MAX_EMPRESA.NROEMPRESA%TYPE,
          pdDtaHorLancto       IN        MLF_AUXNOTAFISCAL.DTAHORLANCTO%TYPE,
          psUsuLancto          IN        MLF_AUXNOTAFISCAL.USULANCTO%TYPE,
          pnImpOK              IN OUT    INTEGER)
IS
      vsAux                             VARCHAR2(1000);
      vnPD_IndModCalcICMSST             VARCHAR2(1);
      vnPD_IndModCalcDesconto           VARCHAR2(1);
      vnPD_IndModCalcIPI                VARCHAR2(1);
      vsPD_IndTipCalcTotProd            VARCHAR2(1);
      vsPD_IndModLanctoDespesaPedido    VARCHAR2(1);
      vsPD_IndTotNfBICMS_Import         MAX_PARAMETRO.VALOR%TYPE;
      vnLinhasProc                      INTEGER;
      vbExclui                          BOOLEAN;
      vnSeqAuxNF                        MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL%TYPE;
      vnCount                           NUMBER;
      vsPDSomaFretSegVlrProduto         MAX_PARAMETRO.VALOR%TYPE;
      vsPD_CSTImportUF                  MAX_PARAMETRO.VALOR%TYPE;
      vsPD_UFImportST                   MAX_PARAMETRO.VALOR%TYPE;
      vsPDSomaCapataziaVlrProduto       MAX_PARAMETRO.VALOR%TYPE;
      vsPmtAlterDespAposPedido          MAD_PIPARAMGERAL.PMTALTERDESPAPOSPEDIDO%TYPE;
      Vsdescdespdi                      Mlf_Auxnotafiscal.Observacao%TYPE;
BEGIN
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
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', pnNroEmpresa, 'IND_TOTNFBICMS_IMPORT', 'S', 'N',
          'INDICA SE O TOTAL DA NOTA DE IMPORTAÇÃO É IGUAL A BASE DE ICMS (S/N)', vsAux );
    vsPD_IndTotNfBICMS_Import := SubStr(vsAux,0,1);
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NF', 0, 'SOMA_FRET_SEG_VLR_PRODUTO', 'S', 'N',
               'INCORPORA VALOR SEGURO E FRETE AO VALOR TOTAL DOS PRODUTOS NO RECEBIMENTO ATRAVÉS DE UM DI? VALORES(S-SIM/N-NÃO(VALOR PADRÃO))', vsAux);
    vsPDSomaFretSegVlrProduto := SubStr(vsAux,0,1);
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO('RECEBTO_NF', 0, 'SOMA_CAPATAZIA_VLR_PRODUTO', 'S', 'N',
               'INCORPORA VALOR CAPATAZIA AO VALOR TOTAL DOS PRODUTOS NO RECEBIMENTO ATRAVÉS DE UM DI? VALORES(S-SIM/N-NÃO(VALOR PADRÃO))', vsAux);
    vsPDSomaCapataziaVlrProduto := SubStr(vsAux,0,1);
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', 0, 'CST_IMPORT_UF', 'S', '060',
          'INDICA A SITUAÇÃO TRIBUTÁRIA QUE FAZ PARTE DA IMPORTAÇÃO DE ITENS COM ST NAS UFs DO PARÂMETRO UF_IMPORT_ST.
VALOR PADRÃO: 060
OBS: PARA INFORMAR MAIS DE UM VALOR, SEPARÁ-LOS POR VÍRGULA. EX: 060, 110', vsAux );
    vsPD_CSTImportUF := vsAux;
    PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'RECEBTO_NF', 0, 'UF_IMPORT_ST', 'S', 'T',
          'INDICA A UF PARA IMPORTAÇÃO DOS ITENS COM ST.
VALOR PADRÃO: T
OBS: PARA INFORMAR UFs ESPECÍFICAS, SEPARÁ-LOS POR VÍRGULA. EX: RS, SC', vsAux );
    vsPD_UFImportST := vsAux;
    -- RATEIO DE FRETE, DESPESA, SEGURO E SISCOMEX
    SP_RATEIOADICAOITEM(pnNumeroDI);
    -- INCONSISTENCIAS
    SP_CONSISTENFIMPORT(pnNumeroDI);
    SELECT COUNT(*)
    INTO   vnCount
    FROM   MRL_NFINCONSISTENCIAIMPORT
    WHERE  NUMERODI = pnNumeroDI;
    If vnCount > 0 then
       pnImpOK := 0;
    End If;
    --
    for vtblFornecDI in ( select ge_pessoa.seqpessoa, ge_pessoa.versao, ge_pessoa.uf,
                                 ge_pessoa.nrocgccpf, ge_pessoa.digcgccpf
                          from   mad_adicao, ge_pessoa
                          where  mad_adicao.seqfornecedor = ge_pessoa.seqpessoa
                          and    mad_adicao.numerodi      = pnNumeroDI
                          group by ge_pessoa.seqpessoa, ge_pessoa.versao, ge_pessoa.uf,
                                   ge_pessoa.nrocgccpf, ge_pessoa.digcgccpf )
    loop
      If pnImpOK = 1 Then
            SELECT  S_SEQAUXNOTAFISCAL.NEXTVAL into vnSeqAuxNF from dual;
            SELECT  f_Fretobservacaodespdi(pnNumeroDI) into Vsdescdespdi from dual;
            -- ############### Importa as notas ###############
            --Insere o cabeçalho da nota fiscal
            INSERT INTO MLF_AUXNOTAFISCAL(
                   SEQAUXNOTAFISCAL, STATUSNF, NUMERONF,
                   SEQPESSOA, SERIENF, TIPNOTAFISCAL,
                   NROEMPRESA, VERSAOPESSOA, CODGERALOPER,
                   UFORIGEMDESTINO, VLRRECEBDINHEIRO,
                   NROCGCCPFFORNEC, DIGCGCCPFFORNEC, INDPROCESSAMENTO,
                   TIPCALCDESC, TIPCALCICMSST, TIPCALCIPI,
                   LANCDESPCONFPEDIDO, DTARECEBIMENTO, DTASAIDA,
                   DTAENTRADA, DTAHORLANCTO,
                   USULANCTO, TIPCALCTOTPROD,
                   VLRICMSST, VLRFRETEIMPORT,
                   VLRICMS, VLRIPI,
                   VLRSEGURO, VLRDESPALFAND,
                   VLRSISCOMEX, VLRIMPIMPORTEXPORT,
                   NRODECLARAIMPORT, DTAREGISTRODI, LOCALDESEMBARACODI,
                   UFDESEMBARACODI, DTADESEMBARACOADUANEIRODI, TIPODECLARAIMPORT,
                   FRETESEGUROEMBUT, INDTOTNFIGUALBICMS, IMPIMPORTACAOEMBUT,
                   PISCOFEMBPRODIMPORT, RATEIAPISCOFINSPRODTRIB,
                   PESOTOTBRUTO, PESOTOTLIQUIDO,
                   QTDADICAODI,
                   INDLANCDESPIMPORT, TIPFRETETRANSP, INDVLRBASETITFIN,
                   INDVIATRANSPORTE, VLRAFRMM, INDFORMAIMPORT, SEPESSOAADENCOMENDA,
                   SEQTRANSPORTADOR, PLACATRANSP, UFPLACATRANSP, UFTRANSP, OBSERVACAO,
                   MARCAVOLUME, NUMEROVOLUME,APPORIGEM,
                   NROACDRAWBACK, ESPECIEVOLUME, QTDTOTVOLUME,
                   VLRTOTFCPST
                   )
            SELECT vnSeqAuxNF, 'V', 0,
                   vtblFornecDI.Seqpessoa, B.SERIENFENTRADA, 'E',
                   pnNroEmpresa, vtblFornecDI.Versao, pnCodGeralOper,
                   vtblFornecDI.Uf, 0,
                   vtblFornecDI.Nrocgccpf, vtblFornecDI.Digcgccpf, 'I',
                   vnPD_IndModCalcDesconto, vnPD_IndModCalcICMSST, vnPD_IndModCalcIPI,
                   vsPD_IndModLanctoDespesaPedido, trunc(sysdate), trunc(sysdate),
                   trunc(sysdate), pdDtaHorLancto,
                   psUsuLancto, vsPD_IndTipCalcTotProd,
                   NVL(A.VLRTOTICMSST,0) AS VLRTOTICMSST, NVL(A.VLRTOTFRETE,0) AS VLRTOTFRETE,
                   NVL(A.VLRTOTICMS,0) AS VLRTOTICMS, NVL(A.VLRTOTIPI,0) AS VLRTOTIPI,
                   NVL(A.VLRTOTSEGURO,0) AS VLRTOTSEGURO, NVL(A.VLRTOTDESPAD,0) AS VLRTOTDESPAD,
                   NVL(A.VLRTOTSISCOMEX,0) AS VLRTOTSISCOMEX, NVL(A.VLRTOTII,0) AS VLRTOTII,
                   A.NUMERODI, a.dtaregistro, e.cidade,
                   e.uf, a.dtadesembaracoad, nvl(a.tipodeclaraimport,0),
                   vsPDSomaFretSegVlrProduto, nvl(vsPD_IndTotNfBICMS_Import,'N'), 'N',
                   'N', 'N',
                   NVL(A.PESOBRUTO, 0), NVL(A.PESOLIQUIDO, 0),
                   (SELECT COUNT(*)
                    FROM   MAD_ADICAO
                    WHERE  NUMERODI = A.NUMERODI
                    AND    SEQFORNECEDOR = vtblFornecDI.Seqpessoa),
                   'N', 'C', NVL(A.INDVLRBASETITFIN, 'N'),
                   A.INDVIATRANSPORTE, A.VLRAFRMM, A.INDFORMAIMPORT, A.SEPESSOAADENCOMENDA,
                   A.SEQTRANSPORTADOR, A.PLACATRANSP, A.UFPLACATRANSP, A.UFTRANSP, a.observacaonf || Vsdescdespdi,
                   A.MARCAVOLUME, A.NUMEROVOLUME,35,
                   A.NROACDRAWBACK, A.ESPECIEVOLUME, A.QTDTOTVOLUME,
                   NVL(A.VLRTOTFCPST,0) AS VLRTOTFCPST
            FROM   MAD_DI A, MAX_EMPRESASEG B, MAX_EMPRESA D, ge_cidade e
            WHERE  A.NUMERODI     =     pnNumeroDI
            AND    D.NROEMPRESA   =     A.NROEMPRESA
            AND    B.NROEMPRESA   =     D.NROEMPRESA
            AND    B.NROSEGMENTO  =     D.NROSEGMENTOPRINC
            and    e.seqcidade    =     a.seqcidadead;
            -- Verifica se foi processado alguma linha
            vnLinhasProc := SQL%ROWCOUNT;
            If vnLinhasProc = 0 Then
               pnImpOK := 0;
            End If;
      End If;
      If pnImpOK = 1 Then
        -- Insere os ítens das notas
        INSERT INTO MLF_AUXNFITEM(
               SEQAUXNOTAFISCAL, SEQAUXNFITEM, QTDEMBALAGEM,
               SEQPRODUTO, TIPITEM, SEQITEMNF,
               CODTRIBUTACAO, QUANTIDADE,
               VLRITEM,
               VLRDESCITEM, VLRFUNRURALITEM, VLRDESPTRIBUTITEM,
               VLRDESPNTRIBUTITEM, VLRDESPFORANF, VLRTOTISENTO,
               VLRTOTOUTRA, BASCALCICMS, PERALIQUOTAICMS,
               VLRICMS, BASCALCIPI, PERALIQUOTAIPI,
               VLRIPI, BASCALCICMSST, PERALIQUOTAICMSST,
               VLRICMSST, VLRDESCFINANCEIRO, VLRDESCTRANSF,
               INDADMPRECO, VLRTOTALITEM, INDMANUTENCAO,
               NROPEDIDOSUPRIM,
               VLRABATIMENTO, VLRDESCFINCALC, VLRPAUTAICMS,
               VLRIMPIMPORTEXPORT, VLRDESPESAAD,
               /*VLRSEGURO, VLRFRETE,*/ VLRSISCOMEX,
               VLRPAUTAIPI, NROADICAODI, VLRPIS, VLRCOFINS,
               PERALIQUOTAPIS, PERALIQUOTACOFINS,
               VLRBASEIMPOSTOIMPORT, VLRIMPOSTOIMPORT,
               VLRBASEVLRADUANEIRO,
               VLRFRETEDI, VLRSEGURODI, NRODRAWBACK, VLRAFRMM,
               VLRBASEVLRADIIMP, VLRBASEVLRADIPI, VLRBASEVLRADPIS,
               VLRBASEVLRADCOFINS,VLRBASEVLRADICMS, VLRFRETENANF,
               BASEFCPST, PERALIQFCPST, VLRFCPST
               )
        SELECT vnSeqAuxNF, rownum, A.QTDEMBALAGEM,
               A.SEQPRODUTO, 'R', rownum,
               0, NVL(A.QUANTIDADE,0) * A.QTDEMBALAGEM,
               (NVL(A.VLRVUCV,0) * NVL(A.QUANTIDADE,0) * A.QTDEMBALAGEM) -
               -- FRETE
               (
                (CASE WHEN NVL(B.INDUTILFRETEBASECALC, 'N') = vsPDSomaFretSegVlrProduto THEN
                         NVL(A.VLRFRETE,0)
                    ELSE
                         0
                 END
                ) * DECODE(vsPDSomaFretSegVlrProduto, 'S', -1, 1)
               ) -
               -- CAPATAZIA
               (
                (CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = vsPDSomaCapataziaVlrProduto THEN
                         NVL(A.VLRCAPATAZIA,0)
                    ELSE
                         0
                 END
                ) * DECODE(vsPDSomaCapataziaVlrProduto, 'S', -1, 1)
               ) -
               -- SEGURO
               (
                (CASE WHEN NVL(B.INDUTILSEGUROBASECALC, 'N') = vsPDSomaFretSegVlrProduto THEN
                         NVL(A.VLRSEGURO,0)
                    ELSE
                         0
                 END
                ) * DECODE(vsPDSomaFretSegVlrProduto, 'S', -1, 1)
               )
               VLRITEM,
               0, 0, NVL(A.VLRII,0)+ NVL(A.Vlrdespad,0) + NVL(A.VLRSISCOMEX,0) + NVL(A.VLRPIS,0) + NVL(A.VLRCOFINS,0) +
                     NVL(A.VLRAFRMM, 0) +
                     CASE WHEN vsPDSomaFretSegVlrProduto = 'N' THEN
                         NVL(A.VLRFRETE,0) + NVL(A.VLRSEGURO,0)
                       ELSE
                         0
                     END +
                     CASE WHEN vsPDSomaCapataziaVlrProduto = 'N' AND NVL(B.INDUTILCAPATAZIABASECALC,'N') = 'S' THEN
                         NVL(A.VLRCAPATAZIA,0)
                       ELSE
                         0
                     END + Fcalculadespcompdi(A.NUMERODI,A.NROADICAO,A.SEQPRODUTO,'D'),
               0, NVL(A.VLRDESPFORADI,0), 0,
               0, 0, 0,
               NVL(A.VLRICMS,0), 0, 0,
               NVL(A.VLRIPI,0), 0, 0,
               NVL(A.VLRICMSST,0), 0, 0,
               'N', 0, 'E',
               0,
               0, 0, 0,
               NVL(A.VLRII,0), NVL(A.Vlrdespad,0),
               /*NVL(A.VLRSEGURO,0), NVL(A.VLRFRETE,0),*/ NVL(A.VLRSISCOMEX,0),
               A.VLRIPIPAUTA, A.NROADICAO, NVL(A.VLRPIS,0), NVL(A.VLRCOFINS,0),
               NVL(C.ALIQPIS, 0), NVL(C.ALIQCOFINS, 0),
               (NVL(A.VLRVUCV,0) * NVL(A.QUANTIDADE,0) * A.QTDEMBALAGEM),
               NVL(A.VLRII,0),
               ((NVL(A.VLRVUCV,0) * NVL(A.QUANTIDADE,0) * A.QTDEMBALAGEM) +
               (CASE WHEN NVL(B.INDUTILFRETEBASECALC, 'N') = 'S' THEN
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' THEN
                                     NVL(A.VLRFRETE,0) + NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     NVL(A.VLRFRETE,0) - NVL(A.VLRCAPATAZIA, 0)
                           END
                      ELSE
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' THEN
                                     NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     0
                           END
                END) +
               (CASE WHEN NVL(B.INDUTILSEGUROBASECALC, 'N') = 'S' THEN
                         NVL(A.VLRSEGURO,0)
                    ELSE
                         0
               END)) VRLBASEVLRADUANEIRO,
               /*DECODE(NVL(B.INDUTILFRETEBASECALC,'S'),'S',NVL(A.VLRFRETE,0),0) +
               DECODE(NVL(B.INDUTILSEGUROBASECALC,'S'),'S',NVL(A.VLRSEGURO,0),0))*/
               NVL(A.VLRFRETE, 0), NVL(A.VLRSEGURO, 0), A.NRODRAWBACK, NVL(A.VLRAFRMM, 0),
               -- Imposto Importacao
               ((NVL(A.VLRVUCV,0) * NVL(A.QUANTIDADE,0) * A.QTDEMBALAGEM) +
               (CASE WHEN NVL(B.INDUTILFRETEBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBIIMPFRETE,'S') = 'S' THEN
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBIIMPCTZ,'S') = 'S' THEN
                                     NVL(A.VLRFRETE,0) + NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     NVL(A.VLRFRETE,0) - NVL(A.VLRCAPATAZIA, 0)
                           END
                      ELSE
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBIIMPCTZ,'S') = 'S' THEN
                                     NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     0
                           END
                END) +
               (CASE WHEN NVL(B.INDUTILSEGUROBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBIIMPSEG,'S') = 'S' THEN
                         NVL(A.VLRSEGURO,0)
                    ELSE
                         0
               END)) VRLBASEVLRADUANEIROIIMP,
               -- IPI
               ((NVL(A.VLRVUCV,0) * NVL(A.QUANTIDADE,0) * A.QTDEMBALAGEM) +
               (CASE WHEN NVL(B.INDUTILFRETEBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBIPIFRETE,'S') = 'S' THEN
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBIPICTZ,'S') = 'S' THEN
                                     NVL(A.VLRFRETE,0) + NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     NVL(A.VLRFRETE,0) - NVL(A.VLRCAPATAZIA, 0)
                           END
                      ELSE
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBIPICTZ,'S') = 'S' THEN
                                     NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     0
                           END
                END) +
               (CASE WHEN NVL(B.INDUTILSEGUROBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBIPISEG,'S') = 'S' THEN
                         NVL(A.VLRSEGURO,0)
                    ELSE
                         0
               END)) VRLBASEVLRADUANEIROIPI,
               -- PIS
               ((NVL(A.VLRVUCV,0) * NVL(A.QUANTIDADE,0) * A.QTDEMBALAGEM) +
               (CASE WHEN NVL(B.INDUTILFRETEBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBPISFRETE,'S') = 'S' THEN
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBPISCTZ,'S') = 'S' THEN
                                     NVL(A.VLRFRETE,0) + NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     NVL(A.VLRFRETE,0) - NVL(A.VLRCAPATAZIA, 0)
                           END
                     ELSE
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBPISCTZ,'S') = 'S' THEN
                                     NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     0
                           END
                 END)  +
               (CASE WHEN NVL(B.INDUTILSEGUROBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBPISSEG,'S') = 'S' THEN
                         NVL(A.VLRSEGURO,0)
                    ELSE
                         0
               END)) VRLBASEVLRADUANEIROPIS,
               -- COFINS
               ((NVL(A.VLRVUCV,0) * NVL(A.QUANTIDADE,0) * A.QTDEMBALAGEM) +
               (CASE WHEN NVL(B.INDUTILFRETEBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBCOFINSFRETE,'S') = 'S' THEN
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBCOFINSCTZ,'S') = 'S' THEN
                                     NVL(A.VLRFRETE,0) + NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     NVL(A.VLRFRETE,0) - NVL(A.VLRCAPATAZIA, 0)
                           END
                      ELSE
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBCOFINSCTZ,'S') = 'S' THEN
                                     NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     0
                           END
                 END) +
               (CASE WHEN NVL(B.INDUTILSEGUROBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBCOFINSSEG,'S') = 'S' THEN
                         NVL(A.VLRSEGURO,0)
                    ELSE
                         0
               END)) VRLBASEVLRADUANEIROCOFINS,
               -- ICMS
               ((NVL(A.VLRVUCV,0) * NVL(A.QUANTIDADE,0) * A.QTDEMBALAGEM) +
               (CASE WHEN NVL(B.INDUTILFRETEBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBICMSFRETE,'S') = 'S' THEN
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBICMSCTZ,'S') = 'S' THEN
                                     NVL(A.VLRFRETE,0) + NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     NVL(A.VLRFRETE,0) - NVL(A.VLRCAPATAZIA, 0)
                           END
                      ELSE
                           CASE WHEN NVL(B.INDUTILCAPATAZIABASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBICMSCTZ,'S') = 'S' THEN
                                     NVL(A.VLRCAPATAZIA, 0)
                                ELSE
                                     0
                           END
                 END) +
               (CASE WHEN NVL(B.INDUTILSEGUROBASECALC, 'N') = 'S' AND NVL(B.INCIDEBASETRIBICMSSEG,'S') = 'S' THEN
                         NVL(A.VLRSEGURO,0)
                    ELSE
                         0
               END)) VRLBASEVLRADUANEIROICMS, Fcalculadespcompdi(A.NUMERODI,A.NROADICAO,A.SEQPRODUTO,'F'),
               0, 0, NVL(A.VLRFCPST,0)
        FROM  MAD_ADICAOITEM A, MAD_DI B, MAD_ADICAO C
        WHERE A.NUMERODI      = B.NUMERODI
        AND   A.NUMERODI      = C.NUMERODI
        AND   A.NROADICAO     = C.NROADICAO
        AND   A.NUMERODI      = pnNumeroDI
        AND   C.SEQFORNECEDOR = vtblFornecDI.Seqpessoa
        ORDER BY A.NROADICAO;
        -- Verifica se foi processado alguma linha
        vnLinhasProc := SQL%ROWCOUNT;
        If vnLinhasProc = 0 Then
           pnImpOK := 0;
        End If;
      end if;
      If pnImpOK = 1 Then
        -- Atualiza os valores do cabeçalho da nota da nota com a somatória dos ítens
        UPDATE MLF_AUXNOTAFISCAL
        SET    (VLRDESCONTO, VLRDESCSUFRAMA,
                VLRPRODUTOS, VLRDESPNTRIBUTADA,
                BASEICMSSTCALC, VLRICMSSTCALC,
                VLRDESPFORANF, VLRABATIMENTO,
                VLRFRETEFORANF, VLRFRETENANF,
                VLRDESCINCOND, VLRCOMPROR,
                VLRBASEICMSRETIDO, VLRICMSRETIDO,
                BASECALCICMS, VLRICMS,
                BASECALCICMSST, VLRICMSST,
                VLRDESPTRIBUTADA, VLRIPI,
                VLRTOTALNF,
                VLRPIS, VLRCOFINS,
                VLRTOTICMSSN, VLRTOTFCPST) =
              (SELECT SUM(MLF_AUXNFITEM.VLRDESCITEM), SUM(NVL(MLF_AUXNFITEM.VLRDESCSUFRAMA,0)),
                      SUM(MLF_AUXNFITEM.VLRITEM), SUM(MLF_AUXNFITEM.VLRDESPNTRIBUTITEM),
                      0, 0,
                      SUM(MLF_AUXNFITEM.VLRDESPFORANF), SUM(NVL(MLF_AUXNFITEM.VLRABATIMENTO,0)),
                      0, SUM(NVL(MLF_AUXNFITEM.VLRFRETENANF, 0)),
                      SUM(NVL(MLF_AUXNFITEM.VLRDESCINCOND,0)), SUM(NVL(MLF_AUXNFITEM.VLRCOMPROR,0)),
                      SUM(NVL(MLF_AUXNFITEM.VLRBASEICMSRETIDO,0)), SUM(NVL(MLF_AUXNFITEM.VLRICMSRETIDO,0)),
                      SUM(NVL(MLF_AUXNFITEM.BASCALCICMS,0)), SUM(NVL(MLF_AUXNFITEM.VLRICMS,0)),
                      SUM(NVL(MLF_AUXNFITEM.BASCALCICMSST,0)), SUM(NVL(MLF_AUXNFITEM.VLRICMSST,0)),
                      SUM(NVL(MLF_AUXNFITEM.VLRDESPTRIBUTITEM,0)), SUM(NVL(MLF_AUXNFITEM.VLRIPI,0)),
                      SUM(NVL(MLF_AUXNFITEM.VLRTOTALITEM,0)) + SUM(NVL(MLF_AUXNFITEM.VLRFRETENANF, 0)),
                      SUM(NVL(MLF_AUXNFITEM.VLRPIS, 0)), SUM(NVL(MLF_AUXNFITEM.VLRCOFINS, 0)),
                      SUM(NVL(MLF_AUXNFITEM.VLRICMSSIMPLES, 0)), SUM(NVL(MLF_AUXNFITEM.VLRFCPST,0))
              FROM    MLF_AUXNFITEM
              WHERE   MLF_AUXNFITEM.SEQAUXNOTAFISCAL = MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL )
        WHERE   MLF_AUXNOTAFISCAL.NRODECLARAIMPORT = pnNumeroDI
        AND     MLF_AUXNOTAFISCAL.SEQPESSOA        = vtblFornecDI.Seqpessoa
        AND     MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL = vnSeqAuxNF
        AND     EXISTS( SELECT 1 FROM MLF_AUXNFITEM
                        WHERE  MLF_AUXNOTAFISCAL.SEQAUXNOTAFISCAL = MLF_AUXNFITEM.SEQAUXNOTAFISCAL );
      /*RP 131525*/
      if vtblFornecDI.UF = 'EX' then
          select count(1)
          into   vnCount
          from   MAX_EMPRESA A,
                 GE_PESSOA B
          where  B.SEQPESSOA = A.SEQPESSOAEMP
          and   (vsPD_UFImportST = 'T'
                 or
                 B.UF in (select column_value
                          from table(cast(c5_complexin.c5intable(vsPD_CSTImportUF) as c5instrtable)))
                 )
          and    A.NROEMPRESA = pnNroEmpresa;
          if vnCount > 0 then
            update MLF_AUXNOTAFISCAL A
            set    A.INDNFINTEGRAFISCAL = 19
            where  A.NRODECLARAIMPORT = pnNumeroDI
            and    A.SEQPESSOA        = vtblFornecDI.Seqpessoa
            and    A.SEQAUXNOTAFISCAL = vnSeqAuxNF
            and    exists (select   1
                           from     MLF_AUXNFITEM B
                           where    A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                           and      B.SITUACAONF in (select column_value
                                                     from table(cast(c5_complexin.c5intable(vsPD_CSTImportUF) as c5instrtable)))
                          );
          end if;
      end if;
    ELSE
          -- Exclui as informações das tabelas auxiliares em casos de erro de importação
        if vbExclui then
          -- Vencimento
          DELETE FROM MLF_AUXNFVENCIMENTO B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                       AND   A.NRODECLARAIMPORT = pnNumeroDI
                       AND   A.SEQPESSOA        = vtblFornecDI.Seqpessoa
                       AND   A.SEQAUXNOTAFISCAL = vnSeqAuxNF);
          -- Consistencia de Vencimento
          DELETE FROM MLF_AUXNFVENCIMENTOCONSIST B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                       AND   A.NRODECLARAIMPORT = pnNumeroDI
                       AND   A.SEQPESSOA        = vtblFornecDI.Seqpessoa
                       AND   A.SEQAUXNOTAFISCAL = vnSeqAuxNF);
          -- Lote medicamento
          DELETE FROM MLF_NFITEMLOTE B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                       AND   A.NRODECLARAIMPORT = pnNumeroDI
                       AND   A.SEQPESSOA        = vtblFornecDI.Seqpessoa
                       AND   A.SEQAUXNOTAFISCAL = vnSeqAuxNF);
          -- Ítens da nota
          DELETE FROM MLF_AUXNFITEM B
          WHERE EXISTS (SELECT 1 FROM MLF_AUXNOTAFISCAL A
                       WHERE A.SEQAUXNOTAFISCAL = B.SEQAUXNOTAFISCAL
                       AND   A.NRODECLARAIMPORT = pnNumeroDI
                       AND   A.SEQPESSOA        = vtblFornecDI.Seqpessoa
                       AND   A.SEQAUXNOTAFISCAL = vnSeqAuxNF);
          -- Nota Fiscal
          DELETE FROM MLF_AUXNOTAFISCAL
          WHERE NRODECLARAIMPORT = pnNumeroDI
          AND   SEQPESSOA        = vtblFornecDI.Seqpessoa
          AND   SEQAUXNOTAFISCAL = vnSeqAuxNF;
        End If;
      End If;
      /*ATUALIZA DI COM O SEQAUXNOTAFISCAL DA NOTA MÃE*/
      UPDATE MAD_ADICAO A SET
             A.SEQAUXNOTAFISCAL = vnSeqAuxNF
      WHERE  A.NUMERODI         = pnNumeroDI
      AND    A.SEQFORNECEDOR    = vtblFornecDI.Seqpessoa;
      select count(1) into vnCount
      from   mad_piprocimportacao
      where  numerodi   = pnNumeroDI
      and    nroempresa = pnNroEmpresa;
      if ( vnCount > 0 ) then
          SELECT NVL(MAX(PMTALTERDESPAPOSPEDIDO), 'N')
          INTO   vsPmtAlterDespAposPedido
          FROM   MAD_PIPARAMGERAL
          WHERE  NROEMPRESA = pnNroEmpresa;
          SELECT COUNT(1)
          INTO   vnCount
          FROM   MAD_PIPROCIMPORTACAO A, MAD_PIPEDIDOIMPORT B
          WHERE  A.NROPROCIMPORTACAO = B.NROPROCIMPORTACAO
          AND    A.NROEMPRESA        = B.NROEMPRESA
          AND    A.NUMERODI          = pnNumeroDI
          AND    A.NROEMPRESA        = pnNroEmpresa;
          IF vsPmtAlterDespAposPedido = 'N' OR vnCount > 1 THEN
            UPDATE MLF_AUXNFITEM B SET
                   B.NROPEDIDOSUPRIM = ( SELECT MAX(D.NROPEDIDOSUPRIM)
                                         FROM   MLF_AUXNOTAFISCAL A, MAD_PIPROCIMPORTACAO P, MAD_PIPEDIDOIMPORT D, MAD_PIPEDIMPORTPROD E
                                         WHERE  A.SEQAUXNOTAFISCAL   = B.SEQAUXNOTAFISCAL
                                         AND    A.NRODECLARAIMPORT   = P.NUMERODI
                                         AND    A.NROEMPRESA         = P.NROEMPRESA
                                         AND    P.NROPROCIMPORTACAO  = D.NROPROCIMPORTACAO
                                         AND    P.NROEMPRESA         = D.NROEMPRESA
                                         AND    A.SEQPESSOA          = D.SEQFORNECEDOR
                                         AND    D.SEQPEDIDOIMPORT    = E.SEQPEDIDOIMPORT
                                         AND    B.SEQPRODUTO         = E.SEQPRODUTO
                                         AND    A.NRODECLARAIMPORT   = pnNumeroDI
                                         AND    A.SEQPESSOA          = vtblFornecDI.Seqpessoa )
            WHERE B.SEQAUXNOTAFISCAL = vnSeqAuxNF
            AND   EXISTS( SELECT 1
                          FROM  MLF_AUXNOTAFISCAL A, MAD_PIPROCIMPORTACAO P, MAD_PIPEDIDOIMPORT D, MAD_PIPEDIMPORTPROD E
                          WHERE A.SEQAUXNOTAFISCAL  = B.SEQAUXNOTAFISCAL
                          AND   A.NRODECLARAIMPORT  = P.NUMERODI
                          AND   A.NROEMPRESA        = P.NROEMPRESA
                          AND   P.NROPROCIMPORTACAO = D.NROPROCIMPORTACAO
                          AND   P.NROEMPRESA        = D.NROEMPRESA
                          AND   A.SEQPESSOA         = D.SEQFORNECEDOR
                          AND   D.SEQPEDIDOIMPORT   = E.SEQPEDIDOIMPORT
                          AND   B.SEQPRODUTO        = E.SEQPRODUTO
                          AND   A.NRODECLARAIMPORT  = pnNumeroDI
                          AND   A.SEQPESSOA         = vtblFornecDI.Seqpessoa );
          END IF;
      end if;
    end loop;
end SP_GERA_NFMAE;
--
-- Geração das Inconsistências da DI
PROCEDURE SP_CONSISTENFIMPORT(
            pnNumeroDI           IN        MRL_NFINCONSISTENCIAIMPORT.NUMERODI%TYPE)
IS
    vnQtdAdicao                  number;
    vnVlrTotIcms                 number;
    vnVlrTotPis                  number;
    vnVlrTotCofins               number;
    vnVlrTotII                   number;
    vnVlrTotIpi                  number;
    vnVlrTotVmle                 number;
    vnVlrTotAFRMM                number;
    vnVlrTotFrete                number;
    vnVlrTotSeguro               number;
    vnVlrTotDesp                 number;
    vnVlrTotSiscomex             number;
    vnVlrTotIcmsST               number;
    vnVlrTotFCPST                number;
    vnCount                      number;
    vnVlrIcms                    number;
    vnVlrPis                     number;
    vnVlrCofins                  number;
    vnVlrII                      number;
    vnVlrIpi                     number;
    vnVlrVmle                    number;
    vnVlrAFRMM                   number;
    vnVlrFrete                   number;
    vnVlrSeguro                  number;
    vnVlrDesp                    number;
    vnVlrSiscomex                number;
    vnVlrIcmsST                  number;
    vnVlrFCPST                   number;
    vnVlrIcmsItem                number;
    vnVlrPisItem                 number;
    vnVlrCofinsItem              number;
    vnVlrIIItem                  number;
    vnVlrIpiItem                 number;
    vnVlrVmleItem                number;
    vnVlrAFRMMItem               number;
    vnVlrFreteItem               number;
    vnVlrSeguroItem              number;
    vnVlrDespItem                number;
    vnVlrSiscomexItem            number;
    vnVlrIcmsSTItem              number;
    vnVlrFCPSTItem               number;
    vbIcms                       boolean default FALSE;
    vbPis                        boolean default FALSE;
    vbCofins                     boolean default FALSE;
    vbII                         boolean default FALSE;
    vbIpi                        boolean default FALSE;
    vbVmle                       boolean default FALSE;
    vbAFRMM                      boolean default FALSE;
    vbFrete                      boolean default FALSE;
    vbSeguro                     boolean default FALSE;
    vbDesp                       boolean default FALSE;
    vbSiscomex                   boolean default FALSE;
    vbIcmsST                     boolean default FALSE;
    vbFCPST                      boolean default FALSE;
    vnSeqProduto                 number;
    vnVlrIcmsItemAD              number;
    vnVlrPisItemAD               number;
    vnVlrCofinsItemAD            number;
    vnVlrIIItemAD                number;
    vnVlrIpiItemAD               number;
    vnVlrVmleItemAD              number;
    vnVlrAFRMMItemAD             number;
    vnVlrFreteItemAD             number;
    vnVlrSeguroItemAD            number;
    vnVlrDespItemAD              number;
    vnVlrSiscomexItemAD          number;
    vnVlrIcmsSTItemAD            number;
    vnVlrFCPSTItemAD             number;
    vbExiste                     boolean;
    vsIndGeraDebCredPis          varchar2(1);
    vsIndGeraDebCredCofins       varchar2(1);
    vnCgoImp                     number;
    vnVlrTotCapatazia            MAD_DI.VLRTOTCAPATAZIA%TYPE;
    vnVlrCapatazia               MAD_ADICAO.VLRCAPATAZIA%TYPE;
    vsIndUtilFreteBaseCalc       MAD_DI.INDUTILFRETEBASECALC%TYPE;
    vsIndUtilSeguroBaseCalc      MAD_DI.INDUTILSEGUROBASECALC%TYPE;
    vsIndUtilCapataziaBaseCalc   MAD_DI.INDUTILCAPATAZIABASECALC%TYPE;
    vnVlrVmleAdicao              MAD_ADICAO.VLRVMCV%TYPE;
    vnSeqAuxNotaFiscal           MAD_DI.SEQAUXNOTAFISCAL%TYPE;
    vnPDToleranciaDivergAdic     MAX_PARAMETRO.VALOR%TYPE;
    vnPDToleranciaDivergDI       MAX_PARAMETRO.VALOR%TYPE;
    vsFormaRateioAFRMM           MAD_DI.FORMARATEIOAFRMM%TYPE;
    vsFormaRateioFrete           MAD_DI.FORMARATEIOFRETE%TYPE;
    vsFormaRateioCapatazia       MAD_DI.FORMARATEIOCAPATAZIA%TYPE;
    vsFormaRateioSeguro          MAD_DI.FORMARATEIOSEGURO%TYPE;
    vsPDIndCriticaVrProdZerado   MAX_PARAMETRO.VALOR%TYPE;
    /*vnNumeroNF                   MLF_AUXNOTAFISCAL.NUMERONF%TYPE;
    vsSerieNF                    MLF_AUXNOTAFISCAL.SERIENF%TYPE;
    vdDtaEmissao                 MLF_AUXNOTAFISCAL.DTAEMISSAO%TYPE;*/
BEGIN
    SP_BUSCAPARAMDINAMICO('DECLARACAO_IMPORT', 0, 'TOLERANCIA_DIVERG_ADICAO', 'N', '0,05',
                          'TOLERÂNCIA DE DIVERGÊNCIA ENTRE OS VALORES NA ADIÇÃO E OS VALORES DOS ÍTENS DA ADIÇÃO. VALOR PADRÃO 0,05.',
                          vnPDToleranciaDivergAdic);
    SP_BUSCAPARAMDINAMICO('DECLARACAO_IMPORT', 0, 'TOLERANCIA_DIVERG_DI', 'N', '0,10',
                          'TOLERÂNCIA DE DIVERGÊNCIA ENTRE OS VALORES NA DI E OS VALORES NA ADIÇÃO. VALOR PADRÃO 0,10.',
                          vnPDToleranciaDivergDI);
    SP_BUSCAPARAMDINAMICO('DECLARACAO_IMPORT', 0, 'IND_CRITICA_VRPROD_ZERADO', 'S', 'N',
                          'INDIQUE SE GERA CRITICA QUANDO O VALOR DO PRODUTO ESTIVER ZERADO. VALORES:(S-SIM/N-NÃO(VALOR PADRÃO))',
                          vsPDIndCriticaVrProdZerado);
    select replace(vnPDToleranciaDivergAdic, ',', '.'),
           replace(vnPDToleranciaDivergDI, ',', '.')
    into   vnPDToleranciaDivergAdic,
           vnPDToleranciaDivergDI
    from  dual;
    -- Exclui as inconsistências
    DELETE FROM  MRL_NFINCONSISTENCIAIMPORT
    WHERE  NUMERODI = pnNumeroDI;
    -- Customizazao Nagumo
    -- Giuliano 02/04/25
    -- Critica DI caso existam despesas que nao geraram financeiro
    NAGP_CONSIST_DESP_IMP(pnNumeroDI);
    --
    SELECT  nvl(MAX(A.QTDEADICAO),0), nvl(MAX(A.VLRTOTICMS),0), round(nvl(MAX(A.VLRTOTPIS),0),2),
            round(nvl(MAX(A.VLRTOTCOFINS),0),2), nvl(MAX(A.VLRTOTII),0), nvl(MAX(A.VLRTOTIPI),0),
            nvl(MAX(A.VLRVMLE),0), nvl(MAX(A.VLRAFRMM),0), nvl(MAX(A.VLRTOTFRETE),0), nvl(MAX(A.VLRTOTSEGURO),0),
            nvl(MAX(A.VLRTOTDESPAD),0), nvl(MAX(A.VLRTOTSISCOMEX),0), nvl(MAX(A.VLRTOTICMSST),0), nvl(MAX(A.VLRTOTFCPST),0),
            nvl(MAX(A.VLRTOTCAPATAZIA), 0),
            MAX(A.INDUTILFRETEBASECALC), MAX(A.INDUTILSEGUROBASECALC), MAX(A.INDUTILCAPATAZIABASECALC),
            MAX(A.SEQAUXNOTAFISCAL), MAX(A.FORMARATEIOAFRMM), MAX(A.FORMARATEIOFRETE),
            MAX(A.FORMARATEIOCAPATAZIA), MAX(A.FORMARATEIOSEGURO)
    INTO	vnQtdAdicao, vnVlrTotIcms, vnVlrTotPis,
          vnVlrTotCofins, vnVlrTotII, vnVlrTotIpi,
          vnVlrTotVmle, vnVlrTotAFRMM, vnVlrTotFrete, vnVlrTotSeguro,
          vnVlrTotDesp, vnVlrTotSiscomex, vnVlrTotIcmsST, vnVlrTotFCPST,
          vnVlrTotCapatazia,
          vsIndUtilFreteBaseCalc, vsIndUtilSeguroBaseCalc, vsIndUtilCapataziaBaseCalc,
          vnSeqAuxNotaFiscal, vsFormaRateioAFRMM, vsFormaRateioFrete,
          vsFormaRateioCapatazia, vsFormaRateioSeguro
    FROM	MAD_DI A
	  WHERE	A.NUMERODI = pnNumeroDI;
    SELECT  COUNT(1), round(nvl(SUM(A.VLRICMS),0), 2), round(nvl(SUM(A.VLRPIS),0),2), round(nvl(SUM(A.VLRCOFINS),0),2),
            round(nvl(SUM(A.VLRII),0), 2), round(nvl(SUM(A.VLRIPI),0), 2),
            round(nvl(SUM(A.VLRVMCV),0), 2), round(nvl(SUM(A.VLRAFRMM),0), 2), round(nvl(SUM(A.VLRFRETE),0), 2),
            round(nvl(SUM(A.VLRSEGURO),0), 2), round(nvl(SUM(A.VLRDESPAD),0), 2),
            round(nvl(SUM(A.VLRSISCOMEX),0), 2), round(nvl(SUM(A.VLRICMSST),0), 2),
            round(nvl(SUM(A.VLRCAPATAZIA), 0), 2), round(nvl(SUM(A.VLRFCPST),0), 2)
    INTO    vnCount, vnVlrIcms, vnVlrPis, vnVlrCofins, vnVlrII, vnVlrIpi,
            vnVlrVmle, vnVlrAFRMM, vnVlrFrete, vnVlrSeguro, vnVlrDesp, vnVlrSiscomex, vnVlrIcmsST,
            vnVlrCapatazia, vnVlrFCPST
    FROM    MAD_ADICAO A
    WHERE   A.NUMERODI = pnNumeroDI;
    SELECT  round(nvl(SUM(A.VLRICMS),0), 2), round(nvl(SUM(A.VLRPIS),0),2), round(nvl(SUM(A.VLRCOFINS),0),2),
            round(nvl(SUM(A.VLRII),0), 2), round(nvl(SUM(A.VLRIPI),0), 2),
            round(nvl(SUM(A.VLRVUCV * A.QUANTIDADE * A.QTDEMBALAGEM),0), 2), round(nvl(SUM(A.VLRAFRMM),0), 2), round(nvl(SUM(A.VLRFRETE),0), 2),
            round(nvl(SUM(A.VLRSEGURO),0), 2), round(nvl(SUM(A.VLRDESPAD),0), 2),
            round(nvl(SUM(A.VLRSISCOMEX),0), 2), round(nvl(SUM(A.VLRICMSST),0), 2),
            round(nvl(SUM(A.VLRFCPST),0), 2)
    INTO    vnVlrIcmsItem, vnVlrPisItem, vnVlrCofinsItem, vnVlrIIItem, vnVlrIpiItem,
            vnVlrVmleItem, vnVlrAFRMMItem, vnVlrFreteItem, vnVlrSeguroItem, vnVlrDespItem, vnVlrSiscomexItem, vnVlrIcmsSTItem,
            vnVlrFCPSTItem
    FROM    MAD_ADICAOITEM A
    WHERE   A.NUMERODI = pnNumeroDI;
  	if (vnVlrIcmsItem = vnVlrIcms And vnVlrIcms = vnVlrTotIcms) Or ((abs(vnVlrIcmsItem - vnVlrIcms) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrIcms - vnVlrTotIcms) <= to_number(vnPDToleranciaDivergDI)))  then
  	   vbIcms := TRUE;
  	end if;
    if (vnVlrPisItem = vnVlrPis And vnVlrPis = vnVlrTotPis) Or ((abs(vnVlrPisItem - vnVlrPis) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrPis - vnVlrTotPis) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbPis := TRUE;
  	end if;
    if (vnVlrCofinsItem = vnVlrCofins And vnVlrCofins = vnVlrTotCofins) Or ((abs(vnVlrCofinsItem - vnVlrCofins) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrCofins - vnVlrTotCofins) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbCofins := TRUE;
  	end if;
    if (vnVlrIIItem = vnVlrII And vnVlrII = vnVlrTotII) Or ((abs(vnVlrIIItem - vnVlrII) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrII - vnVlrTotII) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbII := TRUE;
  	end if;
    if (vnVlrIpiItem = vnVlrIpi And vnVlrIpi = vnVlrTotIpi) Or ((abs(vnVlrIpiItem - vnVlrIpi) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrIpi - vnVlrTotIpi) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbIpi := TRUE;
  	end if;
    if (vnVlrVmleItem = vnVlrVmle And vnVlrVmle = vnVlrTotVmle) Or ((abs(vnVlrVmleItem - vnVlrVmle) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrVmle - vnVlrTotVmle) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbVmle := TRUE;
  	end if;
    if vsFormaRateioAFRMM IN ('V', 'Q', 'P') AND (vnVlrAFRMMItem = vnVlrAFRMM And vnVlrAFRMM = vnVlrTotAFRMM) Or ((abs(vnVlrAFRMMItem - vnVlrAFRMM) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrAFRMM - vnVlrTotAFRMM) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbAFRMM := TRUE;
  	end if;
    if (vnVlrFreteItem = vnVlrFrete And vnVlrFrete = vnVlrTotFrete) Or ((abs(vnVlrFreteItem - vnVlrFrete) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrFrete - vnVlrTotFrete) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbFrete := TRUE;
  	end if;
    if (vnVlrSeguroItem = vnVlrSeguro And vnVlrSeguro = vnVlrTotSeguro) Or ((abs(vnVlrSeguroItem - vnVlrSeguro) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrSeguro - vnVlrTotSeguro) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbSeguro := TRUE;
  	end if;
    if (vnVlrDespItem = vnVlrDesp And vnVlrDesp = vnVlrTotDesp) Or ((abs(vnVlrDespItem - vnVlrDesp) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrDesp - vnVlrTotDesp) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbDesp := TRUE;
  	end if;
    if (vnVlrSiscomexItem = vnVlrSiscomex And vnVlrSiscomex = vnVlrTotSiscomex) Or ((abs(vnVlrSiscomexItem - vnVlrSiscomex) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrSiscomex - vnVlrTotSiscomex) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbSiscomex := TRUE;
  	end if;
    if (vnVlrIcmsSTItem = vnVlrIcmsST And vnVlrIcmsST = vnVlrTotIcmsST) Or ((abs(vnVlrIcmsSTItem - vnVlrIcmsST) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrIcmsST - vnVlrTotIcmsST) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbIcmsST := TRUE;
  	end if;
    if (vnVlrFCPSTItem = vnVlrFCPST And vnVlrFCPST = vnVlrTotFCPST) Or ((abs(vnVlrFCPSTItem - vnVlrFCPST) <= to_number(vnPDToleranciaDivergAdic)) and (abs(vnVlrFCPST - vnVlrTotFCPST) <= to_number(vnPDToleranciaDivergDI))) then
  	   vbFCPST := TRUE;
  	end if;
    /* - Consiste quantidade de adições*/
    if vnCount != vnQtdAdicao then
      SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 1, 'B','Quantidade de Adições informadas na DI está diferente das Adições digitadas');
    end if;
    /* - Consiste valores*/
    vbExiste := FALSE;
    if not vbIcms then
      if abs(vnVlrIcmsItem - vnVlrIcms) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRICMS,0), 2) VLRICMS,
                   I.ALIQICMS, I.PERREDICMS
                   /*I.ALIQII, I.ALIQPIS, I.ALIQCOFINS, I.ALIQIPI, I.ALIQICMS, I.ALIQICMSST,
                   I.PERREDBASEII, I.PERREDPIS, I.PERREDCOFINS, I.PERREDIPI, I.PERREDICMS, I.PERREDICMSST*/
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            --AND    NVL(I.INDUTILALIQADITENS,'N') = 'N'
            ORDER BY I.NROADICAO)
         LOOP
            vbExiste := TRUE;
            SELECT  round(nvl(SUM(A.VLRICMS),0), 2)
            INTO    vnVlrIcmsItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrIcmsItemAD - vtAdicao.Vlricms) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 2, 'B','Total do ICMS nos itens está divergente do ICMS na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      --IF vbExiste THEN
          SELECT round(nvl(SUM(I.VLRICMS),0), 2)
          INTO   vnVlrIcms
          FROM   MAD_ADICAO I
          WHERE  I.NUMERODI = pnNumeroDI;
          --AND    NVL(I.INDUTILALIQADITENS,'N') = 'N';
          if abs(vnVlrIcms - vnVlrTotIcms) > to_number(vnPDToleranciaDivergDI) then
             SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 2, 'B','Total do ICMS nas adições está divergente do ICMS na DI');
          end if;
      --END IF;
    end if;
    if not vbPis then
      if abs(vnVlrPisItem - vnVlrPis) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRPIS,0), 2) VLRPIS
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRPIS),0), 2)
            INTO    vnVlrPisItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrPisItemAD - vtAdicao.Vlrpis) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 3, 'B','Total do PIS nos itens está divergente do PIS na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      if abs(vnVlrPis - vnVlrTotPis) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 3, 'B','Total do PIS nas adições está divergente do PIS na DI');
      end if;
    end if;
    if not vbCofins then
      if abs(vnVlrCofinsItem - vnVlrCofins) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRCOFINS,0), 2) VLRCOFINS
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRCOFINS),0), 2)
            INTO    vnVlrCofinsItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrCofinsItemAD - vtAdicao.Vlrcofins) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 4, 'B','Total do COFINS nos itens está divergente do COFINS na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      if abs(vnVlrCofins - vnVlrTotCofins) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 4, 'B','Total do COFINS nas adições está divergente do COFINS na DI');
      end if;
    end if;
    if not vbII then
      if abs(vnVlrIIItem - vnVlrII) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRII,0), 2) VLRII
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRII),0), 2)
            INTO    vnVlrIIItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrIIItemAD - vtAdicao.Vlrii) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 5, 'B','Total do Imposto Importação nos itens está divergente do Imposto Importação na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      if abs(vnVlrII - vnVlrTotII) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 5, 'B','Total do Imposto Importação nas adições está divergente do Imposto Importação na DI');
      end if;
    end if;
    if not vbIpi then
      if abs(vnVlrIpiItem - vnVlrIpi) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRIPI,0), 2) VLRIPI
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRIPI),0), 2)
            INTO    vnVlrIpiItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrIpiItemAD - vtAdicao.Vlripi) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 6, 'B','Total do IPI nos itens está divergente do IPI na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      if abs(vnVlrIpi - vnVlrTotIpi) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 6, 'B','Total do IPI nas adições está divergente do IPI na DI');
      end if;
    end if;
    if not vbVmle then
      if abs(vnVlrVmleItem - vnVlrVmle) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRVMCV,0), 2) VLRVMCV
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRVUCV),0), 2)
            INTO    vnVlrVmleItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
             --RC 109135
/*            if abs(vnVlrVmleItemAD - vtAdicao.Vlrvmcv) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 7, 'B','Total do VMLE nos itens está divergente do VMLE na adição ' || vtAdicao.Nroadicao);
            end if;*/
         END LOOP;
      end if;
      /*CALCULA O VLR VMLE DAS ADIÇÕES PARA COMPARAR COM O DA DI*/
      vnVlrVmleAdicao := vnVlrVmle;
      if vsIndUtilFreteBaseCalc = 'N' then
         vnVlrVmleAdicao := vnVlrVmleAdicao - vnVlrFrete;
      end if;
      if vsIndUtilCapataziaBaseCalc = 'S' then
         vnVlrVmleAdicao := vnVlrVmleAdicao + vnVlrCapatazia;
      else
         vnVlrVmleAdicao := vnVlrVmleAdicao - vnVlrCapatazia;
      end if;
      if vsIndUtilSeguroBaseCalc = 'N' then
         vnVlrVmleAdicao := vnVlrVmleAdicao - vnVlrSeguro;
      end if;
      --RC 109135
/*      if abs(vnVlrVmleAdicao - vnVlrTotVmle) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 7, 'B','Total do VMLE nas adições está divergente do VMLE na DI');
      end if;*/
    end if;
    if vsFormaRateioAFRMM IN ('V', 'Q', 'P') AND not vbAFRMM then
      if abs(vnVlrAFRMMItem - vnVlrAFRMM) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRAFRMM,0), 2) VLRAFRMM
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRAFRMM),0), 2)
            INTO    vnVlrAFRMMItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrAFRMMItemAD - vtAdicao.VlrAFRMM) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 17, 'B','Total do AFRMM nos itens está divergente do AFRMM na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      if abs(vnVlrAFRMM - vnVlrTotAFRMM) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 17, 'B','Total do AFRMM nas adições está divergente do AFRMM na DI');
      end if;
    end if;
    if not vbFrete then
      if abs(vnVlrFreteItem - vnVlrFrete) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRFRETE,0), 2) VLRFRETE
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRFRETE),0), 2)
            INTO    vnVlrFreteItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrFreteItemAD - vtAdicao.Vlrfrete) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 8, 'B','Total do Frete nos itens está divergente do Frete na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      if abs(vnVlrFrete - vnVlrTotFrete) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 8, 'B','Total do Frete nas adições está divergente do Frete na DI');
      end if;
    end if;
    if not vbSeguro then
      if abs(vnVlrSeguroItem - vnVlrSeguro) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRSEGURO,0), 2) VLRSEGURO
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRSEGURO),0), 2)
            INTO    vnVlrSeguroItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrSeguroItemAD - vtAdicao.Vlrseguro) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 9, 'B','Total do Seguro nos itens está divergente do Seguro na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      if abs(vnVlrSeguro - vnVlrTotSeguro) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 9, 'B','Total do Seguro nas adições está divergente do Seguro na DI');
      end if;
    end if;
    if not vbDesp then
       if abs(vnVlrDespItem - vnVlrDesp) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRDESPAD,0), 2) VLRDESPAD
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRDESPAD),0), 2)
            INTO    vnVlrDespItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrDespItemAD - vtAdicao.Vlrdespad) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 10, 'B','Total das Despesas Alfandegárias nos itens está divergente das Despesas Alfandegárias na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      if abs(vnVlrDesp - vnVlrTotDesp) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 10, 'B','Total das Despesas Alfandegárias nas adições está divergente das Despesas Alfandegárias na DI');
      end if;
    end if;
    if not vbSiscomex then
      if abs(vnVlrSiscomexItem - vnVlrSiscomex) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRSISCOMEX,0), 2) VLRSISCOMEX
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRSISCOMEX),0), 2)
            INTO    vnVlrSiscomexItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrSiscomexItemAD - vtAdicao.Vlrsiscomex) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 11, 'B','Total do Siscomex nos itens está divergente do Siscomex na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      if abs(vnVlrSiscomex - vnVlrTotSiscomex) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 11, 'B','Total do Siscomex nas adições está divergente do Siscomex na DI');
      end if;
    end if;
    vbExiste := FALSE;
    if not vbIcmsST then
       if abs(vnVlrIcmsSTItem - vnVlrIcmsST) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRICMSST,0), 2) VLRICMSST
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            --AND    NVL(I.INDUTILALIQADITENS,'N') = 'N'
            ORDER BY I.NROADICAO)
         LOOP
            vbExiste := TRUE;
            SELECT  round(nvl(SUM(A.VLRICMSST),0), 2)
            INTO    vnVlrIcmsSTItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrIcmsSTItemAD - vtAdicao.Vlricmsst) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 12, 'B','Total do ICMSST nos itens está divergente do ICMSST na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      --IF vbExiste THEN
        SELECT round(nvl(SUM(I.VLRICMSST),0), 2)
        INTO   vnVlrIcmsST
        FROM   MAD_ADICAO I
        WHERE  I.NUMERODI = pnNumeroDI;
        --AND    NVL(I.INDUTILALIQADITENS,'N') = 'N';
        if abs(vnVlrIcmsST - vnVlrTotIcmsST) > to_number(vnPDToleranciaDivergDI) then
           SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 12, 'B','Total do ICMSST nas adições está divergente do ICMSST na DI');
        end if;
      --END IF;
    end if;
    if not vbFCPST then
       if abs(vnVlrFCPSTItem - vnVlrFCPST) > to_number(vnPDToleranciaDivergAdic) then
         FOR vtAdicao IN (
            SELECT I.NROADICAO, round(nvl(I.VLRFCPST,0), 2) VLRFCPST
            FROM   MAD_ADICAO I
            WHERE  I.NUMERODI = pnNumeroDI
            ORDER BY I.NROADICAO)
         LOOP
            SELECT  round(nvl(SUM(A.VLRFCPST),0), 2)
            INTO    vnVlrFCPSTItemAD
            FROM    MAD_ADICAOITEM A
            WHERE   A.NUMERODI = pnNumeroDI
            AND     A.NROADICAO = vtAdicao.Nroadicao;
            if abs(vnVlrFCPSTItemAD - vtAdicao.Vlrfcpst) > to_number(vnPDToleranciaDivergAdic) then
               SP_GRAVAINCONSISTIMPORT(pnNumeroDI, vtAdicao.Nroadicao, 0, 'N', 20, 'B','Total do FCP ST nos itens está divergente do FCP ST na adição ' || vtAdicao.Nroadicao);
            end if;
         END LOOP;
      end if;
      SELECT round(nvl(SUM(I.VLRFCPST),0), 2)
      INTO   vnVlrFCPST
      FROM   MAD_ADICAO I
      WHERE  I.NUMERODI = pnNumeroDI;
      if abs(vnVlrFCPST - vnVlrTotFCPST) > to_number(vnPDToleranciaDivergDI) then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 20, 'B','Total do FCP ST nas adições está divergente do FCP ST na DI');
      end if;
    end if;
    -- Consiste se existe adição com item informado não pertencente ao NCM digitado
    FOR T IN (
        SELECT A.*
        FROM   MAD_ADICAO A
        WHERE  A.NUMERODI = pnNumeroDI )
    LOOP
        SELECT nvl(MAX(B.SEQPRODUTO),0)
        INTO   vnSeqProduto
        FROM   MAD_ADICAOITEM B
        WHERE  B.NROADICAO = T.NROADICAO
        AND    B.NUMERODI = T.NUMERODI
        AND    NOT EXISTS (SELECT 1 FROM MAP_FAMILIA C, MAP_PRODUTO D
                           WHERE D.SEQPRODUTO = B.SEQPRODUTO
                           AND   D.SEQFAMILIA = C.SEQFAMILIA
                           AND   C.CODNBMSH = T.CODNBMSH);
        If vnSeqProduto > 0 then
           SP_GRAVAINCONSISTIMPORT(pnNumeroDI, T.NROADICAO, vnSeqProduto, 'N', 13, 'B','Produto ' || vnSeqProduto || ' não corresponde ao NCM digitado para a adição ' || T.NROADICAO);
        End If;
    END LOOP;
    -- Consiste se já foi gerada nota fiscal para a DI em questão
/*    SELECT COUNT(*)
    into vnCount
    FROM   MLFV_AUXNOTAFISCAL A
    WHERE  A.nrodeclaraimport = pnNumeroDI
    AND    NVL(A.statusnf,'V') != 'C'
    AND    nvl(A.statusnfe,4) NOT IN (7,8);
    SELECT COUNT(*), MAX(A.numeronf), MAX(A.serienf), MAX(A.dtaemissao)
    into   vnCount, vnNumeroNF, vsSerieNF, vdDtaEmissao
    FROM   MLFV_AUXNOTAFISCAL A
    WHERE  A.nrodeclaraimport = pnNumeroDI
    AND    A.seqauxnotafiscal = vnSeqAuxNotaFiscal
    AND    NVL(A.statusnf,'V') != 'C'
    AND    nvl(A.statusnfe,4) NOT IN (7,8);
    If vnCount > 0 then
--       SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 14, 'B','Já foi gerada a nota fiscal ' || to_char(vnNumeroNF) || '-' || vsSerieNF || ' na data ' || to_char(vdDtaEmissao, 'DD/MM/YYYY') || ' para a DI em questão');
       SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 14, 'B','Já foi gerada nota fiscal: ela está aguardando liberação e/ou emissão.');
    End If;*/
    -- Consistir quando um produto não possuir o fornecedor da DI cadastrado como fornecedor em sua Família
    FOR T IN (
        SELECT A.NUMERODI, A.NROADICAO, A.SEQFORNECEDOR
        FROM   MAD_ADICAO A
        WHERE  A.NUMERODI = pnNumeroDI
        GROUP BY A.NUMERODI, A.NROADICAO, A.SEQFORNECEDOR )
    LOOP
        SELECT nvl(MAX(B.SEQPRODUTO),0)
        INTO   vnSeqProduto
        FROM   MAD_ADICAOITEM B
        WHERE  B.NUMERODI  = T.NUMERODI
        AND    B.NROADICAO = T.NROADICAO
        AND    NOT EXISTS (SELECT 1 FROM MAP_FAMILIA C, MAP_PRODUTO D, MAP_FAMFORNEC F
                           WHERE D.SEQPRODUTO = B.SEQPRODUTO
                           AND   D.SEQFAMILIA = C.SEQFAMILIA
                           AND   C.SEQFAMILIA = F.SEQFAMILIA
                           AND   F.SEQFORNECEDOR = T.SEQFORNECEDOR);
        If vnSeqProduto > 0 then
           SP_GRAVAINCONSISTIMPORT(pnNumeroDI, null, vnSeqProduto, 'N', 15, 'B','Produto ' || vnSeqProduto || ' na Adição' || T.NROADICAO || ' não possui o fornecedor da DI cadastrado como fornecedor em sua Família');
        End If;
    END LOOP;
    -- Consiste  se o CGO Padrão de Importação está configurado para gerar débito/crédito de PIS/COFINS
    BEGIN
      SELECT COD.CODGERALOPER,NVL(COD.INDGERADEBCREDPIS, 'N') , NVL(COD.INDGERADEBCREDCOFINS, 'N')
      INTO vnCgoImp , vsIndGeraDebCredPis,  vsIndGeraDebCredCofins
      FROM MAD_DI DI ,
           MAX_EMPRESA E,
           MAX_CODGERALOPER  COD
      WHERE  DI.NROEMPRESA = E.NROEMPRESA
      AND    E.CGOPADRAOIMPORTACAO = COD.CODGERALOPER
      AND    DI.NUMERODI = pnNumeroDI;
    EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
      vnCgoImp := NULL;
      vsIndGeraDebCredPis := 'N';
      vsIndGeraDebCredCofins := 'N';
    END;
    If (vsIndGeraDebCredPis != 'S') Or (vsIndGeraDebCredCofins != 'S') then
       SP_GRAVAINCONSISTIMPORT(pnNumeroDI, 0, 0, 'N', 16, 'B','CGO '|| vnCgoImp ||' sem configuração de débito/credito de PIS/COFINS ');
    End If;
    -- RP 156707
    for t in (
      select a.nroadicao,
             a.seqproduto,
             a.vlrvucv
        from mad_adicaoitem a
       where a.numerodi = pnNumeroDI )
    loop
      if vsPDIndCriticaVrProdZerado = 'S' and t.vlrvucv = 0 then
         SP_GRAVAINCONSISTIMPORT(pnNumeroDI, null, vnSeqProduto, 'N', 18, 'B','Produto ' || t.seqproduto || ' na Adição ' || t.nroadicao || ' não possui valor.');
      end if;
    end loop;
    IF vsFormaRateioAFRMM     = 'I' OR
       vsFormaRateioFrete     = 'I' OR
       vsFormaRateioCapatazia = 'I' OR
       vsFormaRateioSeguro    = 'I' THEN
      FOR ad IN (SELECT A.NROADICAO, A.PESOLIQUIDO, SUM(E.PESOLIQUIDO * I.QUANTIDADE) PESOLIQUIDOEMB
                 FROM   MAD_ADICAO A, MAD_ADICAOITEM I, MAP_PRODUTO P, MAP_FAMEMBALAGEM E
                 WHERE  A.NROADICAO = I.NROADICAO
                 AND    A.NUMERODI = I.NUMERODI
                 AND    I.SEQPRODUTO = P.SEQPRODUTO
                 AND    P.SEQFAMILIA = E.SEQFAMILIA
                 AND    I.QTDEMBALAGEM = E.QTDEMBALAGEM
                 AND    A.NUMERODI = pnNumeroDI
                 GROUP BY A.NROADICAO, A.PESOLIQUIDO)
      LOOP
        IF ROUND(ad.PESOLIQUIDO) != ROUND(ad.PESOLIQUIDOEMB) THEN
          SP_GRAVAINCONSISTIMPORT(pnNumeroDI, ad.NROADICAO, 0, 'N', 19, 'B', 'Total do Peso Líquido cadastrado nas embalagens das famílias dos itens está divergente do Peso Líquido na adição ' || ad.NROADICAO);
        END IF;
      END LOOP;
    END IF;
END SP_CONSISTENFIMPORT;
--
-- Grava as inconsistências
PROCEDURE SP_GRAVAINCONSISTIMPORT(
            pnNumeroDI           IN        MRL_NFINCONSISTENCIAIMPORT.NUMERODI%TYPE,
            pnNroAdicao          IN        MRL_NFINCONSISTENCIAIMPORT.NROADICAO%TYPE,
            pnSeqProduto         IN        MRL_NFINCONSISTENCIAIMPORT.SEQPRODUTO%TYPE,
            psTipoInconsist      IN        MRL_NFINCONSISTENCIAIMPORT.TIPOINCONSIST%TYPE,
            pnCodInconsist       IN        MRL_NFINCONSISTENCIAIMPORT.CODINCONSIST%TYPE,
            psBloqueioLiberacao  IN        MRL_NFINCONSISTENCIAIMPORT.BLOQUEIOLIBERACAO%TYPE,
            psDescricao          IN        MRL_NFINCONSISTENCIAIMPORT.DESCRICAO%TYPE)
IS
    vnCount number;
BEGIN
    -- Verifica se já existe a inconsistência gravada e autorizada
    SELECT COUNT(*)
    INTO   vnCount
    FROM   MRL_NFINCONSISTENCIAIMPORT
    WHERE  NUMERODI = pnNumeroDI AND
           NROADICAO     = pnNroAdicao AND
           SEQPRODUTO = pnSeqProduto AND
           CODINCONSIST = pnCodInconsist;
    IF vnCount = 0 THEN
      -- Insere na tabela de inconsistências
      INSERT INTO MRL_NFINCONSISTENCIAIMPORT(
                  SEQINCONSISTENCIA, NUMERODI, NROADICAO, SEQPRODUTO,
                  TIPOINCONSIST, CODINCONSIST, DESCRICAO,
                  BLOQUEIOLIBERACAO)
      VALUES      (S_SEQNFINCONSISTENCIAIMPORT.NEXTVAL, pnNumeroDI, NVL(pnNroAdicao,0), NVL(pnSeqProduto,0),
                  psTipoInconsist, pnCodInconsist, psDescricao,
                  psBloqueioLiberacao);
    END IF;
END SP_GRAVAINCONSISTIMPORT;
--
-- Calculo de Rateio dos Valores de Frete, Seguro, Despesa e Siscomex nos itens
PROCEDURE  SP_RATEIOADICAOITEM(
             pnNumeroDI        IN          MAD_DI.NUMERODI%TYPE)
IS
  vsFormaRateioAFRMM           varchar2(1);
  vsFormaRateioFrete           varchar2(1);
  vsFormaRateioCapatazia       varchar2(1);
  vsFormaRateioSeguro          varchar2(1);
  vsFormaRateioSiscomex        varchar2(1);
  vsPD_FmtRateioDesp           varchar2(1);
  vnVlrTotIcms                 number;
  vnVlrTotPis                  number;
  vnVlrTotCofins               number;
  vnVlrTotII                   number;
  vnVlrTotIpi                  number;
  vnVlrTotVmle                 number;
  vnVlrTotAFRMM                number;
  vnVlrTotFrete                number;
  vnVlrTotCapatazia            number;
  vnVlrTotSeguro               number;
  vnVlrTotDesp                 number;
  vnVlrTotSiscomex             number;
  vnVlrTotIcmsST               number;
  vnVlrTotFCPST                number;
  vnTotValorAdicaoDi           number;
  vnQtdeAdicaoDi               number;
  vnPerc                       number;
  vnVlrAFRMMItem               number;
  vnVlrFreteItem               number;
  vnVlrCapataziaItem           number;
  vnTotAFRMMSoma               number;
  vnTotFreteSoma               number;
  vnTotCapataziaSoma           number;
  vnVlrSeguroItem              number;
  vnTotSeguroSoma              number;
  vnVlrDespItem                number;
  vsFormaRateioDesp            varchar2(1);
  vnTotDespSoma                number;
  vnVlrSiscomexItem            number;
  vnTotSiscomexSoma            number;
  vnTotValorAdicaoItem         number;
  vnVlrAFRMMItemII             number;
  vnTotAFRMMSomaItem           number;
  vnVlrFreteItemII             number;
  vnTotFreteSomaItem           number;
  vnVlrCapataziaItemII         number;
  vnTotCapataziaSomaItem       number;
  vnVlrSeguroItemII            number;
  vnTotSeguroSomaItem          number;
  vnQtdeAdicaoItem             number;
  vnVlrDespItemII              number;
  vnTotDespSomaItem            number;
  vnVlrSiscomexItemII          number;
  vnTotSiscomexSomaItem        number;
  vnTotPesoLiqDi               number;
  vnPercPesoLiq                number;
  vnPercDespSisc               number;
  vnPercSeguro                 number;
  vnTotVMLD                    number;
  vsIndUtilFreteBaseCalc       mad_di.indutilfretebasecalc%type;
  vsIndUtilSeguroBaseCalc      mad_di.indutilsegurobasecalc%type;
  vsIndUtilCapataziaBaseCalc   mad_di.indutilcapataziabasecalc%type;
  vnVlrFreteAux                mad_adicao.vlrfrete%type;
  vnVlrSeguroAux               mad_adicao.vlrseguro%type;
  vsPD_CalcBaseIcmsAfrmm       MAX_PARAMETRO.VALOR%TYPE;
  vnVlrTotVUCV                 mad_adicao.vlrvmcv%type := 0;
  vnNroEmpresa                 mad_di.nroempresa%type := 0;
  vnAuxTotGeral                number;
  vnAuxTotItem                 number;
  vnVlrGeral                   number;
  vnVlrUpdAdicao               number;
BEGIN
  SP_BUSCAPARAMDINAMICO( 'DECLARACAO_IMPORT', 0, 'CALC_BASE_ICMS_AFRMM', 'S', 'N',
         'CONSIDERA O VALOR AFRMM NA BASE DE CÁLCULO DO ICMS QUANDO A VIA DE TRANSPORTE INTERNACIONAL FOR "MARÍTIMA"? VALORES:(S-SIM/N-NÃO(PADRÃO))',
         vsPD_CalcBaseIcmsAfrmm );
   SELECT  nvl(MAX(A.FORMARATEIOAFRMM),'N'), nvl(MAX(A.FORMARATEIOFRETE),'V'), nvl(MAX(A.FORMARATEIOSEGURO),'V'), nvl(MAX(A.FORMARATEIODESPAD),'V'), nvl(MAX(A.FORMARATEIOSISCOMEX),'V'),
           nvl(MAX(A.FORMARATEIOCAPATAZIA),'V'),
           MAX(A.VLRTOTICMS), MAX(A.VLRTOTPIS), MAX(A.VLRTOTCOFINS), MAX(A.VLRTOTII), MAX(A.VLRTOTIPI),
           MAX(A.VLRVMLE), MAX(A.VLRAFRMM), MAX(A.VLRTOTFRETE), MAX(A.VLRTOTSEGURO), MAX(A.VLRTOTDESPAD),
           MAX(A.VLRTOTSISCOMEX), MAX(A.VLRTOTICMSST), MAX(A.VLRTOTFCPST), MAX(A.VLRTOTCAPATAZIA),
           MAX(A.INDUTILFRETEBASECALC), MAX(A.INDUTILSEGUROBASECALC), MAX(A.INDUTILCAPATAZIABASECALC),
           MAX(A.NROEMPRESA)
   INTO	   vsFormaRateioAFRMM, vsFormaRateioFrete, vsFormaRateioSeguro, vsFormaRateioDesp, vsFormaRateioSiscomex,
           vsFormaRateioCapatazia,
           vnVlrTotIcms, vnVlrTotPis, vnVlrTotCofins, vnVlrTotII, vnVlrTotIpi,
           vnVlrTotVmle,  vnVlrTotAfrmm, vnVlrTotFrete, vnVlrTotSeguro, vnVlrTotDesp,
           vnVlrTotSiscomex, vnVlrTotIcmsST, vnVlrTotFCPST, vnVlrTotCapatazia,
           vsIndUtilFreteBaseCalc, vsIndUtilSeguroBaseCalc, vsIndUtilCapataziaBaseCalc,
           vnNroEmpresa
   FROM	   MAD_DI A
	 WHERE	 A.NUMERODI = pnNumeroDI;
   -- Parametros dinamicos
   PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'PROC_IMPORTACAO', vnNroEmpresa, 'FMT_CALC_RATEIO_DESP', 'S', 'T',
   'Formato de rateio que deverá ser utilizado para cálculo do custo do produto na simulação e na geração da D.I.
    T => Rateio pelo valor total do item
    U => Rateio pelo valor unitário do item.', vsPD_FmtRateioDesp );
   --
   SELECT SUM(NVL(I.VLRVMCV,0)), COUNT(1), SUM(NVL(I.PESOLIQUIDO,0))
   INTO   vnTotValorAdicaoDi, vnQtdeAdicaoDi, vnTotPesoLiqDi
   FROM   MAD_ADICAO I
   WHERE  I.NUMERODI = pnNumeroDI;
   if ( vsPD_FmtRateioDesp = 'U' )
     then
       select sum(a.vlrvucv)
       into   vnTotValorAdicaoDi
       from   mad_adicaoitem a
       where  a.numerodi = pnNumeroDI;
   end if;
   DELETE FROM Mad_Adicaodespesa A WHERE A.Numerodi = Pnnumerodi;
   -- Busca as adições
   FOR vtAdicao IN (
      SELECT I.VLRVMCV, I.NROADICAO, I.VLRFRETE, I.PESOLIQUIDO,
             I.VLRDESPAD
      FROM   MAD_ADICAO I
      WHERE  I.NUMERODI = pnNumeroDI
      ORDER  BY I.NROADICAO)
   LOOP
     -- Caso o rateio seja por valor unitário do item
     if ( vsPD_FmtRateioDesp = 'U' )
       then
         select sum(d.vlrvucv)
         into   vnVlrTotVUCV
         from   mad_adicaoitem d
         where  d.numerodi  = pnNumeroDI
         and    d.nroadicao = vtAdicao.Nroadicao;
     else
       vnVlrTotVUCV := vtAdicao.VLRVMCV;
     end if;
     -- Percentual do ítem no total da adição
     If vnTotValorAdicaoDi > 0 Then
        vnPerc := vnVlrTotVUCV / vnTotValorAdicaoDi;
     Else
        vnPerc := 0;
     End If;
     -- Percentual do ítem no total do peso liquido
     If vnTotPesoLiqDi > 0 Then
        vnPercPesoLiq := (vtAdicao.Pesoliquido) / vnTotPesoLiqDi;
     Else
        vnPercPesoLiq := 0;
     End If;
     --DespCom
     vnVlrGeral := 0;
     SELECT SUM(i.Vlrtotdespcom)
       INTO vnVlrGeral
       FROM Mad_Didespesa i
      WHERE i.Numerodi = Pnnumerodi;
     INSERT INTO Mad_Adicaodespesa
       (Seqadicdespesa, Nroadicao, Numerodi, Seqdidespesa, Vlrtotdespcom,
        Usualteracao, Dtaalteracao)
       SELECT s_Mad_Adicaodespesa.Nextval, Vtadicao.Nroadicao, Pnnumerodi,
              x.Seqdidespesa,
              Decode(x.Formarateiodespcom,
              'Q',(x.Vlrtotdespcom / Vnqtdeadicaodi),
              'V',(x.Vlrtotdespcom * Vnperc),
              'P',(x.Vlrtotdespcom * Vnpercpesoliq),
                  NVL((SELECT MAX(a.Vlrtotdespcom)
                         FROM Madx_Adicaodespesa a
                        WHERE a.Numerodi = Pnnumerodi
                          AND a.Nroadicao = Vtadicao.Nroadicao
                          AND a.seqdidespesa = x.seqdidespesa), x.Vlrtotdespcom)) Vlrtotdespcom,
              x.Usualteracao, x.Dtaalteracao
         FROM Mad_Didespesa x
        WHERE x.Numerodi = Pnnumerodi;
     -- AFRMM
     vnVlrAFRMMItem := NULL ;
     if vsFormaRateioAFRMM = 'Q' then
       vnVlrAFRMMItem := vnVlrTotAFRMM /vnQtdeAdicaoDi;
       vnTotAFRMMSoma := vnTotAFRMMSoma + vnVlrAFRMMItem;
     elsif vsFormaRateioAFRMM = 'V' then
       vnVlrAFRMMItem := vnPerc * vnVlrTotAFRMM;
       vnTotAFRMMSoma := vnTotAFRMMSoma + vnVlrAFRMMItem;
     elsif vsFormaRateioAFRMM in ('P', 'I') then
       vnVlrAFRMMItem := vnPercPesoLiq * vnVlrTotAFRMM;
       vnTotAFRMMSoma := vnTotAFRMMSoma + vnVlrAFRMMItem;
     ELSE
       vnVlrAFRMMItem := 0;
       vnTotAFRMMSoma := 0;
     end if;
     -- Frete
     vnVlrFreteItem := NULL ;
     if vsFormaRateioFrete = 'Q' then
       vnVlrFreteItem := vnVlrTotFrete/vnQtdeAdicaoDi;
       vnTotFreteSoma := vnTotFreteSoma + vnVlrFreteItem;
     elsif vsFormaRateioFrete = 'V' then
       vnVlrFreteItem := vnPerc * vnVlrTotFrete;
       vnTotFreteSoma := vnTotFreteSoma + vnVlrFreteItem;
     elsif vsFormaRateioFrete in ('P', 'I') then
       vnVlrFreteItem := vnPercPesoLiq * vnVlrTotFrete;
       vnTotFreteSoma := vnTotFreteSoma + vnVlrFreteItem;
     else
       SELECT A.VLRFRETE
       INTO vnVlrFreteItem
       FROM MAD_ADICAO A
       WHERE  A.NUMERODI = pnNumeroDI
       AND    A.NROADICAO = vtAdicao.Nroadicao;
       vnTotFreteSoma := vnTotFreteSoma + vnVlrFreteItem;
     end if;
     -- Capatazia
     vnVlrCapataziaItem := NULL ;
     if vsFormaRateioCapatazia = 'Q' then
       vnVlrCapataziaItem := vnVlrTotCapatazia/vnQtdeAdicaoDi;
       vnTotCapataziaSoma := vnTotCapataziaSoma + vnVlrCapataziaItem;
     elsif vsFormaRateioCapatazia = 'V' then
       vnVlrCapataziaItem := vnPerc * vnVlrTotCapatazia;
       vnTotCapataziaSoma := vnTotCapataziaSoma + vnVlrCapataziaItem;
     elsif vsFormaRateioCapatazia in ('P', 'I') then
       vnVlrCapataziaItem := vnPercPesoLiq * vnVlrTotCapatazia;
       vnTotCapataziaSoma := vnTotCapataziaSoma + vnVlrCapataziaItem;
     else
       SELECT A.VLRCAPATAZIA
       INTO vnVlrCapataziaItem
       FROM MAD_ADICAO A
       WHERE  A.NUMERODI = pnNumeroDI
       AND    A.NROADICAO = vtAdicao.Nroadicao;
       vnTotCapataziaSoma := vnTotCapataziaSoma + vnVlrCapataziaItem;
     end if;
     -- Seguro
     vnVlrSeguroItem := NULL ;
     if vsFormaRateioSeguro = 'Q' then
       vnVlrSeguroItem := vnVlrTotSeguro/vnQtdeAdicaoDi;
       vnTotSeguroSoma := vnTotSeguroSoma + vnVlrSeguroItem;
     elsif vsFormaRateioSeguro = 'V' then
       -- Cálculo do percentual do ítem pelo total da adição quando for Seguro
       vnVlrTotVUCV := vtAdicao.VLRVMCV;
       If vnTotValorAdicaoDi > 0 Then
          vnPercSeguro := vnVlrTotVUCV / vnTotValorAdicaoDi;
       Else
          vnPercSeguro := 0;
       end if;
       --
       vnVlrSeguroItem := vnPercSeguro * vnVlrTotSeguro;
       vnTotSeguroSoma := vnTotSeguroSoma + vnVlrSeguroItem;
     elsif vsFormaRateioSeguro in ('P', 'I') then
       vnVlrSeguroItem := vnPercPesoLiq * vnVlrTotSeguro;
       vnTotSeguroSoma := vnTotSeguroSoma + vnVlrSeguroItem;
     else
       SELECT A.VLRSEGURO
       INTO vnVlrSeguroItem
       FROM MAD_ADICAO A
       WHERE A.NUMERODI = pnNumeroDI
       AND   A.NROADICAO = vtAdicao.Nroadicao;
       vnTotSeguroSoma := vnTotSeguroSoma + vnVlrSeguroItem;
     end if;
     vnVlrFreteAux := 0;
     if vsIndUtilFreteBaseCalc = 'S' then
        if vsIndUtilCapataziaBaseCalc = 'S' then
           vnVlrFreteAux := vnVlrTotFrete + vnVlrTotCapatazia;
        else
           vnVlrFreteAux := vnVlrTotFrete - vnVlrTotCapatazia;
        end if;
     else
        if vsIndUtilCapataziaBaseCalc = 'S' then
           vnVlrFreteAux := vnVlrTotCapatazia;
        end if;
     end if;
     vnVlrSeguroAux := 0;
     if vsIndUtilSeguroBaseCalc = 'S' then
        vnVlrSeguroAux := vnVlrTotSeguro;
     end if;
--     vnTotVMLD := (vnVlrTotVmle + vnVlrTotFrete + vnVlrTotSeguro);
     vnTotVMLD := (vnVlrTotVmle + vnVlrFreteAux + vnVlrSeguroAux);
     -- Percentual do ítem no total da Di acrescido de frete e seguro para cálculo da despesa e siscomex
     If vnTotVMLD > 0 Then
        --vnPercDespSisc := (vtAdicao.VLRVMCV + vnVlrFreteItem + vnVlrSeguroItem) / vnTotVMLD;
         vnVlrFreteAux := 0;
         if vsIndUtilFreteBaseCalc = 'S' then
            if vsIndUtilCapataziaBaseCalc = 'S' then
               vnVlrFreteAux := vnVlrFreteItem + vnVlrCapataziaItem;
            else
               vnVlrFreteAux := vnVlrFreteItem - vnVlrCapataziaItem;
            end if;
         else
            if vsIndUtilCapataziaBaseCalc = 'S' then
               vnVlrFreteAux := vnVlrCapataziaItem;
            end if;
         end if;
         vnVlrSeguroAux := 0;
         if vsIndUtilSeguroBaseCalc = 'S' then
            vnVlrSeguroAux := vnVlrSeguroItem;
         end if;
         vnPercDespSisc := (vtAdicao.VLRVMCV + vnVlrFreteAux + vnVlrSeguroAux) / vnTotVMLD;
         -- Alterado Multi Formato, dava diferença na D.I.
         --vnPercDespSisc := ROUND(vnPercDespSisc, 2);
     Else
        vnPercDespSisc := 0;
     End If;
     -- Despesas Alfandegárias
     vnVlrDespItem := NULL ;
     if vsFormaRateioDesp = 'Q' then
       vnVlrDespItem := vnVlrTotDesp/vnQtdeAdicaoDi;
       vnTotDespSoma := vnTotDespSoma + vnVlrDespItem;
     elsif vsFormaRateioDesp = 'V' then
       vnVlrDespItem := vnPerc * vnVlrTotDesp;
       vnTotDespSoma := vnTotDespSoma + vnVlrDespItem;
     elsif vsFormaRateioDesp = 'D' then
       vnVlrDespItem := vnPercDespSisc * vnVlrTotDesp;
       vnTotDespSoma := vnTotDespSoma + vnVlrDespItem;
     elsif vsFormaRateioDesp = 'L' then
       vnVlrDespItem := vtAdicao.Vlrdespad;
       vnTotDespSoma := vnTotDespSoma + vnVlrDespItem;
     else
       SELECT A.VLRDESPAD
       INTO vnVlrDespItem
       FROM MAD_ADICAO A
       WHERE A.NUMERODI = pnNumeroDI
       AND   A.NROADICAO = vtAdicao.Nroadicao;
       vnTotDespSoma := vnTotDespSoma + vnVlrDespItem;
     end if;
     -- Siscomex
     vnVlrSiscomexItem := NULL ;
     if vsFormaRateioSiscomex = 'Q' then
       vnVlrSiscomexItem := vnVlrTotSiscomex/vnQtdeAdicaoDi;
       vnTotSiscomexSoma := vnTotSiscomexSoma + vnVlrSiscomexItem;
     elsif vsFormaRateioSiscomex = 'V' then
       vnVlrSiscomexItem := vnPerc * vnVlrTotSiscomex;
       vnTotSiscomexSoma := vnTotSiscomexSoma + vnVlrSiscomexItem;
     elsif vsFormaRateioSiscomex = 'D' then
       vnVlrSiscomexItem := vnPercDespSisc * vnVlrTotSiscomex;
       vnTotSiscomexSoma := vnTotSiscomexSoma + vnVlrSiscomexItem;
     elsif vsFormaRateioSiscomex = 'P' then
       vnVlrSiscomexItem := vnPercPesoLiq * vnVlrTotSiscomex ;
       vnTotSiscomexSoma := vnTotSiscomexSoma + vnVlrSiscomexItem;
     else
       SELECT A.VLRSISCOMEX
       INTO vnVlrSiscomexItem
       FROM MAD_ADICAO A
       WHERE A.NUMERODI = pnNumeroDI
       AND   A.NROADICAO = vtAdicao.Nroadicao;
       vnTotSiscomexSoma := vnTotSiscomexSoma + vnVlrSiscomexItem;
     end if;
     UPDATE MAD_ADICAO A
     SET    A.VLRAFRMM = DECODE(vnVlrAFRMMItem,NULL,A.VLRAFRMM,vnVlrAFRMMItem),
            A.VLRFRETE = DECODE(vnVlrFreteItem,NULL,A.VLRFRETE,vnVlrFreteItem),
            A.VLRCAPATAZIA = DECODE(vnVlrCapataziaItem,NULL,nvl(A.VLRCAPATAZIA,0),vnVlrCapataziaItem),
            A.VLRSEGURO = DECODE(vnVlrSeguroItem,NULL,A.VLRSEGURO,vnVlrSeguroItem),
            A.VLRDESPAD = DECODE(vnVlrDespItem,NULL,A.VLRDESPAD,vnVlrDespItem),
            A.VLRSISCOMEX = DECODE(vnVlrSiscomexItem,NULL,A.VLRSISCOMEX,vnVlrSiscomexItem)
     WHERE  A.NUMERODI = pnNumeroDI AND
            A.NROADICAO = vtAdicao.Nroadicao;
     SELECT SUM((NVL(I.VLRVUCV,0) * I.QTDEMBALAGEM) * NVL(I.QUANTIDADE, I.QTDEITEMDI)), COUNT(1)
     INTO   vnTotValorAdicaoItem, vnQtdeAdicaoItem
     FROM   MAD_ADICAOITEM I
     WHERE  I.NUMERODI = pnNumeroDI
     AND    I.NROADICAO = vtAdicao.Nroadicao;
     DELETE FROM Mad_Adicaoitemdesp A WHERE A.Numerodi = Pnnumerodi AND A.Nroadicao = Vtadicao.Nroadicao;
     -- Busca os itens das adições
     FOR vtAdicaoItem IN (
        SELECT I.VLRVUCV, I.SEQPRODUTO, NVL(I.QUANTIDADE, I.QTDEITEMDI) QUANTIDADE,
               I.QTDEMBALAGEM, E.PESOLIQUIDO * I.QUANTIDADE PESOLIQUIDO
        FROM   MAD_ADICAOITEM I, MAP_PRODUTO P, MAP_FAMEMBALAGEM E
        WHERE  I.SEQPRODUTO = P.SEQPRODUTO
        AND    P.SEQFAMILIA = E.SEQFAMILIA
        AND    I.QTDEMBALAGEM = E.QTDEMBALAGEM
        AND    I.NUMERODI = pnNumeroDI
        AND    I.NROADICAO = vtAdicao.Nroadicao )
     LOOP
        -- Percentual do ítem no total da adição
        if ( vsPD_FmtRateioDesp = 'T' ) then
           If vnTotValorAdicaoItem > 0 Then
              vnPerc := ((vtAdicaoItem.VLRVUCV * vtAdicaoItem.QTDEMBALAGEM) * vtAdicaoItem.QUANTIDADE) / vnTotValorAdicaoItem;
           Else
              vnPerc := 0;
           End If;
        else
           If ( vnVlrTotVUCV > 0 ) Then
              vnPerc := vtAdicaoItem.VLRVUCV / vnVlrTotVUCV;
           Else
              vnPerc := 0;
           End If;
        end if;
        -- Percentual do peso do item no total do peso da adicao
        if vtAdicao.PESOLIQUIDO > 0 then
          vnPercPesoLiq := vtAdicaoItem.PESOLIQUIDO / vtAdicao.PESOLIQUIDO;
        else
          vnPercPesoLiq := 0;
        end if;
        --DespCom
        INSERT INTO Mad_Adicaoitemdesp
          (Seqadicitemdesp, Nroadicao, Numerodi, Seqproduto, Seqadicdespesa,
           Vlrtotdespcom, Usualteracao, Dtaalteracao)
          SELECT s_Mad_Adicaoitemdesp.Nextval, Vtadicao.Nroadicao,
                 Pnnumerodi, Vtadicaoitem.Seqproduto, z.Seqadicdespesa,
                 (z.Vlrtotdespcom * Vnperc), z.Usualteracao, z.Dtaalteracao
            FROM Mad_Adicaodespesa z
           WHERE z.Numerodi = Pnnumerodi
             AND z.Nroadicao = Vtadicao.Nroadicao;
         -- AFRMM
         vnVlrAFRMMItemII := NULL;
         if vsFormaRateioAFRMM = 'Q' then
           vnVlrAFRMMItemII := vnVlrAFRMMItem / vnQtdeAdicaoItem;
         elsif vsFormaRateioAFRMM = 'I' then
           vnVlrAFRMMItemII := vnPercPesoLiq * vnVlrAFRMMItem;
         else
           vnVlrAFRMMItemII := vnPerc * vnVlrAFRMMItem;
         end if;
         vnTotAFRMMSomaItem := vnTotAFRMMSomaItem + vnVlrAFRMMItemII;
         if vnVlrAFRMMItemII = 0 then
           vnVlrAFRMMItemII := null;
         end if;
         -- Frete
         vnVlrFreteItemII := NULL;
         if vsFormaRateioFrete = 'Q' then
           vnVlrFreteItemII := vnVlrFreteItem / vnQtdeAdicaoItem;
         elsif vsFormaRateioFrete = 'I' then
           vnVlrFreteItemII := vnPercPesoLiq * vnVlrFreteItem;
         elsif vsFormaRateioFrete = 'L' then
           vnVlrFreteItemII := 0;
         else
           vnVlrFreteItemII := vnPerc * vnVlrFreteItem;
         end if;
         vnTotFreteSomaItem := vnTotFreteSomaItem + vnVlrFreteItemII;
         if vnVlrFreteItemII = 0 then
            vnVlrFreteItemII := null;
         end if;
         -- Capatazia
         vnVlrCapataziaItemII := NULL;
         if vsFormaRateioCapatazia = 'Q' then
           vnVlrCapataziaItemII := vnVlrCapataziaItem / vnQtdeAdicaoItem;
         elsif vsFormaRateioCapatazia = 'I' then
           vnVlrCapataziaItemII := vnPercPesoLiq * vnVlrCapataziaItem;
         else
           vnVlrCapataziaItemII := vnPerc * vnVlrCapataziaItem;
         end if;
         vnTotCapataziaSomaItem := vnTotCapataziaSomaItem + vnVlrCapataziaItemII;
         if vnVlrCapataziaItemII = 0 then
            vnVlrCapataziaItemII := null;
         end if;
         -- Seguro
         vnVlrSeguroItemII := NULL;
         if vsFormaRateioSeguro = 'Q' then
           vnVlrSeguroItemII := vnVlrSeguroItem / vnQtdeAdicaoItem;
         elsif vsFormaRateioSeguro = 'I' then
           vnVlrSeguroItemII := vnPercPesoLiq * vnVlrSeguroItem;
         else
           vnVlrSeguroItemII := vnPerc * vnVlrSeguroItem;
         end if;
         vnTotSeguroSomaItem := vnTotSeguroSomaItem + vnVlrSeguroItemII;
         if vnVlrSeguroItemII = 0 then
            vnVlrSeguroItemII := null;
         end if;
         -- Despesas Alfandegárias
         vnVlrDespItemII := NULL;
         if vsFormaRateioDesp = 'Q' then
           vnVlrDespItemII := vnVlrDespItem / vnQtdeAdicaoItem;
         else
           vnVlrDespItemII := vnPerc * vnVlrDespItem;
         end if;
         vnTotDespSomaItem := vnTotDespSomaItem + vnVlrDespItemII;
         if vnVlrDespItemII = 0 then
            vnVlrDespItemII := null;
         end if;
         -- Siscomex
         vnVlrSiscomexItemII := NULL;
         if vsFormaRateioSiscomex = 'Q' then
           vnVlrSiscomexItemII := vnVlrSiscomexItem / vnQtdeAdicaoItem;
         else
           vnVlrSiscomexItemII := vnPerc * vnVlrSiscomexItem;
         end if;
         vnTotSiscomexSomaItem := vnTotSiscomexSomaItem + vnVlrSiscomexItemII;
         if vnVlrSiscomexItemII = 0 then
            vnVlrSiscomexItemII := null;
         end if;
         UPDATE MAD_ADICAOITEM A
         SET    A.VLRAFRMM = DECODE(vnVlrAFRMMItemII,NULL,A.VLRAFRMM,vnVlrAFRMMItemII),
                A.VLRFRETE = DECODE(vnVlrFreteItemII,NULL,A.VLRFRETE,vnVlrFreteItemII),
                A.VLRCAPATAZIA = DECODE(vnVlrCapataziaItemII,NULL,nvl(A.VLRCAPATAZIA,0),vnVlrCapataziaItemII),
                A.VLRSEGURO = DECODE(vnVlrSeguroItemII,NULL,A.VLRSEGURO,vnVlrSeguroItemII),
                A.VLRDESPAD = DECODE(vnVlrDespItemII,NULL,A.VLRDESPAD,vnVlrDespItemII),
                A.VLRSISCOMEX = DECODE(vnVlrSiscomexItemII,NULL,A.VLRSISCOMEX,vnVlrSiscomexItemII)
         WHERE  A.NUMERODI = pnNumeroDI AND
                A.NROADICAO = vtAdicao.Nroadicao AND
                A.SEQPRODUTO = vtAdicaoItem.Seqproduto;
     END LOOP;
   END LOOP;
     --Adiciona a diferença no primeiro
     vnAuxTotGeral := 0;
     SELECT SUM(m.Vlrtotdespcom)
       INTO Vnauxtotgeral
       FROM Mad_Adicaodespesa m
      WHERE m.Numerodi = Pnnumerodi;
     IF (vnVlrGeral - vnAuxTotGeral) > 0 THEN
        UPDATE Mad_Adicaodespesa z
           SET z.Vlrtotdespcom = z.Vlrtotdespcom +
                                  (Vnvlrgeral - Vnauxtotgeral)
         WHERE z.Numerodi = Pnnumerodi
           AND Rownum = 1;
     END IF;
     vnAuxTotItem := 0;
     SELECT SUM(i.Vlrtotdespcom)
       INTO vnAuxTotItem
       FROM Mad_Adicaoitemdesp i
      WHERE i.Numerodi = Pnnumerodi;
     IF (vnVlrGeral - vnAuxTotItem) > 0 THEN
        UPDATE Mad_Adicaoitemdesp z
           SET z.Vlrtotdespcom = z.Vlrtotdespcom +
                                  (Vnvlrgeral - Vnauxtotitem)
         WHERE z.Numerodi = Pnnumerodi
           AND Rownum = 1;
     END IF;
     --
   --Update nas tabelas principais
   FOR vtAdicao IN (
      SELECT i.Nroadicao
        FROM Mad_Adicao i
       WHERE i.Numerodi = Pnnumerodi
       ORDER BY i.Nroadicao)
   LOOP
       vnVlrUpdAdicao := 0;
       SELECT SUM(i.Vlrtotdespcom)
         INTO Vnvlrupdadicao
         FROM Mad_Adicaodespesa i
        WHERE i.Numerodi = Pnnumerodi
          AND i.Nroadicao = Vtadicao.Nroadicao;
       UPDATE Mad_Adicao a
          SET a.Vlrtotdespcom = Vnvlrupdadicao
        WHERE a.Numerodi = Pnnumerodi
          AND a.Nroadicao = Vtadicao.Nroadicao;
        FOR vtAdicaoItem IN (
          SELECT i.Seqproduto
            FROM Mad_Adicaoitem i
           WHERE i.Numerodi = Pnnumerodi
             AND i.Nroadicao = Vtadicao.Nroadicao)
        LOOP
            vnVlrUpdAdicao := 0;
            SELECT SUM(i.Vlrtotdespcom)
              INTO Vnvlrupdadicao
              FROM Mad_Adicaoitemdesp i
             WHERE i.Numerodi = Pnnumerodi
               AND i.Nroadicao = Vtadicao.Nroadicao
               AND i.Seqproduto = Vtadicaoitem.Seqproduto;
            UPDATE Mad_Adicaoitem a
               SET a.Vlrtotdespcom = Vnvlrupdadicao
             WHERE a.Numerodi = Pnnumerodi
               AND a.Nroadicao = Vtadicao.Nroadicao
               AND a.Seqproduto = Vtadicaoitem.Seqproduto;
        END LOOP;
   END LOOP;
END  SP_RATEIOADICAOITEM;
--
-- Faz o tratamento para cálculo das tributações referentes a adição da DI
PROCEDURE SP_CALCTRIBADICAO(
                     pnVmcv          in mad_adicao.vlrvmcv%type,
                     pnVlrPautaIPI   in mad_adicao.vlripipauta%type,
                     pnVlrAFRMM      in mad_adicao.vlrafrmm%TYPE,
                     pnVlrFrete      in mad_adicao.vlrfrete%type,
                     pnVlrSeguro     in mad_adicao.vlrseguro%type,
                     pnVlrDespAD     in mad_adicao.vlrdespad%type,
                     pnAliqII        in mad_adicao.aliqii%type,
                     pnPerRedII      in mad_adicao.perredbaseii%type,
                     pnAliqPis       in mad_adicao.aliqpis%type,
                     pnPerRedPis     in mad_adicao.perredpis%type,
                     pnAliqCofins    in mad_adicao.aliqcofins%type,
                     pnPerRedCofins  in mad_adicao.perredcofins%type,
                     pnAliqIpi       in mad_adicao.aliqipi%type,
                     pnPerRedIpi     in mad_adicao.perredipi%type,
                     pnAliqIcms      in mad_adicao.aliqicms%type,
                     pnPerRedIcms    in mad_adicao.perredicms%type,
                     pnAliqIcmsST    in mad_adicao.aliqicmsst%type,
                     pnPerRedIcmsST  in mad_adicao.perredicmsst%type,
                     pnPerAcrST      in mad_adicao.peracrescst%type,
                     pnPerRedCargaTr in mad_adicao.perredcargatribdi%type,
                     pnAliqFCPST     in mad_adicao.peraliqfcpst%type,
                     pnVlrII         in out mad_adicao.vlrii%type,
                     pnVlrPis        in out mad_adicao.vlrpis%type,
                     pnVlrCofins     in out mad_adicao.vlrcofins%type,
                     pnVlrIpi        in out mad_adicao.vlripi%type,
                     pnVlrIcms       in out mad_adicao.vlricmsst%type,
                     pnVlrIcmsST     in out mad_adicao.vlricmsst%TYPE,
                     pnVlrFCPST      in out mad_adicao.vlrfcpst%type,
                     psNumeroDI      in mad_adicaoitem.numerodi%type,
                     pnNroAdicao     in mad_adicaoitem.nroadicao%type,
                     pnNroProcImport in mad_di.nroprocimportacao%type default null
            )
IS
  vnBaseCalculoII         number;
  vnBasCalcIpi            number;
  vnBaseCalculoPis        number;
  vnBaseCalculoCofins     number;
  vnBaseIcms              number;
  vnBaseIcmsST            number;
  vnBaseFCPST             number;
  vsPD_BaseCalcPisCofins  max_parametro.valor%type;
  vsPD_CalcBaseIcmsAfrmm  max_parametro.valor%type;
  vsIndUtilRedCargaTribDI max_paramgeral.indutilredcargatribdi%type;
  vnDespComplII           number; --RC201470
  vnDespComplIPI          number; --RC201470
  vnDespComplPIS          number; --RC201470
  vnDespComplCOF          number; --RC201470
  vnDespComplICMSST       number; --RC201470
  vnDespComplICMS         number; --DSUPCOMP-4661
BEGIN
  SP_BUSCAPARAMDINAMICO( 'DECLARACAO_IMPORT', 0, 'BASE_CALC_PIS_COFINS', 'S', 'A', 'INFORME COMO SERÁ A BASE DE CÁLCULO DOS IMPOSTOS PIS E COFINS? VALORES:(A-VALOR ADUANEIRO(PADRÃO)/B-INCLUI NA BASE DE CÁLCULO AS ALÍQUOTAS DO ICMS, DO IMPOSTO DE IMPORTAÇÃO, DO IPI E AS ALÍQUOTAS DAS PRÓPRIAS CONTRIBUIÇÕES)', vsPD_BaseCalcPisCofins);
  SP_BUSCAPARAMDINAMICO( 'DECLARACAO_IMPORT', 0, 'CALC_BASE_ICMS_AFRMM', 'S', 'N',
         'CONSIDERA O VALOR AFRMM NA BASE DE CÁLCULO DO ICMS QUANDO A VIA DE TRANSPORTE INTERNACIONAL FOR "MARÍTIMA"? VALORES:(S-SIM/N-NÃO(PADRÃO))',
         vsPD_CalcBaseIcmsAfrmm );
  Select nvl(indutilredcargatribdi,'N')
  into   vsIndUtilRedCargaTribDI
  From   Max_Paramgeral;
  if nvl(pnNroProcImport,0) = 0 then
      -- Cálculo do Valor Imposto de Importação (II)
      Vndespcomplii := 0;
      SELECT Nvl(SUM(e.Vlrtotdespcom), 0)
        INTO Vndespcomplii
        FROM Mad_Adicaodespesa e, Mad_Despesacompldi a, Mad_Didespesa d
       WHERE a.Seqdespacompl = d.Seqdespacompl
         AND e.Numerodi = d.Numerodi
         AND e.Seqdidespesa = d.Seqdidespesa
         AND a.Indconsiddespcompii = 'S'
         AND e.Nroadicao = Pnnroadicao
         AND d.Numerodi = Psnumerodi;
      vnBaseCalculoII := (pnVmcv + Vndespcomplii) * (1-(pnPerRedII / 100));
      pnVlrII := vnBaseCalculoII * pnAliqII/100;
  end if;
  -- ========== Cálculo IPI, PIS e COFINS com IPI ad valorem (% IPI) ================
  if nvl(pnNroProcImport,0) = 0 then
      -- Cálculo do IPI (ad valorem)
      vnDespComplIPI := 0;
      SELECT Nvl(SUM(e.Vlrtotdespcom), 0)
        INTO vnDespComplIPI
        FROM Mad_Adicaodespesa e, Mad_Despesacompldi a, Mad_Didespesa d
       WHERE a.Seqdespacompl = d.Seqdespacompl
         AND e.Numerodi = d.Numerodi
         AND e.Seqdidespesa = d.Seqdidespesa
         AND a.Indconsiddespcompipi = 'S'
         AND e.Nroadicao = Pnnroadicao
         AND d.Numerodi = Psnumerodi;
      vnBasCalcIpi := (pnVmcv + pnVlrII + vnDespComplIPI) * (1-(pnPerRedIpi / 100));
      pnVlrIpi := vnBasCalcIpi * pnAliqIpi/100;
  end if;
  -- Cálculo PIS (com IPI ad valorem)
  vnDespComplPIS := 0;
  SELECT Nvl(SUM(e.Vlrtotdespcom), 0)
    INTO vnDespComplPIS
    FROM Mad_Adicaodespesa e, Mad_Despesacompldi a, Mad_Didespesa d
   WHERE a.Seqdespacompl = d.Seqdespacompl
     AND e.Numerodi = d.Numerodi
     AND e.Seqdidespesa = d.Seqdidespesa
     AND a.Indconsiddespcomppis = 'S'
     AND e.Nroadicao = Pnnroadicao
     AND d.Numerodi = Psnumerodi;
  if vsPD_BaseCalcPisCofins = 'B'
  then
    vnBaseCalculoPis := ((pnVmcv + vnDespComplPIS) * ((1 + pnAliqIcms/100 * (pnAliqII/100 + pnAliqIpi/100 * (1+ pnAliqII/100 ))) /
                        ( (1 - pnAliqPis/100 - pnAliqCofins/100) * (1- pnAliqIcms/100)))) * (1-(pnPerRedPis / 100));
  else
    vnBaseCalculoPis := pnVmcv + vnDespComplPIS;
  end if;
  pnVlrPis := vnBaseCalculoPis * pnAliqPis/100;
  -- Cálculo COFINS (com IPI ad valorem)
  vnDespComplCOF := 0;
  SELECT Nvl(SUM(e.Vlrtotdespcom), 0)
    INTO vnDespComplCOF
    FROM Mad_Adicaodespesa e, Mad_Despesacompldi a, Mad_Didespesa d
   WHERE a.Seqdespacompl = d.Seqdespacompl
     AND e.Numerodi = d.Numerodi
     AND e.Seqdidespesa = d.Seqdidespesa
     AND a.Indconsiddespcompcof = 'S'
     AND e.Nroadicao = Pnnroadicao
     AND d.Numerodi = Psnumerodi;
  if vsPD_BaseCalcPisCofins = 'B'
  then
    vnBaseCalculoCofins := ((pnVmcv + vnDespComplCOF) * ((1 + pnAliqIcms/100 * (pnAliqII/100 + pnAliqIpi/100 * (1+ pnAliqII/100 ))) /
                                   ( (1 - pnAliqPis/100 - pnAliqCofins/100) * (1- pnAliqIcms/100)))) * (1-(pnPerRedCofins / 100));
  else
    vnBaseCalculoCofins := pnVmcv + vnDespComplCOF;
  end if;
  --
  pnVlrCofins := vnBaseCalculoCofins * pnAliqCofins/100;
  if nvl(pnNroProcImport,0) = 0 then
        -- ========== Cálculo IPI, PIS e COFINS com IPI alíquota específica (Pauta IPI) ================
        if pnVlrPautaIPI > 0 then
           -- Cálculo do IPI (pauta)
           pnVlrIpi := pnVlrPautaIPI;
           -- Cálculo PIS (com pauta IPI)
           if vsPD_BaseCalcPisCofins = 'B'
           then
             vnBaseCalculoPis := ((pnVmcv * (1 + pnAliqIcms/100 * pnAliqII/100) + pnAliqIcms/100 * (pnVlrPautaIPI)) /
                                            ((1 - pnAliqPis/100 - pnAliqCofins/100) * (1 - pnAliqIcms/100))) * (1-(pnPerRedPis / 100));
           else
             vnBaseCalculoPis := pnVmcv;
           end if;
           --
           pnVlrPis := vnBaseCalculoPis * pnAliqPis/100;
           -- Cálculo COFINS (com pauta IPI)
           if vsPD_BaseCalcPisCofins = 'B'
           then
             vnBaseCalculoCofins := ((pnVmcv * (1 + pnAliqIcms/100 * pnAliqII/100) + pnAliqIcms/100 * (pnVlrPautaIPI)) /
                                            ((1 - pnAliqPis/100 - pnAliqCofins/100) * (1 - pnAliqIcms/100))) * (1-(pnPerRedCofins / 100));
           else
             vnBaseCalculoCofins := pnVmcv;
           end if;
           --
           pnVlrCofins := vnBaseCalculoCofins * pnAliqCofins/100;
        end if;
        -- ========
        -- Cálculo ICMS (tanto com IPI ad valorem como com Pauta IPI)
        vnDespComplICMS := 0;
        SELECT NVL(SUM(e.Vlrtotdespcom),0)
           INTO vnDespComplICMS
           FROM Mad_Adicaodespesa e, Mad_Despesacompldi a, Mad_Didespesa d
          WHERE a.Seqdespacompl = d.Seqdespacompl
            AND e.Numerodi = d.Numerodi
            AND e.Seqdidespesa = d.Seqdidespesa
            AND a.Indconsiddespcompicms = 'S'
            AND e.Nroadicao = pnNroAdicao
            AND d.Numerodi = psNumeroDI;
        if vsIndUtilRedCargaTribDI = 'S' and pnPerRedCargaTr > 0 then -- 139082
            vnBaseIcms := pnVmcv + pnVlrDespAD + pnVlrII + pnVlrIpi + pnVlrPis + pnVlrCofins + vnDespComplICMS;
            if vsPD_CalcBaseIcmsAfrmm = 'S' then
               vnBaseIcms := vnBaseIcms + pnVlrAFRMM;
            end if;
            vnBaseIcms := vnBaseIcms / ((100-pnPerRedCargaTr)/100);
            vnBaseIcms := vnBaseIcms * (1-(nvl(pnPerRedIcms,100) / 100));
        else
            IF vsPD_CalcBaseIcmsAfrmm = 'S' THEN -- 131835
                vnBaseIcms := ((pnVmcv + pnVlrDespAD + pnVlrII + pnVlrIpi + pnVlrPis + pnVlrCofins + vnDespComplICMS + pnVlrAFRMM) / (1 - pnAliqIcms/100)) * (1-(nvl(pnPerRedIcms,100) / 100));
            ELSE
                vnBaseIcms := ((pnVmcv + pnVlrDespAD + pnVlrII + pnVlrIpi + pnVlrPis + pnVlrCofins + vnDespComplICMS) / (1 - pnAliqIcms/100)) * (1-(nvl(pnPerRedIcms,100) / 100));
            END IF;
        end if;
        pnVlrIcms := vnBaseIcms * pnAliqIcms/100;
        -- ========
        -- ICMS Substituição Tributária
         Vndespcomplicmsst := 0;
         SELECT NVL(SUM(e.Vlrtotdespcom),0)
           INTO Vndespcomplicmsst
           FROM Mad_Adicaodespesa e, Mad_Despesacompldi a, Mad_Didespesa d
          WHERE a.Seqdespacompl = d.Seqdespacompl
            AND e.Numerodi = d.Numerodi
            AND e.Seqdidespesa = d.Seqdidespesa
            AND a.Indconsiddespcompicmsst = 'S'
            AND e.Nroadicao = pnNroAdicao
            AND d.Numerodi = psNumeroDI;
        vnBaseIcmsST := vnBaseIcms;
        pnVlrIcmsST := (((( vnBaseIcmsST + Vndespcomplicmsst ) * (1 + pnPerAcrST/100) ) * pnAliqIcmsST/100) - pnVlrIcms) *  (1-(nvl(pnPerRedIcmsST,100) / 100));
        if pnVlrIcmsST < 0 then
           pnVlrIcmsST := 0;
        end if;
        vnBaseFCPST := vnBaseIcms;
        pnVlrFCPST := ( vnBaseFCPST + Vndespcomplicmsst ) * (1 + pnPerAcrST/100) * pnAliqFCPST/100;
        if pnVlrFCPST < 0 then
           pnVlrFCPST := 0;
        end if;
  End if;
END SP_CALCTRIBADICAO;
Procedure SP_RATEIOAUTOMADICAO(
          pnNumeroDI               in mad_di.numerodi%type,
          pnNroEmpresa             in mad_di.nroempresa%type,
          pnNroProcImport          in mad_piprocimportacao.nroprocimportacao%type )
is
  vnVlrII            mad_adicaoitem.vlrii%type := 0;
  vnVlrIPI           mad_adicaoitem.vlripi%type := 0;
  vnVlrPIS           mad_adicaoitem.vlrpis%type := 0;
  vnVlrCOFINS        mad_adicaoitem.vlrcofins%type := 0;
  vnVlrICMS          mad_adicaoitem.vlricms%type := 0;
  vnVlrICMSST        mad_adicaoitem.vlricmsst%type := 0;
  vnVlrFCPST         mad_adicaoitem.vlrfcpst%type := 0;
  vnVlrTotII         mad_adicaoitem.vlrii%type := 0;
  vnVlrTotIPI        mad_adicaoitem.vlripi%type := 0;
  vnVlrTotPIS        mad_adicaoitem.vlrpis%type := 0;
  vnVlrTotCOFINS     mad_adicaoitem.vlrcofins%type := 0;
  vnVlrTotICMS       mad_adicaoitem.vlricms%type := 0;
  vnVlrTotICMSST     mad_adicaoitem.vlricmsst%type := 0;
  vnVlrDespAd        mad_adicaoitem.vlrdespad%type := 0;
  vnVlrPautaIPI      mad_adicaoitem.vlripipauta%type := 0;
  vnTotValorAdicaoDI mad_adicao.vlrvmcv%type := 0;
  vnVlrDespForaDI    mad_adicaoitem.vlrdespforadi%type := 0;
  vnPercValor        number(19,6) := 0;
  vnPercValorVmld    number(19,6) := 0;
  vnVlrVmldTotal     mad_adicao.vlrvmcv%type := 0;
  vnVlrAFRMM         number := 0;
  vnVlrDiferRateio   mad_piresumodiproc.vlrtotinfpis%type := 0;
  vsPD_FmtRateioDesp varchar2(1) := 'T';
  vsPD_DigPautaIPI   varchar2(1) := 'N';
  vnPossuiPrevia     number := 0;
Begin
  -- Parametros dinamicos
  PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'PROC_IMPORTACAO', pnNroEmpresa, 'FMT_CALC_RATEIO_DESP', 'S', 'T',
  'Formato de rateio que deverá ser utilizado para cálculo do custo do produto na simulação e na geração da D.I.
   T => Rateio pelo valor total do item
   U => Rateio pelo valor unitário do item.', vsPD_FmtRateioDesp );
  PKG_MLF_RECEBIMENTO.SP_BUSCAPARAMETRODINAMICO( 'PROC_IMPORTACAO', pnNroEmpresa, 'DIG_PAUTAIPI_PEDIMP', 'S', 'N',
  'Permitir digitar o valor da Pauta de IPI na Simulação / Pedido de Importaçao ?
   N - Não ( Default )
   S - Sim', vsPD_DigPautaIPI );
  --
  BEGIN
   SELECT 1
     INTO vnPossuiPrevia
     FROM MAD_PREVADICAO A,
          MAD_PREVADICAOITEM B
    WHERE A.SEQPREVADICAO = B.SEQPREVADICAO
      AND A.NUMERODI = pnNumeroDI
      AND ROWNUM = 1;
  EXCEPTION
   WHEN NO_DATA_FOUND
   THEN vnPossuiPrevia := 0;
  END;
  IF vnPossuiPrevia = 1 THEN
    INSERT INTO MAD_ADICAO( NROADICAO, NUMERODI, SEQFORNECEDOR, CODNBMSH, VLRVMCV )
    SELECT D.NROADICAO,
           D.NUMERODI,
           D.SEQFORNECEDOR,
           D.CODNBMSH,
           NVL(SUM((C.VLRITEM * B.TXCAMBIO ) * ( G.QUANTIDADE / G.QTDEMBALAGEM)), 0) AS VLRVMCV
      FROM MAD_PREVADICAO D, MAD_PIPEDIDOIMPORT B, MAD_PIPEDIMPORTPROD C,
           MAP_FAMILIA E, MAP_PRODUTO F, MAD_PREVADICAOITEM G
     WHERE D.SEQFORNECEDOR     = B.SEQFORNECEDOR
       AND D.NROPROCIMPORTACAO = B.NROPROCIMPORTACAO
       AND B.SEQPEDIDOIMPORT   = C.SEQPEDIDOIMPORT
       AND D.CODNBMSH          = E.CODNBMSH
       AND E.SEQFAMILIA        = F.SEQFAMILIA
       AND F.SEQPRODUTO        = C.SEQPRODUTO
       AND D.SEQPREVADICAO     = G.SEQPREVADICAO
       AND G.SEQPRODUTO        = C.SEQPRODUTO
       AND B.NROPROCIMPORTACAO = pnNroProcImport
       AND B.NROEMPRESA        = pnNroEmpresa
     GROUP BY D.NROADICAO, D.NUMERODI, D.SEQFORNECEDOR, D.CODNBMSH;
    INSERT INTO MAD_ADICAOITEM( NROADICAO, NUMERODI, SEQPRODUTO, QUANTIDADE, QTDEMBALAGEM,
                                QTDEITEMDI, VLRVUCVIMPDI, VLRVUCV, SEQPEDIDOIMPORT,
                                VLRFRETE, VLRSEGURO, VLRDESPAD, VLRSISCOMEX, VLRII,
                                VLRPIS, VLRCOFINS, VLRIPI, VLRICMS, VLRICMSST, VLRFCPST,
                                VLRDESPFORADI )
    SELECT A.NROADICAO,
           A.NUMERODI,
           C.SEQPRODUTO,
           (C.QUANTIDADE / C.QTDEMBALAGEM) AS QUANTIDADE,
           C.QTDEMBALAGEM,
           (C.QUANTIDADE / C.QTDEMBALAGEM ) AS QTDEITEMDI,
           E.VLRITEM,
           ((E.VLRITEM * D.TXCAMBIO ) / C.QTDEMBALAGEM ) AS VLRVUCV,
           E.SEQPEDIDOIMPORT,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      FROM MAD_ADICAO A, MAD_PREVADICAO B, MAD_PREVADICAOITEM C, MAD_PIPEDIDOIMPORT D, MAD_PIPEDIMPORTPROD E
     WHERE A.NUMERODI          = B.NUMERODI
       AND A.NROADICAO         = B.NROADICAO
       AND A.SEQFORNECEDOR     = B.SEQFORNECEDOR
       AND B.SEQPREVADICAO     = C.SEQPREVADICAO
       AND E.SEQPRODUTO        = C.SEQPRODUTO
       AND D.SEQPEDIDOIMPORT   = E.SEQPEDIDOIMPORT
       AND D.NROPROCIMPORTACAO = B.NROPROCIMPORTACAO
       AND D.SEQFORNECEDOR     = B.SEQFORNECEDOR
       AND D.NROEMPRESA        = B.NROEMPRESA
       AND B.NROPROCIMPORTACAO = pnNroProcImport
       AND B.NROEMPRESA        = pnNroEmpresa;
  ELSE
    insert into mad_adicao( nroadicao, numerodi, seqfornecedor, codnbmsh, vlrvmcv, aliqpis, aliqcofins )
    select d.nroadicao, d.numerodi, d.seqfornecedor, d.codnbmsh,
           nvl(sum((c.vlritem * d.txcambio ) * ( c.qtdsolicitada / c.qtdembalagem)), 0),
           d.perpis, d.percofins
    from   mad_auxdi d, mad_pipedidoimport b, mad_pipedimportprod c,
           map_familia e, map_produto f
    where  d.seqfornecedor     = b.seqfornecedor
    and    b.seqpedidoimport   = c.seqpedidoimport
    and    d.qtdembalagem      = c.qtdembalagem
    and    d.codnbmsh          = e.codnbmsh
    and    e.seqfamilia        = f.seqfamilia
    and    f.seqproduto        = c.seqproduto
    and    b.nroprocimportacao = pnNroProcImport
    and    b.nroempresa        = pnNroEmpresa
    group by d.nroadicao, d.numerodi, d.seqfornecedor, d.codnbmsh, d.perpis, d.percofins;
    insert into mad_adicaoitem( nroadicao, numerodi, seqproduto, quantidade, qtdembalagem,
                                qtdeitemdi, vlrvucvimpdi, vlrvucv,
                                vlrfrete, vlrseguro, vlrdespad, vlrsiscomex, vlrii,
                                vlrpis, vlrcofins, vlripi, vlricms, vlricmsst, vlrfcpst,
                                Vlrdespforadi,seqpedidoimport )
    select a.nroadicao, a.numerodi, c.seqproduto,( c.qtdsolicitada / c.qtdembalagem ), c.qtdembalagem,
           ( c.qtdsolicitada / c.qtdembalagem ), c.vlritem, ((c.vlritem * b.txcambio ) / c.qtdembalagem ),
           0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0,
           0,c.seqpedidoimport
    from   mad_adicao a, mad_auxdi d, mad_pipedidoimport b, mad_pipedimportprod c,
           map_familia e, map_produto f, mad_piresumodiproc g
    where  a.numerodi          = d.numerodi
    and    a.nroadicao         = d.nroadicao
    and    a.seqfornecedor     = d.seqfornecedor
    and    a.seqfornecedor     = b.seqfornecedor
    and    b.seqpedidoimport   = c.seqpedidoimport
    and    d.qtdembalagem      = c.qtdembalagem
    and    d.codnbmsh          = e.codnbmsh
    and    e.seqfamilia        = f.seqfamilia
    and    f.seqproduto        = c.seqproduto
    and    a.numerodi          = g.numerodi
    and    nvl(c.fabricante, 0)= nvl(d.fabricante, 0)
    and    b.nroprocimportacao = pnNroProcImport
    and    b.nroempresa        = pnNroEmpresa;
  END IF;
  update mad_adicao a set
         a.pesoliquido = ( select sum(b.quantidade * d.pesoliquido)
                           from   mad_adicaoitem b, map_produto c, map_famembalagem d
                           where  a.numerodi  = b.numerodi
                           and    a.nroadicao = b.nroadicao
                           and    b.seqproduto = c.seqproduto
                           and    c.seqfamilia = d.seqfamilia
                           and    b.qtdembalagem = d.qtdembalagem
                           and    b.numerodi   = pnNumeroDI )
  where  a.numerodi   = pnNumeroDI
  and    exists( select  1 from mad_adicaoitem b
                 where   a.numerodi  = b.numerodi
                 and     a.nroadicao = b.nroadicao );
  SP_RATEIOADICAOITEM( pnNumeroDI );
  -- Rateio dos valores das despesas e dos impostos por item de acordo com os lançamentos
  select decode( vsPD_FmtRateioDesp, 'T',
                 sum(nvl(i.vlrvucv,0) * nvl(i.qtdembalagem,0) * nvl(i.quantidade,0)),
                 sum(nvl(i.vlrvucv,0)) ),
         sum((nvl(i.vlrvucv,0) * nvl(i.qtdembalagem,0) * nvl(i.quantidade,0)) + i.vlrfrete + i.vlrcapatazia + i.vlrseguro )
  into   vnTotValorAdicaoDI,
         vnVlrVmldTotal
  from   mad_adicaoitem i
  where  i.numerodi = pnNumeroDI;
  select nvl(round(sum(pr.vlrimpimport),2),1), nvl(round(sum(pr.vlrpis),6),1), nvl(round(sum(pr.vlrcofins),6),1),
         nvl(round(sum(pr.vlripi),2),1), nvl(round(sum(pr.vlricms),2),1), nvl(round(sum(pr.vlricmsst),2),1)
  into   vnVlrTotII, vnVlrTotPIS, vnVlrTotCOFINS,
         vnVlrTotIPI, vnVlrTotICMS, vnVlrTotICMSST
  from   mad_pipedidoimport pe, mad_pipedimportprod pr
  where  pe.seqpedidoimport   = pr.seqpedidoimport
  and    pe.nroprocimportacao = pnNroProcImport
  and    pe.nroempresa        = pnNroEmpresa;
  for vtblAdicaoItem in ( select c.nroadicao, c.seqproduto, c.vlrvucv, c.qtdembalagem,
                                 c.quantidade, nvl(b.vlripipauta,0) vlripipauta, a.vlrtotdespad,
                                 a.vlrtotdespforadi, a.nroempresa,
                                 a.vlrtotii, a.vlrtotpis, a.vlrtotcofins,
                                 a.vlrtotipi, a.vlrtoticms, a.vlrtoticmsst, a.vlrtotfcpst,
                                 c.vlrfrete, c.vlrcapatazia, c.vlrseguro,
                                 c.vlrsiscomex, b.seqfornecedor,
                                 a.indutilfretebasecalc, a.indutilsegurobasecalc,
                                 a.indutilcapataziabasecalc, d.uf,c.vlrafrmm,
                                 a.incidebasetribiimpfrete,a.incidebasetribipifrete,
                                 a.incidebasetribpisfrete,a.incidebasetribcofinsfrete,
                                 a.incidebasetribicmsfrete,a.incidebasetribiimpseg,
                                 a.incidebasetribipiseg,a.incidebasetribpisseg,
                                 a.incidebasetribcofinsseg,a.incidebasetribicmsseg,
                                 a.incidebasetribiimpctz,a.incidebasetribipictz,
                                 a.incidebasetribpisctz,a.incidebasetribcofinsctz,
                                 a.incidebasetribicmsctz
                          from   mad_di a, mad_adicao b, mad_adicaoitem c, ge_cidade d
                          where  a.numerodi    = b.numerodi
                          and    b.numerodi    = c.numerodi
                          and    b.nroadicao   = c.nroadicao
                          and    a.seqcidadead = d.seqcidade
                          and    b.numerodi    = pnNumeroDI
                          order by c.nroadicao )
  loop
      -- Cálculo do percentual de rateio
      -- Percentual do VMLE
      if ( vsPD_FmtRateioDesp =  'T' ) then
         vnPercValor := (( vtblAdicaoItem.vlrvucv * vtblAdicaoItem.Qtdembalagem * vtblAdicaoItem.Quantidade ) / vnTotValorAdicaoDI );
      else
         vnPercValor := ( vtblAdicaoItem.vlrvucv / vnTotValorAdicaoDI );
      end if;
      --
      -- Percentual de VMLD
      vnPercValorVmld := ((( vtblAdicaoItem.vlrvucv * vtblAdicaoItem.Qtdembalagem * vtblAdicaoItem.Quantidade ) + vtblAdicaoItem.Vlrfrete +
                             vtblAdicaoItem.Vlrcapatazia + vtblAdicaoItem.Vlrseguro ) / vnVlrVmldTotal );
      --
      vnVlrDespForaDI := vnPercValorVmld * vtblAdicaoItem.Vlrtotdespforadi;
      vnVlrDespAd := vnPercValorVmld * vtblAdicaoItem.vlrtotdespad;
      if ( vsPD_DigPautaIPI = 'S' ) then
        select nvl(max(pp.vlrpautaipi),0) into vnVlrPautaIPI
        from   mad_pipedidoimport pi, mad_pipedimportprod pp
        where  pi.seqpedidoimport     = pp.seqpedidoimport
        and    pi.nroprocimportacao   = pnNroProcImport
        and    pi.nroempresa          = pnNroEmpresa
        and    pp.seqproduto          = vtblAdicaoItem.Seqproduto;
      else
        select nvl(max(a.vlripipauta),0)
        into   vnVlrPautaIPI
        from   map_familia a
        where  seqfamilia in (select seqfamilia from map_produto
                              where  seqproduto = vtblAdicaoItem.Seqproduto);
      end if;
      --
      SP_CALCTRIBADICAOITEM(
                          vtblAdicaoItem.Seqproduto, pnNroEmpresa, vtblAdicaoItem.Vlrvucv,
                          (vtblAdicaoItem.Quantidade * vtblAdicaoItem.Qtdembalagem),
                          vtblAdicaoItem.Seqfornecedor, vnVlrPautaIPI, NVL(vtblAdicaoItem.vlrafrmm,vnVlrAFRMM),
                          vtblAdicaoItem.Vlrfrete, vtblAdicaoItem.Vlrcapatazia, vtblAdicaoItem.Vlrseguro,
                          (vnVlrDespAd + vtblAdicaoItem.Vlrsiscomex),
                          0, 0,
                          vtblAdicaoItem.Indutilfretebasecalc, vtblAdicaoItem.Indutilsegurobasecalc,
                          vtblAdicaoItem.Indutilcapataziabasecalc, 'xx', 'N'
                          ,vtblAdicaoItem.incidebasetribiimpfrete,vtblAdicaoItem.incidebasetribipifrete,
                          vtblAdicaoItem.incidebasetribpisfrete,vtblAdicaoItem.incidebasetribcofinsfrete,
                          vtblAdicaoItem.incidebasetribicmsfrete,vtblAdicaoItem.incidebasetribiimpseg,
                          vtblAdicaoItem.incidebasetribipiseg,vtblAdicaoItem.incidebasetribpisseg,
                          vtblAdicaoItem.incidebasetribcofinsseg,vtblAdicaoItem.incidebasetribicmsseg,
                          vtblAdicaoItem.incidebasetribiimpctz,vtblAdicaoItem.incidebasetribipictz,
                          vtblAdicaoItem.incidebasetribpisctz,vtblAdicaoItem.incidebasetribcofinsctz,
                          vtblAdicaoItem.incidebasetribicmsctz
                          );
      Select nvl(max(vlrimpostoimport),0), nvl(max(vlripi),0), nvl(max(vlrpis),0), nvl(max(vlrcofins),0),
		         nvl(max(vlricms),0), nvl(max(vlricmsst),0), nvl(max(vlrfcpst),0)
      into   vnVlrII, vnVlrIPI, vnVlrPIS, vnVlrCOFINS,
             vnVlrICMS, vnVlrICMSST, vnVlrFCPST
      From 	 mrlx_calctribitem;
      --
      if ( vnVlrPautaIPI > 0 ) then
         vnVlrIPI := (vnVlrPautaIPI * (vtblAdicaoItem.Qtdembalagem * vtblAdicaoItem.Quantidade));
         vnVlrPautaIPI := vnVlrIPI;
      else
        vnVlrPautaIPI := 0;
      end if;
      --
      update mad_adicaoitem set
             vlrii     = vnVlrII,
             vlrpis    = vnVlrPIS,
             vlrcofins = vnVlrCOFINS,
             vlripi    = vnVlrIPI,
             vlricms   = vnVlrICMS,
             vlricmsst = vnVlrICMSST,
             vlrfcpst  = vnVlrFCPST,
             vlripipauta   = vnVlrPautaIPI,
             vlrdespad     = vnVlrDespAd,
             vlrdespforadi = vnVlrDespForaDI
      where  numerodi      = pnNumeroDI
      and    nroadicao     = vtblAdicaoItem.Nroadicao
      and    seqproduto    = vtblAdicaoItem.Seqproduto;
  end loop;
  -- Final do processo de rateio
  -- Atualização do Valores de Impostos
  update mad_di a set
         ( a.vlrtotii, a.vlrtotpis, a.vlrtotcofins, a.vlrtotipi, a.vlrtoticms, a.vlrtoticmsst, a.vlrtotfcpst,
           a.vlrtotdespforadi, a.vlrvmle ) =
         ( select nvl(sum(b.vlrii),0), nvl(sum(b.vlrpis),0), nvl(sum(b.vlrcofins),0), nvl(sum(b.vlripi),0),
                  nvl(sum(b.vlricms),0), nvl(sum(b.vlricmsst),0), nvl(sum(b.vlrfcpst),0), nvl(sum(b.vlrdespforadi),0),
                  nvl(sum(b.vlrvucv * b.qtdembalagem * b.qtdeitemdi),0)
           from   mad_adicaoitem b
           where  a.numerodi  = b.numerodi
           and    b.numerodi   = pnNumeroDI ),
         a.pesobruto = ( select sum(b.quantidade * d.pesobruto)
                         from   mad_adicaoitem b, map_produto c, map_famembalagem d
                         where  a.numerodi  = b.numerodi
                         and    b.seqproduto = c.seqproduto
                         and    c.seqfamilia = d.seqfamilia
                         and    b.qtdembalagem = d.qtdembalagem
                         and    b.numerodi   = pnNumeroDI ),
         a.pesoliquido = ( select sum(b.quantidade * d.pesoliquido)
                           from   mad_adicaoitem b, map_produto c, map_famembalagem d
                           where  a.numerodi  = b.numerodi
                           and    b.seqproduto = c.seqproduto
                           and    c.seqfamilia = d.seqfamilia
                           and    b.qtdembalagem = d.qtdembalagem
                           and    b.numerodi   = pnNumeroDI )
  where  a.numerodi   = pnNumeroDI
  and    exists( select  1 from mad_adicaoitem b
                 where   a.numerodi  = b.numerodi );
  update mad_adicao a set
       ( a.vlrfrete, a.vlrseguro, a.vlrsiscomex, a.vlrcapatazia, a.vlrdespforadi, a.vlrvmcv ) =
       ( select   nvl(sum(b.vlrfrete),0), nvl(sum(b.vlrseguro),0), nvl(sum(b.vlrsiscomex),0),
                  nvl(sum(b.vlrcapatazia),0), nvl(sum(b.vlrdespforadi),0),
                  nvl(sum(b.vlrvucv * b.qtdembalagem * b.qtdeitemdi),0)
         from     mad_adicaoitem b
         where    a.numerodi  = b.numerodi
         and      a.nroadicao = b.nroadicao
         and      b.numerodi   = pnNumeroDI ),
       ( a.vlrii, a.vlrpis, a.vlrcofins, a.vlripi, a.vlricms, a.vlricmsst, a.vlrfcpst, a.vlripipauta, a.vlrdespad ) =
       ( select   nvl(sum(b.vlrii),0), nvl(sum(b.vlrpis),0), nvl(sum(b.vlrcofins),0), nvl(sum(b.vlripi),0),
                  nvl(sum(b.vlricms),0), nvl(sum(b.vlricmsst),0), nvl(sum(b.vlrfcpst),0), nvl(sum(b.vlripipauta),0),
                  nvl(sum(b.vlrdespad), 0)
         from     mad_adicaoitem b
         where    a.numerodi  = b.numerodi
         and      a.nroadicao = b.nroadicao
         and      b.numerodi   = pnNumeroDI )
  where  a.numerodi   = pnNumeroDI
  and    exists( select  1 from mad_adicaoitem b
                 where   a.numerodi  = b.numerodi
                 and     a.nroadicao = b.nroadicao );
  update mad_piresumodiproc a set
         (a.vlrinfvmle,a.vlrtotinfii,a.vlrtotinfpis,a.vlrtotinfcofins,a.vlrtotinfipi,a.vlrtotinficms,a.vlrtotinficmsst) =
         ( select vlrvmle,vlrtotii,vlrtotpis,vlrtotcofins,vlrtotipi,vlrtoticms,vlrtoticmsst
           from   mad_di
           where  a.numerodi = mad_di.numerodi
           and    a.nroprocimportacao = mad_di.nroprocimportacao
           and    a.nroempresa        = mad_di.nroempresa
           and    mad_di.numerodi     = pnNumeroDI
           and    mad_di.nroempresa   = pnNroEmpresa ),
         a.vlrtotinfdespforadi = a.vlrtotinfdespforadi + (
                     case when (a.vlrtotii + a.vlrtotpis + a.vlrtotcofins + a.vlrtotipi + a.vlrtoticms + a.vlrtoticmsst) >
                             (select nvl(sum(vlrtotii + vlrtotpis + vlrtotcofins + vlrtotipi + vlrtoticms + vlrtoticmsst),0)
                              from   mad_di
                              where  a.numerodi          = mad_di.numerodi
                              and    a.nroprocimportacao = mad_di.nroprocimportacao
                              and    a.nroempresa        = mad_di.nroempresa
                              and    mad_di.numerodi     = pnNumeroDI
                              and    mad_di.nroempresa   = pnNroEmpresa ) then
                             (a.vlrtotii + a.vlrtotpis + a.vlrtotcofins + a.vlrtotipi + a.vlrtoticms + a.vlrtoticmsst) -
                             (select nvl(sum(vlrtotii + vlrtotpis + vlrtotcofins + vlrtotipi + vlrtoticms + vlrtoticmsst),0)
                              from   mad_di
                              where  a.numerodi          = mad_di.numerodi
                              and    a.nroprocimportacao = mad_di.nroprocimportacao
                              and    a.nroempresa        = mad_di.nroempresa
                              and    mad_di.numerodi     = pnNumeroDI
                              and    mad_di.nroempresa   = pnNroEmpresa )
                      else
                        0
                      end )
  where  a.numerodi           = pnNumeroDI
  and    a.nroprocimportacao  = pnNroProcImport
  and    a.nroempresa         = pnNroEmpresa
  and    exists( select 1 from mad_di
         where   a.numerodi = mad_di.numerodi
         and     a.nroprocimportacao = mad_di.nroprocimportacao
         and     a.nroempresa        = mad_di.nroempresa );
  --
  -- Faz o rateio das despesas fora DI
  select nvl(sum((vlrtotii + vlrtotpis + vlrtotcofins + vlrtotipi + vlrtoticms + vlrtoticmsst) -
         (vlrtotinfii + vlrtotinfpis + vlrtotinfcofins + vlrtotinfipi + vlrtotinficms + vlrtotinficmsst)),0)
  into   vnVlrDiferRateio
  from   mad_piresumodiproc
  where  numerodi            = pnNumeroDI
  and    nroprocimportacao   = pnNroProcImport
  and    nroempresa          = pnNroEmpresa
  and   (vlrtotii + vlrtotpis + vlrtotcofins + vlrtotipi + vlrtoticms + vlrtoticmsst) >
        (vlrtotinfii + vlrtotinfpis + vlrtotinfcofins + vlrtotinfipi + vlrtotinficms + vlrtotinficmsst);
  if ( vnVlrDiferRateio > 0 ) then
    for vtblRatDespFora in ( select seqproduto, nroadicao,
                                  (((vlrvucv * qtdembalagem * quantidade) +
                                   (vlrfrete + vlrcapatazia + vlrseguro)) / vnVlrVmldTotal) vrlPercDespAd
                             from   mad_adicaoitem
                             where  numerodi          = pnNumeroDI )
    loop
       vnVlrDespForaDI := (vnVlrDiferRateio * vtblRatDespFora.vrlPercDespAd);
       update mad_adicaoitem set vlrdespforadi = vlrdespforadi + vnVlrDespForaDI
       where  numerodi   = pnNumeroDI
       and    nroadicao  = vtblRatDespFora.Nroadicao
       and    seqproduto = vtblRatDespFora.Seqproduto;
    end loop;
  end if;
  -- Marca os valores de lançamentos utilizados para gerar a D.I.
  update mad_pilanctopagtodesp set utzgeracaodi = 'S',
                                   indlanctocontab = 'S'
  where  nroprocimportacao     = pnNroProcImport
  and    nroempresa        	   = pnNroEmpresa
  and    indprevpagto          = 'P'
  and    indcreditodebito      = 'D'
  and    indsituacao not in ('PV','PA','A')
  and    seqtitulo is not null
  and    nvl(utzgeracaodi,'N') = 'N';
  update mad_pilanctopagtodesp a set a.utzgeracaodi = 'S',
                                     a.indlanctocontab = 'S'
  where  a.nroprocimportacao     = pnNroProcImport
  and    a.nroempresa            = pnNroEmpresa
  and    a.indcreditodebito      = 'D'
  and    nvl(a.utzgeracaodi,'N') = 'N'
  and    exists(select 1 from mad_pitipoadiantamento b
                where  a.seqtipoadiant = b.seqtipoadiant
                and    b.inddespesatributo = 'VME');
  --
  exception
        when others then
        raise_application_error (-20200, sqlerrm );
end SP_RATEIOAUTOMADICAO;
FUNCTION Fcalculadespcompdi(Psnumerodi IN Mad_Di.Numerodi%TYPE,
                            Pnnroadicao IN Mad_Adicao.Nroadicao%TYPE DEFAULT NULL,
                            Pnseqproduto IN Mad_Adicaoitem.Seqproduto%TYPE DEFAULT NULL,
                            Pnincdespnf IN Mad_Despesacompldi.Incdespnota%TYPE DEFAULT 'T'
                            -- D - Desp. Tributada -- F - Frete -- T - Todas
                            ) RETURN NUMBER IS
  Vnvalordespret NUMBER;
BEGIN
  SELECT Nvl(SUM(b.Vlrtotdespcom), 0)
    INTO Vnvalordespret
    FROM Mad_Adicaodespesa e, Mad_Despesacompldi a, Mad_Didespesa d,
         Mad_Adicaoitemdesp b
   WHERE a.Seqdespacompl = d.Seqdespacompl
     AND d.Seqdidespesa = e.Seqdidespesa
     AND d.Numerodi = e.Numerodi
     AND b.Seqadicdespesa = e.Seqadicdespesa
     AND b.Nroadicao = e.Nroadicao
     AND b.Numerodi = e.Numerodi
     AND a.Incdespnota =
         Decode(Pnincdespnf, 'D', 'D', 'F', 'F', a.Incdespnota)
     AND b.Seqproduto = Nvl(Pnseqproduto, b.Seqproduto)
     AND b.Nroadicao = Nvl(Pnnroadicao, b.Nroadicao)
     AND b.Numerodi = Psnumerodi;
  RETURN(Vnvalordespret);
END Fcalculadespcompdi;
PROCEDURE SP_GRAVAPREVADICAO(pnNroProcImportacao IN MAD_PIPEDIDOIMPORT.NROPROCIMPORTACAO%TYPE)
IS
  tSP_MAD_PREVADICAO MAD_PREVADICAO%ROWTYPE;
BEGIN
  FOR VT IN (SELECT
                    A.NROEMPRESA,
                    ROW_NUMBER() OVER ( PARTITION BY A.NROEMPRESA
                                        ORDER BY A.NROEMPRESA, D.CODNBMSH, A.SEQFORNECEDOR) AS NROADICAO,
                    D.CODNBMSH,
                    A.SEQFORNECEDOR,
                    C.FABRICANTE,
                    MAX(A.TXCAMBIO) TXCAMBIO,
                    MAX(A.MOEDA) MOEDA
            FROM MAD_PIPEDIDOIMPORT A, MAD_PIPROCIMPORTACAO B, MAD_PIPEDIMPORTPROD C, MAP_FAMILIA D
         WHERE   A.NROPROCIMPORTACAO = B.NROPROCIMPORTACAO
               AND  A.SEQPEDIDOIMPORT = C.SEQPEDIDOIMPORT
               AND  C.SEQFAMILIA = D.SEQFAMILIA
               AND  A.NROPROCIMPORTACAO   = pnNroProcImportacao
                  GROUP BY  A.NROEMPRESA, D.CODNBMSH, A.SEQFORNECEDOR, C.FABRICANTE, A.TXCAMBIO
                  ORDER BY  A.NROEMPRESA, D.CODNBMSH, A.SEQFORNECEDOR
                )
         LOOP
            tSP_MAD_PREVADICAO.NROEMPRESA        := VT.NROEMPRESA;
            tSP_MAD_PREVADICAO.NROPROCIMPORTACAO := pnNroProcImportacao;
            tSP_MAD_PREVADICAO.NROADICAO         := VT.NROADICAO;
            tSP_MAD_PREVADICAO.CODNBMSH          := VT.CODNBMSH;
            tSP_MAD_PREVADICAO.SEQFORNECEDOR     := VT.SEQFORNECEDOR;
            tSP_MAD_PREVADICAO.FABRICANTE        := VT.FABRICANTE;
            tSP_MAD_PREVADICAO.TXCAMBIO          := VT.TXCAMBIO;
            tSP_MAD_PREVADICAO.MOEDA             := VT.MOEDA;
            SP_INSEREADICAO(tSP_MAD_PREVADICAO);
         END LOOP;
END SP_GRAVAPREVADICAO;
PROCEDURE SP_GRAVAPREVADICAOITEM(PNNROPROCIMPORTACAO IN MAD_PIPEDIDOIMPORT.NROPROCIMPORTACAO%TYPE)
IS
  TSP_MAD_PREVADICAOITEM MAD_PREVADICAOITEM%ROWTYPE;
BEGIN
  FOR VT IN (SELECT X.SEQPREVADICAO                SEQPREVADICAO,
                    C.SEQPRODUTO                   SEQPRODUTO,
                    C.QTDSOLICITADA                QUANTIDADE,
                    C.QTDEMBALAGEM                 QTDEMBALAGEM
             FROM MAD_PIPEDIMPORTPROD C, MAP_FAMILIA D, MAP_PRODUTO E,
                  MAP_FAMEMBALAGEM F, MAD_PIPEDIDOIMPORT G, MAD_PREVADICAO X
             WHERE C.SEQPEDIDOIMPORT = G.SEQPEDIDOIMPORT
              AND C.SEQFAMILIA = D.SEQFAMILIA
              AND C.SEQPRODUTO = E.SEQPRODUTO
              AND C.SEQFAMILIA = F.SEQFAMILIA
              AND C.QTDEMBALAGEM = F.QTDEMBALAGEM
              AND X.NROPROCIMPORTACAO = G.NROPROCIMPORTACAO
              AND X.NROEMPRESA = G.NROEMPRESA
              AND X.CODNBMSH = D.CODNBMSH
              AND X.SEQFORNECEDOR = G.SEQFORNECEDOR
              AND G.NROPROCIMPORTACAO = PNNROPROCIMPORTACAO
            ORDER BY X.SEQPREVADICAO, C.SEQPRODUTO)
         LOOP
            TSP_MAD_PREVADICAOITEM.SEQPREVADICAO := VT.SEQPREVADICAO;
            TSP_MAD_PREVADICAOITEM.SEQPRODUTO    := VT.SEQPRODUTO;
            TSP_MAD_PREVADICAOITEM.QUANTIDADE    := VT.QUANTIDADE;
            TSP_MAD_PREVADICAOITEM.QTDEMBALAGEM  := VT.QTDEMBALAGEM;
            SP_INSEREPREVADICAOITEM(TSP_MAD_PREVADICAOITEM);
         END LOOP;
END SP_GRAVAPREVADICAOITEM;
PROCEDURE SP_INSEREADICAO(tSP_MAD_PREVADICAO IN MAD_PREVADICAO%ROWTYPE )
IS
 vnSeqPrevAdicao MAD_PREVADICAO.SEQPREVADICAO%type;
BEGIN
   SELECT S_MAD_PREVADICAO.NEXTVAL
     INTO vnSeqPrevAdicao
     FROM DUAL;
   INSERT INTO MAD_PREVADICAO
   (
        SEQPREVADICAO,
        NROEMPRESA,
        NROADICAO,
        CODNBMSH,
        SEQFORNECEDOR,
        FABRICANTE,
        NROPROCIMPORTACAO,
        TXCAMBIO,
        MOEDA
   )
   VALUES
   (
        vnSeqPrevAdicao,
        tSP_MAD_PREVADICAO.NROEMPRESA,
        tSP_MAD_PREVADICAO.NROADICAO,
        tSP_MAD_PREVADICAO.CODNBMSH,
        tSP_MAD_PREVADICAO.SEQFORNECEDOR,
        tSP_MAD_PREVADICAO.FABRICANTE,
        tSP_MAD_PREVADICAO.NROPROCIMPORTACAO,
        tSP_MAD_PREVADICAO.TXCAMBIO,
        tSP_MAD_PREVADICAO.MOEDA
   );
   COMMIT;
END SP_INSEREADICAO;
PROCEDURE SP_INSEREPREVADICAOITEM(TSP_MAD_PREVADICAOITEM IN MAD_PREVADICAOITEM%ROWTYPE )
IS
 vnSeqPrevAdicaoItem MAD_PREVADICAOITEM.SEQPREVADICAOITEM%TYPE;
 vnQuantidadeItemExistente MAD_PREVADICAOITEM.QUANTIDADE%TYPE;
BEGIN
   SELECT NVL(MAX(B.QUANTIDADE), 0)
   INTO vnQuantidadeItemExistente
   FROM MAD_PREVADICAO A, MAD_PREVADICAOITEM B
   WHERE A.SEQPREVADICAO = B.SEQPREVADICAO
     AND A.SEQPREVADICAO = TSP_MAD_PREVADICAOITEM.SEQPREVADICAO
     AND B.SEQPRODUTO = TSP_MAD_PREVADICAOITEM.SEQPRODUTO;
   IF vnQuantidadeItemExistente > 0 THEN
   DELETE FROM MAD_PREVADICAOITEM B
   WHERE B.SEQPREVADICAO = TSP_MAD_PREVADICAOITEM.SEQPREVADICAO
     AND B.SEQPRODUTO = TSP_MAD_PREVADICAOITEM.SEQPRODUTO;
   COMMIT;
   END IF;
   vnQuantidadeItemExistente := vnQuantidadeItemExistente + TSP_MAD_PREVADICAOITEM.QUANTIDADE;
   SELECT S_MAD_PREVADICAOITEM.NEXTVAL
     INTO vnSeqPrevAdicaoItem
     FROM DUAL;
   INSERT INTO MAD_PREVADICAOITEM
   (
        SEQPREVADICAOITEM,
        SEQPREVADICAO,
        SEQPRODUTO,
        QUANTIDADE,
        QTDEMBALAGEM
     )
    VALUES
    (
        vnSeqPrevAdicaoItem,
        TSP_MAD_PREVADICAOITEM.SEQPREVADICAO,
        TSP_MAD_PREVADICAOITEM.SEQPRODUTO,
        vnQuantidadeItemExistente,
        TSP_MAD_PREVADICAOITEM.QTDEMBALAGEM
    );
    COMMIT;
END SP_INSEREPREVADICAOITEM;
PROCEDURE SP_PROCEXCLUIADICAO(tSP_MAD_PREVADICAO IN MAD_PREVADICAO%ROWTYPE )
IS
 tSP_MAD_PREVADICAOITEM MAD_PREVADICAOITEM%ROWTYPE;
BEGIN
   FOR VT IN (SELECT A.NROADICAO,
                     A.NROPROCIMPORTACAO,
                     A.SEQFORNECEDOR,
                     B.SEQPREVADICAOITEM,
                     B.SEQPRODUTO
                FROM MAD_PREVADICAO A, MAD_PREVADICAOITEM B
               WHERE A.SEQPREVADICAO     = B.SEQPREVADICAO
                 AND A.NROADICAO         = tSP_MAD_PREVADICAO.NROADICAO
                 AND A.NROPROCIMPORTACAO = tSP_MAD_PREVADICAO.NROPROCIMPORTACAO
                 AND A.SEQFORNECEDOR     = tSP_MAD_PREVADICAO.SEQFORNECEDOR
   )LOOP
     tSP_MAD_PREVADICAOITEM.SEQPREVADICAOITEM := VT.SEQPREVADICAOITEM;
     tSP_MAD_PREVADICAOITEM.SEQPRODUTO        := VT.SEQPRODUTO;
     SP_EXCLUIADICAOITEM(tSP_MAD_PREVADICAOITEM);
   END LOOP;
   SP_EXCLUIADICAO(tSP_MAD_PREVADICAO);
END SP_PROCEXCLUIADICAO;
PROCEDURE SP_EXCLUIADICAOITEM(tSP_MAD_PREVADICAOITEM IN MAD_PREVADICAOITEM%ROWTYPE )
IS
BEGIN
   DELETE MAD_PREVADICAOITEM A
    WHERE A.SEQPREVADICAOITEM = tSP_MAD_PREVADICAOITEM.SEQPREVADICAOITEM
      AND A.SEQPRODUTO        = tSP_MAD_PREVADICAOITEM.SEQPRODUTO;
   COMMIT;
END SP_EXCLUIADICAOITEM;
PROCEDURE SP_EXCLUIADICAO(tSP_MAD_PREVADICAO IN MAD_PREVADICAO%ROWTYPE )
IS
BEGIN
   DELETE MAD_PREVADICAO A
    WHERE A.NROADICAO         = tSP_MAD_PREVADICAO.NROADICAO
      AND A.NROPROCIMPORTACAO = tSP_MAD_PREVADICAO.NROPROCIMPORTACAO
      AND A.SEQFORNECEDOR     = tSP_MAD_PREVADICAO.SEQFORNECEDOR;
   COMMIT;
END SP_EXCLUIADICAO;
PROCEDURE SP_DESCARTARPREV(pnNroProcImportacao MAD_PREVADICAO.NROPROCIMPORTACAO%TYPE )
IS
 tSP_MAD_PREVADICAO MAD_PREVADICAO%ROWTYPE;
BEGIN
   FOR VT IN (SELECT C.NUMERODI,
                     A.NROPROCIMPORTACAO,
                     C.NROADICAO,
                     C.SEQFORNECEDOR
                FROM MAD_PIPEDIDOIMPORT A, GE_PESSOA B, MAD_PREVADICAO C
               WHERE A.SEQFORNECEDOR     = B.SEQPESSOA
                 AND C.SEQFORNECEDOR     = A.SEQFORNECEDOR
                 AND C.NROPROCIMPORTACAO = A.NROPROCIMPORTACAO
                 AND A.NROPROCIMPORTACAO = pnNroProcImportacao
   )LOOP
     tSP_MAD_PREVADICAO.NUMERODI          := VT.NUMERODI;
     tSP_MAD_PREVADICAO.NROPROCIMPORTACAO := VT.NROPROCIMPORTACAO;
     tSP_MAD_PREVADICAO.NROADICAO         := VT.NROADICAO;
     tSP_MAD_PREVADICAO.SEQFORNECEDOR     := VT.SEQFORNECEDOR;
     SP_PROCEXCLUIADICAO(tSP_MAD_PREVADICAO);
   END LOOP;
END SP_DESCARTARPREV;
end PKG_MAD_DI;
/
