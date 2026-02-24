WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        p.CreationDate,
        p.Score,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank,
        RANK() OVER (ORDER BY COUNT(a.Id) DESC) AS AnswerRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.Score
),
FilteredRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CommentCount,
        rp.AnswerCount,
        rp.CreationDate,
        rp.Score,
        rp.CommentRank,
        rp.AnswerRank,
        ROW_NUMBER() OVER (PARTITION BY rp.CommentRank, rp.AnswerRank ORDER BY rp.CreationDate DESC) AS RowNum
    FROM 
        RankedPosts rp
)
SELECT 
    f.PostId,
    f.Title,
    f.Body,
    f.Tags,
    f.CommentCount,
    f.AnswerCount,
    f.CreationDate,
    f.Score,
    f.CommentRank,
    f.AnswerRank
FROM 
    FilteredRankedPosts f
WHERE 
    f.RowNum <= 5 
ORDER BY 
    f.CommentRank, 
    f.AnswerRank;