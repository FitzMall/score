/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [SalesID]
      ,[sl_SalesAssociate1]
      ,[VehicleMake]
      ,[MTD]
      ,[FIRSTNAME]
      ,[LASTNAME]
      ,[LOCATION]
      ,[SalesRank]
	  ,SalesTeam
  FROM [SalesCommission].[dbo].[EmployeePerformanceMTD]