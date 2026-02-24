SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    COALESCE(c.CommentCount, 0) AS NumberOfComments,
    COALESCE(an.AnswerCount, 0) AS NumberOfAnswers,
    COALESCE(v.TotalUpVotes, 0) AS TotalUpVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) an ON p.Id = an.ParentId
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS TotalUpVotes FROM Votes WHERE VoteTypeId = 2 GROUP BY PostId) v ON p.Id = v.PostId
WHERE 
    p.PostTypeId = 1  
ORDER BY 
    p.CreationDate DESC
LIMIT 10;