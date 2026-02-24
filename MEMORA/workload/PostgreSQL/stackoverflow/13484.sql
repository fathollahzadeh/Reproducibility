
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        pm.PostId, 
        pm.Title, 
        pm.CreationDate,
        pm.ViewCount,
        pm.Score,
        pm.VoteCount,
        pm.CommentCount,
        ROW_NUMBER() OVER (ORDER BY pm.Score DESC) AS Rank
    FROM 
        PostMetrics pm
)
SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    VoteCount,
    CommentCount
FROM 
    TopPosts
WHERE 
    Rank <= 10;
