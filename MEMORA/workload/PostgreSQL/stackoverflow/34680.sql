WITH RecursiveTagCounts AS (
    SELECT Tags.TagName, COUNT(Posts.Id) AS PostCount
    FROM Tags
    LEFT JOIN Posts ON Tags.Id = Posts.Id
    GROUP BY Tags.TagName
),
UserReputation AS (
    SELECT U.Id AS UserId, U.DisplayName, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostHistoryDetails AS (
    SELECT PH.PostId, PH.UserId, PH.CreationDate, P.Title, 
           P.AcceptedAnswerId, PH.Comment, 
           ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RevisionNumber
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (10, 11, 12)  
),
MostActiveUsers AS (
    SELECT U.DisplayName, COUNT(P.Id) AS TotalPosts
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.DisplayName
    HAVING COUNT(P.Id) > 10
),
LastVotePerPost AS (
    SELECT V.PostId, V.UserId, V.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY V.PostId ORDER BY V.CreationDate DESC) AS rn
    FROM Votes V
)
SELECT 
    U.DisplayName AS UserName,
    COUNT(DISTINCT P.Id) AS TotalPosts,
    SUM(DISTINCT PH.RevisionNumber) AS TotalRevisions,
    COALESCE(RTC.PostCount, 0) AS TotalPostsWithTags,
    R.UPVotes, 
    R.DownVotes,
    MAX(LV.CreationDate) AS LastVoteDate
FROM Users U
LEFT JOIN Posts P ON U.Id = P.OwnerUserId
LEFT JOIN PostHistoryDetails PH ON P.Id = PH.PostId
LEFT JOIN RecursiveTagCounts RTC ON RTC.TagName = SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2) 
LEFT JOIN UserReputation R ON U.Id = R.UserId
LEFT JOIN LastVotePerPost LV ON P.Id = LV.PostId AND LV.rn = 1
WHERE U.Reputation > 1000
GROUP BY U.DisplayName, R.UPVotes, R.DownVotes, RTC.PostCount
HAVING COUNT(DISTINCT P.Id) > 5
ORDER BY TotalPosts DESC, UserName ASC;