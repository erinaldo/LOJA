USE [Loja]
GO
/****** Object:  Table [dbo].[tbl_Entrada]    Script Date: 04/11/2015 16:16:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_Entrada](
	[CodEntrada] [int] IDENTITY(1,1) NOT NULL,
	[DocEntrada] [varchar](20) NOT NULL,
	[SerieNota] [varchar](5) NULL,
	[DatEmissao] [datetime] NULL,
	[DatEntrada] [smalldatetime] NOT NULL,
	[CodTipoEntrada] [int] NOT NULL,
	[CNPJ] [char](14) NULL,
	[CPF] [char](12) NULL,
	[Nome] [varchar](30) NULL,
 CONSTRAINT [PK_tbl_Entrada] PRIMARY KEY CLUSTERED 
(
	[CodEntrada] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tbl_EntradaItens]    Script Date: 04/11/2015 16:16:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tbl_EntradaItens](
	[CodEntrada] [int] NOT NULL,
	[codigounico] [int] NOT NULL,
	[NumOrdem] [int] NULL,
	[CodProduto] [varchar](20) NULL,
	[DesProduto] [varchar](50) NULL,
	[NCM] [char](8) NULL,
	[Unidade] [varchar](15) NULL,
	[Quantidade] [decimal](18, 4) NULL,
	[VlrUnitario] [decimal](18, 4) NULL,
	[VlrTotal] [decimal](18, 4) NULL,
	[Percentual] [decimal](18, 4) NULL,
	[VlrFinal] [decimal](18, 4) NULL,
	[VlrBaseICMS] [decimal](18, 4) NULL,
	[VlrPercICMS] [decimal](18, 4) NULL,
	[VlrICMS] [decimal](18, 4) NULL,
	[VlrBaseICMSST] [decimal](18, 4) NULL,
	[VlrPercICMSST] [decimal](18, 4) NULL,
	[VlrICMSST] [decimal](18, 4) NULL,
	[VlrBasePIS] [decimal](18, 4) NULL,
	[VlrPercPIS] [decimal](18, 4) NULL,
	[VlrPIS] [decimal](18, 4) NULL,
	[VlrBaseCOFINS] [decimal](18, 4) NULL,
	[VlrPercCOFINS] [decimal](18, 4) NULL,
	[VlrCOFINS] [decimal](18, 4) NULL,
 CONSTRAINT [PK_tbl_EntradaItens] PRIMARY KEY CLUSTERED 
(
	[CodEntrada] ASC,
	[codigounico] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[viw_ResumoDiario]    Script Date: 04/11/2015 16:16:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[viw_ResumoDiario]
AS

SELECT Data = ISNULL(CONVERT(SMALLDATETIME, CONVERT(CHAR(10), Data, 121), 121), ''), ValorTotal = COALESCE( SUM(ValorTotal), 0), Mes = CONVERT(CHAR(7), Data, 121)
FROM tbl_Saida
GROUP BY  ISNULL(CONVERT(SMALLDATETIME, CONVERT(CHAR(10), Data, 121), 121), ''), CONVERT(CHAR(7), Data, 121)





GO
ALTER TABLE [dbo].[tbl_Entrada]  WITH CHECK ADD  CONSTRAINT [FK_tbl_Entrada_tbl_TipoEntrada] FOREIGN KEY([CodTipoEntrada])
REFERENCES [dbo].[tbl_TipoEntrada] ([CodTipoEntrada])
GO
ALTER TABLE [dbo].[tbl_Entrada] CHECK CONSTRAINT [FK_tbl_Entrada_tbl_TipoEntrada]
GO
ALTER TABLE [dbo].[tbl_EntradaItens]  WITH CHECK ADD  CONSTRAINT [FK_tbl_EntradaItens_tbl_Entrada] FOREIGN KEY([CodEntrada])
REFERENCES [dbo].[tbl_Entrada] ([CodEntrada])
GO
ALTER TABLE [dbo].[tbl_EntradaItens] CHECK CONSTRAINT [FK_tbl_EntradaItens_tbl_Entrada]
GO
