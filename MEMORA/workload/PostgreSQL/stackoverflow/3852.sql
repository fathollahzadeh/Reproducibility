WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score IS NOT NULL
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerUserId,
        rp.Score,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
)
SELECT 
    u.DisplayName AS Owner,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    COUNT(DISTINCT c.Id) AS CommentCount,
    MAX(v.CreationDate) AS LastVoteDate
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1 
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId IN (2, 3) 
GROUP BY 
    u.DisplayName, tp.Title, tp.Score, tp.ViewCount, b.Name
HAVING 
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10 
ORDER BY 
    tp.Score DESC, u.DisplayName ASC