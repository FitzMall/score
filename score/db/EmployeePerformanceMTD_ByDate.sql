/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [ID]
      ,[dept_code]
      ,[TeamName]
      ,[Make]
      ,[makecode]
      ,[emp_loc]
  FROM [ivory].[dbo].[SalesTeamMakesLocations] where TeamName like '%nissan%' order by TeamName
