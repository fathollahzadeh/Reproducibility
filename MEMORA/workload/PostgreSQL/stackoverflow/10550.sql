
SELECT 
    p.Id AS PostId,
    p.Title,
    p.PostTypeId,
    p.CreationDate,
    p.ViewCount,
    COALESCE(a.AnswerCount, 0) AS TotalAnswers,
    COALESCE(c.CommentCount, 0) AS TotalComments,
    u.Reputation AS OwnerReputation,
    COUNT(v.Id) AS TotalVotes
FROM 
    Posts p
LEFT JOIN 
    (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
LEFT JOIN 
    (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes v ON p.Id = v.PostId
GROUP BY 
    p.Id, p.Title, p.PostTypeId, p.CreationDate, p.ViewCount, a.AnswerCount, c.CommentCount, u.Reputation
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
