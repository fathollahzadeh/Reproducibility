
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS Owner,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        DENSE_RANK() OVER (PARTITION BY p.Tags ORDER BY COALESCE(SUM(v.VoteTypeId), 0) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, u.DisplayName, p.CreationDate
),
TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE Rank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Tags,
    tp.Owner,
    tp.CreationDate,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    pt.Name AS PostType
FROM 
    TopPosts tp
JOIN 
    PostTypes pt ON tp.PostId = pt.Id
ORDER BY 
    tp.Rank, tp.Upvotes DESC;
