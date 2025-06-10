ALTER TRIGGER [dbo].[LXI_LOJA_SAIDAS_PRODUTO] ON [dbo].[LOJA_SAIDAS_PRODUTO] FOR INSERT NOT FOR REPLICATION AS
-- INSERT trigger on LOJA_SAIDAS_PRODUTO
begin
  declare  @numrows int,
           @nullcnt int,
           @validcnt int,
           @insROMANEIO_PRODUTO char(15), 
           @insFILIAL varchar(25), 
           @insPRODUTO char(12), 
           @insCOR_PRODUTO char(10),
           @errno   int,
           @errmsg  varchar(255)

  select @numrows = @@rowcount

/* PRODUTO_CORES R/1191 LOJA_SAIDAS_PRODUTO ON CHILD INSERT RESTRICT */
  if 
     update(PRODUTO) or 
     update(COR_PRODUTO)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,PRODUTO_CORES
     where 
           inserted.PRODUTO = PRODUTO_CORES.PRODUTO and
           inserted.COR_PRODUTO = PRODUTO_CORES.COR_PRODUTO
    
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_SAIDAS_PRODUTO" porque "PRODUTO_CORES" não existe.'
      goto error
    end
  end

/* LOJA_SAIDAS R/1190 LOJA_SAIDAS_PRODUTO ON CHILD INSERT RESTRICT */
  if 
     update(ROMANEIO_PRODUTO) or 
     update(FILIAL)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_SAIDAS
     where 
           inserted.ROMANEIO_PRODUTO = LOJA_SAIDAS.ROMANEIO_PRODUTO and
           inserted.FILIAL = LOJA_SAIDAS.FILIAL
    
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_SAIDAS_PRODUTO" porque "LOJA_SAIDAS" não existe.'
      goto error
    end
  end

--- Verifica bloqueio por contagem ------------------------------------------------------------------------------
	IF EXISTS (SELECT 
			LOJA_SAIDAS.EMISSAO
		FROM 
			Inserted 
			INNER JOIN LOJA_SAIDAS ON Inserted.FILIAL = LOJA_SAIDAS.FILIAL AND Inserted.ROMANEIO_PRODUTO = LOJA_SAIDAS.ROMANEIO_PRODUTO
			INNER JOIN ESTOQUE_PRODUTOS ON ESTOQUE_PRODUTOS.FILIAL = Inserted.FILIAL AND ESTOQUE_PRODUTOS.PRODUTO = Inserted.PRODUTO AND ESTOQUE_PRODUTOS.COR_PRODUTO = Inserted.COR_PRODUTO 
		WHERE 
			LOJA_SAIDAS.EMISSAO < ESTOQUE_PRODUTOS.DATA_AJUSTE)
	BEGIN
		SELECT @errno = 30002, @errmsg = 'Não é possível inserir movimentação de estoque anterior ao ajuste.'
		GOTO Error
	END
-----------------------------------------------------------------------------------------------------------------

--- Atualiza Estoque PA -----------------------------------------------------------------------------------------
	IF UPDATE(PRODUTO) OR UPDATE(COR_PRODUTO) OR UPDATE(FILIAL) OR 
		UPDATE(EN1) OR UPDATE(EN2) OR UPDATE(EN3) OR UPDATE(EN4) OR UPDATE(EN5) OR UPDATE(EN6) OR 
		UPDATE(EN7) OR UPDATE(EN8) OR UPDATE(EN9) OR UPDATE(EN10) OR UPDATE(EN11) OR UPDATE(EN12) OR 
		UPDATE(EN13) OR UPDATE(EN14) OR UPDATE(EN15) OR UPDATE(EN16) OR UPDATE(EN17) OR UPDATE(EN18) OR 
		UPDATE(EN19) OR UPDATE(EN20) OR UPDATE(EN21) OR UPDATE(EN22) OR UPDATE(EN23) OR UPDATE(EN24) OR 
		UPDATE(EN25) OR UPDATE(EN26) OR UPDATE(EN27) OR UPDATE(EN28) OR UPDATE(EN29) OR UPDATE(EN30) OR 
		UPDATE(EN31) OR UPDATE(EN32) OR UPDATE(EN33) OR UPDATE(EN34) OR UPDATE(EN35) OR UPDATE(EN36) OR 
		UPDATE(EN37) OR UPDATE(EN38) OR UPDATE(EN39) OR UPDATE(EN40) OR UPDATE(EN41) OR UPDATE(EN42) OR 
		UPDATE(EN43) OR UPDATE(EN44) OR UPDATE(EN45) OR UPDATE(EN46) OR UPDATE(EN47) OR UPDATE(EN48)
	BEGIN
	    DECLARE cur_LOJA_SAIDAS_PRODUTO CURSOR FOR
		SELECT 
			PRODUTO, COR_PRODUTO, Inserted.FILIAL, 
            SUM(EN1), SUM(EN2), SUM(EN3), SUM(EN4), SUM(EN5), SUM(EN6), SUM(EN7), SUM(EN8), 
            SUM(EN9), SUM(EN10), SUM(EN11), SUM(EN12), SUM(EN13), SUM(EN14), SUM(EN15), SUM(EN16), 
            SUM(EN17), SUM(EN18), SUM(EN19), SUM(EN20), SUM(EN21), SUM(EN22), SUM(EN23), SUM(EN24), 
            SUM(EN25), SUM(EN26), SUM(EN27), SUM(EN28), SUM(EN29), SUM(EN30), SUM(EN31), SUM(EN32), 
            SUM(EN33), SUM(EN34), SUM(EN35), SUM(EN36), SUM(EN37), SUM(EN38), SUM(EN39), SUM(EN40), 
			SUM(EN41), SUM(EN42), SUM(EN43), SUM(EN44), SUM(EN45), SUM(EN46), SUM(EN47), SUM(EN48) 
		 FROM 
			Inserted  
			INNER JOIN LOJA_SAIDAS ON Inserted.FILIAL = LOJA_SAIDAS.FILIAL AND Inserted.ROMANEIO_PRODUTO = LOJA_SAIDAS.ROMANEIO_PRODUTO 
		WHERE
			LOJA_SAIDAS.SAIDA_ENCERRADA = 1
		GROUP BY 
			PRODUTO, COR_PRODUTO, Inserted.FILIAL

		OPEN cur_LOJA_SAIDAS_PRODUTO

	    DECLARE @cProduto Char(12), @cCor_Produto Char(10), @cFilial VarChar(25), @nEstoque Int, 
			@nEs1  Int, @nEs2  Int, @nEs3  Int, @nEs4  Int, @nEs5  Int, @nEs6  Int, @nEs7  Int, @nEs8  Int,
			@nEs9  Int, @nEs10 Int, @nEs11 Int, @nEs12 Int, @nEs13 Int, @nEs14 Int, @nEs15 Int, @nEs16 Int,
			@nEs17 Int, @nEs18 Int, @nEs19 Int, @nEs20 Int, @nEs21 Int, @nEs22 Int, @nEs23 Int, @nEs24 Int, 
			@nEs25 Int, @nEs26 Int, @nEs27 Int, @nEs28 Int, @nEs29 Int, @nEs30 Int, @nEs31 Int, @nEs32 Int, 
			@nEs33 Int, @nEs34 Int, @nEs35 Int, @nEs36 Int, @nEs37 Int, @nEs38 Int, @nEs39 Int, @nEs40 Int, 
			@nEs41 Int, @nEs42 Int, @nEs43 Int, @nEs44 Int, @nEs45 Int, @nEs46 Int, @nEs47 Int, @nEs48 Int

		FETCH NEXT FROM cur_LOJA_SAIDAS_PRODUTO INTO @cProduto, @cCor_Produto, @cFilial, 
			@nEs1,  @nEs2,  @nEs3,  @nEs4,  @nEs5,  @nEs6,  @nEs7,  @nEs8,  @nEs9,  @nEs10, @nEs11, @nEs12, 
			@nEs13, @nEs14, @nEs15, @nEs16, @nEs17, @nEs18, @nEs19, @nEs20, @nEs21, @nEs22, @nEs23, @nEs24, 
			@nEs25, @nEs26, @nEs27, @nEs28, @nEs29, @nEs30, @nEs31, @nEs32, @nEs33, @nEs34, @nEs35, @nEs36, 
			@nEs37, @nEs38, @nEs39, @nEs40, @nEs41, @nEs42, @nEs43, @nEs44, @nEs45, @nEs46, @nEs47, @nEs48

		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SELECT @nEstoque = @nEs1 + @nEs2 + @nEs3 + @nEs4 + @nEs5 + @nEs6 + @nEs7 + @nEs8 + @nEs9 + @nEs10 + @nEs11 + @nEs12 + 
				@nEs13 + @nEs14 + @nEs15 + @nEs16 + @nEs17 + @nEs18 + @nEs19 + @nEs20 + @nEs21 + @nEs22 + @nEs23 + @nEs24 + 
				@nEs25 + @nEs26 + @nEs27 + @nEs28 + @nEs29 + @nEs30 + @nEs31 + @nEs32 + @nEs33 + @nEs34 + @nEs35 + @nEs36 + 
				@nEs37 + @nEs38 + @nEs39 + @nEs40 + @nEs41 + @nEs42 + @nEs43 + @nEs44 + @nEs45 + @nEs46 + @nEs47 + @nEs48

			IF (SELECT COUNT(*) FROM ESTOQUE_PRODUTOS WHERE PRODUTO = @cProduto AND COR_PRODUTO = @cCor_Produto AND FILIAL = @cFilial) > 0
				UPDATE 
					ESTOQUE_PRODUTOS
				SET 
					ESTOQUE = ESTOQUE - @nEstoque, ULTIMA_SAIDA = GETDATE(), 
					ES1 = ES1 - @nES1, ES2 = ES2 - @nES2, ES3 = ES3 - @nES3, ES4 = ES4 - @nES4, ES5 = ES5 - @nES5, ES6 = ES6 - @nES6, 
					ES7 = ES7 - @nES7, ES8 = ES8 - @nES8, ES9 = ES9 - @nES9, ES10 = ES10 - @nES10, ES11 = ES11 - @nES11, ES12 = ES12 - @nES12, 
					ES13 = ES13 - @nES13, ES14 = ES14 - @nES14, ES15 = ES15 - @nES15, ES16 = ES16 - @nES16, ES17 = ES17 - @nES17, ES18 = ES18 - @nES18, 
					ES19 = ES19 - @nES19, ES20 = ES20 - @nES20, ES21 = ES21 - @nES21, ES22 = ES22 - @nES22, ES23 = ES23 - @nES23, ES24 = ES24 - @nES24, 
					ES25 = ES25 - @nES25, ES26 = ES26 - @nES26, ES27 = ES27 - @nES27, ES28 = ES28 - @nES28, ES29 = ES29 - @nES29, ES30 = ES30 - @nES30, 
					ES31 = ES31 - @nES31, ES32 = ES32 - @nES32, ES33 = ES33 - @nES33, ES34 = ES34 - @nES34, ES35 = ES35 - @nES35, ES36 = ES36 - @nES36, 
					ES37 = ES37 - @nES37, ES38 = ES38 - @nES38, ES39 = ES39 - @nES39, ES40 = ES40 - @nES40, ES41 = ES41 - @nES41, ES42 = ES42 - @nES42, 
					ES43 = ES43 - @nES43, ES44 = ES44 - @nES44, ES45 = ES45 - @nES45, ES46 = ES46 - @nES46, ES47 = ES47 - @nES47, ES48 = ES48 - @nES48 
				WHERE 
					PRODUTO = @cProduto AND COR_PRODUTO = @cCor_Produto AND FILIAL = @cFilial
			ELSE
				INSERT INTO ESTOQUE_PRODUTOS 
					(PRODUTO, COR_PRODUTO, FILIAL, ESTOQUE, ULTIMA_SAIDA, 
                    ES1,  ES2,  ES3,  ES4,  ES5,  ES6,  ES7,  ES8,  ES9,  ES10, ES11, ES12, ES13, ES14, ES15, ES16,  
                    ES17, ES18, ES19, ES20, ES21, ES22, ES23, ES24, ES25, ES26, ES27, ES28, ES29, ES30, ES31, ES32,
                    ES33, ES34, ES35, ES36, ES37, ES38, ES39, ES40, ES41, ES42, ES43, ES44, ES45, ES46, ES47, ES48)
				VALUES 
					(@cProduto, @cCor_Produto, @cFilial, @nEstoque * -1, GETDATE(), 
                    @nEs1 * -1, @nEs2 * -1, @nEs3 * -1, @nEs4 * -1, @nEs5 * -1, @nEs6 * -1, @nEs7 * -1, @nEs8 * -1, 
                    @nEs9 * -1, @nEs10 * -1, @nEs11 * -1, @nEs12 * -1, @nEs13 * -1, @nEs14 * -1, @nEs15 * -1, @nEs16 * -1, 
                    @nEs17 * -1, @nEs18 * -1, @nEs19 * -1, @nEs20 * -1, @nEs21 * -1, @nEs22 * -1, @nEs23 * -1, @nEs24 * -1, 
                    @nEs25 * -1, @nEs26 * -1, @nEs27 * -1, @nEs28 * -1, @nEs29 * -1, @nEs30 * -1, @nEs31 * -1, @nEs32 * -1, 
                    @nEs33 * -1, @nEs34 * -1, @nEs35 * -1, @nEs36 * -1, @nEs37 * -1, @nEs38 * -1, @nEs39 * -1, @nEs40 * -1, 
                    @nEs41 * -1, @nEs42 * -1, @nEs43 * -1, @nEs44 * -1, @nEs45 * -1, @nEs46 * -1, @nEs47 * -1, @nEs48 * -1)

			IF @@ROWCOUNT = 0
			BEGIN
				SELECT @errno = 30002, @errmsg = 'A operação foi cancelada. Não foi possível atualizar "ESTOQUE_PRODUTOS".'
				GOTO Error
			END

	        FETCH NEXT FROM cur_LOJA_SAIDAS_PRODUTO INTO @cProduto, @cCor_Produto, @cFilial, 
				@nEs1,  @nEs2,  @nEs3,  @nEs4,  @nEs5,  @nEs6,  @nEs7,  @nEs8,  @nEs9,  @nEs10, @nEs11, @nEs12, 
				@nEs13, @nEs14, @nEs15, @nEs16, @nEs17, @nEs18, @nEs19, @nEs20, @nEs21, @nEs22, @nEs23, @nEs24, 
				@nEs25, @nEs26, @nEs27, @nEs28, @nEs29, @nEs30, @nEs31, @nEs32, @nEs33, @nEs34, @nEs35, @nEs36, 
				@nEs37, @nEs38, @nEs39, @nEs40, @nEs41, @nEs42, @nEs43, @nEs44, @nEs45, @nEs46, @nEs47, @nEs48
		END
		CLOSE cur_LOJA_SAIDAS_PRODUTO
		DEALLOCATE cur_LOJA_SAIDAS_PRODUTO
	END
-----------------------------------------------------------------------------------------------------------------

	return
error:
    raiserror(@errmsg, 18, 1)
    rollback transaction
end