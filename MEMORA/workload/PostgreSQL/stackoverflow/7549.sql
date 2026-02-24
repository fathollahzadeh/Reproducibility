
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1   
        AND p.CreationDate >= DATE('2024-10-01') - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1  
    ORDER BY 
        rp.Score DESC, rp.ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    COALESCE(b.Count, 0) AS BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT UserId, COUNT(*) AS Count 
     FROM Badges 
     GROUP BY UserId) b ON tp.OwnerDisplayName = (SELECT DisplayName 
                                                    FROM Users 
                                                    WHERE Id = b.UserId)
ORDER BY 
    tp.Score DESC;
