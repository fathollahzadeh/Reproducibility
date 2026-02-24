WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        CreationDate, 
        PostType, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.*,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS UpvoteCount
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON tp.PostId = c.PostId
LEFT JOIN 
    Votes v ON tp.PostId = v.PostId AND v.VoteTypeId = 2 
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.CreationDate, tp.PostType, tp.OwnerDisplayName
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;