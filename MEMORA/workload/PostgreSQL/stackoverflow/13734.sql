SELECT 
    COUNT(*) AS TotalPosts,
    AVG(ViewCount) AS AvgViewCount,
    AVG(Score) AS AvgScore,
    SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    SUM(CASE WHEN PostTypeId = 3 THEN 1 ELSE 0 END) AS TotalWikis,
    SUM(CASE WHEN ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalClosedPosts,
    SUM(CASE WHEN FavoriteCount > 0 THEN 1 ELSE 0 END) AS TotalFavoritePosts,
    COUNT(DISTINCT OwnerUserId) AS TotalUniqueAuthors,
    COUNT(DISTINCT Tags) AS TotalUniqueTags,
    MIN(CreationDate) AS EarliestPostDate,
    MAX(CreationDate) AS LatestPostDate
FROM 
    Posts
WHERE 
    CreationDate >= '2023-01-01' AND CreationDate < '2024-01-01';
