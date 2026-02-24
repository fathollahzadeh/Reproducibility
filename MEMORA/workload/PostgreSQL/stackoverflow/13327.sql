
WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        P.CreationDate,
        U.Reputation
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATE '2022-01-01'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, U.Reputation
)
SELECT 
    PostId,
    Title,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    BadgeCount,
    CreationDate,
    Reputation,
    CASE 
        WHEN Score > 10 THEN 'High Engagement'
        WHEN Score BETWEEN 1 AND 10 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostStatistics
ORDER BY 
    Score DESC, ViewCount DESC;
