SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
    AVG(u.Reputation) AS AverageReputation,
    COUNT(DISTINCT b.Id) AS TotalBadges,
    MAX(p.CreationDate) AS LastPostDate
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
LEFT JOIN 
    Badges b ON u.Id = b.UserId
WHERE 
    u.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC, AverageReputation DESC
LIMIT 10;