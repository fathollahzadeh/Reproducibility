
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount, 
        COUNT(DISTINCT v.Id) AS VoteCount,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, pt.Name
),
TopPosts AS (
    SELECT 
        PostId, Title, Score, ViewCount, CommentCount, VoteCount, PostType
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    pt.Name AS PostType,
    ARRAY_AGG(b.Name) AS UserBadges
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
JOIN 
    PostTypes pt ON tp.PostType = pt.Name
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.CommentCount, tp.VoteCount, pt.Name
ORDER BY 
    tp.Score DESC;
