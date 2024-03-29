USE [SalesCommission]
GO
/****** Object:  StoredProcedure [dbo].[sp_EmployeeSalesBPPMTD_ByDate]    Script Date: 3/13/2023 11:26:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:		DAVE BURROUGHS
-- Create date: 3/9/23
-- Description:	for BPP/Zurich sales display, often in past
-- =============================================
ALTER PROCEDURE [dbo].[sp_EmployeeSalesBPPMTD_ByDate]
	-- Add the parameters for the stored procedure here
	 @parDate date
AS
BEGIN

-- list of sales persons by sales team

SELECT b.FIRSTNAME, b.LASTNAME, a.emp_loc AS LOCATION, b.DMS_ID, c.TeamName AS SalesTeam, c.dept_code
INTO #SalesPersonsIvory
FROM [ivory].[dbo].[employees2] a JOIN [FITZDB].[dbo].[users] b ON b.DMS_ID = a.emp_nameid
JOIN [ivory].[dbo].[SalesTeamMakes] c ON c.dept_code = a.emp_deptcode
WHERE ((year(a.emp_termdate) = 1900) OR (datediff(d,a.emp_termdate, @parDate) < 31))
AND a.emp_pos = 'SLS ASSOC'

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

-- one salesperson gets whole 1 sale (no sales assoc 2)
SELECT a.[sl_SalesAssociate1],  a.sl_VehicleMake AS VehicleMake, CAST(SUM(1) AS decimal(5,2)) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesTeam, b.dept_code, a.sl_BPP, a.sl_etch
  INTO #TEMP_EmployeePerformanceMTD_ByDate
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  AND COALESCE([sl_SalesAssociate2],'') = ''
  AND (COALESCE(sl_BPP, 0) + COALESCE(sl_etch, 0)) > 0 
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, sl_VehicleNU, a.sl_VehicleMake, SalesTeam, dept_code, a.sl_BPP, a.sl_etch
  
  -- half-sales where there is a 2nd sales associate

  --first associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT a.[sl_SalesAssociate1],  a.sl_VehicleMake AS VehicleMake,  SUM(.5) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME, b.SalesTeam, b.dept_code, a.sl_BPP, a.sl_etch
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate1
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  and COALESCE([sl_SalesAssociate2],'') != ''
  AND (COALESCE(sl_BPP, 0) + COALESCE(sl_etch, 0)) > 0 
  GROUP by sl_SalesAssociate1, FIRSTNAME, LASTNAME, sl_VehicleNU, a.sl_VehicleMake, SalesTeam, dept_code, a.sl_BPP, a.sl_etch

  --second associate gets half of sale
  INSERT INTO #TEMP_EmployeePerformanceMTD_ByDate
  SELECT a.[sl_SalesAssociate2] AS sl_SalesAssociate1,  a.sl_VehicleMake AS VehicleMake,  SUM(.5) as salescount, a.sl_VehicleNU
	, b.FIRSTNAME, b.LASTNAME,  b.SalesTeam, b.dept_code, a.sl_BPP, a.sl_etch
  FROM [SalesCommission].[dbo].[saleslog] a JOIN #SalesPersons b ON b.DMS_ID = a.sl_SalesAssociate2
    where a.sl_VehicleCategory != 'T' and
 month(sl_dealmonth) = month(@parDate) and
  year(sl_dealmonth) = year(@parDate) 
  AND (COALESCE(sl_BPP, 0) + COALESCE(sl_etch, 0)) > 0 
  GROUP by sl_SalesAssociate2, FIRSTNAME, LASTNAME, sl_VehicleNU, a.sl_VehicleMake, SalesTeam, dept_code, a.sl_BPP, a.sl_etch

  --- up to this point the figures are correct

  UPDATE #TEMP_EmployeePerformanceMTD_ByDate SET VehicleMake = 'BPP' WHERE COALESCE(sl_BPP,0) > 0
  UPDATE #TEMP_EmployeePerformanceMTD_ByDate SET VehicleMake = 'ZURICH' WHERE COALESCE(sl_etch,0) > 0
  UPDATE #TEMP_EmployeePerformanceMTD_ByDate SET VehicleMake = 'BOTH' WHERE COALESCE(sl_etch,0) > 0 AND COALESCE(sl_BPP,0) > 0
  DELETE FROM #TEMP_EmployeePerformanceMTD_ByDate  WHERE COALESCE(sl_etch,0) = 0 AND COALESCE(sl_BPP,0) = 0
  DROP TABLE #SalesPersons

  SELECT salescount, sl_SalesAssociate1, FIRSTNAME, LASTNAME, VehicleMake, SalesTeam, dept_code,
  0 AS SalesRank, 0 AS SalesRank_New, 0 AS SalesRank_Used
  INTO #TEMP_COMBINE FROM #TEMP_EmployeePerformanceMTD_ByDate
  UNION SELECT 0 AS salescount, sl_SalesAssociate1, FIRSTNAME, LASTNAME, 'ZURICH' AS VehicleMake, SalesTeam, dept_code,
  0 AS SalesRank, 0 AS SalesRank_New, 0 AS SalesRank_Used FROM #TEMP_EmployeePerformanceMTD_ByDate
  UNION SELECT 0 AS salescount, sl_SalesAssociate1, FIRSTNAME, LASTNAME, 'BOTH' AS VehicleMake, SalesTeam, dept_code,
  0 AS SalesRank, 0 AS SalesRank_New, 0 AS SalesRank_Used FROM #TEMP_EmployeePerformanceMTD_ByDate
  UNION SELECT 0 AS salescount, sl_SalesAssociate1, FIRSTNAME, LASTNAME, 'BPP' AS VehicleMake, SalesTeam, dept_code,
  0 AS SalesRank, 0 AS SalesRank_New, 0 AS SalesRank_Used FROM #TEMP_EmployeePerformanceMTD_ByDate

  DROP TABLE #TEMP_EmployeePerformanceMTD_ByDate

  	-- get sales rank (order in chart from highest top to bottom) for all cars
UPDATE #TEMP_COMBINE 
SET SalesRank = OtherTable.SalesRank
FROM (
    SELECT SUM(salescount * 2) AS SalesRank, LASTNAME, FIRSTNAME, dept_code,
	sl_SalesAssociate1
    FROM #TEMP_COMBINE GROUP BY LASTNAME, FIRSTNAME,sl_SalesAssociate1, dept_code) AS OtherTable
WHERE 
    OtherTable.sl_SalesAssociate1 = #TEMP_COMBINE.sl_SalesAssociate1 
	AND
    OtherTable.LASTNAME = #TEMP_COMBINE.LASTNAME 
	AND 
	OtherTable.dept_code = #TEMP_COMBINE.dept_code

  
  SELECT  IDENTITY(INT, 1,1) AS SalesID,  SUM(salescount) AS MTD, sl_SalesAssociate1, FIRSTNAME, LASTNAME, VehicleMake, SalesTeam, dept_code,
  SalesRank, 0 AS SalesRank_New, 0 AS SalesRank_Used 
  INTO #TEMP_FINAL
  FROM #TEMP_COMBINE
    GROUP BY  sl_SalesAssociate1, FIRSTNAME, LASTNAME, VehicleMake, SalesTeam, dept_code,SalesRank

	SELECT * FROM  #TEMP_FINAL 

	DROP TABLE #TEMP_COMBINE
  DROP TABLE #TEMP_FINAL


END
