USE [SalesCommission]
GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeePerformanceMTD]    Script Date: 1/26/2023 1:47:33 PM ******/
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

--get brands for each location/mall/sales team

  SELECT mallcode , UPPER(make) AS VehicleMake 
  INTO #MakesByLocation1 
  FROM Mall join Make on Make.mall_id = Mall.id 
  WHERE on_off = '' and makecode != 'AA' AND Makecode != 'IC'  
AND COALESCE(mallcode,'') != '' 
ORDER BY mallcode

SELECT DISTINCT  a.[dept_code]
      ,a.[dept_desc]
	  ,b.emp_deptcode
	  , c.VehicleMake
  INTO #MakesByTeam 
  FROM [ivory].[dbo].[dept] a JOIN [ivory].[dbo].[employees2] b ON b.emp_deptcode = a.dept_code
  JOIN #MakesByLocation1 c ON b.emp_loc = c.mallcode
  WHERE b.emp_pos = 'SLS ASSOC' 
  AND b.emp_loc != '???'
  AND b.emp_loc != ''

  drop table #MakesByLocation1

  UPDATE #MakesByTeam SET VehicleMake = 'USED' WHERE VehicleMake LIKE '%Used%' 
  UPDATE #MakesByTeam SET VehicleMake = REPLACE(VehicleMake,' TRUCK','') WHERE VehicleMake LIKE '%TRUCK%'

-- list of sales persons by sales team

SELECT 	b.FIRSTNAME, b.LASTNAME, a.emp_loc AS LOCATION, b.DMS_ID, c.dept_desc AS SalesTeam, c.dept_code
INTO #SalesPersonsIvory
FROM [ivory].[dbo].[employees2] a JOIN [FITZDB].[dbo].[users] b ON b.DMS_ID = a.emp_nameid
JOIN [ivory].[dbo].[dept] c ON c.dept_code = a.emp_deptcode
AND b.LASTNAME = a.emp_lname
AND b.FIRSTNAME = a.emp_fname
AND ((year(a.emp_termdate) = 1900) OR (datediff(d,a.emp_termdate, getdate()) < 31))
-- above: termination date must be empty or quite recent

-- list of sales persons with total sales for ALL brands (Sales Rank)
SELECT COUNT(a.sl_VehicleVIN) as SalesRank
	, b.FIRSTNAME, b.LASTNAME, b.LOCATION, b.DMS_ID , b.SalesTeam, b.dept_code
  INTO #SalesPersons
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersonsIvory b ON b.DMS_ID = a.sl_SalesAssociate1
    where COALESCE(DMS_ID,'') != '' AND   
 month(sl_VehicleDealDate) = month(getdate()) and
  year(sl_VehicleDealDate) = year(getdate()) and
  COALESCE(LOCATION, '') != ''
  GROUP by DMS_ID, FIRSTNAME, LASTNAME, LOCATION, SalesTeam, dept_code

  DROP TABLE #SalesPersonsIvory

-- one salesperson gets whole 1 sale (no sales assoc 2)
SELECT a.[sl_SalesAssociate1],  a.sl_VehicleMake AS VehicleMake, CAST(COUNT(a.sl_VehicleVIN) AS decimal(5,2)) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesRank, b.SalesTeam, b.dept_code
  INTO #TEMP_EmployeePerformanceMTD1
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where COALESCE(DMS_ID,'') != '' AND   
 month(sl_VehicleDealDate) = month(getdate()) and
  year(sl_VehicleDealDate) = year(getdate()) 
  and COALESCE([sl_SalesAssociate2],'') = ''
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, B.LOCATION, sl_VehicleNU, a.sl_VehicleMake, SalesRank ,SalesTeam, dept_code
  
  -- half-sales where there is a 2nd sales associate

  --first associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD1
  SELECT a.[sl_SalesAssociate1],  a.sl_VehicleMake AS VehicleMake, COUNT(a.sl_VehicleVIN) * .5 as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesRank, b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where COALESCE(DMS_ID,'') != '' AND   
 month(sl_VehicleDealDate) = month(getdate()) and
  year(sl_VehicleDealDate) = year(getdate()) 
  and COALESCE([sl_SalesAssociate2],'') != ''
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, B.LOCATION, sl_VehicleNU, a.sl_VehicleMake, SalesRank ,SalesTeam, dept_code

  --second associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD1
  SELECT a.[sl_SalesAssociate2] AS sl_SalesAssociate1,  a.sl_VehicleMake AS VehicleMake, COUNT(a.sl_VehicleVIN) * .5 as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesRank, b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate2
    where COALESCE(DMS_ID,'') != '' AND   
 month(sl_VehicleDealDate) = month(getdate()) and
  year(sl_VehicleDealDate) = year(getdate()) 
  and COALESCE([sl_SalesAssociate2],'') != ''
  GROUP by sl_SalesAssociate2, FIRSTNAME, LASTNAME, B.LOCATION, sl_VehicleNU, a.sl_VehicleMake, SalesRank ,SalesTeam, dept_code


  UPDATE #TEMP_EmployeePerformanceMTD1 SET VehicleMake = REPLACE(VehicleMake,' TRUCK','') WHERE VehicleMake LIKE '%TRUCK%'
  UPDATE #TEMP_EmployeePerformanceMTD1 SET VehicleMake = 'USED' WHERE sl_VehicleNU = 'USED'
  UPDATE #TEMP_EmployeePerformanceMTD1 SET VehicleMake = 'USED' WHERE VehicleMake = ''
  UPDATE #TEMP_EmployeePerformanceMTD1 SET sl_VehicleNU = 'USED' WHERE VehicleMake = 'USED' AND sl_VehicleNU = ''

  --only get ones that are sold at the CORRECT location and brand

SELECT a.[sl_SalesAssociate1],  b.VehicleMake, a.salescount, a.sl_VehicleNU
	, a.FIRSTNAME, a.LASTNAME, a.SalesRank, a.SalesTeam, a.dept_code
  INTO #TEMP_EmployeePerformanceMTD
  FROM #TEMP_EmployeePerformanceMTD1 a JOIN #MakesByTeam b ON a.VehicleMake = b.VehicleMake AND
  a.dept_code = b.dept_code

  DROP TABLE #TEMP_EmployeePerformanceMTD1

  -- ADD BLANKS SO THAT ALL BRANDS SHOW UP for each sales team
-- insert zero totals for all salesmen for all showrooms for all products relevant to them

  INSERT INTO #TEMP_EmployeePerformanceMTD
  SELECT b.DMS_ID, a.[VehicleMake], 0.00 AS salescount, sl_VehicleNU =
	  CASE 
	  WHEN a.[VehicleMake] = 'USED' THEN 'USED'
	  ELSE 'NEW'
      END
	  , b.FIRSTNAME, b.LASTNAME, b.SalesRank, b.SalesTeam, b.dept_code
  FROM #MakesByTeam a JOIN #SalesPersons b on b.dept_code = a.dept_code
  WHERE COALESCE(b.DMS_ID,'') != '' AND COALESCE(b.LASTNAME,'') != ''

  DROP TABLE #MakesByTeam

SELECT DISTINCT [sl_SalesAssociate1], VehicleMake, CAST(SUM(salescount) AS decimal(5,2)) AS MTD
	, FIRSTNAME, LASTNAME, SalesRank,SalesTeam, dept_code
  INTO #TEMP_EmployeePerformanceMTD2  
  FROM #TEMP_EmployeePerformanceMTD 
  GROUP by sl_SalesAssociate1, VehicleMake, FIRSTNAME, LASTNAME, SalesRank, SalesTeam, dept_code

SELECT DISTINCT IDENTITY(INT, 1,1) AS SalesID, [sl_SalesAssociate1], VehicleMake, MTD
	, FIRSTNAME, LASTNAME, SalesRank, SalesTeam, dept_code
  INTO EmployeePerformanceMTD  
  FROM #TEMP_EmployeePerformanceMTD2 
  ORDER by SalesRank, sl_SalesAssociate1, VehicleMake 

    DROP TABLE #TEMP_EmployeePerformanceMTD
    DROP TABLE #TEMP_EmployeePerformanceMTD2
	DROP TABLE #SalesPersons

	-- DELETE those who had NO sales (probably dismissed) 

  DELETE FROM EmployeePerformanceMTD WHERE SalesRank = 0;

END
