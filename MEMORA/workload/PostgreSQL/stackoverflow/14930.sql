SELECT 
    COUNT(DISTINCT p.Id) AS TotalPosts,
    COUNT(DISTINCT c.Id) AS TotalComments,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    AVG(p.Score) AS AveragePostScore,
    AVG(c.Score) AS AverageCommentScore,
    AVG(CASE WHEN p.ViewCount IS NULL THEN 0 ELSE p.ViewCount END) AS AveragePostViewCount,
    AVG(CASE WHEN p.AnswerCount IS NULL THEN 0 ELSE p.AnswerCount END) AS AverageAnswersPerQuestion,
    AVG(u.Reputation) AS AverageUserReputation
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate >= '2023-01-01' 
    AND p.PostTypeId IN (1, 2);