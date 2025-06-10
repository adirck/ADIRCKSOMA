*/ Events
#define _EVENT_MSG_BOX 1
#define _EVENT_FLOATING_MSG 2
#define _EVENT_SQL_ERROR 3
#define _EVENT_FOX_ERROR 4
#define _EVENT_CONFIG_CHANGED 5
#define _EVENT_EXCEPTION 6
#define _EVENT_TEF 7
#define _EVENT_UPGRADE 8
#define _EVENT_TRANSACTION 9

*/ Messages
#define _IDOK 1
#define _IDCANCEL 2
#define _IDABORT 3
#define _IDRETRY 4
#define _IDIGNORE 5
#define _IDYES 6
#define _IDNO 7

function ExecuteForm (cFormName as string, eParam1, eParam2, eParam3, eParam4, eParam5, eParam6, eParam7, eParam8, eParam9, eParam10, eParam11, eParam12, eParam13, eParam14, eParam15) as Boolean
	local strScript as string, intParameter as integer
	
	*!* if type("main.name") == "C" and !pemstatus(main, "OmniClusterMonitor", 5)
	*!* 	main.newobject("OmniClusterMonitor", "COmniClusterMonitor", "UserPrograms\Classes\UnicoLoyalty.vcx")
	*!* endif

	DefineNewErrorHandler()
	VerifyAndCopy(cFormName)

	strScript = "InternalExecuteForm(cFormName, .f."
	for intParameter = 1 to pcount() - 1
		strScript = strScript + ", eParam" + transform(intParameter)
	endfor
	strScript = strScript + ")"

	return &strScript
endfunc

function ExecuteFormModal (cFormName as string, eParam1, eParam2, eParam3, eParam4, eParam5, eParam6, eParam7, eParam8, eParam9, eParam10, eParam11, eParam12, eParam13, eParam14, eParam15) as Variant
	local strScript as string, intParameter as integer
	
	local objException as Exception
	
	*!* if type("main.name") == "C" and !pemstatus(main, "OmniClusterMonitor", 5)
	*!* 	try
	*!* 		main.newobject("OmniClusterMonitor", "COmniClusterMonitor", "UserPrograms\Classes\UnicoLoyalty.vcx")
	*!* 	catch to objException
	*!* 		messagebox("Não foi possível ativar o monitor Omni." + chr(13) + chr(13) + objException.Message, 64, "Atenção")
	*!* 	endtry
	*!* endif

	DefineNewErrorHandler()
	VerifyAndCopy(cFormName)

	strScript = "InternalExecuteForm(cFormName, .t."
	for intParameter = 1 to pcount() - 1
		strScript = strScript + ", eParam" + transform(intParameter)
	endfor
	strScript = strScript + ")"

	return &strScript
endfunc

function VerifyAndCopy (strFormName as string)
	local strFolder as string, strSourceFile as string, strDestinationFile as string

	if lower(alltrim(strFormName)) != "main"
		return .t.
	endif

	try
		strFolder = strTempDir + strProductName + "UserPrograms"
		mkdir "&strFolder"
		strFolder = strFolder + "\*.*"
		delete file "&strFolder"
	catch
	endtry

	try
		strFolder = strTempDir + strProductName + "UserPrograms\Forms"
		mkdir "&strFolder"
		strFolder = strFolder + "\*.*"
		delete file "&strFolder"
	catch
	endtry

	try
		strFolder = strTempDir + strProductName + "UserPrograms\Forms\Touch"
		mkdir "&strFolder"
		strFolder = strFolder + "\*.*"
		delete file "&strFolder"
	catch
	endtry

	try
		strFolder = strTempDir + strProductName + "UserPrograms\Classes"
		mkdir "&strFolder"
		strFolder = strFolder + "\*.*"
		delete file "&strFolder"
	catch
	endtry

	try
		strFolder = strTempDir + strProductName + "UserPrograms\Classes\Touch"
		mkdir "&strFolder"
		strFolder = strFolder + "\*.*"
		delete file "&strFolder"
	catch
	endtry

	try
		strSourceFile = strTempDir + strProductName + "\UserPrograms\*.*"
		strDestinationFile = strTempDir + strProductName + "UserPrograms\*.*"
		copy file "&strSourceFile" to "&strDestinationFile"
	catch
	endtry

	try
		strSourceFile = strTempDir + strProductName + "\UserPrograms\Forms\*.*"
		strDestinationFile = strTempDir + strProductName + "UserPrograms\Forms\*.*"
		copy file "&strSourceFile" to "&strDestinationFile"
	catch
	endtry

	try
		strSourceFile = strTempDir + strProductName + "\UserPrograms\Forms\Touch\*.*"
		strDestinationFile = strTempDir + strProductName + "UserPrograms\Forms\Touch\*.*"
		copy file "&strSourceFile" to "&strDestinationFile"
	catch
	endtry

	try
		strSourceFile = strTempDir + strProductName + "\UserPrograms\Classes\*.*"
		strDestinationFile = strTempDir + strProductName + "UserPrograms\Classes\*.*"
		copy file "&strSourceFile" to "&strDestinationFile"
	catch
	endtry

	try
		strSourceFile = strTempDir + strProductName + "\UserPrograms\Classes\Touch\*.*"
		strDestinationFile = strTempDir + strProductName + "UserPrograms\Classes\Touch\*.*"
		copy file "&strSourceFile" to "&strDestinationFile"
	catch
	endtry
endfunc

function DefineNewErrorHandler () as Boolean

	if _vfp.startmode != 0 and val(LoadRegistry("Debug\Enable debug mode")) == 0
		on error NewHandleProgramError(program(), iif(lineno(1) == 0, lineno(), lineno(1)))
	endif

	return .t.
endfunc

function NewHandleProgramError (strProgram as string, intErrorLine as integer) as Boolean
	local strMessageText as string
	local array arParameters[4]
	
	if error() == 2012
		return .t.
	endif

	if error() == 1581 && Field "name" does not accept null values.
		strMessageText = "Violação de regra no aplicativo.\n\n" + ;
			"Informações adicionais: \n%v - %v"

		arParameters[1] = error()
		arParameters[2] = message()

		MsgBox(strMessageText, 48, "Atenção", @arParameters, _EVENT_FOX_ERROR)

		return .t.
	endif

	strMessageText = "O aplicativo executou uma operação ilegal.\n" + ;
		"Informações adicionais: \n\n%v (%v)\n%v - %v"

	arParameters[1] = lower(alltrim(strProgram))
	arParameters[2] = evl(intErrorLine, lineno(1))
	arParameters[3] = error()
	arParameters[4] = message()

	if MsgBox(strMessageText, 16 + 5, "Atenção", @arParameters, _EVENT_FOX_ERROR) == _IDRETRY
		retry
	else
		if type("Main.Name") == "C"
			for each oForm in main.forms
				if type("oForm.Name") == "C"
					oForm.release()
				endif
			endfor
			main.ExitCommand()
		endif
		cancel
	endif

	return .t.
endfunc