WITH RankedPosts AS (
    SELECT 
        p.Id as PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        COALESCE(NULLIF(p.OwnerDisplayName, ''), 'Community User') as OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) as RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum <= 5
),
PostStatistics AS (
    SELECT 
        tp.PostId, 
        tp.Title, 
        tp.CreationDate, 
        tp.Score, 
        tp.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.OwnerDisplayName
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpvoteCount,
    ps.DownvoteCount
FROM 
    PostStatistics ps
ORDER BY 
    ps.Score DESC, ps.CreationDate ASC;