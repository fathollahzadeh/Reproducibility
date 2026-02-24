
SELECT u.DisplayName, 
       p.Title, 
       COUNT(c.Id) AS CommentCount, 
       SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
       SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM Posts p
JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
GROUP BY u.DisplayName, p.Title
ORDER BY CommentCount DESC, UpVotes DESC;
