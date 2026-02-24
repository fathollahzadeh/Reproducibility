
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
),
CommentsWithScores AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
CombinedStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        COALESCE(cs.TotalComments, 0) AS TotalComments,
        COALESCE(cs.PositiveComments, 0) AS PositiveComments,
        CASE 
            WHEN tp.AnswerCount > 0 THEN (CAST(tp.Score AS FLOAT) / tp.AnswerCount) 
            ELSE NULL 
        END AS ScorePerAnswer
    FROM 
        TopPosts tp
    LEFT JOIN 
        CommentsWithScores cs ON tp.PostId = cs.PostId
)
SELECT 
    cs.PostId,
    cs.Title,
    cs.CreationDate,
    cs.Score,
    cs.ViewCount,
    cs.AnswerCount,
    cs.TotalComments,
    cs.PositiveComments,
    cs.ScorePerAnswer,
    CASE 
        WHEN cs.Score IS NULL THEN 'No Score'
        ELSE CASE 
            WHEN cs.Score >= 100 THEN 'High Score'
            WHEN cs.Score >= 50 THEN 'Medium Score'
            ELSE 'Low Score'
        END 
    END AS ScoreCategory
FROM 
    CombinedStats cs
ORDER BY 
    cs.Score DESC, cs.CreationDate ASC;
