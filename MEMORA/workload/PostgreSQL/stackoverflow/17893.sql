SELECT 
    COUNT(*) AS TotalPosts,
    SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
    SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
    AVG(ViewCount) AS AverageViewCount
FROM 
    Posts
WHERE 
    CreationDate >= '2023-01-01';
