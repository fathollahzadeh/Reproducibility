WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),

TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score, 
        rp.AnswerCount, 
        rp.ViewCount, 
        rp.OwnerUserId, 
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 
),

PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentsText 
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),

PostSummary AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.AnswerCount,
        tp.ViewCount,
        tp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pc.CommentsText, '') AS CommentsText
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.AnswerCount,
    ps.ViewCount,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.CommentsText,
    CASE 
        WHEN ps.Score > 10 THEN 'Highly Scored'
        WHEN ps.Score BETWEEN 5 AND 10 THEN 'Moderately Scored'
        ELSE 'Low Scored'
    END AS ScoreCategory
FROM 
    PostSummary ps
ORDER BY 
    ps.CreationDate DESC;