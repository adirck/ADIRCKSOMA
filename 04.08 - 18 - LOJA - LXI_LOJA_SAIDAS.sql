ALTER trigger [dbo].[LXI_LOJA_SAIDAS] on [dbo].[LOJA_SAIDAS] for INSERT NOT FOR REPLICATION as

/* FELIPE SILVA	  - (SS01) - 05/10/2015 - INCLUIDO UPDATE NO CAMPO SS_ID_MAQUINA PARA SALVAR A IDENTIFICAÇÃO DA MAQUINA QUE FEZ A TRANSAÇÃO PELO LINX. */

/* INSERT trigger on LOJA_SAIDAS */
/* default body for LXI_LOJA_SAIDAS */
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
					JOIN LOJA_SAIDAS_PRODUTO ON 
						Inserted.FILIAL = LOJA_SAIDAS_PRODUTO.FILIAL AND 
						Inserted.ROMANEIO_PRODUTO = LOJA_SAIDAS_PRODUTO.ROMANEIO_PRODUTO
					JOIN ESTOQUE_PRODUTOS ON 
						ESTOQUE_PRODUTOS.FILIAL=Inserted.FILIAL AND 
						ESTOQUE_PRODUTOS.PRODUTO=LOJA_SAIDAS_PRODUTO.PRODUTO AND 
						ESTOQUE_PRODUTOS.COR_PRODUTO=LOJA_SAIDAS_PRODUTO.COR_PRODUTO 
				WHERE Inserted.EMISSAO < ESTOQUE_PRODUTOS.DATA_AJUSTE )

		BEGIN
			Select 	@errno=30002,
				@errmsg='Não é possível inserir Movimentacao de Estoque anterior ao ajuste!'
			GoTo Error
		END
	END
	-----------------------------------------------------------------------------------------------------------------


/* LOJA_TIPOS_ENTRADA_SAIDA R/1307 LOJA_SAIDAS ON CHILD INSERT RESTRICT */
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
             @errmsg = 'Impossível Incluir "LOJA_SAIDAS" porque "LOJA_TIPOS_ENTRADA_SAIDA" não existe.'
      goto error
    end
  end

/* FILIAIS FILIAL_DESTINO LOJA_SAIDAS ON CHILD INSERT RESTRICT */
  if 
     update(FILIAL_DESTINO)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,FILIAIS
     where 
           inserted.FILIAL_DESTINO = FILIAIS.FILIAL
    select @nullcnt = count(*) from inserted where
      inserted.FILIAL_DESTINO is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_SAIDAS" porque "FILIAIS" não existe.'
      goto error
    end
  end

/* FILIAIS R/1174 LOJA_SAIDAS ON CHILD INSERT RESTRICT */
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
             @errmsg = 'Impossível Incluir "LOJA_SAIDAS" porque "FILIAIS" não existe.'
      goto error
    end
  end
  
/*SS01*/
UPDATE B 
   SET B.SS_ID_MAQUINA = HOST_NAME()
  FROM INSERTED A
  JOIN LOJA_SAIDAS B 
	ON A.FILIAL = B.FILIAL
   AND A.ROMANEIO_PRODUTO = B.ROMANEIO_PRODUTO
/*SS01*/
  
-----------------------------------------------------------------------------------------------------------------
/*SS01 - Não deixa salvar se a nota fiscal não for preenchida.*/
if exists (	select a.ROMANEIO_PRODUTO 
				from inserted a
				inner join lojas_varejo lv
					on a.FILIAL = lv.FILIAL
				inner join FILIAIS origem 
					on a.FILIAL = lv.FILIAL
				inner join filiais destino
					on destino.FILIAL = isnull(a.FILIAL_DESTINO ,a.FORNECEDOR_DEVOLUCAO )
				inner join LOJA_SAIDAS c
					on a.ROMANEIO_PRODUTO = c.romaneio_produto and a.FILIAL = c.filial 
				where a.SAIDA_ENCERRADA = 1 
					and a.SAIDA_CANCELADA = 0 
					and origem.CGC_CPF <> destino.CGC_CPF
					and ltrim(rtrim(c.NUMERO_NF_TRANSFERENCIA)) =''
			)
		begin
			/*Tento recuperar o numero do LOJA_NOTA_FISCAL*/
			update c	
					set c.NUMERO_NF_TRANSFERENCIA = NF.NF_NUMERO
				from inserted a
				inner join lojas_varejo lv
					on a.FILIAL = lv.FILIAL
				inner join FILIAIS origem 
					on a.FILIAL = lv.FILIAL
				inner join filiais destino
					on destino.FILIAL = isnull(a.FILIAL_DESTINO ,a.FORNECEDOR_DEVOLUCAO )
				inner join LOJA_SAIDAS c
					on a.ROMANEIO_PRODUTO = c.romaneio_produto and a.FILIAL = c.filial
				inner join LOJA_NOTA_FISCAL nf
					on nf.ROMANEIO_PRODUTO = a.ROMANEIO_PRODUTO and nf.CODIGO_FILIAL = lv.CODIGO_FILIAL 				
				where a.SAIDA_ENCERRADA = 1 
					and a.SAIDA_CANCELADA = 0 
					and origem.CGC_CPF <> destino.CGC_CPF
					and ltrim(rtrim(c.NUMERO_NF_TRANSFERENCIA)) =''
			
			
			if exists (	select a.ROMANEIO_PRODUTO 
						from inserted a
						inner join lojas_varejo lv
							on a.FILIAL = lv.FILIAL
						inner join FILIAIS origem 
							on a.FILIAL = lv.FILIAL
						inner join filiais destino
							on destino.FILIAL = isnull(a.FILIAL_DESTINO ,a.FORNECEDOR_DEVOLUCAO )
						inner join LOJA_SAIDAS c
							on a.ROMANEIO_PRODUTO = c.romaneio_produto and a.FILIAL = c.filial 
						where a.SAIDA_ENCERRADA = 1 
							and a.SAIDA_CANCELADA = 0 
							and origem.CGC_CPF <> destino.CGC_CPF
							and ltrim(rtrim(c.NUMERO_NF_TRANSFERENCIA)) =''
					)		
				begin
					SELECT @errno = 30002, @errmsg = 'Não é permitido encerrar uma saída sem número de nota fiscal.'
					GOTO Error
				end
				
		end  

  return
error:
    raiserror(@errmsg, 18, 1)
    rollback transaction
end