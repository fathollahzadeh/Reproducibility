SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    p.Score,
    p.ViewCount,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    COALESCE(answers.AnswerCount, 0) AS TotalAnswers,
    COALESCE(voteCounts.UpVotes, 0) AS TotalUpVotes,
    COALESCE(voteCounts.DownVotes, 0) AS TotalDownVotes
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    (SELECT PostId, COUNT(*) AS CommentCount 
     FROM Comments 
     GROUP BY PostId) c ON p.Id = c.PostId
LEFT JOIN 
    (SELECT ParentId, COUNT(*) AS AnswerCount 
     FROM Posts 
     WHERE PostTypeId = 2 
     GROUP BY ParentId) answers ON p.Id = answers.ParentId
LEFT JOIN 
    (SELECT PostId, 
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
     FROM Votes 
     GROUP BY PostId) voteCounts ON p.Id = voteCounts.PostId
WHERE 
    p.PostTypeId = 1 
ORDER BY 
    p.CreationDate DESC
LIMIT 100;