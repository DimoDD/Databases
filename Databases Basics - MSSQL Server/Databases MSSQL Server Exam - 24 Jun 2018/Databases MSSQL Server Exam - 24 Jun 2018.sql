
CREATE TABLE Cities
(
	Id INT PRIMARY KEY IDENTITY,
	Name NVARCHAR(20) NOT NULL,
	CountryCode CHAR(2) NOT NULL
)
CREATE TABLE Hotels
(
	Id INT PRIMARY KEY IDENTITY,
	Name NVARCHAR(30) NOT NULL,
	CityId INT FOREIGN KEY REFERENCES Cities(Id) NOT NULL,
	EmployeeCount INT NOT NULL,
	BaseRate DECIMAL(15,2) 
)

CREATE TABLE Rooms
(
	Id INT PRIMARY KEY IDENTITY,
	Price DECIMAL(15,2), 
	[Type] NVARCHAR(20) NOT NULL,
	Beds INT NOT NULL,
	HotelId INT FOREIGN KEY REFERENCES Hotels(Id) NOT NULL
)

CREATE TABLE Trips
(
	Id INT PRIMARY KEY IDENTITY,
	RoomId INT FOREIGN KEY REFERENCES Rooms(Id) NOT NULL,
	BookDate DATE NOT NULL,
	ArrivalDate DATE NOT NULL,
	ReturnDate DATE NOT NULL,
	CancelDate DATE,
	CONSTRAINT CH_BookDate CHECK(BookDate < ArrivalDate),
	CONSTRAINT CH_ArrivalDate CHECK(ArrivalDate < ReturnDate)
)

CREATE TABLE Accounts
(
	Id INT PRIMARY KEY IDENTITY,
	FirstName NVARCHAR(50) NOT NULL,
	MiddleName NVARCHAR(50),
	LastName  NVARCHAR(50) NOT NULL,
	CityId INT FOREIGN KEY REFERENCES Cities(Id) NOT NULL,
	BirthDate DATE NOT NULL,
	Email NVARCHAR(100) NOT NULL UNIQUE
)

CREATE TABLE AccountsTrips
(
	AccountId INT FOREIGN KEY REFERENCES Accounts(Id) NOT NULL,
	TripId INT FOREIGN KEY REFERENCES Trips(Id) NOT NULL,
	Luggage INT NOT NULL CHECK(Luggage >=0),
	PRIMARY KEY (AccountId, TripId)
)

/*--2--*/
INSERT INTO Accounts VALUES
('John',	'Smith',	'Smith',	34,	'1975-07-21',	'j_smith@gmail.com'),
('Gosho',	NULL,	'Petrov',	11,	'1978-05-16',	'g_petrov@gmail.com'),
('Ivan',	'Petrovich',	'Pavlov',	59,	'1849-09-26',	'i_pavlov@softuni.bg'),
('Friedrich','Wilhelm','Nietzsche',	2,	'1844-10-15',	'f_nietzsche@softuni.bg')

INSERT INTO Trips VALUES
(101,	'2015-04-12',	'2015-04-14',	'2015-04-20',	'2015-02-02' ),
(102,	'2015-07-07',	'2015-07-15',	'2015-07-22',	'2015-04-29' ),
(103,	'2013-07-17',	'2013-07-23',	'2013-07-24',	NULL		 ),
(104,	'2012-03-17',	'2012-03-31',	'2012-04-01',	'2012-01-10' ),
(109,	'2017-08-07',	'2017-08-28',	'2017-08-29',	NULL		 )
	
/*--3--*/
UPDATE Rooms
SET Price *= 1.14
WHERE HotelId IN(5,7,9)			

/*--4--*/
DELETE FROM AccountsTrips	
WHERE AccountId = 47 

/*--5--*/
SELECT Id, Name 
FROM Cities
WHERE CountryCode = 'BG'
ORDER BY Name

/*--6--*/
SELECT FirstName + ' ' + ISNULL(MiddleName+ ' ', '') + LastName, DATEPART(YEAR, BirthDate) as BirthYear
FROM Accounts
WHERE DATEPART(YEAR, BirthDate)>1991
ORDER BY BirthYear DESC, FirstName

/*--7--*/
SELECT FirstName, LastName, FORMAT(BirthDate, 'MM-dd-yyyy') AS BirthDate, c.Name AS Hometown, a.Email
FROM Accounts AS a
JOIN Cities AS c ON c.Id = a.CityId
WHERE Email LIKE 'e%'
ORDER BY c.Name DESC

/*--8--*/
SELECT c.Name, COUNT(h.Id) AS HotelCount
FROM Cities AS c
LEFT JOIN Hotels AS h
ON h.CityId = c.Id
GROUP BY c.Name
ORDER BY HotelCount DESC, c.Name

/*--9--*/
SELECT r.Id, r.Price, h.Name, c.Name 
FROM Rooms AS r
JOIN Hotels AS h
ON h.Id = r.HotelId
JOIN Cities AS c 
ON c.Id = h.CityId
WHERE r.Type= 'First Class'
ORDER BY r.Price DESC, r.Id

/*--10--*/
SELECT a.Id, a.FirstName + ' ' + a.LastName AS FullName,
MAX(DATEDIFF(DAY, t.ArrivalDate, t.ReturnDate)) AS LongestTrip,
MIN(DATEDIFF(DAY, t.ArrivalDate, t.ReturnDate)) AS ShortestTrip
FROM Accounts AS a
JOIN AccountsTrips AS at ON at.AccountId = a.Id
JOIN Trips AS t ON  t.Id = at.TripId
WHERE a.MiddleName IS NULL AND t.CancelDate IS NULL
GROUP BY a.Id, a.FirstName + ' ' + a.LastName
ORDER BY LongestTrip DESC, a.Id

/*--11--*/
SELECT TOP(5) c.Id, c.Name, c.CountryCode, COUNT(a.Id) AS Accounts 
FROM Cities AS c
JOIN Accounts AS a ON a.CityId = c.Id
GROUP BY c.Id, c.Name, c.CountryCode
ORDER BY Accounts DESC

/*--12--*/
SELECT a.Id, a.Email, c.Name , COUNT(t.Id) AS TripsCount
FROM Accounts AS a
JOIN AccountsTrips AS at ON at.AccountId = a.Id
JOIN Trips AS t ON t.Id = at.TripId
JOIN Rooms AS r ON r.Id = t.RoomId
JOIN Hotels AS h ON h.Id = r.HotelId
JOIN Cities AS c ON c.Id = h.CityId
WHERE a.CityId = h.CityId
GROUP BY a.Id, a.Email, c.Name
ORDER BY TripsCount DESC, a.Id

/*--13--*/
SELECT TOP(10) c.Id, c.Name, SUM(h.BaseRate+r.Price) AS [Total Revenue], COUNT(t.Id) AS [Trips]
FROM Cities AS c
JOIN Hotels AS h ON h.CityId = c.Id
JOIN Rooms AS r ON r.HotelId = h.Id
JOIN Trips AS t ON t.RoomId = r.Id
WHERE DATEPART(YEAR, t.BookDate) = 2016
GROUP BY c.Id, c.Name
ORDER BY [Total Revenue] DESC, Trips DESC

/*--14--*/
SELECT t.Id, h.Name, r.Type,
CASE
  WHEN t.CancelDate IS NULL THEN SUM(h.BaseRate + r.Price)
  ELSE 0.00
  END AS Revenue
FROM Trips AS t
JOIN AccountsTrips AS at ON t.Id = at.TripId
JOIN Rooms AS r ON r.Id = t.RoomId
JOIN Hotels AS h ON r.HotelId = h.Id

GROUP BY t.Id, h.Name, r.Type, t.CancelDate
ORDER BY r.Type, t.Id

/*--15--*/
SELECT Temp.Id, Temp.Email, Temp.CountryCode, Temp.Trips
FROM (SELECT a.Id, a.Email, c.CountryCode, COUNT(t.Id) AS Trips, 
DENSE_RANK() OVER (PARTITION BY c.CountryCode ORDER BY COUNT(t.Id) DESC, a.Id) AS TripsRank

FROM Accounts AS a 
JOIN AccountsTrips AS at ON at.AccountId = a.Id
JOIN Trips AS t ON t.Id = at.TripId
JOIN Rooms AS r ON r.Id = t.RoomId
JOIN Hotels AS h ON h.Id = r.HotelId
JOIN Cities AS c ON c.Id = h.CityId
GROUP BY  a.Id, a.Email, c.CountryCode) AS Temp
WHERE Temp.TripsRank = 1
ORDER BY Temp.Trips DESC, Temp.Id

/*--16--*/
SELECT TripId, SUM(Luggage),
CASE 
WHEN SUM(Luggage) > 5 THEN CONCAT('$', SUM(Luggage)*5)
ELSE '$0'
END AS Fee
FROM AccountsTrips
GROUP BY TripId
HAVING SUM(Luggage)>0
ORDER BY SUM(Luggage) DESC

/*--17--*/


/*--18--*/
/*--19--*/
/*--20--*/


