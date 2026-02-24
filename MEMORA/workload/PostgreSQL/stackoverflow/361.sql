WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE
        P.CreationDate >= (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
),
UserRecentPosts AS (
    SELECT 
        U.DisplayName,
        COUNT(RP.Id) AS RecentPostsCount,
        AVG(RP.Score) AS AvgPostScore
    FROM 
        UserStats U
    LEFT JOIN 
        RecentPosts RP ON U.UserId = RP.OwnerUserId
    GROUP BY 
        U.DisplayName
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    COALESCE(URP.RecentPostsCount, 0) AS RecentPostsCount,
    COALESCE(URP.AvgPostScore, 0) AS AvgPostScore,
    CASE 
        WHEN U.Reputation > 1000 THEN 'High Reputation'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    UserStats U
LEFT JOIN 
    UserRecentPosts URP ON U.DisplayName = URP.DisplayName
WHERE 
    U.TotalPosts > 0
ORDER BY 
    U.Reputation DESC, URP.RecentPostsCount DESC
LIMIT 10;