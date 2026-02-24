WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        u.DisplayName AS Owner, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.Owner,
        CASE 
            WHEN rp.Score > 100 THEN 'High Score' 
            WHEN rp.Score BETWEEN 50 AND 100 THEN 'Medium Score'
            ELSE 'Low Score' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank = 1
)
SELECT 
    tp.Title, 
    tp.CreationDate, 
    tp.Score, 
    tp.Owner, 
    tp.ScoreCategory,
    COALESCE(b.Count, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS Count 
     FROM Badges 
     GROUP BY UserId) b ON tp.Owner = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
WHERE 
    tp.ScoreCategory = 'High Score'
ORDER BY 
    tp.Score DESC
LIMIT 10;