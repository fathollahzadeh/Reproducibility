
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName,
        COALESCE(b.Name, 'No Badges') AS UserBadges,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, 
        u.DisplayName, b.Name
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.OwnerDisplayName,
    ps.UserBadges,
    ps.CommentCount,
    ps.VoteCount,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.LastEditDate
FROM 
    PostStats ps
LEFT JOIN 
    PostHistoryStats phs ON ps.PostId = phs.PostId
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 100;
