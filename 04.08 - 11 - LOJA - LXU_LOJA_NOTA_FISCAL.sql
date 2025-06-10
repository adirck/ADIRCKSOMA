ALTER TRIGGER [dbo].[LXU_LOJA_NOTA_FISCAL] ON [dbo].[LOJA_NOTA_FISCAL] FOR UPDATE NOT FOR REPLICATION AS
-- Felipe Carvalho - 12/04/2017 - Corre��o na trava (SS06), para olhar se o update na chave possui 44 digitos
-- Felipe Carvalho - (SS10) - 11/02/2017 - Adicionada trava para n�o gerar nota fiscal com pulo de sequencial 
-- TIAGO CARVALHO - (SS09) - 28/01/2016 - Zero os valores se não estiver zerando no cancelamento, n�o deixo zerar se não for cancelamento
-- FELIPE SILVA   - (SS08) - 21/01/2016 - BLOQUEIA PARA NÃO SALVAR NUMERO DA NOTA EM BRANCO.
-- TIAGO CARVALHO - (SS07) 11/01/2016 - ALTERADO PARA PERCORRER TODOS OS DADOS DO INSERTED E PREENCHER O CAMPO DE NOTA CASO O MESMO ESTEJA NULO.
-- FELIPE SILVA - (SS06) 05/01/2016 - BLOQUEIA A ALTERAÇÃO CASO O NUMERO DA NOTA NÃO ESTÁ NA COMPOSIÇÃO DA CHAVE ALTERADA.
-- TIAGO CARVALHO - (SS05) - Apaga o numero do loja_venda_pgto caso seja um cancelamento,denegação ou inutilização de nota fiscal.
-- FELIPE SILVA  - (SS04) - 04/11/2015 - CORREÇÃO PARA GERAR A CHAVE DA NOTA FISCAL CASO A MESMA ESTEJA NULL.
-- FELIPE SILVA  - (SS03) - 14/10/2015 - NÃO ALTERAR FINALIDADE DE NOTA COM CFOP 6921 E 5921 "RETORNO DE MALOTE", ESSE CFOP NÃO DEVE SER TRATADO COMO DEVOLUÇÃO.
-- THIAGO.MARCON - #2# - (16/03/2015) - TPs 8052501 e 8055839 - Impacto no ETL na carga das tabelas LOJA_NOTA_FISCAL e LOJA_CONTROLE_FISCAL
-- TIAGO CARVALHO - (SS02) - 23/06/2015 - ALTERADO PARA REFERENCIAR A CHAVE_NFE DO NFCe quando ele for autorizado, muitos estão ficando com a chave null no inicio.
-- TIAGO CARVALHO - (SS02) - 19/05/2015 - ALTERADO PARA SEMPRE TENTAR REFERENCIAR NOTAS DE DEVOLUÇÃO QUE AINDA NÃO FORAM REFERENCIADAS.
-- TIAGO CARVALHO - (SS01) - 23/04/2015 - ALTERADO PARA ASSOCIAR A NOTA FISCAL A UMA ORIGEM CASO O ERRO QUE RETORNOU SEJA REFERENTE A NOTA DE DEVOLUÇÃO SEM DOCUMENTO REFERENCIADO.
-- JORGE.DAMASCO - #1# - (05/12/2014) - SOLICITADO POR THIAGO.MARCON DEVIDO À SINCRONIZAÇÃO COM O MID-E.
-- UPDATE TRIGGER ON LOJA_NOTA_FISCAL
BEGIN
    DECLARE @NUMROWS    INT,
        @NULLCNT    INT,
        @VALIDCNT   INT,
        @INSCODIGO_FILIAL CHAR(6), 
        @INSNF_NUMERO CHAR(15), 
        @INSSERIE_NF CHAR(6),
        @DELCODIGO_FILIAL CHAR(6), 
        @DELNF_NUMERO CHAR(15), 
        @DELSERIE_NF CHAR(6),
        @ERRNO   INT,
        @ERRMSG  VARCHAR(255)
 
    SELECT @NUMROWS = @@ROWCOUNT
       /* INCIO -- SS10*/
    declare @strCodigoFilialValidaseq		varchar(6),
            @StrNfNumeroValidaseq			varchar(15),
            @StrSerieNfValidaseq			varchar(6),
            @iNfnumeroAnteriorValidaseq		int  ,
            @StrNfnumeroAnteriorValidaseq	varchar(15)
            
            
    DECLARE CurValidaseq  CURSOR FOR
    SELECT  A.CODIGO_FILIAL,
            A.NF_NUMERO,
            A.SERIE_NF
        FROM INSERTED A (nolock)
                 
    OPEN CurValidaseq
    FETCH NEXT FROM CurValidaseq INTO @strCodigoFilialValidaseq, @StrNfNumeroValidaseq, @StrSerieNfValidaseq     
     
    WHILE @@FETCH_STATUS = 0
    BEGIN
		select @iNfnumeroAnteriorValidaseq = convert (int,@StrNfNumeroValidaseq) - 1 
		select @StrNfnumeroAnteriorValidaseq = RIGHT (replicate ('0',len(@StrNfNumeroValidaseq)) + convert(varchar(15),@iNfnumeroAnteriorValidaseq),len(@StrNfNumeroValidaseq))
		
		if @iNfnumeroAnteriorValidaseq > 0 
		and not exists (select nf_numero from LOJA_NOTA_FISCAL where CODIGO_FILIAL = @strCodigoFilialValidaseq AND NF_NUMERO = @iNfnumeroAnteriorValidaseq AND SERIE_NF = @StrSerieNfValidaseq )
		BEGIN
            SELECT  @ERRNO  = 30002,
                @ERRMSG = 'IMPOSSIVEL INCLUIR A NOTA: ' + @StrNfNumeroValidaseq + 'PORQUE A NOTA ANTERIOR: ' +@StrNfnumeroAnteriorValidaseq+ ' N�O EXISTE. FAVOR ENTRAR EM CONTATO COM A TI'
            GOTO ERROR
        END
                
		FETCH NEXT FROM CurValidaseq INTO @strCodigoFilialValidaseq, @StrNfNumeroValidaseq, @StrSerieNfValidaseq     
    END
    CLOSE CurValidaseq
    DEALLOCATE CurValidaseq
    /* FIM -- SS10*/
    
     
    /*SS06*/
    IF  UPDATE(CHAVE_NFE)
    BEGIN
        IF EXISTS (SELECT 1
        FROM INSERTED
        WHERE   SUBSTRING(INSERTED.CHAVE_NFE , 26, 9) <> RIGHT('000000000' + LTRIM(RTRIM(INSERTED.NF_NUMERO)), 9) AND ISNULL(inserted.CHAVE_NFE, '') <> '' AND  LEN(ISNULL(inserted.CHAVE_NFE, ''))= 44)
 
        BEGIN
            SELECT  @ERRNO  = 30002,
                @ERRMSG = 'IMPOSSIVEL ATUALIZAR LOJA_NOTA_FISCAL PORQUE EXISTEM ALTERACOES NO CAMPO CHAVE_NFE QUE NAO CONTEM O NUMERO DA NOTA CORRESPONDENTE EM SUA COMPOSICAO.'
            GOTO ERROR
        END
    END
    /*FIM SS06*/
        
    /*SS08*/
        IF EXISTS (SELECT 1 FROM INSERTED WHERE LTRIM(RTRIM(NF_NUMERO)) = '')
        BEGIN
            SELECT  @ERRNO  = 30002,
                @ERRMSG = 'IMPOSSIVEL SALVAR LOJA_NOTA_FISCAL PORQUE O NUMERO DA NOTA NÃO PODE FICAR EM BRANCO.'
            GOTO ERROR
        END
    /*FIM SS08*/
 
-- LOJAS_VAREJO - CHILD UPDATE RESTRICT
    IF  UPDATE(CODIGO_FILIAL)
    BEGIN
        SELECT @NULLCNT = 0
        SELECT @VALIDCNT = COUNT(*)
        FROM INSERTED, LOJAS_VAREJO
        WHERE   INSERTED.CODIGO_FILIAL = LOJAS_VAREJO.CODIGO_FILIAL
 
        IF @VALIDCNT + @NULLCNT != @NUMROWS
        BEGIN
            SELECT  @ERRNO  = 30002,
                @ERRMSG = 'IMPOSSÍVEL ATUALIZAR #LOJA_NOTA_FISCAL #PORQUE #LOJAS_VAREJO #NÃO EXISTE.'
            GOTO ERROR
        END
    END
 
-- CLIENTES_VAREJO - CHILD UPDATE RESTRICT
    IF  UPDATE(CODIGO_CLIENTE)
    BEGIN
        SELECT @NULLCNT = 0
        SELECT @VALIDCNT = COUNT(*)
        FROM INSERTED, CLIENTES_VAREJO
        WHERE   INSERTED.CODIGO_CLIENTE = CLIENTES_VAREJO.CODIGO_CLIENTE
 
        SELECT @NULLCNT = COUNT(*)
        FROM INSERTED 
        WHERE   INSERTED.CODIGO_CLIENTE IS NULL
 
        IF @VALIDCNT + @NULLCNT != @NUMROWS
        BEGIN
            SELECT  @ERRNO  = 30002,
                @ERRMSG = 'IMPOSSÍVEL ATUALIZAR #LOJA_NOTA_FISCAL #PORQUE #CLIENTES_VAREJO #NÃO EXISTE.'
            GOTO ERROR
        END
    END
 
-- LOJAS_VAREJO - CHILD UPDATE RESTRICT
    IF  UPDATE(COD_CLIFOR)
    BEGIN
        SELECT @NULLCNT = 0
        SELECT @VALIDCNT = COUNT(*)
        FROM INSERTED, CADASTRO_CLI_FOR
        WHERE   INSERTED.COD_CLIFOR = CADASTRO_CLI_FOR.COD_CLIFOR
 
        SELECT @NULLCNT = COUNT(*)
        FROM INSERTED 
        WHERE   INSERTED.COD_CLIFOR IS NULL
 
        IF @VALIDCNT + @NULLCNT != @NUMROWS
        BEGIN
            SELECT  @ERRNO  = 30002,
                @ERRMSG = 'IMPOSSÍVEL ATUALIZAR #LOJA_NOTA_FISCAL #PORQUE #CADASTRO_CLI_FOR #NÃO EXISTE.'
            GOTO ERROR
        END
    END
 
-- LOJAS_NATUREZA_OPERACAO - CHILD UPDATE RESTRICT
    IF  UPDATE(NATUREZA_OPERACAO_CODIGO)
    BEGIN
        SELECT @NULLCNT = 0
        SELECT @VALIDCNT = COUNT(*)
        FROM INSERTED, LOJAS_NATUREZA_OPERACAO
        WHERE   INSERTED.NATUREZA_OPERACAO_CODIGO = LOJAS_NATUREZA_OPERACAO.NATUREZA_OPERACAO_CODIGO
 
        IF @VALIDCNT + @NULLCNT != @NUMROWS
        BEGIN
            SELECT  @ERRNO  = 30002,
                @ERRMSG = 'IMPOSSÍVEL ATUALIZAR #LOJA_NOTA_FISCAL #PORQUE #LOJAS_NATUREZA_OPERACAO #NÃO EXISTE.'
            GOTO ERROR
        END
    END
 
-- #1# - INÍCIO
---- VERIFICA SE PODE ALTERAR O STATUS_NFE DENTRO DAS CONDIÇÕES PERMITIDAS -----------------------------------------------------------
--  DECLARE @STATUS_APROVADA INT, @STATUS_INUTILIZADA INT, @STATUS_CANCELADA INT, @STATUS_DENEGADA INT
--  SELECT @STATUS_APROVADA = 5
--  SELECT @STATUS_INUTILIZADA = 59
--  SELECT @STATUS_CANCELADA = 49
--  SELECT @STATUS_DENEGADA = 70
     
--  DECLARE @STATUS_NFE SMALLINT, @PROTOCOLO_AUTORIZACAO_NFE VARCHAR(15) , @DATA_AUTORIZACAO_NFE DATETIME, @PROTOCOLO_CANCELAMENTO_NFE  VARCHAR(15), @DATA_CANCELAMENTO DATETIME
     
--  IF UPDATE(STATUS_NFE)   
--  BEGIN
--      SELECT 
--          @STATUS_NFE = STATUS_NFE, @PROTOCOLO_AUTORIZACAO_NFE = PROTOCOLO_AUTORIZACAO_NFE, @DATA_AUTORIZACAO_NFE = DATA_AUTORIZACAO_NFE, 
--          @PROTOCOLO_CANCELAMENTO_NFE = PROTOCOLO_CANCELAMENTO_NFE, @DATA_CANCELAMENTO = DATA_CANCELAMENTO 
--      FROM 
--          INSERTED
--      WHERE 
--          STATUS_NFE = @STATUS_APROVADA OR STATUS_NFE = @STATUS_INUTILIZADA OR STATUS_NFE = @STATUS_CANCELADA OR STATUS_NFE = @STATUS_DENEGADA            
 
--      IF EXISTS ( SELECT STATUS_NFE FROM INSERTED 
--           WHERE (STATUS_NFE = @STATUS_APROVADA OR STATUS_NFE = @STATUS_INUTILIZADA OR STATUS_NFE = @STATUS_CANCELADA OR STATUS_NFE = @STATUS_DENEGADA)) 
 
--          BEGIN
--              IF (@STATUS_NFE = @STATUS_APROVADA OR @STATUS_NFE = @STATUS_CANCELADA) AND ((@PROTOCOLO_AUTORIZACAO_NFE IS NULL OR @PROTOCOLO_AUTORIZACAO_NFE = '') OR @DATA_AUTORIZACAO_NFE IS NULL) 
--                  BEGIN
--                      SELECT  @ERRNO=30002,
--                          @ERRMSG='NAO E POSSIVEL ALTERAR O #STATUS_NFE. #PROTOCOLO_AUTORIZACAO_NFE E/OU #DATA_AUTORIZACAO_NFE NÃO ESTÃO INFORMADOS !'
--                      GOTO ERROR
--                  END
--              IF(@STATUS_NFE = @STATUS_INUTILIZADA OR @STATUS_NFE = @STATUS_DENEGADA) AND ((@PROTOCOLO_CANCELAMENTO_NFE IS NULL OR @PROTOCOLO_CANCELAMENTO_NFE = '') OR @DATA_CANCELAMENTO IS NULL)
--                  BEGIN
--                      SELECT  @ERRNO=30002,
--                          @ERRMSG='NAO E POSSIVEL ALTERAR O #STATUS_NFE. #PROTOCOLO_CANCELAMENTO_NFE E/OU #DATA_CANCELAMENTO NÃO ESTÃO INFORMADOS !'
--                      GOTO ERROR
--                  END 
--          END
--  END 
---- #1# - FIM   
     
-- LOJA_NOTA_FISCAL_ITEM - PARENT UPDATE CASCADE
    IF  UPDATE(CODIGO_FILIAL) OR
        UPDATE(NF_NUMERO) OR
        UPDATE(SERIE_NF)
    BEGIN  
        IF EXISTS ( SELECT * 
                FROM INSERTED 
                    LEFT JOIN DELETED ON
                        DELETED.CODIGO_FILIAL = INSERTED.CODIGO_FILIAL AND
                    DELETED.NF_NUMERO = INSERTED.NF_NUMERO AND
                    DELETED.SERIE_NF = INSERTED.SERIE_NF
                WHERE   DELETED.CODIGO_FILIAL IS NULL  OR 
                DELETED.NF_NUMERO IS NULL  OR 
                DELETED.SERIE_NF IS NULL
            )
        BEGIN
            DECLARE CURI_LOJA_NOTA_FISCAL_ITEM2170 CURSOR FOR
                SELECT  CODIGO_FILIAL ,  
                NF_NUMERO ,  
                SERIE_NF
                FROM INSERTED
            DECLARE CURD_LOJA_NOTA_FISCAL_ITEM2170 CURSOR FOR
                SELECT  CODIGO_FILIAL ,  
                NF_NUMERO ,  
                SERIE_NF
                FROM DELETED
            OPEN CURI_LOJA_NOTA_FISCAL_ITEM2170
            OPEN CURD_LOJA_NOTA_FISCAL_ITEM2170
            FETCH NEXT FROM CURI_LOJA_NOTA_FISCAL_ITEM2170
                    INTO    @INSCODIGO_FILIAL ,  
                    @INSNF_NUMERO ,  
                    @INSSERIE_NF
            FETCH NEXT FROM CURD_LOJA_NOTA_FISCAL_ITEM2170
                    INTO    @DELCODIGO_FILIAL ,  
                    @DELNF_NUMERO ,  
                    @DELSERIE_NF
            WHILE @@FETCH_STATUS = 0
            BEGIN
                UPDATE LOJA_NOTA_FISCAL_ITEM
                SET CODIGO_FILIAL = @INSCODIGO_FILIAL, 
                NF_NUMERO = @INSNF_NUMERO, 
                SERIE_NF = @INSSERIE_NF
                WHERE   CODIGO_FILIAL = @DELCODIGO_FILIAL AND
                NF_NUMERO = @DELNF_NUMERO AND
                SERIE_NF = @DELSERIE_NF
 
                FETCH NEXT FROM CURI_LOJA_NOTA_FISCAL_ITEM2170
                        INTO    @INSCODIGO_FILIAL ,  
                        @INSNF_NUMERO ,  
                        @INSSERIE_NF
                FETCH NEXT FROM CURD_LOJA_NOTA_FISCAL_ITEM2170
                        INTO    @DELCODIGO_FILIAL ,  
                        @DELNF_NUMERO ,  
                        @DELSERIE_NF
            END
        CLOSE CURI_LOJA_NOTA_FISCAL_ITEM2170
        CLOSE CURD_LOJA_NOTA_FISCAL_ITEM2170
        DEALLOCATE CURI_LOJA_NOTA_FISCAL_ITEM2170
        DEALLOCATE CURD_LOJA_NOTA_FISCAL_ITEM2170
        END
    END
 
-- LOJA_NOTA_FISCAL_IMPOSTO - PARENT UPDATE CASCADE
    IF  UPDATE(CODIGO_FILIAL) OR
        UPDATE(NF_NUMERO) OR
        UPDATE(SERIE_NF)
    BEGIN  
        IF EXISTS ( SELECT * 
                FROM INSERTED 
                    LEFT JOIN DELETED ON
                        DELETED.CODIGO_FILIAL = INSERTED.CODIGO_FILIAL AND
                    DELETED.NF_NUMERO = INSERTED.NF_NUMERO AND
                    DELETED.SERIE_NF = INSERTED.SERIE_NF
                WHERE   DELETED.CODIGO_FILIAL IS NULL  OR 
                DELETED.NF_NUMERO IS NULL  OR 
                DELETED.SERIE_NF IS NULL
            )
        BEGIN
            DECLARE CURI_LOJA_NOTA_FISCAL_IMPOSTO2171 CURSOR FOR
                SELECT  CODIGO_FILIAL ,  
                NF_NUMERO ,  
                SERIE_NF
                FROM INSERTED
            DECLARE CURD_LOJA_NOTA_FISCAL_IMPOSTO2171 CURSOR FOR
                SELECT  CODIGO_FILIAL ,  
                NF_NUMERO ,  
                SERIE_NF
                FROM DELETED
            OPEN CURI_LOJA_NOTA_FISCAL_IMPOSTO2171
            OPEN CURD_LOJA_NOTA_FISCAL_IMPOSTO2171
            FETCH NEXT FROM CURI_LOJA_NOTA_FISCAL_IMPOSTO2171
                    INTO    @INSCODIGO_FILIAL ,  
                    @INSNF_NUMERO ,  
                    @INSSERIE_NF
            FETCH NEXT FROM CURD_LOJA_NOTA_FISCAL_IMPOSTO2171
                    INTO    @DELCODIGO_FILIAL ,  
                    @DELNF_NUMERO ,  
                    @DELSERIE_NF
            WHILE @@FETCH_STATUS = 0
            BEGIN
                UPDATE LOJA_NOTA_FISCAL_IMPOSTO
                SET CODIGO_FILIAL = @INSCODIGO_FILIAL, 
                NF_NUMERO = @INSNF_NUMERO, 
                SERIE_NF = @INSSERIE_NF
                WHERE   CODIGO_FILIAL = @DELCODIGO_FILIAL AND
                NF_NUMERO = @DELNF_NUMERO AND
                SERIE_NF = @DELSERIE_NF
 
                FETCH NEXT FROM CURI_LOJA_NOTA_FISCAL_IMPOSTO2171
                        INTO    @INSCODIGO_FILIAL ,  
                        @INSNF_NUMERO ,  
                        @INSSERIE_NF
                FETCH NEXT FROM CURD_LOJA_NOTA_FISCAL_IMPOSTO2171
                        INTO    @DELCODIGO_FILIAL ,  
                        @DELNF_NUMERO ,  
                        @DELSERIE_NF
            END
        CLOSE CURI_LOJA_NOTA_FISCAL_IMPOSTO2171
        CLOSE CURD_LOJA_NOTA_FISCAL_IMPOSTO2171
        DEALLOCATE CURI_LOJA_NOTA_FISCAL_IMPOSTO2171
        DEALLOCATE CURD_LOJA_NOTA_FISCAL_IMPOSTO2171
        END
    END
     
     /*SS01*/
    declare @strCodigoFilialRef     varchar(6),
            @StrNfNumeroRef         varchar(15),
            @StrSerieNfRef          varchar(6),
            @StrChaveNfeRef         varchar(44),
            @StrMensagemErroSefaz   varchar(max),
            @StrRomaneioProdutoRef  varchar(15),
            @strFilialRef           varchar(25)
     
    DECLARE CurRecalculoNotaReferenciadaNFe CURSOR FOR
    SELECT  A.CODIGO_FILIAL,
            A.NF_NUMERO,
            A.SERIE_NF,
            A.CHAVE_NFE 
        FROM INSERTED A (nolock)
        INNER JOIN LOJA_NOTA_FISCAL_ITEM I(nolock)
            ON I.NF_NUMERO = A.NF_NUMERO AND A.SERIE_NF = I.SERIE_NF AND A.CODIGO_FILIAL = I.CODIGO_FILIAL 
        INNER JOIN LOJAS_NATUREZA_OPERACAO NAT (nolock)
            ON NAT.NATUREZA_OPERACAO_CODIGO = A.NATUREZA_OPERACAO_CODIGO
        INNER JOIN CTB_LX_TIPO_OPERACAO CT (nolock)
            ON NAT.CTB_TIPO_OPERACAO = CT.CTB_TIPO_OPERACAO
        INNER JOIN DELETED B(nolock)
            ON A.NF_NUMERO = B.NF_NUMERO AND A.SERIE_NF = B.SERIE_NF AND A.CODIGO_FILIAL = B.CODIGO_FILIAL 
        WHERE A.STATUS_NFE NOT IN (0,5,49,59,70)
			AND I.CODIGO_FISCAL_OPERACAO NOT IN ('1913','2913','5949','6949', '6921', '5921','5916','6916') 
			AND (CT.TIPO_OPERACAO IN('D','E') OR I.CODIGO_FISCAL_OPERACAO IN ('5209','6209'))
        GROUP BY A.CODIGO_FILIAL, A.NF_NUMERO, A.SERIE_NF, A.CHAVE_NFE 
         
    OPEN CurRecalculoNotaReferenciadaNFe
    FETCH NEXT FROM CurRecalculoNotaReferenciadaNFe INTO @strCodigoFilialRef, @StrNfNumeroRef, @StrSerieNfRef, @StrChaveNfeRef      
     
    WHILE @@FETCH_STATUS = 0
    BEGIN
 
        update LOJA_NOTA_FISCAL set FIN_EMISSAO_NFE = 4 where CODIGO_FILIAL = @strCodigoFilialRef and NF_NUMERO = @StrNfNumeroRef and SERIE_NF = @StrSerieNfRef AND FIN_EMISSAO_NFE <> 4
         
        /*Se For Uma Saida Chama a procedure de recalculo de Saidas*/
        if exists (select a.romaneio_produto 
                        FROM LOJA_SAIDAS A(nolock)
                        INNER JOIN LOJAS_VAREJO B(nolock)
                            ON A.FILIAL = B.FILIAL
                        INNER JOIN LOJA_NOTA_FISCAL C(nolock)
                            ON A.NUMERO_NF_TRANSFERENCIA = C.NF_NUMERO AND B.CODIGO_FILIAL = C.CODIGO_FILIAL AND A.SERIE_NF = C.SERIE_NF 
                        LEFT JOIN LOJA_SAIDAS_ORIGEM D(NOLOCK)
                            on a.romaneio_produto = d.romaneio_produto and a.filial = d.filial
                        where c.CODIGO_FILIAL = @strCodigoFilialRef 
                            and c.NF_NUMERO = @StrNfNumeroRef 
                            and c.SERIE_NF = @StrSerieNfRef
                            and D.ROMANEIO_PRODUTO IS NULL)
            begin
                select @StrRomaneioProdutoRef = a.romaneio_produto,
                       @strFilialRef = a.FILIAL  
                            FROM LOJA_SAIDAS A(nolock)
                            INNER JOIN LOJAS_VAREJO B(nolock)
                                ON A.FILIAL = B.FILIAL
                            INNER JOIN LOJA_NOTA_FISCAL C(nolock)
                                ON A.NUMERO_NF_TRANSFERENCIA = C.NF_NUMERO AND B.CODIGO_FILIAL = C.CODIGO_FILIAL AND A.SERIE_NF = C.SERIE_NF 
                            where c.CODIGO_FILIAL = @strCodigoFilialRef 
                                and c.NF_NUMERO = @StrNfNumeroRef 
                                and c.SERIE_NF = @StrSerieNfRef
                 
                EXECUTE PROC_SS_LOJA_SAIDA_ORIGEM @pFilial = @strFilialRef, @pRomaneioSaida = @StrRomaneioProdutoRef        
            end
         
        if exists(select A.NF_NUMERO
                    FROM LOJA_NOTA_FISCAL A(nolock)
                    INNER JOIN LOJA_VENDA_PGTO B(nolock)
                        ON A.CODIGO_FILIAL = B.CODIGO_FILIAL AND A.NF_NUMERO = B.NUMERO_FISCAL_TROCA AND A.SERIE_NF = B.SERIE_NF_ENTRADA 
                    INNER JOIN LOJA_VENDA C(nolock)
                        ON C.CODIGO_FILIAL = B.CODIGO_FILIAL AND C.LANCAMENTO_CAIXA = B.LANCAMENTO_CAIXA AND C.TERMINAL = B.TERMINAL 
                    INNER JOIN LOJA_VENDA_TROCA D(nolock)
                        ON D.CODIGO_FILIAL = C.CODIGO_FILIAL AND D.TICKET = C.TICKET AND D.DATA_VENDA = C.DATA_VENDA 
                    LEFT JOIN LOJA_VENDA_TROCA_ORIGEM E(nolock)
                        ON E.CODIGO_FILIAL = D.CODIGO_FILIAL AND E.TICKET = D.TICKET AND E.DATA_VENDA = D.DATA_VENDA AND E.ITEM =D.ITEM 
                    where a.CODIGO_FILIAL = @strCodigoFilialRef 
                        and a.NF_NUMERO = @StrNfNumeroRef 
                        and a.SERIE_NF = @StrSerieNfRef
                        and e.CODIGO_FILIAL is null )
        begin
            execute PROC_SS_LOJA_VENDA_TROCA_ORIGEM @prChaveNFe = @StrChaveNfeRef 
        end
         
        FETCH NEXT FROM CurRecalculoNotaReferenciadaNFe INTO @strCodigoFilialRef, @StrNfNumeroRef, @StrSerieNfRef, @StrChaveNfeRef      
    END
    CLOSE CurRecalculoNotaReferenciadaNFe
    DEALLOCATE CurRecalculoNotaReferenciadaNFe
     
    /*Caso tenha uma nota de venda relacioanada ao ticket de origem relaciona a chave de origem.*/  
    UPDATE A
        SET A.CHAVE_NFE_ORIGEM = D.CHAVE_NFE 
    FROM LOJA_VENDA_TROCA_ORIGEM A
    INNER JOIN LOJA_VENDA B
        ON A.TICKET_ORIGEM = B.TICKET AND A.CODIGO_FILIAL_ORIGEM = B.CODIGO_FILIAL AND A.DATA_VENDA_ORIGEM = B.DATA_VENDA 
    INNER JOIN LOJA_VENDA_PGTO C
        ON C.TERMINAL = B.TERMINAL AND C.LANCAMENTO_CAIXA = B.LANCAMENTO_CAIXA AND C.CODIGO_FILIAL = B.CODIGO_FILIAL 
    INNER JOIN LOJA_NOTA_FISCAL D
        ON D.NF_NUMERO = C.NUMERO_FISCAL_VENDA AND D.CODIGO_FILIAL = C.CODIGO_FILIAL AND D.SERIE_NF = C.SERIE_NF_SAIDA 
    INNER JOIN inserted E
        ON D.NF_NUMERO = E.NF_NUMERO AND D.CODIGO_FILIAL = E.CODIGO_FILIAL AND D.SERIE_NF = E.SERIE_NF 
    WHERE CHAVE_NFE_ORIGEM IS NULL
        AND D.CHAVE_NFE IS NOT NULL
         
    /*SS01*/
 
     ---LINX ETL--------------------------------------------------------------------------------  
 
    -- #2# - Trecho comentado e substituído
    --  IF (SELECT CASE WHEN APP_NAME() LIKE '%LinxETL%' THEN 1 ELSE 0 END) = 0
    --BEGIN
    --       UPDATE  LOJA_NOTA_FISCAL  
    --        SET  LX_STATUS_NOTA_FISCAL = 1, DATA_PARA_TRANSFERENCIA = INSERTED.DATA_PARA_TRANSFERENCIA    
    --        FROM  LOJA_NOTA_FISCAL, INSERTED  
    --        WHERE LOJA_NOTA_FISCAL.CODIGO_FILIAL = INSERTED.CODIGO_FILIAL AND   
    --          LOJA_NOTA_FISCAL.NF_NUMERO = INSERTED.NF_NUMERO AND   
    --          LOJA_NOTA_FISCAL.SERIE_NF = INSERTED.SERIE_NF    
    -- END
 
    -- #2#
    IF NOT UPDATE(LX_STATUS_NOTA_FISCAL)
    UPDATE  LOJA_NOTA_FISCAL
    SET     LX_STATUS_NOTA_FISCAL = 1
    FROM    LOJA_NOTA_FISCAL, INSERTED
    WHERE   LOJA_NOTA_FISCAL.CODIGO_FILIAL = INSERTED.CODIGO_FILIAL AND  
            LOJA_NOTA_FISCAL.NF_NUMERO = INSERTED.NF_NUMERO AND  
            LOJA_NOTA_FISCAL.SERIE_NF = INSERTED.SERIE_NF    
 
     -----------------------------------------------------------------------------------------------------  
 
    ---DATA PARA TRANSFERENCIA---------------------------------------------------------------------------
    IF NOT UPDATE(DATA_PARA_TRANSFERENCIA)
    UPDATE  LOJA_NOTA_FISCAL
    SET     DATA_PARA_TRANSFERENCIA = GETDATE()
    FROM    LOJA_NOTA_FISCAL, INSERTED
    WHERE   LOJA_NOTA_FISCAL.CODIGO_FILIAL = INSERTED.CODIGO_FILIAL AND
            LOJA_NOTA_FISCAL.NF_NUMERO = INSERTED.NF_NUMERO AND
            LOJA_NOTA_FISCAL.SERIE_NF = INSERTED.SERIE_NF
            AND (INSERTED.DATA_PARA_TRANSFERENCIA IS NULL
            OR LOJA_NOTA_FISCAL.DATA_PARA_TRANSFERENCIA = INSERTED.DATA_PARA_TRANSFERENCIA) 
    -----------------------------------------------------------------------------------------------------
     
    /* SS04 */ /* SS07 */
    IF EXISTS (SELECT 1 FROM INSERTED WHERE CHAVE_NFE IS NULL)
    BEGIN
        DECLARE @CNPJ_EMITENTE VARCHAR(14), @CIDADE_EMITENTE VARCHAR(35), @UF_EMITENTE CHAR(2), @AAMM_EMISSAO CHAR(4), @MODELO CHAR(2), @TIPO_EMISSAO TINYINT, @VERSAO_CHAVE_NFE CHAR(6), @CODIGO_UF_IBGE CHAR(2)
        DECLARE @CHAVE_NFE TABLE (CHAVE_NFE VARCHAR(44))
 
        /*Seleciona todas as notas que voltaram com o Status 4 que sejam de devolução */
        DECLARE CurGeraChaveNFE CURSOR FOR
        SELECT a.NF_NUMERO, a.SERIE_NF, a.codigo_filial, B.FILIAL FROM INSERTED A INNER JOIN LOJAS_VAREJO B  ON A.CODIGO_FILIAL = B.CODIGO_FILIAL 
                     
        OPEN CurGeraChaveNFE
        FETCH NEXT FROM CurGeraChaveNFE INTO @StrNfNumeroRef, @StrSerieNfRef,@strCodigoFilialRef, @strFilialRef
         
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT  @CNPJ_EMITENTE = NFE.CNPJ_EMITENTE,  
                    @CIDADE_EMITENTE  = NFE.CIDADE_EMITENTE,
                    @UF_EMITENTE =  NFE.UF_EMITENTE,
                    @AAMM_EMISSAO = SUBSTRING(CONVERT(VARCHAR(20),NFE.EMISSAO,112),3,4),
                    @TIPO_EMISSAO = NFE.TIPO_EMISSAO_NFE,
                    @VERSAO_CHAVE_NFE = VERSAO_LAYOUT_NFE,
                    @CODIGO_UF_IBGE = SUBSTRING(NFE.EMITENTE_COD_MUNICIPIO_IBGE,1,2)
            FROM  W_IMPRESSAO_NFE NFE
            WHERE  NF = @StrNfNumeroRef  AND
                   SERIE_NF = @StrSerieNfRef AND
                   FILIAL = @strFilialRef
 
            SELECT @MODELO = RTRIM(ES.NUMERO_MODELO_FISCAL)
                FROM SERIES_NF SN 
                INNER JOIN CTB_ESPECIE_SERIE ES 
                    ON SN.ESPECIE_SERIE = ES.ESPECIE_SERIE 
            WHERE SERIE_NF = @StrSerieNfRef
             
            INSERT INTO @CHAVE_NFE
            EXEC LX_GERA_CHAVE_NFE_GENERICA @StrNfNumeroRef, @StrSerieNfRef, @CNPJ_EMITENTE, @CIDADE_EMITENTE, @UF_EMITENTE, @AAMM_EMISSAO, @MODELO, @TIPO_EMISSAO, @VERSAO_CHAVE_NFE, @CODIGO_UF_IBGE
             
            UPDATE LOJA_NOTA_FISCAL SET CHAVE_NFE = (SELECT CHAVE_NFE FROM @CHAVE_NFE) WHERE  NF_NUMERO = @StrNfNumeroRef  AND SERIE_NF = @StrSerieNfRef AND CODIGO_FILIAL = @strCodigoFilialRef 
             
            delete from @CHAVE_NFE
                 
            FETCH NEXT FROM CurGeraChaveNFE INTO @StrNfNumeroRef, @StrSerieNfRef,@strCodigoFilialRef, @strFilialRef
        END
        CLOSE CurGeraChaveNFE
        DEALLOCATE CurGeraChaveNFE
    END
    /* SS04 */ /* SS07 */
     
    /* SS05 */
    if exists (select nf_numero from inserted WHERE STATUS_NFE IN (49,59,70)  )
    begin
    /*Apaga o numero da nota fiscal de venda*/
        update b
            set b.NUMERO_FISCAL_VENDA  = null,
                b.SERIE_NF_SAIDA = null
        FROM inserted A
        INNER JOIN LOJA_VENDA_PGTO B
            ON A.CODIGO_FILIAL = B.CODIGO_FILIAL AND A.NF_NUMERO = B.NUMERO_FISCAL_VENDA AND A.SERIE_NF = B.SERIE_NF_SAIDA 
        INNER JOIN LOJA_VENDA C
            ON B.CODIGO_FILIAL = C.CODIGO_FILIAL AND B.TERMINAL = C.TERMINAL AND B.LANCAMENTO_CAIXA = C.LANCAMENTO_CAIXA
        WHERE A.STATUS_NFE IN (49,59,70)
            AND C.DATA_HORA_CANCELAMENTO IS NULL
             
        /*Apaga o numero da nota fiscal de troca*/
        update b
            set b.NUMERO_FISCAL_TROCA  = null,
                b.SERIE_NF_ENTRADA = null
        FROM inserted A
        INNER JOIN LOJA_VENDA_PGTO B
            ON A.CODIGO_FILIAL = B.CODIGO_FILIAL AND A.NF_NUMERO = B.NUMERO_FISCAL_TROCA  AND A.SERIE_NF = B.SERIE_NF_ENTRADA  
        INNER JOIN LOJA_VENDA C
            ON B.CODIGO_FILIAL = C.CODIGO_FILIAL AND B.TERMINAL = C.TERMINAL AND B.LANCAMENTO_CAIXA = C.LANCAMENTO_CAIXA
        WHERE A.STATUS_NFE IN (49,59,70)
            AND C.DATA_HORA_CANCELAMENTO IS NULL
                 
        /*Apaga o numero da nota fiscal de cancelamento*/
        update b
            set b.NUMERO_FISCAL_CANCELAMENTO  = null,
                b.SERIE_NF_CANCELAMENTO = null
        FROM inserted A
        INNER JOIN LOJA_VENDA_PGTO B
            ON A.CODIGO_FILIAL = B.CODIGO_FILIAL AND A.NF_NUMERO = B.NUMERO_FISCAL_CANCELAMENTO  AND A.SERIE_NF = B.SERIE_NF_CANCELAMENTO 
        WHERE A.STATUS_NFE IN (49,59,70)
        
        /*SS09 - Apaga Os Valores da Nota Fiscal*/
        UPDATE a 
			SET a.QTDE_TOTAL =0, 
				a.VALOR_TOTAL_ITENS=0, 
				a.VALOR_TOTAL=0, 
				a.NOTA_CANCELADA=1, 
				a.VALOR_CANCELADO = case when a.VALOR_TOTAL > 0 then a.VALOR_TOTAL else a.VALOR_CANCELADO end , 
				a.QTDE_CANCELADA  = case when a.QTDE_TOTAL  > 0 then a.QTDE_TOTAL  else a.QTDE_CANCELADA  end 
		from LOJA_NOTA_FISCAL a
		inner join inserted b
			on a.CODIGO_FILIAL = b.CODIGO_FILIAL and a.SERIE_NF = b.SERIE_NF and a.NF_NUMERO = b.NF_NUMERO 
		WHERE B.STATUS_NFE IN (49,59,70)
			AND (a.QTDE_TOTAL <> 0 or a.VALOR_TOTAL_ITENS <> 0 or a.VALOR_TOTAL <> 0 or a.NOTA_CANCELADA <> 1)
			
		UPDATE a
			SET a.QTDE_ITEM=0,
				a.VALOR_ITEM=0,
				a.PRECO_UNITARIO=0,
				a.DESCONTO_ITEM=0 
		from LOJA_NOTA_FISCAL_ITEM A
		inner join inserted b
			on a.CODIGO_FILIAL = b.CODIGO_FILIAL and a.SERIE_NF = b.SERIE_NF and a.NF_NUMERO = b.NF_NUMERO 
		WHERE B.STATUS_NFE IN (49,59,70)
			And (A.QTDE_ITEM <> 0 OR A.VALOR_ITEM <> 0 OR A.PRECO_UNITARIO <> 0 OR A.DESCONTO_ITEM <>0 )

		UPDATE  A
			SET A.TAXA_IMPOSTO  = 0, 
				A.VALOR_IMPOSTO = 0,
				A.BASE_IMPOSTO  = 0 
		FROM LOJA_NOTA_FISCAL_IMPOSTO A
		inner join inserted b
			on a.CODIGO_FILIAL = b.CODIGO_FILIAL and a.SERIE_NF = b.SERIE_NF and a.NF_NUMERO = b.NF_NUMERO 
		WHERE B.STATUS_NFE IN (49,59,70)
			and (A.TAXA_IMPOSTO <> 0 OR A.VALOR_IMPOSTO <> 0 OR A.BASE_IMPOSTO <> 0 )
    end
    /* SS05 */  
    /* SS09 */
    if exists (select a.NF_NUMERO 
				from inserted a
				inner join deleted b
					on a.CODIGO_FILIAL = b.CODIGO_FILIAL and a.NF_NUMERO = b.NF_NUMERO and a.SERIE_NF = b.SERIE_NF
				where	A.status_nfe not in (0,49,59,70)
						and ((a.QTDE_TOTAL = 0 AND B.QTDE_TOTAL <> 0) OR
							(a.VALOR_TOTAL_ITENS = 0 AND B.VALOR_TOTAL_ITENS <> 0) OR
							(a.VALOR_TOTAL = 0 AND B.VALOR_TOTAL <> 0) OR
							(a.NOTA_CANCELADA = 0 AND B.NOTA_CANCELADA = 1))
				)
		begin
			update d
				set d.QTDE_TOTAL			= b.QTDE_TOTAL,
					d.VALOR_TOTAL_ITENS		= b.VALOR_TOTAL_ITENS,
					d.VALOR_TOTAL			= b.VALOR_TOTAL,
					d.NOTA_CANCELADA		= b.NOTA_CANCELADA 				
			from inserted a
			inner join deleted b
				on a.CODIGO_FILIAL = b.CODIGO_FILIAL and a.NF_NUMERO = b.NF_NUMERO and a.SERIE_NF = b.SERIE_NF 
			inner join LOJA_NOTA_FISCAL c
				on a.CODIGO_FILIAL = c.CODIGO_FILIAL and a.SERIE_NF = c.SERIE_NF and a.NF_NUMERO = c.NF_NUMERO 
			inner join LOJA_NOTA_FISCAL d
				on a.CODIGO_FILIAL = d.CODIGO_FILIAL and a.NF_NUMERO = d.NF_NUMERO and a.SERIE_NF = d.SERIE_NF 
			where c.status_nfe not in (0,49,59,70)
				and(	(a.QTDE_TOTAL = 0 AND B.QTDE_TOTAL <> 0) OR
						(a.VALOR_TOTAL_ITENS = 0 AND B.VALOR_TOTAL_ITENS <> 0) OR
						(a.VALOR_TOTAL = 0 AND B.VALOR_TOTAL <> 0) OR
						(a.NOTA_CANCELADA = 0 AND B.NOTA_CANCELADA = 1) 
					)
		END

     
    RETURN
ERROR:
    raiserror(@errmsg, 18, 1)
    ROLLBACK TRANSACTION
END


