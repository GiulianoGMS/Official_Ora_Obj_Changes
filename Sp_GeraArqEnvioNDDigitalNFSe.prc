create or replace procedure Sp_GeraArqEnvioNDDigitalNFSe(
       pnSeqNota        in        mfl_doctofiscal.seqnotafiscal%type,
       pnNroEmpresa     in        max_empresa.nroempresa%type,
       psSoftPDV        in        mrl_empsoftpdv.softpdv%type)
is
      vsNomeArquivo        varchar2(100);
      vdDtaHoraEmissao mlf_notafiscal.dtahorlancto%type;
      vsCodNatureza max_codgeraloper.codnaturezanfse%type;
      vsNroRegimeTribNFSe max_codgeraloper.nroregimeesptribnfse%type;
      vsIndTribMun varchar2(1);
      vsIndTribPrest varchar2(1);
      vnNroNota      mlf_notafiscal.numeronf%type;
      vsSerieNFSe max_codgeraloper.serienfse%type;
      vnSeqCidade ge_cidade.seqcidade%type;
      vnCodIBGE ge_cidade.codibge%type;
      vsObs mlf_notafiscal.observacao%type;
      vnPercCofins max_empresa.percofins%type;
      vnPercPis max_empresa.perpis%type;
      vnPercIR max_empresa.perir%type;
      vnPercISS  max_empresa.perciss%type;
      vnPercCSLL max_empresa.percsll%type;
      vnPercINSS max_empresa.perinss%type;
      vsCNPJ varchar2(14);
      vsInscMun ge_pessoa.inscricaorg%type;
      vnSeqFamilia map_familia.seqfamilia%type;
      vnRegimeTribut number;
      vnTipoRec      max_codgeraloper.tiporecolhimentonfse%type;
      vsMotivoRec    max_codgeraloper.motivoretencaonfse%type;
      vnCodCNAE      rf_parametro.codativmunicipio%type;
      vnPDJobIntegraNFSE         number;
      vslinha                    CLOB;
      vsLinhaBLOBIntegra         BLOB;
      dest_offset                INTEGER := 1;
      src_offset                 INTEGER := 1;
      warning                    INTEGER := 0;
      v_lang                     INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
      vnSeqPessoaTomadorNFSe     max_empresa.seqpessoatomadornfse%type;
      vnSeqPessoaDestinatarioNFSe mlf_notafiscal.seqpessoadestinatarionfse%type;
      vsPDBaseCalcVlrISS         max_parametro.valor%type;
      vnFoneDDDPrest             ge_pessoa.foneddd1%type;
      vnFonePrest                ge_pessoa.fonenro1%type;
      vsRazaoSocialPrest         ge_pessoa.nomerazao%type;
      vsFantasiaPrest            ge_pessoa.fantasia%type;
      vsEmailPrest               ge_pessoa.email%type;
      vnCodSiaf                  ge_cidade.codsiafi%type;
      vnQtdDigInscrMun           max_parametro.valor%type;
      vsPDGeraMesNF_OutrasInfo   max_parametro.valor%type;
      vsPDGeraLocal_OutrasInfo   max_parametro.valor%type;
      vsPDGeraReco_OutrasInfo    max_parametro.valor%type;
      vsPDGeraTrib_OutrasInfo    max_parametro.valor%type;
      vsPDGeraRPS_OutrasInfo     max_parametro.valor%type;
      vsPDGeraCNAE_OutrasInfo    max_parametro.valor%type;
      vsPDGeraAtiv_OutrasInfo    max_parametro.valor%type;
      vsCidadePessoaNF           ge_cidade.cidade%type;
      vsUFPessoaNF               ge_pessoa.uf%type; 
      vsDescAtividadeNFSE        mlf_notafiscal.descatividadenfse%type;     
      vnSeqPessoaIntermediarioNFSe  mlf_notafiscal.seqpessoaintermediarionfse%type;
      vsLogradouroPrest       ge_pessoa.logradouro%type;
      vnNroLogradouroPrest    ge_pessoa.nrologradouro%type;
      vsCmpltoLogradouroPrest ge_pessoa.cmpltologradouro%type;
      vsBairroPrest           ge_pessoa.bairro%type;
      vsUfPrest               ge_pessoa.uf%type;
      vsCepPrest              ge_pessoa.cep%type;
      vnCodPaisPrest          ge_cidade.codpais%type;
      vsCodObraNFSe           mlf_notafiscal.codobranfse%type;
      vsCodArtObraNFSe        mlf_notafiscal.codartobranfse%type; 
      vsEmailDestNFSe         mlf_notafiscal.emaildestnfse%type; 
      vsEmailCopiaNFSe        mlf_notafiscal.emailcopianfse%type; 
      vsAssuntoEmailNFSe      mlf_notafiscal.assuntoemailnfse%type; 
      vsCorpoEmailNFSe        mlf_notafiscal.corpoemailnfse%type;
      vsChaveAcesso           mlf_notafiscal.nfechaveacesso%type;
      vsExibeISSRetido        varchar2(1);
      vsPDCodIbgeMunIncid     max_parametro.valor%type;
      vnCodIBGEEmp            ge_cidade.codibge%type;
      vsPDConcatObsNFDiscrim  max_parametro.valor%type;
      vsPDUtilizaPisCofinsRet max_parametro.valor%type;
      vnSeqCidadeCorreio      ge_cidade.seqcidadecorreios%type;
      vsPDRetiraAcentoArq     max_parametro.valor%type;
      vsNomeJobNFePonto       max_emppontoimpr.nomejobnfe%type;
      vsPDControlPontoImp     max_parametro.valor%type;     
      vnPerCSLLProdEmp        mlf_nfitem.percsll%type;
      vnPerINSSProdEmp        mlf_nfitem.perINSS%type;
      vnPerIRRFProdEmp        mlf_nfitem.perirrf%type;
      vnPercPisProdEmp        mrl_produtoempresa.peraliqpisret%type;
      vnPercCofinsProdEmp     mrl_produtoempresa.peraliqcofinsret%type;    
      vsIndRetPis             mlf_nfitem.indretpis%type;
      vsIndRetCofins          mlf_nfitem.indretcofins%type;   
      vsPDExibeVenctoObsNFSe  max_parametro.valor%type;
      vnNroDiaVenctoISS       max_empresa.nrodiavenctoiss%type;
      vsDtaVenctoTitISS       varchar2(15);
      vsObsNFSE               mlf_notafiscal.observacao%type;
      vnVlrTotISS             mlf_nfitem.vlrtotiss%type;
      vnVlrTotISSRet          mlf_nfitem.vlrissretido%type;
      vsPDFonteCargaTributaria max_parametro.valor%type;
      vnTipoRecNFSe           ge_pessoa.tiporecolhimentonfse%type;
      vsMotivoRecNFSe         ge_pessoa.motivoretencaonfse%type;
      vsPDExibeCodPaisTomador MAX_PARAMETRO.VALOR%TYPE;
      vsPD_EnviaCidadeTomador max_parametro.valor%type;
      vsCidadeTomador         ge_cidade.cidade%type;
      vsPDCodPaisPrestador    max_parametro.valor%type;
      vsPD_EnviaTipoDocumento max_parametro.valor%type;
      vsPdIrRetidoProdutoServico max_parametro.valor%type;
      pObjGeraArqNDDNFSe         tp_GeraArqNDDNFSe := tp_GeraArqNDDNFSe(NULL, NULL, NULL, NULL);
      vdDtaHoraCompetenciaCust mlf_notafiscal.dtahorlancto%type;
      vsPDExigeItemDiscrimServ max_parametro.valor%type;
      vnNfItemServ             integer;
      vsStatusNT004           MAX_EMPRESANOTATECNICA.STATUS%TYPE;
      vnPerDiferimentoIbsMun  mlf_nfitem.perdiferimentoibsmun%type;
      vnPerDiferimentoIbsUf   mlf_nfitem.perdiferimentoibsuf%type;
      vnPerDiferimentoCbs     mlf_nfitem.perdiferimentocbs%type;
      vnCodigoOperacaoFornecimento mrl_produtoempresa.codindopernfse%type;
      vsIndConsideraImposto          CCT_PAINELCONFIGURACAO.INDCONSIDERAIMPOSTO%TYPE;
      
      -- Constantes
      csFormatoNumber3_2   VARCHAR2(8) := 'FM990D00';
      csFormatoNumber2_2   VARCHAR2(8) := 'FM90D00';
      csFormatoNumber13_2  VARCHAR2(18) := 'FM9999999999990D00'; 
      csCodLayoutNFSE VARCHAR2(4) := '5.13'; 
      csNT4Versao VARCHAR2(3) := '1.4'; 
      csFormatNlsNumeric VARCHAR2(40) := 'NLS_NUMERIC_CHARACTERS = '',.''';

      
begin
     sp_buscaparamdinamico('EMISSAO_NF',pnNroEmpresa,'JOBKEY_INTEGRACAO_NFSE','N','0',
     'NÚMERO DO JOBKEY PARA A INTEGRAÇÃO DA NFSE COM A NDDIGITAL', vnPDJobIntegraNFSE);
     
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'BASE_CALC_VLR_ISS', 'S', 'B',
     'BASE PARA CALCULO DO ISS. B - VLR BRUTO(PADRAO) L - VLR LIQUIDO ', vsPDBaseCalcVlrISS);
     
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'QTD_DIG_INSCR_MUN_TOM', 'N', '15',
     'QTDE DIGITOS INSCR. MUNICIPAL TOMADOR. PADRAO 15', vnQtdDigInscrMun);
     
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'GERA_MES_NF_OUTRAS_INFO', 'S', 'N',
     'GERA MÊS E ANO DE COMPETÊNCIA DA NOTA FISCAL NO CAMPO OUTRAS INFORMAÇÕES? (LINHA 9000)' || CHR(13) || CHR(10)  ||
     'S-SIM' || CHR(13) || CHR(10)  ||
     'N-NÃO(PADRÃO)'     
     , vsPDGeraMesNF_OutrasInfo);  
       
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'GERA_LOCAL_OUTRAS_INFO', 'S', 'N',
     'GERA LOCAL DA PRESTAÇÃO DO SERVIÇO DA NOTA FISCAL NO CAMPO OUTRAS INFORMAÇÕES? (LINHA 9000)' || CHR(13) || CHR(10)  ||
     'S-SIM' || CHR(13) || CHR(10)  ||
     'N-NÃO(PADRÃO)'     
     , vsPDGeraLocal_OutrasInfo);       

     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'GERA_RECO_OUTRAS_INFO', 'S', 'N',
     'GERA RECOLHIMENTO DA NOTA FISCAL NO CAMPO OUTRAS INFORMAÇÕES? (LINHA 9000)' || CHR(13) || CHR(10)  ||
     'S-SIM' || CHR(13) || CHR(10)  ||
     'N-NÃO(PADRÃO)'     
     , vsPDGeraReco_OutrasInfo);  
     
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'GERA_TRIB_OUTRAS_INFO', 'S', 'N',
     'GERA TRIBUTAÇÃO DA NOTA FISCAL NO CAMPO OUTRAS INFORMAÇÕES? (LINHA 9000)' || CHR(13) || CHR(10)  ||
     'S-SIM' || CHR(13) || CHR(10)  ||
     'N-NÃO(PADRÃO)'     
     , vsPDGeraTrib_OutrasInfo); 
     
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'GERA_RPS_OUTRAS_INFO', 'S', 'N',
     'GERA RPS DA NOTA FISCAL NO CAMPO OUTRAS INFORMAÇÕES? (LINHA 9000)' || CHR(13) || CHR(10)  ||
     'S-SIM' || CHR(13) || CHR(10)  ||
     'N-NÃO(PADRÃO)'     
     , vsPDGeraRPS_OutrasInfo); 
     
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'GERA_CNAE_OUTRAS_INFO', 'S', 'N',
     'GERA CNAE DA NOTA FISCAL NO CAMPO OUTRAS INFORMAÇÕES? (LINHA 9000)' || CHR(13) || CHR(10)  ||
     'S-SIM' || CHR(13) || CHR(10)  ||
     'N-NÃO(PADRÃO)'     
     , vsPDGeraCNAE_OutrasInfo); 
     
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'GERA_ATIVIDADE_OUTRAS_INFO', 'S', 'N',
     'GERA DESCRIÇÃO DA ATIVIDADE DA NOTA FISCAL NO CAMPO OUTRAS INFORMAÇÕES? (LINHA 9000)' || CHR(13) || CHR(10)  ||
     'S-SIM' || CHR(13) || CHR(10)  ||
     'N-NÃO(PADRÃO)'     
     , vsPDGeraAtiv_OutrasInfo); 
     
     sp_checaparamdinamico('NF_SERVICO', pnNroEmpresa, 'GERA_MUN_TOM_OUTRAS_INFO', 'S', 'N',
     'GERA DESCRIÇÃO DO MUNICIPIO DO TOMADOR NO CAMPO OUTRAS INFORMAÇÕES? (LINHA 9000)' || CHR(13) || CHR(10)  ||
     'S-SIM' || CHR(13) || CHR(10)  ||
     'N-NÃO(PADRÃO)');     
     
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'COD_IBGE_MUNICIPIO_INCIDENCIA', 'S', 'C',
     'CODIGO IBGE DO MUNICIPIO DE INCIDENCIA  (LINHA 2300)' || CHR(13) || CHR(10)  ||
     'C-CLIENTE(PADRAO)' || CHR(13) || CHR(10)  ||
     'E-EMPRESA'     
     , vsPDCodIbgeMunIncid);
     
     sp_buscaparamdinamico('NF_SERVICO', pnNroEmpresa, 'CONCAT_OBS_NF_DISCRIM', 'S', 'N',
     'EMITE OBSERVAÇÃO DA NOTA NA DISCRIMINAÇÃO DO SERVIÇO  (LINHA 2300)' || CHR(13) || CHR(10)  ||
     'S-SIM' || CHR(13) || CHR(10)  ||
     'N-NÃO(PADRÃO)'     
     , vsPDConcatObsNFDiscrim);          
     
     sp_buscaparamdinamico('NF_SERVICO', 0, 'UTILIZA_PISCOFINSRET', 'S', 'N',
     'UTILIZA RECURSO DE RETENÇÃO DE PIS/COFINS?' || CHR(13) || CHR(10) ||
     'S-SIM' || CHR(13) || CHR(10) ||
     'N-NÃO(PADRÃO)',
     vsPDUtilizaPisCofinsRet);
                 
     SP_BUSCAPARAMDINAMICO('NF_SERVICO', 0,'RETIRA_ACENTO_ARQUIVO','S','S',
        'RETIRA A ACENTUAÇÃO DAS LINHAS NO ARQUIVO DE ENVIO'|| chr(13) || chr(10) ||
        'S-SIM (PADRÃO)' ||chr(13) || chr(10) ||
        'N-NÃO', vsPDRetiraAcentoArq); 
                
        SP_BUSCAPARAMDINAMICO('EMISSAO_NF', 0,'CONTROLA_PONTO_IMPRESSAO','S','S',
        'CONTROLA PONTO DE IMPRESSO PARA QUE AS INFORMAES SEJAM GERADAS NOS ARQUIVOS DA NDDIGITAL?'||chr(13) || chr(10) ||
        'S - SIM'          ||chr(13) || chr(10) ||
        'N - NÃO (DEFAULT)'||chr(13) || chr(10) ||
        'OBS.: O PONTO DE IMPRESSO  SOMENTE PARA CONTROLE DOS REGISTRO DA NFE E NO PARA ALTERAO DA IMPRESSORA PADRO DO WINDOWS.'
        , vsPDControlPontoImp);
             
     SP_BUSCAPARAMDINAMICO('NF_SERVICO', pnNroEmpresa, 'EXIBE_VENCTO_OBS_NFSE', 'S', 'N',
     'INDICA QUAIS CAMPOS SERÃO EXIBIDOS JUNTAMENTE COM A DATA DE VENCIMENTO, NOS DADOS ADICIONAIS DA DANFE PARA NFSE:' || CHR(13) || CHR(10) ||
     'S-SOMENTE ISS' || CHR(13) || CHR(10) ||
     'R-SOMENTE ISS RETIDO' || CHR(13) || CHR(10) ||
     'A-AMBOS, ISS E ISS RETIDO' || CHR(13) || CHR(10) ||
     'N-NÃO EXIBE(PADRÃO)',vsPDExibeVenctoObsNFSe); 
   
     SP_BUSCAPARAMDINAMICO( 'NF_SERVICO', pnNroEmpresa, 'FONTE_CARGA_TRIBUTARIA', 'S', '1',
     'IDENTIFICADOR DA ORIGEM DO IMPOSTO APLICADO AO VALOR DA NOTA FISCAL DE SERVIÇO.' ,
     vsPDFonteCargaTributaria );
     
     SP_BUSCAPARAMDINAMICO('NF_SERVICO', pnNroEmpresa, 'EXIBE_COD_PAIS_TOMADOR', 'S', 'S',
                           'EXIBE O CÓDIGO DO PAÍS DO TOMADOR DA NOTA FISCAL DE SERVIÇO? (LINHA 2540)' || CHR(13) || CHR(10) ||
                           'S-SIM(PADRÃO)' || CHR(13) || CHR(10) ||
                           'N-NÃO', vsPDExibeCodPaisTomador);
     
     vsPD_EnviaCidadeTomador := 'N';
     SP_BUSCAPARAMDINAMICO('NF_SERVICO', pnNroEmpresa,
     'ENVIA_CIDADE_TOMADOR', 'S', 'N',
     'INFORMA A CIDADE DO TOMADOR NO CAMPO LOCAL DE PRESTAÇÂO TAG <MunicipioPrestacaoDescricao>' || CHR(13) || CHR(10) || 
     'S-ENVIA CIDADE TOMADOR' || CHR(13) || CHR(10) ||
     'N-ENVIA CIDADE TRANSPORTADORA(PADRÃO)', vsPD_EnviaCidadeTomador);                                                          
     
      vsPDCodPaisPrestador := '01058';
      SP_BUSCAPARAMDINAMICO('NF_SERVICO', pnNroEmpresa, 'COD_PAIS_PRESTADOR', 'S', '01058',
                 'DEFINE O CÓDIGO DO PAÍS DO PRESTADOR DA NOTA FISCAL DE SERVIÇO (LINHA 2420)' || CHR(13) || CHR(10) ||
                 '01058 - (PADRÃO)', vsPDCodPaisPrestador);
       
     vsPD_EnviaTipoDocumento := 'N';
     SP_BUSCAPARAMDINAMICO('NF_SERVICO', pnNroEmpresa,
                           'ENVIA_TIPO_DOCUMENTO', 'S', 'N',
                           'DEFINE A IDENTIFICAÇÃO DO TIPO DO DOCUMENTO DO TOMADOR DE SERVIÇO TAG <TipoDocumento>' || CHR(13) || CHR(10) || 
                           'S - ENVIA TIPO_DOCUMENTO COM O VALOR 1' || CHR(13) || CHR(10) ||
                           'N - NÃO ENVIA TIPO_DOCUMENTO(PADRÃO)', vsPD_EnviaTipoDocumento);
     
     vsPdIrRetidoProdutoServico := 'N';
     SP_BUSCAPARAMDINAMICO('NF_SERVICO', pnNroEmpresa, 'IRRETIDO_PRODUTO_SERVICO', 'S', 'N',
                           'DEFINE SE O VALOR DE IR RETIDO SERÁ DESCONSIDERADO DO CALCULO DE VALOR LIQUIDO DO PRODUTO/SERVIÇO POR ITEM (LINHA 2340)' || CHR(13) || CHR(10) ||
                           'N - Não desconsidera (Padrão)'|| CHR(13) || CHR(10) ||
                           'S - Desconsidera o valor de IR.', vsPdIrRetidoProdutoServico);
     
     vsPDExigeItemDiscrimServ := 'N'; 
     SP_BUSCAPARAMDINAMICO( 'NF_SERVICO', pnNroEmpresa, 'EXIGE_ITEMDISCRIM_SERVICO', 'S', 'N',
                            'OBRIGA O USUÁRIO ASSOCIAR ITEM DE DISCRIMINAÇÃO DO SERVIÇO?' || CHR(13) || CHR(10) ||
                            'S-SIM' || CHR(13) || CHR(10) ||
                            'N-NÃO(PADRÃO)',vsPDExigeItemDiscrimServ);
                            
     vsIndConsideraImposto := PKG_CCTMOTOR.CCTF_BUSCACONFIGPAINEL(pnNroEmpresa);                                                
                                                                                                            
          
     select A.DTAHORLANCTO, 
            B.CODNATUREZANFSE ,
            B.NROREGIMEESPTRIBNFSE,
            Decode(NVL(B.INDTRIBMUNICIPIONFSE,'N'), 'S', '1', '2'),
            Decode(NVL(B.INDTRIBPRESTADORNFSE,'N'), 'S', '1', '2'),
            B.SERIENFSE, A.Numeronf, C.SEQCIDADE, D.CODIBGE, replace(replace(A.observacao, chr(13), ' '), chr(10), ''),
            nvl(E.Percofins,0), nvl(e.perpis,0), nvl(e.perir,0), nvl(e.perciss,0), nvl(e.percsll,0), 
            nvl(e.perinss,0), lpad(to_char(e.nrocgc),12,0)||lpad(to_char(e.digcgc),2,'0'), f.inscrmunicipal, b.tiporecolhimentonfse,
            b.motivoretencaonfse, A.SEQPESSOATOMADORNFSE,
            c.foneddd1, c.fonenro1, c.nomerazao, c.fantasia, c.email, d.codsiafi,
            D.CIDADE, C.UF, REPLACE(A.DESCATIVIDADENFSE,CHR(13)||CHR(10),' '), 
            a.seqpessoaintermediarionfse, c.logradouro, c.nrologradouro, replace(c.cmpltologradouro, ';', ''), c.bairro,
            c.uf, c.cep, d.codpais, a.codobranfse, a.codartobranfse,
            -- Alt Giuliano 30/01/25 ---
            COALESCE(a.emaildestnfse, j.EMAILNFE, C.EMAILNFE, 'nfe1@ .com.br') emaildestnfse, 
            'nfe1@ .com.br' emailcopianfse, 
            'Nota Fiscal de Serviço Eletrônica – NFSe n '||a.NUMERONF assuntoemailnfse, 
            'Prezados(as), Segue em anexo a Nota Fiscal de Serviço Eletrônica (NFSe) referente aos serviços prestados. Este é um e-mail automático. Favor não responder.' corpoemailnfse,
            ----------------------------
            a.nfechaveacesso, H.CODIBGE CODIBGEEMP, D.SEQCIDADECORREIOS,
            nvl(a.jobnfeenvio, nvl(a.jobnfeuser, nvl(a.jobnfeseg, i.nomejobnfe))),
            e.nrodiavenctoiss, j.tiporecolhimentonfse, j.motivoretencaonfse,
            a.seqpessoadestinatarionfse
     into   vdDtaHoraEmissao, 
            vsCodNatureza, 
            vsNroRegimeTribNFSe,  
            vsIndTribMun, 
            vsIndTribPrest,
            vsSerieNFSe, vnNroNota,  vnSeqCidade, vnCodIBGE, vsObs,
            vnPercCofins, vnPercPis, vnPercIR, vnPercISS, vnPercCSLL, 
            vnPercINSS, vsCNPJ, vsInscMun, vnTipoRec, vsMotivoRec, vnSeqPessoaTomadorNFSe,
            vnFoneDDDPrest, vnFonePrest, vsRazaoSocialPrest, vsFantasiaPrest, vsEmailPrest ,vnCodSiaf,
            vsCidadePessoaNF, vsUFPessoaNF, vsDescAtividadeNFSE,
            vnSeqPessoaIntermediarioNFSe, vsLogradouroPrest, vnNroLogradouroPrest, vsCmpltoLogradouroPrest, vsBairroPrest,
            vsUfPrest, vsCepPrest, vnCodPaisPrest, vsCodObraNFSe, vsCodArtObraNFSe,
            vsEmailDestNFSe, vsEmailCopiaNFSe, vsAssuntoEmailNFSe, vsCorpoEmailNFSe ,
            vsChaveAcesso, vnCodIBGEEmp, vnSeqCidadeCorreio, vsNomeJobNFePonto,
            vnNroDiaVenctoISS, vnTipoRecNFSe, vsMotivoRecNFSe, vnSeqPessoaDestinatarioNFSe
     from   MLF_NOTAFISCAL A, MAX_CODGERALOPER B, GE_PESSOA C, GE_CIDADE D, MAX_EMPRESA E, GE_EMPRESA F, GE_PESSOA G, GE_CIDADE H, MAX_EMPPONTOIMPR I, GE_PESSOA J
     where A.CODGERALOPER = B.CODGERALOPER
     AND   A.seqnotafiscal = pnSeqNota
     AND   A.seqpessoa = C.SEQPESSOA
     AND   C.SEQCIDADE = D.SEQCIDADE
     AND   A.nroempresa = E.Nroempresa
     AND   E.NROEMPRESA = F.NROEMPRESA
     AND   G.SEQPESSOA  = E.SEQPESSOAEMP
     AND   H.SEQCIDADE  = G.SEQCIDADE
     AND   I.NROEMPRESA(+) = A.NROEMPRESA
     AND   I.DESCRICAO(+)  = A.PONTOIMPRESSAOSEL
     AND   J.SEQPESSOA(+)  = A.SEQPESSOATOMADORNFSE
     AND   I.Tipojob(+)    = 'NFSE';

    vsStatusNT004 := NVL(fc5_BuscaStatusNotaTecnica(4, pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, NVL(vdDtaHoraEmissao,SYSDATE),NULL,'NFSE'), 'I');   
     
     BEGIN
       IF vsPDExigeItemDiscrimServ = 'S' THEN
         SELECT COUNT(1)
         into vnNfItemServ
         FROM MLF_NFITEM A, MAP_PRODUTO B, MLF_NOTAFISCAL C, MRL_PRODUTOEMPRESA D,
              MAX_EMPRESA E, MLF_NFITEMSERV F, MRL_PRODEMPSERVICO G
         WHERE A.SEQPRODUTO = B.SEQPRODUTO
               AND A.SEQNF = C.SEQNF
               AND A.SEQPRODUTO = D.SEQPRODUTO
               AND A.NROEMPRESA = D.NROEMPRESA
               AND C.NROEMPRESA = E.NROEMPRESA
               AND F.NUMERONF = A.NUMERONF
               AND F.SEQPESSOA = A.SEQPESSOA
               AND F.SERIENF = A.SERIENF
               AND F.TIPNOTAFISCAL = A.TIPNOTAFISCAL
               AND F.NROEMPRESA = A.NROEMPRESA
               AND F.SEQPRODUTO = A.SEQPRODUTO
               AND G.SEQPRODUTO = F.SEQPRODUTO
               AND G.NROEMPRESA = F.NROEMPRESA
               AND G.SEQSERVICO = F.SEQSERVICO
               AND C.SEQNOTAFISCAL = pnSeqNota;
       END IF;
     EXCEPTION
       WHEN OTHERS THEN
         vnNfItemServ := 0;            
     END;
     
     If vsNomeJobNFePonto is not null and isnumeric(vsNomeJobNFePonto) = 'S' then
        vnPDJobIntegraNFSE := vsNomeJobNFePonto;
     end if;              
          
     select MAX(C.SEQFAMILIA), max(b.peraliquotapis), max(b.peraliquotacofins),
     (case when max(d.peraliqissretido) is not null then 'S' else 'N' end),
     max(b.perinss), max(b.percsll), max(b.perirrf), max(b.peraliqpisret), max(b.peraliqcofinsret),
     max(b.indretpis), max(b.indretcofins), nvl(sum(b.vlrtotiss),0), nvl(sum(b.vlrissretido),0), 
     max(b.perdiferimentoibsmun), max(b.perdiferimentoibsuf), max(b.perdiferimentocbs), max(d.codindopernfse) 
     into vnSeqFamilia, vnPercPis, vnPercCofins, vsExibeISSRetido,
          vnPerINSSProdEmp, vnPerCSLLProdEmp, vnPerIRRFProdEmp, vnPercPisProdEmp, vnPercCofinsProdEmp,
          vsIndRetPis, vsIndRetCofins, vnVlrTotISS, vnVlrTotISSRet,
          vnPerDiferimentoIbsMun, vnPerDiferimentoIbsUf, vnPerDiferimentoCbs, vnCodigoOperacaoFornecimento
     from MLF_NOTAFISCAL A, MLF_NFITEM B, MAP_PRODUTO C, MRL_PRODUTOEMPRESA D
     where B.Numeronf = A.NUMERONF
     and b.serienf = a.serienf
     and a.nroempresa = b.nroempresa
     and a.seqnotafiscal = pnSeqNota
     and b.seqproduto = c.seqproduto
     and d.seqproduto = b.seqproduto
     and d.nroempresa = a.nroempresa;
          
     If vsPDExibeVenctoObsNFSe != 'N' and vnNroDiaVenctoISS > 0 then
        select to_char(vnNroDiaVenctoISS||'/'||to_char(add_months(sysdate,+1),'mm/yyyy'))
        into   vsDtaVenctoTitISS       
        from   dual ; 
        
        if vsDtaVenctoTitISS is not null then
      
          vsObsNFSE := ' Data Vencto ISS: ' || vsDtaVenctoTitISS ;
          If vsPDExibeVenctoObsNFSe = 'S'  then
            vsObsNFSE := vsObsNFSE || '. Valor ISS: '|| vnVlrTotISS ;
          ElsIf vsPDExibeVenctoObsNFSe = 'R' then
            vsObsNFSE := vsObsNFSE || '. Valor ISS Retido: '|| vnVlrTotISSRet ;
          ElsIf vsPDExibeVenctoObsNFSe = 'A' then
            vsObsNFSE := vsObsNFSE || '. Valor ISS: '|| vnVlrTotISS || '. Valor ISS Retido: '|| vnVlrTotISSRet ;
          End if;
             
          update mlf_nfitem a
          set    a.observacao = a.observacao || substr(FC5LIMPAACENTO(vsObsNFSE),1,2000)         
          where  exists ( select 1
                          from   mlf_notafiscal b
                          where  b.numeronf      = a.numeronf
                          and    b.serienf       = a.serienf
                          and    b.tipnotafiscal = a.tipnotafiscal
                          and    b.seqpessoa     = a.seqpessoa
                          and    b.nroempresa    = a.nroempresa
                          and    b.seqnotafiscal = pnSeqNota );                    
        end if;
     end if; 
      
     vsNomeArquivo := 'ASS' || '-' || lpad(pnNroEmpresa, 6, 0)  || '-' || 'IMPR'
                       || '-' || to_char(vdDtaHoraEmissao, 'yyyymmddhh24miss')  || pnSeqNota || '-' || 'env.txt';

     begin

      select (case
                   when RFF_BuscaRegimeTribut(pnNroEmpresa, to_number(to_char(sysdate, 'MM')), to_number(to_char(sysdate, 'YYYY'))) = 5 then 1
                   else 2
                 end), a.codativmunicipio
        into   vnRegimeTribut, vnCodCNAE
        from   RF_PARAMETRO A
        where  A.NROEMPRESA = pnNroEmpresa;
      exception
        when no_data_found then
          vnRegimeTribut := 2;
     end;
     
     if c5_strtonumber(vsCodNatureza)  > 0 then 
        vsCodNatureza := c5_strtonumber(vsCodNatureza);
     end if;
     
     if c5_strtonumber(vsNroRegimeTribNFSe)  > 0 then 
        vsNroRegimeTribNFSe := c5_strtonumber(vsNroRegimeTribNFSe);
     end if;
         
     IF vsPD_EnviaCidadeTomador = 'S' AND vnseqpessoatomadornfse IS NOT NULL THEN
       BEGIN   
        SELECT C.CIDADE
        INTO vsCidadeTomador
        FROM GE_PESSOA B, GE_CIDADE C
        WHERE B.SEQCIDADE = C.SEQCIDADE
        AND B.SEQPESSOA = vnseqpessoatomadornfse;
       EXCEPTION
        WHEN no_data_found THEN
        vsCidadeTomador := NULL;
       END;  
     END IF;
     
     -- Objeto Customização: Linha 2000 e 9000
     pObjGeraArqNDDNFSe.cnSeqNota := pnSeqNota;
     pObjGeraArqNDDNFSe.cnNroEmpresa := pnNroEmpresa;
     pObjGeraArqNDDNFSe.csSoftPDV := psSoftPDV;
     SP_GeraArqNDDNFSeCust(pObjGeraArqNDDNFSe);
     vdDtaHoraCompetenciaCust := pObjGeraArqNDDNFSe.cdDtaHoraCompetencia;
     
     -- 2000 - Identificação Fiscal do RPS           
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        linha, arquivo, seqnotafiscal)
     values (
        pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
        '2000;' ||'RPS'|| 
        pnSeqNota || ';' || -- id
        '5.13;' || -- Versao
        to_char(nvl(vdDtaHoraCompetenciaCust, vdDtaHoraEmissao), 'dd-mm-yyyy hh24:mi:ss') || ';' || -- Competencia
        to_char(vdDtaHoraEmissao, 'dd-mm-yyyy hh24:mi:ss') || ';' || -- DataEmissao
        vsCodNatureza || ';' || -- NaturezaOperacao
        vsNroRegimeTribNFSe  || ';' || -- RegimeEspecialTributacao
        vnRegimeTribut || ';' || -- OptanteSimplesNacional
        '2'  || ';' || -- IncentivoFiscal
        '1'  || ';' || -- Status
        vsIndTribMun || ';' || -- TributarMunicipio
        vsIndTribPrest || -- TributarPrestador
        ';' || -- CodigoVerificacao
        ';' || -- TipoAmbiente
        ';' || -- RegimeApuracaoTributos
        ';' || -- TipoLancamento
        ';' || -- TipoTributacao
        -- Reforma
        fc5_buscacamponotatecnica( 0 , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 1, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- FinalidadeNFSe
        fc5_buscacamponotatecnica( 0 , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 2, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- OperacaoUsoConsumoPessoal
        fc5_buscacamponotatecnica( vnCodigoOperacaoFornecimento , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 3, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- CodigoOperacaoFornecimento
        fc5_buscacamponotatecnica( NULL , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 4, SYSDATE, 'N', NULL, NULL, 'NFSE') -- TipoEnteGovernamenta
        ,   
        vsNomeArquivo, pnSeqNota);              
     
     -- 2100 - Identificação do RPS
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        linha, arquivo, seqnotafiscal)
     values (
        pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
        '2100;' ||
        vnNroNota || ';' ||
        vsSerieNFSe || ';' ||
        '1;', 
         vsNomeArquivo, pnSeqNota);
     
     -- 2300 - Identificação do Serviço Prestado             
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '2300' ||
            ';' || b.itemlistaservnfse || -- ItemListaServico
            ';' || Nvl(b.codcnaenfse, vnCodCNAE) || -- CodigoCnae
            ';' || b.codservicomunicipionfse || -- CodigoTributacaoMunicipio
            ';' || decode( vsPDConcatObsNFDiscrim, 'S',  substr(FC5LIMPAACENTO(b.discriminacaonfse || ' - ' || vsObs),1,2000),
                                            'N',  substr(FC5LIMPAACENTO(b.discriminacaonfse),1,2000))|| -- Discriminacao
            ';' || decode(vsPDCodIbgeMunIncid,'E', vnCodIBGEEmp, vnCodIBGE) || -- MunicipioIncidencia
            ';' || vnCodSiaf || --  MunicipioIncidenciaSiafi 
            ';' || -- NumeroProcesso
            ';' || decode( vsPDConcatObsNFDiscrim, 'S', substr(FC5LIMPAACENTO(b.discriminacaonfse || ' - ' || vsObs),1,1500),
                                            'N', substr(FC5LIMPAACENTO(b.discriminacaonfse),1,1500))|| -- DescricaoRPS
            ';' || (case when b.peraliqissretido is not null then 1 else 2 end) || -- ISSRetido
            ';' || b.respretencaoiss || -- ResponsavelRetencao
            ';' || vnSeqCidadeCorreio || -- MunicipioIncidenciaOutros 
            ';' || -- ServicoPrestadoViasPublicas
            ';' || decode(c.indimportexport,'S',1,2) || -- ServicoExportacao
            ';' || a.observacao || -- Observacao
            ';' || substr( trim( vsPDFonteCargaTributaria ), 1 , 10 ) || -- FonteCargaTributaria
            ';' || '2' ||-- EmpreitadaGlobal
            ';' || b.codnbs  || -- CodigoNbs
            ';' || -- CodigoFiscalPrestacaoServico
            ';' || -- IdentifNaoExigibilidade
            ';' || -- CodigoInternoContribuinte
            ';' || -- CodigoSituacaoTributaria
            ';' || -- DocumentoReferencia
            ';' || -- ExigibilidadeSuspensa
            ';' || -- IdDocumentoTecnico
            ';' || -- TipoImunidade
            ';' || -- TributacaoISSQN
            -- Reforma
            fc5_buscacamponotatecnica( LPAD(NVL(A.CCLASSTRIBCBS, A.CCLASSTRIBIBSUF),6,0) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 6, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- CodigoClassificacaoTributariaIBSCBS
            fc5_buscacamponotatecnica( LPAD(NVL(A.CSTCBS, A.CSTIBSUF),3,0) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 7, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- CodigoSituacaoTributariaIBSCBS
            fc5_buscacamponotatecnica( LPAD(NVL(A.CCLASSTRIBREGULARCBS, A.CCLASSTRIBREGULARIBSUF),6,0) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 8, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- CodigoSituacaoTributariaRegularIBSCBS
            fc5_buscacamponotatecnica( LPAD(NVL(A.CSTREGULARCBS, A.CSTREGULARIBSUF),3,0) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 9, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- CodigoClassificacaoTributariaRegularIBSCBS
            fc5_buscacamponotatecnica( LPAD(NVL(A.CCREDPRESCBS,A.CCREDPRESIBSUF),2,0) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 10, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- CodigoCreditoPresumidoIBSCBS           
            fc5_buscacamponotatecnica( NULL , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 30, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- NumeroPedido           
            fc5_buscacamponotatecnica( NULL , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 31, SYSDATE, 'N', NULL, NULL, 'NFSE') -- CodigoNCM         
            
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MRL_PRODUTOEMPRESA b, MLF_NOTAFISCAL c
         where a.seqproduto = b.seqproduto
         and a.nroempresa = b.nroempresa
         and a.numeronf = c.numeronf
         and a.nroempresa = c.nroempresa
         and a.serienf = c.serienf
         and a.tipnotafiscal = c.tipnotafiscal
         and c.seqnotafiscal = pnSeqNota;
         
     -- 2300 - Identificação do Serviço Prestado             
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select distinct
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '23001' ||       
            -- Reforma
            fc5_buscacamponotatecnica( NVL(a.NFREFERENCIANFECHAVEACESSO, C.NFEREFERENCIACHAVE) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 11, SYSDATE, 'N', NULL, NULL, 'NFSE') -- NFSeReferenciada
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.numeronf = c.numeronf
         and a.nroempresa = c.nroempresa
         and a.serienf = c.serienf
         and a.tipnotafiscal = c.tipnotafiscal
         and c.seqnotafiscal = pnSeqNota
         and ( a.NFREFERENCIANFECHAVEACESSO IS NOT NULL OR C.NFEREFERENCIACHAVE IS NOT NULL )
         and vsStatusNT004 = 'A';             

     -- 2310 - Identificação dos Valores do RPS        
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo,seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '2310;' || -- Calculo para os valores abaixo são realizado na trigger tbi_mlf_nfitem
            replace(fc5ConverteNumberToChar(trunc(nvl(a.vlritem, 0), 2)), '.', ',') || ';' || -- ValorServicos
            replace(fc5ConverteNumberToChar(trunc(nvl(a.vlrDeducoes, 0), 2)), '.', ',') || ';' || -- ValorDeducoes
            replace(fc5ConverteNumberToChar(trunc(decode( vsPDUtilizaPisCofinsRet, 'S', decode(a.indretpis, 'S', nvl(a.vlrpisretido, 0), 0), nvl(a.vlrpis, 0)), 2)), '.', ',') || ';' || -- ValorPis
            replace(fc5ConverteNumberToChar(trunc(decode( vsPDUtilizaPisCofinsRet, 'S', decode(a.indretcofins, 'S', nvl(a.vlrcofinsretido, 0), 0), nvl(a.vlrcofins, 0)), 2)), '.', ',') || ';' || -- ValorCofins
            replace(fc5ConverteNumberToChar(nvl(a.vlrinss, 0)), '.', ',') || ';' || -- ValorInss
            replace(fc5ConverteNumberToChar(nvl(a.vlrir, 0)), '.', ',') || ';' || -- ValorIr
            replace(fc5ConverteNumberToChar(nvl(a.vlrcsll,0 )), '.', ',') || ';' || -- ValorCsll
            replace(fc5ConverteNumberToChar(decode(g.codnaturezanfse, 9, 0, nvl(a.vlrtotiss, 0))), '.', ',') || ';' || -- ValorIss
            replace(fc5ConverteNumberToChar(nvl(a.vlrissretido, 0)), '.', ',') || ';' || -- ValorIssRetido
            '0,00' || ';' || -- OutrasRetencoes
            replace(fc5ConverteNumberToChar(nvl(a.vlrbaseiss, 0)), '.', ',') || ';' || -- BaseCalculo
            replace(fc5ConverteNumberToChar(trunc(coalesce(a.peraliqiss,a.peraliqissretido, 0) / 100, 4), 1, 4), '.', ',') || ';' || -- Aliquota
            replace(fc5ConverteNumberToChar(
                      trunc(nvl(a.vlritem - a.vlrdescitem
                      - decode( vsPDUtilizaPisCofinsRet, 'S', decode(a.indretpis, 'S', trunc(nvl(a.Vlrpisretido, 0), 2), 0), trunc(nvl(a.vlrpis, 0), 2)) 
                      - decode( vsPDUtilizaPisCofinsRet, 'S', decode(a.indretcofins, 'S', trunc(nvl(a.vlrcofinsretido, 0), 2), 0), trunc(nvl(a.vlrcofins, 0),2)) 
                      - a.vlrinss - a.vlrir - a.vlrcsll - a.vlrissretido, 0), 2)), '.', ',') || ';' || -- ValorLiquidoNfse 
            replace(fc5ConverteNumberToChar(nvl(a.vlrdescitem, 0)), '.', ',') || ';' || -- Desconto Incondicionado
            '0,00' || ';'  -- DescontoCondicionado
            ||'0,00;0,00;0,00;0,00;0,00;0,00;0,00;0,00;0,00', -- ValorReducaoBaseCalculo - ValorRepasse - ValorAproximadoImposto - AliquotaAproximadoImposto - ValorISSQNSubstituicao - BaseCalculoSubstituicao - ValorISSQN - BaseCalculoISSQNSubstituicao - ValorCpp
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MRL_PRODUTOEMPRESA b, MLF_NOTAFISCAL c, max_codgeraloper g
         where a.seqproduto = b.seqproduto
         and a.nroempresa = b.nroempresa
         and a.numeronf = c.numeronf
         and a.nroempresa = c.nroempresa
         and a.serienf = c.serienf
         and a.tipnotafiscal = c.tipnotafiscal
         and c.codgeraloper = g.codgeraloper
         and c.seqnotafiscal = pnSeqNota;
          
     -- 2320 - Identificação das Alíquotas do RPS
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        linha, arquivo, seqnotafiscal)
     values (
        pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
        '2320' ||
        ';' || replace(fc5ConverteNumberToChar(trunc(decode(vsPDUtilizaPisCofinsRet, 'S', decode(vsIndRetPis, 'S', nvl(vnPercPisProdEmp, 0), 0), nvl(vnPercPis, 0)) / 100, 4), 2, 4), '.', ',') ||
        ';' || replace(fc5ConverteNumberToChar(trunc(decode(vsPDUtilizaPisCofinsRet, 'S', decode(vsIndRetCofins, 'S', nvl(vnPercCofinsProdEmp, 0), 0), nvl(vnPercCofins, 0)) / 100, 4), 2, 4), '.', ',') ||
        ';' || replace(fc5ConverteNumberToChar(trunc(nvl(nvl(vnPerINSSProdEmp, vnPercINSS), 0) / 100, 4), 2, 4), '.', ',') || 
        ';' || replace(fc5ConverteNumberToChar(trunc(nvl(nvl(vnPerIRRFProdEmp, vnPercIR), 0) / 100, 4), 2, 4), '.', ',') ||
        ';' || replace(fc5ConverteNumberToChar(trunc(nvl(nvl(vnPerCSLLProdEmp, vnPercCSLL), 0) / 100, 4), 2, 4), '.', ',') || 
        ';' || -- AliquotaCPP
        ';' || -- RetidoPIS
        ';' || -- RetidoCofins
        ';' || -- RetidoInss
        ';' || -- RetidoIr
        ';' || -- RetidoCsll
        ';' || -- RetidoOutrasRetencoes
        ';' || -- AliquotaTotalTributos
        ';' || -- RetidoCpp
        ';' || -- ValorTotalTibutos
        ';' || -- PercentualTotalTributosEstaduais
        ';' || -- PercentualTotalTributosFederais
        ';' || -- PercentualTotalTributosMunicipais
        ';' || -- RetidoPisCofins
        -- Reforma
        fc5_buscacamponotatecnica( to_char(vnPerDiferimentoIbsMun, csFormatoNumber3_2, csFormatNlsNumeric), '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 12, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- PercentualDiferimentoMunicipal
        fc5_buscacamponotatecnica( to_char(vnPerDiferimentoIbsUf, csFormatoNumber3_2, csFormatNlsNumeric), '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 13, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- PercentualDiferimentoEstadual
        fc5_buscacamponotatecnica( to_char(vnPerDiferimentoCbs, csFormatoNumber3_2, csFormatNlsNumeric), '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 14, SYSDATE, 'N', NULL, NULL, 'NFSE') -- PercentualDiferimentoCBS
        , 
        vsNomeArquivo, pnSeqNota);

     -- 2330 - Identificação Complementar do Serviço
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        linha, arquivo, seqnotafiscal)
     select
        pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
        '2330;' ||
        nvl(vnTipoRecNFSe, vnTipoRec) || ';' ||
        FC5LIMPAACENTO(nvl(vsMotivoRecNFSe, vsMotivoRec)) || ';' || 
        NVL(vsCidadeTomador,a.cidade) || ';' || 
        '99' || ';' || -- SeriePrestacao
        '', --MotCancelamento
        vsNomeArquivo, pnSeqNota
     from GE_CIDADE a
     where a.seqcidade = vnSeqCidade;

     -- 2340 - Identificação dos Itens do Serviço     
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '2340' ||
            ';' || D.Itemlistaservnfse  || -- ItemListaServico
            ';' || Nvl(D.codcnaenfse, vnCodCNAE) || -- CodigoCnae
            ';' || CASE WHEN G.DISCRIMINACAO IS NULL THEN
              b.desccompleta
            ELSE
              G.DISCRIMINACAO
            END || -- DiscriminacaoServico
            ';' || CASE WHEN F.QUANTIDADE IS NULL THEN
              a.quantidade
            ELSE
              F.QUANTIDADE
            END   || -- Quantidade
            ';' || replace(fc5ConverteNumberToChar(trunc(nvl(CASE WHEN F.VALOR IS NULL THEN
                                                           nvl(a.vlritem / a.quantidade, 0)
                                                         ELSE
                                                           F.VALOR
                                                         END, 0), 2)), '.', ',') || -- ValorUnitario
            ';' || replace(fc5ConverteNumberToChar(trunc(nvl(CASE WHEN F.VALOR IS NULL THEN
                                                           nvl(a.vlrdescitem, 0)
                                                         ELSE
                                                           F.VLRDESCONTO
                                                         END, 0), 2)), '.', ',') || -- ValorDesconto
            ';' || replace(fc5ConverteNumberToChar(trunc(nvl(CASE WHEN F.VALOR IS NULL THEN
                                                           nvl(a.vlritem, 0)
                                                         ELSE
                                                           (F.VALOR - NVL(F.VLRDESCONTO,0)) * F.QUANTIDADE
                                                         END, 0),2)), '.', ',') || -- ValorTotal
            ';' || (case when coalesce(d.peraliqiss, d.peraliqissretido, 0 ) = 0 then 2 else 1 end) || -- ServicoTributavel
            ';' || replace(fc5ConverteNumberToChar(trunc(coalesce(d.peraliqiss, d.peraliqissretido, 0) / 100, 4), 1, 4),'.', ',') || -- VlrAliquota
            ';' || d.codservicomunicipionfse || -- CodigoTributacaoMunicipio
            ';' || CASE WHEN NVL(vnNfItemServ,0) >= 2 THEN
                         replace(fc5ConverteNumberToChar((F.VALOR * F.QUANTIDADE - F.VLRDESCONTO), 15, 2), '.', ',')                 
                       ELSE
                         replace(fc5ConverteNumberToChar( nvl( a.baseissnfse,0 ), 15, 2), '.', ',')      
                       END || -- VlrBaseCalculo
            ';' || a.embalagem || -- Unidade
            ';' || CASE WHEN NVL(vnNfItemServ,0) >= 2 THEN
                          replace(fc5ConverteNumberToChar(trunc(F.VALOR * F.QUANTIDADE - F.VLRDESCONTO,2)), '.', ',')                   
                       ELSE
                          replace(fc5ConverteNumberToChar(
                                    trunc(nvl(a.vlritem - a.vlrdescitem
                                    - decode( vsPDUtilizaPisCofinsRet, 'S', decode(a.indretpis, 'S', trunc(nvl(a.Vlrpisretido, 0), 2), 0), trunc(nvl(a.vlrpis, 0), 2)) 
                                    - decode( vsPDUtilizaPisCofinsRet, 'S', decode(a.indretcofins, 'S', trunc(nvl(a.vlrcofinsretido, 0), 2), 0), trunc(nvl(a.vlrcofins, 0),2)) 
                                    - a.vlrinss - decode(vsPdIrRetidoProdutoServico,'S', 0, a.vlrir) - a.vlrcsll - a.vlrissretido, 0), 2)), '.', ',')  -- ValorLiquido
            END || -- ValorLiquido
            ';' || -- VlrIssServico
            ';' || -- ValorPis
            ';' || -- ValorCofins
            ';' || -- ValorInss
            ';' || -- ValorIr
            ';' || -- ValorCsll
            ';' || -- IssRetido
            ';' || -- ValorIss
            ';' || -- ValorIssRetido
            ';' || -- OutrasRetencoes
            ';' || -- DescontoIncondicionado
            ';' || -- DescontoCondicionado
            ';' || -- CodigoMunicipio
            ';' || -- ValorReducaoBaseCalculo
            ';' || -- BaseCalculoSubstituicao
            ';' || -- AliquotaAproximadoImposto
            ';' || -- ValorISSQNSubstituicao
            ';' || -- CodigoSituacaoTributaria
            ';' || -- ValorReducaoBaseCalculoISS
            ';' || -- VlrDeducao
            fc5_buscacamponotatecnica( decode(b.codprodfiscal, 'FRETE',                991,
                                                               'SEGURO',               992,
                                                               'PIS COFINS',           993,
                                                               'AP CRD AT IMOB',       994,
                                                               'RESS SUB TRIB',        995,
                                                               'TRANSF CREDITO',       996,
                                                               'COMP VR E ICMS',       997,
                                                               'SERV NAO TRIB',        998,
                                                               'DESPESA',              999,
                                                               nvl(a.seqordemnfe, a.seqitemnf)), '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 15, SYSDATE, 'N', NULL, NULL, 'NFSE') -- NumeroItem
            ,vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MAP_PRODUTO b, MLF_NOTAFISCAL c, MRL_PRODUTOEMPRESA D,MAX_EMPRESA E,
         MLF_NFITEMSERV F, MRL_PRODEMPSERVICO G
         where a.seqproduto = b.seqproduto
         and a.seqnf = c.seqnf
         and a.seqproduto = d.seqproduto
         and a.nroempresa = d.nroempresa
         and C.NROEMPRESA = E.NROEMPRESA
         AND F.NUMERONF(+) = A.NUMERONF
         AND F.SEQPESSOA(+) = A.SEQPESSOA
         AND F.SERIENF(+) = A.SERIENF
         AND F.TIPNOTAFISCAL(+) = A.TIPNOTAFISCAL
         AND F.NROEMPRESA(+) = A.NROEMPRESA
         AND F.SEQPRODUTO(+) = A.SEQPRODUTO
         AND G.SEQPRODUTO(+) = F.SEQPRODUTO
         AND G.NROEMPRESA(+) = F.NROEMPRESA
         AND G.SEQSERVICO(+) = F.SEQSERVICO
         and c.seqnotafiscal = pnSeqNota;
      
     -- 2360 - Identificação Endereço Serviço
        insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,       seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2360;' || p.logradouro || ';' ||
              p.nrologradouro || ';' ||
              replace(p.cmpltologradouro, ';', '') || ';' ||
              p.bairro || ';' ||
              p.uf || ';' ||
              nvl(p.cep, '00000000') || ';' ||
              p.cidade,
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p, ge_cidade c, mlf_notafiscal n
        where p.seqcidade = c.seqcidade
          and p.seqpessoa = n.seqpessoa
          and p.cidade  = c.cidade
          and n.seqnotafiscal = pnSeqNota
          and NVL(c.IndGeraEnderecoServico, 'N') = 'S';
     
     -- 2400 - Identificação do Prestador de Serviços
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        linha, arquivo, seqnotafiscal)
     values (
        pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
        '2400;' ||
        vsCNPJ || ';' ||
        vsInscMun,
        vsNomeArquivo, pnSeqNota); 
     
     -- 2410 - Dados Complementares do Prestador     
     insert into mrlx_pdvimportacao
       (nroempresa, softpdv, dtamovimento, dtahorlancamento,
        linha, arquivo, seqnotafiscal)
     values (
        pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
        '2410;' ||
        vnFoneDDDPrest || ';' ||
        vnFonePrest || ';' ||
        vsRazaoSocialPrest || ';' ||
        vsFantasiaPrest || ';' ||
        vsEmailPrest || ';',
        vsNomeArquivo, pnSeqNota);
        
     -- 2420 - Dados de Endereço do Prestador
     insert into mrlx_pdvimportacao
           (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
            linha,
            arquivo,       seqnotafiscal)
     values (
             pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
             '2420;' ||
             vsLogradouroPrest || ';' ||
             vnNroLogradouroPrest || ';' ||
             vsCmpltoLogradouroPrest || ';' ||
             vsBairroPrest || ';' ||
             vsUfPrest || ';' ||
             vsCepPrest || ';' ||
             trim(substr(vsPDCodPaisPrestador,1,7)),
             vsNomeArquivo, pnSeqNota );                 
     
     if(vnSeqPessoaTomadorNFSe is not null) then              
       -- 2500 - Identificação do tomador de serviços
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,              arquivo,       seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2500;' || substr(p.nomerazao,1,115),
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p
        where p.seqpessoa = vnSeqPessoaTomadorNFSe;
               
       -- 2510 - Informações do tomador de serviços
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,       seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2510;' ||  decode(p.fisicajuridica, 'F', lpad(p.nrocgccpf,9,0) || lpad(p.digcgccpf,2,0), '') || ';' ||
              decode(p.fisicajuridica, 'J', lpad(p.nrocgccpf,12,0) || lpad(p.digcgccpf,2,0), '') || ';' ||
              decode(p.fisicajuridica, 'F', lpad('0',vnQtdDigInscrMun,'0'), 'J', nvl(p.inscmunicipal,(lpad('0',vnQtdDigInscrMun,'0')))),
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p
        where p.seqpessoa = vnSeqPessoaTomadorNFSe;
        
       -- 2520 - Endereço do tomador de serviços       
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,       seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2520;' || p.logradouro || ';' ||
              p.nrologradouro || ';' ||
              replace(p.cmpltologradouro, ';', '') || ';' ||
              p.bairro || ';' ||
              c.codibge || ';' ||
              c.codsiafi || ';' ||
              p.uf || ';' ||
              nvl(p.cep, '00000000') || ';' ||
              c.seqcidadecorreios || ';',
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p, ge_cidade c
        where p.seqpessoa = vnSeqPessoaTomadorNFSe
          and p.seqcidade = c.seqcidade;
          
       -- 2530 - Contato do tomador de serviços
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,       seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2530;'|| SUBSTR(LPAD(p.foneddd1||p.fonenro1, 11,0), 1, 11) || ';' ||
              p.email,
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p
        where p.seqpessoa = vnSeqPessoaTomadorNFSe;
       
       -- 2540 - Dados complementares do tomador
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,            seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2540;' ||
              substr(l.tiplogradouro,1,10) || ';' ||
              b.tipbairro ||';' ||
              c.cidade || ';' ||
              lpad(p.foneddd1,3,0) ||';' ||          
              ';' ||
              p.pais || ';' ||
              CASE WHEN 
                NVL(vsPD_EnviaTipoDocumento,'N') = 'S' AND p.fisicajuridica = 'F' THEN
                  ';1;;' 
                ELSE
                  ';;;' 
              END || 
              DECODE(NVL(vsPDExibeCodPaisTomador, 'S'), 'S', '1058', '') ||';',
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p, ge_cidade c, ge_logradouro l, ge_bairro b
        where p.seqpessoa = vnSeqPessoaTomadorNFSe
          and p.seqcidade = c.seqcidade
          and p.seqcidade = l.seqcidade
          and p.seqlogradouro = l.seqlogradouro
          and p.seqcidade = b.seqcidade
          and p.seqbairro = b.seqbairro;
     end if;
          
     if (vnSeqPessoaIntermediarioNFSe is not null) then
         -- 2600 - Identificação do Intermediário do Serviço
         insert into mrlx_pdvimportacao
                 (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
                  linha,
                  arquivo,       seqnotafiscal)
         select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
                 '2600;' ||  p.nomerazao || ';' ||
                 decode(p.fisicajuridica, 'F', lpad(p.nrocgccpf,9,0) || lpad(p.digcgccpf, 2, '0'), '') || ';' || 
                 decode(p.fisicajuridica, 'J', lpad(p.nrocgccpf,12,0) || lpad(p.digcgccpf,2,0), '') || ';' || 
                 decode(p.fisicajuridica, 'F', lpad('0',vnQtdDigInscrMun,'0'), 'J', lpad(nvl(p.inscmunicipal, '0'),vnQtdDigInscrMun,'0')) , 
                 vsNomeArquivo, pnSeqNota
         from    ge_pessoa p
         where   p.seqpessoa = vnSeqPessoaIntermediarioNFSe ;
     end if;
     
     if (vsCodObraNFSe is not null and vsCodArtObraNFSe is not null) then
       -- 2700 - Identificação dos códigos da Obra       
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,       seqnotafiscal)
       values (
               pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
               '2700;' || 
               vsCodObraNFSe || ';' || 
               vsCodArtObraNFSe || ';' ||
               ';;;', 
               vsNomeArquivo, pnSeqNota );
        
     end if;
     
     if vnSeqPessoaDestinatarioNFSe is not null then
       
       -- 2900 - Destinatario
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,            seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2900'
              ,
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p
        where p.seqpessoa = vnSeqPessoaDestinatarioNFSe
          and vsStatusNT004 = 'A';
     
       -- 2910 - IdentificacaoDestinatario
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,            seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2910' ||
              fc5_buscacamponotatecnica( p.nomerazao, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 16, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- Nome
              fc5_buscacamponotatecnica(decode(p.fisicajuridica, 'F', lpad(p.nrocgccpf,9,0) || lpad(p.digcgccpf, 2, '0'), ''), '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 17, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- Cpf
              fc5_buscacamponotatecnica(decode(p.fisicajuridica, 'J', lpad(p.nrocgccpf,12,0) || lpad(p.digcgccpf,2,0), ''), '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 18, SYSDATE, 'N', NULL, NULL, 'NFSE') -- CNPJ 
              ,
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p
        where p.seqpessoa = vnSeqPessoaDestinatarioNFSe
          and vsStatusNT004 = 'A';
          
       -- 2920 - Endereco
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,            seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2920' ||
              fc5_buscacamponotatecnica( P.CEP, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 19, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- Cep
              fc5_buscacamponotatecnica( C.CODPAIS, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 20, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- CodigoPais
              fc5_buscacamponotatecnica( C.CIDADE, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 21, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- CidadeDescricao
              fc5_buscacamponotatecnica( C.UF, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 22, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- EstProvReg
              fc5_buscacamponotatecnica( p.Nrologradouro, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 23, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- Numero
              fc5_buscacamponotatecnica( p.Bairro, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 24, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- Bairro
              fc5_buscacamponotatecnica( p.Cmpltologradouro, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 25, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- Complemento
              fc5_buscacamponotatecnica( p.Logradouro, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 26, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- Endereco
              fc5_buscacamponotatecnica( C.CODIBGE, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 27, SYSDATE, 'N', NULL, NULL, 'NFSE') -- CodigoMunicipio
              ,
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p, ge_cidade c, ge_logradouro l, ge_bairro b
        where p.seqpessoa = vnSeqPessoaDestinatarioNFSe
          and p.seqcidade = c.seqcidade
          and p.seqcidade = l.seqcidade
          and p.seqlogradouro = l.seqlogradouro
          and p.seqcidade = b.seqcidade
          and p.seqbairro = b.seqbairro
          and vsStatusNT004 = 'A';  
          
       -- 2930 - Contato
       insert into mrlx_pdvimportacao
             (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
              linha,
              arquivo,            seqnotafiscal)
       select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
              '2930' ||
              fc5_buscacamponotatecnica( SUBSTR(LPAD(p.foneddd1||p.fonenro1, 11,0), 1, 11), '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 28, SYSDATE, 'N', NULL, NULL, 'NFSE')  || -- Telefone
              fc5_buscacamponotatecnica( p.Email, '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 29, SYSDATE, 'N', NULL, NULL, 'NFSE') -- Email
              ,
              vsNomeArquivo, pnSeqNota
         from ge_pessoa p
        where p.seqpessoa = vnSeqPessoaDestinatarioNFSe
          and vsStatusNT004 = 'A';       
     end if;
              
     -- 4010 - ValoresBrutosIBSCBS         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4010' ||
            fc5_buscacamponotatecnica( to_char( NVL(A.VLRBASEIBSUF, A.VLRBASECBS), csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 33, SYSDATE, 'N', NULL, NULL, 'NFSE') -- ValorBrutoBaseCalculo 
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';
         
     -- 4011 - ValoresEstaduais         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4011' ||
            fc5_buscacamponotatecnica(  to_char(a.PERALIQIBSUF, csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 34, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- AliquotaIBSUF
            fc5_buscacamponotatecnica(  to_char(a.PERALIQREDIBSUF, csFormatoNumber3_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 35, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- PercentualReducaoIBSUF
            fc5_buscacamponotatecnica(  to_char(a.PERALIQEFETIVAIBSUF, csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 36, SYSDATE, 'N', NULL, NULL, 'NFSE') -- AliquotaEfetivaIBSUF 
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and a.cstibsuf is not null
         and (a.PERALIQIBSUF >= 0 or a.PERALIQREDIBSUF >= 0 or a.PERALIQEFETIVAIBSUF >= 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A'; 
         
     -- 4012 - ValoresMunicipais         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4012' ||
            fc5_buscacamponotatecnica(  to_char(a.PERALIQIBSMUN, csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 37, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- AliquotaIBSMUN
            fc5_buscacamponotatecnica(  to_char(a.PERALIQREDIBSMUN, csFormatoNumber3_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 38, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- PercentualReducaoIBSMUN
            fc5_buscacamponotatecnica(  to_char(a.PERALIQEFETIVAIBSMUN, csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 39, SYSDATE, 'N', NULL, NULL, 'NFSE') -- AliquotaEfetivaIBSMUN 
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and a.cstibsmun is not null
         and (a.PERALIQIBSMUN >= 0 or a.PERALIQREDIBSMUN >= 0 or a.PERALIQEFETIVAIBSMUN >= 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';
         
     -- 4013 - ValoresFederais         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4013' ||
            fc5_buscacamponotatecnica(  to_char(a.PERALIQCBS, csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 40, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- AliquotaCBS
            fc5_buscacamponotatecnica(  to_char(a.PERALIQREDCBS, csFormatoNumber3_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 41, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- PercentualReducaoCBS
            fc5_buscacamponotatecnica(  to_char(a.PERALIQEFETIVACBS, csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 42, SYSDATE, 'N', NULL, NULL, 'NFSE') -- AliquotaEfetivaCBS 
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and a.cstcbs is not null
         and (a.PERALIQCBS >= 0 or a.PERALIQREDCBS >= 0 or a.PERALIQEFETIVACBS >= 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';
         
     -- 4020 - TotalizadoresIBSCBS         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4020' ||
            fc5_buscacamponotatecnica(  to_char(trunc(nvl(CASE WHEN F.VALOR IS NULL THEN
                                                           nvl(a.vlritem, 0)
                                                         ELSE
                                                           (F.VALOR - NVL(F.VLRDESCONTO,0)) * F.QUANTIDADE
                                                         END, 0),2) 
                                                         + 
                                                         CASE WHEN NVL(vsIndConsideraImposto,'N') = 'S'
                                                              THEN A.VLRIMPOSTOIS + A.VLRIMPOSTOIBSMUN + A.VLRIMPOSTOIBSUF + A.VLRIMPOSTOCBS 
                                                              ELSE 0  
                                                         END 
                                                         , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 43, SYSDATE, 'N', NULL, NULL, 'NFSE') -- ValorTotal
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c, MLF_NFITEMSERV f
         where a.seqnf = c.seqnf
         AND F.NUMERONF(+) = A.NUMERONF
         AND F.SEQPESSOA(+) = A.SEQPESSOA
         AND F.SERIENF(+) = A.SERIENF
         AND F.TIPNOTAFISCAL(+) = A.TIPNOTAFISCAL
         AND F.NROEMPRESA(+) = A.NROEMPRESA
         AND F.SEQPRODUTO(+) = A.SEQPRODUTO
         and (A.CSTCBS IS NOT NULL OR A.CSTIBSUF IS NOT NULL OR A.CSTIBSMUN IS NOT NULL)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';
         
     -- 4021 - TributacaoRegular         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4021' ||
            fc5_buscacamponotatecnica(  to_char(a.PERALIQREGULARIBSUF, csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 44, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- AliquotaEfetivaRegularIBSUF
            fc5_buscacamponotatecnica(  to_char(a.VLRIMPOSTOREGULARIBSUF, csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 45, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- ValorTributacaoRegularIBSUF
            fc5_buscacamponotatecnica(  to_char(a.PERALIQREGULARIBSMUN, csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 46, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- AliquotaEfetivaRegularIBSMUN 
            fc5_buscacamponotatecnica(  to_char(a.VLRIMPOSTOREGULARIBSMUN, csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 47, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- ValorTributacaoRegularIBSMUN
            fc5_buscacamponotatecnica(  to_char(a.PERALIQREGULARCBS, csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 48, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- AliquotaEfetivaRegularCBS
            fc5_buscacamponotatecnica(  to_char(a.VLRIMPOSTOREGULARCBS, csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 49, SYSDATE, 'N', NULL, NULL, 'NFSE') -- ValorTributacaoRegularCBS 
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and (A.CSTCBS IS NOT NULL OR A.CSTIBSUF IS NOT NULL OR A.CSTIBSMUN IS NOT NULL) 
         and (a.VLRIMPOSTOREGULARIBSUF > 0 or a.VLRIMPOSTOREGULARIBSMUN > 0 or a.VLRIMPOSTOREGULARCBS > 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';
         
     -- 4023 - ValoresIBS         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4023' ||
            fc5_buscacamponotatecnica(  to_char( NVL(A.VLRIMPOSTOIBSMUN,0) + NVL(A.VLRIMPOSTOIBSUF,0) , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 50, SYSDATE, 'N', NULL, NULL, 'NFSE') -- TotalIBS
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and (A.CSTIBSUF IS NOT NULL OR A.CSTIBSMUN IS NOT NULL) 
         and (a.VLRIMPOSTOIBSMUN > 0 or a.VLRIMPOSTOIBSUF > 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';
         
     -- 4024 - ValoresIBS         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4024' ||
            fc5_buscacamponotatecnica(  to_char( A.PERALIQCCREDPRESIBSUF , csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 51, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- AliquotaCreditoIBS
            fc5_buscacamponotatecnica(  to_char( A.VLRCCREDPRESIBSUF , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 52, SYSDATE, 'N', NULL, NULL, 'NFSE') -- ValorCreditoIBS
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and a.cstibsuf is not null
         and (a.VLRCCREDPRESIBSUF > 0 or a.PERALIQCCREDPRESIBSUF > 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';
         
     -- 4025 - TotalIBSEstado         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4025' ||
            fc5_buscacamponotatecnica(  to_char( A.VLRDIFERIDOIBSUF , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 53, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- ValorDiferimentoIBS
            fc5_buscacamponotatecnica(  to_char( A.VLRIMPOSTOIBSUF , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 54, SYSDATE, 'N', NULL, NULL, 'NFSE') -- ValorIBS
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and a.cstibsuf is not null
         and (a.VLRDIFERIDOIBSUF > 0 or a.VLRIMPOSTOIBSUF > 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';
         
     -- 4026 - TotalIBSMunicipio         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4026' ||
            fc5_buscacamponotatecnica(  to_char( A.VLRDIFERIDOIBSMUN , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 55, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- ValorDiferimentoIBS
            fc5_buscacamponotatecnica(  to_char( A.VLRIMPOSTOIBSMUN , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 56, SYSDATE, 'N', NULL, NULL, 'NFSE') -- ValorIBS
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and a.cstibsmun is not null
         and (a.VLRDIFERIDOIBSMUN > 0 or a.VLRIMPOSTOIBSMUN > 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A'; 
         
     -- 4027 - ValoresCBS         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4027' ||
            fc5_buscacamponotatecnica(  to_char( A.VLRDIFERIDOCBS , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 57, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- ValorDiferimentoCBS
            fc5_buscacamponotatecnica(  to_char( A.VLRIMPOSTOCBS , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 58, SYSDATE, 'N', NULL, NULL, 'NFSE') -- ValorCBS
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and a.cstcbs is not null
         and (a.VLRDIFERIDOCBS > 0 or a.VLRIMPOSTOCBS > 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';
     
     -- 4028 - CreditoPresumidoCBS         
     insert into mrlx_pdvimportacao
           (nroempresa, softpdv, dtamovimento, dtahorlancamento,
            linha, arquivo, seqnotafiscal)
         select
            pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
            '4028' ||
            fc5_buscacamponotatecnica(  to_char( A.PERALIQCCREDPRESCBS , csFormatoNumber2_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 59, SYSDATE, 'N', NULL, NULL, 'NFSE') || -- AliquotaCreditoCBS
            fc5_buscacamponotatecnica(  to_char( A.VLRCCREDPRESCBS , csFormatoNumber13_2, csFormatNlsNumeric) , '4', pnNroEmpresa, csCodLayoutNFSE, csNT4Versao, 60, SYSDATE, 'N', NULL, NULL, 'NFSE') -- ValorCreditoCBS
            ,   
            vsNomeArquivo, pnSeqNota
         from MLF_NFITEM a, MLF_NOTAFISCAL c
         where a.seqnf = c.seqnf
         and a.cstcbs is not null
         and (a.VLRCCREDPRESCBS > 0 or a.PERALIQCCREDPRESCBS > 0)
         and c.seqnotafiscal = pnSeqNota
         and vsStatusNT004 = 'A';                                                        
     
     -- 9000 - Outras Informações
     insert into mrlx_pdvimportacao
            (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
             linha,
             arquivo,            seqnotafiscal)
     select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'REF_COMPETENCIA;' || TO_CHAR(nvl(vdDtaHoraCompetenciaCust, vdDtaHoraEmissao),'MM/YYYY') ,
             vsNomeArquivo, pnSeqNota
     from    max_parametro p
     where   p.parametro   =       'GERA_MES_NF_OUTRAS_INFO'
     and     p.grupo       =       'NF_SERVICO'
     and     p.nroempresa  =       pnNroEmpresa  
     and     p.valor       =       'S' 
     UNION ALL
     --9000 MUNICIPIO_TOMADOR
      select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'MUNICIPIO_TOMADOR;' || c.cidade ,
             vsNomeArquivo, pnSeqNota
     from    max_parametro p, ge_pessoa b, ge_cidade c
     where   p.parametro   =       'GERA_MUN_TOM_OUTRAS_INFO'
     and     p.grupo       =       'NF_SERVICO'
     and     p.nroempresa  =       pnNroEmpresa
     and     p.valor       =       'S'
     and     b.seqpessoa   =       vnSeqPessoaTomadorNFSe
     and     b.seqcidade   =       c.seqcidade
    ---
     UNION ALL
     select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'LOCAL_PRESTACAO_SERVICO;' || vsCidadePessoaNF||'/'||vsUFPessoaNF ,
             vsNomeArquivo, pnSeqNota
     from    max_parametro p
     where   p.parametro   =       'GERA_LOCAL_OUTRAS_INFO'
     and     p.grupo       =       'NF_SERVICO'
     and     p.nroempresa  =       pnNroEmpresa  
     and     p.valor       =       'S' 
     and     (vsCidadePessoaNF is not null and vsUFPessoaNF is not null)
     UNION ALL
     select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'RECOLHIMENTO;' || decode(vnSeqPessoaTomadorNFSe, null, ' ', case when nvl(vnTipoRecNFSe, vnTipoRec) = 1 then
                                                                                            'ISS a Recolher pelo Prestador'
                                                                                          when nvl(vnTipoRecNFSe, vnTipoRec) = 2 then
                                                                                            'ISS Retido na Fonte pelo Tomador'
                                                                                          else
                                                                                            'ISS Retido na Fonte pelo Tomador'
                                                                                     end),
             vsNomeArquivo, pnSeqNota
     from    max_parametro p
     where   p.parametro   =       'GERA_RECO_OUTRAS_INFO'
     and     p.grupo       =       'NF_SERVICO'
     and     p.nroempresa  =       pnNroEmpresa  
     and     p.valor       =       'S' 
     UNION ALL
     select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'TRIBUTACAO;' || decode(vsIndTribMun, 1, 'Tributável', ' ') ,
             vsNomeArquivo, pnSeqNota
     from    max_parametro p
     where   p.parametro   =       'GERA_TRIB_OUTRAS_INFO'
     and     p.grupo       =       'NF_SERVICO'
     and     p.nroempresa  =       pnNroEmpresa  
     and     p.valor       =       'S'
     UNION ALL
     select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'RPS;' || to_char(vnNroNota) ,
             vsNomeArquivo, pnSeqNota
     from    max_parametro p
     where   p.parametro   =       'GERA_RPS_OUTRAS_INFO'
     and     p.grupo       =       'NF_SERVICO'
     and     p.nroempresa  =       pnNroEmpresa  
     and     p.valor       =       'S' 
     UNION ALL
     select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'CNAE;' || to_char(vnCodCNAE),
             vsNomeArquivo, pnSeqNota
     from    max_parametro p
     where   p.parametro   =       'GERA_CNAE_OUTRAS_INFO'
     and     p.grupo       =       'NF_SERVICO'
     and     p.nroempresa  =       pnNroEmpresa  
     and     p.valor       =       'S' 
     and     vnCodCNAE     is not null
     UNION ALL
     select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'CNAE;' || to_char(nvl(b.codcnaenfse, vnCodCNAE)),
             vsNomeArquivo, pnSeqNota
     from MLF_NFITEM a, MRL_PRODUTOEMPRESA b, MLF_NOTAFISCAL c
     where a.seqproduto = b.seqproduto
     and a.nroempresa = b.nroempresa
     and a.numeronf = c.numeronf
     and a.nroempresa = c.nroempresa
     and a.serienf = c.serienf
     and a.tipnotafiscal = c.tipnotafiscal
     and c.seqnotafiscal = pnSeqNota
     UNION ALL
     select  pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'DESCRICAO_DA_ATIVIDADE;' || vsDescAtividadeNFSE ,
             vsNomeArquivo, pnSeqNota
     from    max_parametro p
     where   p.parametro   =       'GERA_ATIVIDADE_OUTRAS_INFO'
     and     p.grupo       =       'NF_SERVICO'
     and     p.nroempresa  =       pnNroEmpresa  
     and     p.valor       =       'S'
     and     vsDescAtividadeNFSE   is not null
     UNION ALL
     select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
             '9000;' || 'ISS;' || decode(vsExibeISSRetido,'S','SIM','NAO') ,
             vsNomeArquivo, pnSeqNota
     from    dual
     ;
     
   if (vsEmailDestNFSe is not null) then
     -- 9100 - TAG de identificação do envio de e-mail
     insert into mrlx_pdvimportacao
           (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
            linha,
            arquivo,       seqnotafiscal)
     values (
             pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
             '9100;' || vsEmailDestNFSe ,
             vsNomeArquivo, pnSeqNota );  
   end if;
     
   if (vsEmailCopiaNFSe is not null) then
     -- 9110 - Identificador do e-mail em cópia
     insert into mrlx_pdvimportacao
           (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
            linha,
            arquivo,       seqnotafiscal)
     values (
             pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
             '9110;' || vsEmailCopiaNFSe ,
             vsNomeArquivo, pnSeqNota );  
   end if;
     
   if (vsAssuntoEmailNFSe is not null) then
     -- 9120 - Assunto do e-mail
     insert into mrlx_pdvimportacao
           (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
            linha,
            arquivo,       seqnotafiscal)
     values (
             pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
             '9120;' || vsAssuntoEmailNFSe ,
             vsNomeArquivo, pnSeqNota );  
   end if;
     
   if (vsCorpoEmailNFSe is not null) then
     -- 9130 - Corpo do e-mail
     insert into mrlx_pdvimportacao
           (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
            linha,
            arquivo,       seqnotafiscal)
     values (
             pnNroEmpresa, psSoftPDV, vdDtaHoraEmissao, sysdate,
             '9130;' || vsCorpoEmailNFSe ,
             vsNomeArquivo, pnSeqNota );  
   end if;
     
     -- 9200       
     insert into mrlx_pdvimportacao
           (nroempresa,         softpdv,       dtamovimento,     dtahorlancamento,
            linha,
            arquivo,       seqnotafiscal)
     select pnNroEmpresa,       psSoftPDV,     vdDtaHoraEmissao, sysdate,
            '9200;'             ||
            a.numeronf          ||';'||
            a.serienf           ||';'||
            '1'                 ||             
            ';'                 ||             
            b.nomeimp           ||';'||
            '1',                               
            vsNomeArquivo, pnSeqNota
       from MLF_NOTAFISCAL a, MAX_EMPPONTOIMPR b
      where a.pontoimpressaosel = b.descricao
      and   a.nroempresa        = b.nroempresa
      and   vsPDControlPontoImp = 'S'
      and   a.nroempresa        = pnNroEmpresa
      and   a.seqnotafiscal     = pnSeqNota
      and   b.nomeimp           is not null;     
           
     vslinha := null;

     For vt In (
           SELECT decode(vsPDRetiraAcentoArq,'N',a.linha,fc5limpaacento(a.linha)) linha
           FROM   mrlx_pdvimportacao a
           where  a.arquivo = vsNomeArquivo
           and    a.nroempresa = pnNroEmpresa
           and    a.dtamovimento = vdDtaHoraEmissao
           and    a.seqnotafiscal = pnSeqNota)
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
    
     EXECUTE IMMEDIATE 'Begin sp_NDDigital_TBL_InputDoc(:1,:2,:3,:4,:5); End;'
     USING IN vsLinhaBLOBIntegra, 1, pnSeqNota, vnPDJobIntegraNFSE, vsChaveAcesso;
    
     SP_GRAVALOGDOCELETRONICO('NFSE', pnSeqNota, 'NFS-e integrada com NDDIGITAL aguardando retorno.');

     update mlf_notafiscal a 
     set a.statusnfe = '1' 
     where a.seqnotafiscal = pnSeqNota;

end Sp_GeraArqEnvioNDDigitalNFSe;
