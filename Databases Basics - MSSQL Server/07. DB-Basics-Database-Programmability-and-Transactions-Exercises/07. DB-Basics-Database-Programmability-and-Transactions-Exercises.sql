USE SoftUni
GO

/*--01--*/
CREATE PROC usp_GetEmployeesSalaryAbove35000 AS
SELECT FirstName, LastName FROM Employees
WHERE Salary > 35000

EXEC usp_GetEmployeesSalaryAbove35000
GO

/*--02--*/
CREATE PROC usp_GetEmployeesSalaryAboveNumber(@Salary DECIMAL(18,4)) AS
SELECT FirstName, LastName FROM Employees
WHERE Salary >= @Salary

EXEC usp_GetEmployeesSalaryAboveNumber 48100
GO

/*--03--*/
CREATE PROC usp_GetTownsStartingWith(@StartWith VARCHAR(50)) AS
SELECT Name AS Town FROM Towns
WHERE Name LIKE @StartWith + '%'

EXEC usp_GetTownsStartingWith 'b'
GO

/*--04--*/
CREATE PROC usp_GetEmployeesFromTown(@TownName VARCHAR(50)) AS
SELECT e.FirstName, e.LastName FROM Employees AS e
JOIN Addresses AS a
ON e.AddressID = a.AddressID
JOIN Towns AS t
ON a.TownID = t.TownID
WHERE t.Name = @TownName

EXEC usp_GetEmployeesFromTown 'Sofia'
GO

/*--05--*/
CREATE FUNCTION ufn_GetSalaryLevel(@salary DECIMAL(18,4))
RETURNS VARCHAR(10) AS
BEGIN
	DECLARE @SalaryLevel VARCHAR(10)
	SET @SalaryLevel =
		CASE
			WHEN @salary < 30000 THEN 'Low'
			WHEN @salary <= 50000 THEN 'Average'
			ELSE 'High'
		END
	RETURN @SalaryLevel
END
GO

SELECT Salary, dbo.ufn_GetSalaryLevel(Salary) AS [Salary Level] FROM Employees
GO

/*--06--*/
CREATE PROC usp_EmployeesBySalaryLevel(@SalaryLevel VARCHAR(10)) AS
SELECT FirstName, LastName FROM Employees
WHERE dbo.ufn_GetSalaryLevel(Salary) = @SalaryLevel

EXEC usp_EmployeesBySalaryLevel 'High'
GO

/*--7--*/
CREATE FUNCTION ufn_IsWordComprised(@setOfLetters VARCHAR(20), @word VARCHAR(20)) 
RETURNS BIT AS
	BEGIN
		DECLARE @wordLength INT = LEN(@word)
		DECLARE @charIndex INT =1

		WHILE(@charIndex<=@wordLength)
		BEGIN
			IF(CHARINDEX(SUBSTRING(@word, @charIndex, 1), @setOfLetters)=0)
			BEGIN
				RETURN 0
			END
			SET @charIndex +=1
		END
		RETURN 1
	END
GO

SELECT dbo.ufn_IsWordComprised('oistmiahf', 'Sofia')
SELECT dbo.ufn_IsWordComprised('oistmiahf', 'halves')
SELECT dbo.ufn_IsWordComprised('bobr', 'Rob')
SELECT dbo.ufn_IsWordComprised('pppp', 'Guy')
GO

/*--8--*/
CREATE PROC usp_DeleteEmployeesFromDepartment (@departmentId INT)
AS
ALTER TABLE Departments
ALTER COLUMN ManagerID INT /*makes it nullable (not specified as 'NOT NULL')*/
 
DELETE FROM EmployeesProjects
WHERE EmployeeID IN (SELECT EmployeeID FROM Employees WHERE DepartmentID = @departmentId) /*selects records from Employees table*/
 
UPDATE Departments
SET ManagerID = NULL
WHERE DepartmentID = @departmentId
 
UPDATE Employees
SET ManagerID = NULL
WHERE ManagerID IN (SELECT EmployeeID from Employees WHERE DepartmentID = @departmentId) /*removing the manager of the selected department from other dept employee records*/
 
DELETE FROM Employees
WHERE DepartmentID = @departmentId
 
DELETE FROM Departments
WHERE DepartmentID = @departmentId
 
SELECT COUNT(*)
  FROM Employees
 WHERE DepartmentID = @departmentId

/*--9--*/
USE Bank
CREATE PROC usp_GetHoldersFullName AS
SELECT CONCAT(FirstName, ' ', LastName) AS [Full Name] 
FROM AccountHolders

EXEC usp_GetHoldersFullName
GO

/*--10--*/
CREATE PROC usp_GetHoldersWithBalanceHigherThan(@inputNumber DECIMAL(18,4)) AS
SELECT k.FirstName, k.LastName 
  FROM (
SELECT ah.FirstName, ah.LastName
  FROM AccountHolders AS ah
JOIN Accounts AS a ON a.AccountHolderId = ah.Id

GROUP BY ah.Id, ah.FirstName, ah.LastName
HAVING SUM(a.Balance) > @inputNumber) AS k
ORDER BY k.FirstName, k.LastName

EXEC usp_GetHoldersWithBalanceHigherThan 20000
GO

/*--11--*/
CREATE FUNCTION ufn_CalculateFutureValue(@Sum DECIMAL(16, 2), @Interest FLOAT, @Years INT) 
RETURNS DECIMAL(20, 4) AS
BEGIN
	DECLARE @FutureValue DECIMAL(20, 4) = @Sum * POWER(1 + @Interest, @Years)
	RETURN @FutureValue
END
GO

SELECT dbo.ufn_CalculateFutureValue(1000, 0.1, 5)
GO

/*--12--*/
CREATE PROCEDURE usp_CalculateFutureValueForAccount(@accounID INT, @interestRate FLOAT, @years INT = 5)
AS 
BEGIN
	SELECT 
		a.Id,
		ah.FirstName,
		ah.LastName, 
		a.Balance, 
		dbo.ufn_CalculateFutureValue(a.Balance, @interestRate, @years) AS [Balance in 5 years]
	FROM Accounts AS a
	JOIN AccountHolders AS ah
	ON ah.Id = a.AccountHolderId
	WHERE a.Id = @accounID
END

EXECUTE usp_CalculateFutureValueForAccount 1, 0.1, 10
GO

/*--13--*/
USE Diablo
CREATE FUNCTION ufn_CashInUsersGames(@gameName NVARCHAR(MAX))
RETURNS TABLE
AS 
RETURN (SELECT SUM(fQuerry.Cash) AS SumCash
		FROM
			(
				SELECT 
				ug.Cash AS Cash,
				ROW_NUMBER() OVER (ORDER BY ug.Cash DESC) AS [Row Number]
				FROM UsersGames AS ug
				JOIN Games AS g
				ON g.Id = ug.GameId
				WHERE g.[Name] = @gameName
			) 
			AS fQuerry
		WHERE fQuerry.[Row Number] % 2 = 1)
GO

SELECT * FROM dbo.ufn_CashInUsersGames('Love in a mist')


/*--14--*/
--USE BANK
CREATE TABLE Logs
(	
	LogId INT IDENTITY, 
	AccountID INT NOT NULL, 
	OldSum DECIMAL(16,2) NOT NULL, 
	NewSum DECIMAL(16,2) NOT NULL, 

	CONSTRAINT PK_Logs
	PRIMARY KEY (LogId), 

	CONSTRAINT FK_Logs_Accounts
	FOREIGN KEY (AccountID)
	REFERENCES Accounts(Id)
)
GO

CREATE TRIGGER tr_ChangeBalance ON Accounts AFTER UPDATE
AS 
BEGIN 
	INSERT INTO Logs
	SELECT inserted.Id, deleted.Balance, inserted.Balance
	FROM inserted
	JOIN deleted
	ON inserted.Id = deleted.Id
END	

UPDATE Accounts 
SET Balance += 555
WHERE Id = 2

/*--15--*/
CREATE TABLE NotificationEmails
(
	ID INT IDENTITY PRIMARY KEY, 
	Recipient INT FOREIGN KEY REFERENCES Accounts(ID), 
	Subject NVARCHAR(MAX) NOT NULL, 
	Body NVARCHAR(MAX) NOT NULL
)
GO

CREATE TRIGGER tr_SendEmail ON Logs AFTER INSERT
AS 
BEGIN 
	INSERT INTO NotificationEmails
	SELECT 
		inserted.AccountID,
		CONCAT('Balance change for account: ',inserted.AccountID ),
		CONCAT('On ', GETDATE(), ' your balance was changed from ', inserted.OldSum, ' to ', inserted.NewSum)
	FROM inserted
END
GO

SELECT * FROM Logs
SELECT * FROM NotificationEmails

UPDATE Accounts 
SET Balance += 500000
WHERE Id = 1
GO

/*--16--*/
CREATE PROCEDURE usp_DepositMoney(@accountID INT, @moneyAmount DECIMAL (16,4))
AS
BEGIN
	BEGIN TRANSACTION 

	UPDATE Accounts
	SET Balance += @moneyAmount
	WHERE Id = @accountID
	
	IF @moneyAmount < 0
	BEGIN
		ROLLBACK; 
		RETURN;  
	END
		COMMIT
END

EXECUTE dbo.usp_DepositMoney 1, 100000
SELECT * FROM Accounts
GO

/*--17--*/
CREATE PROCEDURE usp_WithdrawMoney (@AccountId INT, @MoneyAmount DECIMAL (16,4))
AS 
BEGIN 
	BEGIN TRANSACTION
		IF(@MoneyAmount > 0)
		BEGIN 
			UPDATE Accounts
			SET Balance -= @MoneyAmount
			WHERE ID = @AccountId
		
			IF(@@ROWCOUNT <> 1)
			BEGIN 
				RAISERROR('INVALID ACCOUNT!',16, 2)
				ROLLBACK; 
				RETURN; 
			END 
		END
	COMMIT
END

EXECUTE dBO.usp_WithdrawMoney 1, 100000
GO

/*--18--*/
CREATE OR ALTER PROCEDURE usp_TransferMoney(@SenderId INT, @ReceiverId INT, @Amount DECIMAL (16,4))
AS
BEGIN 
	BEGIN TRANSACTION 
	IF(@Amount > 0)
	BEGIN 
		EXECUTE usp_WithdrawMoney @SenderId, @Amount
		EXECUTE usp_DepositMoney @ReceiverId, @Amount
	END
	COMMIT
END 

SELECT * FROM Accounts
EXECUTE dbo.usp_TransferMoney 1, 2, 1000
GO

/*--19--*/
--BACKUP DATABASE Diablo
--TO DISK = 'D:\Downloads\diablo.bak'
CREATE TRIGGER tr_BuyItem ON UserGameItems AFTER INSERT
AS
BEGIN
	DECLARE @userLevel INT; 
	DECLARE @itemLevel INT;  

	SET @userLevel = (SELECT ug.[Level] 
	FROM inserted
	JOIN UsersGames AS ug
	ON ug.Id = inserted.UserGameId)

	SET @itemLevel = (SELECT i.MinLevel
	FROM inserted
	JOIN Items AS i
	ON i.Id = inserted.ItemId)

	IF(@userLevel < @itemLevel)
	BEGIN 
		RAISERROR('User can not buy this item!', 16, 1);
		ROLLBACK;
		RETURN;  
	END
END 

INSERT INTO UserGameItems
VALUES 
(4, 1)

UPDATE UsersGames
SET Cash += 50000
FROM UsersGames AS ug
JOIN Users AS u
ON u.Id = ug.UserId
JOIN Games AS g
ON g.Id = ug.GameId
WHERE g.Name = 'Bali' 
AND u.Username IN ('baleremuda', 'loosenoise', 'inguinalself', 'buildingdeltoid', 'monoxidecos')
GO

CREATE PROCEDURE udp_BuyItems(@username NVARCHAR(MAX))
AS 
BEGIN 
	DECLARE @counter INT = 251;
	DECLARE @userId INT = (SELECT u.Id FROM Users AS u WHERE u.Username = @username);
	
	WHILE(@counter <= 539)
	BEGIN 
		DECLARE @itemValue DECIMAL(16,2) = (SELECT i.Price FROM Items AS i WHERE i.Id = @counter);
		DECLARE @UserCash DECIMAL(16,2) = (SELECT u.Cash FROM UsersGames AS u WHERE u.UserId = @userId);

		IF(@itemValue <= @UserCash)
		BEGIN 
			INSERT INTO UserGameItems 
			VALUES 
			(@counter, @userId)

			UPDATE UsersGames
			SET Cash -= @itemValue
			WHERE UserId = @userId
		END

		SET @counter += 1; 
		IF(@counter = 300)
		BEGIN
			SET @counter = 501; 
		END
	END
END

EXECUTE udp_BuyItems 'baleremuda'
EXECUTE udp_BuyItems 'loosenoise'
EXECUTE udp_BuyItems 'inguinalself'
EXECUTE udp_BuyItems 'buildingdeltoid'
EXECUTE udp_BuyItems 'monoxidecos'
GO

/*--20--*/
DECLARE @gameId INT = (SELECT Id FROM Games AS g WHERE g.[Name] = 'Safflower'); 
DECLARE @userId INT = (SELECT u.Id FROM Users AS u WHERE u.Username = 'Stamat');	
DECLARE @userGameId INT = (SELECT ug.Id FROM UsersGames AS ug WHERE ug.GameId = @gameId AND ug.UserId = @userId);
DECLARE @userCash DECIMAL(15, 2) = (SELECT ug.Cash FROM UsersGames AS ug WHERE ug.Id = @userGameId);  
DECLARE @itemsPricesSummed DECIMAL(15, 2) = (SELECT SUM(i.Price) FROM Items AS i WHERE i.MinLevel BETWEEN 11 AND 12); 

IF(@userCash >= @itemsPricesSummed)
BEGIN
	BEGIN TRANSACTION
		INSERT UserGameItems
		SELECT i.Id, @UserGameId
		FROM Items AS i
		WHERE i.MinLevel BETWEEN 11 AND 12

		UPDATE UsersGames 
		SET Cash -= @itemsPricesSummed
		WHERE Id = @UserGameId 
	COMMIT
END

SET @itemsPricesSummed = (SELECT SUM(i.Price) FROM Items AS i WHERE i.MinLevel BETWEEN 19 AND 21); 
SET @UserCash = (SELECT ug.Cash FROM UsersGames AS ug WHERE ug.Id = @UserGameId);  

IF(@UserCash >= @itemsPricesSummed)
BEGIN 	
	BEGIN TRANSACTION
		INSERT UserGameItems
		SELECT i.Id, @UserGameId
		FROM Items AS i
		WHERE i.MinLevel BETWEEN 19 AND 21

		UPDATE UsersGames 
		SET Cash -= @itemsPricesSummed
		WHERE Id = @UserGameId 
	COMMIT TRANSACTION 
END

SELECT i.[Name] 
FROM UsersGames AS ug
JOIN Users AS u
ON u.Id = ug.UserId
JOIN Games AS g
ON g.Id = ug.GameId
JOIN UserGameItems AS ugi
ON ugi.UserGameId = ug.Id
JOIN Items AS i
ON i.Id = ugi.ItemId
WHERE (u.Username = 'Stamat' 
AND g.[Name] = 'Safflower')
ORDER BY i.[Name]

GO

/*--21--*/
--USE SoftUnI
CREATE PROCEDURE usp_AssignProject(@emloyeeId INT, @projectID INT)
AS
BEGIN 
	DECLARE @maxProjectsAllowed INT = 3; 
	DECLARE @currentProjects INT;

	SET @currentProjects = 
	(SELECT COUNT(*) 
	FROM Employees AS e
	JOIN EmployeesProjects AS ep
	ON ep.EmployeeID = e.EmployeeID
	WHERE ep.EmployeeID = @emloyeeId)

BEGIN TRANSACTION 	
	IF(@currentProjects >= @maxProjectsAllowed)
	BEGIN 
		RAISERROR('The employee has too many projects!', 16, 1);
		ROLLBACK;
		RETURN;
	END

	INSERT INTO EmployeesProjects
	VALUES
	(@emloyeeId, @projectID)

COMMIT	
END 

/*--22-- */
CREATE TABLE Deleted_Employees
(
	EmployeeId INT NOT NULL IDENTITY, 
	FirstName NVARCHAR(64) NOT NULL, 
	LastName NVARCHAR(64) NOT NULL, 
	MiddleName NVARCHAR(64), 
	JobTitle NVARCHAR(64) NOT NULL, 
	DepartmentID INT NOT NULL, 
	Salary DECIMAL(15, 2) NOT NULL

	CONSTRAINT PK_Deleted_Emp
	PRIMARY KEY (EmployeeId), 

	CONSTRAINT FK_DeletedEmp_Departments
	FOREIGN KEY (DepartmentID)
	REFERENCES Departments(DepartmentID)
)
GO

CREATE TRIGGER tr_DeletedEmp 
ON Employees 
AFTER DELETE 
AS
	INSERT INTO Deleted_Employees
	SELECT 	
		d.FirstName, 
		d.LastName, 
		d.MiddleName, 
		d.JobTitle, 
		d.DepartmentID, 
		d.Salary
	FROM deleted as d
