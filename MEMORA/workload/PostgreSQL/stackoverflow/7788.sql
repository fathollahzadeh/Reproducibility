WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.Author
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
CommentsAggregate AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(c.Text ORDER BY c.CreationDate DESC) AS LatestComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.Author,
    ca.CommentCount,
    ca.LatestComments
FROM 
    TopPosts tp
JOIN 
    CommentsAggregate ca ON tp.PostId = ca.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;