
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY 
        p.Id, p.Title, p.Score, u.DisplayName 
),
TopPosts AS (
    SELECT 
        PostId, Title, OwnerDisplayName, Score, CommentCount, UpvoteCount, DownvoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10 
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    CURRENT_DATE - p.CreationDate AS DaysSincePosted
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
