SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    COUNT(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 END) AS AcceptedAnswers,
    SUM(p.Score) AS TotalScore,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.ViewCount) AS AverageViews,
    AVG(p.Score) AS AverageScore,
    MIN(p.CreationDate) AS EarliestPost,
    MAX(p.CreationDate) AS LatestPost
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
GROUP BY 
    p.PostTypeId
ORDER BY 
    TotalPosts DESC;