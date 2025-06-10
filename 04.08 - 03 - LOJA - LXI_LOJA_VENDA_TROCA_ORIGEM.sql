ALTER trigger LXI_LOJA_VENDA_TROCA_ORIGEM on dbo.LOJA_VENDA_TROCA_ORIGEM for INSERT NOT FOR REPLICATION as
/* INSERT trigger on LOJA_VENDA_TROCA_ORIGEM */
/* default body for LXI_LOJA_VENDA_TROCA_ORIGEM */

/*Tiago Carvalho - (SS01) - 09/04/2015 - Não Valida o Ticket de Origem porque ele pode ser de Outra Loja e já será validado na troca*/
begin
  declare  @numrows int,
           @nullcnt int,
           @validcnt int,
           @insTICKET char(8), 
           @insCODIGO_FILIAL char(6), 
           @insITEM char(4), 
           @insDATA_VENDA datetime,
           @errno   int,
           @errmsg  varchar(255)

  select @numrows = @@rowcount

/* LOJA_VENDA_TROCA LOJA_TROCA_ORIGEM_VENDA LOJA_VENDA_TROCA_ORIGEM ON CHILD INSERT RESTRICT */
  if 
     update(CODIGO_FILIAL) or 
     update(TICKET) or 
     update(DATA_VENDA) or
     update(ITEM)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_VENDA_TROCA
     where 
           inserted.CODIGO_FILIAL = LOJA_VENDA_TROCA.CODIGO_FILIAL and
           inserted.TICKET = LOJA_VENDA_TROCA.TICKET and
           inserted.DATA_VENDA = LOJA_VENDA_TROCA.DATA_VENDA and
	   inserted.ITEM = LOJA_VENDA_TROCA.ITEM
    
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA_TROCA_ORIGEM" porque "LOJA_VENDA_TROCA" não existe.'
      goto error
    end
  end
/*ss01*/
/* LOJA_VENDA_PRODUTO LOJA_TROCA_ORIGEM_VENDA LOJA_VENDA_TROCA_ORIGEM ON CHILD INSERT RESTRICT 
  if 
     update(CODIGO_FILIAL_ORIGEM) or 
     update(TICKET_ORIGEM) or 
     update(DATA_VENDA_ORIGEM) or
     update(ITEM_ORIGEM)
  begin
    select @nullcnt = 0
    select @validcnt = count(*)
      from inserted,LOJA_VENDA_PRODUTO
     where 
           inserted.CODIGO_FILIAL_ORIGEM = LOJA_VENDA_PRODUTO.CODIGO_FILIAL and
           inserted.TICKET_ORIGEM = LOJA_VENDA_PRODUTO.TICKET and
           inserted.DATA_VENDA_ORIGEM = LOJA_VENDA_PRODUTO.DATA_VENDA and
	   inserted.ITEM_ORIGEM = LOJA_VENDA_PRODUTO.ITEM
   select @nullcnt = count(*) from inserted where
           inserted.CODIGO_FILIAL_ORIGEM is null or
           inserted.TICKET_ORIGEM is null or
           inserted.DATA_VENDA_ORIGEM is null or
	   inserted.ITEM_ORIGEM is null
    if @validcnt + @nullcnt != @numrows
    begin
      select @errno  = 30002,
             @errmsg = 'Impossível Incluir "LOJA_VENDA_TROCA_ORIGEM" porque "LOJA_VENDA_PRODUTO" não existe.'
      goto error
    end
  end */

  return
error:
    raiserror(@errmsg, 18, 1)
    rollback transaction
end
