
SELECT
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    pt.Name AS PostType,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
FROM
    Posts p
JOIN
    Users u ON p.OwnerUserId = u.Id
JOIN
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN
    Comments c ON p.Id = c.PostId
LEFT JOIN
    Votes v ON p.Id = v.PostId
LEFT JOIN
    VoteTypes vt ON v.VoteTypeId = vt.Id
WHERE
    p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
GROUP BY
    p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, u.Reputation, pt.Name
ORDER BY
    p.ViewCount DESC 
LIMIT 100;
