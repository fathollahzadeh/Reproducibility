
WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.LastAccessDate,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(CM.Score, 0)) AS CommentScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments CM ON P.Id = CM.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.LastAccessDate
), 
ActiveUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.Reputation,
        UA.CreationDate,
        UA.LastAccessDate,
        UA.PostCount,
        UA.PositivePosts,
        UA.NegativePosts,
        UA.CommentScore,
        RANK() OVER (ORDER BY UA.Reputation DESC) AS ReputationRank
    FROM 
        UserActivity UA
    WHERE 
        UA.LastAccessDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
)
SELECT 
    A.UserId,
    A.DisplayName,
    A.Reputation,
    A.PostCount,
    A.PositivePosts,
    A.NegativePosts,
    A.CommentScore,
    COALESCE(SUM(B.Id), 0) AS BadgeCount,
    CASE 
        WHEN A.Reputation > 1000 THEN 'High Reputation'
        WHEN A.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    ActiveUsers A
LEFT JOIN 
    Badges B ON A.UserId = B.UserId
WHERE 
    A.PostCount > 5
GROUP BY 
    A.UserId, A.DisplayName, A.Reputation, A.PostCount, A.PositivePosts, A.NegativePosts, A.CommentScore
HAVING 
    AVG(A.CommentScore) > 0
ORDER BY 
    A.Reputation DESC
LIMIT 10 OFFSET 0;
