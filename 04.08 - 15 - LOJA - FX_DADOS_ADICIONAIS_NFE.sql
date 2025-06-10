ALTER FUNCTION [dbo].[FX_DADOS_ADICIONAIS_NFE](@NOTAFISCAL VARCHAR(15), @SERIENOTA VARCHAR(6), @FILIALNOTA VARCHAR(25), @TIPO_NOTA CHAR(1))
RETURNS VARCHAR(5000)
as
-- Versão Hotfix 11 spk 3 - Julio --
/*Tiago Carvalho SS01 - Corrigido o Join para pegar a origem da nota fiscal de devolução*/
-- 19/10/2018 - Eder Silva   - DM 93003	- #2# - Correção no tamanho dos campos @NUMERO_NF_TRANSFERENCIA e @SERIE_NF_ENTRADA.
-- 20/09/2017 - Diego Moreno - DM 58430	- #1# - Adequacao NFE 4.00. Melhoria para atender ao layout 4.0.
begin 
	declare @ICMS_ZF_ALIQ numeric(14,5), @PIS_ZF_ALIQ numeric(14,5),  @COFINS_ZF_ALIQ numeric(14,5), --#1#
			@ICMS_ZF numeric(14,2), @PIS_ZF numeric(14,2),  @COFINS_ZF numeric(14,2), 
			@ICMS_ZF_BASE numeric(14,2), @PIS_ZF_BASE numeric(14,2),  @COFINS_ZF_BASE numeric(14,2), 
			@VALOR_IMPOSTO_AGREGAR numeric(14,2), @texto varchar(5000), @INSCRICAO_SUFRAMA char(9),
			@OBS_FAT varchar(5000)

	select  @OBS_FAT	= OBS, @INSCRICAO_SUFRAMA = CADASTRO_CLI_FOR.INSCRICAO_SUFRAMA,
			@ICMS_ZF		= dbo.fn_GetFiscalTax(LOJA_NOTA_FISCAL.CODIGO_FILIAL, LOJA_NOTA_FISCAL.NF_NUMERO, LOJA_NOTA_FISCAL.SERIE_NF, 36, 1), 
			@ICMS_ZF_BASE	= dbo.fn_GetFiscalTax(LOJA_NOTA_FISCAL.CODIGO_FILIAL, LOJA_NOTA_FISCAL.NF_NUMERO, LOJA_NOTA_FISCAL.SERIE_NF, 36, 2), 
			@ICMS_ZF_ALIQ	= dbo.fn_GetFiscalTax(LOJA_NOTA_FISCAL.CODIGO_FILIAL, LOJA_NOTA_FISCAL.NF_NUMERO, LOJA_NOTA_FISCAL.SERIE_NF, 36, 0), 
			@PIS_ZF			= dbo.fn_GetFiscalTax(LOJA_NOTA_FISCAL.CODIGO_FILIAL, LOJA_NOTA_FISCAL.NF_NUMERO, LOJA_NOTA_FISCAL.SERIE_NF, 37, 1), 
			@PIS_ZF_BASE	= dbo.fn_GetFiscalTax(LOJA_NOTA_FISCAL.CODIGO_FILIAL, LOJA_NOTA_FISCAL.NF_NUMERO, LOJA_NOTA_FISCAL.SERIE_NF, 37, 2), 
			@PIS_ZF_ALIQ	= dbo.fn_GetFiscalTax(LOJA_NOTA_FISCAL.CODIGO_FILIAL, LOJA_NOTA_FISCAL.NF_NUMERO, LOJA_NOTA_FISCAL.SERIE_NF, 37, 0), 
			@COFINS_ZF		= dbo.fn_GetFiscalTax(LOJA_NOTA_FISCAL.CODIGO_FILIAL, LOJA_NOTA_FISCAL.NF_NUMERO, LOJA_NOTA_FISCAL.SERIE_NF, 38, 1), 
			@COFINS_ZF_BASE = dbo.fn_GetFiscalTax(LOJA_NOTA_FISCAL.CODIGO_FILIAL, LOJA_NOTA_FISCAL.NF_NUMERO, LOJA_NOTA_FISCAL.SERIE_NF, 38, 2), 
			@COFINS_ZF_ALIQ = dbo.fn_GetFiscalTax(LOJA_NOTA_FISCAL.CODIGO_FILIAL, LOJA_NOTA_FISCAL.NF_NUMERO, LOJA_NOTA_FISCAL.SERIE_NF, 38, 0) 
	FROM LOJA_NOTA_FISCAL  (NOLOCK) 
		LEFT JOIN CADASTRO_CLI_FOR (NOLOCK)  ON LOJA_NOTA_FISCAL.COD_CLIFOR = CADASTRO_CLI_FOR.COD_CLIFOR 
		INNER JOIN LOJAS_VAREJO (NOLOCK)  ON LOJAS_VAREJO.CODIGO_FILIAL = LOJA_NOTA_FISCAL.CODIGO_FILIAL
		WHERE LOJA_NOTA_FISCAL.NF_NUMERO	= @NOTAFISCAL
			AND LOJA_NOTA_FISCAL.SERIE_NF		= @SERIENOTA
			AND LOJAS_VAREJO.FILIAL	= @FILIALNOTA  	
	
	select @TEXTO = ''

	IF @ICMS_ZF+@PIS_ZF+@COFINS_ZF > 0
		BEGIN 
			SELECT @TEXTO = @TEXTO+ CASE WHEN @INSCRICAO_SUFRAMA IS NULL OR @INSCRICAO_SUFRAMA = '' THEN '' ELSE  'Inscricao Suframa '+ LTRIM(@INSCRICAO_SUFRAMA)+'. ' END

			SELECT @TEXTO = @TEXTO+ CASE WHEN @ICMS_ZF+@PIS_ZF+@COFINS_ZF = 0 THEN '' ELSE 'Dedução total = ' END +LTRIM(RTRIM(STR(@ICMS_ZF+@PIS_ZF+@COFINS_ZF,14,2)))+'. Sendo: '+
				(CASE WHEN @ICMS_ZF_ALIQ >= 0 THEN LTRIM(RTRIM(STR(@ICMS_ZF_ALIQ,5,2)))+'% ICMS = ' +LTRIM(RTRIM(STR(@ICMS_ZF,14,2)))+', ' END + 
				 CASE WHEN @PIS_ZF_ALIQ >= 0  THEN LTRIM(RTRIM(STR(@PIS_ZF_ALIQ,5,2))) +'% PIS = ' +LTRIM(RTRIM(STR(@PIS_ZF,14,2)))+', ' END +
				 CASE WHEN @COFINS_ZF_ALIQ >= 0 THEN LTRIM(RTRIM(STR(@COFINS_ZF_ALIQ,5,2)))+'% COFINS = ' +LTRIM(RTRIM(STR(@COFINS_ZF,14,2)))+'. ' END )
		END 
	IF @OBS_FAT IS NOT NULL AND @OBS_FAT <> '' 
		SELECT @TEXTO = @TEXTO+' '+@OBS_FAT+'. '

----- Seleciona as notas de origem na devolução.

	Declare @NUMERO_NF_TRANSFERENCIA Char(15), @SERIE_NF_ENTRADA Char(6), @DATA_SAIDA DateTime, @VALOR_TOTAL Numeric(17,2), @Texto_Devolucao VarChar(1024), @LF VarChar(2)

	Declare curNotasFiscais Cursor Fast_Forward For 

	Select 
		A.NUMERO_NF_TRANSFERENCIA, A.SERIE_NF_ENTRADA, A.DATA_SAIDA, A.VALOR_TOTAL
	From 
		LOJA_ENTRADAS A 
		Inner Join LOJA_SAIDAS_ORIGEM B On A.FILIAL = B.FILIAL /*SS01*/ And A.ROMANEIO_PRODUTO = B.ROMANEIO_PRODUTO_ENTRADA
		Inner Join LOJA_SAIDAS C On B.FILIAL = C.FILIAL And B.ROMANEIO_PRODUTO = C.ROMANEIO_PRODUTO
		Inner Join LOJAS_VAREJO D On A.FILIAL = D.FILIAL
	Where 
		D.FILIAL = @FILIALNOTA AND  C.FILIAL = D.FILIAL And C.NUMERO_NF_TRANSFERENCIA = @NOTAFISCAL And C.SERIE_NF = @SERIENOTA
	Group By 
		A.NUMERO_NF_TRANSFERENCIA, A.SERIE_NF_ENTRADA, A.DATA_SAIDA, A.VALOR_TOTAL

	Set @LF = Char(13) + Char(10)

	Set @Texto_Devolucao = ''

	Open curNotasFiscais
	Fetch Next From curNotasFiscais Into @NUMERO_NF_TRANSFERENCIA, @SERIE_NF_ENTRADA, @DATA_SAIDA, @VALOR_TOTAL
	While @@FETCH_STATUS = 0
	Begin
		Set @Texto_Devolucao =	@Texto_Devolucao + 
								'Nota Fiscal: ' + lTrim(rTrim(IsNull(@NUMERO_NF_TRANSFERENCIA, ''))) + ' - ' + 
								'Série NF: '    + lTrim(rTrim(IsNull(@SERIE_NF_ENTRADA, ''))) + ' - ' + 
								'Emissão: '     + IsNull(Convert(VarChar(10), @DATA_SAIDA, 103), '          ') + ' - ' + 
								'Valor NF: '    + Right(Replicate(' ', 10) + IsNull(Convert(VarChar, @VALOR_TOTAL), ''), 10) + @LF

		Fetch Next From curNotasFiscais Into @NUMERO_NF_TRANSFERENCIA, @SERIE_NF_ENTRADA, @DATA_SAIDA, @VALOR_TOTAL
	End

	Close curNotasFiscais
	Deallocate curNotasFiscais

	If @Texto_Devolucao = ''
		Select @Texto_Devolucao = NULL
	else
		Select @Texto_Devolucao =  'Notas Fiscais de entrada:' + @LF + @LF + @Texto_Devolucao

	Select @texto = Isnull(@texto,'') + @LF + @LF + Isnull(@Texto_Devolucao,'')				
		
	-- SE @TEXTO FOR EM BRANCO, RETORNA NULL
	IF @TEXTO = ''
		SELECT @TEXTO = NULL

	RETURN LTRIM(RTRIM(@TEXTO))
END 

