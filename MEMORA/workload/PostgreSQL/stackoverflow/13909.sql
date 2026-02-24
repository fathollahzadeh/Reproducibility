
SELECT
    p.Id AS PostId,
    p.Title,
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    MAX(ph.CreationDate) AS LastEditDate,
    MAX(ph.CreationDate) AS LastActivityDate
FROM
    Posts p
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN
    PostHistory ph ON p.Id = ph.PostId
WHERE
    p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
GROUP BY
    p.Id, p.Title, pt.Name, u.DisplayName, u.Reputation
ORDER BY
    p.Score DESC
LIMIT 100;
