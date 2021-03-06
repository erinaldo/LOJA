USE [Loja]
GO
/****** Object:  StoredProcedure [dbo].[spc_FinalizaVenda]    Script Date: 04/11/2015 16:46:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spc_FinalizaVenda]
	(
	@CodOrca		VARCHAR(5),
	@CodTipoVenda	INT,
	@CodCliente		INT = NULL,
	@FlgNFE			INT = 0
	)
AS
	SET NOCOUNT ON
	
	BEGIN TRANSACTION

	BEGIN TRY 
		DECLARE @CodVenda VARCHAR(10)

		IF (@FlgNFE = 1)
			SELECT @CodVenda = SisNumNF + 1
			FROM tbl_Parametros
		ELSE
			SELECT @CodVenda = 'V' + CAST((SisCodVenda + 1) AS VARCHAR)
			FROM tbl_Parametros

		INSERT INTO tbl_Saida(CodVenda, Data, ValorTotal, QtdItens, FlgStatusNFE, ChaveSefaz, FlgStatusNota, CodTipoVenda, CodCliente)
		SELECT @CodVenda, GETDATE(), SUM(PF), SUM(Quantidade), 'E', '', '', @CodTipoVenda, @CodCliente
		FROM tbl_Orcamento
		WHERE CodOrca = @CodOrca

		--SELECT @CodVenda = @@IDENTITY

		INSERT INTO tbl_SaidaItens (CodVenda, CodOrcamento, CodProduto, DesProduto, VlrUnitario,
								Quantidade, VlrCusto, DatSaida, codigounico, VlrDesconto, VlrImposto)
		SELECT @CodVenda, CodOrca, O.CodProduto, DescProduto, O.VlrUnitario, Quantidade, O.VlrCusto, GetDate(), O.codigounico, VlrDesconto,
				P.VlrICMSST
		FROM tbl_Orcamento O
		INNER JOIN tbl_Produtos P ON P.codigounico = O.codigounico
		WHERE CodOrca = @CodOrca

		UPDATE tbl_Produtos
		SET QtdProduto = QtdProduto - Quantidade
		FROM tbl_Produtos
		INNER JOIN tbl_Orcamento ON
			tbl_Orcamento.codigounico = tbl_Produtos.codigounico
		WHERE CodOrca = @CodOrca
		
		IF (@FlgNFE = 1)
			UPDATE tbl_Parametros SET SisNumNF = SisNumNF + 1
		ELSE
			UPDATE tbl_Parametros SET SisCodVenda = SisCodVenda + 1

		COMMIT
	END TRY
	BEGIN CATCH
		DECLARE @Mensagem VARCHAR(1000)
		SET @Mensagem = ERROR_MESSAGE()
		RAISERROR (@Mensagem, 16, 0)
		ROLLBACK
	END CATCH
	
	SELECT Resultado = @CodVenda

