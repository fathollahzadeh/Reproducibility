WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate, LastAccessDate, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank,
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS DenseRank
    FROM Users
    WHERE Reputation > 1000
),
ActivePosts AS (
    SELECT P.Id AS PostId, P.OwnerUserId, P.ViewCount, P.CreationDate, P.LastActivityDate,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id, P.OwnerUserId, P.ViewCount, P.CreationDate, P.LastActivityDate
),
TopUsers AS (
    SELECT U.Id, U.DisplayName, U.Reputation, UR.Rank
    FROM Users U
    JOIN UserReputation UR ON U.Id = UR.Id
    WHERE UR.Rank <= 10
),
PostStatistics AS (
    SELECT AP.OwnerUserId, COUNT(AP.PostId) AS TotalPosts, 
           SUM(AP.ViewCount) AS TotalViews, 
           SUM(AP.UpVotes) AS TotalUpVotes, 
           SUM(AP.DownVotes) AS TotalDownVotes
    FROM ActivePosts AP
    GROUP BY AP.OwnerUserId
)
SELECT TU.DisplayName, TU.Reputation, PS.TotalPosts, PS.TotalViews, PS.TotalUpVotes, PS.TotalDownVotes
FROM TopUsers TU
LEFT JOIN PostStatistics PS ON TU.Id = PS.OwnerUserId
ORDER BY TU.Reputation DESC, PS.TotalViews DESC;