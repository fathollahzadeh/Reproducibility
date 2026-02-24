SELECT 
    p.PostTypeId,
    COUNT(p.Id) AS TotalPosts,
    SUM(CASE WHEN p.ANSWERCOUNT > 0 THEN 1 ELSE 0 END) AS TotalQuestionsWithAnswers,
    AVG(p.Score) AS AvgScorePerPost,
    SUM(c.CommentCount) AS TotalComments,
    SUM(v.VoteCount) AS TotalVotes,
    u.Reputation AS UserReputation,
    u.DisplayName AS UserDisplayName
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount
     FROM Comments
     GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS VoteCount
     FROM Votes
     GROUP BY PostId) v ON p.Id = v.PostId
WHERE 
    p.CreationDate >= '2023-01-01' AND 
    p.CreationDate < '2024-01-01' 
GROUP BY 
    p.PostTypeId, u.Reputation, u.DisplayName
ORDER BY 
    TotalPosts DESC;