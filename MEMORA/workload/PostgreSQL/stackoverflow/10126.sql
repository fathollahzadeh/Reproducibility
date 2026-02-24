
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        PT.Name AS PostType,
        U.Reputation AS OwnerReputation,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = P.OwnerUserId) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Score, P.ViewCount, PT.Name, U.Reputation
)

SELECT 
    PostId,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    PostType,
    OwnerReputation,
    BadgeCount
FROM 
    PostMetrics
ORDER BY 
    ViewCount DESC;
