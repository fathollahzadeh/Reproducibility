
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        COUNT(c.Id) AS CommentCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, Score, ViewCount, OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RowNum = 1
    ORDER BY 
        Score DESC, ViewCount DESC
    LIMIT 10
)
SELECT 
    tp.Title, 
    tp.CreationDate, 
    tp.Score, 
    tp.ViewCount, 
    tp.OwnerDisplayName,
    COALESCE(b.Name, 'No Badge') AS BadgeName, 
    COUNT(v.Id) AS VoteCount
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    Votes v ON v.PostId = tp.PostId
GROUP BY 
    tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.OwnerDisplayName, b.Name
ORDER BY 
    tp.Score DESC;
