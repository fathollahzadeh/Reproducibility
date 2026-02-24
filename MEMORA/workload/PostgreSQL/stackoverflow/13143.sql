SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AvgQuestionScore,
    COUNT(DISTINCT u.Id) AS TotalUsers,
    COUNT(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 END) AS ClosedPostsCount
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
GROUP BY 
    DATE_TRUNC('month', p.CreationDate) 
ORDER BY 
    DATE_TRUNC('month', p.CreationDate);