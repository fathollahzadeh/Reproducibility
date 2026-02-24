
SELECT 
    CAST(CreationDate AS DATE) AS PostCreationDate,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore
FROM 
    Posts
GROUP BY 
    CAST(CreationDate AS DATE)
ORDER BY 
    PostCreationDate;
