
SELECT 
    CAST(CreationDate AS DATE) AS PostDate,
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore,
    AVG(ViewCount) AS AverageViewCount
FROM 
    Posts
GROUP BY 
    CAST(CreationDate AS DATE)
ORDER BY 
    PostDate;
