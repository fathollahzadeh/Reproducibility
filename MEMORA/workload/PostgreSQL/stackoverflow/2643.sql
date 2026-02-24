
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags,
    COALESCE(b.Class, 0) AS BadgeClass,
    tp.Title,
    tp.Score,
    tp.CommentCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN 
    PostLinks pl ON pl.PostId = p.Id
LEFT JOIN 
    Tags t ON t.Id = pl.RelatedPostId
LEFT JOIN 
    Badges b ON b.UserId = u.Id AND b.Class = 1
LEFT JOIN 
    TopPosts tp ON tp.PostId = p.Id
WHERE 
    u.Reputation > 1000
GROUP BY 
    u.Id, u.DisplayName, b.Class, tp.Title, tp.Score, tp.CommentCount
HAVING 
    COUNT(t.Id) > 2
ORDER BY 
    u.Reputation DESC, tp.Score DESC;
