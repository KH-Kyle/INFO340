USE BOOK_CLUB 
GO

/*
1)the total amount of dollars 
	collected from fee type ‘First-Print Signed Book’ 
	for all events of the type ‘Personal Appearance by Author’ 
	held at Downtown Seattle Library 
	since July 5, 2014
*/
SELECT SUM(F.FeeAmount) AS TotalAmount
FROM tblFEE F
	JOIN tblEVENT_FEE EF  ON F.FeeID = EF.FeeID
	JOIN tblEVENT E		  ON EF.EventID = E.EventID
	JOIN tblEVENT_TYPE ET ON E.EventTypeID = ET.EventTypeID
	JOIN tblLOCATION L	  ON E.LocationID = L.LocationID
WHERE F.FeeName = 'First-Print Signed Book'
AND	  ET.EventTypeName = 'Personal Appearance by Author'
AND   L.LocationName = 'Downtown Seattle Library'
AND   E.EventDate >= '07/05/2014'
GO

/*
2)the list of female authors 
	from the region of South America who 
	wrote a romance novel 
	before May 15, 1983
*/
SELECT *
FROM tblAUTHOR A
	JOIN tblGENDER G  ON A.GenderID = G.GenderID
	JOIN tblCOUNTRY C ON A.CountryID = C.CountryID
	JOIN tblREGION R  ON C.RegionID = R.RegionID
	JOIN tblBOOK B    ON A.AuthorID = B.AuthorID
	JOIN tblGENRE GR  ON B.GenreID = GR.GenreID
WHERE G.GenderName = 'Female'
AND   R.RegionName = 'South America'
AND   GR.GenreName = 'Romance Novel'
AND   B.DatePublished < '05/15/1983'
GO

/*
3)top 5 publishers 
	released the most non-fiction biographies 
	written by non-European authors 
	between 1942 and 2005
*/
SELECT TOP 5 with ties P.PublisherID, COUNT(B.BookID) AS ReleasedAmount
FROM tblPUBLISHER P
	JOIN tblBOOK B   ON P.PublisherID = B.PublisherID
	JOIN tblGENRE G  ON B.GenreID = G.GenreID
	JOIN tblAUTHOR A ON B.AuthorID = A.AuthorID
	JOIN tblCOUNTRY C ON A.CountryID = C.CountryID
	JOIN tblREGION R  ON C.RegionID = R.RegionID
WHERE G.GenreName = 'Non-fiction Biography'
AND	  R.RegionName <> 'European'
AND   B.DatePublished BETWEEN '01/01/1942' AND '12/31/2005'
GROUP BY P.PublisherID
ORDER BY COUNT(B.BookID) DESC

/*
4)genres of books 
	have been assigned at least 24 times 
	in the past 5 years
*/
SELECT G.GenreID, COUNT(b.GenreID) AS AssignedAmount
FROM tblGENRE G
	JOIN tblBOOK B ON G.GenreID = B.GenreID
WHERE B.DatePublished > (SELECT GetDate() - 5 * 365.25)
GROUP BY G.GenreID
HAVING COUNT(B.BookID) > 23

/*
5)5 members 
	have registered for the most events of the type ‘Standard Book Club Meeting’ 
	in the role as ‘Host’ 
	in the past 3 years
*/
SELECT TOP 5 with ties M.MemberID, COUNT(R.MemberID) AS Times
FROM tblMEMBER M
	JOIN tblREGISTRATION R ON M.MemberID = R.MemberID
	JOIN tblROLE RO		   ON R.RoleID = RO.RoleID
	JOIN tblEVENT E		   ON R.EventID = E.EventID
	JOIN tblEVENT_TYPE ET  ON E.EventTypeID = ET.EventTypeID
WHERE RO.RoleName = 'Host'
AND  E.EventDate > (SELECT GetDate() - 3 * 365.25)
AND   ET.EventTypeName = 'Standard Book Club Meeting'
GROUP BY M.MemberID
ORDER BY COUNT(E.EventID) DESC

/*
6)the youngest to ever be 
	an ‘organizer’ of 
	an event of type ‘Annual Holiday Celebration’ 
	held at a ‘Retirement Community’ where 
	there was no reading assignment
*/
SELECT TOP 1 *
FROM tblMEMBER M
	JOIN tblREGISTRATION R	 ON M.MemberID = R.MemberID
	JOIN tblROLE RO			 ON R.RoleID = RO.RoleID
	JOIN tblEVENT E			 ON R.EventID = E.EventID
	JOIN tblEVENT_TYPE ET	 ON E.EventTypeID = ET.EventTypeID
	JOIN tblLOCATION L		 ON E.LocationID = L.LocationID
	JOIN tblLOCATION_TYPE LT ON L.LocationTypeID = LT.LocationTypeID
WHERE RO.RoleName = 'Organizer'
AND	  ET.EventTypeName = 'Annual Holiday Celebration'
AND   LT.LocationTypeName = 'Retirement Community'
AND   E.AssignmentID IS NULL
ORDER BY M.BirthDate DESC

/*
7)a stored procedure to populate the EVENT table.
*/
CREATE PROCEDURE uspEventProcessing
@EventName varchar(30),
--EventTypeID
@EventTypeName varchar(30),
--LoctionID
@LocaName varchar(30),
--AssignmentID
@AnnoDate Date,
@Due Date,
	--BookID
	@AssignBookName varchar(30),
    @AssignBookPublised Date,
@EventDate Date,
AS

DECLARE @EventTypeID INT
DECLARE @LoctionID INT
DECLARE @BookID INT
DECLARE @AssignmentID INT

SET @EventTypeID = (SELECT @EventTypeID FROM tblEVENT_TYPE 
										WHERE EventTypeName = @EventTypeName)
SET @LoctionID = (SELECT @LoctionID FROM tblLOCATION 
									WHERE LocationName = @LocaName)
SET @BookID = (SELECT @BookID FROM tblBOOK 
							  WHERE BookTitle = @AssignBookName
							  AND   DatePublished = @AssignBookPublised)
SET @AssignmentID = (SELECT @AssignmentID FROM tblASSIGNMENT
										  WHERE BookID = @BookID
										  AND AnnounceDate = @AnnoDate
										  ANd DueDate = @Due)

-- THIS IS WHERE WILL DO ERROR-HANDLING
IF @EventTypeID IS NULL
	BEGIN
	PRINT 'cannot find Event Type'
	RAISERROR ('@EventTypeID cannot be null; please check spelling', 11,1)
	RETURN
	END
IF @LoctionID IS NULL
	BEGIN
	PRINT 'cannot find Location'
	RAISERROR ('@LoctionID cannot be null; please check spelling', 11,1)
	RETURN
	END
IF @AssignmentID IS NULL
	BEGIN
	PRINT 'cannot find Assignment'
	RAISERROR ('@AssignmentID cannot be null; please check spelling', 11,1)
	RETURN
	END

/*
8)no member under 21 years of age may host an event type ‘Annual Holiday Celebration’ in a restaurant
*/
CREATE FUNCTION fn_no21CelebrationinRestaurant()
RETURNS INT 
AS
BEGIN
	DECLARE @Ret INT = 0
	IF EXISTS (SELECT *
				FROM tblMEMBER M
				JOIN tblREGISTRATION R	 ON M.MemberID = R.MemberID
				JOIN tblROLE RO			 ON R.RoleID = RO.RoleID
				JOIN tblEVENT E			 ON R.EventID = E.EventID
				JOIN tblEVENT_TYPE ET	 ON E.EventTypeID = ET.EventTypeID
				JOIN tblLOCATION L		 ON E.LocationID = L.LocationID
				JOIN tblLOCATION_TYPE LT ON L.LocationTypeID = LT.LocationTypeID
				WHERE M.birthDate > (SELECT getDate() - 365.25 * 21)
				AND	  RO.RoleName = 'Host'
				AND   ET.EventTypeName = 'Annual Holiday Celebration'
				AND   LT.LocationTypeName = 'Restaurant'
	)
	SET @Ret = 1
	RETURN @Ret

END

ALTER TABLE tblREGISTRATION
ADD CONSTRAINT CK_no21CelebrationinRestaurant()
CHECK (dbo.fn_no21CelebrationinRestaurant()= 0)

/*
Extra Credit: 
Which 4 books 
have been selected as an assignment 
the most frequently 
between June and September months 
since 1997?
*/
SELECT TOP 4 B.BookID, COUNT(A.BookID) AS NumofTimes
FROM tblBOOK B
	JOIN tblASSIGNMENT A ON B.BookID = A.BookID
WHERE (SELECT DatePart(YEAR, A.AnnounceDate )) >= 1997
AND	  (SELECT DatePart(Month, A.AnnounceDate)) BETWEEN 6 AND 9
GROUP BY B.BookID
ORDER BY COUNT(A.BookID) DESC
