SELECT 
    p.PostTypeId,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    AVG(v.CountVotes) AS AverageVotesPerPost,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CountVotes
     FROM Votes 
     GROUP BY PostId) v ON p.Id = v.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
GROUP BY 
    p.PostTypeId
ORDER BY 
    p.PostTypeId;