
WITH RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > (DATE '2024-10-01' - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
HighScoredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerName,
        ROW_NUMBER() OVER (PARTITION BY rp.OwnerName ORDER BY rp.Score DESC) AS Rank
    FROM 
        RecentPosts rp
    WHERE 
        rp.Score > (SELECT AVG(Score) FROM Posts)
),
TopPosts AS (
    SELECT 
        hsp.Id,
        hsp.Title,
        hsp.CreationDate,
        hsp.ViewCount,
        hsp.Score,
        hsp.OwnerName
    FROM 
        HighScoredPosts hsp
    WHERE 
        hsp.Rank <= 3
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerName,
    COALESCE(b.BadgeCount, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON tp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
WHERE 
    tp.OwnerName IS NOT NULL
ORDER BY 
    tp.Score DESC;
