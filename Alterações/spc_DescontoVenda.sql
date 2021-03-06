USE [Loja]
GO
/****** Object:  StoredProcedure [dbo].[spc_DescontoVenda]    Script Date: 28/10/2015 20:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[spc_DescontoVenda]
(
	@CodOrca varchar(5),
	@Desconto numeric(10,4),
	@FlgTipo char(1) = 'R'
)
AS
	SET NOCOUNT ON;

IF ISNULL(@FlgTipo, 'R') = 'P' BEGIN

	UPDATE tbl_Orcamento
	SET VlrUnitario = VlrCusto - ROUND(VlrCusto * (@Desconto/100), 2)
	WHERE (CodOrca = @CodOrca);

END
ELSE
BEGIN
	--select O.DescProduto, O.VlrUnitario, T.ValorTotal, Repres = (VlrUnitario / ValorTotal), 
	--VlrNegativo = (VlrUnitario / ValorTotal) * 24, VlrUnitario - ((VlrUnitario / ValorTotal) * 24)

	UPDATE O
	SET VlrUnitario = VlrUnitario - ((VlrUnitario / ValorTotal) * @Desconto)
	from tbl_Orcamento O
	INNER JOIN (SELECT ValorTotal = SUM(VlrUnitario) FROM tbl_Orcamento WHERE CodOrca = '00001') T ON 1 = 1
	WHERE (CodOrca = @CodOrca);

END