WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        pc.CommentCount,
        ua.Reputation AS OwnerReputation,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN Users ua ON p.OwnerUserId = ua.Id
),
TopPosts AS (
    SELECT 
        ps.PostId, 
        ps.Title,
        ps.CreationDate,
        ps.ViewCount,
        ps.Score,
        ps.CommentCount,
        ps.OwnerReputation,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC) AS Rank
    FROM 
        PostStatistics ps
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.OwnerReputation
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10;