WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 DAYS'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.CommentCount,
    r.Upvotes,
    r.Downvotes,
    r.Rank
FROM 
    RankedPosts r
WHERE 
    r.Rank <= 10
ORDER BY 
    r.Rank, r.PostId;