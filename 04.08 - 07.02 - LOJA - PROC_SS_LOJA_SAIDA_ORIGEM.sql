ALTER PROCEDURE PROC_SS_LOJA_SAIDA_ORIGEM (@pFilial varchar(25), @pRomaneioSaida varchar(8))

/*Tiago Carvalho (SS) - 13/10/2015 - Alterado para retornar erro caso o saldo final seja menor ou igual a zero.*/
/*Tiago Carvalho (SS) - 28/06/2015 - Alterado para não preencher a OBs da Nota Fiscal porque a view w_impressao_Nfe já preenche com base nas notas Dev.*/
/*Tiago Carvalho (SS) - 18/06/2015 - Alterado só pegar entradas com o ctb_tipo_operacao (100,120) venda e transferencia */
/*Tiago Carvalho (SS) - 14/06/2015 - Alterado para Não recalcular Saidas Canceladas ou qtde_total igual a zero*/
/*Tiago Carvalho (SS) - 11/06/2015 - Alterado a estrutura da procedure para fazer a verificação po SKU*/
AS
BEGIN
set nocount on 
declare @RomaneioProduto char(15),
		@RomaneioProdutoEntrada char(15),
		@Filial			varchar(25),
		@FilialEntrada	varchar(25),
		@cnpjDestino	varchar(19),
		@errmsg         varchar(max),
		@Produto		varchar(12),
		@produtoEntrada varchar(12),
		@CorProduto		varchar(10),
		@corProdutoEntrada varchar(10),
		@tamanhoEntrada	int,
		@qtde			int,
		@tamanho		int,
		@ProdutoSemSaldo varchar(12),
		@qtdeSaidaSemSaldo int ,
		@qtdeDisponivelSemSaldo int ,	
		@qtdeDiferencaSemSaldo int,
		@count					int,
		@script			varchar(max),
		@Obs			varchar(max),
		@TextoObs		varchar(max),
		@ChaveNFe		varchar(44)
					
select 	@RomaneioProduto =@pRomaneioSaida,
		@Filial =@pFilial,
		@errmsg =''


SELECT @ChaveNFe =C.CHAVE_NFE 
	FROM LOJA_SAIDAS A
	INNER JOIN LOJAS_VAREJO B
		ON A.FILIAL = B.FILIAL 
	INNER JOIN LOJA_NOTA_FISCAL C
		ON C.CODIGO_FILIAL = B.CODIGO_FILIAL AND A.NUMERO_NF_TRANSFERENCIA = C.NF_NUMERO AND C.SERIE_NF = A.SERIE_NF 
	WHERE A.ROMANEIO_PRODUTO = @pRomaneioSaida
		AND A.FILIAL = @pFilial

SELECT @cnpjDestino = B.CGC_CPF 
	FROM LOJA_SAIDAS A(NOLOCK)
	inner join CADASTRO_CLI_FOR B(NOLOCK) 
		on A.FILIAL_DESTINO = B.NOME_CLIFOR 
	where A.FILIAL =@Filial
		AND A.ROMANEIO_PRODUTO = @RomaneioProduto
	
IF EXISTS (SELECT ROMANEIO_PRODUTO FROM LOJA_SAIDAS_ORIGEM(NOLOCK) WHERE ROMANEIO_PRODUTO = @RomaneioProduto AND FILIAL = @Filial )
BEGIN
	DELETE LOJA_SAIDAS_ORIGEM WHERE ROMANEIO_PRODUTO = @RomaneioProduto AND FILIAL = @Filial 
END

DELETE A 
FROM LOJA_SAIDAS_ORIGEM A 
INNER JOIN LOJA_SAIDAS B
	ON A.ROMANEIO_PRODUTO = B.ROMANEIO_PRODUTO
	AND A.FILIAL = B.FILIAL
WHERE (B.SAIDA_CANCELADA = 1 OR B.QTDE_TOTAL = 0)

/*Atualiza a chave das entradas e o tipo de operação*/
INSERT INTO LOJA_TRANSITO (ROMANEIO_PRODUTO,FILIAL,CODIGO_TAB_PRECO,FILIAL_ORIGEM,TIPO_ENTRADA_SAIDA,NUMERO_NF_TRANSFERENCIA,SERIE_NF,FORNECEDOR,RESPONSAVEL,EMISSAO,OBS,QTDE_TOTAL,VALOR_TOTAL,FATOR_PRECO,LANCADO_LOJA,ROMANEIO_NF_SAIDA,DATA_PARA_TRANSFERENCIA,SERIE_NF_ENTRADA,ENTRADA_POR,CGC_FORNECEDOR,LX_STATUS_TRANSITO)
SELECT DISTINCT A.ROMANEIO_PRODUTO,A.FILIAL,A.CODIGO_TAB_PRECO,A.FILIAL_ORIGEM,A.TIPO_ENTRADA_SAIDA,A.NUMERO_NF_TRANSFERENCIA,A.SERIE_NF_ENTRADA,A.FORNECEDOR,A.RESPONSAVEL,A.EMISSAO,CONVERT(VARCHAR(MAX),A.OBS),A.QTDE_TOTAL,A.VALOR_TOTAL,A.FATOR_PRECO,LANCADO_LOJA=1,A.ROMANEIO_NF_SAIDA,A.DATA_PARA_TRANSFERENCIA,A.SERIE_NF_ENTRADA,A.ENTRADA_POR,A.CGC_FORNECEDOR,LX_STATUS_TRANSITO=3
FROM LOJA_ENTRADAS A(NOLOCK)
LEFT JOIN LOJA_TRANSITO B(NOLOCK)
	ON A.FILIAL = B.FILIAL AND A.FILIAL_ORIGEM = B.FILIAL_ORIGEM AND A.SERIE_NF_ENTRADA = B.SERIE_NF_ENTRADA AND A.NUMERO_NF_TRANSFERENCIA = B.NUMERO_NF_TRANSFERENCIA 
LEFT JOIN LOJA_TRANSITO C (NOLOCK)
	ON A.FILIAL = C.FILIAL AND A.ROMANEIO_PRODUTO = C.ROMANEIO_PRODUTO
WHERE B.ROMANEIO_PRODUTO IS NULL
	AND C.ROMANEIO_PRODUTO IS NULL
		
UPDATE A
		SET A.CHAVE_NFE = B.CHAVE_NFE,A.CHAVE_NFE_ORIGEM = ISNULL(A.CHAVE_NFE_ORIGEM ,B.CHAVE_NFE) ,A.CTB_TIPO_OPERACAO = B.CTB_TIPO_OPERACAO
	FROM LOJA_TRANSITO A
	INNER JOIN SS_CHAVE_NFE_ORIGEM B(NOLOCK)
		ON A.FILIAL_ORIGEM = B.FILIAL_ORIGEM AND A.SERIE_NF_ENTRADA = B.SERIE_NF AND RIGHT('000000000000000'+ LTRIM(RTRIM(A.NUMERO_NF_TRANSFERENCIA)),15) = RIGHT('000000000000000'+ LTRIM(RTRIM(B.NF)),15)
	WHERE A.CHAVE_NFE IS NULL OR A.CHAVE_NFE_ORIGEM IS NULL

UPDATE A
		SET A.CHAVE_NFE = B.CHAVE_NFE ,A.CTB_TIPO_OPERACAO = B.CTB_TIPO_OPERACAO 
	FROM LOJA_ENTRADAS A
	INNER JOIN SS_CHAVE_NFE_ORIGEM B(NOLOCK)
		ON A.FILIAL_ORIGEM = B.FILIAL_ORIGEM AND A.SERIE_NF_ENTRADA = B.SERIE_NF AND RIGHT('000000000000000'+ LTRIM(RTRIM(A.NUMERO_NF_TRANSFERENCIA)),15) = RIGHT('000000000000000'+ LTRIM(RTRIM(B.NF)),15)
	WHERE A.CHAVE_NFE IS NULL 

IF OBJECT_ID('TEMPDB..#TmpLojaSaidaOrigem') > 0 
	DROP TABLE #TmpLojaSaidaOrigem
	
select ROMANEIO_PRODUTO,FILIAL,PRODUTO,COR_PRODUTO,ROMANEIO_PRODUTO_ENTRADA,FILIAL_ENTRADA,QTDE_ENTRADA,EN1,EN2,EN3,EN4,EN5,EN6,EN7,EN8,EN9,EN10,EN11,EN12,EN13,EN14,EN15,EN16,EN17,EN18,EN19,EN20,EN21,EN22,EN23,EN24,EN25,EN26,EN27,EN28,EN29,EN30,EN31,EN32,EN33,EN34,EN35,EN36,EN37,EN38,EN39,EN40,EN41,EN42,EN43,EN44,EN45,EN46,EN47,EN48 
	into #TmpLojaSaidaOrigem
	from LOJA_SAIDAS_ORIGEM(nolock) where 1=0
		
IF OBJECT_ID('TEMPDB..#GRADE48') > 0 
	DROP TABLE #GRADE48

/*Coloco uma tabela com a grade 48 para eu conseguir fazer por tamanho sem usar a view da LINX para não ficar lento*/	
SELECT ORDEM INTO #GRADE48
from (	SELECT ORDEM =1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
						SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL 
						SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL 
						SELECT 23 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29 UNION ALL 
						SELECT 30 UNION ALL SELECT 31 UNION ALL SELECT 32 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35 UNION ALL SELECT 36 UNION ALL 
						SELECT 37 UNION ALL SELECT 38 UNION ALL SELECT 39 UNION ALL SELECT 40 UNION ALL SELECT 41 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL 
						SELECT 44 UNION ALL SELECT 45 UNION ALL SELECT 46 UNION ALL SELECT 47 UNION ALL SELECT 48) as grade48

IF OBJECT_ID('TEMPDB..#TmpSaidaProdutos') > 0 
	DROP TABLE #TmpSaidaProdutos
					
/*guarda os produtos da saída por tamanho para conseguir abater grade a grade, incluindo ao maximo a grade correta*/					
SELECT ROMANEIO_PRODUTO, FILIAL , PRODUTO, COR_PRODUTO , TAMANHO, 
	QTDE = SUM(QTDE)
	into #TmpSaidaProdutos
	FROM ( SELECT ROMANEIO_PRODUTO , FILIAL ,A.PRODUTO,COR_PRODUTO ,TAMANHO = C.ORDEM,
					QTDE = CASE C.ORDEM WHEN 1 THEN A.EN1	WHEN 2 THEN A.EN2	WHEN 3 THEN A.EN3	WHEN 4 THEN A.EN4	WHEN 5 THEN A.EN5	WHEN 6 THEN A.EN6
										WHEN 7 THEN A.EN7	WHEN 8 THEN A.EN8	WHEN 9 THEN A.EN9	WHEN 10 THEN A.EN10	WHEN 11 THEN A.EN11	WHEN 12 THEN A.EN12	WHEN 13 THEN A.EN13
										WHEN 14 THEN A.EN14	WHEN 15 THEN A.EN15	WHEN 16 THEN A.EN16	WHEN 17 THEN A.EN17	WHEN 18 THEN A.EN18	WHEN 19 THEN A.EN19	WHEN 20 THEN A.EN20
										WHEN 21 THEN A.EN21	WHEN 22 THEN A.EN22	WHEN 23 THEN A.EN23	WHEN 24 THEN A.EN24	WHEN 25 THEN A.EN25	WHEN 26 THEN A.EN26	WHEN 27 THEN A.EN27
										WHEN 28 THEN A.EN28	WHEN 29 THEN A.EN29	WHEN 30 THEN A.EN30	WHEN 31 THEN A.EN31	WHEN 32 THEN A.EN32	WHEN 33 THEN A.EN33	WHEN 34 THEN A.EN34
										WHEN 35 THEN A.EN35	WHEN 36 THEN A.EN36	WHEN 37 THEN A.EN37	WHEN 38 THEN A.EN38	WHEN 39 THEN A.EN39	WHEN 40 THEN A.EN40	WHEN 41 THEN A.EN41
										WHEN 42 THEN A.EN42	WHEN 43 THEN A.EN43	WHEN 44 THEN A.EN44	WHEN 45 THEN A.EN45	WHEN 46 THEN A.EN46	WHEN 47 THEN A.EN47	WHEN 48 THEN A.EN48
							END
				FROM LOJA_SAIDAS_PRODUTO A(NOLOCK),
				#grade48 C(nolock)
				WHERE  A.ROMANEIO_PRODUTO =@RomaneioProduto
					AND A.FILIAL =@Filial
					AND (EN1+EN2+EN3+EN4+EN5+EN6+EN7+EN8+EN9+EN10+EN11+EN12+EN13+EN14+EN15+EN16+EN17+EN18+EN19+EN20+EN21+EN22+EN23+EN24+EN25+EN26+EN27+EN28+EN29+EN30+EN31+EN32+EN33+EN34+EN35+EN36+EN37+EN38+EN39+EN40+EN41+EN42+EN43+EN44+EN45+EN46+EN47+EN48) > 0 
		) SAIDA
	WHERE QTDE> 0 
GROUP BY ROMANEIO_PRODUTO, FILIAL , PRODUTO, COR_PRODUTO , TAMANHO

if exists (select 1 from #TmpSaidaProdutos)
begin
	IF OBJECT_ID('TEMPDB..#SaldoEntrada') > 0 
		DROP TABLE #SaldoEntrada
		
	/*Guardo os saldos disponíveis para devolução de todos os produtos da saída*/					
	SELECT	A.FILIAL,
			A.ROMANEIO_PRODUTO,
			B.FILIAL_ORIGEM AS FILIAL_ENTRADA, 
			A.PRODUTO,
			A.COR_PRODUTO,
			C.CGC_CPF,
			#grade48.ORDEM,
			QTDE = CASE #grade48.ORDEM WHEN 1 THEN A.EN1	WHEN 2 THEN A.EN2	WHEN 3 THEN A.EN3	WHEN 4 THEN A.EN4	WHEN 5 THEN A.EN5	WHEN 6 THEN A.EN6
											WHEN 7 THEN A.EN7	WHEN 8 THEN A.EN8	WHEN 9 THEN A.EN9	WHEN 10 THEN A.EN10	WHEN 11 THEN A.EN11	WHEN 12 THEN A.EN12	WHEN 13 THEN A.EN13
											WHEN 14 THEN A.EN14	WHEN 15 THEN A.EN15	WHEN 16 THEN A.EN16	WHEN 17 THEN A.EN17	WHEN 18 THEN A.EN18	WHEN 19 THEN A.EN19	WHEN 20 THEN A.EN20
											WHEN 21 THEN A.EN21	WHEN 22 THEN A.EN22	WHEN 23 THEN A.EN23	WHEN 24 THEN A.EN24	WHEN 25 THEN A.EN25	WHEN 26 THEN A.EN26	WHEN 27 THEN A.EN27
											WHEN 28 THEN A.EN28	WHEN 29 THEN A.EN29	WHEN 30 THEN A.EN30	WHEN 31 THEN A.EN31	WHEN 32 THEN A.EN32	WHEN 33 THEN A.EN33	WHEN 34 THEN A.EN34
											WHEN 35 THEN A.EN35	WHEN 36 THEN A.EN36	WHEN 37 THEN A.EN37	WHEN 38 THEN A.EN38	WHEN 39 THEN A.EN39	WHEN 40 THEN A.EN40	WHEN 41 THEN A.EN41
											WHEN 42 THEN A.EN42	WHEN 43 THEN A.EN43	WHEN 44 THEN A.EN44	WHEN 45 THEN A.EN45	WHEN 46 THEN A.EN46	WHEN 47 THEN A.EN47	WHEN 48 THEN A.EN48
								END
	into #SaldoEntrada
	FROM LOJA_ENTRADAS B(NOLOCK)
	INNER JOIN LOJA_ENTRADAS_PRODUTO A(NOLOCK)
		ON A.ROMANEIO_PRODUTO = B.ROMANEIO_PRODUTO AND A.FILIAL = B.FILIAL 
	INNER JOIN (SELECT FILIAL, PRODUTO FROM #TmpSaidaProdutos GROUP BY FILIAL, PRODUTO )SAIDA
		ON A.FILIAL = SAIDA.FILIAL AND A.PRODUTO = SAIDA.PRODUTO 
	INNER JOIN CADASTRO_CLI_FOR C(NOLOCK)
		ON B.FILIAL_ORIGEM = C.NOME_CLIFOR 
	INNER JOIN #grade48
		ON 1=1
	WHERE A.FILIAL =@Filial
		AND C.CGC_CPF = @cnpjDestino
		AND B.CTB_TIPO_OPERACAO IN(100,120)
		AND (EN1+EN2+EN3+EN4+EN5+EN6+EN7+EN8+EN9+EN10+EN11+EN12+EN13+EN14+EN15+EN16+EN17+EN18+EN19+EN20+EN21+EN22+EN23+EN24+EN25+EN26+EN27+EN28+EN29+EN30+EN31+EN32+EN33+EN34+EN35+EN36+EN37+EN38+EN39+EN40+EN41+EN42+EN43+EN44+EN45+EN46+EN47+EN48) > 0 

	IF OBJECT_ID('TEMPDB..#SaldoSaida') > 0 
		DROP TABLE #SaldoSaida
		
	/*Saldo com as saidas com esse produto para abater dos romaneios de entrada*/
	SELECT  b.FILIAL,
			b.ROMANEIO_PRODUTO, 
			B.FILIAL_ORIGEM AS FILIAL_ENTRADA, 
			a.PRODUTO,
			a.COR_PRODUTO,
			C.CGC_CPF,
			#grade48.ORDEM,
		QTDE = CASE #grade48.ORDEM WHEN 1 THEN -A.EN1	WHEN 2 THEN -A.EN2	WHEN 3 THEN -A.EN3	WHEN 4 THEN -A.EN4	WHEN 5 THEN -A.EN5	WHEN 6 THEN -A.EN6
								WHEN 7 THEN -A.EN7	WHEN 8 THEN -A.EN8	WHEN 9 THEN -A.EN9	WHEN 10 THEN -A.EN10	WHEN 11 THEN -A.EN11	WHEN 12 THEN -A.EN12	WHEN 13 THEN -A.EN13
								WHEN 14 THEN -A.EN14	WHEN 15 THEN -A.EN15	WHEN 16 THEN -A.EN16	WHEN 17 THEN -A.EN17	WHEN 18 THEN -A.EN18	WHEN 19 THEN -A.EN19	WHEN 20 THEN -A.EN20
								WHEN 21 THEN -A.EN21	WHEN 22 THEN -A.EN22	WHEN 23 THEN -A.EN23	WHEN 24 THEN -A.EN24	WHEN 25 THEN -A.EN25	WHEN 26 THEN -A.EN26	WHEN 27 THEN -A.EN27
								WHEN 28 THEN -A.EN28	WHEN 29 THEN -A.EN29	WHEN 30 THEN -A.EN30	WHEN 31 THEN -A.EN31	WHEN 32 THEN -A.EN32	WHEN 33 THEN -A.EN33	WHEN 34 THEN -A.EN34
								WHEN 35 THEN -A.EN35	WHEN 36 THEN -A.EN36	WHEN 37 THEN -A.EN37	WHEN 38 THEN -A.EN38	WHEN 39 THEN -A.EN39	WHEN 40 THEN -A.EN40	WHEN 41 THEN -A.EN41
								WHEN 42 THEN -A.EN42	WHEN 43 THEN -A.EN43	WHEN 44 THEN -A.EN44	WHEN 45 THEN -A.EN45	WHEN 46 THEN -A.EN46	WHEN 47 THEN -A.EN47	WHEN 48 THEN -A.EN48
					END
	into #SaldoSaida
	FROM LOJA_ENTRADAS b(NOLOCK)
	INNER JOIN LOJA_SAIDAS_ORIGEM a(NOLOCK)
		ON b.ROMANEIO_PRODUTO = a.ROMANEIO_PRODUTO_ENTRADA AND A.FILIAL = B.FILIAL  
	INNER JOIN (SELECT FILIAL, PRODUTO FROM #TmpSaidaProdutos GROUP BY FILIAL, PRODUTO )SAIDA
		ON a.FILIAL = SAIDA.FILIAL AND a.PRODUTO = SAIDA.PRODUTO 
	INNER JOIN #grade48
		on 1=1
	INNER JOIN CADASTRO_CLI_FOR C(NOLOCK)
		ON b.FILIAL_ORIGEM = c.NOME_CLIFOR 
	WHERE b.FILIAL =@Filial
		AND C.CGC_CPF = @cnpjDestino
		AND B.CTB_TIPO_OPERACAO IN(100,120)
		AND (EN1+EN2+EN3+EN4+EN5+EN6+EN7+EN8+EN9+EN10+EN11+EN12+EN13+EN14+EN15+EN16+EN17+EN18+EN19+EN20+EN21+EN22+EN23+EN24+EN25+EN26+EN27+EN28+EN29+EN30+EN31+EN32+EN33+EN34+EN35+EN36+EN37+EN38+EN39+EN40+EN41+EN42+EN43+EN44+EN45+EN46+EN47+EN48) > 0 

	IF OBJECT_ID('TEMPDB..#saldoFinal') > 0 
		DROP TABLE #saldoFinal
		
	SELECT  FILIAL, ROMANEIO_PRODUTO,FILIAL_ENTRADA, PRODUTO, COR_PRODUTO, CGC_CPF, ORDEM, QTDE = SUM(QTDE) 
		INTO #saldoFinal
		FROM (	select * from #SaldoEntrada 
					union all 
				select * from #SaldoSaida
			 ) as saldoFinal
		group by FILIAL, ROMANEIO_PRODUTO, PRODUTO, COR_PRODUTO, CGC_CPF, ORDEM,FILIAL_ENTRADA


	if not exists (select produto from #saldoFinal where QTDE > 0 )
	begin
		SELECT	@errmsg = 'Não existe saldo a devolver disponível para nenhum produto da saída'
		goto error 
	end

	IF OBJECT_ID('TEMPDB..#ProdutosSemSaldo') > 0 
		DROP TABLE #ProdutosSemSaldo
		
	select A.PRODUTO, QTDE_SAIDA = A.QTDE , QTDE_DISPONIVEL =ISNULL(B.QTDE,0),QTDE_DIFERENCA = A.QTDE - ISNULL(B.QTDE,0)
		into #ProdutosSemSaldo
		from (select FILIAL, PRODUTO, QTDE=SUM(QTDE) from #TmpSaidaProdutos GROUP BY  FILIAL, PRODUTO) A
		LEFT JOIN (select FILIAL, PRODUTO, QTDE=SUM(QTDE) from #saldoFinal GROUP BY  FILIAL, PRODUTO) B
			ON A.FILIAL = B.FILIAL AND A.PRODUTO = B.PRODUTO 
		where a.QTDE - isnull(b.QTDE,0) > 0 

	if exists (select produto from #ProdutosSemSaldo)	
		begin
			SELECT @errmsg = ''
			DECLARE curProdutosSemSaldo cursor for
			SELECT PRODUTO ,QTDE_SAIDA , QTDE_DISPONIVEL , QTDE_DIFERENCA  from #ProdutosSemSaldo
			
			OPEN curProdutosSemSaldo
			fetch next from curProdutosSemSaldo into @ProdutoSemSaldo, @qtdeSaidaSemSaldo, @qtdeDisponivelSemSaldo, @qtdeDiferencaSemSaldo 
			
			while @@FETCH_STATUS =0
			begin 
				SELECT @errmsg = @errmsg +	' Produto:' + RTRIM(LTRIM(@ProdutoSemSaldo))+ 
											' Qtde Saida:' + CONVERT(varchar(12),@qtdeSaidaSemSaldo)+
											' Qtde Disponível:' + CONVERT(varchar(12),@qtdeDisponivelSemSaldo)+
											' Qtde Diferença:' + CONVERT(varchar(12),@qtdeDiferencaSemSaldo)+CHAR(10)
				
				fetch next from curProdutosSemSaldo into @ProdutoSemSaldo, @qtdeSaidaSemSaldo, @qtdeDisponivelSemSaldo, @qtdeDiferencaSemSaldo 
			END
			CLOSE 	curProdutosSemSaldo
			DEALLOCATE curProdutosSemSaldo
			GoTo Error
		end

	/* Atualiza a origem com base na saída recuperada tentando */
	DECLARE CurSaldoSaida cursor for
	SELECT PRODUTO, COR_PRODUTO, TAMANHO, QTDE from #TmpSaidaProdutos

	OPEN CurSaldoSaida
	fetch next from CurSaldoSaida into @produto, @corproduto, @tamanho, @qtde 

	while @@FETCH_STATUS =0
	begin 
		/*Procuro o mesmo produto/cor/tamanho, enquanto exitir saldo vou matando e diminuindo a qtde*/
		while exists (select 1 from #saldoFinal where PRODUTO =@Produto and COR_PRODUTO =@CorProduto and ORDEM = @tamanho and QTDE > 0 and @qtde > 0 )
			begin 
				select top 1 @RomaneioProdutoEntrada = ROMANEIO_PRODUTO, @produtoEntrada = PRODUTO, @corProdutoEntrada = COR_PRODUTO, @tamanhoEntrada = ORDEM, @FilialEntrada = FILIAL_ENTRADA
				from #saldoFinal where PRODUTO =@Produto and COR_PRODUTO =@CorProduto and ORDEM = @tamanho and QTDE > 0
				order by ROMANEIO_PRODUTO ,FILIAL_ENTRADA 
					
				SET @SCRIPT =   'INSERT INTO #TmpLojaSaidaOrigem (ROMANEIO_PRODUTO,FILIAL,PRODUTO,COR_PRODUTO,ROMANEIO_PRODUTO_ENTRADA,FILIAL_ENTRADA,QTDE_ENTRADA,EN'+ LTRIM(RTRIM(CONVERT(VARCHAR(2),@tamanhoEntrada)))+')'+
								'VALUES('+ char(39)+ @RomaneioProduto +char(39)+ ',' + char(39)+ @Filial +char(39)+ ',' + char(39)+ @produtoEntrada +char(39)+ ',' + char(39)+ @corProdutoEntrada +char(39)+ ',' + char(39)+ @RomaneioProdutoEntrada +char(39)+ ',' + char(39)+ @FilialEntrada +char(39)+ ',' +	char(39)+ '1' +char(39)+ ',' + char(39)+ '1' +char(39)+ ')' 
				
				IF @SCRIPT IS NULL
					BEGIN  
						SELECT  @ERRMSG = 'Erro ao Gerar o Script para Inserir a Saida'
						GOTO ERROR  
					END 
				
				execute(@SCRIPT)
			
				update #saldoFinal set QTDE = QTDE - 1 where  ROMANEIO_PRODUTO = @RomaneioProdutoEntrada and PRODUTO =  @produtoEntrada  and COR_PRODUTO = @corProdutoEntrada  and ORDEM = @tamanhoEntrada and FILIAL_ENTRADA = @FilialEntrada 
					
				select @qtde = @qtde - 1 
				
			end
		
		/*Procuro o mesmo produto/cor em Qualquer Outro Tamanho se não tiver acabado a quantidade*/
		while exists (select 1 from #saldoFinal where PRODUTO =@Produto and COR_PRODUTO =@CorProduto and QTDE > 0 and @qtde > 0 )
			begin 
				select top 1 @RomaneioProdutoEntrada = ROMANEIO_PRODUTO, @produtoEntrada = PRODUTO, @corProdutoEntrada = COR_PRODUTO, @tamanhoEntrada = ORDEM, @FilialEntrada = FILIAL_ENTRADA
				from #saldoFinal where PRODUTO =@Produto and COR_PRODUTO =@CorProduto and QTDE > 0
				order by ROMANEIO_PRODUTO ,FILIAL_ENTRADA 
					
				SET @SCRIPT =   'INSERT INTO #TmpLojaSaidaOrigem (ROMANEIO_PRODUTO,FILIAL,PRODUTO,COR_PRODUTO,ROMANEIO_PRODUTO_ENTRADA,FILIAL_ENTRADA,QTDE_ENTRADA,EN'+ LTRIM(RTRIM(CONVERT(VARCHAR(2),@tamanhoEntrada)))+')'+
								'VALUES('+ char(39)+ @RomaneioProduto +char(39)+ ',' + char(39)+ @Filial +char(39)+ ',' + char(39)+ @produtoEntrada +char(39)+ ',' + char(39)+ @corProdutoEntrada +char(39)+ ',' + char(39)+ @RomaneioProdutoEntrada +char(39)+ ',' + char(39)+ @FilialEntrada +char(39)+ ',' +	char(39)+ '1' +char(39)+ ',' + char(39)+ '1' +char(39)+ ')' 
				
				IF @SCRIPT IS NULL
					BEGIN  
						SELECT  @ERRMSG = 'Erro ao Gerar o Script para Inserir a Saida'
						GOTO ERROR  
					END 
				
				execute(@SCRIPT)
			
				update #saldoFinal set QTDE = QTDE - 1 where  ROMANEIO_PRODUTO = @RomaneioProdutoEntrada and PRODUTO =  @produtoEntrada  and COR_PRODUTO = @corProdutoEntrada  and ORDEM = @tamanhoEntrada and FILIAL_ENTRADA = @FilialEntrada 
					
				select @qtde = @qtde - 1 
			end
		
		/*Procuro o mesmo produto em Qualquer Outro Tamanho/Cor se não tiver acabado a quantidade*/
		while exists (select 1 from #saldoFinal where PRODUTO =@Produto and QTDE > 0 and @qtde > 0 )
			begin 
				select top 1 @RomaneioProdutoEntrada = ROMANEIO_PRODUTO, @produtoEntrada = PRODUTO, @corProdutoEntrada = COR_PRODUTO, @tamanhoEntrada = ORDEM, @FilialEntrada = FILIAL_ENTRADA
				from #saldoFinal where PRODUTO = @Produto and QTDE > 0 order by ROMANEIO_PRODUTO ,FILIAL_ENTRADA 
					
				SET @SCRIPT =   'INSERT INTO #TmpLojaSaidaOrigem (ROMANEIO_PRODUTO,FILIAL,PRODUTO,COR_PRODUTO,ROMANEIO_PRODUTO_ENTRADA,FILIAL_ENTRADA,QTDE_ENTRADA,EN'+ LTRIM(RTRIM(CONVERT(VARCHAR(2),@tamanhoEntrada)))+')'+
								'VALUES('+ char(39)+ @RomaneioProduto +char(39)+ ',' + char(39)+ @Filial +char(39)+ ',' + char(39)+ @produtoEntrada +char(39)+ ',' + char(39)+ @corProdutoEntrada +char(39)+ ',' + char(39)+ @RomaneioProdutoEntrada +char(39)+ ',' + char(39)+ @FilialEntrada +char(39)+ ',' +	char(39)+ '1' +char(39)+ ',' + char(39)+ '1' +char(39)+ ')' 
				
				IF @SCRIPT IS NULL
					BEGIN  
						SELECT  @ERRMSG = 'Erro ao Gerar o Script para Inserir a Saida'
						GOTO ERROR  
					END 
				
				execute(@SCRIPT)
			
				update #saldoFinal set QTDE = QTDE - 1 where  ROMANEIO_PRODUTO = @RomaneioProdutoEntrada and PRODUTO =  @produtoEntrada  and COR_PRODUTO = @corProdutoEntrada  and ORDEM = @tamanhoEntrada and FILIAL_ENTRADA = @FilialEntrada 
					
				select @qtde = @qtde - 1 
			end

		fetch next from CurSaldoSaida into @produto, @corproduto, @tamanho, @qtde 
	END

	CLOSE 	CurSaldoSaida
	DEALLOCATE CurSaldoSaida

	insert into LOJA_SAIDAS_ORIGEM ( ROMANEIO_PRODUTO, FILIAL,PRODUTO,COR_PRODUTO,ROMANEIO_PRODUTO_ENTRADA,FILIAL_ENTRADA,QTDE_ENTRADA,EN1,EN2,EN3,EN4,EN5,EN6,EN7,EN8,EN9,EN10,EN11,EN12,EN13,EN14,EN15,EN16,EN17,EN18,EN19,EN20,EN21,EN22,EN23,EN24,EN25,EN26,EN27,EN28,EN29,EN30,EN31,EN32,EN33,EN34,EN35,EN36,EN37,EN38,EN39,EN40,EN41,EN42,EN43,EN44,EN45,EN46,EN47,EN48 )
	select ROMANEIO_PRODUTO,FILIAL,PRODUTO,COR_PRODUTO,ROMANEIO_PRODUTO_ENTRADA,FILIAL_ENTRADA,
		QTDE_ENTRADA = SUM(isnull(QTDE_ENTRADA,0) ),EN1=sum(isnull(EN1,0)),EN2=sum(isnull(EN2,0)),EN3=sum(isnull(EN3,0)),EN4=sum(isnull(EN4,0)),EN5=sum(isnull(EN5,0)),EN6=sum(isnull(EN6,0)),EN7=sum(isnull(EN7,0)),EN8=sum(isnull(EN8,0)),EN9=sum(isnull(EN9,0)),EN10=sum(isnull(EN10,0)),
		EN11=sum(isnull(EN11,0)),EN12=sum(isnull(EN12,0)),EN13=sum(isnull(EN13,0)),EN14=sum(isnull(EN14,0)),EN15=sum(isnull(EN15,0)),EN16=sum(isnull(EN16,0)),EN17=sum(isnull(EN17,0)),EN18=sum(isnull(EN18,0)),EN19=sum(isnull(EN19,0)),EN20=sum(isnull(EN20,0)),EN21=sum(isnull(EN21,0)),
		EN22=sum(isnull(EN22,0)),EN23=sum(isnull(EN23,0)),EN24=sum(isnull(EN24,0)),EN25=sum(isnull(EN25,0)),EN26=sum(isnull(EN26,0)),EN27=sum(isnull(EN27,0)),EN28=sum(isnull(EN28,0)),EN29=sum(isnull(EN29,0)),EN30=sum(isnull(EN30,0)),EN31=sum(isnull(EN31,0)),EN32=sum(isnull(EN32,0)),
		EN33=sum(isnull(EN33,0)),EN34=sum(isnull(EN34,0)),EN35=sum(isnull(EN35,0)),EN36=sum(isnull(EN36,0)),EN37=sum(isnull(EN37,0)),EN38=sum(isnull(EN38,0)),EN39=sum(isnull(EN39,0)),EN40=sum(isnull(EN40,0)),EN41=sum(isnull(EN41,0)),EN42=sum(isnull(EN42,0)),EN43=sum(isnull(EN43,0)),
		EN44=sum(isnull(EN44,0)),EN45=sum(isnull(EN45,0)),EN46=sum(isnull(EN46,0)),EN47=sum(isnull(EN47,0)),EN48=sum(isnull(EN48,0))
	from #TmpLojaSaidaOrigem 
	group by ROMANEIO_PRODUTO,FILIAL,PRODUTO,COR_PRODUTO,ROMANEIO_PRODUTO_ENTRADA,FILIAL_ENTRADA

end

SELECT 'OK' as RETORNO	

SET NOCOUNT OFF

RETURN


error:
	 SELECT @errmsg as RETORNO
	--rollback transaction
end