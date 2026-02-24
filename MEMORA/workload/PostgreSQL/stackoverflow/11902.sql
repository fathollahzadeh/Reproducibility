
SELECT 
    p.PostTypeId,
    pt.Name AS PostTypeName,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
    SUM(p.ViewCount) AS TotalViews,
    AVG(COALESCE(p.Score, 0)) AS AverageScore,
    SUM(COALESCE(c.CommentCount, 0)) AS TotalComments,
    COUNT(DISTINCT v.UserId) AS UniqueVoters,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS TotalGoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS TotalSilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS TotalBronzeBadges
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Badges b ON p.OwnerUserId = b.UserId
GROUP BY 
    p.PostTypeId, pt.Name
ORDER BY 
    TotalPosts DESC;
