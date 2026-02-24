
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' AND
        p.PostTypeId = 1 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        OwnerPostRank <= 3 
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(c.Score) AS TotalCommentScore
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalPostMetrics AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pc.TotalCommentScore, 0) AS TotalCommentScore,
        tp.OwnerDisplayName
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    fpm.PostId,
    fpm.Title,
    fpm.CreationDate,
    fpm.Score,
    fpm.ViewCount,
    fpm.AnswerCount,
    fpm.CommentCount,
    fpm.TotalCommentScore,
    fpm.OwnerDisplayName,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes 
FROM 
    FinalPostMetrics fpm
LEFT JOIN 
    Votes v ON fpm.PostId = v.PostId
GROUP BY 
    fpm.PostId, fpm.Title, fpm.CreationDate, fpm.Score, fpm.ViewCount, fpm.AnswerCount, fpm.CommentCount, fpm.TotalCommentScore, fpm.OwnerDisplayName
ORDER BY 
    fpm.Score DESC, fpm.ViewCount DESC
LIMIT 10;
