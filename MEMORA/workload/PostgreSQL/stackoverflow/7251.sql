
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
CommentsAggregation AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        AVG(Score) AS AvgCommentScore
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    COALESCE(ca.CommentCount, 0) AS CommentCount,
    COALESCE(ca.AvgCommentScore, 0) AS AvgCommentScore
FROM 
    TopPosts tp
LEFT JOIN 
    CommentsAggregation ca ON tp.PostId = ca.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
