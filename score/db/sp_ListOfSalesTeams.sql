USE [SalesCommission]
GO
/****** Object:  StoredProcedure [dbo].[sp_ListOfSalesTeams]    Script Date: 2/6/2023 11:35:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Dave Burroughs
-- Create date: 1/31/2023
-- Description:	list of the sales teams for team scoreboards score.sln
-- =============================================
ALTER PROCEDURE [dbo].[sp_ListOfSalesTeams]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
--get each sales team

SELECT DISTINCT  [dept_code]
      ,[dept_desc]
  FROM [ivory].[dbo].[dept] WHERE dept_desc LIKE '%sales%'
END
