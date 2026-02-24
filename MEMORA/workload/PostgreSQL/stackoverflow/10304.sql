SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
    AVG(vote_score.VoteCount) AS AverageVotes,
    AVG(c.CommentCount) AS AverageComments,
    MAX(p.CreationDate) AS LatestPostDate,
    MIN(p.CreationDate) AS EarliestPostDate
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount 
     FROM Votes 
     GROUP BY PostId) AS vote_score ON p.Id = vote_score.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) AS c ON p.Id = c.PostId
GROUP BY 
    pt.Name
ORDER BY 
    TotalPosts DESC;