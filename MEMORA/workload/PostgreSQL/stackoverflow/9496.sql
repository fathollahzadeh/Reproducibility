
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(v.Id) AS VoteCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate > (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 10
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    tp.OwnerDisplayName,
    bh.Name AS BadgeName,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerDisplayName = (SELECT u.DisplayName FROM Users u WHERE u.Id = b.UserId)
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    (SELECT UserId, Name FROM Badges WHERE Class = 1) bh ON b.UserId = bh.UserId
GROUP BY 
    tp.Title, tp.ViewCount, tp.CreationDate, tp.OwnerDisplayName, bh.Name
ORDER BY 
    tp.ViewCount DESC, tp.CreationDate ASC;
