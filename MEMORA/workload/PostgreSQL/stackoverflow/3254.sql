WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.Reputation, 0) AS OwnerReputation,
        COALESCE(c.CommentCount, 0) AS CommentsCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        ViewCount,
        OwnerUserId,
        OwnerReputation,
        CommentsCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.OwnerReputation,
    tp.CommentsCount,
    ARRAY_AGG(t.TagName) AS Tags,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.ExcerptPostId = p.Id
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.OwnerReputation, tp.CommentsCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;