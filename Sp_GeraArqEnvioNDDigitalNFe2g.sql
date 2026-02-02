create or replace procedure Sp_GeraArqEnvioNDDigitalNFe2g(
       pnSeqNota        in        mfl_doctofiscal.seqnotafiscal%type,
       pnNroEmpresa     in        max_empresa.nroempresa%type,
       psSoftPDV        in        mrl_empsoftpdv.softpdv%type,
       psIndGeraTxtNFe  in        mrl_empsoftpdv.indgeratxtnfe%type)
is
      -- Constantes
      csFormatoNumber3_4   VARCHAR2(10) := 'FM990.0099';
      csFormatoNumber13_2  VARCHAR2(18) := 'FM9999999999990.00';
      csFormatoNumber11_4  VARCHAR2(18)  := 'FM99999999990.0099';

      -- Variaveis
      vsNomeArquivo        varchar2(100);
      vsChaveAcesso        mfl_doctofiscal.nfechaveacesso%type;
      vsDiretorioExport    mrl_empsoftpdv.diretexportarquivo%type;
      vnStatusFile         number(1);
      vhWndFile            sys.utl_file.File_type;
      vdDtaMovimento       mfl_doctofiscal.dtamovimento%type;
      vsSerieDF            mfl_doctofiscal.seriedf%type;
      vsUFEmpresa          max_empresa.uf%type;
      vsDigitoChaveNFE     varchar2(2);
      vsAmbienteNFE        varchar2(2);
      vsPontoImpressao     MAX_DISPOSITIVOIMP.Pontoimpressao%type;
      vdDtaHorArquivo      mfl_doctofiscal.dtahoremissao%type;
      vnAppOrigem          mfl_doctofiscal.apporigem%type;
      vsCodNroChave        varchar2(9);
      vsDriverImp          MAX_EMPPONTOIMPR.driverimp%type;
      vsNumeroDF           varchar2(9);
      vnSeqPessoa          mfl_doctofiscal.seqpessoa%type;
      vsTipNotaFiscal      mlf_notafiscal.tipnotafiscal%type;
      vnCodGeralOper       mfl_doctofiscal.codgeraloper%type;
      vsNomeJobNFe         mrl_empsoftpdv.nomejobnfe%type;
      vsNomeJobNFePonto    max_emppontoimpr.nomejobnfe%type;
      vslinha              CLOB;
      vsLinhaBLOBIntegra   BLOB;
      dest_offset          INTEGER := 1;
      src_offset           INTEGER := 1;
      warning              INTEGER := 0;
      v_lang               INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
      vsPD_GeraArqDirTempCopiaExp        max_parametro.parametro%type;
      vsDiretorioTemp                    mrl_empsoftpdv.direttemp%type;
      vsDiretorioAux                     mrl_empsoftpdv.diretexportarquivo%type;
      vsEmailTransportador               TMP_M000_NF.M000_Ds_Email_Alt%type;
      vnNroCarga                         mfl_doctofiscal.nrocarga%type;
      vsPdGeraOrdemEmissaoNDD            max_parametro.valor%type;
      vsGeraFormCondCanhoto              max_parametro.valor%type;
      vnNroFormaPagto                    MRL_FORMAPAGTO.NROFORMAPAGTO%TYPE;
      vnNroCondPagto                     MAD_CONDICAOPAGTO.NROCONDICAOPAGTO%TYPE;
      vnContador                         INTEGER := 1;
      vnContCupom                        INTEGER := 0;
      vsEmailsNFe                        TMP_M002_DESTINATARIO.EMAILNFEC5%TYPE;
      vsJobNFeUser                       mfl_doctofiscal.jobnfeuser%type;
      vsJobNFeSeg                        mfl_doctofiscal.jobnfeseg%type;
      vsPDGeraRegTotImpNFe               MAX_PARAMETRO.PARAMETRO%TYPE;
      vsPDGeraCaractEspecial             MAX_PARAMETRO.VALOR%TYPE;
      vsCaracteresEspeciais              varchar2(100);
      vsDirSalvaXmlNDD                   MAX_PARAMETRO.VALOR%TYPE;
      vsDirSalvaPdfNDD                   MAX_PARAMETRO.VALOR%TYPE;
      vsPDUtilNovaEstrutControl          max_parametro.valor%type;
      vsPDVersaoXml                      max_parametro.valor%type;
      vsFusoHorario                      max_empresa.fusohorario%type;
      vsNroRECOPI                        max_empresa.nrorecopi%type;
      vsObsNFe                           varchar2(4000);
      vsInscricaoSuframaDest             TMP_M002_DESTINATARIO.M002_Nr_Suframa%type;
      vsPDConcObsPedVdaItemInfoItem      max_parametro.valor%type;
      vsUsuEmitiuNFe                     mflv_basenf.USUEMITIU%type;
      vsPDUsuEmitiuPDV                   MAX_PARAMETRO.VALOR%type;
      vnUsuPainel                        number;
      vsTextoSoftware                    varchar2(40);
      vdDtaHorEmissao                    TMP_M000_NF.M000_DT_EMISSAO%type;
      vsIndIEDest                        varchar2(1);
      vsPDInfDadosTransp                 MAX_PARAMETRO.VALOR%TYPE;
      vsPD_IndEquipUFOlimpiada           max_parametro.valor%type;
      vsIndVendaInterPresencial          max_codgeraloper.indvendainterpresencial%type;
      vsPDRetiraAcentoArq                max_parametro.valor%type;
      vsPDEmiteNFItemGenerico            max_parametro.valor%type;
      vsPDGeraVlrTotLiqItem              max_parametro.valor%type;
      vsPDDataPadraoEmissaoNF            max_parametro.valor%type;
      vsPDEnviaNumCargaCanhoto           max_parametro.valor%type;
      vsPDGeraCestGenerico               max_parametro.valor%type;
      vsIntegraNfeNT2018005              max_parametro.valor%type;
      vsObservacao                       long;
      vsPDCGO_IcmsOp_Distrib_NfEntr      max_parametro.valor%type;
      vsIndUtilCalcFCP                   max_empresa.indutilcalcfcp%type;
      vnIndDestInterstadual              number;
      vnVlrTotFCPIcms                    tmp_m014_item.m014_vl_fcp_icms%type;
      vnVlrTotFCPST                      tmp_m014_item.m014_vl_fcp_st%type;
      vnVlrTotFCPSTRet                   tmp_m014_item.m014_vl_fcp_ret%type;
      vnVlrTotIPI                        tmp_m014_item.m014_vl_ipi%type;
      vnVlrTotIPIDevol                   tmp_m014_item.m014_vl_ipi%type;
      vsPDIndVerMunUfTransp              max_parametro.valor%type;
      vsIndPresenca                      max_codgeraloper.indpresenca%type;
      vsEmiteApuracaoIPI                 rf_parametro.emiteregapuripi%type;
      vnindreqrecopi                     mfl_doctofiscal.indreqrecopi%type;
      vnNroRecopiNDD                     number(20);
      vsIndComplemento                   varchar2(1);
      vsPDEnviaQRCodeCanhoto             max_parametro.valor%type;
      pObjGeraLinha                      tp_sp_geralinha := tp_sp_geralinha(0,0);
      vsDescFormaPagtoOutros             VARCHAR2(60);
      vsPDDescFormaPagtoOutrosEnt        MAX_PARAMETRO.VALOR%TYPE;
      vdPDGeraTagMed                     MAX_PARAMETRO.VALOR%TYPE;
      vnNroPassaporte                    GE_PESSOA.NROPASSAPORTE%TYPE;
      vsStatusNT2024003                  MAX_EMPRESANOTATECNICA.STATUS%TYPE;
      vsStatusNT2025002                  MAX_EMPRESANOTATECNICA.STATUS%TYPE;
      indGeraGrupoIBSCBSTot              VARCHAR2(1);
      indTemItemNaoGeraGrupoIBSCBSTot    VARCHAR2(1);

begin
     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'DIR_SALVA_XML_NDD', 'S', 'N',
                           'INFORME O DIRETÓRIO PARA SALVAR O XML DE ENVIO E CANCELAMENTO NF-E?' || chr(13) || chr(10) ||
                           'N-NÃO UTILIZA' || chr(13) || chr(10) ||
                           'OBS: ESSE PD É SOMENTE PARA INTEGRAÇÃO COM NDDIGITAL.', vsDirSalvaXmlNDD);

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'DIR_SALVA_PDF_NDD', 'S', 'N',
                           'INFORME O DIRETÓRIO PARA SALVAR O PDF DE ENVIO E CANCELAMENTO NF-E?' || chr(13) || chr(10) ||
                           'N-NÃO UTILIZA' || chr(13) || chr(10) ||
                           'OBS: ESSE PD É SOMENTE PARA INTEGRAÇÃO COM NDDIGITAL.', vsDirSalvaPdfNDD);

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', 0, 'GERA_ARQ_EXP_DIR_TEMP_COP_EXP', 'S', 'N',
                           'GERA O ARQUIVO DE EXPORTAÇÃO NO DIRETÓRIO TEMPORÁRIO E APÓS TERMINAR A GERAÇÃO DO ARQUIVO MOVE O ARQUIVO PARA O DIRETÓRIO DE EXPORTAÇÃO?(S-SIM/N-NÃO) DEFAULT: N.', vsPD_GeraArqDirTempCopiaExp );

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'GERA_ORDEM_EMISSAO_NDD', 'S', 'N',
                           'GERA ORDEM DE EMISSÃO PARA IMPRESSÃO CONTROLADA NO SOFTWARE NDDIGITAL?' || chr(13) || chr(10) ||
                           'S=SIM, EM ORDEM CRESCENTE.' || chr(13) || chr(10) ||
                           'D-SIM, EM ORDEM DECRESCENTE' || chr(13) || chr(10) ||
                           'N=NÃO(PADRÃO)' || chr(13) || chr(10) ||
                           'OBS: ESSA PD IRÁ GERAR A LINHA 10300 NA NDDIGITAL.', vsPdGeraOrdemEmissaoNDD );

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'UTIL_NOVA_ESTRUT_CONTROL_NDD', 'S', 'N',
                           'UTILIZA NOVA ESTRUTURA DE IMPRESSAO CONTROLADA?
                           (Empresa Carga Sequencia Contador ) SIM/NAO(PADRAO)', vsPDUtilNovaEstrutControl );

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'GER_FORM_COND_CANHOTO', 'S', 'N',
                           'GERA FORMA E CONDIÇÃO DE PAGAMENTO NO CANHOTO DA DANFE?
                           S-SIM.
                           N-NÃO(VALOR PADRÃO)
                           OBS: TRATAMENTO APENAS PARA NDDIGITAL, GERAÇÃO DA LINHA 10200.', vsGeraFormCondCanhoto );

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa,'GERA_REG_TOT_IMP_NFE','S','S',
                           'GERA REGISTROS TOTAL DE IMPOSTOS DOS PRODUTOS(LEI NRO 12.741) NA NFE?' || chr(13) || chr(10) ||
                           'S-SIM, VERIFICANDO REGRAS DO CGO E CONTRIBUINTE(PADRÃO).' ||chr(13) || chr(10) ||
                           'N-NÃO GERA.' ||chr(13) || chr(10) ||
                          'C-APENAS NÃO CONTRIBUINTES.' ||chr(13) || chr(10) ||
                           'O-APENAS CONTRIBUINTES.' ||chr(13) || chr(10) ||
                           'E-GERAR SEMPRE SEM VERIFICAR REGRA.', vsPDGeraRegTotImpNFe);

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa,'GERA_VLRTOTLIQ_ITEM','S','S',
                           'GERA COLUNA VALOR TOTAL LÍQUIDO (VALOR TOTAL - VALOR DESCONTO) POR ITEM DA NOTA FISCAL?'|| chr(13) || chr(10) ||
                           'S-SIM(OBS: AS INFORMAÇÕES SERÃO GERADAS NA LINHA 10200, CONFORME PADRÃO NDDIGITAL)' ||chr(13) || chr(10) ||
                           'N-NÃO(PADRÃO)', vsPDGeraVlrTotLiqItem);

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', 0,'GERA_CARACT_ESPECIAL','S','S',
                           'GERA CARACTERES BARRA E VIRGULA NA DESCRICAO DO PRODUTO '|| chr(13) || chr(10) ||
                           'S-SIM (PADRÃO)' ||chr(13) || chr(10) ||
                           'N-NÃO', vsPDGeraCaractEspecial);

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'CONC_OBSPEDVENDAITEM_INFO_ITEM', 'S', 'N',
                           'GERA OBSERVACAO INFORMADA NO ITEM DO PEDIDO DE VENDA NO CAMPO DE INFORMACAO DO ITEM (M014_DS_INFO)?'||chr(13)||
                           'S-CONCATENA COM A DESC.(SOMENTE LICITAÇÃO),'||chr(13)||
                           'T-SUBSTITUI A DESC. PELA OBSERVAÇÃO,'||chr(13)||
                           'C-CONCATENA COM A DESC. DO PROD(LIMITE 120).'||chr(13)||
                           'N-NAO(PADRAO)',
                            vsPDConcObsPedVdaItemInfoItem);

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE',pnNroEmpresa,'USU_EMITIU_PDV','S','0',
                           'INFORMAR O USUÁRIO PADRÃO PARA EMISSÃO DE NOTA NO PDV?'||chr(13)||'
                           VALOR PADRÃO 0'||chr(13)||'
                           OBS: INFORMAR 0(ZERO) PARA NÃO UTILIZA. PD APENAS PARA PDV CONSINCO', vsPDUsuEmitiuPDV);

     SP_BUSCAPARAMDINAMICO('PESSOA', 0, 'UTIL_EQUIP_UF_OLIMPIADA', 'S', 'N',
                           'INDICA SE IRÁ PERMITIR EQUIPARAR UF DO EXTERIOR COM A UF DO RJ PARA ATENDER OBRIGAÇÕES LEGAIS DURANTE O PERÍODO DAS OLIMPÍADAS RIO 2016. (S-SIM/N-NÃO) DEFAULT: N.',
                           vsPD_IndEquipUFOlimpiada );

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'INF_DADOS_TRANSP', 'S', '1',
                           'DEFINE SE AS INFORMAÇÕES DE RAZÃO SOCIAL E ENDEREÇO REFERENTES AO TRANSPORTADOR SERÃO ENVIADAS NA NFe.' || CHR(13) || CHR(10) ||
                           '1 - GERA RAZÃO SOCIAL E ENDEREÇO (PADRÃO)' || CHR(13) || CHR(10) ||
                           '2 - GERA APENAS RAZÃO SOCIAL' || CHR(13) || CHR(10) ||
                           '3 - NÃO GERA INFORMAÇÕES', vsPDInfDadosTransp);

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', 0,'RETIRA_ACENTO_ARQUIVO','S','S',
                           'RETIRA A ACENTUAÇÃO DAS LINHAS NO ARQUIVO DE ENVIO'|| chr(13) || chr(10) ||
                           'S-SIM (PADRÃO)' ||chr(13) || chr(10) ||
                           'N-NÃO', vsPDRetiraAcentoArq);

     SP_BUSCAPARAMDINAMICO('MAX_NF', pnNroEmpresa,'EMITE_NF_ITEM_GENERICO','S','S',
                           'PERMITE A EMISSÃO DE NOTA FISCAL BASEADA EM CUPOM INFORMANDO APENAS UM PRODUTO GENÉRICO. VALORES:(S-SIM/N-NÃO(VALOR PADRÃO))',
                           vsPDEmiteNFItemGenerico);

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE',pnNroEmpresa,'DATA_PADRAO_EMISSAO_NOTA','S','E',
                           'TIPO DE DATA PARA EMISSÃO DA DANFE:' || CHR(13) || CHR(10) ||
                           'E - DATA DE EMISSÃO (PADRÃO)' || CHR(13) || CHR(10) ||
                           'S - DATA HORA DE SAÍDA, QUANDO A MESMA FOR NULA PASSA DATA DE EMISSÃO' || CHR(13) || CHR(10) ||
                           'D - SOMENTE DATA HORA DE SAÍDA.' || CHR(13) || CHR(10) ||
                           'P - DTAHORA DE IMP QDO A DATA SAIDA NAO POSSUIR HORA', vsPDDataPadraoEmissaoNF);

     SP_BUSCAPARAMDINAMICO( 'EXPORT_NFE', pnNroEmpresa, 'ENVIA_NRO_CARGA_CANHOTO', 'S', 'N',
                            'ENVIA NÚMERO DA CARGA PARA A NDD IMPRIMIR NO CANHOTO DO DANFE?
                            S-SIM.
                            N-NÃO(VALOR PADRÃO)
                            OBS: TRATAMENTO APENAS PARA NDDIGITAL, GERAÇÃO DA LINHA 10200.', vsPDEnviaNumCargaCanhoto );

     SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa,'GERA_CEST_GENERICO','S','N',
                           'GERA CEST GENERICO.'|| chr(13) || chr(10) ||
                           'S-SIM' ||chr(13) || chr(10) ||
                           'N-NÃO(PADRÃO)', vsPDGeraCestGenerico);

    SP_BUSCAPARAMDINAMICO('SILLUS_FATURAMENTO',0,'CGO_ICMS_OP_DISTRIB_NF_ENTR','S',' ',
                          'INFORMAR OS CGOS DE EMISSÃO/SAÍDA QUE IRÃO CALCULAR O ICMS OP DISTRIBUIDOR UTILIZANDO AS INFORMAÇÕES DA OPERAÇÃO (ICMS OP) DA ÚLTIMA NOTA FISCAL DE ENTRADA (BASE DE CÁLCULO ST E ALÍQUOTA INTERNA)'||CHR(13)||CHR(10)||
                          'OBS: SEPARAR OS CGOS POR VIRGULA.', vsPDCGO_IcmsOp_Distrib_NfEntr);


    SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'IND_VER_MUN_UF_TRANSP', 'S', 'N',
                          'INDICA SE EM OPERAÇÕES INTERNAS NA UF DA EMPRESA EMITENTE SERÁ VERIFICADO MUNICIPIOS DE ORIGEM E DESTINO DIFERENTES PARA ENVIO DO BLOCO DE GRUPO DE TRANSPORTE.'||CHR(13)||CHR(10)||
                          'S-SIM' ||chr(13) || chr(10) ||
                          'N-NÃO(PADRÃO)', vsPDIndVerMunUfTransp);

    SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'PD_INTEGRA_NFE_NT_2018_005', 'S', 'N',
                          'ATUALIZAR INTEGRAÇÃO NF-E CONFORME NT 2018.005.'|| chr(13) || chr(10) ||
                          'N-NÃO (PADRÃO)' ||chr(13) || chr(10) ||
                          'S-SIM' ||chr(13)||chr(10)||
                          'OBS.: ENTRA EM VIGOR 07/05/2019', vsIntegraNfeNT2018005);

    SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'ENVIA_QRCODE_CANHOTO', 'S', '0',
                          'INFORMAR O CÓDIGO DA MENSAGEM A SER DEMONSTRADA NO QRCODE IMPRESSO NO CANHOTO DO DANFE.' || chr(13) || chr(10) ||
                          'PREENCHER COM CÓDIGO ÚNICO' || chr(13) || chr(10) ||
                          '0 - NÃO ENVIA A MENSAGEM (PADRÃO)' || chr(13) || chr(10) ||
                          'OBS: TRATAMENTO APENAS PARA NDDIGITAL, GERAÇÃO DA LINHA 10210.', vsPDEnviaQRCodeCanhoto);

    SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa, 'DESC_FORMAPAGTO_OUTROS_ENT', 'S', NULL,
                          'DESCRIÇÃO PADRÃO PARA MEIO DE PAGAMENTO NO ENVIO DO XML QUANDO A FORMA DE PAGAMENTO FOR 99-OUTROS. ' || CHR(13) || CHR(10) ||
                          'VAZIO (PADRÃO).' || CHR(13) || CHR(10) ||
                          'PREENCHER COM ATÉ 60 CARACTERES.' || CHR(13) || CHR(10) ||
                          'OBS.: SOMENTE PARA DOCUMENTOS DE ENTRADA E, CASO NÃO SEJA INFORMADO, SERÁ CONSIDERADO O PD DESC_PADRAO_FORMAPAGTO_OUTROS.',
                          vsPDDescFormaPagtoOutrosEnt);

    vdPDGeraTagMed:= '31/12/2050';
    SP_BUSCAPARAMDINAMICO('EXPORT_NFE', pnNroEmpresa,'DTA_INI_TAGMED', 'D', vdPDGeraTagMed,
                          'DATA PARA INÍCIO DA REGRA K01-10 - MEDICAMENTOS - NCMs QUE COMEÇAM COM 3001, 3002, 3003, 3004, 3005 E 3006 REFERNETE A NT2021-004.' || CHR(13) || CHR(10) ||
                          '31/12/2050 - (PADRÃO)', vdPDGeraTagMed);


     If vsPDGeraCaractEspecial = 'N' then
       vsCaracteresEspeciais:= '[><,¬/&]';
     Else
       vsCaracteresEspeciais:= '[><¬&]';
     End if;

     vsPDVersaoXml := fc5maxparametro('EXPORT_NFE', pnNroEmpresa, 'VERSAO_XML');


    SELECT MAX(F.FORMAPAGTO)
      INTO vsDescFormaPagtoOutros
      FROM TMP_M000_NF NF, MRL_FORMAPAGTO F
     WHERE NF.NROFORMAPAGTO = F.NROFORMAPAGTO
       AND NF.M000_ID_NF = pnSeqNota;

     select w.nfechaveacesso, w.dtaemissao, w.serie,
            w.dtahoremissao, w.apporigem,
            substr(substr(w.nfechaveacesso, -9), 1, 8),
            nvl(w.pontoimpressaoautoriza, w.pontoimpressaosel),
            lpad(w.numero, 9, 0),
            w.seqpessoa, w.tipnotafiscal,
            w.codgeraloper, w.nrocarga, w.nroformapagto,
            w.nrocondpagto, w.jobnfeuser, w.jobnfeseg,
            w.jobnfeenvio, w.usuemitiu,
            w.observacaonfe, w.indreqrecopi,
      w.NumeroRECOPI
     into   vsChaveAcesso, vdDtaMovimento, vsSerieDF,
            vdDtaHorArquivo, vnAppOrigem,
            vsCodNroChave,
            vsPontoImpressao,
            vsNumeroDF,
            vnSeqPessoa, vsTipNotaFiscal,
            vnCodGeralOper, vnNroCarga, vnNroFormaPagto,
            vnNroCondPagto, vsJobNFeUser, vsJobNFeSeg,
            vsNomeJobNFePonto,
            vsUsuEmitiuNFe,
            vsObsNFe,
            vnindreqrecopi,
            vnNroRecopiNDD
     from   (      select    x.seqnotafiscal,               x.nfechaveacesso,                  x.dtaemissao,
                             x.serienf   serie,             x.dtahorlancto dtahoremissao,      x.apporigem,
                             x.pontoimpressaoautoriza,      x.pontoimpressaosel,               x.numeronf   numero,
                             x.seqpessoa,                   x.tipnotafiscal,                   x.codgeraloper,
                             x.nrocargaexped  nrocarga,     x.nroformapagto,                   x.nrocondpagto,
                             x.jobnfeuser,                  x.jobnfeseg,                       x.jobnfeenvio,
                             x.usuemitiu,                   x.observacaonfe,                   x.indreqrecopi,
                             x.NumeroRECOPI
                   from      mlf_notafiscal x
                   where     x.seqnotafiscal = pnSeqNota

                   union all

                   select    y.seqnotafiscal,               y.nfechaveacesso,                  y.dtamovimento dtaemissao,
                             y.seriedf   serie,             y.dtahoremissao dtahoremissao,     y.apporigem,
                             y.pontoimpressaoautoriza,      y.pontoimpressaosel,               y.numerodf   numero,
                             y.seqpessoa,                  'S' tipnotafiscal,                  y.codgeraloper,
                             y.nrocarga  nrocarga,          y.nroformapagto,                   y.nrocondicaopagto,
                             y.jobnfeuser,                  y.jobnfeseg,                       y.jobnfeenvio,
                             y.usuemitiu,                   y.observacaonfe,                   y.indreqrecopi,
                             y.NumeroRECOPI
                   from      mfl_doctofiscal y
                   where     y.seqnotafiscal = pnSeqNota )  w
     where  w.seqnotafiscal = pnSeqNota;

     if vnCodGeralOper is not null then
       select nvl(max(a.indvendainterpresencial),'N'),
              nvl(max(a.indpresenca), 'N'),
              nvl(max(a.indcomplvlrimp),'N')
       into   vsIndVendaInterPresencial,
              vsIndPresenca,
              vsIndComplemento
       from   max_codgeraloper a
       where  a.codgeraloper   =  vnCodGeralOper ;
     end if;

     if vnNroCarga is not null then

        select sum(x.notas)
        into   vnContador
        from   (  select count(distinct numeronf)  notas
                  from   mlf_notafiscal
                  where  nrocargaexped = vnNroCarga
                  and    nroempresa = pnNroEmpresa

                  union all

                  select count(distinct b.numerodf) notas
                  from   mfl_doctofiscal b
                  where  b.nrocarga = vnNroCarga
                  and    nroempresa = pnNroEmpresa ) x ;

     else
       vnContador:= 1;
     end if;

     vsDigitoChaveNFE := substr(vsChaveAcesso, length(vsChaveAcesso), 1);

     select  a.uf, decode(a.tipoemisnfe, 'H', 2, 'P', 1, 0), nvl(vnNrorecopiNDD, a.nrorecopi), a.fusohorario, nvl(a.indutilcalcfcp, 'N')
     into    vsUFEmpresa, vsAmbienteNFE, vsNroRECOPI, vsFusoHorario, vsIndUtilCalcFCP
     from    max_empresa a
     where   a.nroempresa = pnNroEmpresa;

     if vsNomeJobNFePonto is null then

            if vsNomeJobNFePonto is null then
                       select  max(b.driverimp), max(b.nomejobnfe)
                       into    vsDriverImp, vsNomeJobNFePonto
                       from    max_emppontoimpr b
                       where   b.descricao      = vsPontoImpressao
                       and     b.nroempresa     = pnNroEmpresa;
            end if;

            if vnAppOrigem = 7  then
                   select max(b.driverimp), max(b.nomejobnfe)
                   into   vsDriverImp, vsNomeJobNFePonto
                   from   max_dispositivoimp a, max_emppontoimpr b
                   where  a.nroempresa     = b.nroempresa
                   and    a.pontoimpressao = b.descricao
                   and    a.codaplicacao   = 'MAX0015'
                   and    a.seriedocto     = vsSerieDF
                   and    a.nroempresa     = pnNroEmpresa;
             end if;

         If vsJobNFeUser is not null Then
            vsNomeJobNFePonto := vsJobNFeUser;
         Else

             If vsJobNFeSeg is not null Then
                vsNomeJobNFePonto := vsJobNFeSeg;
             End If;
         End IF;
     end if;

     vsNomeArquivo := 'ASS' || '-' || lpad(pnNroEmpresa, 6, 0)  || '-' || 'IMP2'
                       || '-' || to_char(vdDtaHorArquivo, 'yyyymmddhh24miss')  || vsNumeroDF || '-' || 'env.txt';

     select max(a.diretexportarquivo), max(a.direttemp),

            max(a.nomejobnfe)
     into   vsDiretorioExport, vsDiretorioTemp,
            vsNomeJobNFe

     from   mrl_empsoftpdv a
     where  a.nroempresa = pnNroEmpresa
     and    a.softpdv    = psSoftPDV
     and    a.tiposoft   = 'N';

     If vsNomeJobNFePonto is not null then
        vsNomeJobNFe := vsNomeJobNFePonto;
     end if;

     SELECT max(X.EMAILNFEC5),
            max(x.M002_NR_SUFRAMA),
            max(x.M002_NR_PASSAPORTE),
            max(case when a.NRODECLARAIMPORTc5 is not null or
                           case when vsPD_IndEquipUFOlimpiada = 'S' and nvl(b.indequipufolimpiada,'N') = 'S' then
                                'EX' else  x.M002_DS_UF
                          end = 'EX' or x.M002_IND_CONTRIB_ICMS = 'N' or x.m002_nr_passaporte is not null then
                        '9'
                    else
                        case when nvl(UPPER(x.M002_NR_IE), 'ISENTO')  = 'ISENTO' AND  x.M002_IND_CONTRIB_ICMS = 'S' then
                            '2'
                        else
                            '1'
                        end
                    end)
     INTO   vsEmailsNFe, vsInscricaoSuframaDest,
            vnNroPassaporte, vsIndIEDest
     FROM   TMP_M002_DESTINATARIO X, TMP_M000_NF a, ge_pessoa b
     WHERE  X.M000_ID_NF = pnSeqNota
     and    x.m000_id_nf = a.m000_id_nf
     and    b.seqpessoa  = x.m002_nr_cliente;

     -- Apuração IPI (IPI devol.)
     select nvl(max(a.emiteregapuripi), 'N')
     into   vsEmiteApuracaoIPI
     from   rf_parametro a
     where  a.nroempresa = pnNroEmpresa;

     ---registro A - Dados da Nota Fiscal Eletrônica
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        linha, arquivo, seqlinha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        '0000;' || decode(vsPDVersaoXml, 4, '4.00') ||';ENVIO', vsNomeArquivo, 0, pnSeqNota
     from  dual
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        '1000;000000000000001', vsNomeArquivo, 1000, pnSeqNota
     from  dual
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        '2000;' || decode(vsPDVersaoXml, 4, '4.00') || ';NFe' || vsChaveAcesso, vsNomeArquivo, 2000, pnSeqNota
     from  dual;

     ---registro B - Identificação da Nota Fiscal Eletrônica
     select max(case when vsPDDataPadraoEmissaoNF != 'E' then
                   case when (trunc(a.M000_DT_EMISSAO) > trunc(a.M000_DT_ENTRADA_SAIDA)) then
                      a.M000_DT_ENTRADA_SAIDA
                   else
                      a.M000_DT_EMISSAO
                   end
                else
                   case when (trunc(a.M000_DT_EMISSAO) > trunc(a.M000_DT_ENTRADA_SAIDA)) OR (TO_CHAR(a.M000_DT_ENTRADA_SAIDA,'MM') - TO_CHAR(a.M000_DT_EMISSAO,'MM') >= 1 AND a.M000_DT_ENTRADA_SAIDA <= TRUNC(SYSDATE)) then
                      a.M000_DT_ENTRADA_SAIDA
                   else
                      a.M000_DT_EMISSAO
                   end
                end
            ) as DTAHOREMISSAO
     into   vdDtaHorEmissao
     from   TMP_M000_NF a
     where  a.m000_id_nf = pnSeqNota;

     IF vdDtaHorEmissao IS NULL THEN
       vdDtaHorEmissao := SYSDATE;
     END IF;
     vsStatusNT2025002 := NVL(fc5_BuscaStatusNotaTecnica(2025002, pnNroEmpresa, 4, 1.30, vdDtaHorEmissao), 'I');
     vsStatusNT2024003 := NVL(fc5_BuscaStatusNotaTecnica(2024003, pnNroEmpresa, 4, 1.06, vdDtaHorEmissao), 'I');

     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        linha, arquivo, seqlinha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        '2100;' ||
        fBuscaCodIBGEUf(vsUFEmpresa) || ';' ||
        lpad(vsCodNroChave, 8, 0)    || ';' ||
        a.M000_DS_NAT_OPER           || ';' ||
        a.M000_NR_MODELO             || ';' ||
        a.M000_NR_SERIE              || ';' ||
        a.M000_NR_DOCUMENTO          || ';' ||
        to_char(vdDtaHorEmissao, 'yyyy-MM-dd') || 'T' ||
        to_char(vdDtaHorEmissao, 'HH24:MI:ss') || fc5_fusohorario(vsFusoHorario)
        || ';' ||
        to_char(a.M000_DT_ENTRADA_SAIDA, 'yyyy-MM-dd') || DECODE(a.M000_DT_ENTRADA_SAIDA, NULL, NULL,'T' ||
        to_char(case when (to_number(to_char(vdDtaHorEmissao, 'HH24MISS')) > to_number(to_char(a.M000_DT_ENTRADA_SAIDA, 'HH24MISS')) and (to_number(to_char(vdDtaHorEmissao, 'DDMMYYYY')) = to_number(to_char(a.M000_DT_ENTRADA_SAIDA, 'DDMMYYYY'))) )
                     then vdDtaHorEmissao else a.M000_DT_ENTRADA_SAIDA
                     end , 'HH24:MI:ss') || fc5_fusohorario(vsFusoHorario))
        || ';' ||
        a.M000_DM_ENTRADA_SAIDA || ';' ||
        nvl2( a.cfop_dev_vend_n_reconhec,  '2', decode(vsIndVendaInterPresencial, 'S', '1', decode(a.ufdestinoc5, vsUFEmpresa, '1', 'EX', decode(vnNroPassaporte, NULL, '3', '1'), '2'))) || ';' ||
        lpad(a.M000_NR_IBGE_MUN_FG, 7, 0) || ';' ||
        nvl(a.M000_DM_FMT_DANFE, '1') || ';' ||
        nvl(a.M000_DM_FORMA_EMISSAO, '1') || ';' ||
        vsDigitoChaveNFE || ';' ||
        nvl(to_char(a.M000_DM_AMB_SIS), vsAmbienteNFE) || ';' ||
        a.M000_DM_FIN_EM || ';' ||
        decode(vsIndIEDest, '9', 1, a.m000_indfinal) || ';' ||
        fNfeIndPresenca(nvl(a.indpresenca, vsIndPresenca)) || ';' ||
        '0' || ';' ||
        decode(vsPDVersaoXml, 4, '4.00') ||
        DECODE(vsPDVersaoXml, '4', fc5_BuscaCampoNotaTecnica(CASE WHEN fNfeIndPresenca(nvl(a.indpresenca, vsIndPresenca)) IN (2, 3, 9) THEN a.M000_INDINTERMED END, 2020006, pnNroEmpresa, 4, 1, 26, vdDtaHorEmissao) , '') ||
         fc5_BuscaCampoNotaTecnica(a.M000_NR_IBGE_MUN_FG_IBS, 2025002, pnNroEmpresa, 4, 1.30, 1, vdDtaHorEmissao) || -- cMunFGIBS
         fc5_BuscaCampoNotaTecnica(a.M000_TP_INDNOTADEBITO, 2025002, pnNroEmpresa, 4, 1.30, 2, vdDtaHorEmissao) || -- tpNFDebito
         fc5_BuscaCampoNotaTecnica(a.M000_TP_INDNOTACREDITO, 2025002, pnNroEmpresa, 4, 1.30, 3, vdDtaHorEmissao) || -- tpNFCredito
         CASE WHEN NAGF_BUSCA_MODFRETE(A.M000_NR_CHAVE_ACESSO) NOT IN (1,4,9) THEN
           fc5_BuscaCampoNotaTecnica(to_char(NVL(vdDtaHorEmissao,a.M000_DT_DTAPREVENTREGA), 'yyyy-MM-dd'), 2025002, pnNroEmpresa, 4, 1.30, 116, vdDtaHorEmissao) END , -- dPrevEntrega
        vsNomeArquivo, 2100, pnSeqNota
     from   TMP_M000_NF a
     where  a.m000_id_nf = pnSeqNota;

     select max(trim(a.M000_Ds_Email_Alt)),
            max(decode( a.ufdestinoc5,
                          vsUFEmpresa, decode(vsPDIndVerMunUfTransp, 'S', decode(lpad(b.M001_NR_IBGE_MUN, 7, 0), lpad(c.m002_nr_ibge_mun, 7, 0), '1', '2'), '1'),
                          'EX', '3',
                          decode(vsIndVendaInterPresencial, 'S', '1', '2')))
     into   vsEmailTransportador,
            vnIndDestInterstadual
     from   TMP_M000_NF a,
            TMP_M001_EMITENTE b,
            TMP_M002_DESTINATARIO c
     where  b.m000_id_nf = a.m000_id_nf
     and    b.m000_id_nf = c.m000_id_nf
     and    a.m000_id_nf = pnSeqNota;

     ---REFNFE ¿ Informação das NF-e referenciadas
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2110,
        '2110;' || lpad(a.M013_NR_CHAVE_ACESSO_REF, 44, '0'), pnSeqNota
     from   TMP_M013_CHAVE_REF a
     where  a.m000_id_nf = pnSeqNota
     and    a.M013_NR_CHAVE_ACESSO_REF is not null;

     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2120,
        '2120;' ||
        lpad(a.M013_NR_IBGE_UF, 2, 0) || ';' ||
        to_char(a.M013_DT_EMISSAO, 'yyMM') || ';' ||
        lpad(a.M013_NR_CNPJ, 14, 0) || ';' ||
        lpad(a.M013_NR_MODELO, 2, 0) || ';' ||
        trim(a.M013_NR_SERIE) || ';' ||
        trim(a.M013_NR_DOCUMENTO), pnSeqNota
     from   TMP_M013_CHAVE_REF a
     where  a.m000_id_nf = pnSeqNota
     and    a.M013_NR_CHAVE_ACESSO_REF is null
     AND    (A.M013_Nr_Modelo = '55' or
            (A.M013_Nr_Modelo = '01' and a.m013_tipo_chave != 3));

     ---refNFP ¿ Grupo com as informações NF de produtor rural referenciada
     --2130
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2130,
        '2130;' ||
        lpad(a.M013_NR_IBGE_UF, 2, 0) || ';' ||
        to_char(a.M013_DT_EMISSAO, 'yyMM') || ';' ||
        nvl(lpad(a.M013_NR_CNPJ, 14, 0), LPAD(a.M013_NR_CPF, 11, 0)) || ';' ||
        trim(a.m013_nr_ie) || ';' ||
        lpad(a.M013_NR_MODELO, 2, 0) || ';' ||
        trim(a.M013_NR_SERIE) || ';' ||
        trim(a.M013_NR_DOCUMENTO), pnSeqNota
     from   TMP_M013_CHAVE_REF a
     where  a.m000_id_nf = pnSeqNota
     AND    a.M013_NR_CHAVE_ACESSO_REF is  null
     AND    (a.M013_NR_MODELO = '04' or
            (a.M013_NR_MODELO = '01' and a.m013_tipo_chave = 3));

     ---refECF ¿ Grupo de informações do cupom fiscal referenciado
     --2150
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2150,
        '2150;' ||
        lpad(a.M013_NR_MODELO, 2, 0) || ';' ||
        lpad(a.m013_nr_ecf, 3, 0) || ';' ||
        lpad(a.m013_nr_coo, 6, 0), pnSeqNota
     from   TMP_M013_CHAVE_REF a
     where  a.m000_id_nf = pnSeqNota
     AND    a.M013_NR_MODELO = '2D'
     AND    a.M013_NR_CHAVE_ACESSO_REF is  null
     AND    NVL(A.M013_NR_COO, 0) > 0;

     vnContCupom:= sql%rowcount;

     if vnContCupom = 0 then

       insert into mrlx_pdvimportacao
         (nroempresa, softpdv, dtamovimento, dtahorlancamento,
          arquivo, seqlinha,
          linha, seqnotafiscal)
       select DISTINCT pnNroEmpresa,
                       psSoftPDV,
                       vdDtaMovimento,
                       sysdate,
                       vsNomeArquivo,
                       2150,
                       '2150;' || lpad(a.NFREFERENCIAMODELO, 2, 0) || ';' ||
                       lpad(B.NFREFERENCIANROECF, 3, 0) || ';' ||
                       lpad(B.NFREFERENCIANRO, 6, 0),
                       pnSeqNota
         FROM MLF_NOTAFISCAL A, MLF_NFITEM B
        WHERE A.NUMERONF = B.NUMERONF
          AND A.SEQPESSOA = B.SEQPESSOA
          AND A.SERIENF = B.SERIENF
          AND A.TIPNOTAFISCAL = B.TIPNOTAFISCAL
          AND A.NROEMPRESA = B.NROEMPRESA
          AND A.SEQNOTAFISCAL = pnSeqNota
          AND B.NFREFERENCIANROECF IS NOT NULL
          AND A.NFREFERENCIAMODELO  = '2D'
          AND B.NFREFERENCIANRO IS NOT NULL;

          vnContCupom:= sql%rowcount;
      end if;

      if vsPDEmiteNFItemGenerico = 'S' and vnContCupom = 0 then

         insert into mrlx_pdvimportacao
         (nroempresa, softpdv, dtamovimento, dtahorlancamento,
          arquivo, seqlinha,
          linha, seqnotafiscal)
         select DISTINCT pnNroEmpresa,
                       psSoftPDV,
                       vdDtaMovimento,
                       sysdate,
                       vsNomeArquivo,
                       2150,
                       '2150;' || lpad(C.NFREFERENCIAMODELO, 2, 0) || ';' ||
                       lpad(NVL(D.NROECF,C.NRONROCHECKOUT), 3, 0) || ';' ||
                       lpad(C.NUMERONFREF, 6, 0),
                       pnSeqNota
         FROM MLF_NOTAFISCAL A, MLF_NFITEM B, MRL_CUPOMPRODREF C, MFL_DOCTOFISCAL D
        WHERE A.NUMERONF = B.NUMERONF
          AND A.SEQPESSOA = B.SEQPESSOA
          AND A.SERIENF = B.SERIENF
          AND A.TIPNOTAFISCAL = B.TIPNOTAFISCAL
          AND A.NROEMPRESA = B.NROEMPRESA
          AND A.SEQNOTAFISCAL = pnSeqNota
          AND C.NUMERONF      = A.NUMERONF
          AND C.SERIENF       = A.SERIENF
          AND C.SEQPESSOA     = A.SEQPESSOA
          AND C.TIPNOTAFISCAL = A.TIPNOTAFISCAL
          AND C.NROEMPRESA    = A.NROEMPRESA
          AND D.NUMERODF(+)      = C.NUMERONFREF
          AND D.NROSERIEECF(+)   = C.NROSERIEECFREF
          AND D.MODELODF(+)      = C.NFREFERENCIAMODELO
          AND D.NROEMPRESA(+)    = C.NROEMPRESA
          AND C.NROSERIEECFREF IS NOT NULL
          AND C.NFREFERENCIAMODELO  = '2D'
          AND C.NUMERONFREF IS NOT NULL;

      end if;

     ---Informações sobre a entrada em contingência
     --2180
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2180,
        '2180;' ||
        to_char(a.dtacontingencianfe, 'yyyy-MM-dd') || 'T' || to_char(a.dtacontingencianfe, 'HH24:MI:ss') ||
        decode(nvl(vsFusoHorario,'CC'), 'CC', to_char(current_timestamp, 'TZH:TZM'),'BD', to_char(systimestamp, 'TZH:TZM'), vsFusoHorario || ':00') || ';' ||
        a.descontingencianfe, pnSeqNota
     from  max_empresa a
     where a.nroempresa = pnNroEmpresa
     and   exists (select 1
                   from   tmp_m000_nf x
                   where  x.m000_id_nf = pnSeqNota
                   and    x.m000_nr_serie between 900 and 999);

     --- gCompraGov¿ Grupo de informações de compra governamental
     --2190
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2190,
        '2190;' ||
        fc5_BuscaCampoNotaTecnica(a.M000_TP_INDENTEGOV, 2025002, pnNroEmpresa, 4, 1.30, 4, vdDtaHorEmissao) || -- tpEnteGov
        fc5_BuscaCampoNotaTecnica(a.M000_PER_REDALIQCGOV, 2025002, pnNroEmpresa, 4, 1.30, 5, vdDtaHorEmissao) || -- pRedutor
        fc5_BuscaCampoNotaTecnica(a.M000_TP_INDOPERGOV, 2025002, pnNroEmpresa, 4, 1.30, 6, vdDtaHorEmissao), -- tpOperGov
        pnSeqNota
     from  TMP_M000_NF a
     where a.m000_id_nf = pnSeqNota
     and M000_TP_INDENTEGOV is not null
     and M000_PER_REDALIQCGOV is not null
     and   vsStatusNT2025002 = 'A';

     --- gPagAntecipado ¿ Grupo de notas de antecipação de pagamento
     --2195
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2195,
        '2195;' ||
        fc5_BuscaCampoNotaTecnica(a.M000_DS_CHAVEACESSOREFPAGANTECIP, 2025002, pnNroEmpresa, 4, 1.30, 7, vdDtaHorEmissao), -- refNFe
        pnSeqNota
     from  TMP_M000_NF a
     where a.m000_id_nf = pnSeqNota
     and   M000_DS_CHAVEACESSOREFPAGANTECIP is not null
     and   vsStatusNT2025002 = 'A';

     --- registro C - Identificação do Emitente da Nota Fiscal Eletrônica
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2200,
        '2200;' ||
        a.M001_NR_CNPJ || ';' ||
        a.M001_NM_RAZAO_SOCIAL || ';' ||
        a.M001_NM_FANTASIA || ';' ||
        a.M001_NR_IE || ';' ||
        a.M001_NR_IE_ST || ';' ||
        case when a.M001_NR_CNAE is not null then a.M001_NR_IM
        else ''
        end  || ';' ||
        a.M001_NR_CNAE || ';' ||
        decode(a.M001_DM_CRT, 0, '1', 1, '2', 2, '3', 3, '4'), pnSeqNota
     from   TMP_M001_EMITENTE a
     where  a.m000_id_nf = pnSeqNota
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2210,
        '2210;' ||
        a.M001_NM_LOGRADOURO || ';' ||
        a.M001_NR_LOGRADOURO || ';' ||
        a.M001_DS_CPL_LOGRADOURO || ';' ||
        a.M001_Ds_Bairro || ';' ||
        lpad(a.M001_NR_IBGE_MUN, 7, 0) || ';' ||
        a.M001_DS_MUN || ';' ||
        a.M001_DS_UF || ';' ||
        lpad(a.M001_NR_CEP, 8, 0) || ';' ||
        a.M001_NR_PAIS || ';' ||
        a.M001_DS_PAIS || ';' ||
        a.M001_NR_TELEFONE, pnSeqNota
     from   TMP_M001_EMITENTE a
     where  a.m000_id_nf = pnSeqNota;

     ---registro D - Identificação do Fisco Emitente da NF-e
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2250,
        '2250;' ||
        a.M012_NR_CNPJ || ';' ||
        a.M012_NM_ORGAO || ';' ||
        a.M012_NR_MATRICULA || ';' ||
        a.M012_NM_AGENTE || ';' ||
        a.M012_NR_TELEFONE || ';' ||
        a.M012_DS_UF || ';' ||
        a.M012_NR_DAR || ';' ||
        to_char(a.M012_DT_EMISSAO, 'yyyy-MM-dd') || ';' ||
        trim(to_char(a.M012_VL_TOTAL, '999G999G999G990d00', 'nls_numeric_characters='',.''')) || ';' ||
        a.M012_DS_REPARTICAO || ';' ||
        to_char(a.M012_DT_PAGAMENTO, 'yyyy-MM-dd'), pnSeqNota
     from   TMP_M012_FISCO a
     where  a.m000_id_nf = pnSeqNota;

     ---registro E - Identificação do Destinatário da Nota Fiscal eletrônica
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2300,
        '2300;' ||
        decode(case when vsPD_IndEquipUFOlimpiada = 'S' and nvl(c.indequipufolimpiada,'N') = 'S' then
                     'EX' else  a.M002_DS_UF
                end, 'EX', decode( M002_NR_PASSAPORTE, null, decode( a.M002_NR_CNPJ_CPF, 0, null), M002_NR_PASSAPORTE), a.M002_NR_CNPJ_CPF) || ';' ||
        trim(replace( replace(a.M002_NM_RAZAO_SOCIAL, chr(10), NULL),chr(13), NULL)) || ';' ||
        vsIndIEDest            || ';' ||
        decode(nvl(UPPER(a.M002_NR_IE), 'ISENTO'), 'ISENTO', null, 'FISICA', null, a.M002_NR_IE) || ';' ||
        a.M002_NR_SUFRAMA || ';' ||
         ';' ||
        A.M002_DS_EMAIL,
        pnSeqNota
     from   TMP_M002_DESTINATARIO a, TMP_M000_NF b, ge_pessoa c
     where  a.m000_id_nf = pnSeqNota
     and    a.m000_id_nf = b.m000_id_nf
     and    c.seqpessoa  = a.m002_nr_cliente
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2310,
        '2310;' ||
        a.M002_NM_LOGRADOURO || ';' ||
        a.M002_NR_LOGRADOURO || ';' ||
        a.M002_DS_CPL || ';' ||
        a.M002_DS_BAIRRO || ';' ||
        decode( case when vsPD_IndEquipUFOlimpiada = 'S' and nvl(b.indequipufolimpiada,'N') = 'S' then
                     'EX' else  a.M002_DS_UF
                end, 'EX', 9999999, a.M002_NR_IBGE_MUN
              ) || ';' ||
        decode(case when vsPD_IndEquipUFOlimpiada = 'S' and nvl(b.indequipufolimpiada,'N') = 'S' then
                     'EX' else  a.M002_DS_UF
                end, 'EX', 'EXTERIOR', REGEXP_REPLACE(a.M002_DS_MUNICIPIO,'[^ [:alnum:]]',NULL)
              ) || ';' ||
        case when vsPD_IndEquipUFOlimpiada = 'S' and nvl(b.indequipufolimpiada,'N') = 'S' then
                     'EX' else  a.M002_DS_UF
                end || ';' ||
        lpad(a.M002_NR_CEP, 8, 0) || ';' ||
        case when vsPD_IndEquipUFOlimpiada = 'S' and nvl(b.indequipufolimpiada,'N') = 'S' then
                  1058 else  a.M002_NR_PAIS
              end || ';' ||
        a.M002_DS_PAIS || ';' ||
        a.M002_NR_TELEFONE, pnSeqNota
     from   TMP_M002_DESTINATARIO a, ge_pessoa b
     where  a.m000_id_nf = pnSeqNota
     and    b.seqpessoa  = a.m002_nr_cliente;

     ---registro F- Identificação do Local de retirada
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2400,
        '2400;' ||
        decode(a.M005_DS_UF, 'EX', '00000000000000', a.M005_NR_CNPJ) || ';' ||
        a.M005_NM_LOGR || ';' ||
        a.M005_NR_LOGR || ';' ||
        a.M005_DS_COMPL || ';' ||
        a.M005_DS_BAIRRO || ';' ||
        decode(a.M005_DS_UF, 'EX', 9999999, lpad(a.M005_NR_IBGE_MUN, 7, 0)) || ';' ||
        decode(a.M005_DS_UF, 'EX', 'EXTERIOR', a.M005_DS_MUN) || ';' ||
        a.M005_DS_UF    ||
        CASE WHEN vsIntegraNfeNT2018005 = 'S' THEN ';' ||
        a.M005_DS_NOME  || ';' ||
        LPAD(a.M005_NR_CEP,8,'0')   || ';' ||
        /*Código do Pais*/ ';' ||
        a.M005_DS_PAIS  || ';' ||
        a.M005_NR_FONE  || ';' ||
        a.M005_DS_EMAIL || ';'
        ELSE
               null
        END
        /*Inscrição Estadual*/,
        pnSeqNota

     from   TMP_M005_LOCAL a
     where  a.m000_id_nf = pnSeqNota
     and    a.M005_DM_TIPO = 0;

     ---registro G- Identificação do Local de Entrega
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2500,
        '2500;' ||
        decode(a.M005_DS_UF, 'EX', '00000000000000', a.M005_NR_CNPJ)|| ';' ||
        a.M005_NM_LOGR || ';' ||
        a.M005_NR_LOGR || ';' ||
        a.M005_DS_COMPL || ';' ||
        a.M005_DS_BAIRRO || ';' ||
        decode(a.M005_DS_UF, 'EX', 9999999, lpad(a.M005_NR_IBGE_MUN, 7, 0)) || ';' ||
        decode(a.M005_DS_UF, 'EX', 'EXTERIOR', a.M005_DS_MUN) || ';' ||
        a.M005_DS_UF    ||
        CASE WHEN vsIntegraNfeNT2018005 = 'S' THEN ';' ||
        a.M005_DS_NOME  || ';' ||
        LPAD(a.M005_NR_CEP,8,'0')   || ';' ||
        /*Codigo do Pais*/ ';' ||
        a.M005_DS_PAIS  || ';' ||
        a.M005_NR_FONE  || ';' ||
        a.M005_DS_EMAIL || ';'
        ELSE
             null
        END
        /*Inscrição Estadual*/,
        pnSeqNota

     from   TMP_M005_LOCAL a
     where  a.m000_id_nf = pnSeqNota
     and    a.M005_DM_TIPO = 1
     and    not (nvl(vnAppOrigem, 0) = 14  and    nvl(vsIndIEDest, '0') = '9')
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 2500,
        '2500;' ||
        decode(a.M001_DS_UF, 'EX', '00000000000000', a.M001_NR_CNPJ) || ';' ||
        a.M001_NM_LOGRADOURO || ';' ||
        a.M001_NR_LOGRADOURO || ';' ||
        a.M001_DS_CPL_LOGRADOURO || ';' ||
        a.M001_DS_BAIRRO || ';' ||
        decode(a.M001_DS_UF, 'EX', 9999999, lpad(a.M001_NR_IBGE_MUN, 7, 0)) || ';' ||
        decode(a.M001_DS_UF, 'EX', 'EXTERIOR', REGEXP_REPLACE(a.M001_DS_MUN,'[^ [:alnum:]]',NULL)) || ';' ||
        a.M001_DS_UF, pnSeqNota
     from   TMP_M001_EMITENTE a
     where  a.m000_id_nf = pnSeqNota
     and    nvl(vnAppOrigem, 0) = 14
     and    nvl(vsIndIEDest, '0') = '9';

     -- registro H - Pessoas autorizadas para o download do XML da NF-e
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
            vsNomeArquivo, 2550,
            '2550;' ||
            decode(a.tipopessoa, 'J', lpad(a.nrocgccpf, 12, '0') || lpad(a.digcgccpf, 2, '0'), lpad(a.nrocgccpf, 9, '0') || lpad(a.digcgccpf, 2, '0')),
            pnSeqNota
     from   max_empresadownloadxml a
     where  a.nroempresa = pnNroEmpresa;

     ---registro H - Detalhamento de Produto e Serviços da NF-e
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha,
        seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1A-', to_char(a.m014_id_item), a.m014_nr_item,
        '3000;' ||
        NVL(a.M014_Cd_Produtoaux_C5, A.M014_CD_PRODUTO) || ';' ||
        NVL(a.M014_CD_EAN, nvl(a.M014_CD_EAN_TRIB, decode(vsPDVersaoXml, '4', 'SEM GTIN', ''))) || ';' ||
        trim(convert (REPLACE( REPLACE( REGEXP_REPLACE(a.M014_DS_PRODUTO,vsCaracteresEspeciais,NULL), chr(13), null),chr(10),null) , 'US7ASCII') ) || ';' ||
        a.M014_CD_NCM || ';' ||
        a.M014_CD_NVEC5 || ';' ||
        case when vsPDGeraCestGenerico = 'S' and a.codcest is null and m014_CSOSN_C5 in ('060','090') then '9999999'
        else lpad(a.codcest,7,0)
        end || ';' ||
        decode(vsPDVersaoXml,
                   '4', case when a.codcest is NULL then
                          ';;'
                        else
                          a.Indescalarelevante || ';' ||
                          case when a.Indescalarelevante = 'N' then
                            a.cnpjfabricante || a.digcnpjfabricante
                          else
                            ''
                          end || ';'
                        end
                        || case
                             when vsUFEmpresa = 'RS' and M014_DM_TRIB_ICMS = 0 then
                               null
                             else
                               nvl(a.codajusteefd, fBuscaCSTSemCbeneF(vsUFEmpresa, m014_CSOSN_C5))
                           end || ';',
                   null
        ) ||
        a.M014_CD_EX_TIPI || ';' ||
        a.M014_CD_CFOP || ';' ||
        a.M014_DS_UNID_COM || ';' ||
        fc5ConverteNumberToChar(a.M014_VL_QTDE_COM, 11, 4) || ';' ||
        fc5ConverteNumberToChar(a.M014_VL_UNIT, 11, 10) || ';' ||
        fc5ConverteNumberToChar(a.M014_VL_TOTAL_BRUTO) || ';' ||
        NVL(a.M014_CD_EAN_TRIB, decode(vsPDVersaoXml, '4', 'SEM GTIN', '')) || ';' ||
        a.M014_DS_UNID_TRIB || ';' ||
        fc5ConverteNumberToChar(a.M014_VL_QTDE_TRIB, 11, 4) || ';' ||
        fc5ConverteNumberToChar(a.M014_VL_UNIT_TRIBUTAVEL, 11, 10) || ';' ||
        fc5ConverteNumberToChar(fRetNullQdoParamZero(a.M014_VL_TOTAL_FRETE)) || ';' ||
        fc5ConverteNumberToChar(fRetNullQdoParamZero(a.M014_VL_TOTAL_SEGURO)) || ';' ||
        fc5ConverteNumberToChar(fRetNullQdoParamZero(a.M014_VL_DESCONTO)) || ';' ||
        fc5ConverteNumberToChar(fRetNullQdoParamZero(a.M014_VL_OUTRAS_DESPESAS)) || ';' ||
        a.M014_DM_ITEM_TOTAL || ';' ||
        a.M014_NR_PED_COMP || ';' ||
        a.M014_NR_ITEM_PED_COMP || ';' ||
        a.M014_NRO_FCI_C5 ||
        CASE
          WHEN vsPDVersaoXml = '4' THEN
            fc5_BuscaCampoNotaTecnica(a.M014_CD_CBARRA, 2020005, pnNroEmpresa, 4, 1, 160, vdDtaHorEmissao) ||
            fc5_BuscaCampoNotaTecnica(a.M014_CD_CBARRA_TRIB, 2020005, pnNroEmpresa, 4, 1, 161, vdDtaHorEmissao) ||
            fc5_BuscaCampoNotaTecnica(a.M014_CD_CRED_PRESUMIDO, 2019001, pnNroEmpresa, 4, 1.60, 163, vdDtaHorEmissao) ||
            fc5_BuscaCampoNotaTecnica(decode(a.M014_CD_CRED_PRESUMIDO,null,null,rtrim(to_char(a.M014_ALIQ_CRED_PRESUMIDO, csFormatoNumber3_4), ',')), 2019001, pnNroEmpresa, 4, 1.60, 164, vdDtaHorEmissao, 'S', 3, 4) ||
            fc5_BuscaCampoNotaTecnica(decode(a.M014_CD_CRED_PRESUMIDO,null,null,rtrim(to_char(a.M014_VL_CRED_PRESUMIDO, csFormatoNumber13_2), ',')), 2019001, pnNroEmpresa, 4, 1.60, 165, vdDtaHorEmissao, 'S', 13, 2) ||
            fc5_BuscaCampoNotaTecnica(a.M014_TP_INDBEMMOVELUSADO, 2025002, pnNroEmpresa, 4, 1.30, 8, vdDtaHorEmissao) ||
            fc5_BuscaCampoNotaTecnica(a.M014_DM_INDCREDPRESIBSZFM, 2025002, pnNroEmpresa, 4, 1.30, 117, vdDtaHorEmissao)
          ELSE
            ''
        END,
        pnSeqNota
     from   TMP_M014_item a
     where a.m000_id_nf = pnSeqNota;

     --- DI - Declaração de Importação
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha,
        seqnotafiscal)
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1BA', to_char(b.m014_id_item), b.m014_nr_item,
        '3001;' || c.m019_nr_documento                                                                  || ';' ||
                  to_char(c.m019_dt_registro, 'YYYY-MM-DD')                                             || ';' ||
                  trim(convert(REGEXP_REPLACE(c.m019_ds_local ,'[><,¬/&]',NULL), 'US7ASCII'))           || ';' ||
                  c.m019_ds_uf                                                                          || ';' ||
                  to_char(c.m019_dt_saida, 'YYYY-MM-DD')                                                || ';' ||
                  a.indviatransporte                                                                    || ';' ||
                  fc5ConverteNumberToChar(nvl(a.vlrAFRMM,0), 13)                                        || ';' ||
                  a.indformaimport                                                                      ||
                  COALESCE(
                    FC5_BUSCACAMPONOTATECNICA(
                      DECODE(D.FISICAJURIDICA, 'J', LPAD(D.NROCGCCPF, 12, 0) || LPAD(D.DIGCGCCPF, 2, 0),
                                                    LPAD(D.NROCGCCPF, 9, '0') || LPAD(D.DIGCGCCPF, 2, '0')), 2023004, pnNroEmpresa, 4, 1.20, 300, vdDtaHorEmissao),
                    ';' || lpad(d.nrocgccpf, 12, '0') || lpad(d.digcgccpf, 2, '0'))                  || ';' ||
                  d.uf                                                                                  || ';' ||
                  c.m019_cd_exportador as linha,
        a.seqnotafiscal
       from   mlf_notafiscal a, TMP_M014_item b, TMP_M019_DI c,
              ge_pessoa d
       where  a.seqnotafiscal = pnSeqNota
       and    a.seqnotafiscal = b.m000_id_nf
       and    b.m014_id_item = c.m014_id_item
       and    a.sepessoaadencomenda = d.seqpessoa(+)
       and    c.m019_nr_documento is not null;

      insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha, seqnotafiscal)
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1BB',to_char(b.m014_id_item), b.m014_nr_item,
        '3002;' || d.m020_nr_adicao || ';' || d.m020_nr_seq || ';'|| d.M020_CD_FABRICANTE || ';' ||

        decode (d.m020_vl_desconto, 0, null, null, null, fc5ConverteNumberToChar(d.m020_vl_desconto,
                 13)) || ';' || d.m020_nr_drawback as linha,
        a.seqnotafiscal
       from   mlf_notafiscal a, TMP_M014_item b, TMP_M019_DI c, tmp_m020_adicao d
       where  a.seqnotafiscal = pnSeqNota
       and    a.seqnotafiscal = b.m000_id_nf
       and    b.m014_id_item = c.m014_id_item
       and    c.m019_nr_documento is not null
       and    c.m019_id_di = d.m019_id_di;

      insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha, seqnotafiscal)
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1BC',to_char(b.m014_id_item), b.m014_nr_item,
        '3005;' || d.m020_nr_drawback as linha,
        a.seqnotafiscal
       from   mlf_notafiscal a, TMP_M014_item b, TMP_M019_DI c, tmp_m020_adicao d
       where  a.seqnotafiscal = pnSeqNota
       and    a.seqnotafiscal = b.m000_id_nf
       and    b.m014_id_item = c.m014_id_item
       and    c.m019_nr_documento is not null
       and    c.m019_id_di = d.m019_id_di
       and    d.m020_nr_drawback is not null;

      insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha, seqnotafiscal)
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1BC',to_char(b.m014_id_item), b.m014_nr_item,
        '3008;'                                              ||
         e.m017_nr_lote                                      || ';' ||
         fc5ConverteNumberToChar(e.m017_vl_qtd_lote, 10, 3)  || ';' ||
         to_char(e.m017_dt_fabr, 'yyyy-MM-dd')               || ';' ||
         to_char(e.m017_dt_validade, 'yyyy-MM-dd')                                               || ';' ||
         to_char(e.codagregacao),
         pnSeqNota

       from   TMP_M014_item b, tmp_m017_med e
       where  b.m014_id_item = e.m014_id_item
        and   b.m000_id_nf = pnSeqNota
        and   vsPDVersaoXml   = '4'
        AND   (CASE WHEN TRUNC(SYSDATE) >= NVL(to_date(vdPDGeraTagMed, 'dd/mm/yyyy'),to_date('31/12/2050', 'dd/mm/yyyy')) THEN
                decode(nvl(e.m017_nr_lote, '0'),'0','0','1')
               ELSE
                 '1'
               END) = '1';

     --- registro J- Detalhamento Específico de Veículos novos
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1BD', to_char(b.m014_id_item), b.m014_nr_item,
        '3010;' ||
        a.M015_DM_TIPO_OPER      || ';' ||
        a.M015_DS_CHASSI         || ';' ||
        a.M015_NR_COR            || ';' ||
        a.M015_DS_COR            || ';' ||
        a.M015_NR_POTENCIA       || ';' ||
        a.M015_NR_CM3            || ';' ||
        a.M015_VL_PESO_LIQUIDO   || ';' ||
        a.M015_VL_PESO_BRUTO     || ';' ||
        a.M015_NR_SERIE          || ';' ||
        a.M015_TP_COMBUSTIVEL    || ';' ||
        a.M015_NR_MOTOR          || ';' ||
        a.M015_DS_CMKG           || ';' ||
        a.M015_NR_DISTANCIA_EIXO || ';' ||
        a.M015_NR_RENAVAM        || ';' ||
        a.M015_NR_ANO_MODELO     || ';' ||
        a.M015_NR_ANO_FABRICACAO || ';' ||
        a.M015_TP_PINTURA        || ';' ||
        a.M015_NR_TIPO_VEICULO   || ';' ||
        a.M015_NR_ESPECIE        || ';' ||
        a.M015_DS_VIN            || ';' ||
        a.M015_DM_CONDICAO       || ';' ||
        a.M015_NR_MODELO, pnSeqNota
     from  TMP_M015_VEICULO a, TMP_M014_ITEM b
     where a.m014_id_item = b.m014_id_item
     and   b.m000_id_nf = pnSeqNota;

     --- registro K - Detalhamento Específico de Medicamentos
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha,
        seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1C-', MAX(to_char(b.m014_id_item)), b.m014_nr_item,
        '3020;' ||
        CASE WHEN vsIntegraNfeNT2018005 = 'S' THEN
          CASE WHEN A.NROREGMINSAUDE IS NULL THEN
            'ISENTO'
          WHEN instr(upper( fc5limpatexto(A.NROREGMINSAUDE, 'DOCTOe') ),'ISENTO') > 0 THEN
            'ISENTO'
          ELSE
            lpad(a.nroregminsaude, 13, '0')
          END  || ';' ||
          MAX(fc5ConverteNumberToChar(a.M017_VL_PRECO_MAX)) || ';' ||
            A.MOTIVOISENCAOMINSAUDE
        ELSE
          lpad(a.nroregminsaude, 13, '0') || ';' ||
          MAX(fc5ConverteNumberToChar(a.M017_VL_PRECO_MAX))
        END,
        pnSeqNota
     from  TMP_M017_MED a, TMP_M014_ITEM b
     where a.m014_id_item = b.m014_id_item
     and   b.m000_id_nf = pnSeqNota
     and   vsPDVersaoXml = '4'
     and   (  exists( select 1
                      from   map_produto p,
                             map_familia f
                      where  f.seqfamilia = p.seqfamilia
                      and    p.seqproduto = b.seqprodutoc5
                      and    nvl(f.indmedicamento, 'N') = 'S' -- Valida se produto é um medicamento
              ) or
              a.nroregminsaude is not null
           )
     GROUP BY a.nroregminsaude, b.m014_nr_item, a.motivoisencaominsaude;
     --- registro L - Detalhamento Específico de Armamentos
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha,
        seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1D-', to_char(b.m014_id_item), b.m014_nr_item,
        '3030;' ||
        a.M016_DM_ARMA || ';' ||
        a.M016_NR_SERIE || ';' ||
        a.M016_NR_SERIE_CANO || ';' ||
        a.M016_DS_COMPLETA,
        pnSeqNota
     from  TMP_M016_ARMA a, TMP_M014_ITEM b
     where a.m014_id_item = b.m014_id_item
     and   b.m000_id_nf = pnSeqNota;

     --- registro L1 - Detalhamento Específico de Combustíveis
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha, seqnotafiscal)
     SELECT Pnnroempresa, Pssoftpdv, Vddtamovimento, SYSDATE,
        Vsnomearquivo, 3000,'1E-', To_Char(a.M014_Id_Item), b.m014_nr_item,
       '3040;' ||
        a.M018_Nr_Prod_Anp || ';' ||
        Decode( Vspdversaoxml,
                   '4', a.m018_descricaoanp || ';' ||
                        decode( a.m018_nr_prod_anp,
                                  '210203001', fc5ConverteNumberToChar(a.m018_vl_perc_gas_naturalc5, 3, 4) || ';' || -- Percentual do grupo originado do petróleo no grupo GPL.
                                               fc5ConverteNumberToChar(a.m018_vl_percgasnaturalnacional, 3, 4) || ';' || -- Percentual do gás natural nacional ¿ GLGNn para o produto GPL.
                                               fc5ConverteNumberToChar(a.m018_vl_percgasnaturalimport, 3, 4) || ';', -- Percentual do gás importado pGNi para produto GLP.
                                  ';;;') ||
                        fc5ConverteNumberToChar(a.m018_vl_vlrpartidaglp),
                   fc5ConverteNumberToChar(a.M018_Vl_Perc_Gas_Naturalc5, 3, 4)
        ) || ';' ||
        a.M018_Nr_Codif || ';' ||
        fc5ConverteNumberToChar(a.M018_Qt_Comb_Temp, 10, 4) || ';' ||
        a.M018_Ds_Uf_Con ||
        CASE
          WHEN vsPDVersaoXml = '4' THEN
            fc5_BuscaCampoNotaTecnica(a.m018_vl_perc_biodiesel, 2023001, pnNroEmpresa, 4, 1, 228, vdDtaHorEmissao)
          ELSE
            ''
        END,
        Pnseqnota
     FROM TMP_M018_COMB a, TMP_M014_ITEM b
     WHERE a.m014_id_item = b.m014_id_item
     AND a.M000_Id_Nf = Pnseqnota
     AND a.M018_Nr_Prod_Anp IS NOT NULL

     union all

     select pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
            vsNomeArquivo, 3000, '1E1-', to_char(b.m014_id_item), b.m014_nr_item,
            '3043;' ||
            a.M018_ORIG_COMB_IND_IMPORT || ';' || --indImport
            a.M018_ORIG_COMB_COD_UF_ORIG || ';' || --cUFOrig
            case when a.M018_ORIG_COMB_VL_PERC_ORIG = 100 Then
              '100'
            else
              fc5ConverteNumberToChar(a.M018_ORIG_COMB_VL_PERC_ORIG, 3, 4) ----pOrig
            end, pnSeqNota
     FROM   TMP_M018_ORIG_COMB a, TMP_M014_ITEM b
     WHERE  a.m014_id_item = b.m014_id_item
     AND    a.M000_Id_Nf = Pnseqnota
     AND    a.M018_Orig_Comb_Vl_Perc_Orig IS NOT NULL

     union all

     select pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
            vsNomeArquivo, 3000, '1E2-', to_char(b.m014_id_item), b.m014_nr_item,
            '3050;' || vsNroRECOPI as linha,
            pnSeqNota
     from   TMP_M014_ITEM b
     where  b.m000_id_nf   = pnSeqNota
     and    vsNroRECOPI is not null
     and    b.INDPAPELIMUNE = 'S';

     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1F-', to_char(a.m014_id_item), a.m014_nr_item,
        '3090;' ||
        fc5ConverteNumberToChar(a.M014_VL_TOTTRIB),
        pnSeqNota
     FROM  TMP_M014_ITEM a
     where a.m000_id_nf   = pnSeqNota
     AND   NVL(a.M014_VL_TOTTRIB, 0) > 0
      and   nvl(vsPDGeraRegTotImpNFe, 'N') != 'N';

     --- registro M - Tributos Incidentes no Produto ou no serviço
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha,
        seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1G-', to_char(a.m014_id_item), a.m014_nr_item,
        '3100;' ||
        a.M014_DM_ORIG_ICMS || ';' ||
        '00' || ';' ||
        a.M014_DM_MOD_BC_ICMS || ';' ||
        fc5ConverteNumberToChar(a.M014_VL_BC_ICMS)          || ';' ||
        fc5ConverteNumberToChar(a.M014_VL_ALIQ_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(a.M014_VL_ICMS)             || ';' ||
        decode(vsPDVersaoXml, '4',
          decode(vsIndUtilCalcFCP, 'S',
             case when nvl(a.m014_vl_aliq_fcp_icms, 0) + nvl(a.m014_vl_fcp_icms, 0) > 0 then
                fc5ConverteNumberToChar(nvl(a.m014_vl_aliq_fcp_icms, 0)) || ';' ||
                fc5ConverteNumberToChar(nvl(a.m014_vl_fcp_icms, 0))
             else
                ';'
             end,
             case when nvl(a.PERALIQUOTAFECP, 0) + nvl(a.VLRFECP, 0) > 0 then
                fc5ConverteNumberToChar(nvl(a.PERALIQUOTAFECP, 0))  || ';' ||
                fc5ConverteNumberToChar(nvl(a.VLRFECP, 0))
             else
                ';'
             end), null),
        pnSeqNota
     from  TMP_M014_ITEM a, TMP_M001_EMITENTE
     where a.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   a.M014_DM_TRIB_ICMS = 0
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   a.m000_id_nf = pnSeqNota;

     --- registro N- ICMS Normal e ST
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha,
        seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1H-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3103;' ||
        TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
        '10' || ';' ||
        TMP_M014_ITEM.M014_DM_MOD_BC_ICMS || ';' ||
        fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_BC_ICMS, 0)) || ';' ||
        fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_ALIQ_ICMS, 0), 10, 4) || ';' ||
        fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_ICMS, 0)) || ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' then
            case when nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0))) > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, 0), 13)  || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0), 13) || ';'
            else
              ';;;'
            end
          else
            case when nvl(TMP_M014_ITEM.BASCALCFECP, nvl(TMP_M014_ITEM.PERALIQUOTAFECP, nvl(TMP_M014_ITEM.VLRFECP, 0))) > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.BASCALCFECP, 0), 13)    || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.PERALIQUOTAFECP, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.VLRFECP, 0), 13)        || ';'
            else
              ';;;'
            end
          end,
        null)||

        TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS || ';' ||

        case when TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS = 5 then
          null
        else
          case when nvl(TMP_M014_ITEM.PERCMVAST,0) > 0 then
             fc5ConverteNumberToChar(TMP_M014_ITEM.PERCMVAST, 10, 4)
          when fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'M') > 0 then
             fc5ConverteNumberToChar(fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'M'), 10, 4)
          else '0.0000'
        end
        end
        || ';' ||
        fc5ConverteNumberToChar(fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5,null,'SR'), 10, 4) || ';' ||
        fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_BC_ST_ICMS, 0)) || ';' ||
        fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_ALIQ_ST_ICMS, 0), 10, 4) || ';' ||
        fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_ICMS_ST, 0)) || ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' and
             nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0))) > 0 then
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, 0), 13) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, 0), 3) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0), 13)
            else
              ';;'
            end,
         null) ||
        CASE
          WHEN vsPDVersaoXml = '4' THEN
            fc5_BuscaCampoNotaTecnica(TMP_M014_ITEM.M014_VL_ICMS_ST_DESONERADO, 2020005, pnNroEmpresa, 4, 1, 263, vdDtaHorEmissao, 'S', 13, 2) ||
            fc5_BuscaCampoNotaTecnica(TMP_M014_ITEM.M014_MOTIVO_DES_ICMS_ST, 2020005, pnNroEmpresa, 4, 1, 264, vdDtaHorEmissao)
          ELSE
            ''
        END,
        pnSeqNota
     from  TMP_M014_ITEM
     where TMP_M014_ITEM.M014_DM_TRIB_ICMS = 1
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5) > 0
     and (
         case when NVL(TMP_M014_ITEM.PERCMVAST,0) > 0 then NVL(TMP_M014_ITEM.PERCMVAST,0)
              else fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'M')
         end > 0
          OR TMP_M014_ITEM.M014_LANCAMENTOSTC5 IN ('S','O','D')
          OR TMP_M014_ITEM.M014_VL_PERC_CARGA_LIQ > 0
          OR nvl(vnAppOrigem, 0) = '23'
          OR fBuscaCalcDifalStNfe(pnSeqNota,TMP_M014_ITEM.SEQPRODUTOC5) > 0 )
     union all
     --3106
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1I-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3106;' ||
        TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
        decode(TMP_M014_ITEM.M014_DM_TRIB_ICMS, '2', '20', TMP_M014_ITEM.M014_DM_TRIB_ICMS) || ';' ||
        TMP_M014_ITEM.M014_DM_MOD_BC_ICMS || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_REDUC_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS) || ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' then
            case when nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0))) > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0), 13) || ';'
            else
              ';;;'
            end
          else
            case when nvl(TMP_M014_ITEM.BASCALCFECP, nvl(TMP_M014_ITEM.PERALIQUOTAFECP, nvl(TMP_M014_ITEM.VLRFECP, 0)))  > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.BASCALCFECP, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.PERALIQUOTAFECP, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.VLRFECP, 0), 13) || ';'
            else
              ';;;'
            end
          end,
        null)||

             case when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS > 0 and M014_VLRTOTICMSDESONOUTROS > 0 then
                   fc5ConverteNumberToChar(M014_VLRTOTICMSDESONOUTROS)
                  when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS = 9 and TMP_M014_ITEM.VLRDESCICMS > 0 then
                   fc5ConverteNumberToChar(TMP_M014_ITEM.VLRDESCICMS)
                  when  TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (3, 12) and TMP_M014_ITEM.M014_VL_ICMS > 0 then
                   fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS)
             end
        || ';' ||
            case when TMP_M014_ITEM.Codajusteefd is not null and TMP_M014_ITEM.M014_VLRTOTICMSDESONOUTROS > 0 then
                TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
             else
                case when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS = 9 and TMP_M014_ITEM.VLRDESCICMS > 0 then
                       TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
                     when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (3, 12) and TMP_M014_ITEM.M014_VL_ICMS > 0 then
                       TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
                end
             end
         || fc5_BuscaCampoNotaTecnica(case when (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS > 0 and M014_VLRTOTICMSDESONOUTROS > 0) or
                                                (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS = 9 and TMP_M014_ITEM.VLRDESCICMS > 0) or
                                                (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (3, 12) and TMP_M014_ITEM.M014_VL_ICMS > 0)
                                           then TMP_M014_ITEM.M014_DM_DEDUZ_DESON
                                           else null
                                      end , 2023004, pnNroEmpresa, 4, 1.20, 300, vdDtaHorEmissao) as linha,
        pnSeqNota
     from  TMP_M014_ITEM
     where TMP_M014_ITEM.M014_DM_TRIB_ICMS = 2
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   (fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5) > 0 or fc5_busca_apporigem(TMP_M014_ITEM.m000_id_nf) = 1)
     union all
     --3110
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1J-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3110;' ||
        TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
        decode(TMP_M014_ITEM.M014_DM_TRIB_ICMS, 3, '30', TMP_M014_ITEM.M014_DM_TRIB_ICMS) || ';' ||
        TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS || ';' ||
        case when TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS = 5 then
          null
        else
          fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_PERC_MARG_ICMS,0), 10, 4)
        end
        || ';' ||
        fc5ConverteNumberToChar(fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'SR'), 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ST_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ST_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS_ST) || ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' and
                nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0))) > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0), 13) || ';'
            else
              ';;;'
          end,
        null)||
        case when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS = 9 and TMP_M014_ITEM.VLRDESCICMS > 0 then
                fc5ConverteNumberToChar(TMP_M014_ITEM.VLRDESCICMS)
             when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (6, 7) then
               case when TMP_M014_ITEM.M014_VL_ICMS > 0 then
                     fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS)
                    when TMP_M014_ITEM.VLRDESCICMS > 0 then
                     fc5ConverteNumberToChar(TMP_M014_ITEM.VLRDESCICMS)
               end
        end
        || ';' ||
        case when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (6, 7, 9) and ( TMP_M014_ITEM.M014_VL_ICMS > 0 or TMP_M014_ITEM.VLRDESCICMS > 0 ) then
             TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
        end
        ||
        fc5_BuscaCampoNotaTecnica(case when (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS = 9 and TMP_M014_ITEM.VLRDESCICMS > 0) or
                                            (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (6, 7) and (TMP_M014_ITEM.M014_VL_ICMS > 0 or TMP_M014_ITEM.VLRDESCICMS > 0))
                                       then TMP_M014_ITEM.M014_DM_DEDUZ_DESON
                                       else null
                                  end, 2023004, pnNroEmpresa, 4, 1.20, 314, vdDtaHorEmissao) as linha,
        pnSeqNota
     from  TMP_M014_ITEM
     where TMP_M014_ITEM.M014_DM_TRIB_ICMS = 3
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   (fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5) > 0 or fc5_busca_apporigem(TMP_M014_ITEM.m000_id_nf) = 1)
     union all
     --3113
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1K1-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3113;' ||
        TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
        decode(TMP_M014_ITEM.M014_DM_TRIB_ICMS, 4, '40', 5, '41', 6, '50') || ';' ||
       --210109
       case when TMP_M014_ITEM.Codajusteefd is not null and TMP_M014_ITEM.M014_VLRTOTICMSDESONOUTROS > 0 then
          fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VLRTOTICMSDESONOUTROS)
        else
            case when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) then
                case when  TMP_M014_ITEM.VLRDESCICMS > 0 then
                     fc5ConverteNumberToChar(TMP_M014_ITEM.VLRDESCICMS)
                when  TMP_M014_ITEM.M014_VL_ICMS > 0 then
                     fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_ICMS, 0))
                end
            end
         end

       || ';' ||
             case when TMP_M014_ITEM.Codajusteefd is not null and TMP_M014_ITEM.M014_VLRTOTICMSDESONOUTROS > 0 then
                TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
             else
             case when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
                 and (TMP_M014_ITEM.M014_VL_ICMS > 0 OR TMP_M014_ITEM.VLRDESCICMS > 0)then
                   TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
               end
             end
       || fc5_BuscaCampoNotaTecnica(case when (TMP_M014_ITEM.Codajusteefd is not null and TMP_M014_ITEM.M014_VLRTOTICMSDESONOUTROS > 0) or
                                              (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11) and (TMP_M014_ITEM.VLRDESCICMS > 0 or TMP_M014_ITEM.M014_VL_ICMS > 0))
                                         then TMP_M014_ITEM.M014_DM_DEDUZ_DESON
                                         else null
                                    end , 2023004, pnNroEmpresa, 4, 1.20, 319, vdDtaHorEmissao) as linha,
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and TMP_M014_ITEM.M014_DM_TRIB_ICMS in (4,5,6)
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota

     UNION ALL

     --3116
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1L-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3116;' ||
        TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
        decode(TMP_M014_ITEM.M014_DM_TRIB_ICMS, 7, '51', TMP_M014_ITEM.M014_DM_TRIB_ICMS) || ';' ||
        TMP_M014_ITEM.M014_DM_MOD_BC_ICMS || ';' ||
        fc5ConverteNumberToChar(fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'TR'), 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ICMS, 10) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(decode(nvl(TMP_M014_ITEM.M014_VL_ICMS_OPPROPRIAC5, 0), 0, '0.00', TMP_M014_ITEM.M014_VL_ICMS_OPPROPRIAC5)) || ';' ||
        fc5ConverteNumberToChar(case when TMP_M014_ITEM.M014_TIPOCALCICMSFISCI_C5 = 25 then
                                                          TMP_M014_ITEM.M014_PERALIQICMSDIF_C5
                                                     else --210109
                                                          NVLZERO(TMP_M014_ITEM.M014_PERDIFERIDO_C5, decode(fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'TR'), 100, 100, decode(TMP_M014_ITEM.M014_VL_ICMS_DIFC5,0,TMP_M014_ITEM.M014_VL_ICMS,TMP_M014_ITEM.M014_VL_ICMS_DIFC5) * 100 / decode(TMP_M014_ITEM.M014_VL_ICMS, 0, null, TMP_M014_ITEM.M014_VL_ICMS) )
                                                          )
                                                end, 10, 4) || ';' ||
        fc5ConverteNumberToChar(decode(TMP_M014_ITEM.M014_VL_ICMS_DIFC5,0,TMP_M014_ITEM.M014_VL_ICMS,TMP_M014_ITEM.M014_VL_ICMS_DIFC5)) || ';' ||
        nvl(fc5ConverteNumberToChar( case
                                       when TMP_M014_ITEM.M014_TIPOCALCICMSFISCI_C5 = 25 and TMP_M014_ITEM.M014_DM_TRIB_ICMS in ('7', '51') and
                                            TMP_M014_ITEM.M014_VL_ICMS_OPPROPRIAC5 - TMP_M014_ITEM.M014_VL_ICMS_DIFC5 != TMP_M014_ITEM.M014_VL_ICMS and
                                            TMP_M014_ITEM.M014_VL_ICMS_DIFC5 > 0 then
                                              TMP_M014_ITEM.M014_VL_ICMS_OPPROPRIAC5 - TMP_M014_ITEM.M014_VL_ICMS_DIFC5
                                       when TMP_M014_ITEM.M014_TIPOCALCICMSFISCI_C5 = 25 and TMP_M014_ITEM.M014_DM_TRIB_ICMS in ('7', '51') and
                                            TMP_M014_ITEM.M014_VL_ICMS_OPPROPRIAC5 - TMP_M014_ITEM.M014_VL_ICMS_DIFC5 = TMP_M014_ITEM.M014_VL_ICMS and
                                            TMP_M014_ITEM.M014_VL_ICMS_DIFC5 = 0 then
                                        round ((fc5ConverteNumberToChar(decode(TMP_M014_ITEM.M014_VL_ICMS_DIFC5,0,TMP_M014_ITEM.M014_VL_ICMS,TMP_M014_ITEM.M014_VL_ICMS_DIFC5)) *
                                               (fc5ConverteNumberToChar(case when TMP_M014_ITEM.M014_TIPOCALCICMSFISCI_C5 = 25 then
                                                          TMP_M014_ITEM.M014_PERALIQICMSDIF_C5
                                                     else
                                                          NVLZERO(TMP_M014_ITEM.M014_PERDIFERIDO_C5, decode(fBuscaPerRedICMS(21956, TMP_M014_ITEM.SEQPRODUTOC5, null, 'TR'), 100, 100, decode(TMP_M014_ITEM.M014_VL_ICMS_DIFC5,0,TMP_M014_ITEM.M014_VL_ICMS,TMP_M014_ITEM.M014_VL_ICMS_DIFC5) * 100 / decode(TMP_M014_ITEM.M014_VL_ICMS, 0, null, TMP_M014_ITEM.M014_VL_ICMS) )
                                                          )
                                                end, 10, 4)/100)),2)
                                       when TMP_M014_ITEM.M014_TIPOCALCICMSFISCI_C5 = 25 or vsUFEmpresa = 'RJ' then
                                         TMP_M014_ITEM.M014_VL_ICMS
                                       else
                                         TMP_M014_ITEM.M014_VL_ICMS_OPPROPRIAC5 - TMP_M014_ITEM.M014_VL_ICMS
                                     end), '0.00') || ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' then
            case when nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0))) > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0), 13)
            else
              ';;'
            end
          else
            case when nvl(TMP_M014_ITEM.BASCALCFECP, nvl(TMP_M014_ITEM.PERALIQUOTAFECP, nvl(TMP_M014_ITEM.VLRFECP, 0)))  > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.BASCALCFECP, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.PERALIQUOTAFECP, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.VLRFECP, 0), 13)
            else
              ';;'
            end
          end,
        null) ||
        case
          when vsPDVersaoXml = '4' then
            case when nvl(TMP_M014_ITEM.M014_ALIQ_FCP_ICMS_DIF, 0) > 0 then
              fc5_BuscaCampoNotaTecnica(rtrim(to_char(TMP_M014_ITEM.M014_ALIQ_FCP_ICMS_DIF, csFormatoNumber3_4), ','), 2020005, pnNroEmpresa, 4, 1, 307, vdDtaHorEmissao, 'S', 3, 4)
            else
              ';'
            end ||
            case when NVL(TMP_M014_ITEM.M014_VL_FCP_ICMS_DIF, 0) > 0 then
              fc5_BuscaCampoNotaTecnica(rtrim(to_char(TMP_M014_ITEM.M014_VL_FCP_ICMS_DIF, csFormatoNumber13_2), ','), 2020005, pnNroEmpresa, 4, 1, 308, vdDtaHorEmissao, 'S', 13, 2)
            else
              ';'
            end ||
            case when NVL(TMP_M014_ITEM.M014_VL_FCP_ICMS_EFET, 0) > 0 then
              fc5_BuscaCampoNotaTecnica(rtrim(to_char(TMP_M014_ITEM.M014_VL_FCP_ICMS_EFET, csFormatoNumber13_2), ','), 2020005, pnNroEmpresa, 4, 1, 309, vdDtaHorEmissao, 'S', 13, 2)
            else
              ';'
            end ||
            fc5_BuscaCampoNotaTecnica(TMP_M014_ITEM.M014_CD_BENEF_RBC, 2019001, pnNroEmpresa, 4, 1.60, 336, vdDtaHorEmissao)
          else
            ''
        end,
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_TRIB_ICMS = 7
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   (fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5) > 0 or fc5_busca_apporigem(TMP_M014_ITEM.m000_id_nf) = 1)
     union all
     --3120
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1M-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3120;' ||
        case when TMP_M014_ITEM.M014_DM_TRIB_ICMS = 8 AND nvl(vsPDCGO_IcmsOp_Distrib_NfEntr, ' ') = ' ' Then
          TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';60;;' || decode(vsPDVersaoXml, '4', ';;;;;;;;', '')
        else
            TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
            decode(TMP_M014_ITEM.M014_DM_TRIB_ICMS, 8, '60', TMP_M014_ITEM.M014_DM_TRIB_ICMS) || ';' ||
            fc5ConverteNumberToChar(COALESCE(TMP_M014_ITEM.M014_Bc_Icms_St_Distrib, NVL(TMP_M014_ITEM.M014_VL_BC_ST_ICMS, '0'))) || ';' ||
            decode(vsPDVersaoXml, '4',
            fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_ALIQ_ICMS_ST_DISTRIB,0), 3)|| ';',
            null)||
            fc5ConverteNumberToChar(COALESCE(TMP_M014_ITEM.M014_Vl_Icms_St_Distrib, NVL(TMP_M014_ITEM.M014_VL_ICMS_ST, '0'))) || ';' ||
            decode(vsPDVersaoXml, '4',
              case when vsIndUtilCalcFCP = 'S' then
                  case when nvl(TMP_M014_ITEM.m014_vl_bc_fcp_ret, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_ret, nvl(TMP_M014_ITEM.m014_vl_fcp_ret, 0))) > 0 then
                     fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_ret, 0), 13) || ';' ||
                     fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_ret, 0), 3) || ';' ||
                     fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_ret, 0), 13)
                  else
                    ';;'
                  end
              else
                  case when nvl(TMP_M014_ITEM.BASCALCFECP, nvl(TMP_M014_ITEM.PERALIQUOTAFECP, nvl(TMP_M014_ITEM.VLRFECP, 0)))  > 0 then
                    fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.BASCALCFECP, 0), 13) || ';' ||
                    fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.PERALIQUOTAFECP, 0), 3) || ';' ||
                    fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.VLRFECP, 0), 13)
                  else
                    ';;'
                  end
              end                          || ';' ||
            trim(to_char(nvl(TMP_M014_ITEM.PERREDBCICMSEFET, 0),'990d00', 'nls_numeric_characters=''.,'''))            || ';' ||
            trim(to_char(nvl(TMP_M014_ITEM.VLRBASEICMSEFET, 0), '9999999999990d00', 'nls_numeric_characters=''.,'''))  || ';' ||
            trim(to_char(nvl(TMP_M014_ITEM.PERALIQICMSEFET, 0), '990d00', 'nls_numeric_characters=''.,'''))            || ';' ||
            trim(to_char(nvl(TMP_M014_ITEM.VLRICMSEFET, 0),     '9999999999990d00', 'nls_numeric_characters=''.,'''))  ||
            CASE WHEN vsIntegraNfeNT2018005 = 'S' THEN
              ';' ||fc5ConverteNumberToChar(NVL(TMP_M014_ITEM.M014_VL_OP_PROP_DIST,0),13)
            ELSE
              null
            END,
            null)
          end,
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_TRIB_ICMS = 8
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   not exists (select 1
                       from  Tmp_M018_Comb ANP
                       where M018_Nr_Prod_Anp in
                       ('210203001', '320101001', '320101002', '320102002', '320102001', '320102003', '320102005', '320201001',
                        '320103001', '220102001', '320301001', '320103002', '820101032', '820101026', '820101027', '820101004',
                        '820101005', '820101022', '820101031', '820101030', '820101014', '820101006', '820101016', '820101015',
                        '820101025', '820101017', '820101018', '820101019', '820101020', '820101021', '420105001', '420101005',
                        '420101004', '420102005', '420102004', '420104001', '820101033', '820101034', '420106001', '820101011',
                        '820101003', '820101013', '820101012', '420106002', '830101001', '420301004', '420202001', '420301001',
                        '420301002', '410103001', '410101001', '410102001', '430101004', '510101001', '510101002', '510102001',
                        '510102002', '510201001', '510201003', '510301003', '510103001', '510301001')
                        and   ANP.m014_id_item = TMP_M014_ITEM.m014_id_item
                        and   ANP.m000_id_nf   = TMP_M014_ITEM.m000_id_nf)
     union all
     --3121
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1N-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3121;' ||
        TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
        decode(TMP_M014_ITEM.M014_DM_TRIB_ICMS, 27, '61', TMP_M014_ITEM.M014_DM_TRIB_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_AD_REM_ICMS_RET, 2, 4)|| ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS_MONO_RET, 13, 2) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ICMS_MONO_RET, 11, 4),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_TRIB_ICMS = 27
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota

     union all
     --3123
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1N-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3123;' ||
        TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
        decode(TMP_M014_ITEM.M014_DM_TRIB_ICMS, 9, '70', TMP_M014_ITEM.M014_DM_TRIB_ICMS) || ';' ||
        TMP_M014_ITEM.M014_DM_MOD_BC_ICMS || ';' ||
        fc5ConverteNumberToChar(fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'TR'), 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS) || ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' then
            case when nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0))) > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0), 13) || ';'
            else
              ';;;'
            end
          else
            case when nvl(TMP_M014_ITEM.BASCALCFECP, nvl(TMP_M014_ITEM.PERALIQUOTAFECP, nvl(TMP_M014_ITEM.VLRFECP, 0)))  > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.BASCALCFECP, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.PERALIQUOTAFECP, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.VLRFECP, 0), 13) || ';'
            else
              ';;;'
            end
          end,
        null)||
        TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS || ';' ||
        case when TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS = 5 then
          null
        else
          decode(TMP_M014_ITEM.M014_VL_PERC_MARG_ICMS, 0, '0.0000', fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_MARG_ICMS, 10, 4))
        end
        || ';'||
        fc5ConverteNumberToChar(fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null,'SR'), 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ST_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ST_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS_ST) || ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' and
            nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0))) > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0), 13) || ';'
            else
              ';;;'
          end,
        null)||
             case when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS > 0 and M014_VLRTOTICMSDESONOUTROS > 0 then
                   fc5ConverteNumberToChar(M014_VLRTOTICMSDESONOUTROS)
                  when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS = 9 and TMP_M014_ITEM.VLRDESCICMS > 0 then
                   fc5ConverteNumberToChar(TMP_M014_ITEM.VLRDESCICMS)
                  when  TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (3, 12) and TMP_M014_ITEM.M014_VL_ICMS > 0 then
                   fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS)
             end
        || ';' ||
            case when TMP_M014_ITEM.Codajusteefd is not null and TMP_M014_ITEM.M014_VLRTOTICMSDESONOUTROS > 0 then
                TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
            else
                case when  TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (3, 9, 12) and (TMP_M014_ITEM.M014_VL_ICMS > 0 or TMP_M014_ITEM.VLRDESCICMS > 0) then
                  TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
                end
            end ||
        CASE
          WHEN vsPDVersaoXml = '4' THEN
            fc5_BuscaCampoNotaTecnica(TMP_M014_ITEM.M014_VL_ICMS_ST_DESONERADO, 2020005, pnNroEmpresa, 4, 1, 344, vdDtaHorEmissao, 'S', 13, 2) ||
            fc5_BuscaCampoNotaTecnica(TMP_M014_ITEM.M014_MOTIVO_DES_ICMS_ST, 2020005, pnNroEmpresa, 4, 1, 345, vdDtaHorEmissao)
          ELSE
            ''
        END
        || fc5_BuscaCampoNotaTecnica(case when (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS > 0 and M014_VLRTOTICMSDESONOUTROS > 0) or
                                               (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS = 9 and TMP_M014_ITEM.VLRDESCICMS > 0) or
                                               (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (3, 12) and TMP_M014_ITEM.M014_VL_ICMS > 0)
                                          then TMP_M014_ITEM.M014_DM_DEDUZ_DESON
                                          else null
                                     end , 2023004, pnNroEmpresa, 4, 1.20, 386, vdDtaHorEmissao)  as linha,
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_TRIB_ICMS = 9
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   (fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5) > 0 or fc5_busca_apporigem(TMP_M014_ITEM.m000_id_nf) = 1)
     union all
     --3126
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1O-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3126;' ||
        TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
        decode(TMP_M014_ITEM.M014_DM_TRIB_ICMS, 10, '90', TMP_M014_ITEM.M014_DM_TRIB_ICMS) || ';' ||
           case when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS > 0 and M014_VLRTOTICMSDESONOUTROS > 0 then
                   fc5ConverteNumberToChar(M014_VLRTOTICMSDESONOUTROS)
                  when TMP_M014_ITEM.M014_MOTIVO_DES_ICMS = 9 and TMP_M014_ITEM.VLRDESCICMS > 0 then
                   fc5ConverteNumberToChar(TMP_M014_ITEM.VLRDESCICMS)
                  when  TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (3, 12) and TMP_M014_ITEM.M014_VL_ICMS > 0 then
                   fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS)
             end
         || ';' ||
            case when TMP_M014_ITEM.Codajusteefd is not null and TMP_M014_ITEM.M014_VLRTOTICMSDESONOUTROS > 0 then
                TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
            else
                case when  TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (3, 9, 12) and (TMP_M014_ITEM.M014_VL_ICMS > 0 or TMP_M014_ITEM.VLRDESCICMS > 0) then
                  TMP_M014_ITEM.M014_MOTIVO_DES_ICMS
                end
            end  ||
        CASE
          WHEN vsPDVersaoXml = '4' THEN
            fc5_BuscaCampoNotaTecnica(TMP_M014_ITEM.M014_VL_ICMS_ST_DESONERADO, 2020005, pnNroEmpresa, 4, 1, 350, vdDtaHorEmissao, 'S', 13, 2) ||
            fc5_BuscaCampoNotaTecnica(TMP_M014_ITEM.M014_MOTIVO_DES_ICMS_ST, 2020005, pnNroEmpresa, 4, 1, 351, vdDtaHorEmissao)
          ELSE
            ''
        END
        || fc5_BuscaCampoNotaTecnica(case when (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS > 0 and M014_VLRTOTICMSDESONOUTROS > 0) or
                                               (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS = 9 and TMP_M014_ITEM.VLRDESCICMS > 0) or
                                               (TMP_M014_ITEM.M014_MOTIVO_DES_ICMS in (3, 12) and TMP_M014_ITEM.M014_VL_ICMS > 0)
                                          then TMP_M014_ITEM.M014_DM_DEDUZ_DESON
                                          else null
                                     end , 2023004, pnNroEmpresa, 4, 1.20, 393, vdDtaHorEmissao) as linha,
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_TRIB_ICMS = 10
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     union all
     -- 3127
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1OA', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3127;' ||
        TMP_M014_ITEM.M014_DM_MOD_BC_ICMS || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ICMS) || ';' ||
        fc5ConverteNumberToChar((Case When TMP_M014_ITEM.M014_VL_PERC_REDUC_ICMS = 100 THEN NULL
                                      When NVL(TMP_M014_ITEM.M014_VL_BC_ICMS,0) > 0 THEN TMP_M014_ITEM.M014_VL_PERC_REDUC_ICMS
                                      ELSE NULL END), 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS)|| ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' then
            case when nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0))) > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_icms, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_icms, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_icms, 0), 13)
            else
              ';;'
            end
          else
            case when nvl(TMP_M014_ITEM.BASCALCFECP, nvl(TMP_M014_ITEM.PERALIQUOTAFECP, nvl(TMP_M014_ITEM.VLRFECP, 0)))  > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.BASCALCFECP, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.PERALIQUOTAFECP, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.VLRFECP, 0), 13)
            else
              ';;'
            end
          end,
        null),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_TRIB_ICMS = 10
     and   M014_DM_MOD_BC_ICMS IN (0, 1, 2, 3)
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     union all
     -- 3128
    select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1OB', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3128;' ||
        TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS || ';' ||
        case when TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS = 5 then
          null
        else
          case when fBuscaPerRedICMS( pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'M') > 0 then
             fc5ConverteNumberToChar(fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'M'), 10, 4)
          else '0.0000'
          end
        end
        || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_REDUC_ICMS_ST, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ST_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ST_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS_ST)|| ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' and
            nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0))) > 0 then
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, 0), 13) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, 0), 3) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0), 13)
            else
              ';;'
          end,
        null),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   TMP_M014_ITEM.M014_DM_TRIB_ICMS = 10
     and   TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS IN (0, 1, 2, 3, 4, 5)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     union all
     -- 3133
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1OC-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3133;' ||
        TMP_M014_ITEM.M014_DM_ORIG_ICMS                                                                                      || ';' ||
        decode(TMP_M014_ITEM.M014_DM_TRIB_ICMS, 8, '60', TMP_M014_ITEM.M014_DM_TRIB_ICMS)                                    || ';' ||
        fc5ConverteNumberToChar(COALESCE(TMP_M014_ITEM.M014_Bc_Icms_St_Distrib, NVL(TMP_M014_ITEM.M014_VL_BC_ST_ICMS, '0'))) || ';' ||
        fc5ConverteNumberToChar(COALESCE(TMP_M014_ITEM.M014_Vl_Icms_St_Distrib, NVL(TMP_M014_ITEM.M014_VL_ICMS_ST, '0')))    || ';0.00;0.00' ||
        CASE WHEN vsIntegraNfeNT2018005 = 'S' THEN
        ';' || decode(vsPDVersaoXml, '4',
               case when vsIndUtilCalcFCP = 'S' then
                    case when nvl(TMP_M014_ITEM.m014_vl_bc_fcp_ret, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_ret, nvl(TMP_M014_ITEM.m014_vl_fcp_ret, 0))) > 0 then
                              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_ret, 0), 13) || ';' ||
                              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_ret, 0), 3) || ';' ||
                              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_ret, 0), 13)
                         else ';;'
                    end
               else
                    case when nvl(TMP_M014_ITEM.BASCALCFECP, nvl(TMP_M014_ITEM.PERALIQUOTAFECP, nvl(TMP_M014_ITEM.VLRFECP, 0)))  > 0 then
                              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.BASCALCFECP, 0), 13)    || ';' ||
                              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.PERALIQUOTAFECP, 0), 3) || ';' ||
                              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.VLRFECP, 0), 13)
                         else ';;'
                    end
               end                                                                              || ';' || -- vBCFCPSTRet / pFCPSTRet / vFCPSTRet
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_ALIQ_ICMS_ST_DISTRIB,0), 3)    || ';' || -- pST
               fc5ConverteNumberToChar(NVL(TMP_M014_ITEM.M014_VL_OP_PROP_DIST,0),13)            || ';' || -- vICMSSubstituto
               trim(to_char(nvl(TMP_M014_ITEM.PERREDBCICMSEFET, 0),'990d00', 'nls_numeric_characters=''.,'''))            || ';' || -- pRedBCEfet
               trim(to_char(nvl(TMP_M014_ITEM.VLRBASEICMSEFET, 0), '9999999999990d00', 'nls_numeric_characters=''.,'''))  || ';' || -- vBCEfet
               trim(to_char(nvl(TMP_M014_ITEM.PERALIQICMSEFET, 0), '990d00', 'nls_numeric_characters=''.,'''))            || ';' || -- pICMSEfet
               trim(to_char(nvl(TMP_M014_ITEM.VLRICMSEFET, 0),     '9999999999990d00', 'nls_numeric_characters=''.,'''))            -- vICMSEfet
        ,null)
        ELSE
         null
        END,
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE, Tmp_M018_Comb a
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   a.m014_id_item = TMP_M014_ITEM.m014_id_item
     and   a.m000_id_nf   = tmp_m014_item.m000_id_nf
     and   TMP_M014_ITEM.M014_DM_TRIB_ICMS = 8
     and   TMP_M001_EMITENTE.M001_DM_CRT NOT IN (0, 3)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   a.M018_Nr_Prod_Anp  in ('210203001', '320101001', '320101002', '320102002', '320102001', '320102003', '320102005', '320201001',
                                   '320103001', '220102001', '320301001', '320103002', '820101032', '820101026', '820101027', '820101004',
                                   '820101005', '820101022', '820101031', '820101030', '820101014', '820101006', '820101016', '820101015',
                                   '820101025', '820101017', '820101018', '820101019', '820101020', '820101021', '420105001', '420101005',
                                   '420101004', '420102005', '420102004', '420104001', '820101033', '820101034', '420106001', '820101011',
                                   '820101003', '820101013', '820101012', '420106002', '830101001', '420301004', '420202001', '420301001',
                                   '420301002', '410103001', '410101001', '410102001', '430101004', '510101001', '510101002', '510102001',
                                   '510102002', '510201001', '510201003', '510301003', '510103001', '510301001')
     union all
     --3136
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1P-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3136;' || TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' ||
        TMP_M014_ITEM.m014_CSOSN_C5 || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_CRED_SN, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_CRED_ICMS_SN),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.m014_CSOSN_C5 = '101'
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   TMP_M001_EMITENTE.M001_DM_CRT IN (0, 3)
     union all
     --3140
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1Q-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3140;' || TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' || TMP_M014_ITEM.m014_CSOSN_C5,
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.m014_CSOSN_C5 in ('102', '103', '300', '400')
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   TMP_M001_EMITENTE.M001_DM_CRT IN (0, 3)
     union all
     --3143
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1R-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3143;' || TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' || TMP_M014_ITEM.m014_CSOSN_C5 || ';' ||
        M014_DM_MOD_BC_ST_ICMS || ';' ||
        case when TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS = 5 then
          null
        else
          fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_PERC_MARG_ICMS,0), 10, 4)
        end
        || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_REDUC_ICMS_ST, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ST_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ST_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS_ST) || ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' and
            nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0))) > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0), 13) || ';'
            else
              ';;;'
          end,
        null)||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_CRED_SN, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_CRED_ICMS_SN),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.m014_CSOSN_C5 = '201'
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   TMP_M001_EMITENTE.M001_DM_CRT IN (0, 3)
     union all
     --3146
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1S-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3146;' || TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' || TMP_M014_ITEM.m014_CSOSN_C5 || ';' ||
        M014_DM_MOD_BC_ST_ICMS || ';' ||
        case when TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS = 5 then
          null
        else
          fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_PERC_MARG_ICMS,0), 10, 4)
        end
        || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_REDUC_ICMS_ST, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ST_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ST_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS_ST)|| ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' and
            nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0))) > 0 then
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, 0), 13) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, 0), 3) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0), 13)
            else
              ';;'
          end,
        null),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.M000_ID_NF = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.m014_CSOSN_C5 IN ('202', '203')
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   TMP_M001_EMITENTE.M001_DM_CRT IN (0, 3)
     union all
     --3150
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1T-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3150;' || TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' || TMP_M014_ITEM.m014_CSOSN_C5 || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ST_RET) || ';' ||
        decode(vsPDVersaoXml, '4', decode(TMP_M014_ITEM.M014_VL_BC_ST_RET, null, ';',
        fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_ALIQ_ST_ICMS,0) + nvl(TMP_M014_ITEM.PERALIQUOTAFECP,0), 3)|| ';'),
        null) ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS_ST_RET)|| ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' then
            case when nvl(TMP_M014_ITEM.m014_vl_bc_fcp_ret, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_ret, nvl(TMP_M014_ITEM.m014_vl_fcp_ret, 0))) > 0 then
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_ret, 0), 13) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_ret, 0), 3) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_ret, 0), 13)
            else
              ';;'
            end
          else
            case when nvl(TMP_M014_ITEM.BASCALCFECP, nvl(TMP_M014_ITEM.PERALIQUOTAFECP, nvl(TMP_M014_ITEM.VLRFECP, 0)))  > 0 then
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.BASCALCFECP, 0), 13) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.PERALIQUOTAFECP, 0), 3) || ';' ||
              fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.VLRFECP, 0), 13)
            else
              ';;'
            end
          end                          || ';' ||
        trim(to_char(nvl(TMP_M014_ITEM.PERREDBCICMSEFET, 0),'990d00', 'nls_numeric_characters=''.,'''))            || ';' ||
        trim(to_char(nvl(TMP_M014_ITEM.VLRBASEICMSEFET, 0), '9999999999990d00', 'nls_numeric_characters=''.,'''))  || ';' ||
        trim(to_char(nvl(TMP_M014_ITEM.PERALIQICMSEFET, 0), '990d00', 'nls_numeric_characters=''.,'''))            || ';' ||
        trim(to_char(nvl(TMP_M014_ITEM.VLRICMSEFET, 0),     '9999999999990d00', 'nls_numeric_characters=''.,'''))  ||
        CASE WHEN vsIntegraNfeNT2018005 = 'S' THEN
           ';' || fc5ConverteNumberToChar(NVL(TMP_M014_ITEM.M014_VL_OP_PROP_DIST,0),13)
        ELSE
           null
        END,
        null),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.m014_CSOSN_C5  = '500'
     and   TMP_M014_ITEM.m000_id_nf = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   TMP_M001_EMITENTE.M001_DM_CRT IN (0, 3)
     union all
     --3153
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1UA', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3153;' || TMP_M014_ITEM.M014_DM_ORIG_ICMS || ';' || TMP_M014_ITEM.m014_CSOSN_C5,
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.m014_CSOSN_C5  = '900'
     and   TMP_M014_ITEM.m000_id_nf = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   TMP_M001_EMITENTE.M001_DM_CRT IN (0, 3)
     union all

     --3154
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1UB', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3154;' ||
        TMP_M014_ITEM.M014_DM_MOD_BC_ICMS || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ICMS) || ';' ||
        fc5ConverteNumberToChar(Decode(TMP_M014_ITEM.M014_VL_PERC_REDUC_ICMS,100,null,TMP_M014_ITEM.M014_VL_PERC_REDUC_ICMS), 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.m014_CSOSN_C5  = '900'
     and   TMP_M014_ITEM.m000_id_nf = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   TMP_M001_EMITENTE.M001_DM_CRT IN (0, 3)
     union all
     --3155
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1UC', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3155;' ||
        TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS || ';' ||
        case when TMP_M014_ITEM.M014_DM_MOD_BC_ST_ICMS = 5 then
          null
        else
          case when fBuscaPerRedICMS( pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'M') > 0 then
             fc5ConverteNumberToChar(fBuscaPerRedICMS(pnSeqNota, TMP_M014_ITEM.SEQPRODUTOC5, null, 'M'), 10, 4)
          else '0.0000'
          end
        end
        || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_REDUC_ICMS_ST, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ST_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ST_ICMS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ICMS_ST)|| ';' ||
        decode(vsPDVersaoXml, '4',
          case when vsIndUtilCalcFCP = 'S' and
            nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0))) > 0 then
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_bc_fcp_st, 0), 13) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_aliq_fcp_st, 0), 3) || ';' ||
               fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.m014_vl_fcp_st, 0), 13)
            else
              ';;'
          end,
        null),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.m014_CSOSN_C5  = '900'
     and   TMP_M014_ITEM.m000_id_nf = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   TMP_M001_EMITENTE.M001_DM_CRT IN (0, 3)
     union all
     --3156
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1UD', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3156;' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_CRED_SN, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_CRED_ICMS_SN),
        pnSeqNota
     from  TMP_M014_ITEM, TMP_M001_EMITENTE
     where TMP_M014_ITEM.m014_CSOSN_C5  = '900'
     and   TMP_M014_ITEM.m000_id_nf = TMP_M001_EMITENTE.M000_ID_NF
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   TMP_M001_EMITENTE.M001_DM_CRT IN (0, 3)
     and   TMP_M014_ITEM.M014_VL_PERC_CRED_SN > 0
     union all
     --registro O - Imposto Sobre Produtos Industrializados
     --3180
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1V-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3180;' ||
        TMP_M014_ITEM.M014_NR_CLASSE_IPI || ';' ||
        TMP_M014_ITEM.M014_NR_CNPJ_IPI || ';' ||
        TMP_M014_ITEM.M014_CD_SELO_IPI || ';' ||
        TMP_M014_ITEM.M014_NR_SELO_IPI || ';' ||
        TMP_M014_ITEM.M014_CD_ENQ_IPI,
        pnSeqNota
     from  TMP_M000_NF, TMP_M014_ITEM
     where TMP_M000_NF.M000_ID_NF = TMP_M014_ITEM.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_ST_TRIB_IPI in (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   ((TMP_M014_ITEM.M014_VL_IPI > 0 OR SUBSTR(TMP_M014_ITEM.M014_CD_CFOP,1,1) = '3') OR
           (TMP_M014_ITEM.M014_VL_IPI = 0 AND TMP_M014_ITEM.M014_DM_ST_TRIB_IPI in (1, 2, 3, 4, 5, 8, 9, 10, 11, 12)))
     and   (TMP_M000_NF.M000_DM_FIN_EM != 4 OR (TMP_M000_NF.M000_DM_FIN_EM = 4 AND vsEmiteApuracaoIPI = 'S' AND FC5_IndCalcIPISaida(TMP_M014_ITEM.SEQPRODUTOC5, pnNroEmpresa) = 'S'))
     union all

     --3181
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1W-', to_char(TMP_M014_ITEM.m014_id_item),TMP_M014_ITEM.m014_nr_item,
        '3181;' ||
        decode(TMP_M014_ITEM.M014_DM_ST_TRIB_IPI, 6, '49', 7, '50', 13, '99', '00') || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_IPI) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_IPI, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_IPI),
        pnSeqNota
     from  TMP_M000_NF, TMP_M014_ITEM
     where TMP_M000_NF.M000_ID_NF = TMP_M014_ITEM.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_ST_TRIB_IPI in (6, 7, 13, 0 )
     and   M014_VL_UNID_TRIB_IPI is null
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   (TMP_M014_ITEM.M014_VL_IPI > 0 OR SUBSTR(TMP_M014_ITEM.M014_CD_CFOP,1,1) = '3')
     and   (TMP_M000_NF.M000_DM_FIN_EM != 4 OR (TMP_M000_NF.M000_DM_FIN_EM = 4 AND vsEmiteApuracaoIPI = 'S' AND FC5_IndCalcIPISaida(TMP_M014_ITEM.SEQPRODUTOC5, pnNroEmpresa) = 'S'))

     union all

     --3182
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1X-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3182;' ||
        decode(TMP_M014_ITEM.M014_DM_ST_TRIB_IPI, 6, '49', 7, '50', 13, '99', '00') || ';' ||
        fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_NR_UND_PRD_IPI,0), 10, 4) || ';' ||
        fc5ConverteNumberToChar(nvl(TMP_M014_ITEM.M014_VL_UNID_TRIB_IPI,0), 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_IPI),
        pnSeqNota
     from  TMP_M000_NF, TMP_M014_ITEM
     where TMP_M000_NF.M000_ID_NF = TMP_M014_ITEM.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_ST_TRIB_IPI in (6, 7, 13, 0)
     and   M014_VL_UNID_TRIB_IPI is not null
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   (TMP_M014_ITEM.M014_VL_IPI > 0 OR SUBSTR(TMP_M014_ITEM.M014_CD_CFOP,1,1) = '3')
     and   (TMP_M000_NF.M000_DM_FIN_EM != 4 OR (TMP_M000_NF.M000_DM_FIN_EM = 4 AND vsEmiteApuracaoIPI = 'S' AND FC5_IndCalcIPISaida(TMP_M014_ITEM.SEQPRODUTOC5, pnNroEmpresa) = 'S'))

     union all

     --3190
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1Y-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3190;' ||
        decode(TMP_M014_ITEM.M014_DM_ST_TRIB_IPI, 1, '01', 2, '02', 3, '03', 4, '04', 5, '05', 8, '51', 9, '52', 10, '53', 11, '54', 12, '55' ),
        pnSeqNota
     from  TMP_M000_NF, TMP_M014_ITEM
     where TMP_M000_NF.M000_ID_NF = TMP_M014_ITEM.M000_ID_NF
     and   TMP_M014_ITEM.M014_DM_ST_TRIB_IPI in (1, 2, 3, 4, 5, 8, 9, 10, 11, 12)
     and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and   NVL(TMP_M014_ITEM.M014_VL_IPI, 0) >= 0
     and   (TMP_M000_NF.M000_DM_FIN_EM != 4 OR (TMP_M000_NF.M000_DM_FIN_EM = 4 AND vsEmiteApuracaoIPI = 'S' AND FC5_IndCalcIPISaida(TMP_M014_ITEM.SEQPRODUTOC5, pnNroEmpresa) = 'S'));

     -- registro P-Imposto de Importação
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha, ordem, auxiliar1, auxiliar2,
        linha, seqnotafiscal)
     --3195
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '1Z-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3195;' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_IMPOSTO_IMPORT) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_DESP_ADUANEIRAS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_IMPOSTO_IMPORT) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_IOF),
        pnSeqNota
       from   TMP_M000_NF, TMP_M014_ITEM
      where   TMP_M000_NF.M000_ID_NF = TMP_M014_ITEM.M000_ID_NF
        and   TMP_M014_ITEM.m000_id_nf = pnSeqNota
        and   TMP_M000_NF.NRODECLARAIMPORTC5 IS NOT NULL
     union all
     --U -ISSQN
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2A-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3197;' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_ISSQN) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ISSQN, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ISSQN) || ';' ||
        TMP_M014_ITEM.M014_NR_IBGE_MUN_ISSQN || ';' ||
        fCodServicoFamilia(TMP_M014_ITEM.M014_CD_LISTA_SERVICOS) || ';;;;;;3;;;;;1',
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_CD_LISTA_SERVICOS is not null
     union all
     --Q-PIS
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2B-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3200;' ||
        TMP_M014_ITEM.M014_DM_ST_TRIB_PIS || ';' ||
        case when nvl(TMP_M014_ITEM.M014_VL_BC_PIS, 0) > 0 then
             fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_PIS)
             else
             '0'
             end || ';' ||
        case when nvl(TMP_M014_ITEM.M014_VL_PERC_ALIQ_PIS,0) > 0 then
             fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_ALIQ_PIS, 10, 4)
             else
             '0'
             end || ';' ||
        case when nvl(TMP_M014_ITEM.M014_VL_PIS, 0) > 0 then
             fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PIS)
             else
             '0'
             end ,
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_DM_ST_TRIB_PIS in ('01', '02')

     union all
     --3210
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2C-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3210;' ||
        TMP_M014_ITEM.M014_DM_ST_TRIB_PIS || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_QTDE_VEND_PIS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_PIS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PIS),
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_DM_ST_TRIB_PIS = '03'

     union all
     --3220
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2D-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3220;' ||
        TMP_M014_ITEM.M014_DM_ST_TRIB_PIS,
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_DM_ST_TRIB_PIS in ('04','06','07','08','09','05')
     union all
     --3230
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2E-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3230;' ||
        TMP_M014_ITEM.M014_DM_ST_TRIB_PIS || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_PIS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_ALIQ_PIS, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PIS),
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_DM_ST_TRIB_PIS IN ('49','50','51','52','53','54','55','56','60','61','62','63','64','65','66','67','70','71','72','73','74','75','98','99')

     union all

     --R-PIS ST
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2F-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3240;' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_PIS_ST) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PALIQ_PIS_ST, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PIS_ST) ||
        CASE
          WHEN vsPDVersaoXml = '4' THEN
            fc5_BuscaCampoNotaTecnica(TMP_M014_ITEM.M014_DM_SOMA_PISST, 2020005, pnNroEmpresa, 4, 1, 515, vdDtaHorEmissao)
          ELSE
            ''
        END,
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    nvl(TMP_M014_ITEM.M014_VL_BC_PIS_ST, 0) > 0
     union all

     --S-COFINS
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2G-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3300;' ||
        TMP_M014_ITEM.M014_DM_ST_TRIB_CF|| ';' ||
        case when nvl(TMP_M014_ITEM.M014_VL_BC_CF, 0) > 0 then
             fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_CF)
             else
             '0'
             end || ';' ||
        case when nvl(TMP_M014_ITEM.M014_VL_PERC_ALIQ_CF, 0) > 0 then
             fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_ALIQ_CF, 10, 4)
             else
             '0'
             end || ';' ||
        case when nvl(TMP_M014_ITEM.M014_VL_CF, 0) > 0 then
             fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_CF)
             else
             '0'
             end ,
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_DM_ST_TRIB_CF in ('01', '02')

     union all
     --COFINSQtde - grupo de COFINS tributado por Qtde
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2H-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3310;' ||
        TMP_M014_ITEM.M014_DM_ST_TRIB_CF || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_QTDE_VEND_CF, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_CF, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_CF),
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_DM_ST_TRIB_CF = '03'

     union all
     --COFINSNT - grupo de COFINS não tributado
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2I-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3320;' ||
        TMP_M014_ITEM.M014_DM_ST_TRIB_CF,
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_DM_ST_TRIB_CF in ('04','06','07','08','09','05')
     union all
     --COFINSOutr ¿
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2J-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3330;' ||
        TMP_M014_ITEM.M014_DM_ST_TRIB_CF || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_CF) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PERC_ALIQ_CF, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_CF),
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_DM_ST_TRIB_CF IN ('49','50','51','52','53','54','55','56','60','61','62','63','64','65','66','67','70','71','72','73','74','75','98','99')

     union all

     --T- CONFINS ST
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2L-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3400;' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_BC_CF_ST) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_PALIQ_CF_ST, 10, 4) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_CF_ST) ||
        CASE
          WHEN vsPDVersaoXml = '4' THEN
            fc5_BuscaCampoNotaTecnica(TMP_M014_ITEM.M014_DM_SOMA_COFINSST, 2020005, pnNroEmpresa, 4, 1, 543, vdDtaHorEmissao)
          ELSE
            ''
        END,
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    nvl(TMP_M014_ITEM.M014_VL_BC_CF_ST, 0) > 0
     union all
     -- 3450 -  ICMSUFDest - Informação do ICMS Interestadual
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2L-0', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3450;' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VBCUFDESTPART) || ';' ||
        decode(vsPDVersaoXml, '4', fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VBCFCPUFDESTPART) || ';', null)||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_PFCPUFDEST) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_PICMSINTER) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VL_ALIQ_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_PICMSINTERPART) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VFCPUFDEST) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VICMSUFDEST) || ';' ||
        fc5ConverteNumberToChar(TMP_M014_ITEM.M014_VICMSUFREMET),
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    nvl(TMP_M014_ITEM.M014_VBCUFDESTPART, 0) > 0
     and    nvl(TMP_M014_ITEM.M014_PICMSINTER, 0) > 0
     union all
     -- Grupo IS ¿ Informações do Imposto Seletivo
     --3460
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2M-', to_char(a.m014_id_item), a.m014_nr_item,
        '3460' ||
        fc5_BuscaCampoNotaTecnica(LPAD(a.M014_CD_CSTIS,3,'0'), 2025002, pnNroEmpresa, 4, 1.30, 9, vdDtaHorEmissao) || -- CSTIS
        fc5_BuscaCampoNotaTecnica(a.M014_DS_CCLASSTRIBIS, 2025002, pnNroEmpresa, 4, 1.30, 10, vdDtaHorEmissao),   -- cClassTribIS
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIS is not null
     and   a.M014_DS_CCLASSTRIBIS is not null
     union all
     --3461
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2M-0', to_char(a.m014_id_item), a.m014_nr_item,
        '3461' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRBASEIS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 12, vdDtaHorEmissao, 'S', 13, 2) || -- vBCIS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQIS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 13, vdDtaHorEmissao, 'S', 3, 4) || -- pIS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQEUNIS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 14, vdDtaHorEmissao, 'S', 3, 4) || -- pISEspec
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOIS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 15, vdDtaHorEmissao, 'S', 13, 2), -- vIS
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIS is not null
     and   a.M014_DS_CCLASSTRIBIS is not null
     and   a.M014_VL_VLRIMPOSTOIS >= 0
     AND   CASE WHEN LPAD(a.M014_CD_CSTIS,3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     --3462
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2M-1', to_char(a.m014_id_item), a.m014_nr_item,
        '3462' ||
        fc5_BuscaCampoNotaTecnica(a.M014_DS_UNTRIBIS, 2025002, pnNroEmpresa, 4, 1.30, 15, vdDtaHorEmissao) || -- uTrib
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_QTDTRIBIS, csFormatoNumber11_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 16, vdDtaHorEmissao, 'S', 11, 4), -- qTrib
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIS is not null
     and   a.M014_DS_CCLASSTRIBIS is not null
     AND   CASE WHEN LPAD(a.M014_CD_CSTIS,3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- IBSCBS ¿ Informações do Imposto de Bens e Serviços - IBS e da Contribuição de Bens e Serviços - CBS
     --3466
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2N-', to_char(a.m014_id_item), a.m014_nr_item,
        '3466' ||
        fc5_BuscaCampoNotaTecnica(LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0'), 2025002, pnNroEmpresa, 4, 1.30, 17, vdDtaHorEmissao) || -- CST
        fc5_BuscaCampoNotaTecnica(NVL(a.M014_DS_CCLASSTRIBIBSUF,a.M014_DS_CCLASSTRIBCBS), 2025002, pnNroEmpresa, 4, 1.30, 18, vdDtaHorEmissao) || -- cClassTrib
        fc5_BuscaCampoNotaTecnica(A.M014_DM_INDDOACAO, 2025002, pnNroEmpresa, 4, 1.30, 118, vdDtaHorEmissao), -- indDoacao
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M014_CD_CSTCBS is not null or a.M014_CD_CSTIBSUF is not null)
     and   (a.M014_DS_CCLASSTRIBCBS is not null or a.M014_DS_CCLASSTRIBIBSUF is not null)
     union all
     -- gIBSCBS ¿ Grupo de Informações do IBS, CBS e Imposto Seletivo
     --3467
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2O-', to_char(a.m014_id_item), a.m014_nr_item,
        '3467' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(NVL(a.M014_VL_VLRBASEIBSUF,a.M014_VL_VLRBASECBS), csFormatoNumber13_2),','), 2025002, pnNroEmpresa, 4, 1.30, 19, vdDtaHorEmissao, 'S', 13, 2), -- vBC
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M014_CD_CSTCBS is not null or a.M014_CD_CSTIBSUF is not null)
     and   (a.M014_DS_CCLASSTRIBCBS is not null or a.M014_DS_CCLASSTRIBIBSUF is not null)
     and   (a.M014_VL_VLRBASECBS >= 0 or a.M014_VL_VLRBASEIBSUF >= 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gIBSUF ¿ Grupo de Informações do IBS para a UF
     --3468
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2O-0', to_char(a.m014_id_item), a.m014_nr_item,
        '3468' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQIBSUF, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 20, vdDtaHorEmissao, 'S', 3, 4) || -- pIBSUF
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 21, vdDtaHorEmissao, 'S', 13, 2), -- vIBSUF
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIBSUF is not null
     and   a.M014_DS_CCLASSTRIBIBSUF is not null
     and   a.M014_VL_VLRIMPOSTOIBSUF >= 0
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gDif ¿ Grupo de Informações do Diferimento IBS para a UF
     --3469
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2O-1', to_char(a.m014_id_item), a.m014_nr_item,
        '3469' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERDIFERIDOIBSUF, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 22, vdDtaHorEmissao, 'S', 3, 4) || -- pDif
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRDIFERIDOIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 23, vdDtaHorEmissao, 'S', 13, 2), -- vDif
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIBSUF is not null
     and   a.M014_DS_CCLASSTRIBIBSUF is not null
     and   (a.M014_VL_VLRDIFERIDOIBSUF > 0 or M014_VL_PERDIFERIDOIBSUF > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gDevTrib ¿ Grupo de Informações da devolução de tributos IBS para a UF
     --3470
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2O-2', to_char(a.m014_id_item), a.m014_nr_item,
        '3470' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRDEVTRIBIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 24, vdDtaHorEmissao, 'S', 13, 2), -- vDevTrib
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIBSUF is not null
     and   a.M014_DS_CCLASSTRIBIBSUF is not null
     and   a.M014_VL_VLRDEVTRIBIBSUF > 0
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gRed ¿ Grupo de informações da redução da alíquota IBS para a UF
     --3471
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2O-3', to_char(a.m014_id_item), a.m014_nr_item,
        '3471' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQREDIBSUF, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 25, vdDtaHorEmissao, 'S', 3, 4) || -- pRedAliq
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQEFETIVAIBSUF, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 26, vdDtaHorEmissao, 'S', 3, 2), -- pAliqEfet
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIBSUF is not null
     and   a.M014_DS_CCLASSTRIBIBSUF is not null
     and   (a.M014_VL_PERALIQREDIBSUF > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gIBSMun ¿ Grupo de Informações do IBS para o município
     --3474
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2P-', to_char(a.m014_id_item), a.m014_nr_item,
        '3474' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQIBSMUN, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 27, vdDtaHorEmissao, 'S', 3, 4) || -- pIBSMun
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOIBSMUN, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 28, vdDtaHorEmissao, 'S', 13, 2), -- vIBSMun
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIBSMUN is not null
     and   a.M014_DS_CCLASSTRIBIBSMUN is not null
     and   a.M014_VL_VLRIMPOSTOIBSMUN >= 0
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gDif ¿ Grupo de Informações do Diferimento IBS para o município
     --3475
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2P-0', to_char(a.m014_id_item), a.m014_nr_item,
        '3475' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERDIFERIDOIBSMUN, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 29, vdDtaHorEmissao, 'S', 3, 4) || -- pDif
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRDIFERIDOIBSMUN, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 30, vdDtaHorEmissao, 'S', 13, 2), -- vDif
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIBSMUN is not null
     and   a.M014_DS_CCLASSTRIBIBSMUN is not null
     and   (a.M014_VL_VLRDIFERIDOIBSMUN > 0 or M014_VL_PERDIFERIDOIBSMUN > 0)
   AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gDevTrib ¿ Grupo de Informações da devolução de tributos IBS para o município
     --3476
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2P-1', to_char(a.m014_id_item), a.m014_nr_item,
        '3476' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRDEVTRIBIBSMUN, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 31, vdDtaHorEmissao, 'S', 13, 2), -- vDevTrib
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIBSMUN is not null
     and   a.M014_DS_CCLASSTRIBIBSMUN is not null
     and   a.M014_VL_VLRDEVTRIBIBSMUN > 0
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gRed ¿ Grupo de informações da redução da alíquota IBS para o município
     --3477
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2P-2', to_char(a.m014_id_item), a.m014_nr_item,
        '3477' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQREDIBSMUN, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 32, vdDtaHorEmissao, 'S', 3, 4) || -- pRedAliq
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQEFETIVAIBSMUN, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 33, vdDtaHorEmissao, 'S', 3, 2), -- pAliqEfet
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTIBSMUN is not null
     and   a.M014_DS_CCLASSTRIBIBSMUN is not null
     and   (a.M014_VL_PERALIQREDIBSMUN > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- vIBS ¿ Valor do IBS
     --3478
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2Q-1', to_char(a.m014_id_item), a.m014_nr_item,
        '3478' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOIBS, csFormatoNumber13_2),','), 2025002, pnNroEmpresa, 4, 1.30, 115, vdDtaHorEmissao, 'S', 13, 2), -- vIBS
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gCBS ¿ Grupo de Informações da CBS
     --3480
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2Q-2', to_char(a.m014_id_item), a.m014_nr_item,
        '3480' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 34, vdDtaHorEmissao, 'S', 3, 4) || -- pCBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 35, vdDtaHorEmissao, 'S', 13, 2), -- vCBS
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTCBS is not null
     and   a.M014_DS_CCLASSTRIBCBS is not null
     and   a.M014_VL_VLRIMPOSTOCBS >= 0
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gDif ¿ Grupo de Informações do Diferimento CBS
     --3481
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2Q-3', to_char(a.m014_id_item), a.m014_nr_item,
        '3481' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERDIFERIMENTOCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 36, vdDtaHorEmissao, 'S', 3, 4) || -- pDif
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRDIFERIDOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 38, vdDtaHorEmissao, 'S', 13, 2), -- vDif
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTCBS is not null
     and   a.M014_DS_CCLASSTRIBCBS is not null
     and   (a.M014_VL_VLRDIFERIDOCBS > 0 or a.M014_VL_PERDIFERIMENTOCBS > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gDevTrib ¿ Grupo de Informações da devolução de tributos CBS
     --3482
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2Q-4', to_char(a.m014_id_item), a.m014_nr_item,
        '3482' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRDEVTRIBCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 39, vdDtaHorEmissao, 'S', 13, 2), -- vDevTrib
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTCBS is not null
     and   a.M014_DS_CCLASSTRIBCBS is not null
     and   a.M014_VL_VLRDEVTRIBCBS > 0
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gRed ¿ Grupo de informações da redução da alíquota CBS
     --3483
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2Q-5', to_char(a.m014_id_item), a.m014_nr_item,
        '3483' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQREDCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 40, vdDtaHorEmissao, 'S', 3, 4) || -- pRedAliq
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQEFETIVACBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 41, vdDtaHorEmissao, 'S', 3, 2), -- pAliqEfet
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CSTCBS is not null
     and   a.M014_DS_CCLASSTRIBCBS is not null
     and   (a.M014_VL_PERALIQREDCBS > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('000','200','220','222','510','515','550','830') THEN 1 ELSE 0 END = 1
     union all
     -- gTribRegular ¿ Grupo de informações da Tributação Regular
     --3486
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2R-', to_char(a.m014_id_item), a.m014_nr_item,
        '3486' ||
        fc5_BuscaCampoNotaTecnica(LPAD(NVL(a.M014_CD_CSTREGULARIBSUF,a.M014_CD_CSTREGULARCBS),3,'0'), 2025002, pnNroEmpresa, 4, 1.30, 42, vdDtaHorEmissao) || -- CSTReg
        fc5_BuscaCampoNotaTecnica(NVL(a.M014_DS_CCLASSTRIBREGULARIBSUF,a.M014_DS_CCLASSTRIBREGULARCBS), 2025002, pnNroEmpresa, 4, 1.30, 43, vdDtaHorEmissao) || -- cClassTribReg
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQREGULARIBSUF, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 44, vdDtaHorEmissao, 'S', 3, 4) || -- pAliqEfetRegIBSUF
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOREGULARIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 45, vdDtaHorEmissao, 'S', 13, 2) || -- vTribRegIBSUF
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQREGULARIBSMUN, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 46, vdDtaHorEmissao, 'S', 3, 4) || -- pAliqEfetRegIBSMun
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOREGULARIBSMUN, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 47, vdDtaHorEmissao, 'S', 13, 2) || -- vTribRegIBSMun
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQREGULARCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 48, vdDtaHorEmissao, 'S', 3, 4) || -- pAliqEfetRegCBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOREGULARCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 49, vdDtaHorEmissao, 'S', 13, 2), -- vTribRegCBS
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M014_CD_CSTREGULARCBS is not null or a.M014_CD_CSTREGULARIBSUF is not null)
     and   (a.M014_DS_CCLASSTRIBREGULARCBS is not null or a.M014_DS_CCLASSTRIBREGULARIBSUF is not null)
     and   (a.M014_VL_VLRIMPOSTOREGULARIBSUF > 0 or a.M014_VL_VLRIMPOSTOREGULARIBSMUN > 0 or a.M014_VL_VLRIMPOSTOREGULARCBS > 0)
     union all
     -- gTribCompraGov - Grupo de informações da composição do valor do IBS e da CBS em compras governamentais
     --3487
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2S-', to_char(a.m014_id_item), a.m014_nr_item,
        '3487' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQCOMPRAGOVIBSUF, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 58, vdDtaHorEmissao) || -- pAliqIBSUF
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOCOMPRAGOVIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 59, vdDtaHorEmissao, 'S', 3, 4) || -- vTribIBSUF
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQCOMPRAGOVIBSMUN, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 60, vdDtaHorEmissao, 'S', 13, 2) || -- pAliqIBSMun
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOCOMPRAGOVIBSMUN, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 61, vdDtaHorEmissao) || -- vTribIBSMun
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQCOMPRAGOVCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 62, vdDtaHorEmissao, 'S', 3, 4) || -- pAliqCBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOCOMPRAGOVCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 63, vdDtaHorEmissao, 'S', 13, 2), -- vTribCBS
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M014_VL_VLRIMPOSTOCOMPRAGOVIBSUF > 0 or a.M014_VL_VLRIMPOSTOCOMPRAGOVIBSMUN > 0 or a.M014_VL_VLRIMPOSTOCOMPRAGOVCBS > 0)
     union all
     -- gIBSCBSMono ¿ Grupo de Informações do IBS e CBS em operações com imposto monofásico
     --3488
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2T-', to_char(a.m014_id_item), a.m014_nr_item,
        '3488' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOMONOIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 69, vdDtaHorEmissao, 'S', 13, 2) || -- vIBSMono
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOMONOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 70, vdDtaHorEmissao, 'S', 13, 2), -- vCBSMono
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_VL_QTDE_TRIB_MONO > 0
     and   (a.M014_VL_VLRIMPOSTOMONOIBS > 0 or a.M014_VL_VLRIMPOSTOMONOCBS > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('620') THEN 1 ELSE 0 END = 1
     union all
     -- gIBSCBSMono ¿ Grupo de Informações do IBS e CBS em operações com imposto monofásico
     --3489
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2T-1', to_char(a.m014_id_item), a.m014_nr_item,
        '3489' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_QTDE_TRIB_MONO, csFormatoNumber11_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 64, vdDtaHorEmissao, 'S', 11, 4) || -- qBCMono
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQADREMIBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 65, vdDtaHorEmissao, 'S', 3, 4) || -- adRemIBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQADREMCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 66, vdDtaHorEmissao, 'S', 3, 4) || -- adRemCBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOMONOIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 67, vdDtaHorEmissao, 'S', 13, 2) || -- vIBSMono
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOMONOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 68, vdDtaHorEmissao, 'S', 13, 2), -- vCBSMono
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_VL_QTDE_TRIB_MONO > 0
     and   (a.M014_VL_VLRIMPOSTOMONOIBS > 0 or a.M014_VL_VLRIMPOSTOMONOCBS > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('620') THEN 1 ELSE 0 END = 1
     union all
     -- gIBSCBSMono ¿ Grupo de sequência das informações do IBS e CBS em operações com imposto monofásico
     --3490
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2U-', to_char(a.m014_id_item), a.m014_nr_item,
        '3490' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_QTDE_TRIB_MONORETENIBS, csFormatoNumber11_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 71, vdDtaHorEmissao, 'S', 11, 4) || -- qBCMonoReten
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQMONORETENIBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 72, vdDtaHorEmissao, 'S', 3, 4) || -- adRemIBSREten
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOMONORETENIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 73, vdDtaHorEmissao, 'S', 13, 2) || -- vIBSMonoReten
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQMONORETENCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 74, vdDtaHorEmissao, 'S', 3, 4) || -- adRemCBSReten
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOMONORETENCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 75, vdDtaHorEmissao, 'S', 13, 2), -- vCBSMonoReten
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_VL_QTDE_TRIB_MONORETENIBS > 0
     and   (a.M014_VL_VLRIMPOSTOMONORETENIBS > 0 or a.M014_VL_VLRIMPOSTOMONORETENCBS > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('620') THEN 1 ELSE 0 END = 1
     union all
     -- gIBSCBSMono ¿ Grupo de sequência das informações do IBS e CBS em operações com imposto monofásico
     --3491
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2V-', to_char(a.m014_id_item), a.m014_nr_item,
        '3491' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_QTDE_TRIB_MONORETIBS, csFormatoNumber11_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 76, vdDtaHorEmissao, 'S', 11, 4) || -- qBCMonoRet
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQMONORETIBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 77, vdDtaHorEmissao, 'S', 3, 4) || -- adRemIBSRet
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOMONORETIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 78, vdDtaHorEmissao, 'S', 13, 2) || -- vIBSMonoRet
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQMONORETCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 79, vdDtaHorEmissao, 'S', 3, 4) || -- adRemCBSRet
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOMONORETCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 80, vdDtaHorEmissao, 'S', 13, 2), -- vCBSMonoRet
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_VL_QTDE_TRIB_MONORETIBS > 0
     and   (a.M014_VL_VLRIMPOSTOMONORETIBS > 0 or a.M014_VL_VLRIMPOSTOMONORETCBS > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('620') THEN 1 ELSE 0 END = 1
     union all
     -- gIBSCBSMono ¿ Grupo de sequência das informações do IBS e CBS em operações com imposto monofásico
     --3492
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2W-', to_char(a.m014_id_item), a.m014_nr_item,
        '3492' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERDIFERIMENTOMONOIBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 81, vdDtaHorEmissao, 'S', 3, 4) || -- pDifIBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRDIFERIDOMONOIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 82, vdDtaHorEmissao, 'S', 13, 2) || -- vIBSMonoDif
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERDIFERIMENTOMONOCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 83, vdDtaHorEmissao, 'S', 3, 4) || -- pDifCBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRDIFERIDOMONOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 84, vdDtaHorEmissao, 'S', 13, 2), -- vCBSMonoDif
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M014_VL_VLRDIFERIDOMONOIBS >= 0 or a.M014_VL_VLRDIFERIDOMONOCBS >= 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('620') THEN 1 ELSE 0 END = 1
     union all
     -- gTransfCred ¿ Transferências de Crédito.
     --3493
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2X-', to_char(a.m014_id_item), a.m014_nr_item,
        '3493' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOTRANSFERIDOIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 85, vdDtaHorEmissao, 'S', 3, 4) || -- vIBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOTRANSFERIDOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 86, vdDtaHorEmissao, 'S', 13, 2), -- vCBS
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M014_VL_VLRIMPOSTOTRANSFERIDOIBS >= 0 or a.M014_VL_VLRIMPOSTOTRANSFERIDOCBS >= 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('800') THEN 1 ELSE 0 END = 1
     union all
     -- gAjusteCompet ¿ Ajuste de Competência.
     --3494
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2X-1', to_char(a.m014_id_item), a.m014_nr_item,
        '3494' ||
        fc5_BuscaCampoNotaTecnica(TO_CHAR(M014_DT_DTAJUSTECOMPETENCIAPUR,'YYYY-MM'), 2025002, pnNroEmpresa, 4, 1.30, 119, vdDtaHorEmissao, 'S', 3, 4) || -- competApur
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOAJUSCOMPETIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 120, vdDtaHorEmissao, 'S', 13, 2) || -- vIBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOAJUSCOMPETCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 121, vdDtaHorEmissao, 'S', 13, 2), -- vCBS
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     AND   A.M014_DT_DTAJUSTECOMPETENCIAPUR IS NOT NULL
     and   (a.M014_VL_VLRIMPOSTOAJUSCOMPETIBS > 0 or a.M014_VL_VLRIMPOSTOAJUSCOMPETCBS > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('811') THEN 1 ELSE 0 END = 1
     union all
     -- gEstornoCred ¿ Estorno de Crédito
     --3495
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2X-2', to_char(a.m014_id_item), a.m014_nr_item,
        '3495' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOESTORNOIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 122, vdDtaHorEmissao, 'S', 3, 4) || -- vIBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRIMPOSTOESTORNOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 123, vdDtaHorEmissao, 'S', 13, 2), -- vCBS
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M014_VL_VLRIMPOSTOESTORNOIBS > 0 or a.M014_VL_VLRIMPOSTOESTORNOCBS > 0)
     AND   CASE WHEN LPAD(NVL(a.M014_CD_CSTIBSUF,a.M014_CD_CSTCBS),3,'0') IN ('410') THEN 1 ELSE 0 END = 1
     AND   CASE WHEN LPAD(NVL(A.M014_DS_CCLASSTRIBIBSUF,A.M014_DS_CCLASSTRIBCBS),3,'0') IN ('410026') THEN 1 ELSE 0 END = 1
     union all
     -- gIBSCredPres¿ Grupo de Informações do Crédito Presumido referente ao IBS/CBS
     --3496
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2Y-', to_char(a.m014_id_item), a.m014_nr_item,
        '3496' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(NVL(a.M014_VL_VLRBASECCREDPRESIBSUF,a.M014_VL_VLRBASECCREDPRESCBS), csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 125, vdDtaHorEmissao) || -- vBCCredPres
        fc5_BuscaCampoNotaTecnica(LPAD(NVL(a.M014_CD_CCREDPRESIBSUF,a.M014_CD_CCREDPRESCBS),2,'0'), 2025002, pnNroEmpresa, 4, 1.30, 50, vdDtaHorEmissao), -- cCredPres
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M014_CD_CCREDPRESIBSUF is not null OR a.M014_CD_CCREDPRESCBS is not null)
     and   (a.M014_VL_VLRBASEIBSUF > 0 or a.M014_VL_VLRBASECBS > 0)
     union all
     -- gCBSCredPres¿ Grupo de Informações do Crédito Presumido referente a IBSS.
     --3497
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '2Z-', to_char(a.m014_id_item), a.m014_nr_item,
        '3497' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQCCREDPRESIBSUF, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 51, vdDtaHorEmissao, 'S', 3, 4) || -- pCredPres
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(NVL(a.M014_VL_VLRCCREDPRESIBSUF,a.M014_VL_VLRCCREDPRESCONDSUSIBSUF), csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 52, vdDtaHorEmissao, 'S', 13, 2), -- vCredPres || vCredPresCondSus
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CCREDPRESIBSUF is not null
     and   (a.M014_VL_VLRCCREDPRESIBSUF > 0 or a.M014_VL_VLRCCREDPRESCONDSUSIBSUF > 0)
     union all
     -- gCBSCredPres¿ Grupo de Informações do Crédito Presumido referente a CBS.
     --3498
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '3A-', to_char(a.m014_id_item), a.m014_nr_item,
        '3498' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_PERALIQCCREDPRESCBS, csFormatoNumber3_4), ','), 2025002, pnNroEmpresa, 4, 1.30, 55, vdDtaHorEmissao, 'S', 3, 4) || -- pCredPres
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(NVL(a.M014_VL_VLRCCREDPRESCBS,a.M014_VL_VLRCCREDPRESCONDSUSCBS), csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 56, vdDtaHorEmissao, 'S', 13, 2), -- vCredPres || vCredPresCondSus
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_CD_CCREDPRESCBS is not null
     and   (a.M014_VL_VLRCCREDPRESCBS > 0 or a.M014_VL_VLRCCREDPRESCONDSUSCBS > 0)
     union all
     -- gCredPresIBSZFM ¿ Informações do crédito presumido de IBS para fornecimentos a partir da ZFM
     --3499
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '3B-', to_char(a.m014_id_item), a.m014_nr_item,
        '3499' ||
        fc5_BuscaCampoNotaTecnica(to_char(a.M014_DT_DTACREDZFMCOMPETENCIAPUR,'YYYY-MM'), 2025002, pnNroEmpresa, 4, 1.30, 124, vdDtaHorEmissao) || -- competApur
        fc5_BuscaCampoNotaTecnica(a.M000_TP_INDCREDPRESZFMIBS, 2025002, pnNroEmpresa, 4, 1.30, 87, vdDtaHorEmissao) || -- tpCredPresIBSZFM
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRCCREDPRESZFMIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 88, vdDtaHorEmissao, 'S', 13, 2), -- vCredPresIBSZFM
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M000_TP_INDCREDPRESZFMIBS IS NOT NULL or a.M014_VL_VLRCCREDPRESZFMIBS >= 0)
     union all
     -- V - Tributos Devolvidos
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '3C-1', to_char(b.m014_id_item), b.m014_nr_item,
        '3500;'  ||
        fc5ConverteNumberToChar(b.M014_VL_PERC_DEVOLC5),
        pnSeqNota
     from  TMP_M000_NF a, TMP_M014_ITEM b
     where a.M000_ID_NF = b.M000_ID_NF
     and   a.M000_DM_FIN_EM = 4
     and   (vsEmiteApuracaoIPI != 'S' or FC5_IndCalcIPISaida(B.SEQPRODUTOC5, pnNroEmpresa) != 'S')
     And   a.M000_ID_NF = pnSeqNota
     And   (b.M014_VL_IPI > 0  OR ( nvl(b.M014_VL_IPI_DADOSADIC_C5,0) > 0 and vsPDVersaoXml  = '4'))
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '3C-2', to_char(b.m014_id_item), b.m014_nr_item,
        '3501;' ||
        fc5ConverteNumberToChar(decode(nvl(b.M014_VL_IPI, 0), 0, nvl(b.M014_VL_IPI_DADOSADIC_C5,0), nvl(b.M014_VL_IPI,0))),
        pnSeqNota
     from  TMP_M000_NF a, TMP_M014_ITEM b
     where a.M000_ID_NF = b.M000_ID_NF
     and   a.M000_DM_FIN_EM = 4
     and   (vsEmiteApuracaoIPI != 'S' or FC5_IndCalcIPISaida(B.SEQPRODUTOC5, pnNroEmpresa) != 'S')
     And   a.M000_ID_NF = pnSeqNota
     And   (b.M014_VL_IPI > 0  OR ( nvl(b.M014_VL_IPI_DADOSADIC_C5,0) > 0 and vsPDVersaoXml  = '4'))
     union all
     --V- Informações Adicionais
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '3D-', to_char(TMP_M014_ITEM.m014_id_item), TMP_M014_ITEM.m014_nr_item,
        '3600;' ||
        TRIM(REPLACE(REPLACE(TMP_M014_ITEM.M014_DS_INFO, CHR(13), ' '), CHR(10), ' ')),
        pnSeqNota
     from   TMP_M014_ITEM
     where  TMP_M014_ITEM.m000_id_nf = pnSeqNota
     and    TMP_M014_ITEM.M014_DS_INFO is not null
     and    nvl(vsPDConcObsPedVdaItemInfoItem, 'N') != 'C'
     union all
     -- vItem- Valor Total do Item da NF-e
     --3750
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '3E-', to_char(a.m014_id_item), a.m014_nr_item,
        '3750' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M014_VL_VLRITEM, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 89, vdDtaHorEmissao, 'S', 13, 2), -- vItem
        pnSeqNota
     from  TMP_M014_ITEM a
     where a.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M014_VL_VLRITEM > 0
     union all
     -- DFeReferenciado- Grupo de Documento Fiscal Eletrônico Referenciado
     --3800
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 3000, '3F-', to_char(a.m014_id_item), a.m014_nr_item,
        '3800' ||
        fc5_BuscaCampoNotaTecnica(a.M014_DS_CHAVEACESSOREF, 2025002, pnNroEmpresa, 4, 1.30, 90, vdDtaHorEmissao) || -- chaveAcesso
        fc5_BuscaCampoNotaTecnica(a.M014_DS_NROITEMREF, 2025002, pnNroEmpresa, 4, 1.30, 91, vdDtaHorEmissao), -- nItem
        pnSeqNota
     from   TMP_M014_ITEM A
     where  A.m000_id_nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and (a.M014_DS_CHAVEACESSOREF is not null or a.M014_DS_NROITEMREF is not null);

     -- ================ registro W - 4000 - Valores Totais da NF-e ======================

     -- FCP ST Ret, FCP ST Outras Desp
     select case when vsIndUtilCalcFCP = 'S' and nvl(sum(ITEM.m014_vl_fcp_ret), 0) > 0 then
              sum(ITEM.m014_vl_fcp_ret)
            end VlrTotFCPSTRet

     into   vnVlrTotFCPSTRet

     from   TMP_M000_NF NF,
            TMP_M014_ITEM ITEM,
            TMP_M001_EMITENTE EMIT

     where  ITEM.M000_ID_NF = NF.m000_id_nf
     and    ITEM.M000_ID_NF = EMIT.M000_ID_NF
     and    NF.m000_id_nf   = pnSeqNota
     and    ((ITEM.m014_CSOSN_C5 = '500' and  EMIT.M001_DM_CRT IN (0, 3)) or ITEM.M014_DM_TRIB_ICMS = 8);

     -- FCPICMS
     select decode(vsIndUtilCalcFCP, 'S', sum(ITEM.m014_vl_fcp_icms), sum(ITEM.vlrfecp)) VlrTotFCPIcms
     into   vnVlrTotFCPIcms
     from   TMP_M014_ITEM ITEM,
            TMP_M001_EMITENTE EMIT
     where  ITEM.M000_ID_NF = EMIT.M000_ID_NF
     and    ITEM.M000_ID_NF = pnSeqNota
     and    ((ITEM.m014_CSOSN_C5 != '500' and  EMIT.M001_DM_CRT IN (0, 3)) or  ITEM.M014_DM_TRIB_ICMS != 8);
     -- FCP ST
     select case when vsIndUtilCalcFCP = 'S' and nvl(SUM(ITEM.M014_VL_BC_FCP_ST), 0) > 0 then
                  sum(ITEM.m014_vl_fcp_st)
            end VlrTotFCPST
     into   vnVlrTotFCPST
     from   TMP_M014_ITEM ITEM,
            TMP_M001_EMITENTE EMIT
     where  ITEM.M000_ID_NF = EMIT.M000_ID_NF
     and    ITEM.M000_ID_NF = pnSeqNota
     and    ((ITEM.m014_CSOSN_C5 != '500' and  EMIT.M001_DM_CRT IN (0, 3)) or  ITEM.M014_DM_TRIB_ICMS not in (0, 2, 8));

     select sum(case when vsEmiteApuracaoIPI = 'S' and FC5_IndCalcIPISaida(ITEM.SEQPRODUTOC5, pnNroEmpresa) = 'S' then
                  case when nvl(ITEM.m014_vl_ipi, 0) = 0 then
                    nvl(ITEM.M014_VL_IPI_DADOSADIC_C5, 0)
                  else
                    nvl(ITEM.m014_vl_ipi, 0)
                  end
                else
                  0
                end) VlrTotIPI,
            sum(case when vsEmiteApuracaoIPI = 'S' and FC5_IndCalcIPISaida(ITEM.SEQPRODUTOC5, pnNroEmpresa) = 'S' then
                  0
                else
                  case when nvl(ITEM.m014_vl_ipi, 0) = 0 then
                    nvl(ITEM.M014_VL_IPI_DADOSADIC_C5, 0)
                  else
                    nvl(ITEM.m014_vl_ipi, 0)
                  end
                end) VlrTotIPIDevol
     into   vnVlrTotIPI, vnVlrTotIPIDevol
     from   TMP_M014_ITEM ITEM
     where  ITEM.M000_ID_NF = pnSeqNota;

     SELECT MAX(CASE
                    WHEN LPAD(NVL(I.M014_CD_CSTIBSUF, I.M014_CD_CSTCBS), 3, '0') IN
                             ('000', '200', '220', '222', '510', '515', '550', '830')
                    THEN 'S'
                    END),
            MAX(CASE
                    WHEN LPAD(NVL(I.M014_CD_CSTIBSUF, I.M014_CD_CSTCBS), 3, '0') NOT IN
                             ('000', '200', '220', '222', '510', '515', '550', '830')
                    THEN 'S'
                    END)
       INTO indGeraGrupoIBSCBSTot,
            indTemItemNaoGeraGrupoIBSCBSTot
       FROM TMP_M000_NF N, TMP_M014_ITEM I
      WHERE N.M000_ID_NF = I.M000_ID_NF
        AND I.M000_ID_NF = pnSeqNota;

     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4000,
        '4000;' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_BC_ICMS) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_ICMS) || ';' ||

       case when vsUFEmpresa in ('RJ','SC','GO') AND NVL(M000_MOTIVO_DES_ICMS, 0) != 8 THEN
          fc5ConverteNumberToChar(tmp_m000_nf.m000_vl_icms_des) || ';'
        else
          case when TMP_M000_NF.M000_MOTIVO_DES_ICMS = 9 and TMP_M000_NF.VLRDESCICMS > 0 then
                    fc5ConverteNumberToChar(TMP_M000_NF.VLRDESCICMS) || ';'
                 when TMP_M000_NF.M000_MOTIVO_DES_ICMS in (3, 7, 8, 12) then
                     case when TMP_M000_NF.M000_VL_ICMS > 0  then
                          fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_ICMS) || ';'
                          when TMP_M000_NF.VLRDESCICMS > 0  then
                          fc5ConverteNumberToChar(TMP_M000_NF.VLRDESCICMS) || ';'
                     else
                          fc5ConverteNumberToChar(nvl(TMP_M000_NF.VLRDESCSUFRAMA, 0)) || ';'
                     end
          else
               '0.00;'
          end
        end ||

        fc5ConverteNumberToChar(TMP_M000_NF.M000_VLRFCPUFDEST) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VLRICMSUFDEST) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VLRICMSUFREMET) || ';' ||

        decode( vsPDVersaoXml,
                  '4',
                     fc5ConverteNumberToChar(nvl(vnVlrTotFCPIcms, 0)) || ';',
                  NULL) ||

        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_BC_ICMS_ST) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_ICMS_ST) || ';' ||

        decode( vsPDVersaoXml,
                  '4',
                     fc5ConverteNumberToChar(nvl(vnVlrTotFCPST, 0), 13) || ';' ||
                     fc5ConverteNumberToChar(nvl(vnVlrTotFCPSTRet, 0), 13) || ';',
                  NULL) ||

        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_PROD) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_FRETE) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_SEGURO) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_DESCONTO) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_TOTAL_II) || ';' ||
        case when TMP_M000_NF.M000_DM_FIN_EM = 4 then
          fc5ConverteNumberToChar(vnVlrTotIPI) || ';' ||
          fc5ConverteNumberToChar(vnVlrTotIPIDevol)
        else
          fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_IPI) || ';' ||
          fc5ConverteNumberToChar(0)
        end || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_PIS) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_COFINS) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_OUTROS) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_NF) || ';' ||

        DECODE( vsPDGeraRegTotImpNFe,
                   'N', '0',
                   DECODE(NVL(TMP_M000_NF.M000_VL_TOTTRIB, 0), '0',  '0', fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_TOTTRIB))
        ) ||
        CASE
          WHEN vsPDVersaoXml = '4' AND fc5_BuscaCampoNotaTecnica(TMP_M000_NF.M000_VL_ICMS_MONO, 2023001, pnNroEmpresa, 4, 1, 609, vdDtaHorEmissao)
            IS NOT NULL THEN
            ';' ||
            fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_ICMS_MONO) || ';' ||
            fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_ICMS_MONO_RETEN) || ';' ||
            fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_ICMS_MONO_RET)|| ';' ||
            fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_BC_ICMS_MONO) || ';' ||
            fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_BC_ICMS_MONO_RETEN) || ';' ||
            fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_BC_ICMS_MONO_RET)
          ELSE
            ''
        END,
        pnSeqNota
     from   TMP_M000_NF
     where  TMP_M000_NF.M000_Id_Nf = pnSeqNota

     union all

     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4100,
        '4100;' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_SERV) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_BC_ISS) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_ISS) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_PIS_ISS) || ';' ||
        fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_COFINS_ISS) || ';' ||
        to_char(TMP_M000_NF.M000_DT_EMISSAO, 'YYYY-MM-DD') || ';;;;;;',
        pnSeqNota
     from   TMP_M000_NF
     where  TMP_M000_NF.M000_Id_Nf = pnSeqNota
     and    TMP_M000_NF.M000_VL_SERV > 0

     union all

     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4200,
        '4200;' ||
        CASE WHEN TMP_M000_NF.M000_VL_RET_PIS > 0 THEN
         fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_RET_PIS)
        ELSE ''
        END || ';' ||
        CASE WHEN TMP_M000_NF.M000_VL_RET_COFINS > 0 THEN
         fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_RET_COFINS)
        ELSE ''
        END || ';' ||
        CASE WHEN TMP_M000_NF.M000_VL_RET_CSLL > 0 THEN
         fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_RET_CSLL)
        ELSE ''
        END || ';' ||
        CASE WHEN TMP_M000_NF.M000_VL_RET_IRRF > 0 THEN
         fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_BC_IRRF)
        ELSE ''
        END || ';' ||
        CASE WHEN TMP_M000_NF.M000_VL_RET_IRRF > 0 THEN
         fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_RET_IRRF)
        ELSE ''
        END || ';' ||
        CASE WHEN TMP_M000_NF.M000_VL_RET_PREV > 0 THEN
         fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_BC_RET_PREV)
        ELSE ''
        END || ';' ||
        CASE WHEN TMP_M000_NF.M000_VL_RET_PREV > 0 THEN
         fc5ConverteNumberToChar(TMP_M000_NF.M000_VL_RET_PREV)
        ELSE ''
        END,
        pnSeqNota
     from   TMP_M000_NF
     where  TMP_M000_NF.M000_Id_Nf = pnSeqNota

     union all

     -- ISTot ¿ Grupo total do imposto seletivo
     --4300
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4300,
        '4300' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOIS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 92, vdDtaHorEmissao, 'S', 13, 2), -- vIS
        pnSeqNota
     from   TMP_M000_NF a
     where  a.M000_Id_Nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M000_VL_VLRIMPOSTOIS > 0

     union all

     -- IBSCBSTot ¿ Totais da NF-e com IBS e CBS
     --4350
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4350,
        '4350' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(NVL(a.M000_VL_VLRBASECBS,a.M000_VL_VLRBASEIBSUF) , csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 93, vdDtaHorEmissao, 'S', 13, 2), -- vBCIBSCBS
        pnSeqNota
     from   TMP_M000_NF a
     where  a.M000_Id_Nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (((a.M000_VL_VLRBASEIBSUF >= 0 or a.M000_VL_VLRBASECBS >= 0) and indGeraGrupoIBSCBSTot = 'S') or indTemItemNaoGeraGrupoIBSCBSTot = 'S')

     union all

     -- gIBS ¿ Grupo total do IBS
     --4360
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4360,
        '4360' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 94, vdDtaHorEmissao, 'S', 13, 2) || -- vIBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRCCREDPRESIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 95, vdDtaHorEmissao, 'S', 13, 2) || -- vCresPres
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRCCREDPRESCONDSUSIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 96, vdDtaHorEmissao, 'S', 13, 2), -- vCredPresCondSus
        pnSeqNota
     from   TMP_M000_NF a
     where  a.M000_Id_Nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (((a.M000_VL_VLRIMPOSTOIBS >= 0 or a.M000_VL_VLRCCREDPRESIBSUF >= 0) and indGeraGrupoIBSCBSTot = 'S') or indTemItemNaoGeraGrupoIBSCBSTot = 'S')

     union all

     -- gIBSUF ¿ Grupo total do IBS da UF
     --4365
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4365,
        '4365' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRDIFERIDOIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 97, vdDtaHorEmissao, 'S', 13, 2) || -- vDif
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRDEVTRIBIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 98, vdDtaHorEmissao, 'S', 13, 2) || -- vDevTrib
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOIBSUF, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 99, vdDtaHorEmissao, 'S', 13, 2), -- vIBSUF
        pnSeqNota
     from   TMP_M000_NF a
     where  a.M000_Id_Nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (((a.M000_VL_VLRDIFERIDOIBSUF >= 0 or a.M000_VL_VLRIMPOSTOIBSUF >= 0) and indGeraGrupoIBSCBSTot = 'S') or indTemItemNaoGeraGrupoIBSCBSTot = 'S')

     union all

     -- gIBSMun ¿ Grupo total do IBS do Município
     --4370
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4370,
        '4370' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRDIFERIDOIBSMUN, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 100, vdDtaHorEmissao, 'S', 13, 2) || -- vDif
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRDEVTRIBIBSMUN, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 101, vdDtaHorEmissao, 'S', 13, 2) || -- vDevTrib
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOIBSMUN, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 102, vdDtaHorEmissao, 'S', 13, 2), -- vIBSMun
        pnSeqNota
     from   TMP_M000_NF a
     where  a.M000_Id_Nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (((a.M000_VL_VLRDIFERIDOIBSMUN >= 0 or a.M000_VL_VLRIMPOSTOIBSMUN >= 0) and indGeraGrupoIBSCBSTot = 'S') or indTemItemNaoGeraGrupoIBSCBSTot = 'S')

     union all

     -- gCBS ¿ Grupo total da CBS
     --4380
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4380,
        '4380' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRDIFERIDOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 103, vdDtaHorEmissao, 'S', 13, 2) || -- vDif
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRDEVTRIBCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 104, vdDtaHorEmissao, 'S', 13, 2) || -- vDevTrib
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 105, vdDtaHorEmissao, 'S', 13, 2) || -- vCBS
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRCCREDPRESCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 106, vdDtaHorEmissao, 'S', 13, 2) || -- vCresPres
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRCCREDPRESCONDSUSCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 107, vdDtaHorEmissao, 'S', 13, 2), -- vCredPresCondSus
        pnSeqNota
     from   TMP_M000_NF a
     where  a.M000_Id_Nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (((a.M000_VL_VLRDIFERIDOCBS >= 0 or a.M000_VL_VLRIMPOSTOCBS >= 0 or a.M000_VL_VLRCCREDPRESCBS > 0) and indGeraGrupoIBSCBSTot = 'S') or indTemItemNaoGeraGrupoIBSCBSTot = 'S')

     union all

     -- gMono ¿ Grupo total da Monofasia
     --4390
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4390,
        '4390' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOMONOIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 108, vdDtaHorEmissao, 'S', 13, 2) || -- vIBSMono
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOMONOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 109, vdDtaHorEmissao, 'S', 13, 2) || -- vCBSMono
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOMONORETENIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 110, vdDtaHorEmissao, 'S', 13, 2) || -- vIBSMonoReten
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOMONORETENCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 111, vdDtaHorEmissao, 'S', 13, 2) || -- vCBSMonoReten
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOMONORETIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 112, vdDtaHorEmissao, 'S', 13, 2) || -- vIBSMonoRet
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOMONORETCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 113, vdDtaHorEmissao, 'S', 13, 2), -- vCBSMonoRet
        pnSeqNota
     from   TMP_M000_NF a
     where  a.M000_Id_Nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M000_VL_VLRIMPOSTOMONORETIBS > 0 or a.M000_VL_VLRIMPOSTOMONORETCBS > 0)

     union all

     -- gEstornoCred ¿ Grupo total do Estorno de Crédito
     --4395
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4390,
        '4395' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOESTORNOIBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 126, vdDtaHorEmissao, 'S', 13, 2) || -- vIBSMonoRet
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_VLRIMPOSTOESTORNOCBS, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 127, vdDtaHorEmissao, 'S', 13, 2), -- vCBSMonoRet
        pnSeqNota
     from   TMP_M000_NF a
     where  a.M000_Id_Nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   (a.M000_VL_VLRIMPOSTOESTORNOIBS > 0 or a.M000_VL_VLRIMPOSTOESTORNOCBS > 0)

     union all

     -- Total NF ¿ Grupo de totais da Nota Fiscal Considerando os Impostos por fora
     --4400
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 4400,
        '4400' ||
        fc5_BuscaCampoNotaTecnica(rtrim(to_char(a.M000_VL_NFTOT, csFormatoNumber13_2), ','), 2025002, pnNroEmpresa, 4, 1.30, 114, vdDtaHorEmissao, 'S', 13, 2), -- vNFTot
        pnSeqNota
     from   TMP_M000_NF a
     where  a.M000_Id_Nf = pnSeqNota
     and   vsStatusNT2025002 = 'A'
     and   a.M000_VL_NFTOT > 0;

     --X-Informações do Transporte da NF-e
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 5000,
        '5000;' ||
        TMP_M006_TRANSPORTE.M006_DM_FRETE,
        pnSeqNota
     from   TMP_M006_TRANSPORTE
     where  TMP_M006_TRANSPORTE.M000_ID_NF = pnSeqNota
     and    TMP_M006_TRANSPORTE.M006_DM_FRETE is not null
     union all
     ---registro 5100 - TRANSPORTA ¿ dados do transportador
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 5100,
        '5100;' ||
        TMP_M006_TRANSPORTE.M006_NR_CNPJ_CPF || ';' ||
        decode(vsPDInfDadosTransp, '3', '', TMP_M006_TRANSPORTE.M006_NM_TRANSP)  || ';' ||
        TMP_M006_TRANSPORTE.M006_NR_IE || ';' ||
        decode(vsPDInfDadosTransp, '1', trim(TMP_M006_TRANSPORTE.M006_NM_LOGR), '') || ';' ||
        TMP_M006_TRANSPORTE.M006_DS_MUN  || ';' ||
        TMP_M006_TRANSPORTE.M006_DS_UF,
        pnSeqNota
     from   TMP_M006_TRANSPORTE
     where  TMP_M006_TRANSPORTE.M000_ID_NF = pnSeqNota
     and    TMP_M006_TRANSPORTE.M006_DM_FRETE is not null
     and    TMP_M006_TRANSPORTE.M006_NM_TRANSP is not null
     union all
     ---registro 5300 - TRANSPORTA ¿ dados da placa
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 5300,
        '5300;' ||
        TMP_M006_TRANSPORTE.M006_DS_PLACA || ';' ||
        TMP_M006_TRANSPORTE.M006_DS_UF_PLACA  || ';' ||
        TMP_M006_TRANSPORTE.M006_NR_RNTC ,
        pnSeqNota
     from   TMP_M006_TRANSPORTE
     where  TMP_M006_TRANSPORTE.M000_ID_NF = pnSeqNota
     and    TMP_M006_TRANSPORTE.M006_DM_FRETE is not null
     and    TMP_M006_TRANSPORTE.M006_DS_PLACA is not null
     and    case
              when TMP_M006_TRANSPORTE.M006_DS_UF_PLACA is null then -- Tratamento para atender a NT 2020.005 onde UF da placa é opcional
                case
                  when fc5_buscacamponotatecnica(null, 2020005, 1, 4, 1, 613, vdDtaHorEmissao) is not null then
                    1
                  else
                    0
                end
              else
                1
            end > 0
     and    vnIndDestInterstadual != 2
     union all
     ---registro 5600 - balsa
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 5600,
        '5600;' || TMP_M006_TRANSPORTE.M006_IDENTIFICA_BALSA,
        pnSeqNota
     from   TMP_M006_TRANSPORTE
     where  TMP_M006_TRANSPORTE.M000_ID_NF = pnSeqNota
     and    TMP_M006_TRANSPORTE.M006_IDENTIFICA_BALSA is not null
     union all
     ---registro 5700 - VOL ¿ Dados dos volumes
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 5700,
        '5700;' ||
        NVL(TMP_M008_VOLUME.M008_VL_QTDE, 0) || ';' ||
        TMP_M008_VOLUME.M008_DS_ESPECIE || ';' ||
        TMP_M008_VOLUME.M008_DS_MARCA || ';' ||
        TMP_M008_VOLUME.M008_NR_IDENT || ';' ||
        fc5ConverteNumberToChar(TMP_M008_VOLUME.M008_VL_PL, 9, 3) || ';' ||
        fc5ConverteNumberToChar(TMP_M008_VOLUME.M008_VL_PB, 9, 3),
        pnSeqNota
     from    TMP_M008_VOLUME
     where   TMP_M008_VOLUME.M000_ID_NF = pnSeqNota;

     --Y - Dados de Cobrança
     --FAT ¿ dados da fatura
     -- 6000 - NFe 4.0
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 6000,
        '6000;' ||
        TMP_M003_FATURA.M003_NR_FATURA || ';' ||
        fc5ConverteNumberToChar(nvl(B.M004_VL_DUPLICATA, TMP_M003_FATURA.M003_VL_ORIGINAL)) || ';' ||
        fc5ConverteNumberToChar(nvl(TMP_M003_FATURA.M003_VL_DESCONTO, 0)) || ';' ||
        fc5ConverteNumberToChar(nvl(B.M004_VL_DUPLICATA, TMP_M003_FATURA.M003_VL_LIQUIDO)),
        pnSeqNota
     from   TMP_M003_FATURA,
            ( select SUM(D.M004_VL_DUPLICATA) M004_VL_DUPLICATA
              from   TMP_M004_DUPLICATA D
              where  D.M000_ID_NF = pnSeqNota
            ) B,
            TMP_M000_NF
     where  TMP_M003_FATURA.M000_ID_NF      = pnSeqNota
     AND    TMP_M000_NF.M000_ID_NF          = TMP_M003_FATURA.M000_ID_NF
     AND    B.M004_VL_DUPLICATA             > 0
     AND    TMP_M000_NF.M000_FORMAPAGTONFE != '90'
     AND    vsPDVersaoXml = '4';

     --DUP ¿ dados da duplicata
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, ordem, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 6100,
        '6100;' ||
        trim(lpad(TMP_M004_DUPLICATA.M004_NR_DUPLICATA, 3, '0')) || ';' ||
        to_char(TMP_M004_DUPLICATA.M004_DT_VENCIMENTO, 'yyyy-MM-dd') || ';' ||
        fc5ConverteNumberToChar(TMP_M004_DUPLICATA.M004_VL_DUPLICATA, 12),
        TMP_M004_DUPLICATA.M004_ID_DUPLICATA,
        pnSeqNota
     from    TMP_M004_DUPLICATA, TMP_M003_FATURA,
             ( select count(d.M004_NR_DUPLICATA) qtd, count(distinct(d.M004_NR_DUPLICATA)) qtdunicas
               from   TMP_M004_DUPLICATA d
               where  d.M000_ID_NF = pnSeqNota
               and    d.M004_VL_DUPLICATA > 0
             ) parcelas,
             TMP_M000_NF
     where   TMP_M004_DUPLICATA.M000_ID_NF = pnSeqNota
     and     TMP_M004_DUPLICATA.M004_VL_DUPLICATA > 0
     and     TMP_M003_FATURA.M000_ID_NF = TMP_M004_DUPLICATA.M000_ID_NF
     and     TMP_M000_NF.M000_Id_Nf = TMP_M004_DUPLICATA.M000_ID_NF
     and     TMP_M000_NF.M000_FORMAPAGTONFE != '90'
     and     TMP_M004_DUPLICATA.M004_DT_VENCIMENTO >= trunc(sysdate)
     and     TMP_M000_NF.M000_INDPAG = 1
     and     parcelas.QTD = parcelas.qtdunicas
     order by TMP_M004_DUPLICATA.M004_ID_DUPLICATA;

     --registro Z- Informações Adicionais
     --INFADIC ¿ grupo de Informações Adicionais

      insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
      select
         pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 6500,
         '6500;' ||
         (select case
                   when (sum(DETPAGTO.M005_VLRLANCTO) - NF.M000_VL_NF) > 0 then
                        fc5ConverteNumberToChar(sum(DETPAGTO.M005_VLRLANCTO) - NF.M000_VL_NF, 13, 2)
                   else
                        ''
                 end
            from TMP_M000_NF NF
                 join TMP_M005_DETPAGTO DETPAGTO
                   on NF.M000_ID_NF = DETPAGTO.M000_ID_NF
           where DETPAGTO.M000_FORMAPAGTONFE IN ('03', '04', '17')
             and NF.M000_ID_NF = pnSeqNota
           group by NF.M000_VL_NF),
         pnSeqNota
        from dual
        where vsPDVersaoXml = '4';

      insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal, auxiliar1, ordem)
      select
         pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 6510,
        '6510' ||
        ';'    || NF.M000_FORMAPAGTONFE || -- Forma de pagamento
        ';'    || decode( NF.M000_FORMAPAGTONFE,
                            '90', '0.00',
                            fc5ConverteNumberToChar(NF.M000_VL_NF)
                  ) || -- Valor do pagamento
        ';'    || NF.M000_INDPAG || -- Ident. da forma de pagamento = (0 ¿ Pagamento à vista / 1 ¿ Pagamento à prazo)
        DECODE(NF.M000_FORMAPAGTONFE, '99',
              SUBSTR(NVL(CASE
                           WHEN NF.M000_DM_ENTRADA_SAIDA = 0 THEN
                             fc5_BuscaCampoNotaTecnica(vsPDDescFormaPagtoOutrosEnt, 2020006, pnNroEmpresa, 4, 1.2, 644, vdDtaHorEmissao) -- PD Padrão de Documentos de Entrada
                           ELSE
                             NULL
                         END, fc5_BuscaCampoNotaTecnica(vsDescFormaPagtoOutros, 2020006, pnNroEmpresa, 4, 1.2, 644, vdDtaHorEmissao)
                         ), 0, 60),
               fc5_BuscaCampoNotaTecnica(NULL, 2020006, pnNroEmpresa, 4, 1.2, 644, vdDtaHorEmissao) ) -- Descrição do meio de pagamento para 99 - Outros
               || fc5_BuscaCampoNotaTecnica( TO_CHAR(NF.M000_DPAG, 'YYYY-MM-DD'), 2023004, pnNroEmpresa, 4, 1.20, 694, vdDtaHorEmissao)    -- dPag, Data Pagamento
               || fc5_BuscaCampoNotaTecnica( LPAD(NF.M000_CNPJPAG,14,'0'), 2023004, pnNroEmpresa, 4, 1.20, 695, vdDtaHorEmissao) -- CNPJPag, CNPJ transacional do pagamento
               || fc5_BuscaCampoNotaTecnica( NF.M000_UFPag, 2023004, pnNroEmpresa, 4, 1.20, 696, vdDtaHorEmissao),  -- UFPag, UF do CNPJ do estabelecimento onde o pagamento foi processado/transacionado/recebido
        pnSeqNota,
        1,
        '1A'
        from  TMP_M000_NF NF
        where vsPDVersaoXml = '4'
        and   NF.M000_Id_Nf = pnSeqNota
        and   not exists (select 1
                            from TMP_M005_DETPAGTO DETPAGTO
                           where DETPAGTO.M000_ID_NF = NF.M000_ID_NF
                             and DETPAGTO.M005_VLRLANCTO > 0
                             and DETPAGTO.M000_FORMAPAGTONFE in ('03', '04', '17'))

     UNION ALL

     SELECT pnNroEmpresa, psSoftPDV, vdDtaMovimento, SYSDATE, vsNomeArquivo, 6510,
            '6510' ||
            ';'    || DETPAGTO.M000_FORMAPAGTONFE || -- Forma de pagamento
            ';'    || DECODE(DETPAGTO.M000_FORMAPAGTONFE, '90', '0.00', fc5ConverteNumberToChar(DETPAGTO.M005_VLRLANCTO, 13, 2)) || -- Valor do pagamento
            ';'    || DETPAGTO.M005_INDPAG -- Ident. da forma de pagamento = (0 ¿ Pagamento à vista / 1 ¿ Pagamento à prazo)
                   || DECODE(DETPAGTO.M000_FORMAPAGTONFE, '99',  -- Descrição do meio de pagamento para 99 - Outros
                              SUBSTR(fc5_BuscaCampoNotaTecnica(vsDescFormaPagtoOutros, 2020006, pnNroEmpresa, 4, 1.2, 644, vdDtaHorEmissao), 0, 60),
                             fc5_BuscaCampoNotaTecnica(NULL, 2020006, pnNroEmpresa, 4, 1.2, 644, vdDtaHorEmissao))
                   || fc5_BuscaCampoNotaTecnica( TO_CHAR(DETPAGTO.M005_DPAG, 'YYYY-MM-DD'), 2023004, pnNroEmpresa, 4, 1.20, 694, vdDtaHorEmissao)    -- dPag, Data Pagamento
                   || fc5_BuscaCampoNotaTecnica( LPAD(DETPAGTO.M005_CNPJPAG,14,'0'), 2023004, pnNroEmpresa, 4, 1.20, 695, vdDtaHorEmissao) -- CNPJPag, CNPJ transacional do pagamento
                   || fc5_BuscaCampoNotaTecnica( DETPAGTO.M005_UFPag, 2023004, pnNroEmpresa, 4, 1.20, 696, vdDtaHorEmissao),  -- UFPag, UF do CNPJ do estabelecimento onde o pagamento foi processado/transacionado/recebido,
           pnSeqNota,
           DETPAGTO.M005_ID_DETPAGTO,
           '1A'
      FROM TMP_M005_DETPAGTO DETPAGTO
     WHERE vsPDVersaoXml = '4'
       AND DETPAGTO.M000_ID_NF = pnSeqNota
       AND DETPAGTO.M005_VLRLANCTO > 0
       AND DETPAGTO.M000_FORMAPAGTONFE IN ('03', '04', '17')
     ORDER BY DETPAGTO.M005_ID_DETPAGTO;

      insert into mrlx_pdvimportacao(
        nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha,
        seqnotafiscal, auxiliar1, ordem)
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 6510,
        '6550;' ||
        '2;'    ||   -- tpIntegra - (1 - Pagamento integrado / 2 - Pagamento não integrado)
        ';'     ||   -- CNPJ da instituição de pagamento
        ';'     ||   -- tBand - Bandeira da operado de cartão de crédito/débito (Visa, MasterCard, etc)
        ';'     ||   -- cAut - Número de autorização da operação cartão de crédito/débito.
        ';'     ||   -- cnpjReceb - CNPJ do estabelecimento beneficiário do Pagamento
        ';',  -- idTermPag - Identificar o terminal em que foi realizado o pagamento
        pnSeqNota,
        1,
        '1B'
        from  TMP_M000_NF NF
        where vsPDVersaoXml = '4'
        and   NF.M000_Id_Nf = pnSeqNota
        and   NF.M000_FORMAPAGTONFE in('03', '04', '17')
        and   vsUFEmpresa not in('CE')
        and   not exists (select 1
                            from TMP_M005_DETPAGTO DETPAGTO
                           where DETPAGTO.M000_ID_NF = NF.M000_ID_NF
                             and DETPAGTO.M005_VLRLANCTO > 0
                             and DETPAGTO.M000_FORMAPAGTONFE in ('03', '04', '17'))

      UNION ALL

      SELECT pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate, vsNomeArquivo, 6510,
             '6550' || ';' ||
             DETPAGTO.M005_TPINTEGRA || ';' ||  -- tpIntegra - (1 - Pagamento integrado / 2 - Pagamento não integrado)
             NVL(DETPAGTO.M005_CNPJCARTAO,DECODE(NF.M000_INDINTERMED, 1, NF.M000_CNPJ_INTERMED, NULL)) || ';'|| -- CNPJ da instituição de pagamento
             DETPAGTO.M005_TBANDCARTAO ||';' ||  -- tBand - Bandeira da operado de cartão de crédito/débito (Visa, MasterCard, etc)
             DETPAGTO.M005_CAUTCARTAO || -- cAut - Número de autorização da operação cartão de crédito/débito.
             CASE WHEN fc5_BuscaCampoNotaTecnica( DETPAGTO.M005_CNPJRECEB, 2023004, pnNroEmpresa, 4, 1.20, 701, vdDtaHorEmissao) IS NOT NULL
                     AND fc5_BuscaCampoNotaTecnica( DETPAGTO.M005_IDTERMPAG, 2023004, pnNroEmpresa, 4, 1.20, 702, vdDtaHorEmissao) IS NOT NULL
                  THEN
                     fc5_BuscaCampoNotaTecnica( DETPAGTO.M005_CNPJRECEB, 2023004, pnNroEmpresa, 4, 1.20, 701, vdDtaHorEmissao) ||
                     fc5_BuscaCampoNotaTecnica( DETPAGTO.M005_IDTERMPAG, 2023004, pnNroEmpresa, 4, 1.20, 702, vdDtaHorEmissao)
                  ELSE
                     ''
             END,
             pnSeqNota,
             DETPAGTO.M005_ID_DETPAGTO,
             '1B'
        FROM TMP_M000_NF NF, TMP_M005_DETPAGTO DETPAGTO
       WHERE NF.M000_ID_NF = DETPAGTO.M000_ID_NF
         AND DETPAGTO.M000_ID_NF = pnSeqNota
         -- Alt Giuliano 25/01
         AND DETPAGTO.M000_FORMAPAGTONFE IN ('03', '04', '17','36','50','51','56','53')
         AND DETPAGTO.M005_VLRLANCTO > 0
         AND vsUFEmpresa NOT IN ('CE')
         AND vsPDVersaoXml = '4'
       ORDER BY DETPAGTO.M005_ID_DETPAGTO;

     -- InfIntermed ¿ Intermediador da Transação
     insert into mrlx_pdvimportacao(
        nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha,
        seqnotafiscal)
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 6600,
        '6600' ||
        fc5_buscacamponotatecnica(NF.M000_CNPJ_INTERMED, 2020006, pnNroEmpresa, 4, 1, 648, vdDtaHorEmissao) || -- CNPJ do Intermediador da Transação
        fc5_buscacamponotatecnica(NF.M000_NOME_INTERMED, 2020006, pnNroEmpresa, 4, 1, 649, vdDtaHorEmissao), -- IdCadIntTran - Identificador cadastrado no intermediador
        pnSeqNota
        from  TMP_M000_NF NF
        where vsPDVersaoXml = '4'
        and   NF.M000_Id_Nf = pnSeqNota
        and   replace(trim(fc5_BuscaCampoNotaTecnica(NF.M000_INDINTERMED, 2020006, pnNroEmpresa, 4, 1, 26, vdDtaHorEmissao)), ';', '') = '1';

     select '7000;' || trim(replace(replace(TMP_M000_NF.M000_DS_INFO_FISCO , chr(13), null), chr(10), null)) || ';'
     into   vsObservacao
     from   TMP_M000_NF
     where  TMP_M000_NF.M000_ID_NF = pnSeqNota;

     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha,
        seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 7000,
        vsObservacao || substr( trim(replace(replace(TMP_M000_NF.M000_DS_INFO_CONTRIB, chr(13), null), chr(10), null)),
                                1,
                                4000 - length(vsObservacao)),
        pnSeqNota
     from   TMP_M000_NF
     where  TMP_M000_NF.M000_ID_NF = pnSeqNota;

     -- Objeto Customização 7100 (Linha)
     pObjGeraLinha.cnSeqNota := pnSeqNota;
     pObjGeraLinha.cnNroRegistro := 7100;
     SP_GERALINHACUST(pObjGeraLinha);

     --OBSFISCO
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha,
        seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 7200,
        '7200;' || A.CAMPO || ';' || A.TEXTO,
        pnSeqNota
     from   MFL_INFOADICIONALFISCO A
     where  A.SEQNOTAFISCAL = pnSeqNota;

     -- Objeto Customização 7300 (Linha)
     pObjGeraLinha.cnSeqNota := pnSeqNota;
     pObjGeraLinha.cnNroRegistro := 7300;
     SP_GERALINHACUST(pObjGeraLinha);

     -- ZA-Informações de Comércio Exterior
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 8000,
        '8000;' ||
        TMP_M000_NF.M000_DS_UF_EMBARQUE || ';' ||
        TMP_M000_NF.M000_DS_LOCAL_EMBARQUE || ';', pnSeqNota
     from   TMP_M000_NF
     where  TMP_M000_NF.M000_ID_NF = pnSeqNota
     and    TMP_M000_NF.M000_DS_UF_EMBARQUE is not null
     and    TMP_M000_NF.NRODECLARAIMPORTc5 is null
     and    decode(vsIndVendaInterPresencial, 'S', '1', decode(TMP_M000_NF.ufdestinoc5, vsUFEmpresa, '1', 'EX', '3', '2')) = 3
     union all
     --ZB-Informações de Compras
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 9000,
        '9000;' ||
        TMP_M000_NF.M000_DS_NF_EMPENHO || ';' ||
        TMP_M000_NF.M000_DS_PEDIDO || ';' ||
        TMP_M000_NF.M000_DS_CONTRATO, pnSeqNota
     from    TMP_M000_NF
     where   TMP_M000_NF.M000_ID_NF = pnSeqNota
     and     TMP_M000_NF.M000_DS_NF_EMPENHO is not null;

     --defensivo ¿ Defensivo Agrícola / Agrotóxico
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 9910,
        '9910' ||
        fc5_BuscaCampoNotaTecnica(A.M014_NR_RECEITUARIO, 2024003, pnNroEmpresa, 4, 1.06, 1, vdDtaHorEmissao) ||
        fc5_BuscaCampoNotaTecnica(LPAD(A.M014_NR_CPFRESPTECNICO,11,0), 2024003, pnNroEmpresa, 4, 1.06, 2, vdDtaHorEmissao), pnSeqNota
     from  TMP_M014_ITEM A
     where A.M000_ID_NF = pnSeqNota
     and   A.M014_TP_GUIAAGRO = 'D'
     and   vsStatusNT2024003 = 'A'
     group by A.M014_NR_CPFRESPTECNICO, A.M014_NR_RECEITUARIO
     fetch first 20 rows only;

    --guiaTransito -  Guias de Trânsito de produtos agropecuários animais, vegetais e de origem florestal
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal)
     select
        pnNroEmpresa as nroempresa,
        psSoftPDV as softpdv,
        vdDtaMovimento as dtamovimento,
        sysdate as dtahorlancamento,
        vsNomeArquivo as arquivo,
        9920 as seqlinha,
        '9920' ||
        fc5_BuscaCampoNotaTecnica(A.M014_TP_GUIATRANSITO, 2024003, pnNroEmpresa, 4, 1.06, 3, vdDtaHorEmissao) ||
        fc5_BuscaCampoNotaTecnica(A.M014_UF_GUIA, 2024003, pnNroEmpresa, 4, 1.06, 4, vdDtaHorEmissao) ||
        fc5_BuscaCampoNotaTecnica(A.M014_NR_SERIEGUIA, 2024003, pnNroEmpresa, 4, 1.06, 5, vdDtaHorEmissao) ||
        fc5_BuscaCampoNotaTecnica(A.M014_NR_GUIA, 2024003, pnNroEmpresa, 4, 1.06, 6, vdDtaHorEmissao) as linha,
        pnSeqNota as seqnotafiscal
     from  TMP_M014_ITEM A
     where A.M000_ID_NF = pnSeqNota
     and   A.M014_TP_GUIAAGRO = 'G'
     and   vsStatusNT2024003 = 'A'
     order by A.M014_NR_GUIA desc
     fetch first 1 row only;


     IF vsEmailTransportador IS NOT NULL THEN
        vsEmailsNFe := vsEmailsNFe || ';' || vsEmailTransportador;
     END IF;

     if vsObsNFe is null then
         vsObsNFe := fc5_nfeobservacaonf(pnSeqNota);
     end if;

     --gera registro 10000
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        arquivo, seqlinha,
        linha, seqnotafiscal, auxiliar2)
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10000,
        '10000;', pnSeqNota, null
     from   dual
     union all
     Select pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
            vsNomeArquivo, 10100,
            '10100;email;' || trim(Column_Value),
            pnSeqNota, null
     From Table(Cast(C5_Complexin.C5intable(Replace(Replace(Replace(Trim(vsEmailsNFe), Chr(13), Null), Chr(10), Null), ';', ',')) As C5instrtable)) TBEMAIL
     where TBEMAIL.Column_Value like '%@%'
     union all

     select pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
            vsNomeArquivo, 10150,
            '10150;' || vsDirSalvaXmlNDD,
            pnSeqNota, null
       from dual
      where nvl(vsDirSalvaXmlNDD, 'N') <> 'N'
     union all

     select pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
            vsNomeArquivo, 10160,
            '10160;' || vsDirSalvaPdfNDD,
            pnSeqNota, null
       from dual
      where nvl(vsDirSalvaPdfNDD, 'N') <> 'N'
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
        '10200;' || 'MSG1;' ||
        trim(substr(replace(replace(replace(vsObsNFe, '"', null), chr(13), null), chr(10), null), 1, 85)),
        pnSeqNota, 1
     from   dual
     where  length(trim(substr(replace(replace(vsObsNFe, chr(13), null), chr(10), null), 1, 85))) > 0
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
        '10200;' || 'MSG2;' ||
        trim(substr(replace(replace(replace(vsObsNFe, '"', null), chr(13), null), chr(10), null), 86, 85)),
        pnSeqNota, 2
     from   dual
     where  length(trim(substr(replace(replace(vsObsNFe, chr(13), null), chr(10), null), 86, 85))) > 0
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
        '10200;' || 'MSG3;' ||
        trim(substr(replace(replace(replace(vsObsNFe, '"', null), chr(13), null), chr(10), null), 171, 85)),
        pnSeqNota, 3
     from   dual
     where  length(trim(substr(replace(replace(vsObsNFe, chr(13), null), chr(10), null), 171, 85))) > 0
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
        '10200;' || 'MSG4;' ||
        trim(substr(replace(replace(replace(vsObsNFe, '"', null), chr(13), null), chr(10), null), 256, 85)),
        pnSeqNota, 4
     from   dual
     where  length(trim(substr(replace(replace(vsObsNFe, chr(13), null), chr(10), null), 256, 85))) > 0
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
        '10200;' || 'MSG5;' ||
        trim(substr(replace(replace(replace(vsObsNFe, '"', null), chr(13), null), chr(10), null), 341, 85)),
        pnSeqNota, 5
     from   dual
     where  length(trim(substr(replace(replace(vsObsNFe, chr(13), null), chr(10), null), 341, 85))) > 0
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
        '10200;' || 'MSG6;' ||
        trim(substr(replace(replace(replace(vsObsNFe, '"',null), chr(13), null), chr(10), null), 426, 85)),
        pnSeqNota, 6
     from   dual
     where  length(trim(substr(replace(replace(vsObsNFe, chr(13), null), chr(10), null), 426, 85))) > 0
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
        '10200;' || 'MSG7;' ||
        trim(substr(replace(replace(replace(vsObsNFe, '"', null), chr(13), null), chr(10), null), 511, 85)),
        pnSeqNota, 7
     from   dual
     where  length(trim(substr(replace(replace(vsObsNFe, chr(13), null), chr(10), null), 511, 85))) > 0
    union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
        '10200;SERIE;' || vsSerieDF,
        pnSeqNota, 8
     from   dual
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
       '10200;FORMAPAG;'  || a.formapagtoreduz,
        pnSeqNota, 9
     from  MRL_FORMAPAGTO a
     where  a.NROFORMAPAGTO = vnNroFormaPagto
     and vsGeraFormCondCanhoto = 'S'
    union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10200,
       '10200;CONDICAOPAG;'  || a.desccondicaopagto,
        pnSeqNota, 10
     from  MAD_CONDICAOPAGTO A
     where  A.NROCONDICAOPAGTO = vnNroCondPagto
     and vsGeraFormCondCanhoto = 'S'
     union all
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
         vsNomeArquivo, 10200,
         '10200;' || M011.M011_DS_CAMPO || ';' || M011.M011_DS_TXT,
         pnSeqNota, 11
      from TMP_M011_INFO M011
      where M011.M000_ID_NF = pnSeqNota

     union all
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
         vsNomeArquivo, 10200,
         '10200;FATURA;' ||  fc5extenso(M000.M000_VL_NF) || ';',
         pnSeqNota, 12
      from TMP_M000_NF M000
      where M000.M000_ID_NF = pnSeqNota
     union all
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
         vsNomeArquivo, 10200,
         '10200;PERCREGRA.' || tmp_m014_item.m014_nr_item || ';' || fc5ConverteNumberToChar(tmp_m014_item.percincentivoped, 12) || ';',
         pnSeqNota, 13
      from tmp_m014_item
     where tmp_m014_item.m000_id_nf = pnSeqNota
       and tmp_m014_item.percincentivoped > 0
     union all
     select * from (
      select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
         vsNomeArquivo, 10200,
        '10200;VLIQ.'||
        to_char(TMP_M014_ITEM.M014_NR_ITEM - 1) || ';' ||
        trim(to_char(TMP_M014_ITEM.M014_VL_TOTAL_BRUTO - TMP_M014_ITEM.M014_VL_DESCONTO, '999G999G999G990d00', 'nls_numeric_characters='',.''')),
         pnSeqNota, 14
      from TMP_M014_ITEM
      where TMP_M014_ITEM.M000_Id_Nf = pnSeqNota
      and   vsPDGeraVlrTotLiqItem = 'S'
      order by to_char(TMP_M014_ITEM.M014_NR_ITEM)
                   )
       union all
      select
       pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
         vsNomeArquivo, 10200,
         '10200;CARGA;' ||  M000.m000_nr_carga || ';',
         pnSeqNota, 15
      from TMP_M000_NF M000
      where M000.M000_ID_NF = pnSeqNota
      and   vsPDEnviaNumCargaCanhoto = 'S'
    union all
    select
      pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
      vsNomeArquivo, 10210,
      '10210;QRCODNFE;' || fBuscaMensagemQRCodeNDDigital(pnSeqnota, MENSAGEM, CODMSG) || ';QRCODE',
      pnSeqNota, null
    from  MAX_NFEMSGQRCODE
    where CODMSG = vsPDEnviaQRCodeCanhoto
    and   STATUS = 'A'
    union all
    select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10250,
        '10250;' || vsDriverImp, pnSeqNota, null
     from   dual a
     where  vsDriverImp is not null
     and    nvl(psIndGeraTxtNFe, 'N') != 'N'
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10260,
        '10260;' || vsDriverImp, pnSeqNota, null
     from   dual
     where  vsDriverImp is not null
     and    nvl(psIndGeraTxtNFe, 'N') != 'N'
     union all
     select
        pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
        vsNomeArquivo, 10270,
        '10270;', pnSeqNota, null
     from   MFLV_BASENF NF
     where  NF.indboletonddigital = '1'
     and    NF.seqnotafiscal = pnSeqNota;

     -- 10300
     If vsPdGeraOrdemEmissaoNDD = 'S' OR  vsPdGeraOrdemEmissaoNDD = 'D' then

          if vsPDUtilNovaEstrutControl = 'S' then

            insert into mrlx_pdvimportacao
               (nroempresa, softpdv, dtamovimento, dtahorlancamento,
                arquivo, seqlinha, ordem,
                linha, seqnotafiscal)
             select
                pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
                vsNomeArquivo, 10300, '1',
                '10300;Empresa;' || pnNroEmpresa, pnSeqNota
             from   dual
             where   vnNroCarga > 0
             union all
             select
                pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
                vsNomeArquivo, 10300, '2',
                '10300;Carga;' || vnNroCarga, pnSeqNota
             from   dual
             where   vnNroCarga > 0
             union all
             select
               pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
               vsNomeArquivo, 10300, '3',
               '10300;Sequencia;' || decode(vsPdGeraOrdemEmissaoNDD,'S',pnSeqNota,fGeraOrdemDescEmissaoNDD(vnNroCarga,pnSeqNota)), pnSeqNota
              from   dual
             union all
             select
               pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
               vsNomeArquivo, 10300, '4',
               '10300;Contador;' || vnContador, pnSeqNota
              from   dual ;

          else
             insert into mrlx_pdvimportacao
               (nroempresa, softpdv, dtamovimento, dtahorlancamento,
                arquivo, seqlinha, ordem,
                linha, seqnotafiscal)
             select
                pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
                vsNomeArquivo, 10300, '1',
                '10300;Carga;' || vnNroCarga ||'000'|| pnNroEmpresa, pnSeqNota
             from   dual
             where   vnNroCarga > 0
             union all
             select
               pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
               vsNomeArquivo, 10300, '2',
               '10300;Sequencia;' || decode(vsPdGeraOrdemEmissaoNDD,'S',pnSeqNota,fGeraOrdemDescEmissaoNDD(vnNroCarga,pnSeqNota)), pnSeqNota
              from   dual
             union all
             select
               pnNroEmpresa, psSoftPDV, vdDtaMovimento, sysdate,
               vsNomeArquivo, 10300, '3',
               '10300;Contador;' || vnContador, pnSeqNota
              from   dual ;
          end if;
     end if;

     -- Objeto Customização 21000 (Linha)
     pObjGeraLinha.cnSeqNota := pnSeqNota;
     pObjGeraLinha.cnNroRegistro := 21000;
     SP_GERALINHACUST(pObjGeraLinha);

     If vsPD_GeraArqDirTempCopiaExp = 'S' then
         vsDiretorioAux := vsDiretorioTemp;
     Else
         vsDiretorioAux := vsDiretorioExport;
     end if;

     if psIndGeraTxtNFe = 'N' then

        vslinha := null;

        For vt In (
               SELECT decode(vsPDRetiraAcentoArq,'N',a.linha,fc5limpaacento(a.linha)) linha
               FROM   mrlx_pdvimportacao a
               where  a.arquivo = vsNomeArquivo
               and    a.nroempresa = pnNroEmpresa
               and    a.dtamovimento = vdDtaMovimento
               and    a.seqnotafiscal = pnSeqNota
               order by seqlinha, auxiliar2, auxiliar1, ordem)
        Loop
              if vslinha is null then
               vslinha := vt.linha;
              else
               vslinha := vslinha || CHR(13) || CHR(10) || vt.linha;
              end if;

        end loop;

        DBMS_LOB.CREATETEMPORARY( vsLinhaBLOBIntegra, TRUE );

        DBMS_LOB.CONVERTTOBLOB( vsLinhaBLOBIntegra,
                                vslinha,
                                DBMS_LOB.LOBMAXSIZE,
                                dest_offset,
                                src_offset,
                                DBMS_LOB.DEFAULT_CSID,
                                v_lang,
                                warning );

        IF psSoftPDV = 'OPHOSNFE' then
            if  vnAppOrigem = 7 and vsPDUsuEmitiuPDV != '0' then
                  vsUsuEmitiuNFe := vsPDUsuEmitiuPDV;
            end if;

            vnUsuPainel :=  nvl(fRetornaUsuarioOphos(vsUsuEmitiuNFe, pnNroEmpresa),0) ;
            if vnUsuPainel > 0 then
               vsNomeJobNFe := vnUsuPainel;
            end if;
        end if;

        EXECUTE IMMEDIATE 'Begin sp_NDDigital_TBL_Input(:1,:2,:3,:4); End;'
                 USING IN vsLinhaBLOBIntegra, 'CONSINCO', vsNomeJobNFe, vsChaveAcesso;

        if psSoftPDV = 'OPHOSNFE' then
           vsTextoSoftware := 'PAINEL FISCAL';
        else
           vsTextoSoftware := psSoftPDV;
        end if;
        SP_GRAVALOGDOCELETRONICO('NFE',  pnSeqNota, 'NFe integrada com '|| vsTextoSoftware || ' aguardando retorno.');


     else

           vnStatusFile := 0;

           For vt In (
               SELECT a.linha
               FROM   mrlx_pdvimportacao a
               where  a.arquivo = vsNomeArquivo
               and    a.nroempresa = pnNroEmpresa
               and    a.dtamovimento = vdDtaMovimento
               and    a.seqnotafiscal = pnSeqNota
               order by seqlinha, auxiliar2, auxiliar1, ordem)
           Loop

               If  vnStatusFile = 0 Then
                  vhWndFile := SYS.UTL_FILE.FOPEN(vsDiretorioAux, vsNomeArquivo, 'W');
                  vnStatusFile := 1;
               End If;

               SYS.UTL_FILE.PUT_LINE(vhWndFile, vt.linha);

           End Loop;

           SYS.UTL_FILE.FCLOSE(vhWndFile);

           If  vsPD_GeraArqDirTempCopiaExp = 'S' then
                 SYS.UTL_FILE.fcopy(vsDiretorioAux, vsNomeArquivo, vsDiretorioExport,vsNomeArquivo);
           end if;

     end if;

     delete from TMP_M001_EMITENTE a where  a.m000_id_nf = pnSeqNota;
     delete from TMP_M002_DESTINATARIO a where  a.m000_id_nf = pnSeqNota;
     delete from TMP_M003_FATURA a where  a.m000_id_nf = pnSeqNota;
     delete from TMP_M011_INFO a where  a.m000_id_nf = pnSeqNota;
     delete from tmp_m018_orig_comb a where a.m000_id_nf = pnSeqNota;
     delete from tmp_m018_comb a where a.m000_id_nf = pnSeqNota;
     delete from tmp_m017_med a where exists (select 1 from tmp_m014_item x
                                             where x.m000_id_nf = pnSeqNota
                                             and   x.m014_id_item = a.m014_id_item);
     delete from tmp_m020_adicao a where  exists (select 1 from tmp_m014_item x, tmp_m019_di w
                                             where x.m000_id_nf = pnSeqNota
                                             and   x.m014_id_item = w.m014_id_item
                                             and   w.m019_id_di   = a.m019_id_di);
     delete from tmp_m019_di a where exists (select 1 from tmp_m014_item x
                                             where x.m000_id_nf = pnSeqNota
                                             and   x.m014_id_item = a.m014_id_item);
     delete from TMP_M014_ITEM a where  a.m000_id_nf = pnSeqNota;
     delete from TMP_M004_DUPLICATA a where  a.m000_id_nf = pnSeqNota;
     delete from TMP_M013_CHAVE_REF a where  a.m000_id_nf = pnSeqNota;
     delete from TMP_M008_VOLUME a where  a.m000_id_nf = pnSeqNota;
     delete from TMP_M006_TRANSPORTE a where  a.m000_id_nf = pnSeqNota;
     delete from TMP_M005_LOCAL a where  a.m000_id_nf = pnSeqNota;
     delete from TMP_M005_DETPAGTO a where a.m000_id_nf = pnSeqNota;
     delete from TMP_M000_NF a where  a.m000_id_nf = pnSeqNota;

end Sp_GeraArqEnvioNDDigitalNFe2g;
