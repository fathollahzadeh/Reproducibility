
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounties
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        CommentCount,
        TotalBounties,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStatistics
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
)
SELECT 
    TU.DisplayName AS TopUser,
    TU.Reputation,
    COALESCE(RP.Title, 'No recent posts') AS RecentPostTitle,
    COALESCE(RP.CreationDate::text, 'N/A') AS RecentPostDate,
    TU.PostCount,
    TU.CommentCount,
    TU.TotalBounties
FROM 
    TopUsers TU
LEFT JOIN 
    RecentPosts RP ON TU.UserId = RP.OwnerUserId AND RP.RecentPostRank = 1
WHERE 
    TU.ReputationRank <= 10
ORDER BY 
    TU.Reputation DESC;
