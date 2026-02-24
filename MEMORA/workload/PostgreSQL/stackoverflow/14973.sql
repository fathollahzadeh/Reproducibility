
SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges,
    AVG(Score) AS AveragePostScore,
    AVG(ViewCount) AS AveragePostViewCount
FROM 
    Posts
WHERE 
    CreationDate >= '2023-01-01' 
    AND PostTypeId = 1 
GROUP BY 
    EXTRACT(YEAR FROM CreationDate) 
ORDER BY 
    TotalPosts DESC;
