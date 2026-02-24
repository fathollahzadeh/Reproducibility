
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerUserId,
        rp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    LEFT JOIN 
        Badges b ON rp.OwnerUserId = b.UserId
    WHERE 
        rp.Rank = 1 
    GROUP BY 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.OwnerUserId, 
        rp.OwnerDisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.VoteCount,
    ps.BadgeCount,
    COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM ph.CreationDate) - EXTRACT(EPOCH FROM ps.CreationDate)), 2), 0) AS AverageEditTime
FROM 
    PostStats ps
LEFT JOIN 
    PostHistory ph ON ps.PostId = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6) 
GROUP BY 
    ps.PostId, 
    ps.Title, 
    ps.CreationDate, 
    ps.Score, 
    ps.ViewCount, 
    ps.OwnerDisplayName, 
    ps.CommentCount, 
    ps.VoteCount, 
    ps.BadgeCount
ORDER BY 
    ps.Score DESC, 
    ps.ViewCount DESC
LIMIT 10;
