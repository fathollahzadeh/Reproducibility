WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2  
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Owner,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    COALESCE(b.UserCount, 0) AS BadgeCount
FROM 
    PostStats ps
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS UserCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON ps.Owner = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 100;