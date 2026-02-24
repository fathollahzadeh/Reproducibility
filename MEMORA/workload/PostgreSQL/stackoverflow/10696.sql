SELECT 
    COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS QuestionCount,
    COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS AnswerCount,
    AVG(CASE WHEN PostTypeId = 1 THEN Score END) AS AverageQuestionScore,
    AVG(CASE WHEN PostTypeId = 2 THEN Score END) AS AverageAnswerScore,
    SUM(ViewCount) AS TotalViewCount,
    SUM(CommentCount) AS TotalCommentCount,
    SUM(AnswerCount) AS TotalAnswerCount
FROM 
    Posts
WHERE 
    CreationDate >= '2023-01-01' AND CreationDate < '2024-01-01';