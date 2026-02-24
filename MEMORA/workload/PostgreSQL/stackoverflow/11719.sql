SELECT 
    EXTRACT(YEAR FROM p.CreationDate) AS Year,
    COUNT(p.Id) AS TotalPosts,
    AVG(CASE WHEN p.PostTypeId = 1 THEN p.Score END) AS AverageQuestionScore,
    COUNT(DISTINCT b.UserId) AS TotalUsersWithBadges
FROM 
    Posts p
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    Year
ORDER BY 
    Year DESC;