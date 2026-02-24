
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 4 THEN 1 ELSE 0 END), 0) AS OffensiveVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 10 THEN 1 ELSE 0 END), 0) AS PostDeletions
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.OwnerUserId,
        P.Title,
        P.ViewCount,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS Rank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 DAY'
)

SELECT 
    U.DisplayName,
    US.Upvotes,
    US.Downvotes,
    US.PostDeletions,
    SP.Title AS RecentPostTitle,
    SP.ViewCount,
    SP.Score
FROM 
    UserStats US
LEFT JOIN 
    RecentPosts SP ON US.UserId = SP.OwnerUserId AND SP.Rank = 1
JOIN 
    Users U ON US.UserId = U.Id
WHERE 
    US.Upvotes > US.Downvotes
    AND US.PostDeletions = 0
ORDER BY 
    US.Upvotes DESC, 
    U.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
