ALTER TRIGGER [dbo].[LXI_LOJA_NOTA_FISCAL] ON [dbo].[LOJA_NOTA_FISCAL] FOR INSERT NOT FOR REPLICATION AS
-- FELIPE SILVA   - (SS05) - 13/01/2016 - BLOQUEIA PARA NÃO SALVAR NUMERO DA NOTA EM BRANCO.
-- FELIPE SILVA   - (SS04) - 11/01/2016 - BLOQUEIA A ALTERA??O CASO O NUMERO DA NOTA N?O EST? NA COMPOSI??O DA CHAVE ALTERADA.
-- FELIPE SILVA   - (SS03) - 05/10/2015 - INCLUIDO UPDATE NO CAMPO SS_ID_MAQUINA PARA SALVAR A IDENTIFICA??O DA MAQUINA QUE FEZ A TRANSA??O PELO LINX.
-- TIAGO CARVALHO - (SS02) - 23/06/2015 - ALTERADO PARA REFERENCIAR A CHAVE_NFE DO NFCe quando ele for autorizado, muitos estao ficando com a chave null no inicio.
-- TIAGO CARVALHO - (SS01) - 10/05/2015 - Corrigido o join que era feito para conseguir atualizar a nota fiscal na hora da emissao
-- TIAGO CARVALHO - (SS01) - 23/04/2015 - ALTERADO PARA ASSOCIAR A NOTA FISCAL A UMA ORIGEM quando nota de troca ou saida e nao existir nota associada.
-- INSERT Trigger On LOJA_NOTA_FISCAL
Begin
    Declare @numrows    Int,
        @nullcnt    Int,
        @validcnt   Int,
        @insCODIGO_FILIAL char(6), 
        @insNF_NUMERO char(15), 
        @insSERIE_NF char(6), 
        @errno   Int,
        @errmsg  varchar(255)
 
    Select @numrows = @@rowcount
     
    /*SS04*/
    IF  UPDATE(CHAVE_NFE)
    BEGIN
        IF EXISTS (SELECT 1
        FROM INSERTED
        WHERE   SUBSTRING(INSERTED.CHAVE_NFE , 26, 9) <> RIGHT('000000000' + LTRIM(RTRIM(INSERTED.NF_NUMERO)), 9) AND ISNULL(inserted.CHAVE_NFE, '') <> '')
 
        BEGIN
            SELECT  @ERRNO  = 30002,
                @ERRMSG = 'IMPOSSIVEL ATUALIZAR LOJA_NOTA_FISCAL PORQUE EXISTEM ALTERACOES NO CAMPO CHAVE_NFE QUE NAO CONTEM O NUMERO DA NOTA CORRESPONDENTE EM SUA COMPOSICAO.'
            GOTO ERROR
        END
    END
    /*FIM SS04*/
    
    /*SS05*/
        IF EXISTS (SELECT 1 FROM INSERTED WHERE LTRIM(RTRIM(NF_NUMERO)) = '')
        BEGIN
            SELECT  @ERRNO  = 30002,
                @ERRMSG = 'IMPOSSIVEL SALVAR LOJA_NOTA_FISCAL PORQUE O NUMERO DA NOTA NÃO PODE FICAR EM BRANCO.'
            GOTO ERROR
        END
    /*FIM SS05*/
 
-- LOJAS_VAREJO - Child Insert Restrict
    IF  UPDATE(CODIGO_FILIAL)
    Begin
        SELECT @NullCnt = 0
        SELECT @ValidCnt = count(*)
        FROM Inserted, LOJAS_VAREJO
        WHERE   INSERTED.CODIGO_FILIAL = LOJAS_VAREJO.CODIGO_FILIAL
 
        If @validcnt + @nullcnt != @numrows
        Begin
            Select  @errno  = 30002,
                @errmsg = 'Imposs?vel Incluir #LOJA_NOTA_FISCAL #porque #LOJAS_VAREJO #nao existe.'
            GoTo Error
        End
    End
 
-- CLIENTES_VAREJO - Child Insert Restrict
    IF  UPDATE(CODIGO_CLIENTE)
    Begin
        SELECT @NullCnt = 0
        SELECT @ValidCnt = count(*)
        FROM Inserted, CLIENTES_VAREJO
        WHERE   INSERTED.CODIGO_CLIENTE = CLIENTES_VAREJO.CODIGO_CLIENTE
 
        SELECT @NullCnt = count(*)
        FROM Inserted 
        WHERE   INSERTED.CODIGO_CLIENTE IS NULL
 
        If @validcnt + @nullcnt != @numrows
        Begin
            Select  @errno  = 30002,
                @errmsg = 'Imposs?vel Incluir #LOJA_NOTA_FISCAL #porque #CLIENTES_VAREJO #nao existe.'
            GoTo Error
        End
    End
 
-- LOJAS_VAREJO - Child Insert Restrict
    IF  UPDATE(COD_CLIFOR)
    Begin
        SELECT @NullCnt = 0
        SELECT @ValidCnt = count(*)
        FROM Inserted, CADASTRO_CLI_FOR
        WHERE   INSERTED.COD_CLIFOR = CADASTRO_CLI_FOR.COD_CLIFOR
 
        SELECT @NullCnt = count(*)
        FROM Inserted 
        WHERE   INSERTED.COD_CLIFOR IS NULL
 
        If @validcnt + @nullcnt != @numrows
        Begin
            Select  @errno  = 30002,
                @errmsg = 'Imposs?vel Incluir #LOJA_NOTA_FISCAL #porque #CADASTRO_CLI_FOR #nao existe.'
            GoTo Error
        End
    End
 
-- LOJAS_NATUREZA_OPERACAO - Child Insert Restrict
    IF  UPDATE(NATUREZA_OPERACAO_CODIGO)
    Begin
        SELECT @NullCnt = 0
        SELECT @ValidCnt = count(*)
        FROM Inserted, LOJAS_NATUREZA_OPERACAO
        WHERE   INSERTED.NATUREZA_OPERACAO_CODIGO = LOJAS_NATUREZA_OPERACAO.NATUREZA_OPERACAO_CODIGO
 
        If @validcnt + @nullcnt != @numrows
        Begin
            Select  @errno  = 30002,
                @errmsg = 'Imposs?vel Incluir #LOJA_NOTA_FISCAL #porque #LOJAS_NATUREZA_OPERACAO #nao existe.'
            GoTo Error
        End
    End
     
    /*SS03*/
    UPDATE B 
       SET B.SS_ID_MAQUINA = HOST_NAME()
      FROM INSERTED A
    INNER JOIN LOJA_NOTA_FISCAL B 
    ON A.CODIGO_FILIAL = B.CODIGO_FILIAL
    AND A.NF_NUMERO = B.NF_NUMERO
    AND A.SERIE_NF = B.SERIE_NF 
    /*SS03*/
     
     
    /*SS01*/
    declare @strCodigoFilialRef     varchar(6),
            @StrNfNumeroRef         varchar(15),
            @StrSerieNfRef          varchar(6),
            @StrChaveNfeRef         varchar(44),
            @StrMensagemErroSefaz   varchar(max),
            @StrRomaneioProdutoRef  varchar(15),
            @strFilialRef           varchar(25)
 
    /*Seleciona todas as notas que voltaram com o Status 4 que sejam de devolu?ao */
    DECLARE CurRecalculoNotaReferenciadaNFe CURSOR FOR
    SELECT  A.CODIGO_FILIAL,
            A.NF_NUMERO,
            A.SERIE_NF,
            B.CHAVE_NFE 
        FROM INSERTED A (nolock)
        INNER JOIN LOJA_NOTA_FISCAL B 
            ON B.NF_NUMERO = A.NF_NUMERO AND B.SERIE_NF = A.SERIE_NF AND B.CODIGO_FILIAL = A.CODIGO_FILIAL 
        INNER JOIN LOJA_NOTA_FISCAL_ITEM I(nolock)
            ON I.NF_NUMERO = A.NF_NUMERO AND A.SERIE_NF = I.SERIE_NF AND A.CODIGO_FILIAL = I.CODIGO_FILIAL 
        INNER JOIN LOJAS_NATUREZA_OPERACAO NAT (nolock)
            ON NAT.NATUREZA_OPERACAO_CODIGO = A.NATUREZA_OPERACAO_CODIGO
        INNER JOIN CTB_LX_TIPO_OPERACAO CT (nolock)
            ON NAT.CTB_TIPO_OPERACAO = CT.CTB_TIPO_OPERACAO
        WHERE I.CODIGO_FISCAL_OPERACAO NOT IN ('1913','2913','5949','6949','5916','6916') AND (CT.TIPO_OPERACAO IN('D','E') OR I.CODIGO_FISCAL_OPERACAO IN ('5209','6209'))
        GROUP BY A.CODIGO_FILIAL, A.NF_NUMERO, A.SERIE_NF, B.CHAVE_NFE 
         
    OPEN CurRecalculoNotaReferenciadaNFe
    FETCH NEXT FROM CurRecalculoNotaReferenciadaNFe INTO @strCodigoFilialRef, @StrNfNumeroRef, @StrSerieNfRef, @StrChaveNfeRef      
     
    WHILE @@FETCH_STATUS = 0
    BEGIN
        /*Atualiza a Finalidade de Emissao da NFe para 4-devolu?ao se o erro for de nota de devolu?ao sem finalidade de devolu?ao*/
        update LOJA_NOTA_FISCAL set FIN_EMISSAO_NFE = 4 where CODIGO_FILIAL = @strCodigoFilialRef and NF_NUMERO = @StrNfNumeroRef and SERIE_NF = @StrSerieNfRef and FIN_EMISSAO_NFE <> 4 
       
        /*Se For Uma Saida Chama a procedure de recalculo de Saidas*/
        if exists (select a.romaneio_produto 
                        FROM LOJA_SAIDAS A(nolock)
                        INNER JOIN LOJAS_VAREJO B(nolock)
                            ON A.FILIAL = B.FILIAL
                        INNER JOIN LOJA_NOTA_FISCAL C(nolock)
                            ON A.NUMERO_NF_TRANSFERENCIA = C.NF_NUMERO AND B.CODIGO_FILIAL = C.CODIGO_FILIAL AND A.SERIE_NF = C.SERIE_NF 
                        LEFT JOIN LOJA_SAIDAS_ORIGEM D(NOLOCK)
                            ON A.ROMANEIO_PRODUTO = D.ROMANEIO_PRODUTO AND A.FILIAL = D.FILIAL 
                        where c.CODIGO_FILIAL = @strCodigoFilialRef 
                            and c.NF_NUMERO = @StrNfNumeroRef 
                            and c.SERIE_NF = @StrSerieNfRef
                            and d.ROMANEIO_PRODUTO is null  )
        begin
            select @StrRomaneioProdutoRef = null
             
            select @StrRomaneioProdutoRef = a.romaneio_produto,
                   @strFilialRef = a.FILIAL  
                        FROM LOJA_SAIDAS A(nolock)
                        INNER JOIN LOJAS_VAREJO B(nolock)
                            ON A.FILIAL = B.FILIAL
                        INNER JOIN LOJA_NOTA_FISCAL C(nolock)
                            ON A.NUMERO_NF_TRANSFERENCIA = C.NF_NUMERO AND B.CODIGO_FILIAL = C.CODIGO_FILIAL AND A.SERIE_NF = C.SERIE_NF 
                        LEFT JOIN LOJA_SAIDAS_ORIGEM D(NOLOCK)
                            ON A.ROMANEIO_PRODUTO = D.ROMANEIO_PRODUTO AND A.FILIAL = D.FILIAL 
                        where c.CODIGO_FILIAL = @strCodigoFilialRef 
                            and c.NF_NUMERO = @StrNfNumeroRef 
                            and c.SERIE_NF = @StrSerieNfRef
                            and d.ROMANEIO_PRODUTO is null
             
            if @StrRomaneioProdutoRef is not null
                begin
                    EXECUTE PROC_SS_LOJA_SAIDA_ORIGEM @pFilial = @strFilialRef, @pRomaneioSaida = @StrRomaneioProdutoRef        
                end
             
        end
            else
                begin
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
 
    return
Error:
    raiserror(@errmsg, 18, 1)
    rollback transaction
end