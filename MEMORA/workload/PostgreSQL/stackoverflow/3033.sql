WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounties,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
HighRepUsers AS (
    SELECT UserId, DisplayName, Reputation
    FROM UserStats
    WHERE Reputation > 1000
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY P.Id, P.Title, P.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.Id,
        RP.Title,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.VoteCount,
        ROW_NUMBER() OVER (ORDER BY RP.VoteCount DESC, RP.CreationDate DESC) AS PostRank
    FROM RecentPosts RP
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    T.Title AS TopPostTitle,
    T.CreationDate AS TopPostDate,
    T.VoteCount AS TopPostVoteCount
FROM HighRepUsers U
LEFT JOIN TopPosts T ON T.OwnerDisplayName = U.DisplayName
WHERE T.PostRank <= 10
ORDER BY U.Reputation DESC, T.VoteCount DESC;