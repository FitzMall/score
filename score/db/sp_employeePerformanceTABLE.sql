USE [SalesCommission]
GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeePerformanceTABLE]    Script Date: 8/10/2023 8:10:23 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		DAVE BURROUGHS
-- Create date: 8/9/23
-- Description:	Generate Table for team scorecard/high scores display, often in past
-- INCLUDING  BPP and Zurich totals
-- =============================================
ALTER PROCEDURE [dbo].[sp_EmployeePerformanceTABLE]
AS
BEGIN

	-- Add the parameters for the stored procedure here
	DECLARE @parDate date
	SET @parDate = getdate()

	DECLARE	@return_value int

-- list of sales persons by sales team
  SELECT * 
  INTO #TempMakes FROM [ivory].[dbo].[SalesTeamMakes]
  

SELECT b.FIRSTNAME, b.LASTNAME, a.emp_loc AS LOCATION, b.DMS_ID, c.TeamName AS SalesTeam, c.dept_code
INTO #SalesPersonsIvory
FROM [ivory].[dbo].[employees2] a JOIN [FITZDB].[dbo].[users] b ON b.DMS_ID = a.emp_nameid
JOIN #TempMakes c ON c.dept_code = a.emp_deptcode
WHERE ((year(a.emp_termdate) = 1900) OR (datediff(d,a.emp_termdate, @parDate) < 31))
AND a.emp_pos = 'SLS ASSOC'


UPDATE #TempMakes 
SET dept_code = 'GASL01' WHERE  dept_code = 'GASL02'

-- above: termination date must be empty or quite recent

-- list of sales persons 
SELECT b.FIRSTNAME, b.LASTNAME, b.DMS_ID , b.SalesTeam, b.dept_code
  INTO #SalesPersons
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersonsIvory b ON b.DMS_ID = a.sl_SalesAssociate1
    where COALESCE(DMS_ID,'') != '' AND   
	a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) and
  COALESCE(LOCATION, '') != ''
  GROUP by DMS_ID, FIRSTNAME, LASTNAME, SalesTeam, dept_code

  DROP TABLE #SalesPersonsIvory

  UPDATE #SalesPersons 
SET dept_code = 'GASL01' WHERE  dept_code = 'GASL02'

-- one salesperson gets whole 1 sale (no sales assoc 2)
SELECT a.[sl_SalesAssociate1],  a.sl_VehicleMake AS VehicleMake, CAST(SUM(1) AS decimal(5,2)) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesTeam, b.dept_code
  INTO #TEMP_EmployeePerformanceMTD_ByDate
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  and COALESCE([sl_SalesAssociate2],'') = ''
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, sl_VehicleNU, a.sl_VehicleMake, SalesTeam, dept_code
  
  -- half-sales where there is a 2nd sales associate

  --first associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT a.[sl_SalesAssociate1],  a.sl_VehicleMake AS VehicleMake,  SUM(.5) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  and COALESCE([sl_SalesAssociate2],'') != ''
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, sl_VehicleNU, a.sl_VehicleMake, SalesTeam, dept_code

  --second associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT a.[sl_SalesAssociate2] AS sl_SalesAssociate1,  a.sl_VehicleMake AS VehicleMake,  SUM(.5) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME,  b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate2
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  GROUP by sl_SalesAssociate2, FIRSTNAME, LASTNAME, sl_VehicleNU, a.sl_VehicleMake, SalesTeam, dept_code

  --- up to this point the figures are correct
  -- BPP totals

-- one salesperson gets whole 1 sale (no sales assoc 2)
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
SELECT a.[sl_SalesAssociate1],  'BPP' AS VehicleMake, CAST(SUM(1) AS decimal(5,2)) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  and COALESCE([sl_SalesAssociate2],'') = ''
    AND COALESCE(sl_BPP, 0)  > 0 
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, sl_VehicleNU, SalesTeam, dept_code
  
  -- half-sales where there is a 2nd sales associate

  --first associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT a.[sl_SalesAssociate1],   'BPP' AS VehicleMake,  SUM(.5) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  and COALESCE([sl_SalesAssociate2],'') != ''
    AND COALESCE(sl_BPP, 0)  > 0 
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, sl_VehicleNU, SalesTeam, dept_code

  --second associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT a.[sl_SalesAssociate2] AS sl_SalesAssociate1,   'BPP' AS VehicleMake,  SUM(.5) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME,  b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate2
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
    AND COALESCE(sl_BPP, 0)  > 0 
  GROUP by sl_SalesAssociate2, FIRSTNAME, LASTNAME, sl_VehicleNU, SalesTeam, dept_code  


  -- ZURICH

  -- one salesperson gets whole 1 sale (no sales assoc 2)
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
SELECT a.[sl_SalesAssociate1],  'ZURICH' AS VehicleMake, CAST(SUM(1) AS decimal(5,2)) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  and COALESCE([sl_SalesAssociate2],'') = ''
    AND COALESCE(sl_insurance , 0)  > 0 
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, sl_VehicleNU, SalesTeam, dept_code
  
  -- half-sales where there is a 2nd sales associate

  --first associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT a.[sl_SalesAssociate1],   'ZURICH' AS VehicleMake,  SUM(.5) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  and COALESCE([sl_SalesAssociate2],'') != ''
    AND COALESCE(sl_insurance , 0)  > 0 
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, sl_VehicleNU, SalesTeam, dept_code

  --second associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT a.[sl_SalesAssociate2] AS sl_SalesAssociate1,   'ZURICH' AS VehicleMake,  SUM(.5) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME,  b.SalesTeam, b.dept_code
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate2
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
    AND COALESCE(sl_insurance , 0)  > 0 
  GROUP by sl_SalesAssociate2, FIRSTNAME, LASTNAME, sl_VehicleNU, SalesTeam, dept_code  

  -- END OF ZURICH

  UPDATE #TEMP_EmployeePerformanceMTD_ByDate SET VehicleMake = REPLACE(VehicleMake,' TRUCK','') WHERE VehicleMake LIKE '%TRUCK%'
  UPDATE #TEMP_EmployeePerformanceMTD_ByDate SET VehicleMake = 'TOYOTA' WHERE VehicleMake = 'TOYOTA TRUCK'

  UPDATE #TEMP_EmployeePerformanceMTD_ByDate SET VehicleMake = 'USED' WHERE sl_VehicleNU = 'USED' AND VehicleMake NOT IN ('BPP','ZURICH')
  UPDATE #TEMP_EmployeePerformanceMTD_ByDate SET VehicleMake = 'USED' WHERE VehicleMake = ''
  UPDATE #TEMP_EmployeePerformanceMTD_ByDate SET sl_VehicleNU = 'USED' WHERE VehicleMake = 'USED'
  UPDATE #TEMP_EmployeePerformanceMTD_ByDate SET sl_VehicleNU = 'NEW' WHERE VehicleMake != 'USED' AND VehicleMake NOT IN ('BPP','ZURICH')
    -- ADD BLANKS SO THAT ALL BRANDS SHOW UP for each sales team
		
UPDATE #TEMP_EmployeePerformanceMTD_ByDate 
SET dept_code = 'GASL01' WHERE  dept_code = 'GASL02'

  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT b.DMS_ID, a.[Make] AS VehicleMake, 000.00 AS salescount, sl_VehicleNU =
	  CASE 
	  WHEN a.[Make] = 'USED' THEN 'USED'
	  ELSE 'NEW'
      END
	  , b.FIRSTNAME, b.LASTNAME,  b.SalesTeam, b.dept_code
  FROM #TempMakes a JOIN #SalesPersons b on b.dept_code = a.dept_code
    	     
  -- insure there are BPPs (even zeroes) for every person

  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT b.DMS_ID, 'BPP' AS VehicleMake, 000.00 AS salescount, sl_VehicleNU =
	  CASE 
	  WHEN a.[Make] = 'USED' THEN 'USED'
	  ELSE 'NEW'
      END
	  , b.FIRSTNAME, b.LASTNAME,  b.SalesTeam, b.dept_code
  FROM #TempMakes a JOIN #SalesPersons b on b.dept_code = a.dept_code
  
  -- insure there are Zurich (even zeroes) for every person

  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT b.DMS_ID, 'ZURICH' AS VehicleMake, 000.00 AS salescount, sl_VehicleNU =
	  CASE 
	  WHEN a.[Make] = 'USED' THEN 'USED'
	  ELSE 'NEW'
      END
	  , b.FIRSTNAME, b.LASTNAME,  b.SalesTeam, b.dept_code
  FROM #TempMakes a JOIN #SalesPersons b on b.dept_code = a.dept_code

SELECT IDENTITY(INT, 1,1) AS SalesID, sl_SalesAssociate1, VehicleMake,  SUM(salescount) as MTD, CAST(0.0 AS numeric(5,2)) AS SalesRank,
	CAST(0.0 AS numeric(5,2)) AS SalesRank_USED, CAST(0.0 AS numeric(5,2)) AS SalesRank_NEW, FIRSTNAME, LASTNAME, SalesTeam, dept_code
	INTO #FINAL_MTD1
  FROM #TEMP_EmployeePerformanceMTD_ByDate 
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, VehicleMake, SalesTeam, dept_code
  ORDER BY LASTNAME, FIRSTNAME

 	-- IGNORE those who had NO sales (probably dismissed) 
	SELECT a.SalesID, a.SalesRank, a.SalesRank_USED,a.SalesRank_NEW, a.sl_SalesAssociate1, UPPER(a.VehicleMake) AS VehicleMake
	, a.FIRSTNAME, a.LASTNAME, a.SalesTeam, a.dept_code,
	a.MTD 
	INTO #FINAL_MTD	
	FROM #FINAL_MTD1 a
	JOIN #TempMakes b ON a.dept_code = b.dept_code AND a.VehicleMake = b.Make
	UNION SELECT a.SalesID, a.SalesRank, a.SalesRank_USED,a.SalesRank_NEW, a.sl_SalesAssociate1, UPPER(a.VehicleMake) AS VehicleMake
	, a.FIRSTNAME, a.LASTNAME, a.SalesTeam, a.dept_code,
	a.MTD 
	FROM #FINAL_MTD1 a
	WHERE VehicleMake IN ('BPP','ZURICH')




	-- get sales rank (order in chart from highest top to bottom) for all cars
UPDATE #FINAL_MTD 
SET SalesRank = OtherTable.SalesRank
FROM (
    SELECT SUM(MTD) AS SalesRank, LASTNAME, FIRSTNAME, dept_code,
	sl_SalesAssociate1
    FROM #FINAL_MTD 
	 WHERE VehicleMake != 'BPP'
	 AND  VehicleMake != 'ZURICH'
	 GROUP BY LASTNAME, FIRSTNAME,sl_SalesAssociate1, dept_code) AS OtherTable
WHERE 
    OtherTable.sl_SalesAssociate1 = #FINAL_MTD.sl_SalesAssociate1 
	AND
    OtherTable.LASTNAME = #FINAL_MTD.LASTNAME 
	AND 
	OtherTable.dept_code = #FINAL_MTD.dept_code
	
	-- get sales rank (order in chart from highest top to bottom) for USED cars
UPDATE #FINAL_MTD 
SET SalesRank_USED = OtherTable.SalesRank_USED
FROM (
    SELECT SUM(MTD) AS SalesRank_USED, LASTNAME, FIRSTNAME, dept_code,
	sl_SalesAssociate1
    FROM #FINAL_MTD WHERE VehicleMake = 'USED' GROUP BY LASTNAME, FIRSTNAME,sl_SalesAssociate1, dept_code) AS OtherTable
WHERE 
    OtherTable.sl_SalesAssociate1 = #FINAL_MTD.sl_SalesAssociate1 
	AND
    OtherTable.LASTNAME = #FINAL_MTD.LASTNAME 
		AND 
	OtherTable.dept_code = #FINAL_MTD.dept_code

		-- get sales rank (order in chart from highest top to bottom) for NEW cars
UPDATE #FINAL_MTD 
SET SalesRank_NEW = (SalesRank - SalesRank_USED);

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TodaysTeamScoreboard' AND TABLE_SCHEMA = 'dbo')
DROP TABLE TodaysTeamScoreboard

	SELECT SalesID, SalesRank AS PersonalTotal, CAST((SalesRank * 2) AS int) AS SalesRank, 
	CAST((SalesRank_USED * 2) AS int) AS SalesRank_USED,
	CAST((SalesRank_NEW * 2) AS int) AS SalesRank_NEW, sl_SalesAssociate1, VehicleMake
	, FIRSTNAME, LASTNAME, SalesTeam, dept_code, MTD 
	INTO TodaysTeamScoreboard
	FROM #FINAL_MTD
	WHERE SalesRank > 0
		 ORDER by SalesRank, VehicleMake, SalesID, LASTNAME, FIRSTNAME , sl_SalesAssociate1

DROP TABLE #TEMP_EmployeePerformanceMTD_ByDate 
DROP TABLE #FINAL_MTD1
DROP TABLE #FINAL_MTD
DROP TABLE #TempMakes 

END
