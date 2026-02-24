
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    ut.Name AS PostTypeName,
    p.LastActivityDate
FROM
    Posts p
JOIN
    Users u ON p.OwnerUserId = u.Id
JOIN
    PostTypes ut ON p.PostTypeId = ut.Id
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
WHERE
    p.CreationDate >= '2023-01-01' 
GROUP BY
    p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, ut.Name, p.LastActivityDate
ORDER BY
    p.Score DESC, p.ViewCount DESC
LIMIT 100;
