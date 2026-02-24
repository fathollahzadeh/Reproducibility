WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 AND
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        CreationDate,
        Score,
        ViewCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
CommentsSummary AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        AVG(Score) AS AverageCommentScore
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalResult AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.OwnerDisplayName,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        cs.CommentCount,
        cs.AverageCommentScore
    FROM 
        TopPosts tp
    LEFT JOIN 
        CommentsSummary cs ON tp.PostId = cs.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.OwnerDisplayName,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    COALESCE(fr.CommentCount, 0) AS CommentCount,
    COALESCE(fr.AverageCommentScore, 0) AS AverageCommentScore
FROM 
    FinalResult fr
ORDER BY 
    fr.Score DESC, fr.CreationDate DESC;