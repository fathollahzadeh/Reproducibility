WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COALESCE(PA.Title, 'No Accepted Answer') AS AcceptedAnswerTitle
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        Badges B ON B.UserId = P.OwnerUserId
    LEFT JOIN 
        Posts PA ON PA.Id = P.AcceptedAnswerId
    WHERE 
        P.CreationDate >= '2023-01-01' 
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, PA.Title
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    CommentCount,
    VoteCount,
    BadgeCount,
    AcceptedAnswerTitle
FROM 
    PostMetrics
ORDER BY 
    CreationDate DESC
LIMIT 100;