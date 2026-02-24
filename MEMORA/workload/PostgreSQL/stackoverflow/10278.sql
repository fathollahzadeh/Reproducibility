
WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(pb.BadgeCount, 0) AS BadgeCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2  
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) pb ON p.OwnerUserId = pb.UserId
    WHERE 
        p.CreationDate >= '2022-01-01'  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, pb.BadgeCount, p.OwnerUserId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.CommentCount,
    ps.AnswerCount,
    u.DisplayName AS OwnerUserDisplayName,
    u.Reputation AS OwnerUserReputation,
    ps.BadgeCount
FROM 
    PostSummary ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
