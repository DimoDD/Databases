USE Gringotts

/*--01--*/
SELECT COUNT(*) AS Count 
	FROM WizzardDeposits 

/*--02--*/
SELECT MAX(MagicWandSize) AS LongestMagicWand
FROM WizzardDeposits

/*--03--*/
SELECT DepositGroup, MAX(MagicWandSize) AS LongestMagicWand
	FROM WizzardDeposits
GROUP BY DepositGroup

/*--4--*/
SELECT TOP 2 DepositGroup 
	FROM WizzardDeposits
GROUP BY DepositGroup
ORDER BY AVG(MagicWandSize)

/*--05--*/
SELECT DepositGroup, SUM(DepositAmount) AS TotalSum 
	FROM WizzardDeposits
GROUP BY DepositGroup

/*--06--*/
SELECT DepositGroup, SUM(DepositAmount) AS TotalSum
	FROM WizzardDeposits
WHERE MagicWandCreator = 'Ollivander Family'
GROUP BY DepositGroup

/*--07--*/
SELECT DepositGroup, SUM(DepositAmount) AS TotalSum 
	FROM WizzardDeposits
	WHERE MagicWandCreator = 'Ollivander Family'
GROUP BY DepositGroup
HAVING SUM(DepositAmount) < 150000
ORDER BY TotalSum DESC

/*--08--*/
SELECT DepositGroup, MagicWandCreator, MIN(DepositCharge) AS MinDepositCharge 
	FROM WizzardDeposits
GROUP BY DepositGroup, MagicWandCreator
ORDER BY MagicWandCreator, DepositGroup

/*--9--*/
SELECT*,COUNT(*) AS WizardCount 
FROM
(
	SELECT 
		CASE
		WHEN Age <= 10 THEN '[0-10]'
		WHEN Age BETWEEN 11 AND 20 THEN '[11-20]'
		WHEN Age BETWEEN 21 AND 30 THEN '[21-30]'
		WHEN Age BETWEEN 31 AND 40 THEN '[31-40]'
		WHEN Age BETWEEN 41 AND 50 THEN '[41-50]'
		WHEN Age BETWEEN 51 AND 60 THEN '[51-60]'
		ELSE '[61+]'
		END AS AgeGroup
		FROM WizzardDeposits
)AS t
GROUP BY AgeGroup
ORDER BY AgeGroup

/*--10--*/
SELECT LEFT(FirstName, 1) AS FirstLetter 
FROM WizzardDeposits
WHERE DepositGroup = 'Troll Chest'
GROUP BY LEFT(FirstName, 1)

/*--11--*/
SELECT DepositGroup, IsDepositExpired, AVG(DepositInterest) AS AverageInterest
FROM WizzardDeposits
WHERE DepositStartDate >= '01/01/1985'
GROUP BY DepositGroup, IsDepositExpired
ORDER BY DepositGroup DESC, IsDepositExpired

/*--12--*/
SELECT SUM(k.Diff) AS SumDifference
  FROM(
SELECT wd.Id, wd.FirstName, wd.DepositAmount - (SELECT w.DepositAmount FROM WizzardDeposits AS w WHERE w.Id = wd.Id+1) AS Diff
  FROM WizzardDeposits AS wd)
AS k

/*--12--another solution*/
SELECT SUM(k.SumDiff) AS SumDifference
 FROM(
SELECT DepositAmount - LEAD(DepositAmount,1) OVER(ORDER BY Id) AS SumDiff
  FROM WizzardDeposits) AS k

/*--13--*/
USE SoftUni
SELECT DepartmentId, SUM(Salary) AS TotalSum
  FROM Employees
  GROUP BY DepartmentId

/*--14--*/
SELECT DepartmentID, MIN(Salary) AS TotalSum
  FROM Employees
  WHERE DepartmentID IN (2,5,7) AND HireDate > '01/01/2000'
  GROUP BY DepartmentID

/*--15--*/
SELECT  * INTO NET
FROM Employees
WHERE SALARY > 30000

DELETE FROM NET
WHERE ManagerID = 42

UPDATE NET
SET Salary += 5000
WHERE DepartmentID = 1

SELECT DepartmentID, AVG(Salary) AS AverageSalary
FROM NET
GROUP BY DepartmentID

/*--16--*/
SELECT DepartmentID, MAX(Salary) AS MaxSalary
FROM Employees
GROUP BY DepartmentID
HAVING MAX(Salary) NOT BETWEEN 30000 AND 70000

/*--17--*/
SELECT COUNT(*)
FROM Employees
WHERE ManagerID IS NULL

/*--18--*/
SELECT k.DepartmentID, k.Salary
FROM(
SELECT DepartmentID, Salary, DENSE_RANK() OVER (PARTITION BY DepartmentID ORDER BY Salary DESC) AS SalaryRank
FROM Employees) AS k
WHERE K.SalaryRank = 3
GROUP BY K.DepartmentID, K.Salary

/*--19--*/
SELECT TOP(10) FirstName, LastName, DepartmentID
FROM Employees AS e
WHERE Salary > (SELECT AVG(Salary) FROM Employees AS em WHERE em.DepartmentID = e.DepartmentID)
ORDER BY DepartmentID