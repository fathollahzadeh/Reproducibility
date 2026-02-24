
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        PostId, Title, CreationDate, ViewCount, Score, CommentCount, UpvoteCount, DownvoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    t.Title,
    t.CreationDate,
    t.ViewCount,
    t.Score,
    t.CommentCount,
    t.UpvoteCount,
    t.DownvoteCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    TopPosts t
LEFT JOIN 
    Badges b ON t.PostId = b.UserId
ORDER BY 
    t.Score DESC, t.CreationDate ASC;
