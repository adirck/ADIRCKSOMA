function InvoicePDF (strFilial as string, strNF_Numero as string, strSerie_NF as string)
	*!* Configurações de destino
	public ReportExport as custom, xKimp as string, wwLogo as string, strLastPdfError as string, xLenObsFrm as String
	ReportExport = createobject("empty")
	addproperty(ReportExport, "CurrentFileFormat", "PDF")
	addproperty(ReportExport, "FileName", addbs(main.SystemPath) + "UserPrograms\DANFE-" + strNF_Numero + ".pdf")

	strLastPdfError = ""
	xLenObsFrm = "9/133"

	wwLogo = addbs(main.SystemPath) + "Reports\LogoReport.png"
	if !file(wwLogo)
		strLastPdfError = "O arquivo de logo não foi encontrado."
		return .f.
	endif

	if !SQLSelect("SELECT VALOR_ATUAL FROM PARAMETROS WHERE PARAMETRO = 'LOGO_EXCLUSIVO_DANFE'", "curTmp_LogoDanfe")
		return .f.
	endif
	if !empty(alltrim(nvl(curTmp_LogoDanfe.valor_atual, ""))) and file(alltrim(nvl(curTmp_LogoDanfe.valor_atual, "")))
		wwLogo = alltrim(nvl(curTmp_LogoDanfe.valor_atual, ""))
	endif

	local strReport1 as string, strReport2 as string
	strReport1 = addbs(main.SystemPath) + "Reports\L_Danfe1.frx"
	strReport2 = addbs(main.SystemPath) + "Reports\L_Danfe2.frx"

	local strOutput as string, strOutput1 as string, strOutput2 as string, strItensDanfe as string, strItensDanfe1 as integer, strItensDanfe2 as string
	strOutput1 = "object oXFRX nopageeject"
	strOutput2 = "object oXFRX nopageeject noreset"

	if !SQLSelect("SELECT VALOR_ATUAL FROM PARAMETROS WHERE PARAMETRO = 'ITENS_P_FORM_DANFE'", "curTmp_Itens_p_Form")
		return .f.
	endif

	strItensDanfe = nvl(alltrim(curTmp_Itens_p_Form.valor_atual), "")
	if atc("/", strItensDanfe) > 0
		strItensDanfe1 = val(substr(strItensDanfe, 1, atc("/", strItensDanfe) - 1))
		strItensDanfe2 = val(substr(strItensDanfe, atc("/", strItensDanfe) + 1, len(strItensDanfe)))
	else
		strItensDanfe1 = 16
		strItensDanfe2 = 46
	endif

	*!* Arquivo de funções de NFe
	local strProcSource as string, strProcCompiled as string, strProcedure as string, intReportBehavior as integer, objPrinterError as exception, bPrintError as Boolean
	strProcSource = addbs(main.SystemPath) + "Reports\NFe_Functions.prg"
	strProcCompiled = addbs(main.SystemPath) + "Reports\NFe_Functions.fxp"
	if !file(strProcSource)
		if !file(strProcCompiled)
			strLastPdfError = "O arquivo de programa necessário para a impressão da NFe não foi encontrado."
			return .f.
		endif
	else
		if !file(strProcCompiled)
			strtofile("", strProcCompiled)
			compile "&strProcSource"
			if !file(strProcCompiled)
				strLastPdfError = "O arquivo de programa necessário para a impressão da NFe não foi encontrado."
				return .f.
			endif
		endif
	endif

	strProcedure = set("procedure")
	strProcSource = iif(file(strProcSource), strProcSource, strProcCompiled)
	intReportBehavior = set("reportbehavior")
	set reportbehavior 80
	set procedure to "&strProcSource" additive

	*!* Geração da DANFE em PDF
	if !fx_control_obj_export(.t.)
		return .f.
	endif

	if !fx_danfe_init(strItensDanfe1, strItensDanfe2, "9/133", strFilial, strNF_Numero, strSerie_NF, 1, main)
		return .f.
	endif

	select distinct nf, serie_nf, filial, n_form, t_form, .f. as is_ultimo from vtmp_impressao_nf_00_itens into cursor cur_Lst_DANFE_Emitir readwrite
	select cur_Lst_DANFE_Emitir
	go bottom
	replace is_ultimo with .t.

	select max(t_form) as t_form from cur_Lst_DANFE_Emitir into cursor curChk_t_Form

	if curChk_t_Form.t_form == 1
		select vtmp_impressao_nf_00_itens
		go top

		strOutput = strtran(strtran(strOutput1, "nopageeject", ""), "noreset", "")

		try
			report form (strReport1) &strOutput
		catch to objPrinterError
			strLastPdfError = transform(objPrinterError.errorno) + " - " + alltrim(objPrinterError.message)
			bPrintError = .t.
		endtry
	else
		strOutput = strOutput1

		select cur_Lst_DANFE_Emitir
		scan
			xKimp = alltrim(filial) + alltrim(nf) + alltrim(serie_nf) + str(n_form)

			select vtmp_impressao_nf_00_itens
			set filter to alltrim(filial) + alltrim(nf) + alltrim(serie_nf) + str(n_form) == xKimp
			go top

			if cur_Lst_DANFE_Emitir.is_ultimo
				strOutput = strtran(strtran(strOutput, "nopageeject", ""), "noreset", "")
			endif

			if n_form = 1
				try
					report form (strReport1) &strOutput
				catch to objPrinterError
					strLastPdfError = transform(objPrinterError.errorno) + " - " + alltrim(objPrinterError.message)
					bPrintError = .t.
				endtry
			else
				try
					report form (strReport2) &strOutput
				catch to objPrinterError
					strLastPdfError = transform(objPrinterError.errorno) + " - " + alltrim(objPrinterError.message)
					bPrintError = .t.
				endtry
			endif
			if bPrintError
				return .f.
			endif

			strOutput = strOutput2
		endscan
	endif

	if bPrintError
		return .f.
	endif

	fx_control_obj_export(.f.)

	fx_danfe_destroy(.f.)

	set procedure to &strProcedure
	set reportbehavior &intReportBehavior

	ShowProgress()

	return .t.
endfunc
