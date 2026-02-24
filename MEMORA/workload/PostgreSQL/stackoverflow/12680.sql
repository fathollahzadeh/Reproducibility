
WITH Benchmarking AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(a.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        a.Score AS AcceptedAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount, a.AcceptedAnswerId, a.Score
)
SELECT 
    AVG(ViewCount) AS AvgViewCount,
    AVG(Score) AS AvgScore,
    AVG(CommentCount) AS AvgCommentCount,
    COUNT(*) AS TotalQuestions,
    COUNT(CASE WHEN AcceptedAnswerId != -1 THEN 1 END) AS QuestionsWithAcceptedAnswer
FROM 
    Benchmarking;
