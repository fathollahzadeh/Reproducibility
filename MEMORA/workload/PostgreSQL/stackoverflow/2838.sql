
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount,
        AVG(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - U.CreationDate) / 86400) ) AS DaysSinceCreation
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        Upvotes, 
        Downvotes, 
        PostsCount, 
        CommentsCount, 
        DaysSinceCreation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserActivity
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.Upvotes,
    U.Downvotes,
    U.PostsCount,
    U.CommentsCount,
    CASE 
        WHEN U.DaysSinceCreation < 30 THEN 'New User' 
        WHEN U.DaysSinceCreation BETWEEN 30 AND 365 THEN 'Active User' 
        ELSE 'Veteran User' 
    END AS UserCategory,
    CASE 
        WHEN U.Reputation >= 1000 THEN 'Gold User'
        WHEN U.Reputation BETWEEN 500 AND 999 THEN 'Silver User'
        ELSE 'Bronze User'
    END AS BadgeCategory
FROM
    TopUsers U
WHERE
    U.ReputationRank <= 10
ORDER BY 
    U.Reputation DESC;
