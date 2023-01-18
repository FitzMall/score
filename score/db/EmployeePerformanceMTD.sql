USE [SalesCommission]
GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeePerformanceMTD]    Script Date: 1/18/2023 8:31:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		DAVE BURROUGHS
-- Create date: 12/12/22
-- Description:	for employee scorecard/high scores display
-- =============================================
ALTER PROCEDURE [dbo].[sp_EmployeePerformanceMTD]
	-- Add the parameters for the stored procedure here
AS
BEGIN

DECLARE	@return_value int

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'EmployeePerformanceMTD' AND TABLE_SCHEMA = 'dbo')
DROP TABLE EmployeePerformanceMTD


SELECT a.[sl_SalesAssociate1],  a.sl_VehicleMake AS VehicleMake, COUNT(a.sl_VehicleVIN) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, B.LOCATION
  INTO #TEMP_EmployeePerformanceMTD
  FROM [SalesCommission].[dbo].[saleslog] a JOIN [FITZDB].[dbo].[users] b ON b.DMS_ID = a.sl_SalesAssociate1
    where COALESCE(DMS_ID,'') != '' AND   
 month(sl_VehicleDealDate) = month(getdate()) and
  year(sl_VehicleDealDate) = year(getdate()) 
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, B.LOCATION, sl_VehicleNU, a.sl_VehicleMake order by sl_SalesAssociate1, sl_VehicleMake desc

  -- ADD BLANKS SO THAT ALL BRANDS SHOW UP

  INSERT INTO #TEMP_EmployeePerformanceMTD
  SELECT b.DMS_ID, a.[VehicleMake], 0 AS salescount, sl_VehicleNU =
	  CASE 
	  WHEN a.[VehicleMake] = 'USED' THEN 'USED'
	  ELSE 'NEW'
      END
	  , b.FIRSTNAME, b.LASTNAME, B.LOCATION 
  FROM [SalesCommission].[dbo].[MakesByLocation] a JOIN [FITZDB].[dbo].[users] b on b.LOCATION = a.LOCATION
  WHERE COALESCE(b.DMS_ID,'') != '' AND COALESCE(b.LASTNAME,'') != ''

  UPDATE #TEMP_EmployeePerformanceMTD SET VehicleMake = REPLACE(VehicleMake,' TRUCK','') WHERE VehicleMake LIKE '%TRUCK%'
  UPDATE #TEMP_EmployeePerformanceMTD SET VehicleMake = 'USED' WHERE sl_VehicleNU = 'USED'
  UPDATE #TEMP_EmployeePerformanceMTD SET VehicleMake = 'USED' WHERE VehicleMake = ''

SELECT IDENTITY(INT, 1,1) AS SalesID, [sl_SalesAssociate1], VehicleMake, SUM(salescount) as MTD, sl_VehicleNU
	, FIRSTNAME, LASTNAME, LOCATION
  INTO EmployeePerformanceMTD 
  FROM #TEMP_EmployeePerformanceMTD 
  GROUP by sl_SalesAssociate1, VehicleMake, FIRSTNAME, LASTNAME, LOCATION, sl_VehicleNU 
  order by sl_SalesAssociate1, VehicleMake, sl_VehicleNU desc

SELECT [sl_SalesAssociate1], SUM(MTD) as MTD
	INTO #TEMP_DeleteZeroPersonalMTD
	FROM EmployeePerformanceMTD 
  GROUP by sl_SalesAssociate1

  DROP TABLE #TEMP_EmployeePerformanceMTD

  DELETE FROM EmployeePerformanceMTD WHERE sl_SalesAssociate1 IN (SELECT sl_SalesAssociate1 FROM #TEMP_DeleteZeroPersonalMTD WHERE MTD = 0)
  DROP TABLE #TEMP_DeleteZeroPersonalMTD

END
