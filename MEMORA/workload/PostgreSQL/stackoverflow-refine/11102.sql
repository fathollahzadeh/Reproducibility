SELECT 
    (SELECT COUNT(*) FROM Posts) AS TotalPosts,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    (SELECT COUNT(*) FROM Comments) AS TotalComments,
    AVG(Score) AS AveragePostScore,
    (SELECT COUNT(*) FROM Badges) AS TotalBadges
FROM 
    Posts
WHERE 
    CreationDate >= '2023-01-01' 
    AND ViewCount > 100;