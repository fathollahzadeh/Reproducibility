WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2) AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        CreationDate, 
        OwnerDisplayName 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 5
),
PostCommentCounts AS (
    SELECT 
        PostId, 
        COUNT(*) AS CommentCount
    FROM 
        Comments 
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    tp.OwnerDisplayName,
    COALESCE(pcc.CommentCount, 0) AS CommentCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostCommentCounts pcc ON tp.PostId = pcc.PostId
ORDER BY 
    tp.Score DESC, tp.CreationDate DESC;