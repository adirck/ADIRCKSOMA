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
			 @CODIGO_FILIAL = (SELECT DISTINCT CODIGO_FILIAL FROM LOJA_VENDA where data_venda>getdate()-5)
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
						WHERE (IP_LOJA <> @IP_LOJA
						OR NOME_BANCO <> @NOME_BANCO
						OR CODIGO_FILIAL <> @CODIGO_FILIAL
						OR NOME_SERVIDOR <> @NOME_SERVIDOR) )
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
				 @CODIGO_FILIAL_LOJA = (SELECT DISTINCT CODIGO_FILIAL FROM LOJA_VENDA)
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
							WHERE (IP_LOJA <> @IP_LOCAL_LOJA
							OR NOME_BANCO <> @NOME_BANCO_LOJA
							OR CODIGO_FILIAL <> @CODIGO_FILIAL_LOJA
							OR NOME_SERVIDOR <> @NOME_SERVIDOR_LOJA) )
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