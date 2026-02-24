WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, CreationDate, 0 AS Level
    FROM Users
    WHERE Reputation > 100
    
    UNION ALL
    
    SELECT U.Id, U.Reputation, U.CreationDate, UR.Level + 1
    FROM Users U
    INNER JOIN UserReputation UR ON U.Id = UR.Id
    WHERE U.Reputation > 200
),
PostCounts AS (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts
    FROM Posts
    GROUP BY OwnerUserId
),
TopPosters AS (
    SELECT U.Id, U.DisplayName, COALESCE(PC.TotalPosts, 0) AS PostCount
    FROM Users U
    LEFT JOIN PostCounts PC ON U.Id = PC.OwnerUserId
    WHERE U.Reputation > 100
    ORDER BY PostCount DESC
    LIMIT 10
),
RecentActivity AS (
    SELECT U.DisplayName, 
           COUNT(CASE WHEN P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 END) AS RecentPosts,
           COUNT(CASE WHEN C.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 END) AS RecentComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.DisplayName
),
VotingSummary AS (
    SELECT UserId, 
           SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY UserId
)

SELECT U.Id AS UserId,
       U.DisplayName,
       U.Reputation,
       RA.RecentPosts,
       RA.RecentComments,
       COALESCE(VS.UpVotes, 0) AS TotalUpVotes,
       COALESCE(VS.DownVotes, 0) AS TotalDownVotes,
       COALESCE(TP.PostCount, 0) AS TotalPosts,
       U.CreationDate
FROM Users U
LEFT JOIN RecentActivity RA ON U.DisplayName = RA.DisplayName
LEFT JOIN VotingSummary VS ON U.Id = VS.UserId
LEFT JOIN TopPosters TP ON U.Id = TP.Id
WHERE U.Reputation IS NOT NULL
AND (RA.RecentPosts > 0 OR RA.RecentComments > 0)
ORDER BY U.Reputation DESC
LIMIT 50;