USE fitzway

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FMMMazda' AND TABLE_SCHEMA = 'dbo')
DROP TABLE FMMMazda


SELECT 'Vin' AS Vin
      ,'Year' AS Year
      ,'Make' AS Make
      ,'Model' AS Model
      ,'ModelCode' AS ModelCode
      ,'CarTrim' AS CarTrim
      ,'Invoice_Price' AS Invoice_Price
      ,'Sale_Price' AS Sale_Price
      ,'MSRP' AS MSRP    
	  ,'Miles' AS Miles
      ,'Condition' AS Condition
	  into FMMMazda
UNION ALL SELECT [V_Vin] AS Vin
      ,Cast([V_Year] AS varchar(10)) AS Year
      ,[V_MakeName] AS Make
      ,[V_ModelName] AS Model
      ,[V_StyleCode] AS ModelCode
      ,[V_StyleName] AS CarTrim
      ,CAST([V_inv_price] AS varchar(20)) AS Invoice_Price
      ,CAST(V_int_price AS varchar(15)) AS Sale_Price
      ,CAST(V_msrp_price AS varchar(15)) AS MSRP    
	  ,CAST([V_Miles] AS varchar(15)) AS Miles
      ,[V_nu] AS Condition
  FROM [fitzway].[dbo].[AllInventoryFM] 
  WHERE V_loc = 'FMM' OR V_LOC = 'FOC'

  declare @driveOut varchar(200)

set @driveOut  =  'bcp.exe "SELECT * from fitzway.dbo.FMMMazda"  queryout d:\Third_Party\AutoFi\FTP\FMMMazda.csv -T -c -t,'
--PRINT  @driveOut
EXEC master..xp_cmdshell  @driveOut

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FMMMazda' AND TABLE_SCHEMA = 'dbo')
DROP TABLE FMMMazda

SELECT 'Vin' AS Vin
      ,'Year' AS Year
      ,'Make' AS Make
      ,'Model' AS Model
      ,'ModelCode' AS ModelCode
      ,'CarTrim' AS CarTrim
      ,'Invoice_Price' AS Invoice_Price
      ,'Sale_Price' AS Sale_Price
      ,'MSRP' AS MSRP    
	  ,'Miles' AS Miles
      ,'Condition' AS Condition
	  into FAMMazda
UNION ALL SELECT [V_Vin] AS Vin
      ,Cast([V_Year] AS varchar(10)) AS Year
      ,[V_MakeName] AS Make
      ,[V_ModelName] AS Model
      ,[V_StyleCode] AS ModelCode
      ,[V_StyleName] AS CarTrim
      ,CAST([V_inv_price] AS varchar(20)) AS Invoice_Price
      ,CAST(V_int_price AS varchar(15)) AS Sale_Price
      ,CAST(V_msrp_price AS varchar(15)) AS MSRP    
	  ,CAST([V_Miles] AS varchar(15)) AS Miles
      ,[V_nu] AS Condition
  FROM [fitzway].[dbo].[AllInventoryFM] 
  WHERE V_loc = 'FAM' OR V_loc = 'FCG'  

set @driveOut  = 'bcp.exe "SELECT * from fitzway.dbo.FAMMazda" queryout d:\Third_Party\AutoFi\FTP\FAMMazda.csv -T -c -t,'
--PRINT  @driveOut
EXEC master..xp_cmdshell  @driveOut

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FAMMazda' AND TABLE_SCHEMA = 'dbo')
DROP TABLE FAMMazda
