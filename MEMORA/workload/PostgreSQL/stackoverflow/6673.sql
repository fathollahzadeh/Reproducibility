
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ViewRank <= 5
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.CreationDate,
    tp.OwnerDisplayName,
    bh.Name AS BadgeName,
    pt.Name AS PostTypeName
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
LEFT JOIN 
    PostTypes pt ON (SELECT PostTypeId FROM Posts WHERE Id = tp.PostId) = pt.Id
LEFT JOIN 
    Users u ON tp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    Badges bh ON u.Id = bh.UserId
WHERE 
    bh.Date BETWEEN CURRENT_DATE - INTERVAL '1 year' AND CURRENT_DATE
ORDER BY 
    tp.ViewCount DESC, tp.Score DESC;
