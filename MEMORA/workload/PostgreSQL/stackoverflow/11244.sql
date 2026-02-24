
SELECT 
    u.DisplayName AS UserDisplayName,
    p.Title AS PostTitle,
    p.CreationDate AS PostCreationDate,
    p.Score AS PostScore,
    p.ViewCount AS PostViewCount,
    c.Text AS CommentText,
    c.CreationDate AS CommentCreationDate,
    COUNT(v.Id) AS VoteCount,
    ARRAY_AGG(DISTINCT pt.Name) AS PostTypeNames,
    ARRAY_AGG(DISTINCT lt.Name) AS LinkTypeNames
FROM 
    Users u
JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
GROUP BY 
    u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount, c.Text, c.CreationDate
ORDER BY 
    p.CreationDate DESC
LIMIT 100;
