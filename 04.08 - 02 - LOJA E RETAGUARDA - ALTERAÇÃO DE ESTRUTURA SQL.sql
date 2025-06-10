if not exists(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SS_CHAVE_NFE_ORIGEM') 
	CREATE TABLE [dbo].[SS_CHAVE_NFE_ORIGEM](
	[CHAVE_NFE] [varchar](44) NOT NULL,
	[CODIGO_FILIAL_DESTINO] [char](6) NOT NULL,
	[FILIAL_DESTINO] [varchar](25) NOT NULL,
	[FILIAL_ORIGEM] [varchar](25) NOT NULL,
	[NF] [char](15) NOT NULL,
	[SERIE_NF] [varchar](6) NOT NULL,
	[CTB_TIPO_OPERACAO] [int] NOT NULL,
	[DATA_PARA_TRANSFERENCIA] [datetime] NOT NULL, 
	CONSTRAINT [PK_SS_CHAVE_NFE_ORIGEM] PRIMARY KEY NONCLUSTERED (
	[CHAVE_NFE] ASC,[CODIGO_FILIAL_DESTINO] ASC,[FILIAL_DESTINO] ASC,[FILIAL_ORIGEM] ASC,[NF] ASC,[SERIE_NF] ASC,[CTB_TIPO_OPERACAO] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]) 
	ON [PRIMARY] 

if not exists(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SS_LOJA_OPERACOES_VENDA_MOTIVOS_DESCONTO') 
	CREATE TABLE SS_LOJA_OPERACOES_VENDA_MOTIVOS_DESCONTO(CODIGO_DESCONTO char(2) NOT NULL,OPERACAO_VENDA  CHAR(3) NOT NULL,
	CONSTRAINT [PK_SS_LOJA_OPERACOES_VENDA_MOTIVOS_DESCONTO] PRIMARY KEY NONCLUSTERED(	CODIGO_DESCONTO ASC,OPERACAO_VENDA  ASC)
	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]) ON [PRIMARY]

If ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_MOTIVOS_DESCONTO' and column_name = 'INATIVO')=0
begin 
	execute ( 'ALTER TABLE LOJA_MOTIVOS_DESCONTO ADD INATIVO BIT')
end
begin  
	UPDATE LOJA_MOTIVOS_DESCONTO SET INATIVO = 0 WHERE INATIVO IS NULL
end
begin
	execute SP_BINDEFAULT 'DEFAULT_0', 'LOJA_MOTIVOS_DESCONTO.INATIVO'
end
if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_NOTA_FISCAL' and column_name = 'ROMANEIO_PRODUTO')=0 
begin 
	execute ( 'ALTER TABLE LOJA_NOTA_FISCAL ADD ROMANEIO_PRODUTO CHAR(15) NULL') 
end 
if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_ENTRADAS' and column_name = 'CHAVE_NFE')=0 
begin 
	execute ( 'ALTER TABLE LOJA_ENTRADAS ADD CHAVE_NFE VARCHAR(44) NULL') 
end 
if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_ENTRADAS' and column_name = 'CTB_TIPO_OPERACAO')=0 
begin 
	execute ( 'ALTER TABLE LOJA_ENTRADAS ADD CTB_TIPO_OPERACAO INT NULL') 
end 
if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_TRANSITO' and column_name = 'CHAVE_NFE')=0 
begin 
	execute ( 'ALTER TABLE LOJA_TRANSITO ADD CHAVE_NFE VARCHAR(44) NULL') 
end 

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_TRANSITO' and column_name = 'CTB_TIPO_OPERACAO')=0 
begin 
	execute ( 'ALTER TABLE LOJA_TRANSITO ADD CTB_TIPO_OPERACAO INT NULL') 
end 

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'TICKET_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD TICKET_ORIGEM CHAR(8) NULL')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'NUMERO_CUPOM_FISCAL_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD NUMERO_CUPOM_FISCAL_ORIGEM VARCHAR(8) NULL')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'TICKET_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD TICKET_ORIGEM CHAR(8) NULL')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'DATA_VENDA_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD DATA_VENDA_ORIGEM DATETIME')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'CODIGO_FILIAL_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD CODIGO_FILIAL_ORIGEM CHAR(6)')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'STATUS_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD  STATUS_ORIGEM INT')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'TERMINAL_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD TERMINAL_ORIGEM CHAR(3)')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'ECF_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD ECF_ORIGEM INT')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'MOTIVO_AUTORIZACAO')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD MOTIVO_AUTORIZACAO VARCHAR(50)')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA' and column_name = 'SENHA_SUPERVISOR')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA ADD SENHA_SUPERVISOR VARCHAR(50)')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJAS_NATUREZA_OPERACAO' and column_name = 'TIPO_VALIDACAO_MATRIZ')=0
begin 
	execute ( 'alter table LOJAS_NATUREZA_OPERACAO add TIPO_VALIDACAO_MATRIZ INT ')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA_ORIGEM' and column_name = 'NUMERO_CUPOM_FISCAL_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA_ORIGEM ADD NUMERO_CUPOM_FISCAL_ORIGEM VARCHAR(15) NULL')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA_ORIGEM' and column_name = 'ECF_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA_ORIGEM ADD ECF_ORIGEM INT')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA_ORIGEM' and column_name = 'MODELO_FISCAL_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA_ORIGEM ADD MODELO_FISCAL_ORIGEM VARCHAR(2)')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA_ORIGEM' and column_name = 'CHAVE_NFE_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA_ORIGEM ADD CHAVE_NFE_ORIGEM VARCHAR(44)')
end  

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_VENDA_TROCA_ORIGEM' and column_name = 'ATUALIZACAO_MANUAL')=0
begin 
	execute ( 'ALTER TABLE LOJA_VENDA_TROCA_ORIGEM ADD ATUALIZACAO_MANUAL BIT')
	EXECUTE('SP_BINDEFAULT ''DEFAULT_0'', ''LOJA_VENDA_TROCA_ORIGEM.ATUALIZACAO_MANUAL''')
end 

if ( select count(*) as qtde from information_schema.columns c where table_name = 'LOJA_TRANSITO' and column_name = 'CHAVE_NFE_ORIGEM')=0
begin 
	execute ( 'ALTER TABLE LOJA_TRANSITO ADD CHAVE_NFE_ORIGEM VARCHAR(44)')
end  
