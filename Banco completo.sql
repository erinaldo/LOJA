USE [Loja]
GO
/****** Object:  StoredProcedure [dbo].[spc_AdicionarEntrada]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_AdicionarEntrada]
(
	@DocEntrada		varchar(15),
	@DatEntrada		smalldatetime,
	@CodProduto		int,
	@QtdProduto		float,
	@VlrUnitario	money,
	@CodTipoEntrada	int,
	@Percentual		float,
	@DesFornecedor  varchar(20)
)
AS
	SET NOCOUNT ON
	
	INSERT INTO tbl_Entrada(DocEntrada, DatEntrada, QtdProduto, VlrUnitario, CodTipoEntrada, codigounico, Percentual,DesFornecedor)
	VALUES (@DocEntrada, @DatEntrada, @QtdProduto, @VlrUnitario, @CodTipoEntrada, @CodProduto, @Percentual,@DesFornecedor)

	IF Exists (SELECT * FROM tbl_Produtos WHERE codigounico = @CodProduto AND DesFornecedor = @DesFornecedor)
	
		UPDATE tbl_Produtos
		SET	VlrUltPreco = VlrUnitario,
			QtdProduto = IsNull(QtdProduto, 0) + @QtdProduto, 
			VlrCusto = @VlrUnitario, 
			VlrPercent = @Percentual,
			VlrUnitario = @VlrUnitario * ((@Percentual / 100) + 1)
		WHERE codigounico = @CodProduto
	ELSE 
		INSERT INTO tbl_Produtos(CodProduto, DesProduto, DesLocal,VlrUnitario,QtdProduto,VlrCusto,VlrPercent,EstMinimo,
		DatCadastro, DesFornecedor, CodRefAntiga, DesFaz,VlrUltPreco,Imagem,codigounico)
		SELECT CodProduto, DesProduto, DesLocal,@VlrUnitario * (1+(@Percentual / 100)),@QtdProduto,@VlrUnitario,@Percentual,EstMinimo,
		DatCadastro, @DesFornecedor, CodRefAntiga, DesFaz,VlrUltPreco,Imagem,codigounico 
		FROM tbl_Produtos 
		WHERE codigounico = @CodProduto
						  	
	
	SELECT Registros = @@RowCount
	RETURN

GO
/****** Object:  StoredProcedure [dbo].[spc_AdicionarOrcamento]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_AdicionarOrcamento]
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

GO
/****** Object:  StoredProcedure [dbo].[spc_AlterarEntrada]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_AlterarEntrada]
	@DocEntrada		VARCHAR(15),
	@DatEntrada		SMALLDATETIME,
	@codigounico	INT,
	@Quantidade		FLOAT,
	@VlrUnitario	FLOAT

AS

	IF ISNULL(@Quantidade, 0) = 0 BEGIN
		DECLARE @QtdEntrada FLOAT
		
		SELECT @QtdEntrada = QtdProduto
		FROM tbl_Entrada
		WHERE DocEntrada = @DocEntrada AND DatEntrada = @DatEntrada AND codigounico = @codigounico
	
		UPDATE tbl_Produtos
		SET	QtdProduto = IsNull(QtdProduto, 0) - @QtdEntrada
		WHERE codigounico = @codigounico
	
		DELETE FROM tbl_Entrada WHERE DocEntrada = @DocEntrada AND DatEntrada = @DatEntrada AND codigounico = @codigounico
	END
GO
/****** Object:  StoredProcedure [dbo].[spc_AlterarOrcamento]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_AlterarOrcamento]
	@CodOrca		VARCHAR(5),
	@CodProduto		int,
	@Quantidade		FLOAT = -1,
	@VlrUnitario	FLOAT = -1

AS

SET NOCOUNT ON

DECLARE @QtdEstoque FLOAT

SELECT @QtdEstoque = QtdProduto FROM tbl_Produtos WHERE codigounico = @CodProduto

IF @QtdEstoque < @Quantidade BEGIN
	RAISERROR('QUANTIDADE MAIOR QUE O DISPONÍVEL EM ESTOQUE', 16, 1)
	RETURN
END


IF ISNULL(@Quantidade, -1) > -1
	IF @Quantidade > 0
		UPDATE tbl_Orcamento 
		SET Quantidade = @Quantidade
		WHERE CodOrca = @CodOrca AND 
				codigounico = @CodProduto
	ELSE
		DELETE FROM tbl_Orcamento
		WHERE CodOrca = @CodOrca AND 
				codigounico = @CodProduto

IF ISNULL(@VlrUnitario, -1) > -1
	
	UPDATE tbl_Orcamento 
	SET VlrUnitario = @VlrUnitario
	WHERE CodOrca = @CodOrca AND
			codigounico = @CodProduto

GO
/****** Object:  StoredProcedure [dbo].[spc_ApagarOrcamento]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_ApagarOrcamento]
(
	@Original_CodOrca varchar(5)
)
AS
	SET NOCOUNT OFF;
DELETE FROM tbl_Orcamento
WHERE        (CodOrca = @Original_CodOrca)

GO
/****** Object:  StoredProcedure [dbo].[spc_DescontoVenda]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_DescontoVenda]
(
	@CodOrca varchar(5),
	@Desconto numeric(10,4)
)
AS
	SET NOCOUNT ON;


	UPDATE tbl_Orcamento
	SET VlrUnitario = ROUND(VlrCusto * (@Desconto/100), 2)
	WHERE (CodOrca = @CodOrca);
GO
/****** Object:  StoredProcedure [dbo].[spc_EstornaVenda]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_EstornaVenda]
	(
	@CodVenda int,
	@CodProduto int,
	@DesMotivo varchar(100)
	)
AS
	SET NOCOUNT ON
	
	IF @CodProduto = '' SET @CodProduto = NULL
	
	UPDATE tbl_Produtos
	SET QtdProduto = QtdProduto + Quantidade
	FROM tbl_Produtos
	INNER JOIN tbl_Saidas ON
		tbl_Saidas.codigounico = tbl_Produtos.codigounico
	WHERE CodVenda = @CodVenda
	
	INSERT INTO tbl_SaidasEstorno (CodVenda, DatSaida, CodOrcamento, CodProduto, DesProduto,
									VlrUnitario, Quantidade, VlrCusto, CodTipoVenda,
									DatEstorno, MotivoEstorno, codigounico)
	SELECT CodVenda, DatSaida, CodOrcamento, CodProduto, DesProduto, VlrUnitario, 
			Quantidade, VlrCusto, CodTipoVenda, GetDate(), @DesMotivo, codigounico
	FROM tbl_Saidas
	WHERE CodVenda = @CodVenda AND
			codigounico = IsNull(@CodProduto, codigounico)
	
	DELETE FROM tbl_Saidas
	WHERE CodVenda = @CodVenda AND
			codigounico = IsNull(@CodProduto, codigounico)
	
	
	RETURN

GO
/****** Object:  StoredProcedure [dbo].[spc_FinalizaVenda]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_FinalizaVenda]
	(
	@CodOrca		VARCHAR(5),
	@CodTipoVenda	INT,
	@flgApagarOrca	CHAR(1) = 'S'
	)
AS
	SET NOCOUNT ON
	
	BEGIN TRANSACTION

	BEGIN TRY 
	
		INSERT INTO tbl_Saidas (CodOrcamento, CodProduto, DesProduto, VlrUnitario,
								Quantidade, VlrCusto, DatSaida, CodTipoVenda, codigounico)
		SELECT CodOrca, CodProduto, DescProduto, VlrUnitario, Quantidade, VlrCusto, GetDate(), @CodTipoVenda, codigounico
		FROM tbl_Orcamento
		WHERE CodOrca = @CodOrca

		UPDATE tbl_Produtos
		SET QtdProduto = QtdProduto - Quantidade
		FROM tbl_Produtos
		INNER JOIN tbl_Orcamento ON
			tbl_Orcamento.codigounico = tbl_Produtos.codigounico
		WHERE CodOrca = @CodOrca

		IF @flgApagarOrca = 'N'
			UPDATE tbl_Orcamento
			SET flgStatus = 'V'
			WHERE CodOrca = @CodOrca
		ELSE
			DELETE FROM tbl_Orcamento 
			WHERE CodOrca = @CodOrca
		
		COMMIT
	END TRY
	BEGIN CATCH
		DECLARE @Mensagem VARCHAR(1000)
		SET @Mensagem = ERROR_MESSAGE()
		RAISERROR (@Mensagem, 16, 0)
		ROLLBACK
	END CATCH
	
	SELECT Resultado = @@RowCount

GO
/****** Object:  StoredProcedure [dbo].[spc_ManutProduto]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_ManutProduto]
	@codigounico	INT,
	@CodProduto		VARCHAR(20),
	@DesProduto		VARCHAR(30),
	@DesLocal		VARCHAR(4),
	@VlrUnitario	FLOAT,
	@QtdProduto		FLOAT,
	@VlrCusto		FLOAT,
	@VlrPercent		FLOAT,
	@EstMinimo		FLOAT,
	@DesFornecedor	VARCHAR(10),
	@CodRefAntiga	VARCHAR(10),
	@VlrUltPreco	FLOAT,
	@Imagem			IMAGE
AS
BEGIN
	SET NOCOUNT ON;

	IF NOT EXISTS (SELECT CodProduto FROM tbl_Produtos WHERE codigounico = @codigounico) BEGIN
		INSERT INTO tbl_Produtos (CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, 
									VlrPercent, EstMinimo, DatCadastro, DesFornecedor,CodRefAntiga,
									VlrUltPreco, Imagem)
		VALUES(@CodProduto, @DesProduto, @DesLocal, @VlrUnitario, @QtdProduto, @VlrCusto, @VlrPercent, @EstMinimo,
				CONVERT(VARCHAR(10), GETDATE(), 103), @DesFornecedor, @CodRefAntiga, @VlrUltPreco, @Imagem)
	END
	ELSE BEGIN
		
		UPDATE tbl_Produtos
		SET
			CodProduto = @CodProduto,
			DesProduto = @DesProduto,
			DesLocal = @DesLocal,
			VlrUnitario = @VlrUnitario,
			QtdProduto = @QtdProduto,
			VlrCusto = @VlrCusto,
			VlrPercent = @VlrPercent,
			EstMinimo = @EstMinimo,
			DesFornecedor = @DesFornecedor,
			CodRefAntiga = @CodRefAntiga,
			VlrUltPreco = @VlrUltPreco,
			Imagem = @Imagem
		WHERE codigounico = @codigounico
		
	END
END

GO
/****** Object:  StoredProcedure [dbo].[spc_PesqProduto]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_PesqProduto]
	(
	@CodProduto varchar(20),
	@DesProduto varchar(50),
	@Local		varchar(4)
	)
AS
	/* SET NOCOUNT ON */ 
	IF IsNull(@CodProduto, '') <> '' AND IsNull(@DesProduto, '') = '' AND IsNull(@Local, '') = '' BEGIN
		SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
				EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
		FROM dbo.tbl_Produtos
		WHERE CodProduto LIKE '%' + @CodProduto + '%'
	END
	ELSE IF IsNull(@CodProduto, '') = '' AND IsNull(@DesProduto, '') <> '' AND IsNull(@Local, '') = '' BEGIN
		SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
				EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
		FROM dbo.tbl_Produtos
		WHERE DesProduto LIKE '%' + @DesProduto + '%'
	END 
	ELSE IF IsNull(@CodProduto, '') = '' AND IsNull(@DesProduto, '') = '' AND IsNull(@Local, '') <> '' BEGIN
		SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
				EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
		FROM dbo.tbl_Produtos
		WHERE DesLocal = @Local
	END
	ELSE BEGIN
	SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
			EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
	FROM dbo.tbl_Produtos
	WHERE DesProduto LIKE '%' + IsNull(@DesProduto, '') + '%' AND 
			CodProduto LIKE '+' + IsNull(@CodProduto, '') + '+' AND 
			DesLocal = IsNull(@Local, DesLocal)
	END

	RETURN

GO
/****** Object:  StoredProcedure [dbo].[spc_PesqProduto2]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_PesqProduto2]
	(
	@CodProduto varchar(20),
	@DesProduto varchar(50),
	@Local		varchar(4),
	@flgSaldo	char(1)
	)
AS
	/* SET NOCOUNT ON */ 
	-- Trabalha as variáveis
	IF @CodProduto = '' SET @CodProduto = NULL
	IF @DesProduto = '' SET @DesProduto = NULL
	IF @Local = '' SET @Local = NULL
	
	CREATE TABLE #tmpProdutos(
		[CodProduto] [varchar](20) NOT NULL,
		[DesProduto] [varchar](30) NOT NULL,
		[DesLocal] [varchar](4) NOT NULL,
		[VlrUnitario] [float] NULL,
		[QtdProduto] [float] NULL,
		[VlrCusto] [float] NULL,
		[VlrPercent] [float] NULL,
		[EstMinimo] [float] NULL,
		[DatCadastro] [varchar](10) NULL,
		[DesFornecedor] [varchar](10) NULL,
		[CodRefAntiga] [varchar](10) NULL,
		[DesFaz] [float] NULL,
		[VlrUltPreco] [float] NULL,
		[Imagem] [image] NULL,
	)

	INSERT INTO #tmpProdutos
	SELECT *
	FROM tbl_Produtos
	
	-- @flgSaldo = "S" apaga todos os produtos com quantidade igual ou menor que zero
	-- @flgSaldo = "N" apaga todos os produtos com quantidade igual ou maior que zero
	-- @flgSaldo = "T" mostra tudo
	IF @flgSaldo <> '' AND @flgSaldo = 'S' BEGIN
		DELETE FROM #tmpProdutos WHERE QtdProduto <= 0
	END
	ELSE IF @flgSaldo <> '' AND @flgSaldo = 'N' BEGIN
		DELETE FROM #tmpProdutos WHERE QtdProduto > 0
	END
	
	SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
			EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
	FROM #tmpProdutos
	WHERE DesProduto LIKE '%' + IsNull(@DesProduto,	DesProduto) + '%' AND 
			CodProduto LIKE '%' + IsNull(@CodProduto, CodProduto) + '%' AND 
			DesLocal LIKE '%' + IsNull(@Local, DesLocal) + '%'
	
	/*
	IF IsNull(@CodProduto, '') <> '' AND IsNull(@DesProduto, '') = '' AND IsNull(@Local, '') = '' BEGIN
		SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
				EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
		FROM dbo.tbl_Produtos
		WHERE CodProduto LIKE '%' + @CodProduto + '%'
	END
	ELSE IF IsNull(@CodProduto, '') = '' AND IsNull(@DesProduto, '') <> '' AND IsNull(@Local, '') = '' BEGIN
		SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
				EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
		FROM dbo.tbl_Produtos
		WHERE DesProduto LIKE '%' + @DesProduto + '%'
	END 
	ELSE IF IsNull(@CodProduto, '') = '' AND IsNull(@DesProduto, '') = '' AND IsNull(@Local, '') <> '' BEGIN
		SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
				EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
		FROM dbo.tbl_Produtos
		WHERE DesLocal = @Local
	END
	ELSE IF IsNull(@CodProduto, '') = '' AND IsNull(@DesProduto, '') = '' AND IsNull(@Local, '') = '' BEGIN
		SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
				EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
		FROM dbo.tbl_Produtos
	END
	ELSE BEGIN
	SELECT CodProduto, DesProduto, DesLocal, VlrUnitario, QtdProduto, VlrCusto, VlrPercent, 
			EstMinimo, DatCadastro, DesFornecedor, CodRefAntiga, DesFaz, VlrUltPreco, Imagem
	FROM dbo.tbl_Produtos
	WHERE DesProduto LIKE '%' + IsNull(@DesProduto, '') + '%' AND 
			CodProduto LIKE '%' + IsNull(@CodProduto, '') + '%' AND 
			DesLocal LIKE '%' + IsNull(@Local, DesLocal) + '%'
	END
	*/
	RETURN

GO
/****** Object:  StoredProcedure [dbo].[spc_PesqSaida]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_PesqSaida]
(
	@DatInicial smalldatetime,
	@DatFinal smalldatetime,
	@CodProduto varchar(20)
)
AS
SET NOCOUNT ON;

If @CodProduto = '' SET @CodProduto = NULL

SELECT CodVenda, CodOrcamento, CodProduto, DesProduto, VlrUnitario, Quantidade, VlrCusto, VlrFinal, DatSaida,
A.CodTipoVenda, DesTipoVenda
FROM tbl_Saidas A
INNER JOIN tbl_TipoVenda B ON B.CodTipoVenda = A.CodTipoVenda
WHERE (DatSaida >= @DatInicial AND
		DatSaida <= @DatFinal+1) AND
		CodProduto = IsNull(@CodProduto, CodProduto)

GO
/****** Object:  StoredProcedure [dbo].[spc_PesqVendas]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_PesqVendas]
	@DatIni		smalldatetime,
	@DatFim		smalldatetime,
	@CodVenda	int,
	@CodProduto varchar(20)
AS
	SET NOCOUNT ON
	
	SELECT *
	FROM tbl_Saidas
	WHERE DatSaida >= @DatIni AND
			DatSaida <= @DatFim AND
			CodVenda = IsNull(@CodVenda, CodVenda) AND
			CodProduto = IsNull(@CodProduto, COdProduto)
	
	
	RETURN

GO
/****** Object:  StoredProcedure [dbo].[spc_Reajuste]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spc_Reajuste]
	(
		@Porcentagem numeric(8,2),
		@DesFornecedor varchar(10) = NULL
	)

AS
	SET NOCOUNT ON
	
	IF @DesFornecedor = '' SET @DesFornecedor = NULL
	
	UPDATE tbl_Produtos
	SET Desfaz = VlrPercent,
		VlrUltPreco = VlrUnitario,
		VlrUnitario = VlrUnitario + ((@Porcentagem * VlrUnitario) / 100)
	WHERE IsNull(DesFornecedor, '') = IsNull(@DesFornecedor, IsNull(DesFornecedor, ''))
			AND VlrUnitario > 0
	
	UPDATE tbl_Produtos
	SET VlrPercent = CAST(((VlrUnitario / VlrCusto) * 100) - 100 AS Numeric(8,2))
	WHERE VlrCusto > 0 AND VlrUnitario > 0
	
	SELECT Registros = @@RowCount

GO
/****** Object:  Table [dbo].[tbl_Entrada]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Entrada](
	[DocEntrada] [varchar](15) NOT NULL,
	[DatEntrada] [smalldatetime] NOT NULL,
	[QtdProduto] [numeric](18, 0) NOT NULL,
	[VlrUnitario] [numeric](18, 2) NOT NULL,
	[VlrTotal]  AS ([QtdProduto]*[VlrUnitario]),
	[CodTipoEntrada] [int] NOT NULL,
	[codigounico] [int] NOT NULL,
	[Percentual] [float] NULL,
	[DesFornecedor] [varchar](10) NULL,
 CONSTRAINT [PK_tbl_Entrada_1] PRIMARY KEY CLUSTERED 
(
	[DocEntrada] ASC,
	[DatEntrada] ASC,
	[codigounico] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_Orcamento]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Orcamento](
	[CodOrca] [varchar](5) NOT NULL,
	[CodProduto] [varchar](20) NOT NULL,
	[DescProduto] [varchar](30) NULL,
	[Quantidade] [float] NULL,
	[VlrUnitario] [float] NULL,
	[VlrCusto] [float] NULL,
	[DesLocal] [varchar](4) NULL,
	[PF]  AS ([VlrUnitario]*[Quantidade]),
	[FlgStatus] [char](1) NULL,
	[DatOrca] [smalldatetime] NULL,
	[codigounico] [int] NOT NULL,
 CONSTRAINT [PK_tbl_Orcamento_1] PRIMARY KEY CLUSTERED 
(
	[CodOrca] ASC,
	[codigounico] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_Parametros]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Parametros](
	[EmpresaNome] [varchar](50) NOT NULL,
	[EmpresaEndereco] [varchar](50) NULL,
	[EmpresaTelefone] [varchar](15) NULL,
	[EmpresaEmail] [varchar](25) NULL,
	[EmpresaWebSite] [varchar](30) NULL,
	[EmpresaSlogan] [varchar](50) NULL,
	[EmpresaLogotipo] [image] NULL,
	[EmpresaCNPJ] [char](18) NULL,
	[EmpresaInscEstadual] [varchar](15) NULL,
	[SisCodVenda] [int] NULL,
 CONSTRAINT [PK_tbl_Parametros] PRIMARY KEY CLUSTERED 
(
	[EmpresaNome] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_Preco]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Preco](
	[CodProduto] [varchar](20) NOT NULL,
	[VlrProduto] [float] NULL,
 CONSTRAINT [PK_tbl_Preco] PRIMARY KEY CLUSTERED 
(
	[CodProduto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_Produtos]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Produtos](
	[CodProduto] [varchar](20) NOT NULL,
	[DesProduto] [varchar](30) NOT NULL,
	[DesLocal] [varchar](4) NOT NULL,
	[VlrUnitario] [float] NULL,
	[QtdProduto] [float] NULL,
	[VlrCusto] [float] NULL,
	[VlrPercent] [float] NULL,
	[EstMinimo] [float] NULL,
	[DatCadastro] [varchar](10) NULL,
	[DesFornecedor] [varchar](10) NULL,
	[CodRefAntiga] [varchar](10) NULL,
	[DesFaz] [float] NULL,
	[VlrUltPreco] [float] NULL,
	[Imagem] [image] NULL,
	[codigounico] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_tbl_Produtos] PRIMARY KEY NONCLUSTERED 
(
	[CodProduto] ASC,
	[DesProduto] ASC,
	[DesLocal] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_Saidas]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Saidas](
	[CodVenda] [int] IDENTITY(1,1) NOT NULL,
	[DatSaida] [smalldatetime] NOT NULL,
	[CodOrcamento] [varchar](5) NOT NULL,
	[CodProduto] [varchar](20) NOT NULL,
	[DesProduto] [varchar](30) NOT NULL,
	[VlrUnitario] [money] NOT NULL,
	[Quantidade] [int] NOT NULL,
	[VlrCusto] [money] NOT NULL,
	[VlrFinal]  AS ([Quantidade]*[VlrUnitario]),
	[CodTipoVenda] [int] NOT NULL,
	[codigounico] [int] NOT NULL,
 CONSTRAINT [PK_tbl_Saidas] PRIMARY KEY CLUSTERED 
(
	[CodVenda] ASC,
	[DatSaida] ASC,
	[codigounico] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_SaidasEstorno]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_SaidasEstorno](
	[CodVenda] [int] NOT NULL,
	[DatSaida] [smalldatetime] NOT NULL,
	[CodOrcamento] [varchar](5) NOT NULL,
	[CodProduto] [varchar](20) NOT NULL,
	[DesProduto] [varchar](30) NOT NULL,
	[VlrUnitario] [money] NOT NULL,
	[Quantidade] [int] NOT NULL,
	[VlrCusto] [money] NOT NULL,
	[VlrFinal]  AS ([Quantidade]*[VlrUnitario]),
	[CodTipoVenda] [int] NOT NULL,
	[DatEstorno] [smalldatetime] NOT NULL,
	[MotivoEstorno] [varchar](50) NOT NULL,
	[codigounico] [int] NOT NULL,
 CONSTRAINT [PK_tbl_SaidasEstorno] PRIMARY KEY CLUSTERED 
(
	[CodVenda] ASC,
	[DatSaida] ASC,
	[codigounico] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_TipoEntrada]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_TipoEntrada](
	[CodTipoEntrada] [int] IDENTITY(1,1) NOT NULL,
	[DesTipoEntrada] [varchar](50) NOT NULL,
	[flgMovimentaEstoque] [bit] NOT NULL,
 CONSTRAINT [PK_tbl_TipoEntrada] PRIMARY KEY CLUSTERED 
(
	[CodTipoEntrada] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_TipoVenda]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_TipoVenda](
	[CodTipoVenda] [int] IDENTITY(1,1) NOT NULL,
	[DesTipoVenda] [varchar](50) NULL,
	[flgAtivo] [bit] NULL,
	[flgAVista] [bit] NULL,
	[QtdDias] [numeric](10, 0) NULL,
 CONSTRAINT [PK_tbl_TipoVenda] PRIMARY KEY CLUSTERED 
(
	[CodTipoVenda] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_Usuario]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Usuario](
	[CODIGO] [varchar](3) NOT NULL,
	[NOME] [varchar](10) NULL,
	[TSENHA] [varchar](6) NULL,
	[STATUS] [varchar](10) NULL,
	[NIVEL] [varchar](1) NULL,
 CONSTRAINT [PK_tbl_Usuario] PRIMARY KEY CLUSTERED 
(
	[CODIGO] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[viw_Orcamento]    Script Date: 04/09/2015 19:40:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[viw_Orcamento]
AS
SELECT        CodOrca, COUNT(Quantidade) AS Itens, SUM(VlrUnitario * Quantidade) AS VlrTotal, FlgStatus
FROM            dbo.tbl_Orcamento
GROUP BY CodOrca, FlgStatus

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [idxCodProduto]    Script Date: 04/09/2015 19:40:15 ******/
CREATE CLUSTERED INDEX [idxCodProduto] ON [dbo].[tbl_Produtos]
(
	[CodProduto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [idxCodigoUnico]    Script Date: 04/09/2015 19:40:15 ******/
CREATE UNIQUE NONCLUSTERED INDEX [idxCodigoUnico] ON [dbo].[tbl_Produtos]
(
	[codigounico] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [idxDescricao]    Script Date: 04/09/2015 19:40:15 ******/
CREATE NONCLUSTERED INDEX [idxDescricao] ON [dbo].[tbl_Produtos]
(
	[DesProduto] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tbl_Orcamento] ADD  CONSTRAINT [DF_tbl_Orcamento_FlgStatus]  DEFAULT ('O') FOR [FlgStatus]
GO
ALTER TABLE [dbo].[tbl_TipoVenda] ADD  CONSTRAINT [DF_tbl_TipoVenda_flgAtivo]  DEFAULT ('S') FOR [flgAtivo]
GO
ALTER TABLE [dbo].[tbl_TipoVenda] ADD  CONSTRAINT [DF_tbl_TipoVenda_flgGeraAPagar]  DEFAULT ('N') FOR [flgAVista]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[24] 2[8] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "tbl_Orcamento"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 290
               Right = 235
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1470
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'viw_Orcamento'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'viw_Orcamento'
GO
