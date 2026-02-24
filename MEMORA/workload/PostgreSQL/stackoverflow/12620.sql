
SELECT 
    COUNT(p.Id) AS TotalPosts,
    AVG(p.Score) AS AveragePostScore,
    SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
    p.OwnerUserId
FROM 
    Posts p
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' 
GROUP BY 
    p.OwnerUserId
ORDER BY 
    TotalPosts DESC;
