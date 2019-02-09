USE SoftUni
GO

/*--01--*/
SELECT TOP 5 e.EmployeeID, e.JobTitle, e.AddressID, a.AddressText FROM Employees AS e
JOIN Addresses AS a
ON a.AddressID = e.AddressID
ORDER BY a.AddressID 

/*--02--*/
SELECT TOP 50 FirstName, LastName, t.Name AS Town, AddressText FROM Employees AS e
JOIN Addresses AS a
ON a.AddressID = e.AddressID
JOIN Towns AS t
ON t.TownID = a.TownID
ORDER BY FirstName, LastName

/*--3--*/
SELECT e.EmployeeID
	, e.FirstName
	, e.LastName
	, d.Name AS DepartmentName 
	FROM Employees AS e
	JOIN Departments AS d
	ON d.DepartmentID = e.DepartmentID
	WHERE d.Name = 'Sales'
	ORDER BY e.EmployeeID

/*--4--*/
SELECT TOP(5) e.EmployeeID
	, e.FirstName
	, e.Salary

	, d.Name AS DepartmentName 
	FROM Employees AS e
	JOIN Departments AS d
	ON d.DepartmentID = e.DepartmentID
	WHERE e.Salary > 15000
	ORDER BY d.DepartmentID
	 
/*--05--*/
SELECT DISTINCT TOP(3) 
	e.EmployeeID
	, e.FirstName
FROM Employees AS e
	RIGHT OUTER JOIN EmployeesProjects AS ep
	ON e.EmployeeID NOT IN(SELECT DISTINCT EmployeeID 
FROM EmployeesProjects)
	ORDER BY e.EmployeeID

/*--6--*/
SELECT e.FirstName
	,e.LastName
	,e.HireDate
	,d.Name
	FROM Employees AS e
	JOIN Departments AS d
	ON d.DepartmentID = e.DepartmentID
	WHERE e.HireDate > '1999-01-01' 
	AND (d.Name IN ('Sales', 'Finance'))
	ORDER BY e.EmployeeID

/*--7--*/
SELECT TOP(5) e.EmployeeID, e.FirstName, p.[Name] AS ProjectName
FROM Employees AS e
INNER JOIN EmployeesProjects AS ep
ON e.EmployeeID = ep.EmployeeID
INNER JOIN Projects AS p
ON ep.ProjectID = p.ProjectID
WHERE p.StartDate > 13/02.2002 AND p.EndDate IS NULL
ORDER BY EmployeeID

/*--8--*/
SELECT e.EmployeeID, e.FirstName, 
CASE WHEN p.StartDate >= '2005' THEN NULL
ELSE p.[Name]
END ProjectName
FROM Employees AS e
INNER JOIN EmployeesProjects AS ep
ON e.EmployeeID = ep.EmployeeID
INNER JOIN Projects as p
ON p.ProjectID = ep.ProjectID
WHERE e.EmployeeID = 24

/*--9--*/
SELECT e.EmployeeID, e.FirstName, e.ManagerID, e2.FirstName AS ManagerName 
FROM Employees AS e
JOIN Employees AS e2
ON e2.EmployeeID = e.ManagerID AND e.ManagerID IN(3, 7)
ORDER BY e.EmployeeID

/*--10--*/
SELECT TOP(50)e.EmployeeID
,e.FirstName + ' ' + e.LastName AS [EmployeeName]
,e2.FirstName + ' ' + e2.LastName AS [ManagerName]
,d.Name AS DepartmentName
  FROM Employees AS e
INNER JOIN Employees AS e2
ON e.ManagerID =e2.EmployeeID
INNER JOIN Departments AS d
ON d.DepartmentID = e.DepartmentID
ORDER BY e.EmployeeID

/*--11--*/
SELECT MIN(AverageSalary) FROM
  (SELECT DepartmentID, AVG(Salary) AS AverageSalary 
   FROM Employees
  GROUP BY DepartmentID) AS AverageSalariesByDepartment

/*--12--*/
USE Geography

SELECT c.CountryCode, m.MountainRange, p.PeakName, p.Elevation
FROM Countries AS c
INNER JOIN MountainsCountries AS mc
ON c.CountryCode = mc.CountryCode AND c.CountryCode = 'BG'
INNER JOIN Mountains AS m
ON m.Id = mc.MountainId
JOIN Peaks AS p
ON p.MountainId = mc.MountainId AND p.Elevation > 2835
ORDER BY p.Elevation DESC

/*--13--*/
SELECT c.CountryCode, COUNT(mc.MountainId) AS MountainRanges
FROM Countries AS c
JOIN MountainsCountries AS mc
ON c.CountryCode = mc.CountryCode AND c.CountryName IN('United States', 'Russia', 'Bulgaria')
GROUP BY c.CountryCode

/*--14--*/
SELECT TOP(5) c.CountryName, r.RiverName
FROM Countries AS c
LEFT JOIN CountriesRivers AS cr
ON c.CountryCode = cr.CountryCode
LEFT JOIN Rivers AS r
ON cr.RiverId = r.Id
WHERE c.ContinentCode = (SELECT ContinentCode FROM Continents WHERE ContinentName = 'Africa')
ORDER BY c.CountryName

/*--15--*/
SELECT ContinentCode, CurrencyCode, CurrencyUsage
FROM 
(SELECT ContinentCode, CurrencyCode, CurrencyUsage,
DENSE_RANK() OVER(PARTITION BY(ContinentCode) ORDER BY CurrencyUsage DESC) AS [Rank]
FROM
(SELECT ContinentCode, CurrencyCode, COUNT(CurrencyCode) AS CurrencyUsage
FROM Countries
GROUP BY CurrencyCode, ContinentCode) AS Currencies) AS RankedCurrencies
WHERE [Rank] = 1 AND CurrencyUsage > 1
ORDER BY ContinentCode

/*--16--*/
SELECT COUNT(CountryCode) AS CountryCode
FROM Countries
WHERE CountryCode NOT IN (SELECT CountryCode FROM MountainsCountries)

/*--17--*/
WITH CTE_CountryHighestPeak AS
(
	SELECT c.CountryName, MAX(p.Elevation) AS HighestPeakElevation FROM Countries AS c
	LEFT JOIN MountainsCountries AS mc
	ON mc.CountryCode = c.CountryCode
	LEFT JOIN Peaks AS p
	ON p.MountainId = mc.MountainId
	GROUP BY c.CountryName
),

CTE_CountryLongestRiver AS
(
	SELECT c.CountryName, MAX(r.Length) AS LongestRiverLength FROM Countries AS c
	LEFT JOIN CountriesRivers AS cr
	ON cr.CountryCode = c.CountryCode
	LEFT JOIN Rivers AS r
	ON r.Id = cr.RiverId
	GROUP BY c.CountryName
)

SELECT TOP(5) hp.CountryName, hp.HighestPeakElevation, lr.LongestRiverLength FROM CTE_CountryHighestPeak AS hp
JOIN CTE_CountryLongestRiver AS lr
ON lr.CountryName = hp.CountryName
ORDER BY hp.HighestPeakElevation DESC, lr.LongestRiverLength DESC

/*--18--*/
SELECT TOP(5)CountryName
,CASE 
	WHEN PeakName IS NULL THEN '(no highest peak)'
	ELSE PeakName
	END AS [Highest Peak Name]
,CASE 
	WHEN Elevation IS NULL THEN 0
	ELSE Elevation
	END AS [Highest Peak Elevation]
,CASE 
	WHEN MountainRange IS NULL THEN '(no mountain)'
	ELSE MountainRange
	END AS Mountain
FROM	
	(SELECT CountryName, PeakName, Elevation, MountainRange,
	  DENSE_RANK() OVER (PARTITION BY CountryName ORDER BY Elevation DESC) AS [Rank]
	FROM
		(SELECT c.CountryName, p.PeakName, p.Elevation, m.MountainRange
		FROM Countries AS c
		LEFT JOIN MountainsCountries AS mc ON c.CountryCode = mc.CountryCode
		LEFT JOIN Mountains AS m ON mc.MountainId = m.Id 
		LEFT JOIN Peaks as p ON m.Id = p.MountainId) AS allPeaks) AS rankedPeaks
WHERE [Rank] = 1
ORDER BY CountryName, PeakName
	
