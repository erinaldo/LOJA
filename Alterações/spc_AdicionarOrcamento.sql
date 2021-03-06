USE [Loja]
GO
/****** Object:  StoredProcedure [dbo].[spc_AdicionarOrcamento]    Script Date: 05/11/2013 13:52:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[spc_AdicionarOrcamento]
(
	@CodOrca varchar(5),
	@CodProduto int
)
AS
	SET NOCOUNT ON
	
	DECLARE @Orcamento varchar(5)
	
	IF IsNull(@CodOrca, '') <> '' BEGIN
		SET @Orcamento = @CodOrca
	END
	ELSE BEGIN
		SELECT @Orcamento = MAX(CodOrca) FROM tbl_Orcamento
		IF IsNull(@Orcamento, '') = '' SET @Orcamento = '00000'
		SET @Orcamento = Right('00000' + Cast((@Orcamento + 1) as varchar), 5)
	END
	
	IF NOT EXISTS (SELECT CodOrca FROM tbl_Orcamento WHERE CodOrca = @Orcamento AND codigounico = @CodProduto) BEGIN
		INSERT INTO tbl_Orcamento (CodOrca, CodProduto, DescProduto, Quantidade, VlrUnitario, VlrCusto, DesLocal, FlgStatus, DatOrca, codigounico)
		SELECT @Orcamento, CodProduto, DesProduto, 1, VlrUnitario, VlrUnitario, DesLocal, 'O', GETDATE(), codigounico
		FROM tbl_Produtos
		WHERE codigounico = @CodProduto
	END
	ELSE
	BEGIN
		UPDATE tbl_Orcamento
		SET Quantidade = Quantidade + 1
		WHERE CodOrca = @Orcamento AND
				codigounico = @CodProduto
	END
	
	SELECT CodOrca = @Orcamento
	
	RETURN
