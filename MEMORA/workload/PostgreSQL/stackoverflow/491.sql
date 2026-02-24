
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount
FROM 
    Users u
JOIN 
    UsersWithBadges ub ON u.Id = ub.UserId
JOIN 
    Comments cm ON cm.UserId = u.Id
JOIN 
    TopPosts tp ON tp.Id = cm.PostId
LEFT JOIN 
    Posts p ON p.Id = tp.Id
LEFT JOIN 
    PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10 
WHERE 
    p.Score > 0
    AND (ph.CreationDate IS NULL OR ph.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days')
ORDER BY 
    tp.Score DESC, BadgeCount DESC;
