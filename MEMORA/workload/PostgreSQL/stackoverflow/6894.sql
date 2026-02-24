
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 0
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        BadgeCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY Reputation DESC, TotalScore DESC) AS UserRank
    FROM 
        UserReputation
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        MAX(V.CreationDate) AS LastVoteDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days') AND
        P.ViewCount > 100
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
)
SELECT 
    U.UserRank,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    A.PostId,
    A.Title AS PostTitle,
    A.CreationDate AS PostCreationDate,
    A.ViewCount AS PostViewCount,
    A.Score AS PostScore,
    A.CommentCount AS PostCommentCount,
    A.LastVoteDate
FROM 
    TopUsers U
JOIN 
    ActivePosts A ON A.LastVoteDate IS NOT NULL
WHERE 
    U.UserId IN (
        SELECT OwnerUserId 
        FROM Posts 
        WHERE ParentId IS NULL AND PostTypeId = 1
    )
ORDER BY 
    U.UserRank, A.Score DESC
LIMIT 50;
