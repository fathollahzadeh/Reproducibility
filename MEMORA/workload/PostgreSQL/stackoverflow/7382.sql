
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName
), 
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        CreationDate, 
        Author, 
        CommentCount, 
        Upvotes, 
        Downvotes 
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    tp.Author,
    tp.CommentCount,
    tp.Upvotes,
    tp.Downvotes,
    ROUND((CAST(tp.Upvotes AS decimal) / NULLIF(tp.Upvotes + tp.Downvotes, 0)) * 100, 2) AS UpvotePercentage
FROM 
    TopPosts tp
ORDER BY 
    tp.ViewCount DESC;
