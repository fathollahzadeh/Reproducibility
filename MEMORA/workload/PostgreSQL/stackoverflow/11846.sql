WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        COALESCE(B.BadgeCount, 0) AS UserBadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(Id) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) B ON P.OwnerUserId = B.UserId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, B.BadgeCount
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.AnswerCount,
    PS.UserBadgeCount
FROM 
    PostStatistics PS
ORDER BY 
    PS.Score DESC,
    PS.ViewCount DESC
LIMIT 100;