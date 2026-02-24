WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 10
),
PostComments AS (
    SELECT 
        c.PostId,
        c.UserDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(c.Score) AS TotalScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId, c.UserDisplayName
),
PostsWithComments AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pc.TotalScore, 0) AS TotalScore
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    p.Title,
    p.CreationDate,
    p.OwnerDisplayName,
    p.Score,
    p.ViewCount,
    p.AnswerCount,
    p.CommentCount,
    p.TotalScore,
    CASE 
        WHEN p.Score > 10 THEN 'High Score'
        WHEN p.Score BETWEEN 5 AND 10 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    PostsWithComments p
ORDER BY 
    p.ViewCount DESC, p.Score DESC;