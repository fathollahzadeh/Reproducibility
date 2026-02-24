WITH ranked_posts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND 
        p.ViewCount > 100
),
top_posts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.ViewCount, 
        rp.OwnerDisplayName 
    FROM 
        ranked_posts rp
    WHERE 
        rp.Rank <= 10
),
post_comments AS (
    SELECT 
        pc.PostId, 
        COUNT(pc.Id) AS CommentCount 
    FROM 
        Comments pc
    GROUP BY 
        pc.PostId
),
post_votes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes 
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    COALESCE(pv.Upvotes, 0) AS Upvotes,
    COALESCE(pv.Downvotes, 0) AS Downvotes
FROM 
    top_posts tp
LEFT JOIN 
    post_comments pc ON tp.PostId = pc.PostId
LEFT JOIN 
    post_votes pv ON tp.PostId = pv.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;