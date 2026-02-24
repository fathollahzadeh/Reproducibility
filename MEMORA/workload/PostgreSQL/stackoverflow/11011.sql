
SELECT p.Id AS PostId,
       p.Title,
       p.CreationDate,
       p.ViewCount,
       p.Score,
       COUNT(c.Id) AS CommentCount,
       SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
       SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
       COUNT(DISTINCT b.Id) AS BadgeCount,
       pt.Name AS PostTypeName,
       COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
WHERE p.CreationDate >= '2022-01-01'  
GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, pt.Name, p.AcceptedAnswerId
ORDER BY p.CreationDate DESC;
