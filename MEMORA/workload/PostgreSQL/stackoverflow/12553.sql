SELECT 
    DATE_TRUNC('month', CreationDate) AS Month,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore,
    COUNT(DISTINCT OwnerUserId) AS UniqueUsers
FROM 
    Posts
GROUP BY 
    Month
ORDER BY 
    Month;