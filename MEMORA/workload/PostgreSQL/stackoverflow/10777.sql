
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        (SELECT COUNT(*) FROM Posts sub WHERE sub.ParentId = p.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        CommentCount,
        VoteCount,
        AnswerCount,
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank
    FROM 
        PostStats
)

SELECT 
    PostId,
    Title,
    CreationDate,
    ViewCount,
    Score,
    CommentCount,
    VoteCount,
    AnswerCount,
    ScoreRank
FROM 
    TopPosts
WHERE 
    ScoreRank <= 10  
ORDER BY 
    Score DESC;
