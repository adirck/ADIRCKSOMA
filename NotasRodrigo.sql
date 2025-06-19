select b.CODIGO_FILIAL,b.TICKET,b.DATA_VENDA,d.* from loja_venda_pgto a
join loja_venda b on a.codigo_filial=b.codigo_filial and a.lancamento_caixa=b.lancamento_caixa and a.terminal=b.TERMINAL 
join (select codigo_filial,nf_numero,serie_nf,emissao from LOJA_NOTA_FISCAL where STATUS_NFE in ('3','4'))c on a.CODIGO_FILIAL=c.CODIGO_FILIAL
      and a.NUMERO_FISCAL_TROCA=c.NF_NUMERO and a.SERIE_NF_ENTRADA=c.SERIE_NF
join LOJA_VENDA_TROCA_ORIGEM d on a.CODIGO_FILIAL=d.CODIGO_FILIAL and b.TICKET=d.TICKET and b.DATA_VENDA=d.DATA_VENDA where emissao>= (getdate()-10)
GO
delete d  from loja_venda_pgto a
join loja_venda b
on a.codigo_filial=b.codigo_filial
and a.lancamento_caixa=b.lancamento_caixa
and a.terminal=b.TERMINAL
join (select codigo_filial,nf_numero,serie_nf,emissao from LOJA_NOTA_FISCAL where STATUS_NFE in ('3','4'))c
	on a.CODIGO_FILIAL=c.CODIGO_FILIAL
	and a.NUMERO_FISCAL_TROCA=c.NF_NUMERO
	and a.SERIE_NF_ENTRADA=c.SERIE_NF
join LOJA_VENDA_TROCA_ORIGEM d
on a.CODIGO_FILIAL=d.CODIGO_FILIAL
and b.TICKET=d.TICKET
and b.DATA_VENDA=d.DATA_VENDA
where emissao>='20211201'
GO
update a set data_cancelamento = null,a.valor_cancelado = '0.00',a.MOTIVO_CANCELAMENTO_NFE = null,a.PROTOCOLO_CANCELAMENTO_NFE = null,a.NOTA_CANCELADA = '0' 
from LOJA_NOTA_FISCAL a (nolock)join LOJA_NOTA_FISCAL_item b (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL and  a.nf_numero = b.nf_numero and a.SERIE_NF = b.SERIE_NF
join loja_nota_fiscal_imposto e(nolock) on a.CODIGO_FILIAL = e.CODIGO_FILIAL and  a.nf_numero = e.nf_numero and a.SERIE_NF = e.SERIE_NF and b.SUB_ITEM_TAMANHO = e.SUB_ITEM_TAMANHO and b.ITEM_IMPRESSAO = e.ITEM_IMPRESSAO
join LOJAS_VAREJO C(nolock) on a.CODIGO_FILIAL = C.CODIGO_FILIAL join FILIAIS D(nolock) on D.FILIAL = C.FILIAL  
 where  a.STATUS_NFE  in('5')  and (a.DATA_CANCELAMENTO is not null or a.PROTOCOLO_CANCELAMENTO_NFE is not null) and a.EMISSAO>=(getdate()-10)
go
update LOJA_NOTA_FISCAL set LOG_STATUS_NFE = '0' where EMISSAO>=(getdate()-10) and LOG_STATUS_NFE <> '0' 
go
update CTB_LX_TIPO_OPERACAO set TIPO_OPERACAO='E' where CTB_TIPO_OPERACAO='244' and TIPO_OPERACAO<>'E'

update loja_nota_fiscal
set status_NFe = '52',log_status_nfe = '0'---,tipo_emissao_nfe = '1',DATA_HORA_EMISSAO=emissao,DATA_HORA_SAIDA=emissao
where EMISSAO >= (getdate()-10)   and STATUS_NFE = '59' and (DATA_CANCELAMENTO is null or PROTOCOLO_CANCELAMENTO_NFE is null )
and SERIE_NF ='65'
go
update d set d.INDICADOR_CFOP ='11'
from LOJA_NOTA_FISCAL a join lojas_varejo b on a.CODIGO_FILIAL= b.CODIGO_FILIAL join FILIAIS c on b.FILIAL = c.FILIAL 
join LOJA_NOTA_FISCAL_ITEM d on d.NF_NUMERO = a.NF_NUMERO and d.SERIE_NF = d.SERIE_NF join CADASTRO_CLI_FOR e on e.CLIFOR = c.CLIFOR
where a.EMISSAO >= (getdate()-10)     and a.STATUS_NFE not in('5','59','49','70')
and a.serie_nf <>'65' and d.INDICADOR_CFOP ='10'
go
update  CTB_EXCECAO_IMPOSTO_ITEM
set SUB_ITEM_SPED =ltrim (SUB_ITEM_SPED)
where
SUB_ITEM_SPED is not null
go
update  CTB_EXCECAO_IMPOSTO_ITEM
set SUB_ITEM_SPED =rtrim (SUB_ITEM_SPED)
where
SUB_ITEM_SPED is not null
go
update TRANSPORTADORAS
set INATIVO ='1'
where INSCRICAO =' '
go
update TRANSPORTADORAS
set INATIVO ='1'
where INSCRICAO ='999'
go
update c set c.CODIGO_CLIENTE = a.CODIGO_CLIENTE
from LOJA_VENDA a (nolock)
join loja_venda_pgto b (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL and a.LANCAMENTO_CAIXA =b.LANCAMENTO_CAIXA and a.data_venda= b.data 
join loja_nota_fiscal c (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL and b.NUMERO_FISCAL_CANCELAMENTO = c.NF_NUMERO  and a.data_venda= c.emissao  and a.terminal=b.terminal
join LOJAS_VAREJO(nolock) d on c.CODIGO_FILIAL = d.CODIGO_FILIAL 
join FILIAIS(nolock) e on e.FILIAL = d.FILIAL 
where c.EMISSAO >= (getdate()-10)  AND c.STATUS_NFE NOT IN (5,49,59,70,50) and c.CODIGO_CLIENTE is null and c.cod_clifor is null
go
update c set c.CODIGO_CLIENTE = a.CODIGO_CLIENTE
from LOJA_VENDA a (nolock)
join loja_venda_pgto b (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL and a.LANCAMENTO_CAIXA =b.LANCAMENTO_CAIXA and a.data_venda= b.data and a.terminal=b.terminal
join loja_nota_fiscal c (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL and b.NUMERO_FISCAL_TROCA = c.NF_NUMERO  and a.data_venda= c.emissao
join LOJAS_VAREJO(nolock) d on c.CODIGO_FILIAL = d.CODIGO_FILIAL 
join FILIAIS(nolock) e on e.FILIAL = d.FILIAL 
where c.EMISSAO >= (getdate()-10)  AND c.STATUS_NFE NOT IN (5,49,59,70,50) and c.CODIGO_CLIENTE is null and c.cod_clifor is null
go
update c set c.CODIGO_CLIENTE = a.CODIGO_CLIENTE
from LOJA_VENDA a (nolock)
join loja_venda_pgto b (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL and a.LANCAMENTO_CAIXA =b.LANCAMENTO_CAIXA and a.data_venda= b.data  and a.terminal=b.terminal
join loja_nota_fiscal c (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL and b.NUMERO_FISCAL_VENDA = c.NF_NUMERO  and a.data_venda= c.emissao
join LOJAS_VAREJO(nolock) d on c.CODIGO_FILIAL = d.CODIGO_FILIAL 
join FILIAIS(nolock) e on e.FILIAL = d.FILIAL 
where c.EMISSAO >= (getdate()-10)  AND c.STATUS_NFE NOT IN (5,49,59,70,50) and c.CODIGO_CLIENTE is null and c.cod_clifor is null
go
update b set b.codigo_cliente = a.codigo_cliente
from LOJA_VENDA a (nolock) 
join loja_nota_fiscal b (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL  and a.data_venda= b.emissao 
join LOJA_NOTA_FISCAL_ITEM c (NOLOCK) on c.NF_NUMERO = b.NF_NUMERO and c.SERIE_NF = b.SERIE_NF  and c.CODIGO_FILIAL =b.CODIGO_FILIAL
join loja_venda_troca d (NOLOCK) on d.ticket = a.TICKET and d.codigo_filial = a.codigo_filial and d.data_venda = a.DATA_VENDA and d.produto = c.REFERENCIA
join LOJAS_VAREJO e (nolock) on e.CODIGO_FILIAL = a.CODIGO_FILIAL 
join FILIAIS f (nolock) on f.FILIAL = e.FILIAL 
where b.STATUS_NFE  in('59') and b.EMISSAO >= (getdate()-10) and b.codigo_cliente is null
go
-----xml erro -5912----
update b set   b.codigo_fiscal_operacao=('5912')
--select   a.CODIGO_FILIAL,a.NF_NUMERO,a.NATUREZA_OPERACAO_CODIGO,b.CODIGO_FISCAL_OPERACAO,a.SERIE_NF
from LOJA_NOTA_FISCAL a (nolock)join LOJA_NOTA_FISCAL_item b (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL and  a.nf_numero = b.nf_numero and a.SERIE_NF = b.SERIE_NF
join LOJAS_VAREJO C(nolock) on a.CODIGO_FILIAL = C.CODIGO_FILIAL join FILIAIS D(nolock) on D.FILIAL = C.FILIAL  
where  a.STATUS_NFE not in('5','59','49','70','50')  and a.NATUREZA_OPERACAO_CODIGO in ('5912 ') and b.CODIGO_FISCAL_OPERACAO ='6912'
and a.SERIE_NF<>'65' and a.EMISSAO>=(getdate()-10)
go
-----erro finalidada-2913----
update a set a.FIN_EMISSAO_NFE ='1'
--select   a.CODIGO_FILIAL,a.NF_NUMERO,a.NATUREZA_OPERACAO_CODIGO,b.CODIGO_FISCAL_OPERACAO,a.SERIE_NF,a.FIN_EMISSAO_NFE
from LOJA_NOTA_FISCAL a (nolock)join LOJA_NOTA_FISCAL_item b (nolock) on a.CODIGO_FILIAL = b.CODIGO_FILIAL and  a.nf_numero = b.nf_numero and a.SERIE_NF = b.SERIE_NF
join LOJAS_VAREJO C(nolock) on a.CODIGO_FILIAL = C.CODIGO_FILIAL join FILIAIS D(nolock) on D.FILIAL = C.FILIAL  
where  a.STATUS_NFE not in('5','59','49','70','50')  and a.NATUREZA_OPERACAO_CODIGO in ('2913 ') and a.FIN_EMISSAO_NFE <>'1'
and a.SERIE_NF<>'65' and a.EMISSAO>=(getdate()-10)
-------------------------envia a loja-------------------
update loja_nota_fiscal
set status_NFe = '1',log_status_nfe = '0',DATA_PARA_TRANSFERENCIA = GETDATE ()
where EMISSAO >= (getdate()-10) and STATUS_NFE not in('5','59','49','70','52','42') and SERIE_NF <>'65'
go
REVOKE EXECUTE ON [dbo].[sp_ClearEvents] TO [LinxPOS] AS [dbo]
go
GRANT EXECUTE ON [dbo].[sp_ClearEvents] TO [LinxPOS]
go
update GS_BD_LOJAS
set DATA_PARA_TRANSFERENCIA = GETDATE ()

----------------envia ip da loja -------------------------------
go
IF OBJECT_ID('GS_BD_LOJAS') IS NULL
	BEGIN
		--=== Criando a tabela ===--
			CREATE TABLE GS_BD_LOJAS(
				 CODIGO_FILIAL CHAR(6)
				,NOME_SERVIDOR VARCHAR (50)
				,IP_LOJA VARCHAR(100)
				,NOME_BANCO VARCHAR (25)
				,ULTIMO_IP_VALIDO VARCHAR(100)
				,DATA_PARA_TRANSFERENCIA DATETIME
		
				PRIMARY KEY (CODIGO_FILIAL)
			)

		--=== Inserindo dados de conexão junto à criação da tabela ===--
		DECLARE
			 @CODIGO_FILIAL    CHAR(6)
			,@NOME_SERVIDOR    VARCHAR(50)
			,@IP_LOJA          VARCHAR(100)
			,@ULTIMO_IP_VALIDO VARCHAR(100)
			,@NOME_BANCO       VARCHAR(25) 

		SELECT 
			 @CODIGO_FILIAL = (SELECT DISTINCT CODIGO_FILIAL FROM LOJA_VENDA where DATA_VENDA>getdate()-5)
			,@NOME_SERVIDOR = @@SERVERNAME
			,@IP_LOJA = CASE WHEN EXISTS(select local_net_address from (Select distinct top 1 local_net_address, last_read from sys.dm_exec_connections where local_net_address like '10.%' order by last_read desc)a)
								THEN (select local_net_address from (Select distinct top 1 local_net_address, last_read from sys.dm_exec_connections where local_net_address like '10.%' order by last_read desc)a)
								ELSE CAST(CONNECTIONPROPERTY('local_net_address') AS VARCHAR)
						END
			,@NOME_BANCO = DB_NAME()

	
		IF EXISTS(SELECT 1 FROM GS_BD_LOJAS WHERE CODIGO_FILIAL = @CODIGO_FILIAL AND IP_LOJA IS NOT NULL)
			BEGIN
				SELECT @ULTIMO_IP_VALIDO = (SELECT IP_LOJA FROM GS_BD_LOJAS WHERE CODIGO_FILIAL = @CODIGO_FILIAL)
			END

		IF EXISTS(SELECT 1 FROM GS_BD_LOJAS WHERE CODIGO_FILIAL = @CODIGO_FILIAL)
			BEGIN
			IF EXISTS(SELECT 1 FROM GS_BD_LOJAS 
						WHERE (IP_LOJA = @IP_LOJA
						OR NOME_BANCO = @NOME_BANCO
						OR CODIGO_FILIAL = @CODIGO_FILIAL
						OR NOME_SERVIDOR = @NOME_SERVIDOR) )
				BEGIN
					UPDATE GS_BD_LOJAS
					SET IP_LOJA = @IP_LOJA, NOME_BANCO = @NOME_BANCO, CODIGO_FILIAL = @CODIGO_FILIAL, NOME_SERVIDOR = @NOME_SERVIDOR, ULTIMO_IP_VALIDO = @ULTIMO_IP_VALIDO, DATA_PARA_TRANSFERENCIA = GETDATE()
					WHERE CODIGO_FILIAL = @CODIGO_FILIAL
				END
			END
		ELSE
			BEGIN
				INSERT INTO GS_BD_LOJAS (CODIGO_FILIAL, NOME_SERVIDOR, IP_LOJA, NOME_BANCO, DATA_PARA_TRANSFERENCIA)
				VALUES (@CODIGO_FILIAL, @NOME_SERVIDOR, @IP_LOJA, @NOME_BANCO, GETDATE())
			END
	END
ELSE-->> Se existe a tabela, apenas Valida os dados
	BEGIN
		--=== Declarando variáveis ===--
			DECLARE
				 @CODIGO_FILIAL_LOJA    CHAR(6)
				,@NOME_SERVIDOR_LOJA    VARCHAR(50)
				,@IP_LOCAL_LOJA          VARCHAR(100)
				,@ULTIMO_IP_VALIDO_LOJA VARCHAR(100)
				,@NOME_BANCO_LOJA       VARCHAR(25) 
		--=== Registrando dados nas variáveis ===--
			SELECT 
				 @CODIGO_FILIAL_LOJA = (SELECT DISTINCT CODIGO_FILIAL FROM LOJA_VENDA where DATA_VENDA> getdate ()-5 )
				,@NOME_SERVIDOR_LOJA = @@SERVERNAME
				,@IP_LOCAL_LOJA = CASE WHEN EXISTS(select local_net_address from (Select distinct top 1 local_net_address, last_read from sys.dm_exec_connections where local_net_address like '10.%' order by last_read desc)a)
										THEN (select local_net_address from (Select distinct top 1 local_net_address, last_read from sys.dm_exec_connections where local_net_address like '10.%' order by last_read desc)a)
										ELSE CAST(CONNECTIONPROPERTY('local_net_address') AS VARCHAR)
									END
				,@NOME_BANCO_LOJA = DB_NAME()
		--=== Registro Ultimo_ip_valido ===--
			IF EXISTS(SELECT 1 FROM GS_BD_LOJAS WHERE CODIGO_FILIAL = @CODIGO_FILIAL_LOJA AND IP_LOJA IS NOT NULL)
				BEGIN
					SELECT @ULTIMO_IP_VALIDO_LOJA = (SELECT IP_LOJA FROM GS_BD_LOJAS WHERE CODIGO_FILIAL = @CODIGO_FILIAL_LOJA)
				END
		--=== Valido alteração nos dados de conexão ===--
			IF EXISTS(SELECT 1 FROM GS_BD_LOJAS WHERE CODIGO_FILIAL = @CODIGO_FILIAL_LOJA)
				BEGIN
				IF EXISTS(SELECT 1 FROM GS_BD_LOJAS 
							WHERE (IP_LOJA = @IP_LOCAL_LOJA
							OR NOME_BANCO = @NOME_BANCO_LOJA
							OR CODIGO_FILIAL = @CODIGO_FILIAL_LOJA
							OR NOME_SERVIDOR = @NOME_SERVIDOR_LOJA) )
					BEGIN
						UPDATE GS_BD_LOJAS
						SET IP_LOJA = @IP_LOCAL_LOJA, NOME_BANCO = @NOME_BANCO_LOJA, CODIGO_FILIAL = @CODIGO_FILIAL_LOJA, NOME_SERVIDOR = @NOME_SERVIDOR_LOJA, ULTIMO_IP_VALIDO = @ULTIMO_IP_VALIDO_LOJA, DATA_PARA_TRANSFERENCIA = GETDATE()
						WHERE CODIGO_FILIAL = @CODIGO_FILIAL_LOJA
					END
				END
			ELSE
				BEGIN
					INSERT INTO GS_BD_LOJAS (CODIGO_FILIAL, NOME_SERVIDOR, IP_LOJA, NOME_BANCO, DATA_PARA_TRANSFERENCIA)
					VALUES (@CODIGO_FILIAL_LOJA, @NOME_SERVIDOR_LOJA, @IP_LOCAL_LOJA, @NOME_BANCO_LOJA, GETDATE())
				END
	END
TRUNCATE TABLE LJ_DADO_EXCECAO
GO
select * from GS_BD_LOJAS
GO
update  LOJAS_NATUREZA_OPERACAO
set INATIVO ='1'
where 
MODULO_filtro  is null
and INATIVO ='0'
go
select distinct e.uf,c.CGC_CPF,a.CODIGO_FILIAL,c.FILIAL,a.DATA_HORA_EMISSAO,a.NF_NUMERO,a.SERIE_NF,a.STATUS_NFE,a.LOG_STATUS_NFE,a.TIPO_EMISSAO_NFE,a.NATUREZA_OPERACAO_CODIGO,
d.CODIGO_FISCAL_OPERACAO,G.natureza_descricao,a.VALOR_TOTAl,a.CODIGO_CLIENTE,a.cod_clifor,a.INDICA_PRESENCA_COMPRADOR,a.INDICA_CONSUMIDOR_FINAL,a.DATA_PARA_TRANSFERENCIA,a.EMISSAO,
H.CLIENTE_VAREJO,H.RG_IE,H.STATUS,h.PAIS,h.CEP,h.CIDADE,h.BAIRRO,h.ENDERECO,h.NUMERO,h.TELEFONE,h.RG_IE,h.PF_PJ,a.EMISSAO,a.DATA_HORA_EMISSAO,a.DATA_HORA_SAIDA,a.chave_nfe
from LOJA_NOTA_FISCAL a (NOLOCK)  join lojas_varejo b (NOLOCK) on a.CODIGO_FILIAL= b.CODIGO_FILIAL join FILIAIS c (NOLOCK) on b.FILIAL = c.FILIAL left join LOJA_NOTA_FISCAL_ITEM d (NOLOCK) on d.NF_NUMERO = a.NF_NUMERO and d.SERIE_NF = A.SERIE_NF  and a.CODIGO_FILIAL = d.CODIGO_FILIAL
left join CADASTRO_CLI_FOR e (NOLOCK) on e.CLIFOR = c.CLIFOR join loja_nota_fiscal_imposto  f (nolock)  on D.CODIGO_FILIAL = f.CODIGO_FILIAL and  D.nf_numero = f.nf_numero and D.SERIE_NF = f.SERIE_NF 	and d.SUB_ITEM_TAMANHO = f.SUB_ITEM_TAMANHO and d.ITEM_IMPRESSAO =F.ITEM_IMPRESSAO
left JOIN LOJAS_NATUREZA_OPERACAO G(nolock) on a.NATUREZA_OPERACAO_CODIGO = g.NATUREZA_OPERACAO_CODIGO left JOIN CLIENTES_VAREJO H (nolock) on H.CODIGO_CLIENTE = A.CODIGO_CLIENTE
where a.EMISSAO >= (getdate()-30)  and a.STATUS_NFE not in('5','59','49','70','50') order by c.cgc_cpf,c.filial,a.serie_nf,a.NF_NUMERO,a.EMISSAO,a.DATA_HORA_EMISSAO

