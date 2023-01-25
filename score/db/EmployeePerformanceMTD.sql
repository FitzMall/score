USE [SalesCommission]
GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeePerformanceMTD]    Script Date: 1/25/2023 8:39:40 AM ******/
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

--get brands for each location/mall

  SELECT mallcode , UPPER(make) AS VehicleMake 
  INTO #MakesByLocation 
  FROM Mall join Make on Make.mall_id = Mall.id 
  WHERE on_off = '' and makecode != 'AA' AND Makecode != 'IC'  
AND COALESCE(mallcode,'') != '' 
ORDER BY mallcode

  UPDATE #MakesByLocation SET mallcode = 'FTN' WHERE mallcode = 'FTO' 
  UPDATE #MakesByLocation SET mallcode = 'FBS' WHERE mallcode = 'FBN' 
  UPDATE #MakesByLocation SET VehicleMake = 'USED' WHERE VehicleMake LIKE '%Used%' 
  UPDATE #MakesByLocation SET VehicleMake = REPLACE(VehicleMake,' TRUCK','') WHERE VehicleMake LIKE '%TRUCK%'

-- get sales with info on salespersons for present month

-- list of sales persons with total sales for ALL brands (Sales Rank)
SELECT COUNT(a.sl_VehicleVIN) as SalesRank
	, b.FIRSTNAME, b.LASTNAME, b.LOCATION, b.DMS_ID 
  INTO #SalesPersons
  FROM [SalesCommission].[dbo].[saleslog] a JOIN [FITZDB].[dbo].[users] b ON b.DMS_ID = a.sl_SalesAssociate1
    where COALESCE(DMS_ID,'') != '' AND   
 month(sl_VehicleDealDate) = month(getdate()) and
  year(sl_VehicleDealDate) = year(getdate()) 
  GROUP by DMS_ID, FIRSTNAME, LASTNAME, LOCATION

UPDATE #SalesPersons SET LOCATION = 'FTN' WHERE LOCATION = 'FTO' 
UPDATE #SalesPersons SET LOCATION = 'FBS' WHERE LOCATION = 'FBN' 

-- one salesperson gets whole 1 sale (no sales assoc 2)
SELECT a.[sl_SalesAssociate1],  a.sl_VehicleMake AS VehicleMake, COUNT(a.sl_VehicleVIN) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.LOCATION, b.SalesRank 
  INTO #TEMP_EmployeePerformanceMTD1
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where COALESCE(DMS_ID,'') != '' AND   
 month(sl_VehicleDealDate) = month(getdate()) and
  year(sl_VehicleDealDate) = year(getdate()) 
  and COALESCE([sl_SalesAssociate2],'') = ''
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, B.LOCATION, sl_VehicleNU, a.sl_VehicleMake, SalesRank order by sl_SalesAssociate1, sl_VehicleMake desc
  
  -- half-sales where there is a 2nd sales associate

  --first associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD1
  SELECT a.[sl_SalesAssociate1],  a.sl_VehicleMake AS VehicleMake, COUNT(a.sl_VehicleVIN) * .5 as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.LOCATION , b.SalesRank
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where COALESCE(DMS_ID,'') != '' AND   
 month(sl_VehicleDealDate) = month(getdate()) and
  year(sl_VehicleDealDate) = year(getdate()) 
  and COALESCE([sl_SalesAssociate2],'') != ''
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, B.LOCATION, sl_VehicleNU, a.sl_VehicleMake, SalesRank order by sl_SalesAssociate1, sl_VehicleMake desc

  --second associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD1
  SELECT a.[sl_SalesAssociate2],  a.sl_VehicleMake AS VehicleMake, COUNT(a.sl_VehicleVIN) * .5 as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.LOCATION , b.SalesRank
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate2
    where COALESCE(DMS_ID,'') != '' AND   
 month(sl_VehicleDealDate) = month(getdate()) and
  year(sl_VehicleDealDate) = year(getdate()) 
  and COALESCE([sl_SalesAssociate2],'') != ''
  GROUP by sl_SalesAssociate2, FIRSTNAME, LASTNAME, B.LOCATION, sl_VehicleNU, a.sl_VehicleMake, SalesRank order by sl_SalesAssociate2, sl_VehicleMake desc

  UPDATE #TEMP_EmployeePerformanceMTD1 SET LOCATION = 'FTN' WHERE LOCATION = 'FTO' 
  UPDATE #TEMP_EmployeePerformanceMTD1 SET LOCATION = 'FBS' WHERE LOCATION = 'FBN' 

  UPDATE #TEMP_EmployeePerformanceMTD1 SET VehicleMake = REPLACE(VehicleMake,' TRUCK','') WHERE VehicleMake LIKE '%TRUCK%'
  UPDATE #TEMP_EmployeePerformanceMTD1 SET VehicleMake = 'USED' WHERE sl_VehicleNU = 'USED'
  UPDATE #TEMP_EmployeePerformanceMTD1 SET VehicleMake = 'USED' WHERE VehicleMake = ''
  UPDATE #TEMP_EmployeePerformanceMTD1 SET sl_VehicleNU = 'USED' WHERE VehicleMake = 'USED' AND sl_VehicleNU = ''

  --only get ones that are sold at the CORRECT location and brand

SELECT a.[sl_SalesAssociate1],  b.VehicleMake, a.salescount, a.sl_VehicleNU
	, a.FIRSTNAME, a.LASTNAME, a.LOCATION , a.SalesRank
  INTO #TEMP_EmployeePerformanceMTD
  FROM #TEMP_EmployeePerformanceMTD1 a JOIN #MakesByLocation b ON a.VehicleMake = b.VehicleMake AND
  a.LOCATION = b.mallcode

  DROP TABLE #TEMP_EmployeePerformanceMTD1

  -- ADD BLANKS SO THAT ALL BRANDS SHOW UP
-- insert zero totals for all salesmen for all showrooms for all products relevant to them

  INSERT INTO #TEMP_EmployeePerformanceMTD
  SELECT b.DMS_ID, a.[VehicleMake], 0 AS salescount, sl_VehicleNU =
	  CASE 
	  WHEN a.[VehicleMake] = 'USED' THEN 'USED'
	  ELSE 'NEW'
      END
	  , b.FIRSTNAME, b.LASTNAME, A.mallcode AS LOCATION  , b.SalesRank
  FROM #MakesByLocation a JOIN #SalesPersons b on b.LOCATION = a.mallcode
  WHERE COALESCE(b.DMS_ID,'') != '' AND COALESCE(b.LASTNAME,'') != ''

  DROP TABLE #MakesByLocation

SELECT DISTINCT [sl_SalesAssociate1], VehicleMake, SUM(salescount) as MTD
	, FIRSTNAME, LASTNAME, LOCATION, SalesRank
  INTO #TEMP_EmployeePerformanceMTD2  
  FROM #TEMP_EmployeePerformanceMTD 
  GROUP by sl_SalesAssociate1, VehicleMake, FIRSTNAME, LASTNAME, LOCATION , SalesRank

SELECT DISTINCT IDENTITY(INT, 1,1) AS SalesID, [sl_SalesAssociate1], VehicleMake, MTD
	, FIRSTNAME, LASTNAME, LOCATION, SalesRank
  INTO EmployeePerformanceMTD  
  FROM #TEMP_EmployeePerformanceMTD2 
  ORDER by sl_SalesAssociate1, VehicleMake 

    DROP TABLE #TEMP_EmployeePerformanceMTD
    DROP TABLE #TEMP_EmployeePerformanceMTD2
	DROP TABLE #SalesPersons

	-- DELETE those who had NO sales (probably dismissed) 
SELECT [sl_SalesAssociate1], SUM(MTD) as MTD
	INTO #TEMP_DeleteZeroPersonalMTD
	FROM EmployeePerformanceMTD 
  GROUP by sl_SalesAssociate1


  DELETE FROM EmployeePerformanceMTD WHERE sl_SalesAssociate1 IN (SELECT sl_SalesAssociate1 FROM #TEMP_DeleteZeroPersonalMTD WHERE MTD = 0)
  DROP TABLE #TEMP_DeleteZeroPersonalMTD

END
