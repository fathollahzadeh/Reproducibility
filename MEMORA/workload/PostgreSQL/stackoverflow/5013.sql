WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    t.OwnerDisplayName,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    AVG(bb.Class) AS AverageBadgeClass
FROM 
    TopPosts t
LEFT JOIN 
    Comments c ON c.PostId = t.PostId
LEFT JOIN 
    Votes v ON v.PostId = t.PostId
LEFT JOIN 
    Badges bb ON bb.UserId = (SELECT id FROM Users WHERE DisplayName = t.OwnerDisplayName LIMIT 1)
GROUP BY 
    t.OwnerDisplayName
ORDER BY 
    CommentCount DESC, VoteCount DESC;