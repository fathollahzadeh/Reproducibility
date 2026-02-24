
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
)

SELECT 
    pt.Name AS PostType,
    COUNT(*) AS TotalPosts,
    AVG(p.ViewCount) AS AvgViewCount,
    AVG(p.Score) AS AvgScore,
    COUNT(CASE WHEN p.AnswerCount > 0 THEN 1 END) AS QuestionsWithAnswers,
    COUNT(CASE WHEN p.CommentCount > 0 THEN 1 END) AS QuestionsWithComments
FROM 
    RankedPosts p
JOIN 
    PostTypes pt ON p.PostId = p.PostId
WHERE 
    p.Rank <= 10 
GROUP BY 
    pt.Name
ORDER BY 
    AvgScore DESC;
