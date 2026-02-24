
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId
),
ReputationCounts AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        AVG(P.Score) AS AvgPostScore,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
)
SELECT 
    P.Title,
    U.DisplayName AS OwnerName,
    U.Reputation,
    UVS.UpVotes,
    UVS.DownVotes,
    P.ViewCount,
    P.CommentCount,
    P.BadgeCount,
    RC.ReputationRank,
    P.CreationDate,
    CASE 
        WHEN P.Score > 100 THEN 'High Score'
        WHEN P.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM PostDetails P
JOIN UserVoteSummary UVS ON P.OwnerUserId = UVS.UserId
JOIN Users U ON P.OwnerUserId = U.Id
JOIN ReputationCounts RC ON U.Id = RC.UserId
WHERE U.Reputation > 100
  AND P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '7 days')
ORDER BY RC.ReputationRank, P.CreationDate DESC
LIMIT 50;
