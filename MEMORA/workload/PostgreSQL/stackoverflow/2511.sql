
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    COALESCE(BadgesEarned.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN tp.Score > 100 THEN 'High Score'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
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
) AS BadgesEarned ON tp.PostId IN (
    SELECT 
        p.Id 
    FROM 
        Posts p 
    WHERE 
        p.OwnerUserId = BadgesEarned.UserId
)
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC
FETCH FIRST 10 ROWS ONLY; 
