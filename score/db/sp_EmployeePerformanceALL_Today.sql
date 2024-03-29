USE [SalesCommission]
GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeePerformanceALL_Today]    Script Date: 8/10/2023 8:52:37 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		DAVE BURROUGHS
-- Create date: 8/9/23
-- Description:	RESULTS Table for employee scorecard/high scores display TODAY
-- INCLUDING  BPP and Zurich totals
-- =============================================
ALTER PROCEDURE [dbo].[sp_EmployeePerformanceALL_Today]
AS
BEGIN

DECLARE	@return_value int
SELECT [SalesID]
      ,[PersonalTotal]
      ,[SalesRank]
      ,[SalesRank_USED]
      ,[SalesRank_NEW]
      ,[sl_SalesAssociate1]
      ,[VehicleMake]
      ,[FIRSTNAME]
      ,[LASTNAME]
      ,[SalesTeam]
      ,[dept_code]
      ,[MTD]
  FROM [SalesCommission].[dbo].[TodaysTeamScoreboard]

END
