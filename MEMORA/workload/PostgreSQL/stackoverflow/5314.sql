WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositiveScorePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativeScorePosts,
        SUM(COALESCE(V.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN P.ViewCount > 100 THEN 1 ELSE 0 END) AS HighViewCount,
        MAX(P.CreationDate) AS LastActivity
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    UA.DisplayName,
    UA.PostCount,
    UA.PositiveScorePosts,
    UA.NegativeScorePosts,
    UA.TotalBounty,
    PE.Title,
    PE.CommentCount,
    PE.HighViewCount,
    PE.LastActivity
FROM 
    UserActivity UA
JOIN 
    PostEngagement PE ON UA.UserId = PE.PostId
ORDER BY 
    UA.TotalBounty DESC, UA.PostCount DESC
LIMIT 50;