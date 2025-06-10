ALTER TRIGGER [dbo].[LXI_LOJA_ENTRADAS] on [dbo].[LOJA_ENTRADAS] for INSERT NOT FOR REPLICATION as

/* FELIPE SILVA	  - (SS01) - 05/10/2015 - INCLUIDO UPDATE NO CAMPO SS_ID_MAQUINA PARA SALVAR A IDENTIFICAÇÃO DA MAQUINA QUE FEZ A TRANSAÇÃO PELO LINX. */
/* INSERT trigger on LOJA_ENTRADAS */
/* default body for LXI_LOJA_ENTRADAS */
begin
  declare  @numrows int,
           @nullcnt int,
           @validcnt int,
           @insROMANEIO_PRODUTO char(15), 
           @insFILIAL varchar(25),
           @errno   int,
           @errmsg  varchar(255)

  select @numrows = @@rowcount

-- Bloqueio Estoque PA ------------------------------------------------------------------------------------------

	BEGIN
		--Verifica Bloqueio por Contagem
		IF EXISTS (	SELECT Inserted.EMISSAO
				FROM Inserted 
					JOIN LOJA_ENTRADAS_PRODUTO ON 
						Inserted.ROMANEIO_PRODUTO = LOJA_ENTRADAS_PRODUTO.ROMANEIO_PRODUTO AND 
						Inserted.FILIAL = LOJA_ENTRADAS_PRODUTO.FILIAL
					JOIN ESTOQUE_PRODUTOS ON 
						ESTOQUE_PRODUTOS.FILIAL=Inserted.FILIAL AND 
						ESTOQUE_PRODUTOS.PRODUTO=LOJA_ENTRADAS_PRODUTO.PRODUTO AND 
						ESTOQUE_PRODUTOS.COR_PRODUTO=LOJA_ENTRADAS_PRODUTO.COR_PRODUTO 
				WHERE Inserted.EMISSAO < ESTOQUE_PRODUTOS.DATA_AJUSTE )

		BEGIN
			Select 	@errno=30002,
				@errmsg='Não é possível inserir Movimentacao de Estoque anterior ao ajuste!'
			GoTo Error
		END
	END
	-----------------------------------------------------------------------------------------------------------------

/* LOJA_TIPOS_ENTRADA_SAIDA R/1306 LOJA_ENTRADAS ON CHILD INSERT RESTRICT */
  if 
     update(TIPO_ENTRADA_SAIDA)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_TIPOS_ENTRADA_SAIDA
     where 
           inserted.TIPO_ENTRADA_SAIDA = LOJA_TIPOS_ENTRADA_SAIDA.TIPO_ENTRADA_SAIDA
    select @nullcnt = count(*) from inserted where
      inserted.TIPO_ENTRADA_SAIDA is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_ENTRADAS" porque "LOJA_TIPOS_ENTRADA_SAIDA" não existe.'
      goto error
    end
  end

/* FILIAIS FILIAL_ORIGEM LOJA_ENTRADAS ON CHILD INSERT RESTRICT */
  if 
     update(FILIAL_ORIGEM)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,FILIAIS
     where 
           inserted.FILIAL_ORIGEM = FILIAIS.FILIAL
    select @nullcnt = count(*) from inserted where
      inserted.FILIAL_ORIGEM is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_ENTRADAS" porque "FILIAIS" não existe.'
      goto error
    end
  end

/* FILIAIS R/1170 LOJA_ENTRADAS ON CHILD INSERT RESTRICT */
  if 
     update(FILIAL)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,FILIAIS
     where 
           inserted.FILIAL = FILIAIS.FILIAL
    
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_ENTRADAS" porque "FILIAIS" não existe.'
      goto error
    end
  end

/*SS01*/
UPDATE B 
   SET B.SS_ID_MAQUINA = HOST_NAME()
  FROM INSERTED A
  JOIN LOJA_ENTRADAS B 
	ON A.ROMANEIO_PRODUTO = B.ROMANEIO_PRODUTO
   AND A.FILIAL = B.FILIAL
/*SS01*/

  return
error:
    raiserror(@errmsg, 18, 1)
    rollback transaction
end

