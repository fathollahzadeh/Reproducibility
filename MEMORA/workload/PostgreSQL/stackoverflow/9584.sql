
WITH PostInfo AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(DISTINCT c.Id) AS CommentCount, 
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.OwnerUserId  -- Added to GROUP BY clause
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId  -- Added missing columns
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount, 
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS TotalBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.CreationDate,
    pi.Score,
    pi.ViewCount,
    pi.CommentCount,
    pi.AnswerCount,
    ph.EditCount,
    ph.LastEditDate,
    ub.TotalBadges,
    pi.OwnerDisplayName
FROM 
    PostInfo pi
LEFT JOIN 
    PostHistoryInfo ph ON pi.PostId = ph.PostId
LEFT JOIN 
    UserBadges ub ON pi.OwnerUserId = ub.UserId
ORDER BY 
    pi.Score DESC, 
    pi.ViewCount DESC;
