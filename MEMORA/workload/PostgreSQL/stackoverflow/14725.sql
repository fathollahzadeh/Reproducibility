
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(v.Id) AS TotalVotes,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
    AVG(p.Score) AS AveragePostScore,
    AVG(p.ViewCount) AS AverageViewCount,
    AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - p.CreationDate))) AS AveragePostAgeInSeconds
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalPosts DESC
FETCH FIRST 100 ROWS ONLY;
