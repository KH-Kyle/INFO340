SELECT SUM(F.FeeAmount)
FROM tblFEE F
	JOIN tblEVENT_FEE EF ON F.FeeID = EF.FeeID
	JOIN tblEVENT E ON EF.EventID = E.EventID
	JOIN tblEVENT_TYPE ET ON ET.EventTypeID = E.EventTypeID
	JOIN tblLOCATION L ON L.LocationID = E.LocationID
WHERE ET.EventTypeName = 'Personal Appearance by Author'
AND L.LocationName = 'Downtown Seattle Library'
AND E.EventDate > '7/4/2014'
AND F.FeeName = 'First-Print Signed Book'
-- Q2

SELECT *
FROM tblAUTHOR A
	JOIN tblGENDER G ON G.GenderID = A.GenderID
	JOIN tblCOUNTRY C ON C.CountryID = A.CountryID
	JOIN tblREGION R ON R.RegionID = C.RegionID
	JOIN tblBOOK B ON B.AuthorID = A.AuthorID
	JOIN tblGENRE GE ON GE.GenrelID = B.GenrelID 
WHERE G.GenderName = 'female'
AND R.RegionName = 'South America'
AND GE.GenrelName = 'romance novel'
AND B.DatePublished < '5/15/1983'

--Q3

SELECT TOP 5
FROM tblPUBLISHER P 
	JOIN tblBOOK B ON P.PublisherID = B.PublisherID
	JOIN tblGENRE G ON G.GenrelID = B.GenrelID 
	JOIN tblAUTHOR A ON A.AuthorID = B.AuthorID
	JOIN tblCOUNTRY C ON C.COuntryID = A.CountryID
WHERE G.GenrelName = 'non-fiction biographies'
AND C.CountryName != 'European'
AND B.[YEAR] BETWEEN 1942 AND 2005

--Q4

SELECT G.GenrelID
FROM tblGENRE G 
	JOIN tblBOOK B ON B.GenrelID = G.GenrelID
WHERE B.DatePublished > (GETDATE()-365.25*5)
GROUP BY G.GenrelID 
WHERE COUNT(BookID) > 23

--Q5

SELECT M.MemberID 
FROM tblMEMBER M
	JOIN tblREGISTRATION R ON R.MemberID = M.MemberID
	JOIN tblROLE RO ON R.RoleID = RO.RoleID
	JOIN tblEVENT E ON E.EventID = R.EventID 
	JOIN tblEVENT_TYPE ET ON E.EventTypeID = ET.EventTypeID
WHERE ET.EventTypeName = 'Standard Book Club'
AND RO.RoleName = 'Host'
AND E.EvemtDate > GETDATE - 3*365.25
GROUP BY M.MemberID
ORDER BY COUNT(E.EventID) DESC

--Q6

SELECT *
FROM tblEVENT E 
	JOIN tblEVENT_TYPE ET ON ET.EventTypeID = E.EventTypeID 
	JOIN tblLOCATION L ON E.LocationID = L.LocationID
	JOIN tblASSIGNMENT A ON E.AssignmentID = A.AssignmentID 
	JOIN tblREGISTRATION R ON R.EventID = E.EventID 
	JOIN tblROLE RO ON RO.RoleID = R.RoleId 
	JOIN tblMEMBER M ON R.MemberID = M.MemberID 
WHERE RO.RoleName = 'organizer'
AND E.EventTypeName = 'Annual Holiday Celebration'
AND L.LocationName = 'Retirement Community'
AND E.AssignmentID IS NULL
ORDER BY M.BirthDate ASC

--Q7
CREATE PROCEDURE uspProcessEvent
@p_EventName varchar(50),
@p_EventTypeName varchar(30),
@p_LocationName varchar(30),
@p_AssignmentBookName varchar(30),
@p_AssignmentBookPublised DATE,
@p_AssignmentAnnounceDate DATE,
@p_AssignmentDueDate Date,
@p_EventDate Date
AS 

DECLARE @v_EventTypeID INT
DECLARE @v_LocationID INT
DECLARE @v_AssignmentID INT
DECLARE @v_TotalFeeAmount INT
DECLARE @v_BookID INT

SET @v_EventTypeID = (SELECT EventTypeID FROM tblEVENT_TYPE ET 
						WHERE ET.EventTypeName = @p_EventTypeName)
SET @v_LocationID = (SELECT LocationID FROM tblLOCATION L
						WHERE L.LocationName = @p_LocationName)
SET @v_BookID = (SELECT BookID FROM tblBOOK B 
					WHERE B.BookTitle = @p_AssignmentBookName
					AND B.DatePublished = @p_AssignmentBookPublised)
Set @v_AssignmentID = (SELECT AssignmentID FROM tblASSIGNMENT A
						WHERE A.BookID = @v_BookID 
						AND A.AnnounceDate = @p_AssignmentAnnounceDate
						AND A.DueDate = @p_AssignmentDueDate)
SET @v_TotalFeeAmount = (SELECT SUM(F.FeeAmount) FROM tblFEE F
						JOIN tblEVENT_FEE EF ON F.FeeID = EF.FeeID
						JOIN tblEVENT E ON E.EventID = EF.EventID
						WHERE E.EventName = @p_EventName)

--Q8

GO
CREATE FUNCTION fnundanres()
RETURNS INT
AS 
BEGIN
	DECLARE @Ret INT = 0
	IF EXISTS(SELECT * FROM tblMEMBER M 
				JOIN tblREGISTRATION R ON M.MemberID = R.MemberID
				JOIN tblROLE RO ON RO.RoleID = R.RoleID 
				JOIN tblEVENT E ON E.EventID = R.EventID
				JOIN tblLOCATION L ON E.LocationID = L.LocationID
				WHERE L.LocationName = 'Restaurant'
				AND M.BirthDate > GetDate() - 21*365.25
				AND E.EventTypeName = 'Annual Holiday Celebration'
				AND RO.RoleName = 'host')
	SET @Ret = 1
	RETURN @Ret 
END
GO

GO
ALTER TABLE tblEVENT 
ADD CONSTRAINT CK_undanres
CHECK (dbo.fnundanres() = 0)
GO

SELECT TOP 4 *
FROM tblASSIGNMENT A 
	JOIN tblBOOK B ON A.BookID = B.BookID
WHERE A.AnnounceDate > 6.1
