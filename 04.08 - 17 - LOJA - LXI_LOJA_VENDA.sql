ALTER trigger [dbo].[LXI_LOJA_VENDA] on [dbo].[LOJA_VENDA] for INSERT NOT FOR REPLICATION as

--FELIPE SILVA	  - (SS01)			(05/10/2015) - INCLUIDO UPDATE NO CAMPO SS_ID_MAQUINA PARA SALVAR A IDENTIFICA��O DA MAQUINA QUE FEZ A TRANSA��O PELO LINX.
--TP10794328 - #3# - Diego Moreno (11/11/2015) - Parte II. Comentei o trecho abaixo pois a necessidade de verificar estoque já está sendo atendida através de trigger de INSERT em LXI_LOJA_VENDA_PRODUTO.
--TP7737162 - #2# - Giedson Silva (05/02/2014) - Tratamento para que o campo DATA_DE_TRANSFERENCIA da tabela CLIENTES_VAREJO não seja atualizado através deste Script. É atualizado com trigger da tabela CLIENTES_VAREJO
--TP4629098 - #1# - Diego Moreno (23/12/2014) - Tratamento para evitar bloqueios DeadLock.
/* INSERT trigger on LOJA_VENDA */
begin
  declare  @numrows int,
           @nullcnt int,
           @validcnt int,
           @insCODIGO_FILIAL char(6), 
           @insTICKET char(8), 
           @insDATA_VENDA datetime,
           @errno   int,
           @errmsg  varchar(255)

  select @numrows = @@rowcount

-- Bloqueio Estoque PA ------------------------------------------------------------------------------------------
--#3# - 
	-- BEGIN
		-- --Verifica Bloqueio por Contagem
		-- IF EXISTS (	SELECT Inserted.DATA_VENDA
				-- FROM Inserted 
					-- JOIN LOJA_VENDA_PRODUTO ON 
						-- Inserted.TICKET = LOJA_VENDA_PRODUTO.TICKET AND 
						-- Inserted.CODIGO_FILIAL = LOJA_VENDA_PRODUTO.CODIGO_FILIAL AND 
						-- Inserted.DATA_VENDA = LOJA_VENDA_PRODUTO.DATA_VENDA
					-- JOIN LOJAS_VAREJO (nolock) ON -- #1#
						-- Inserted.CODIGO_FILIAL = LOJAS_VAREJO.CODIGO_FILIAL
					-- JOIN ESTOQUE_PRODUTOS ON 
						-- ESTOQUE_PRODUTOS.FILIAL=LOJAS_VAREJO.FILIAL AND 
						-- ESTOQUE_PRODUTOS.PRODUTO=LOJA_VENDA_PRODUTO.PRODUTO AND 
						-- ESTOQUE_PRODUTOS.COR_PRODUTO=LOJA_VENDA_PRODUTO.COR_PRODUTO 
				-- WHERE Inserted.DATA_VENDA < ESTOQUE_PRODUTOS.DATA_AJUSTE )

		-- BEGIN
			-- Select 	@errno=30002,
				-- @errmsg='Não é possível inserir Movimentacao de Estoque anterior ao ajuste!'
			-- GoTo Error
		-- END
	-- END
--#3#
	-----------------------------------------------------------------------------------------------------------------

/* LOJA_MOTIVOS_DESCONTO LOJA_TIPO_DESCONTO LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(CODIGO_DESCONTO)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_MOTIVOS_DESCONTO
     where 
           inserted.CODIGO_DESCONTO = LOJA_MOTIVOS_DESCONTO.CODIGO_DESCONTO
    select @nullcnt = count(*) from inserted where
      inserted.CODIGO_DESCONTO is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "LOJA_MOTIVOS_DESCONTO" não existe.'
      goto error
    end
  end

/* LOJA_VENDEDORES GERENTE_PERIODO LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(GERENTE_PERIODO)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_VENDEDORES
     where 
           inserted.GERENTE_PERIODO = LOJA_VENDEDORES.VENDEDOR
    
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "LOJA_VENDEDORES" não existe.'
      goto error
    end
  end

/* LOJA_VENDEDORES GERENTES LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(GERENTE_LOJA)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_VENDEDORES
     where 
           inserted.GERENTE_LOJA = LOJA_VENDEDORES.VENDEDOR
    
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "LOJA_VENDEDORES" não existe.'
      goto error
    end
  end

/* LOJA_TERMINAIS TERMINAL LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(TERMINAL) or 
     update(CODIGO_FILIAL)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_TERMINAIS
     where 
           inserted.TERMINAL = LOJA_TERMINAIS.TERMINAL and
           inserted.CODIGO_FILIAL = LOJA_TERMINAIS.CODIGO_FILIAL
    
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "LOJA_TERMINAIS" não existe.'
      goto error
    end
  end

/* CLIENTES_VAREJO clientes_varejo LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(CODIGO_CLIENTE)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,CLIENTES_VAREJO
     where 
           inserted.CODIGO_CLIENTE = CLIENTES_VAREJO.CODIGO_CLIENTE
    select @nullcnt = count(*) from inserted where
      inserted.CODIGO_CLIENTE is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "CLIENTES_VAREJO" não existe.'
      goto error
    end
  end

/* LOJAS_VAREJO LOJAS_VAREJO LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(CODIGO_FILIAL)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJAS_VAREJO (nolock) -- #1# 
     where 
           inserted.CODIGO_FILIAL = LOJAS_VAREJO.CODIGO_FILIAL
    
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "LOJAS_VAREJO" não existe.'
      goto error
    end
  end

/* LOJA_VENDA_PGTO CAIXA_LANC LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(CODIGO_FILIAL_PGTO) or 
     update(TERMINAL_PGTO) or 
     update(LANCAMENTO_CAIXA)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_VENDA_PGTO
     where 
           inserted.CODIGO_FILIAL_PGTO = LOJA_VENDA_PGTO.CODIGO_FILIAL and
           inserted.TERMINAL_PGTO = LOJA_VENDA_PGTO.TERMINAL and
           inserted.LANCAMENTO_CAIXA = LOJA_VENDA_PGTO.LANCAMENTO_CAIXA
    select @nullcnt = count(*) from inserted where
      inserted.CODIGO_FILIAL_PGTO is null or
      inserted.TERMINAL_PGTO is null or
      inserted.LANCAMENTO_CAIXA is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "LOJA_VENDA_PGTO" não existe.'
      goto error
    end
  end

/* TABELAS_PRECO TABELAS_PRECO LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(CODIGO_TAB_PRECO)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,TABELAS_PRECO
     where 
           inserted.CODIGO_TAB_PRECO = TABELAS_PRECO.CODIGO_TAB_PRECO
    
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "TABELAS_PRECO" não existe.'
      goto error
    end
  end

/* LOJA_OPERACOES_VENDA LOJA_OPERACAO LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(OPERACAO_VENDA)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_OPERACOES_VENDA
     where 
           inserted.OPERACAO_VENDA = LOJA_OPERACOES_VENDA.OPERACAO_VENDA
    select @nullcnt = count(*) from inserted where
      inserted.OPERACAO_VENDA is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "LOJA_OPERACOES_VENDA" não existe.'
      goto error
    end
  end

/* LOJA_VENDEDORES LOJA_FUNCIONARIOS LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(VENDEDOR)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_VENDEDORES
     where 
           inserted.VENDEDOR = LOJA_VENDEDORES.VENDEDOR
    select @nullcnt = count(*) from inserted where
      inserted.VENDEDOR is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "LOJA_VENDEDORES" não existe.'
      goto error
    end
  end

/* LOJA_MOTIVOS_CANCELAMENTOS MOTIVO_CANCELAMENTO LOJA_VENDA ON CHILD INSERT RESTRICT */
  if 
     update(MOTIVO_CANCELAMENTO)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_MOTIVOS_CANCELAMENTOS
     where 
           inserted.MOTIVO_CANCELAMENTO = LOJA_MOTIVOS_CANCELAMENTOS.MOTIVO_CANCELAMENTO
    select @nullcnt = count(*) from inserted where
      inserted.MOTIVO_CANCELAMENTO is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA" porque "LOJA_MOTIVOS_CANCELAMENTOS" não existe.'
      goto error
    end
  end

/*-- Ultima Compra ----------------------------------------------------------------------------------------------------*/
UPDATE 
	CLIENTES_VAREJO 
SET 
	ULTIMA_COMPRA = INSERTED.DATA_VENDA
	--, DATA_PARA_TRANSFERENCIA = CLIENTES_VAREJO.DATA_PARA_TRANSFERENCIA  #2#
FROM 
	CLIENTES_VAREJO 
	INNER JOIN INSERTED ON CLIENTES_VAREJO.CODIGO_CLIENTE = INSERTED.CODIGO_CLIENTE 
WHERE 
	ULTIMA_COMPRA < DATA_VENDA OR ULTIMA_COMPRA IS NULL
/*---------------------------------------------------------------------------------------------------------------------*/

/*SS01*/
UPDATE B 
   SET B.SS_ID_MAQUINA = HOST_NAME()
  FROM INSERTED A
  JOIN LOJA_VENDA  B 
	ON A.TICKET = B.TICKET
   AND A.DATA_VENDA = B.DATA_VENDA
   AND A.CODIGO_FILIAL = B.CODIGO_FILIAL
/*SS01*/

  return
error:
    raiserror(@errmsg, 18, 1)
    rollback transaction
end