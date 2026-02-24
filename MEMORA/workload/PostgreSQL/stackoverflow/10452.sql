WITH HighScoringPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
MostCommentedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.CommentCount DESC) AS CommentRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
SELECT 
    h.PostId,
    h.Title,
    h.Score,
    h.ViewCount,
    h.AnswerCount,
    h.OwnerDisplayName AS HighScorerOwner,
    h.CreationDate AS HighScoreCreationDate,
    m.CommentCount,
    m.OwnerDisplayName AS MostCommentedOwner,
    m.CreationDate AS MostCommentedCreationDate
FROM 
    HighScoringPosts h
JOIN 
    MostCommentedPosts m ON h.PostId = m.PostId
WHERE 
    h.ScoreRank <= 10 AND m.CommentRank <= 10
ORDER BY 
    h.Score DESC, m.CommentCount DESC;