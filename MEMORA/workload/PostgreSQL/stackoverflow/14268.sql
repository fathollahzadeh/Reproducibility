
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2020-01-01'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount, u.DisplayName
),
TopPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.ViewCount DESC) AS ViewRank,
        RANK() OVER (ORDER BY pd.Score DESC) AS ScoreRank
    FROM 
        PostDetails pd
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    AnswerCount,
    OwnerDisplayName,
    CommentCount,
    ViewRank,
    ScoreRank
FROM 
    TopPosts
WHERE 
    ViewRank <= 10 OR ScoreRank <= 10
ORDER BY 
    ViewRank, ScoreRank;
