SELECT 
    COUNT(*) AS TotalPosts,
    SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    AVG(ViewCount) AS AverageViews,
    AVG(Score) AS AverageScore,
    MAX(CreationDate) AS MostRecentPost,
    MIN(CreationDate) AS OldestPost
FROM 
    Posts
WHERE 
    CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year';