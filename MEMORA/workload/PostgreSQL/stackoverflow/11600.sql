
SELECT p.Title, p.CreationDate, p.Score, u.DisplayName AS OwnerDisplayName, 
       COUNT(c.Id) AS CommentCount, 
       SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
       SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
WHERE p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
GROUP BY p.Title, p.CreationDate, p.Score, u.DisplayName
ORDER BY p.CreationDate DESC
LIMIT 100;
