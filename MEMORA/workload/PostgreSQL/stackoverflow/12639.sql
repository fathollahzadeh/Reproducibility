SELECT 
    p.PostTypeId,
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViewCount,
    AVG(p.ViewCount) AS AvgViewCount,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 END), 0) AS TotalQuestions,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 END), 0) AS TotalAnswers,
    COALESCE(SUM(CASE WHEN p.PostTypeId = 3 THEN 1 END), 0) AS TotalWikis,
    COUNT(DISTINCT p.OwnerUserId) AS UniqueUsers,
    SUM(u.Reputation) AS TotalReputation,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.PostTypeId, pt.Name
ORDER BY 
    p.PostTypeId;