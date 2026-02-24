SELECT 
    u.DisplayName AS UserName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.ViewCount AS PostViewCount,
    p.Score AS PostScore,
    COUNT(c.Id) AS CommentCount,
    COUNT(DISTINCT v.Id) AS VoteCount,
    pt.Name AS PostType,
    CASE
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer'
        ELSE 'Not Accepted'
    END AS AcceptedStatus
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
WHERE 
    p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.ViewCount, p.Score, pt.Name, p.AcceptedAnswerId
ORDER BY 
    PostScore DESC, PostViewCount DESC;