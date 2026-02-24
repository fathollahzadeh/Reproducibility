WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.Reputation AS OwnerReputation,
        u.DisplayName AS OwnerDisplayName,
        p.LastActivityDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
BadgeStats AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.PostCreationDate,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    ps.OwnerReputation,
    ps.OwnerDisplayName,
    ps.LastActivityDate,
    COALESCE(ph.EditCount, 0) AS EditCount,
    ph.LastEditDate,
    COALESCE(bs.BadgeCount, 0) AS OwnerBadgeCount
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryStats ph ON ps.PostId = ph.PostId
LEFT JOIN 
    BadgeStats bs ON ps.OwnerReputation = bs.UserId
ORDER BY 
    ps.LastActivityDate DESC;