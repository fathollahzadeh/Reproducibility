WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId AND V.VoteTypeId = 8 
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        COUNT(C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        RANK() OVER (ORDER BY P.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY P.Score DESC) AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.Score
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    UR.TotalBounty,
    UR.TotalPosts,
    UR.TotalComments,
    PA.Title AS PostTitle,
    PA.ViewCount,
    PA.Score,
    PA.TotalComments AS PostComments,
    PA.Upvotes,
    PA.Downvotes,
    PA.ViewRank,
    PA.ScoreRank,
    PH.CreationDate AS LastEditDate
FROM 
    UserReputation UR
JOIN 
    Posts P ON UR.UserId = P.OwnerUserId
JOIN 
    PostAnalytics PA ON P.Id = PA.PostId
LEFT JOIN 
    PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (5, 4) 
WHERE 
    UR.Reputation > 1000
    AND PA.Upvotes - PA.Downvotes > 0 
    AND (PH.CreationDate IS NULL OR PH.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
ORDER BY 
    UR.TotalBounty DESC, 
    PA.ViewCount DESC
LIMIT 10;