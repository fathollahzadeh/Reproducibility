
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       p.Score,
       p.ViewCount,
       u.DisplayName AS OwnerDisplayName,
       v.VoteTypeId,
       COUNT(v.Id) AS VoteCount
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, v.VoteTypeId
ORDER BY p.CreationDate DESC
LIMIT 100;
